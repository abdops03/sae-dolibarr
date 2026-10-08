# Manuel de vérification -- SAE Dolibarr

## 1. Objectif

Ce manuel permet à l'enseignant/correcteur de vérifier le projet **SAE
Dolibarr** de manière autonome.

Le projet permet notamment de : - déployer Dolibarr avec Docker ; -
utiliser PostgreSQL comme SGBD ; - automatiser l'installation avec
`install.sh` ; - importer des Tiers avec `import_csv.sh` ; - sauvegarder
la base et les documents avec `backup.sh` ; - préparer une restauration
avec `restore.sh` ; - vérifier une partie du projet avec GitHub Actions.

Le périmètre fonctionnel du POC est centré sur les **Tiers
(clients/fournisseurs)**.

## 2. Pré-requis

Installer : - Git ; - Docker ; - Docker Compose via `docker compose` ; -
un terminal Linux ou WSL2 Ubuntu recommandé.

Récupérer le projet :

``` bash
git clone https://github.com/abdops03/sae-dolibarr.git
cd sae-dolibarr
```

## 3. Vérifier les scripts

``` bash
bash -n scripts/install.sh
bash -n scripts/import_csv.sh
bash -n scripts/backup.sh
bash -n scripts/restore.sh
```

Aucune sortie d'erreur est attendue.

## 4. Configuration

Le script `install.sh` utilise `DOLIBARR_ADMIN_PASSWORD`.

Créer un fichier `.env` local à la racine si nécessaire :

``` env
DOLIBARR_ADMIN_PASSWORD=VotreMotDePasse
DOLIBARR_ADMIN_LOGIN=admin
```

**Ne pas publier `.env` sur GitHub.**

## 5. Installation et démarrage

``` bash
chmod +x scripts/install.sh
./scripts/install.sh
```

À la fin, l'interface est accessible à :

``` text
http://localhost:8090/htdocs
```

Le script vérifie notamment Docker, PostgreSQL, les conteneurs, les
tables et les utilisateurs.

## 6. Vérifier les conteneurs

``` bash
docker compose ps
```

Les conteneurs `sae-dolibarr` et `sae-dolibarr-postgres` doivent être
démarrés.

Tester PostgreSQL :

``` bash
docker exec sae-dolibarr-postgres   pg_isready -U dolibarr -d dolibarr
```

## 7. Vérifier PHP et PostgreSQL

``` bash
docker exec sae-dolibarr php -m | grep -Ei 'pgsql|pdo'
```

Le résultat doit notamment contenir :

``` text
PDO
pdo_pgsql
pgsql
```

## 8. Tester Dolibarr

Ouvrir :

``` text
http://localhost:8090/htdocs
```

Puis se connecter avec les identifiants définis dans `.env`.

## 9. Tester PostgreSQL

``` bash
docker exec sae-dolibarr-postgres   psql -U dolibarr -d dolibarr   -c "SELECT 1;"
```

Vérifier les tables Dolibarr :

``` bash
docker exec sae-dolibarr-postgres   psql -U dolibarr -d dolibarr -tAc   "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'llx_%';"
```

## 10. Tester les Tiers

``` bash
docker exec sae-dolibarr-postgres   psql -U dolibarr -d dolibarr   -c "SELECT rowid, nom, email FROM llx_societe ORDER BY rowid;"
```

Le correcteur peut également vérifier les Tiers directement dans
l'interface Dolibarr.

## 11. Tester l'import CSV

Le fichier utilisé est :

``` text
data/csv/tiers.csv
```

Vérifier sa présence :

``` bash
test -f data/csv/tiers.csv && echo "CSV présent"
```

Vérifier l'en-tête :

``` bash
head -n 1 data/csv/tiers.csv
```

En-tête attendu :

``` text
type;nom;email;telephone;adresse;code_postal;ville;pays
```

Lancer l'import :

``` bash
chmod +x scripts/import_csv.sh
./scripts/import_csv.sh
```

Puis relancer une deuxième fois :

``` bash
./scripts/import_csv.sh
```

Le deuxième lancement doit reconnaître les Tiers déjà présents et ne pas
créer de doublons.

Vérifier le nombre de Tiers :

``` bash
docker exec sae-dolibarr-postgres   psql -U dolibarr -d dolibarr -tAc   "SELECT COUNT(*) FROM llx_societe;"
```

## 12. Tester la sauvegarde

``` bash
chmod +x scripts/backup.sh
./scripts/backup.sh
```

Puis :

``` bash
ls -lh backups/
```

La sauvegarde doit produire : - un fichier PostgreSQL `.dump` ; - une
archive des documents `.tar.gz`.

Exemple :

``` text
backups/database_YYYY-MM-DD_HH-MM-SS.dump
backups/documents_YYYY-MM-DD_HH-MM-SS.tar.gz
```

## 13. Restauration / PRA

Le projet contient :

``` text
scripts/restore.sh
```

Le script de restauration est préparé.

**Important :** ne pas présenter une restauration complète comme validée
si elle n'a pas été exécutée et vérifiée de bout en bout.

Ne pas utiliser `docker compose down -v` pendant une vérification
normale : l'option `-v` supprime les volumes Docker et peut supprimer
les données persistantes.

## 14. Vérifier le CI/CD

Le workflow est :

``` text
.github/workflows/docker-image.yml
```

Il se déclenche sur `push` vers `main` et sur les pull requests vers
`main`.

Il vérifie notamment : 1. la syntaxe des scripts Bash ; 2. la présence
et la structure du CSV ; 3. le build de l'image Docker ; 4. le démarrage
de Docker Compose ; 5. PostgreSQL ; 6. l'état des conteneurs ; 7. les
extensions PHP PostgreSQL ; 8. la connexion à PostgreSQL.

Sur GitHub :

``` text
Repository → Actions → CI/CD SAE Dolibarr
```

Un workflow réussi apparaît avec un statut vert.

## 15. Vérification rapide globale

``` bash
git clone https://github.com/abdops03/sae-dolibarr.git
cd sae-dolibarr

bash -n scripts/install.sh
bash -n scripts/import_csv.sh
bash -n scripts/backup.sh
bash -n scripts/restore.sh

test -f data/csv/tiers.csv

./scripts/install.sh

docker compose ps

docker exec sae-dolibarr-postgres   pg_isready -U dolibarr -d dolibarr

docker exec sae-dolibarr php -m | grep -Ei 'pgsql|pdo'

./scripts/import_csv.sh

docker exec sae-dolibarr-postgres   psql -U dolibarr -d dolibarr   -c "SELECT rowid, nom, email FROM llx_societe ORDER BY rowid;"

./scripts/backup.sh

ls -lh backups/
```

Puis ouvrir :

``` text
http://localhost:8090/htdocs
```

## 16. Résultats attendus

  Test              Résultat attendu
  ----------------- ----------------------------------------
  Syntaxe Bash      Aucune erreur
  CSV               Présent et format valide
  Build Docker      Réussi
  PostgreSQL        Disponible
  Dolibarr          Démarré
  PHP PostgreSQL    `pgsql` et `pdo_pgsql` présents
  Connexion BDD     `SELECT 1` réussi
  Interface         Accessible sur le port 8090
  Tiers             Présents dans Dolibarr / `llx_societe`
  Import CSV        Fonctionnel
  Deuxième import   Pas de doublons
  Backup            `.dump` et `.tar.gz` générés
  CI/CD             Workflow GitHub Actions au vert

## 17. En cas de problème

``` bash
docker compose ps
docker compose logs
docker compose logs dolibarr
docker compose logs postgres
docker ps
```

Conserver le message d'erreur avant de modifier ou supprimer les
données.

## 18. Architecture

``` text
                    Navigateur
                        |
                        | HTTP : 8090
                        v
              +-------------------+
              |     Dolibarr      |
              |  PHP + Apache     |
              +-------------------+
                        |
                        | PostgreSQL : 5432
                        v
              +-------------------+
              |    PostgreSQL     |
              |     Database      |
              +-------------------+
```

Les données PostgreSQL et les documents Dolibarr sont conservés dans des
volumes Docker.

## 19. Correspondance avec le cahier des charges

Les tests permettent notamment de contrôler : - l'installation
automatisée de Dolibarr et de la base ; - l'import automatisé des Tiers
depuis un CSV ; - la séparation Dolibarr / SGBD dans Docker ; - la
sauvegarde de la base et des documents ; - la préparation du processus
de restauration ; - la documentation ; - l'automatisation des
vérifications avec GitHub Actions.

Le projet est un **POC** limité au périmètre des Tiers et n'est pas
présenté comme une installation de production.

## 20. Liens

Dépôt : https://github.com/abdops03/sae-dolibarr

Interface locale : http://localhost:8090/htdocs
