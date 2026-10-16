
#!/bin/bash

# Arrête le script lorsqu'une commande échoue
# (sauf certaines exceptions propres à Bash)
set -e

# Chemin du fichier CSV contenant les clients et fournisseurs
CSV_FILE="data/csv/tiers.csv"

# Nom du conteneur Docker hébergeant PostgreSQL
CONTAINER="sae-dolibarr-postgres"

# Affichage du titre du script
echo "========================================="
echo " SAE-Dolibarr - Import des tiers"
echo "========================================="

# Vérification de l'existence du fichier CSV
# -f vérifie que le fichier existe
# ! inverse la condition : si le fichier n'existe pas, on arrête
if [ ! -f "$CSV_FILE" ]; then
    echo "ERREUR : fichier $CSV_FILE introuvable."
    exit 1
fi

echo "[1/4] Vérification de PostgreSQL..."

# Vérifie que PostgreSQL est disponible dans le conteneur
# -U : utilisateur PostgreSQL
# -d : base de données utilisée
docker exec "$CONTAINER" pg_isready -U dolibarr -d dolibarr

echo "[2/4] Import des tiers..."

# Fonction permettant de préparer les textes pour SQL
# $1 représente la valeur transmise à la fonction
# sed remplace chaque apostrophe simple par deux apostrophes
# Cela évite les erreurs de syntaxe avec des noms comme "L'Entreprise"
escape_sql() {
    printf "%s" "$1" | sed "s/'/''/g"
}

# Lecture du fichier CSV à partir de la deuxième ligne
# tail -n +2 permet d'ignorer l'en-tête du fichier
# | transmet les lignes à la boucle while
# IFS=';' définit le point-virgule comme séparateur des champs
# read -r récupère les valeurs en conservant les antislashs
# Chaque colonne est affectée à une variable Bash
tail -n +2 "$CSV_FILE" | while IFS=';' read -r type nom email telephone adresse code_postal ville pays
do

    # Préparation des informations récupérées dans le CSV
    # $(...) exécute la fonction et récupère son résultat
    # Les variables en majuscules contiennent les valeurs préparées
    NOM=$(escape_sql "$nom")
    EMAIL=$(escape_sql "$email")
    TELEPHONE=$(escape_sql "$telephone")
    ADRESSE=$(escape_sql "$adresse")
    CODE_POSTAL=$(escape_sql "$code_postal")
    VILLE=$(escape_sql "$ville")

    # Vérifie si un tiers possède déjà cette adresse e-mail
    # docker exec exécute psql dans le conteneur PostgreSQL
    # -t : retire les en-têtes et le nombre de lignes du résultat
    # -A : retire le formatage en colonnes
    # -c : exécute directement une requête SQL
    # COUNT(*) compte les tiers possédant cet e-mail
    # Le résultat est stocké dans la variable EXISTE
    EXISTE=$(docker exec "$CONTAINER" psql \
        -U dolibarr \
        -d dolibarr \
        -tAc "SELECT COUNT(*) FROM llx_societe WHERE email = '$EMAIL';")

    # Si EXISTE est supérieur à 0, le tiers est déjà enregistré
    # -gt signifie "strictement supérieur à"
    # continue permet de passer directement à la ligne suivante
    # Cela évite de réimporter les tiers ayant le même e-mail
    if [ "$EXISTE" -gt 0 ]; then
        echo "Déjà présent : $nom ($email)"
        continue
    fi

    # Vérifie le type de tiers indiqué dans le fichier CSV
    # Si le type est "client", on active le statut client
    if [ "$type" = "client" ]; then
        CLIENT=1
        FOURNISSEUR=0

        # Génération d'une référence client commençant par CLI
        # date produit un horodatage, cut conserve 12 caractères
        CODE_CLIENT="CLI$(date +%s%N | cut -c1-12)"

        # Aucune référence fournisseur pour un client
        CODE_FOURNISSEUR=""

    # Si le type est "fournisseur", on active le statut fournisseur
    elif [ "$type" = "fournisseur" ]; then
        CLIENT=0
        FOURNISSEUR=1

        # Aucune référence client pour un fournisseur
        CODE_CLIENT=""

        # Génération d'une référence fournisseur commençant par FOU
        CODE_FOURNISSEUR="FOU$(date +%s%N | cut -c1-12)"

    # Si le type n'est ni client ni fournisseur, on signale l'erreur
    else
        echo "ERREUR : type inconnu : $type"
        exit 1
    fi

    # Construction de la requête SQL d'insertion
    # cat <<SQL permet d'écrire une requête sur plusieurs lignes
    # Les variables Bash sont remplacées par leurs valeurs
    # La requête est stockée dans la variable SQL
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

    # Envoie la requête SQL vers PostgreSQL
    # echo "$SQL" affiche la requête construite
    # | transmet cette requête à docker exec
    # -i permet au conteneur de recevoir les données en entrée
    # psql exécute la requête sur la base dolibarr
    # ON_ERROR_STOP=1 permet de signaler un échec en cas d'erreur SQL
    echo "$SQL" | docker exec -i "$CONTAINER" \
        psql -U dolibarr -d dolibarr -v ON_ERROR_STOP=1

    # Affiche le type et le nom du tiers qui vient d'être importé
    echo "Importé : $type - $nom"

# Fin de la boucle : passage au tiers suivant
done

echo "[3/4] Vérification..."

# Affiche les tiers présents dans la table llx_societe
# SELECT récupère uniquement les colonnes indiquées
# ORDER BY rowid classe les résultats par identifiant croissant
docker exec "$CONTAINER" psql \
    -U dolibarr \
    -d dolibarr \
    -c "SELECT rowid, nom, email, phone, client, fournisseur FROM llx_societe ORDER BY rowid;"

echo "[4/4] Import terminé."

# Affichage du message de fin
echo "========================================="
echo " Fin de l'import"
echo "========================================="
