# Suivi de projet — SAE 51 Dolibarr

> **Formation :** BUT3 Réseaux & Télécommunications — Groupe B  
> **Projet :** Automatisation, dockerisation et reprise d'activité d'un ERP/CRM Dolibarr  
> **Dépôt Git :** `sae-dolibarr`  
> **Équipe :** Abdoulaye, Amine, Hoilid Zeghoubi  
> **Dernière séance documentée :** 07/10/2026

---

## 1. Présentation du projet

Le projet consiste à réaliser un **POC autour de Dolibarr** en partant d'une installation manuelle, puis en rendant l'environnement reproductible et automatisé.

Le cahier des charges nous amène progressivement à mettre en place :

- une installation manuelle initiale de Dolibarr afin d'en comprendre le fonctionnement ;
- une base de données PostgreSQL ;
- une architecture Docker séparant l'application et le SGBD ;
- un script `install.sh` pour automatiser l'installation ;
- un script `import_csv.sh` pour importer les Tiers (clients et fournisseurs) ;
- un script `backup.sh` pour sauvegarder la base et les documents ;
- un script `restore.sh` pour restaurer l'environnement dans le cadre du PRA ;
- un dépôt Git/GitHub pour versionner le projet ;
- un workflow GitHub Actions pour vérifier automatiquement la construction de l'image Docker ;
- une documentation permettant de comprendre, reproduire et tester le projet.

### 1.1 Architecture finale

```text
                        Utilisateur
                            |
                            | http://localhost:8090
                            v
                  +----------------------+
                  |      Dolibarr        |
                  | Apache + PHP 8.2     |
                  | Dolibarr 24.0.1      |
                  +----------+-----------+
                             |
                             | réseau Docker Compose
                             v
                  +----------------------+
                  |    PostgreSQL 16     |
                  | Base : dolibarr      |
                  +----------------------+
```

Les deux services sont séparés afin de faciliter la maintenance, la persistance des données et la reconstruction de l'environnement.

### 1.2 Scripts principaux

```text
scripts/
├── install.sh
├── import_csv.sh
├── backup.sh
└── restore.sh
```

| Script | Rôle |
|---|---|
| `install.sh` | construire, démarrer et initialiser l'environnement |
| `import_csv.sh` | importer automatiquement les clients/fournisseurs |
| `backup.sh` | sauvegarder PostgreSQL et les documents Dolibarr |
| `restore.sh` | restaurer les données et les documents après une perte |

---

## 2. Organisation de l'équipe

Le projet a été réalisé en équipe avec des responsabilités différentes mais complémentaires. Les décisions importantes, les tests et les corrections ont été partagés afin que chaque membre soit capable d'expliquer le fonctionnement général de la solution.

### 2.1 Abdoulaye — Chef de projet

Abdoulaye assure la coordination globale du projet tout en participant aux travaux techniques.

Responsabilités principales :

- analyse du cahier des charges ;
- définition des objectifs des séances ;
- organisation et répartition des tâches ;
- suivi de l'avancement ;
- maintien de la cohérence entre les différentes parties du projet ;
- documentation ;
- participation à l'étude de Dolibarr et de ses dépendances ;
- suivi de la dockerisation ;
- participation aux tests ;
- centralisation des résultats ;
- validation de l'état du projet avant de passer à l'étape suivante.

### 2.2 Amine — Architecte systèmes et réseaux

Amine prend principalement en charge l'architecture technique et l'automatisation.

Responsabilités principales :

- étude de l'architecture Dolibarr/PostgreSQL ;
- mise en place et analyse de Docker/Docker Compose ;
- développement et correction des scripts Bash ;
- travail sur `install.sh`, `import_csv.sh`, `backup.sh` et `restore.sh` ;
- analyse de PostgreSQL et des tables Dolibarr ;
- tests de communication entre les services ;
- diagnostic des erreurs liées aux conteneurs, services et dépendances ;
- tests techniques et validation du fonctionnement.

### 2.3 Hoilid Zeghoubi — Administrateur systèmes et réseaux

Hoilid Zeghoubi rejoint l'équipe à partir du **30/09/2026**.

Son intégration s'est faite progressivement : présentation du projet, découverte de Docker et de l'architecture, reproduction des procédures, puis réalisation de tests indépendants.

Responsabilités principales :

- compréhension de l'architecture générale ;
- découverte et prise en main de Docker/Docker Compose ;
- reproduction des installations et procédures ;
- tests des scripts sur son environnement ;
- vérification du fonctionnement des services ;
- validation indépendante de certaines étapes ;
- remontée des problèmes rencontrés ;
- participation à l'administration systèmes et réseaux.

Cette répartition permet d'éviter qu'un seul membre maîtrise toute la solution : les tests réalisés par plusieurs membres servent également à vérifier la **reproductibilité** du projet.

---

## 3. Méthodologie de travail

### 3.1 Organisation Agile

Nous avons appliqué une démarche Agile simple, adaptée au temps disponible.

Au début de chaque séance :

1. nous faisions un point sur l'état du projet ;
2. nous définissions les objectifs prioritaires ;
3. les tâches étaient réparties selon les responsabilités de chacun ;
4. les résultats étaient testés avant de poursuivre.

Exemple de progression réelle :

```text
Comprendre Dolibarr
        ↓
Installation manuelle
        ↓
Étude PostgreSQL / CSV
        ↓
Dockerisation
        ↓
Automatisation
        ↓
Tests
        ↓
Sauvegarde / restauration
        ↓
Validation finale
```

Lorsqu'une difficulté bloquait une étape, l'objectif suivant était adapté. Nous n'avons donc pas cherché à tout automatiser immédiatement : l'installation manuelle a d'abord servi à comprendre les composants avant de les reproduire dans Docker.

### 3.2 Approche DevOps

La logique DevOps apparaît progressivement dans le projet :

```text
Développement
      ↓
Versionnement Git
      ↓
Automatisation Bash
      ↓
Dockerisation
      ↓
Tests
      ↓
Sauvegarde / PRA
      ↓
Intégration continue
```

Les principaux éléments mis en place sont :

- Git/GitHub pour le versionnement ;
- Dockerfile pour construire l'image Dolibarr ;
- Docker Compose pour orchestrer Dolibarr et PostgreSQL ;
- scripts Bash pour automatiser les opérations ;
- volumes Docker pour la persistance ;
- tests réguliers de l'installation et de l'import ;
- sauvegarde et restauration ;
- GitHub Actions pour vérifier le build de l'image.

Le workflow actuel relève principalement de **l'intégration continue (CI)** : il vérifie que l'image Docker peut être construite. Il n'effectue pas de déploiement automatique.

### 3.3 Versionnement et collaboration

Les commandes Git utilisées régulièrement sont notamment :

```bash
git status
git add
git commit
git push
git pull
git log --oneline
```

Le dépôt commun permet de :

- conserver un historique des modifications ;
- synchroniser les fichiers ;
- identifier les changements apportés ;
- exécuter le workflow GitHub Actions ;
- centraliser la documentation.

---

## 4. Suivi des séances

## 4.1 Séance du 22/09/2026 — Cadrage et découverte

### Objectifs

- prendre connaissance du sujet ;
- lire le cahier des charges ;
- identifier les fonctionnalités demandées ;
- découvrir Dolibarr ;
- définir une première organisation ;
- réfléchir à l'architecture technique.

### Répartition du travail

**Abdoulaye**

- lecture et synthèse du cahier des charges ;
- identification des livrables ;
- début de l'organisation du projet ;
- étude générale de Dolibarr ;
- préparation du suivi de projet.

**Amine**

- première étude de l'architecture technique ;
- recherche des prérequis systèmes ;
- étude des possibilités d'installation ;
- première réflexion sur PostgreSQL et Docker.

**Hoilid Zeghoubi**

- pas encore intégré à l'équipe.

### Tests / vérifications

À ce stade, aucun test complet n'est réalisé : la séance est volontairement consacrée au cadrage et à la compréhension.

### Résultat

Une première architecture est envisagée :

```text
Dolibarr
   |
   v
PostgreSQL
```

L'équipe décide de commencer par une installation manuelle avant toute automatisation.

### Compétences travaillées

- analyse d'un cahier des charges ;
- découpage d'un projet technique ;
- identification des dépendances d'une application web.

---

## 4.2 Séance du 23/09/2026 — Préparation de l'installation

### Objectifs

- approfondir la découverte de Dolibarr ;
- comprendre ses dépendances ;
- préparer l'installation manuelle ;
- étudier PHP, Apache et PostgreSQL ;
- préparer les premiers essais.

### Répartition du travail

**Abdoulaye**

- poursuite de l'étude fonctionnelle de Dolibarr ;
- documentation des dépendances ;
- vérification de la cohérence avec le cahier des charges ;
- préparation des étapes d'installation.

**Amine**

- étude d'Apache et PHP ;
- préparation de l'environnement Debian/WSL ;
- étude du rôle du SGBD ;
- premières recherches sur PostgreSQL et Docker.

### Vérifications préparatoires

Commandes utilisées pour vérifier l'environnement :

```bash
php --version
php -m
sudo systemctl status apache2
sudo ss -ltnp | grep ':80'
```

### Résultat

Les composants nécessaires sont identifiés et l'équipe dispose d'une procédure claire pour commencer l'installation manuelle lors de la séance suivante.

### Compétences travaillées

- vérification des services Linux ;
- compréhension des dépendances PHP ;
- préparation d'un environnement avant installation.

---

## 4.3 Séance du 28/09/2026 — Installation manuelle et étude PostgreSQL

### Objectifs

- installer Dolibarr manuellement ;
- configurer PostgreSQL ;
- comprendre la communication entre l'application et le SGBD ;
- observer les tables générées ;
- commencer la réflexion sur l'import CSV.

### Répartition du travail

**Abdoulaye**

- suivi des étapes d'installation ;
- vérification du fonctionnement de Dolibarr ;
- documentation des étapes importantes ;
- observation de la structure de l'application.

**Amine**

- installation et configuration technique ;
- connexion à PostgreSQL ;
- analyse des premières tables ;
- préparation des futurs scripts ;
- premiers essais autour des Tiers.

### Installation manuelle

Dolibarr est installé sous :

```text
/var/www/html/dolibarr
```

Les documents sont placés dans :

```text
/var/lib/dolibarr/documents
```

Connexion à PostgreSQL :

```bash
psql -h localhost -p 5432 -U dolibarr -d dolibarr
```

### Analyse de la base

Deux tables sont étudiées en priorité.

#### `llx_user`

```sql
SELECT rowid, login, admin, statut
FROM llx_user;
```

Rôle observé :

- `rowid` : identifiant interne ;
- `login` : identifiant de connexion ;
- `admin` : droit administrateur ;
- `statut` : état du compte.

#### `llx_societe`

```sql
SELECT rowid, nom, client, fournisseur, status
FROM llx_societe;
```

Cette table est centrale pour notre POC car elle contient les **Tiers**, notamment les clients et fournisseurs.

### Résultat

Cette séance marque le passage de la découverte à la réalisation technique. L'équipe comprend maintenant suffisamment l'installation et la base pour commencer l'automatisation.

### Compétences travaillées

- installation d'une application PHP ;
- utilisation de PostgreSQL ;
- lecture d'un schéma de base existant ;
- compréhension du rôle des Tiers dans Dolibarr.

---

## 4.4 Séance du 30/09/2026 — Intégration de Hoilid Zeghoubi et dockerisation

### Objectifs

- intégrer Hoilid Zeghoubi au projet ;
- lui présenter l'architecture ;
- expliquer Docker/Docker Compose ;
- séparer Dolibarr et PostgreSQL ;
- créer le Dockerfile et le Compose ;
- commencer la structuration des scripts.

### Répartition du travail

**Abdoulaye**

- présentation du projet et du cahier des charges à Hoilid Zeghoubi ;
- explication de l'organisation ;
- supervision de la dockerisation ;
- documentation des choix ;
- suivi de l'avancement.

**Amine**

- explication technique de Docker ;
- création et correction du Dockerfile ;
- travail sur `docker-compose.yml` ;
- tests de communication entre les services ;
- préparation des scripts.

**Hoilid Zeghoubi**

- découverte de Docker et Docker Compose ;
- compréhension de l'architecture ;
- premières commandes Docker ;
- reproduction de tests simples ;
- prise en main progressive du dépôt.

### Architecture Docker retenue

```text
Docker Compose
      |
      +---- sae-dolibarr
      |
      +---- sae-dolibarr-postgres
```

Le service web est exposé sur :

```text
localhost:8090 -> port 80 du conteneur
```

PostgreSQL n'a pas besoin d'être exposé sur l'hôte : Dolibarr y accède via le réseau Docker.

### Healthcheck PostgreSQL

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U dolibarr -d dolibarr"]
```

Cette ligne permet de tester que PostgreSQL accepte réellement les connexions avant de considérer le service comme disponible.

### Difficulté 1 — URL de téléchargement Dolibarr

Une première URL utilisée dans le Dockerfile renvoyait :

```text
404 Not Found
```

Test :

```bash
wget -S --spider <URL>
```

Le test a permis d'isoler le problème : ce n'était pas la variable de version mais l'URL elle-même.

La source de téléchargement a été remplacée par la source officielle Dolibarr.

### Difficulté 2 — `403 Forbidden`

Le conteneur démarrait, mais l'accès web renvoyait :

```text
403 Forbidden
```

Nous avons vérifié l'arborescence :

```bash
docker exec sae-dolibarr ls -la /var/www/html/dolibarr/
```

Les fichiers web se trouvent sous :

```text
/var/www/html/dolibarr/htdocs
```

Le `DocumentRoot` Apache a donc été corrigé pour pointer vers `htdocs`.

### Résultat

Les deux conteneurs sont séparés et l'architecture devient reproductible. Hoilid Zeghoubi comprend le principe général et commence à reproduire les commandes de son côté.

### Compétences travaillées

- construction d'une image Docker ;
- réseau Docker Compose ;
- diagnostic HTTP ;
- configuration Apache ;
- transmission de connaissances au sein d'une équipe.

---

## 4.5 Séance du 05/10/2026 — Automatisation, import et sauvegarde

### Objectifs

- poursuivre l'automatisation ;
- stabiliser les scripts principaux ;
- automatiser l'import CSV ;
- empêcher les doublons ;
- préparer la sauvegarde et la restauration ;
- multiplier les tests sur plusieurs postes.

### Répartition du travail

**Abdoulaye**

- supervision globale ;
- vérification de la conformité au cahier des charges ;
- documentation ;
- suivi des tests ;
- centralisation des résultats.

**Amine**

- développement et correction des scripts ;
- tests de `install.sh` ;
- tests de `import_csv.sh` ;
- travail sur `backup.sh` et `restore.sh` ;
- diagnostic des erreurs.

**Hoilid Zeghoubi**

- reproduction des manipulations ;
- tests indépendants ;
- vérification des scripts ;
- tests Docker ;
- remontée des erreurs rencontrées.

### Installation automatique

`install.sh` doit permettre de partir d'un environnement vide et de reconstruire Dolibarr.

Logique :

```text
vérification Docker
       ↓
docker compose build
       ↓
docker compose up
       ↓
attente PostgreSQL
       ↓
initialisation Dolibarr
       ↓
création administrateur
       ↓
vérifications
```

Une installation validée produit notamment :

```text
Nombre de tables Dolibarr : 275
Nombre d'utilisateurs Dolibarr : 1
```

### Import CSV

Le fichier contient :

```text
3 clients
2 fournisseurs
```

Le script lit chaque ligne puis vérifie d'abord l'adresse e-mail :

```sql
SELECT COUNT(*)
FROM llx_societe
WHERE email = '<email>';
```

Si le tiers existe, il n'est pas réinséré.

Logique :

```text
CSV
 |
 v
lecture d'une ligne
 |
 v
recherche de l'e-mail
 |
 +---- présent ----> ignorer
 |
 +---- absent -----> INSERT
```

Pour un client :

```text
client = 1
fournisseur = 0
```

Pour un fournisseur :

```text
client = 0
fournisseur = 1
```

### Difficulté — fins de ligne CRLF/LF

Erreur rencontrée :

```text
exec /usr/local/bin/dolibarr-entrypoint.sh: no such file or directory
```

Le fichier existait pourtant.

Nous avons successivement vérifié :

1. son chemin ;
2. ses droits ;
3. le shebang ;
4. le format des fins de ligne.

Commande :

```bash
grep -RIl $'\r' scripts docker
```

Le problème venait de fichiers enregistrés au format **CRLF** sous Windows, alors que les scripts étaient exécutés sous Linux.

Correction :

- conversion vers LF ;
- ajout de `.gitattributes` afin de stabiliser les fins de ligne.

### Sauvegarde

`backup.sh` sauvegarde deux éléments :

```text
PostgreSQL -> fichier .dump
Documents  -> archive .tar.gz
```

Le dump PostgreSQL est créé avec `pg_dump` en format custom, afin de pouvoir être restauré avec `pg_restore`.

### Résultat

À la fin de cette séance, les scripts principaux sont en place et plusieurs membres commencent à reproduire séparément les procédures.

### Compétences travaillées

- scripting Bash ;
- import SQL ;
- idempotence d'un import ;
- sauvegarde PostgreSQL ;
- compatibilité Windows/Linux ;
- tests de reproductibilité.

---

## 4.6 Séance du 07/10/2026 — Validation globale et CI

### Objectifs

- finaliser les tests ;
- vérifier l'installation complète ;
- vérifier l'import ;
- vérifier la sauvegarde/restauration ;
- valider Docker ;
- vérifier GitHub Actions ;
- identifier les derniers éléments documentaires.

### Répartition du travail

**Abdoulaye**

- supervision générale ;
- contrôle du cahier des charges ;
- documentation des résultats ;
- vérification de la cohérence globale ;
- préparation de la validation finale.

**Amine**

- tests techniques des scripts ;
- vérification de l'installation ;
- tests de l'import ;
- tests de sauvegarde/restauration ;
- vérification de Docker ;
- vérification du workflow GitHub Actions.

**Hoilid Zeghoubi**

- reproduction des procédures ;
- tests indépendants ;
- vérification des conteneurs ;
- exécution des scripts de son côté ;
- validation de sa compréhension de l'architecture ;
- remontée des résultats.

### Vérification Docker

```bash
docker compose ps
```

Résultat attendu et obtenu lors des tests :

```text
sae-dolibarr            Up
sae-dolibarr-postgres   Up (healthy)
```

Accès :

```text
http://localhost:8090
```

### Difficulté — cohérence du port

Une incohérence a été identifiée entre l'URL interne configurée et le port réellement publié.

Vérification :

```bash
docker compose config
```

La configuration a été harmonisée sur :

```text
DOLIBARR_URL_ROOT=http://localhost:8090
```

### Test anti-doublons

Une seconde exécution de l'import produit :

```text
Déjà présent : Entreprise Alpha
Déjà présent : Entreprise Beta
Déjà présent : Entreprise Gamma
Déjà présent : Fournisseur Delta
Déjà présent : Fournisseur Epsilon
```

La base reste à **5 tiers**.

### GitHub Actions

Workflow :

```text
.github/workflows/docker-image.yml
```

Il s'exécute sur les `push` et `pull_request` vers `main`.

Logique :

```text
checkout du dépôt
       ↓
docker build
       ↓
succès / échec
```

Une correction du chemin du Dockerfile a été nécessaire pendant la mise en place du workflow.

Le workflow valide actuellement la **construction de l'image Docker**. Il ne réalise pas de déploiement continu.

### Résultat de la séance

À l'issue de la dernière séance documentée :

- l'architecture Docker est stable ;
- l'installation est automatisée ;
- l'import CSV fonctionne ;
- les doublons sont gérés ;
- la sauvegarde/restauration est opérationnelle ;
- le build Docker est vérifié par GitHub Actions ;
- les procédures sont reproductibles par plusieurs membres.

---

## 5. Répartition synthétique des tâches

| Membre | Rôle | Responsabilités principales |
|---|---|---|
| Abdoulaye | Chef de projet | coordination, cahier des charges, documentation, Docker, suivi des tests, validation |
| Amine | Architecte systèmes/réseaux | architecture, Docker, PostgreSQL, scripts Bash, automatisation, tests techniques |
| Hoilid Zeghoubi | Administrateur systèmes/réseaux | prise en main progressive, reproduction des procédures, tests indépendants, validation |

La répartition n'est pas totalement cloisonnée : chaque membre participe aux tests et doit être capable d'expliquer l'architecture globale.

---

## 6. Analyse technique des éléments essentiels

Cette partie reprend volontairement les lignes ou mécanismes qui peuvent être questionnés à l'oral.

### 6.1 Dockerfile

Image de base :

```dockerfile
FROM php:8.2-apache
```

Elle fournit PHP et Apache dans la même image, ce qui correspond au besoin de Dolibarr.

Activation de `rewrite` :

```dockerfile
RUN a2enmod rewrite
```

Correction du répertoire servi par Apache :

```dockerfile
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/dolibarr/htdocs|' \
    /etc/apache2/sites-available/000-default.conf
```

Cette correction est directement liée au problème `403 Forbidden` rencontré.

### 6.2 Docker Compose

Dépendance au healthcheck :

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

Cela évite de lancer l'application avant que PostgreSQL soit réellement prêt.

Volumes utilisés :

```yaml
volumes:
  postgres_data:
  dolibarr_documents:
```

Ils permettent de conserver les données même si les conteneurs sont recréés.

### 6.3 `install.sh`

L'idée importante est que le script ne se contente pas de lancer Docker : il attend PostgreSQL et initialise Dolibarr.

La disponibilité PostgreSQL est vérifiée avec :

```text
pg_isready
```

Puis le script vérifie le résultat de l'installation avec notamment :

```text
275 tables Dolibarr
1 utilisateur
```

### 6.4 `import_csv.sh`

Le contrôle anti-doublon est effectué avant l'insertion :

```sql
SELECT COUNT(*)
FROM llx_societe
WHERE email = '<email>';
```

Les chaînes sont échappées avant construction de la requête afin de limiter les erreurs provoquées par des apostrophes dans les données.

Le POC reste volontairement limité aux **Tiers** conformément au cahier des charges.

### 6.5 `backup.sh`

Deux sauvegardes sont nécessaires :

```text
base PostgreSQL
+
documents Dolibarr
```

Sauvegarder uniquement PostgreSQL serait insuffisant car certains fichiers utilisés par Dolibarr sont stockés dans son répertoire de documents.

### 6.6 `restore.sh`

La restauration :

1. identifie la dernière sauvegarde cohérente ;
2. arrête temporairement Dolibarr ;
3. restaure PostgreSQL ;
4. restaure les documents ;
5. redémarre l'application ;
6. vérifie le nombre de Tiers.

---

## 7. Tests et validation

Les tests ne se limitent pas à constater que les fichiers existent. L'objectif est de vérifier qu'ils sont réellement exploitables.

### 7.1 Service web

```powershell
curl.exe -I http://localhost:8090
```

Résultat observé :

```text
HTTP/1.1 200 OK
Server: Apache/2.4.68 (Debian)
X-Powered-By: PHP/8.2.34
```

### 7.2 Import CSV

Résultat :

```text
Entreprise Alpha
Entreprise Beta
Entreprise Gamma
Fournisseur Delta
Fournisseur Epsilon
```

Soit :

```text
3 clients
2 fournisseurs
5 tiers
```

Une seconde exécution laisse toujours 5 Tiers.

### 7.3 Vérification d'une sauvegarde

Sauvegarde de base :

```text
database_2026-10-08_21-50-27.dump
```

Sauvegarde documentaire :

```text
documents_2026-10-08_21-50-27.tar.gz
```

Le dump a été contrôlé avec :

```bash
pg_restore -l backups/database_2026-10-08_21-50-27.dump | head
```

Résultat :

```text
dbname: dolibarr
TOC Entries: 2595
Format: CUSTOM
Dumped from database version: 16.15
```

L'archive documentaire a été vérifiée avec :

```bash
tar -tzf backups/documents_2026-10-08_21-50-27.tar.gz | head
```

Elle contient notamment :

```text
documents/
documents/export/
documents/import/
documents/societe/
documents/agenda/
documents/install.lock
```

### 7.4 Validation du PRA

La validation complète du PRA a été réalisée lors de la phase finale de vérification du projet, sans créer une séance supplémentaire dans ce suivi.

Simulation d'une perte de l'environnement :

```bash
docker compose down -v
```

Réinstallation :

```bash
bash scripts/install.sh
```

Résultat :

```text
Nombre de tables Dolibarr : 275
Nombre d'utilisateurs Dolibarr : 1
PostgreSQL : healthy
Dolibarr : accessible sur le port 8090
```

Restauration :

```bash
bash scripts/restore.sh
```

Résultat :

```text
Base PostgreSQL restaurée.
Documents restaurés.
Nombre de tiers restaurés : 5
Restauration terminée avec succès.
```

Le PRA démontre donc que l'environnement peut être reconstruit après suppression des volumes et que les données peuvent être récupérées.

---

## 8. Analyse de la base Dolibarr

L'installation automatisée a généré **275 tables** dans notre environnement.

Nous n'avons pas étudié les 275 tables individuellement : le POC étant limité aux Tiers, nous avons concentré l'analyse sur les tables utiles au projet.

### 8.1 `llx_user`

Cette table contient les utilisateurs de Dolibarr.

Champs étudiés :

| Champ | Utilité |
|---|---|
| `rowid` | identifiant interne |
| `login` | identifiant de connexion |
| `admin` | indique si le compte est administrateur |
| `statut` | indique l'état du compte |

### 8.2 `llx_societe`

Cette table contient les Tiers.

Correspondance avec le CSV :

| CSV | Colonne Dolibarr |
|---|---|
| `nom` | `nom` |
| `adresse` | `address` |
| `code_postal` | `zip` |
| `ville` | `town` |
| `telephone` | `phone` |
| `email` | `email` |
| type client | `client` |
| type fournisseur | `fournisseur` |
| code client | `code_client` |
| code fournisseur | `code_fournisseur` |

C'est cette table que `import_csv.sh` remplit directement pour notre POC.

---

## 9. Difficultés rencontrées et démarche de résolution

| Problème | Recherche / essais réalisés | Correction | Ce que nous avons appris |
|---|---|---|---|
| URL Dolibarr en 404 | test HTTP avec `wget --spider` | utilisation de la source officielle | vérifier une dépendance avant de modifier le code |
| `403 Forbidden` | inspection de l'arborescence et du `DocumentRoot` | Apache pointe vers `htdocs` | diagnostic Apache/application |
| Entrypoint introuvable | chemin, droits, shebang, fins de ligne | CRLF → LF + `.gitattributes` | compatibilité Windows/Linux |
| Docker/WSL | vérifications côté Windows et WSL | utilisation cohérente de Docker Desktop/WSL | différence hôte / environnement Linux |
| 8080 / 8090 incohérents | `docker compose config`, `curl` | configuration finale sur 8090 | lecture et validation d'une configuration |
| Risque de doublons CSV | seconde exécution de l'import | recherche par e-mail avant `INSERT` | rendre un import réexécutable |
| Sauvegarde potentiellement inutilisable | `pg_restore -l`, `tar -tzf` | contrôle avant restauration | une sauvegarde doit être testée |
| Reprise après perte | suppression volontaire des volumes | `install.sh` + `restore.sh` | principe concret d'un PRA |
| Workflow Docker | vérification des chemins dans le dépôt | correction du chemin du Dockerfile | fonctionnement d'une CI |

---
---
---

## 11. Sources techniques et traçabilité

Les sources indiquées dans le dépôt doivent correspondre aux ressources réellement utilisées.

### Sources principales

- Dolibarr : <https://github.com/Dolibarr/dolibarr>
- Téléchargements Dolibarr : <https://www.dolibarr.org/downloads.php>
- Dockerfile : <https://docs.docker.com/reference/dockerfile/>
- Docker Compose : <https://docs.docker.com/reference/compose-file/>
- PostgreSQL 16 — `pg_dump` : <https://www.postgresql.org/docs/16/app-pgdump.html>
- PostgreSQL 16 — `pg_restore` : <https://www.postgresql.org/docs/16/app-pgrestore.html>
- PostgreSQL — `pg_isready` : <https://www.postgresql.org/docs/16/app-pg-isready.html>
- GitHub Actions : <https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions>
- Git : <https://git-scm.com/docs>
- supports de cours Git/GitHub utilisés dans le cadre du BUT3.

Une assistance IA a été utilisée ponctuellement comme **outil d'aide au diagnostic, à la recherche de pistes et à la relecture**. Les solutions retenues ont ensuite été vérifiées, testées et adaptées dans l'environnement du projet.



---

## 12. État d'avancement final

| Fonctionnalité | État | Validation |
|---|---|---|
| Installation manuelle | ✅ Terminée | Dolibarr et PostgreSQL compris |
| Dockerfile | ✅ Terminé | image construite |
| Docker Compose | ✅ Terminé | 2 services fonctionnels |
| `install.sh` | ✅ Terminé | 275 tables, admin créé |
| Import CSV | ✅ Terminé | 5 Tiers importés |
| Anti-doublons | ✅ Terminé | deuxième import sans duplication |
| `backup.sh` | ✅ Terminé | dump + archive documents |
| `restore.sh` | ✅ Terminé | 5 Tiers restaurés |
| PRA | ✅ Validé | destruction + reconstruction + restauration |
| GitHub Actions | ✅ Fonctionnel | build Docker validé |


## 14. Bilan

Ce projet ne s'est pas limité à obtenir un Dolibarr fonctionnel. Il nous a surtout permis de comprendre comment passer d'une installation manuelle à une solution reproductible et testable.

Nous avons dû :

- comprendre une application existante ;
- analyser sa base PostgreSQL ;
- séparer l'application et le SGBD ;
- automatiser les opérations ;
- diagnostiquer plusieurs erreurs réelles ;
- vérifier la reproductibilité sur plusieurs environnements ;
- sauvegarder puis reconstruire complètement la solution ;
- mettre en place une première intégration continue.

La progression de Hoilid Zeghoubi à partir du 30/09 a également servi de test de transmission : une personne qui n'avait pas participé au début du projet a progressivement pu comprendre l'architecture puis reproduire les procédures.

La chaîne complète validée est :

```text
Installation
    ↓
Dockerisation
    ↓
Automatisation
    ↓
Import de 5 Tiers
    ↓
Sauvegarde
    ↓
Suppression de l'environnement
    ↓
Réinstallation
    ↓
Restauration
    ↓
5 Tiers récupérés
```

Le projet est donc techniquement fonctionnel et, surtout, les choix, erreurs, tests et corrections peuvent être expliqués par l'équipe.
