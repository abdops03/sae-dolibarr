#!/bin/bash

set -e

CSV_FILE="data/csv/tiers.csv"
CONTAINER="sae-dolibarr-postgres"

echo "========================================="
echo " SAE-Dolibarr - Import des tiers"
echo "========================================="

if [ ! -f "$CSV_FILE" ]; then
    echo "ERREUR : fichier $CSV_FILE introuvable."
    exit 1
fi

echo "[1/4] Vérification de PostgreSQL..."

docker exec "$CONTAINER" pg_isready -U dolibarr -d dolibarr

echo "[2/4] Import des tiers..."

escape_sql() {
    printf "%s" "$1" | sed "s/'/''/g"
}

tail -n +2 "$CSV_FILE" | while IFS=';' read -r type nom email telephone adresse code_postal ville pays
do

    NOM=$(escape_sql "$nom")
    EMAIL=$(escape_sql "$email")
    TELEPHONE=$(escape_sql "$telephone")
    ADRESSE=$(escape_sql "$adresse")
    CODE_POSTAL=$(escape_sql "$code_postal")
    VILLE=$(escape_sql "$ville")

    EXISTE=$(docker exec "$CONTAINER" psql \
        -U dolibarr \
        -d dolibarr \
        -tAc "SELECT COUNT(*) FROM llx_societe WHERE email = '$EMAIL';")

    if [ "$EXISTE" -gt 0 ]; then
        echo "Déjà présent : $nom ($email)"
        continue
    fi

    if [ "$type" = "client" ]; then
        CLIENT=1
        FOURNISSEUR=0
        CODE_CLIENT="CLI$(date +%s%N | cut -c1-12)"
        CODE_FOURNISSEUR=""
    elif [ "$type" = "fournisseur" ]; then
        CLIENT=0
        FOURNISSEUR=1
        CODE_CLIENT=""
        CODE_FOURNISSEUR="FOU$(date +%s%N | cut -c1-12)"
    else
        echo "ERREUR : type inconnu : $type"
        exit 1
    fi

    SQL=$(cat <<SQL
INSERT INTO llx_societe (
    entity,
    nom,
    address,
    zip,
    town,
    phone,
    email,
    client,
    fournisseur,
    code_client,
    code_fournisseur,
    statut,
    status,
    fk_stcomm,
    tva_assuj
)
VALUES (
    1,
    '$NOM',
    '$ADRESSE',
    '$CODE_POSTAL',
    '$VILLE',
    '$TELEPHONE',
    '$EMAIL',
    $CLIENT,
    $FOURNISSEUR,
    NULLIF('$CODE_CLIENT', ''),
    NULLIF('$CODE_FOURNISSEUR', ''),
    1,
    1,
    0,
    1
);
SQL
)

    echo "$SQL" | docker exec -i "$CONTAINER" \
        psql -U dolibarr -d dolibarr -v ON_ERROR_STOP=1

    echo "Importé : $type - $nom"

done

echo "[3/4] Vérification..."

docker exec "$CONTAINER" psql \
    -U dolibarr \
    -d dolibarr \
    -c "SELECT rowid, nom, email, phone, client, fournisseur FROM llx_societe ORDER BY rowid;"

echo "[4/4] Import terminé."

echo "========================================="
echo " Fin de l'import"
echo "========================================="
