#!/bin/bash

set -euo pipefail

# =========================================
# Configuration
# =========================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

POSTGRES_CONTAINER="sae-dolibarr-postgres"
DOLIBARR_CONTAINER="sae-dolibarr"

echo "========================================="
echo " SAE-Dolibarr - Restauration"
echo "========================================="

# =========================================
# Recherche de la dernière sauvegarde
# =========================================

DB_BACKUP=$(ls -t "$BACKUP_DIR"/database_*.dump 2>/dev/null | head -n 1 || true)

if [ -z "$DB_BACKUP" ]; then
    echo "ERREUR : aucune sauvegarde PostgreSQL trouvée."
    exit 1
fi

# Récupère la date contenue dans le nom du dump
BACKUP_NAME=$(basename "$DB_BACKUP")
BACKUP_DATE=${BACKUP_NAME#database_}
BACKUP_DATE=${BACKUP_DATE%.dump}

DOC_BACKUP="$BACKUP_DIR/documents_$BACKUP_DATE.tar.gz"

if [ ! -f "$DOC_BACKUP" ]; then
    echo "ERREUR : archive des documents introuvable."
    echo "Fichier attendu : $DOC_BACKUP"
    exit 1
fi

echo
echo "Sauvegarde utilisée :"
echo "Base      : $DB_BACKUP"
echo "Documents : $DOC_BACKUP"
echo

# =========================================
# Vérification des conteneurs
# =========================================

echo "[1/5] Vérification des conteneurs..."

docker inspect "$POSTGRES_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur PostgreSQL introuvable."
    exit 1
}

docker inspect "$DOLIBARR_CONTAINER" >/dev/null 2>&1 || {
    echo "ERREUR : conteneur Dolibarr introuvable."
    exit 1
}

# Récupère automatiquement le volume des documents
DOC_VOLUME=$(docker inspect \
    -f '{{range .Mounts}}{{if eq .Destination "/var/lib/dolibarr/documents"}}{{.Name}}{{end}}{{end}}' \
    "$DOLIBARR_CONTAINER")

if [ -z "$DOC_VOLUME" ]; then
    echo "ERREUR : volume des documents Dolibarr introuvable."
    exit 1
fi

# Récupère l'image actuellement utilisée par Dolibarr
DOLIBARR_IMAGE=$(docker inspect \
    -f '{{.Config.Image}}' \
    "$DOLIBARR_CONTAINER")

echo "Volume documents : $DOC_VOLUME"

# =========================================
# Arrêt de Dolibarr
# =========================================

echo "[2/5] Arrêt temporaire de Dolibarr..."

docker stop "$DOLIBARR_CONTAINER" >/dev/null

# =========================================
# Restauration PostgreSQL
# =========================================

echo "[3/5] Restauration de PostgreSQL..."

# Ferme les éventuelles connexions encore ouvertes
docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d postgres \
    -c "SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = 'dolibarr'
        AND pid <> pg_backend_pid();" >/dev/null

# Supprime puis recrée une base vide
docker exec "$POSTGRES_CONTAINER" \
    dropdb -U dolibarr --if-exists dolibarr

docker exec "$POSTGRES_CONTAINER" \
    createdb -U dolibarr -O dolibarr dolibarr

# Restaure le dump PostgreSQL
docker exec -i "$POSTGRES_CONTAINER" \
    pg_restore \
    -U dolibarr \
    -d dolibarr \
    --no-owner \
    --no-privileges \
    --exit-on-error \
    < "$DB_BACKUP"

echo "Base PostgreSQL restaurée."

# =========================================
# Restauration des documents
# =========================================

echo "[4/5] Restauration des documents..."

docker run --rm -i \
    --entrypoint sh \
    -v "$DOC_VOLUME:/var/lib/dolibarr/documents" \
    "$DOLIBARR_IMAGE" \
    -c '
        find /var/lib/dolibarr/documents -mindepth 1 -delete
        tar -xzf - -C /var/lib/dolibarr
        chown -R www-data:www-data /var/lib/dolibarr/documents
    ' < "$DOC_BACKUP"

echo "Documents restaurés."

# =========================================
# Redémarrage et vérification
# =========================================

echo "[5/5] Redémarrage de Dolibarr..."

docker start "$DOLIBARR_CONTAINER" >/dev/null

echo
echo "Nombre de tiers restaurés :"

docker exec "$POSTGRES_CONTAINER" \
    psql -U dolibarr -d dolibarr \
    -c "SELECT COUNT(*) AS nombre_de_tiers FROM llx_societe;"

echo
echo "========================================="
echo " Restauration terminée avec succès"
echo "========================================="