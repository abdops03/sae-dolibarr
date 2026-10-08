#!/bin/bash

# Arrête le script dès qu'une commande échoue,
# si une variable non définie est utilisée,
# ou si une commande d'un pipeline échoue.
set -euo pipefail


# ============================================================
# Configuration générale du projet
# ============================================================

# Récupère automatiquement le dossier contenant ce script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# La racine du projet correspond au dossier parent de scripts/.
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Noms des conteneurs définis dans docker-compose.yml.
POSTGRES_CONTAINER="sae-dolibarr-postgres"
DOLIBARR_CONTAINER="sae-dolibarr"

# On se place à la racine du projet afin que toutes les commandes
# docker compose utilisent le bon docker-compose.yml.
cd "$PROJECT_DIR"


# ============================================================
# Chargement des variables sensibles
# ============================================================

# Si un fichier .env existe à la racine du projet,
# les variables qu'il contient sont chargées dans le script.
#
# Exemple :
# DOLIBARR_ADMIN_LOGIN=admin
# DOLIBARR_ADMIN_PASSWORD=mot_de_passe
#
# Le fichier .env doit être ignoré par Git.
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    . "$PROJECT_DIR/.env"
    set +a
fi

# Login administrateur utilisé lors de la première installation.
# Si aucune valeur n'est fournie, "admin" est utilisé.
DOLIBARR_ADMIN_LOGIN="${DOLIBARR_ADMIN_LOGIN:-admin}"

# Le mot de passe administrateur est obligatoire.
if [ -z "${DOLIBARR_ADMIN_PASSWORD:-}" ]; then
    echo "ERREUR : DOLIBARR_ADMIN_PASSWORD n'est pas défini."
    echo "Ajoutez cette variable dans le fichier .env."
    exit 1
fi


echo "========================================="
echo " SAE-Dolibarr - Installation automatique"
echo "========================================="


# ============================================================
# 1 - Vérification des prérequis
# ============================================================

echo "[1/7] Vérification de Docker..."

# Vérifie que la commande Docker existe sur la machine.
if ! command -v docker >/dev/null 2>&1; then
    echo "ERREUR : Docker n'est pas installé."
    exit 1
fi

# Vérifie que Docker Compose v2 est disponible.
if ! docker compose version >/dev/null 2>&1; then
    echo "ERREUR : Docker Compose n'est pas disponible."
    exit 1
fi

echo "Docker et Docker Compose sont disponibles."


# ============================================================
# 2 - Construction de l'image Dolibarr
# ============================================================

echo
echo "[2/7] Construction des images..."

# Construit l'image Dolibarr à partir de :
# docker/dolibarr/Dockerfile
docker compose build


# ============================================================
# 3 - Démarrage de l'infrastructure
# ============================================================

echo
echo "[3/7] Démarrage des services..."

# Démarre PostgreSQL et Dolibarr en arrière-plan.
# Les volumes existants sont conservés.
docker compose up -d


# ============================================================
# 4 - Attente de PostgreSQL
# ============================================================

echo
echo "[4/7] Attente de PostgreSQL..."

# PostgreSQL peut être démarré sans être immédiatement prêt
# à accepter des connexions.
#
# On teste donc son état toutes les 2 secondes,
# avec un maximum de 30 tentatives.
for i in $(seq 1 30); do

    if docker exec "$POSTGRES_CONTAINER" \
        pg_isready -U dolibarr -d dolibarr >/dev/null 2>&1
    then
        echo "PostgreSQL est prêt."
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "ERREUR : PostgreSQL n'est pas devenu disponible."
        exit 1
    fi

    sleep 2
done


# ============================================================
# 5 - Vérification de l'état de la base Dolibarr
# ============================================================

echo
echo "[5/7] Vérification de Dolibarr..."

# Vérifie si la table llx_user existe déjà.
#
# Cette table est créée lors de l'installation de Dolibarr.
# Si elle existe, on considère donc que l'installation
# a déjà été effectuée.
TABLE_EXISTS=$(docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d dolibarr -tAc \
    "SELECT CASE
        WHEN to_regclass('public.llx_user') IS NOT NULL
        THEN 'yes'
        ELSE 'no'
    END;")


if [ "$TABLE_EXISTS" = "yes" ]; then

    echo "Dolibarr est déjà installé."
    echo "L'initialisation de la base est ignorée."

else

    echo "Base Dolibarr vide."
    echo "Démarrage de l'installation automatique..."


    # ========================================================
    # 5.1 - Création temporaire de install.forced.php
    # ========================================================

    # Dolibarr permet de forcer certains paramètres d'installation
    # grâce au fichier install.forced.php.
    #
    # On l'utilise ici notamment pour :
    # - définir le compte administrateur ;
    # - définir son mot de passe ;
    # - activer les modules nécessaires au POC ;
    # - créer install.lock à la fin de l'installation.
    docker exec -i "$DOLIBARR_CONTAINER" \
        sh -c 'cat > /var/www/html/dolibarr/htdocs/install/install.forced.php' <<'PHP'
<?php

// Identifie notre installation automatisée.
$force_install_distrib = 'sae-dolibarr';

// Empêche l'assistant de demander les paramètres manuellement.
$force_install_noedit = 2;

// Compte SuperAdmin Dolibarr.
// Les valeurs sont récupérées depuis les variables d'environnement.
$force_install_dolibarrlogin =
    getenv('DOLIBARR_ADMIN_LOGIN') ?: 'admin';

$force_install_dolibarrpassword =
    getenv('DOLIBARR_ADMIN_PASSWORD') ?: '';

// Force la création du fichier install.lock
// afin d'empêcher de relancer l'assistant d'installation ensuite.
$force_install_lockinstall = true;

// Modules nécessaires à notre POC de gestion
// de clients et fournisseurs.
$force_install_module = 'modSociete,modFournisseur';
PHP


    # ========================================================
    # 5.2 - Création du schéma PostgreSQL Dolibarr
    # ========================================================

    echo "Création des tables Dolibarr..."

    # step2.php est une étape officielle de l'installateur Dolibarr.
    # Elle crée notamment :
    # - les tables ;
    # - les clés ;
    # - les index ;
    # - les données de référence.
    #
    # "set" indique qu'il s'agit d'une installation.
    # "fr_FR" définit la langue utilisée pendant l'installation.
    docker exec \
        -w /var/www/html/dolibarr/htdocs/install \
        "$DOLIBARR_CONTAINER" \
        php step2.php set fr_FR


    # ========================================================
    # 5.3 - Finalisation de Dolibarr
    # ========================================================

    echo "Création du compte administrateur..."

    # step5.php est la dernière étape de l'installation Dolibarr.
    #
    # Elle permet notamment :
    # - de créer le compte administrateur ;
    # - de finaliser les paramètres Dolibarr ;
    # - d'activer les modules demandés ;
    # - de créer le fichier install.lock.
    #
    # Les variables administrateur sont injectées uniquement
    # pendant cette commande.
    docker exec \
        -e DOLIBARR_ADMIN_LOGIN="$DOLIBARR_ADMIN_LOGIN" \
        -e DOLIBARR_ADMIN_PASSWORD="$DOLIBARR_ADMIN_PASSWORD" \
        -w /var/www/html/dolibarr/htdocs/install \
        "$DOLIBARR_CONTAINER" \
        php step5.php "" "" fr_FR set


    # Le fichier install.forced.php n'est utile que pendant
    # l'installation. On le supprime ensuite.
    docker exec "$DOLIBARR_CONTAINER" \
        rm -f /var/www/html/dolibarr/htdocs/install/install.forced.php

    echo "Dolibarr a été initialisé."

fi


# ============================================================
# 6 - Vérification technique de l'installation
# ============================================================

echo
echo "[6/7] Vérification de l'installation..."

# Compte le nombre de tables Dolibarr.
# Une installation correcte doit avoir de nombreuses tables llx_*.
NB_TABLES=$(docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d dolibarr -tAc \
    "SELECT COUNT(*)
     FROM information_schema.tables
     WHERE table_schema = 'public'
     AND table_name LIKE 'llx_%';")

echo "Nombre de tables Dolibarr : $NB_TABLES"


# Vérifie également qu'au moins un utilisateur existe,
# notamment le SuperAdmin créé automatiquement.
NB_USERS=$(docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d dolibarr -tAc \
    "SELECT COUNT(*) FROM llx_user;")

echo "Nombre d'utilisateurs Dolibarr : $NB_USERS"


# ============================================================
# 7 - État final de l'infrastructure
# ============================================================

echo
echo "[7/7] État des services..."

# Affiche l'état final des conteneurs.
docker compose ps


echo
echo "========================================="
echo " Installation terminée avec succès"
echo "========================================="
echo
echo "Dolibarr : http://localhost:8090"
echo "Utilisateur administrateur : $DOLIBARR_ADMIN_LOGIN"
echo
echo "Les volumes Docker existants ont été conservés."