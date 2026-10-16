
#!/bin/bash

# Arrête le script si une commande échoue (-e),
# si une variable non définie est utilisée (-u),
# ou si une commande d'un pipeline échoue (pipefail)
set -euo pipefail

# =========================================
# Configuration
# =========================================

# Récupère le chemin absolu du dossier contenant le script
# $0 : chemin utilisé pour lancer le script
# dirname : récupère le dossier parent
# cd : se déplace dans ce dossier
# pwd : récupère son chemin absolu
# $(...) : exécute les commandes et récupère leur résultat
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Récupère le dossier parent de scripts/
# Il correspond à la racine du projet SAE-Dolibarr
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Définit le chemin du dossier contenant les sauvegardes
BACKUP_DIR="$PROJECT_DIR/backups"

# Noms des conteneurs Docker du projet
# PostgreSQL contient la base de données
# Dolibarr contient l'application Apache/PHP
POSTGRES_CONTAINER="sae-dolibarr-postgres"
DOLIBARR_CONTAINER="sae-dolibarr"

# Affichage du titre du script
echo "========================================="
echo " SAE-Dolibarr - Restauration"
echo "========================================="

# =========================================
# Recherche de la dernière sauvegarde
# =========================================

# Recherche les fichiers database_*.dump dans backups/
# ls -t : trie les fichiers par date de modification,
#         du plus récent au plus ancien
# 2>/dev/null : masque les messages d'erreur
# | : transmet la liste à la commande suivante
# head -n 1 : récupère le premier fichier de la liste
# || true : évite l'arrêt du script si la recherche échoue
# Le chemin obtenu est stocké dans DB_BACKUP
DB_BACKUP=$(ls -t "$BACKUP_DIR"/database_*.dump 2>/dev/null | head -n 1 || true)

# Vérifie qu'un fichier de sauvegarde a été trouvé
# -z vérifie si la variable est vide
# Si aucune sauvegarde n'existe, le script s'arrête
if [ -z "$DB_BACKUP" ]; then
    echo "ERREUR : aucune sauvegarde PostgreSQL trouvée."
    exit 1
fi

# Récupère uniquement le nom du fichier sans son dossier
# Exemple : database_2026-10-16_09-30-00.dump
BACKUP_NAME=$(basename "$DB_BACKUP")

# Retire le préfixe "database_" du nom du fichier
# Le symbole # permet de retirer un préfixe
BACKUP_DATE=${BACKUP_NAME#database_}

# Retire l'extension ".dump"
# Le symbole % permet de retirer un suffixe
# Il ne reste que la date et l'heure de sauvegarde
BACKUP_DATE=${BACKUP_DATE%.dump}

# Recherche l'archive des documents correspondant
# à la même date que la sauvegarde PostgreSQL
DOC_BACKUP="$BACKUP_DIR/documents_$BACKUP_DATE.tar.gz"

# Vérifie que l'archive des documents existe
# ! inverse la condition
# -f vérifie la présence d'un fichier ordinaire
# Si l'archive manque, la restauration est annulée
if [ ! -f "$DOC_BACKUP" ]; then
    echo "ERREUR : archive des documents introuvable."
    echo "Fichier attendu : $DOC_BACKUP"
    exit 1
fi

# Affiche les fichiers sélectionnés pour la restauration
# echo sans argument ajoute une ligne vide
echo
echo "Sauvegarde utilisée :"
echo "Base      : $DB_BACKUP"
echo "Documents : $DOC_BACKUP"
echo

# =========================================
# Vérification des conteneurs
# =========================================

echo "[1/5] Vérification des conteneurs..."

# Vérifie que le conteneur PostgreSQL existe
# docker inspect permet de consulter sa configuration
# >/dev/null masque la sortie standard
# 2>&1 redirige également les erreurs vers /dev/null
# || exécute le bloc suivant si docker inspect échoue
docker inspect "$POSTGRES_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur PostgreSQL introuvable."
    exit 1
}

# Vérifie que le conteneur Dolibarr existe
# exit 1 arrête le script si le conteneur est introuvable
docker inspect "$DOLIBARR_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur Dolibarr introuvable."
    exit 1
}

# Récupère automatiquement le nom du volume Docker
# contenant les documents de Dolibarr
#
# docker inspect -f : formate les informations du conteneur
# .Mounts : liste les montages associés au conteneur
# range : parcourt les différents montages
# if eq .Destination : cherche le chemin de destination voulu
# .Name : récupère le nom du volume correspondant
# Le résultat est stocké dans DOC_VOLUME
DOC_VOLUME=$(docker inspect \
    -f '{{range .Mounts}}{{if eq .Destination "/var/lib/dolibarr/documents"}}{{.Name}}{{end}}{{end}}' \
    "$DOLIBARR_CONTAINER")

# Vérifie que le volume des documents a été trouvé
# -z signifie que la variable est vide
if [ -z "$DOC_VOLUME" ]; then
    echo "ERREUR : volume des documents Dolibarr introuvable."
    exit 1
fi

# Récupère le nom de l'image Docker utilisée
# par le conteneur Dolibarr
# .Config.Image contient la référence de cette image
# Elle sera réutilisée pour créer un conteneur temporaire
DOLIBARR_IMAGE=$(docker inspect \
    -f '{{.Config.Image}}' \
    "$DOLIBARR_CONTAINER")

# Affiche le nom du volume contenant les documents
echo "Volume documents : $DOC_VOLUME"

# =========================================
# Arrêt de Dolibarr
# =========================================

echo "[2/5] Arrêt temporaire de Dolibarr..."

# Arrête temporairement le conteneur Dolibarr
# Cela évite que l'application continue à modifier
# les données et les documents pendant la restauration
# >/dev/null masque l'affichage normal de la commande
docker stop "$DOLIBARR_CONTAINER" >/dev/null

# =========================================
# Restauration PostgreSQL
# =========================================

echo "[3/5] Restauration de PostgreSQL..."

# Ferme les connexions encore ouvertes vers la base dolibarr
#
# psql : client PostgreSQL permettant d'exécuter du SQL
# -U dolibarr : utilisateur PostgreSQL
# -d postgres : connexion à la base postgres
# -c : exécute directement la requête SQL
#
# pg_stat_activity : liste les sessions PostgreSQL
# pg_terminate_backend(pid) : termine une session
# WHERE datname = 'dolibarr' : cible la base Dolibarr
# pg_backend_pid() : identifiant de la session actuelle
# <> : signifie "différent de"
# >/dev/null : masque le résultat affiché
docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d postgres \
    -c "SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = 'dolibarr'
        AND pid <> pg_backend_pid();" >/dev/null

# ATTENTION : opération destructive !
# Supprime la base de données Dolibarr existante
# dropdb : commande PostgreSQL de suppression d'une base
# --if-exists : évite une erreur si la base n'existe pas
docker exec "$POSTGRES_CONTAINER" \
    dropdb -U dolibarr --if-exists dolibarr

# Recrée une base de données vide appelée dolibarr
# createdb : commande de création d'une base PostgreSQL
# -O dolibarr : définit dolibarr comme propriétaire
docker exec "$POSTGRES_CONTAINER" \
    createdb -U dolibarr -O dolibarr dolibarr

# Restaure les données PostgreSQL depuis le fichier .dump
#
# docker exec -i : conserve l'entrée standard ouverte
# pg_restore : restaure une sauvegarde PostgreSQL
# -U dolibarr : utilisateur PostgreSQL
# -d dolibarr : base de destination
# --no-owner : ne réapplique pas les propriétaires du dump
# --no-privileges : ne restaure pas les droits d'accès du dump
# --exit-on-error : arrête pg_restore en cas d'erreur SQL
# < : envoie le contenu du fichier dans l'entrée standard
# $DB_BACKUP : chemin du fichier .dump sur la machine hôte
docker exec -i "$POSTGRES_CONTAINER" \
    pg_restore \
    -U dolibarr \
    -d dolibarr \
    --no-owner \
    --no-privileges \
    --exit-on-error \
    < "$DB_BACKUP"

# Confirme la fin de l'opération PostgreSQL
echo "Base PostgreSQL restaurée."

# =========================================
# Restauration des documents
# =========================================

echo "[4/5] Restauration des documents..."

# Crée un conteneur temporaire à partir de l'image Dolibarr
# pour accéder au volume contenant les documents
#
# docker run : crée et lance un nouveau conteneur
# --rm : supprime ce conteneur après son exécution
# -i : conserve l'entrée standard pour recevoir l'archive
# --entrypoint sh : lance l'interpréteur sh
# -v : monte le volume Docker dans le conteneur temporaire
# $DOC_VOLUME : nom du volume contenant les documents
# $DOLIBARR_IMAGE : image utilisée pour ce conteneur
# -c : demande à sh d'exécuter les commandes fournies
docker run --rm -i \
    --entrypoint sh \
    -v "$DOC_VOLUME:/var/lib/dolibarr/documents" \
    "$DOLIBARR_IMAGE" \
    -c '

        # Supprime le contenu actuel du dossier documents
        # find : parcourt les fichiers et sous-dossiers
        # -mindepth 1 : conserve le dossier racine lui-même
        # -delete : supprime les éléments trouvés
        # ATTENTION : les documents actuels sont effacés
        find /var/lib/dolibarr/documents -mindepth 1 -delete

        # Extrait les documents depuis l archive de sauvegarde
        # tar : outil de gestion des archives
        # -x : extrait le contenu
        # -z : décompresse avec gzip
        # -f - : lit l archive depuis l entrée standard
        # -C : définit le dossier de destination
        tar -xzf - -C /var/lib/dolibarr

        # Rétablit le propriétaire des documents
        # chown : modifie le propriétaire et le groupe
        # -R : applique le changement récursivement
        # www-data : utilisateur et groupe utilisés par Apache
        chown -R www-data:www-data /var/lib/dolibarr/documents
    ' < "$DOC_BACKUP"

# Affiche un message à la fin de la restauration des documents
echo "Documents restaurés."

# =========================================
# Redémarrage et vérification
# =========================================

echo "[5/5] Redémarrage de Dolibarr..."

# Redémarre le conteneur Dolibarr après la restauration
# >/dev/null masque le résultat affiché dans le terminal
docker start "$DOLIBARR_CONTAINER" >/dev/null

# Affiche un titre avant la vérification
echo
echo "Nombre de tiers restaurés :"

# Vérifie que les données des tiers sont présentes
# dans la base de données PostgreSQL restaurée
#
# SELECT COUNT(*) : compte les lignes de la table
# AS nombre_de_tiers : donne un nom à la colonne résultat
# llx_societe : table Dolibarr des clients et fournisseurs
docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d dolibarr \
    -c "SELECT COUNT(*) AS nombre_de_tiers FROM llx_societe;"

# Affichage du message final
echo
echo "========================================="
echo " Restauration terminée avec succès"
echo "========================================="
