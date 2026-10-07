#!/bin/bash

set -e

# Récupère automatiquement la racine du projet
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

BACKUP_DIR="$PROJECT_DIR/backups"

POSTGRES_CONTAINER="sae-dolibarr-postgres"
DOLIBARR_CONTAINER="sae-dolibarr"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

DB_BACKUP="$BACKUP_DIR/database_$DATE.dump"
DOC_BACKUP="$BACKUP_DIR/documents_$DATE.tar.gz"

echo "========================================="
echo " SAE-Dolibarr - Sauvegarde"
echo "========================================="

# Création du dossier backups si nécessaire
mkdir -p "$BACKUP_DIR"

echo "[1/3] Vérification des conteneurs..."

docker inspect "$POSTGRES_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur PostgreSQL introuvable."
    exit 1
}

docker inspect "$DOLIBARR_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur Dolibarr introuvable."
    exit 1
}

echo "[2/3] Sauvegarde de PostgreSQL..."

docker exec "$POSTGRES_CONTAINER" \
    pg_dump \
    -U dolibarr \
    -d dolibarr \
    -Fc > "$DB_BACKUP"

echo "Base sauvegardée :"
echo "$DB_BACKUP"

echo "[3/3] Sauvegarde des documents Dolibarr..."

docker exec "$DOLIBARR_CONTAINER" \
    tar -czf - \
    -C /var/lib/dolibarr \
    documents > "$DOC_BACKUP"

echo "Documents sauvegardés :"
echo "$DOC_BACKUP"

echo "========================================="
echo " Sauvegarde terminée avec succès"
echo "========================================="