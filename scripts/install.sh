#!/bin/bash

set -e

echo "========================================="
echo " SAE-Dolibarr - Installation"
echo "========================================="

echo "[1/4] Vérification de Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERREUR : Docker n'est pas installé."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "ERREUR : Docker Compose n'est pas disponible."
    exit 1
fi

echo "Docker OK."
echo ""

echo "[2/4] Construction des images..."

docker compose build

echo ""
echo "[3/4] Démarrage des services..."

docker compose up -d

echo ""
echo "[4/4] Vérification..."

docker compose ps

echo ""
echo "========================================="
echo " Installation terminée"
echo "========================================="
echo ""
echo "Dolibarr : http://localhost:8090/htdocs"
echo ""
echo "Aucun volume existant n'a été supprimé."
