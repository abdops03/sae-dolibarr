
#!/bin/bash

# Arrête le script lorsqu'une commande échoue
# sauf dans certains cas particuliers de Bash
set -e

# Récupération automatique du chemin du dossier contenant le script
# $0 représente le chemin utilisé pour lancer le script
# dirname récupère le dossier parent
# cd permet de se placer dans ce dossier
# pwd récupère son chemin absolu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Récupération du dossier racine du projet
# dirname retire le dernier dossier du chemin SCRIPT_DIR
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Chemin du dossier destiné à stocker les sauvegardes
BACKUP_DIR="$PROJECT_DIR/backups"

# Noms des conteneurs Docker utilisés dans le projet
# Le premier contient la base de données PostgreSQL
# Le deuxième héberge Dolibarr avec Apache et PHP
POSTGRES_CONTAINER="sae-dolibarr-postgres"
DOLIBARR_CONTAINER="sae-dolibarr"

# Génération de la date et de l'heure actuelles
# Cette valeur permet de différencier les sauvegardes
# Exemple : 2026-10-16_09-30-00
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Définition du chemin de sauvegarde de PostgreSQL
# Le fichier .dump contiendra les données et la structure SQL
DB_BACKUP="$BACKUP_DIR/database_$DATE.dump"

# Définition du chemin de sauvegarde des documents Dolibarr
# Le fichier .tar.gz contiendra une archive compressée
DOC_BACKUP="$BACKUP_DIR/documents_$DATE.tar.gz"

# Affichage du titre du script
echo "========================================="
echo " SAE-Dolibarr - Sauvegarde"
echo "========================================="

# Création du dossier backups s'il n'existe pas
# mkdir permet de créer un répertoire
# -p évite une erreur si le dossier existe déjà
# et permet de créer les dossiers parents manquants
mkdir -p "$BACKUP_DIR"

echo "[1/3] Vérification des conteneurs..."

# Vérifie l'existence du conteneur PostgreSQL
# docker inspect récupère les informations du conteneur
# >/dev/null masque la sortie standard
# 2>&1 redirige les messages d'erreur vers cette même sortie
# || exécute le bloc suivant si docker inspect échoue
docker inspect "$POSTGRES_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur PostgreSQL introuvable."
    exit 1
}

# Vérifie l'existence du conteneur Dolibarr
# Si le conteneur est introuvable, le script s'arrête
# avec un code d'erreur grâce à exit 1
docker inspect "$DOLIBARR_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur Dolibarr introuvable."
    exit 1
}

echo "[2/3] Sauvegarde de PostgreSQL..."

# Exécute pg_dump à l'intérieur du conteneur PostgreSQL
# docker exec permet d'exécuter une commande dans un conteneur actif
# pg_dump est l'outil de sauvegarde de PostgreSQL
# -U dolibarr : utilisateur PostgreSQL
# -d dolibarr : base de données à sauvegarder
# -Fc : crée une sauvegarde au format personnalisé PostgreSQL
# > redirige le résultat vers un fichier sur la machine hôte
# $DB_BACKUP contient le chemin et le nom de ce fichier
docker exec "$POSTGRES_CONTAINER" \
    pg_dump \
    -U dolibarr \
    -d dolibarr \
    -Fc > "$DB_BACKUP"

# Affiche l'emplacement de la sauvegarde de la base
echo "Base sauvegardée :"
echo "$DB_BACKUP"

echo "[3/3] Sauvegarde des documents Dolibarr..."

# Exécute tar à l'intérieur du conteneur Dolibarr
# tar permet de créer une archive des fichiers
# -c : crée une nouvelle archive
# -z : compresse l'archive avec gzip
# -f : indique le fichier d'archive à utiliser
# - après -f : envoie l'archive vers la sortie standard
# -C /var/lib/dolibarr : se place dans ce dossier
# documents : dossier à inclure dans l'archive
# > redirige l'archive vers un fichier sur la machine hôte
# $DOC_BACKUP contient le chemin de cette sauvegarde
docker exec "$DOLIBARR_CONTAINER" \
    tar -czf - \
    -C /var/lib/dolibarr \
    documents > "$DOC_BACKUP"

# Affiche l'emplacement de la sauvegarde des documents
echo "Documents sauvegardés :"
echo "$DOC_BACKUP"

# Affichage du message de fin
echo "========================================="
echo " Sauvegarde terminée avec succès"
echo "========================================="
