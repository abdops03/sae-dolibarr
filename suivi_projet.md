# Suivi du projet SAE 51 : Installation d'un ERP/CRM Dolibarr

* **Membres du binôme :** [Abdoualye Gaye] (Chef de projet), [AEl Khalki Amine] (Rédacteur technique, architecte réseaux)
* **Groupe :** BUT3 R&T - [Groupe B]
* **Dépôt Git :** `sae-dolibarr`

---

## Séance 1 - [22/09/2026]

### Objectifs prévus pour la séance

* Initialiser le dépôt Git et son arborescence de travail.
* Débuter la phase 1 : installation manuelle/test de Dolibarr et de PostgreSQL sur une machine Debian.

### Travail réalisé

* Initialisation du dépôt Git du projet `sae-dolibarr`.
* Mise en place du suivi de projet avec le fichier `suivi_projet.md`.
* Installation et vérification d'Apache2 sur la machine Debian/WSL.
* Vérification du fonctionnement du serveur web avec :

  ```bash
  curl -I http://localhost
  ```
* Vérification de l'écoute d'Apache sur le port 80 avec :

  ```bash
  sudo ss -ltnp | grep ':80'
  ```
* Vérification du service Apache :

  ```bash
  sudo systemctl status apache2
  ```
* Vérification de PHP :

  ```bash
  php --version
  ```
* Vérification du module PHP chargé par Apache :

  ```bash
  apache2ctl -M | grep php
  ```
* Vérification des extensions PHP nécessaires avec :

  ```bash
  php -m
  ```
* Téléchargement de **Dolibarr 24.0.1** au format `.tgz`.
* Extraction et vérification du contenu de Dolibarr, notamment du répertoire `htdocs`.
* Analyse de la configuration Apache et identification du `DocumentRoot` :

  ```text
  /var/www/html
  ```
* Installation de Dolibarr sous :

  ```text
  /var/www/html/dolibarr
  ```
* Mise en place du répertoire de documents Dolibarr :

  ```text
  /var/lib/dolibarr/documents
  ```
* Attribution des droits au serveur web avec `www-data`.
* Lancement de l'interface d'installation web de Dolibarr.
* Configuration manuelle de Dolibarr 24.0.1.
* Configuration de PostgreSQL comme SGBD.
* Création du compte administrateur Dolibarr et d'un compte utilisateur.
* Vérification de l'accès à PostgreSQL avec :

  ```bash
  psql -h localhost -p 5432 -U dolibarr -d dolibarr
  ```
* Vérification de la table des utilisateurs :

  ```sql
  SELECT rowid, login, lastname, firstname, employee, admin, statut
  FROM llx_user;
  ```
* Découverte du fonctionnement de la base Dolibarr et du rôle du champ `rowid`.
* Vérification de la table `llx_societe` et constat qu'aucun tiers n'était encore présent :

  ```sql
  SELECT rowid, nom, client, fournisseur, status
  FROM llx_societe
  LIMIT 10;
  ```

---

## Séance 2 - [28/09/2026]

### Objectifs prévus pour la séance

* Poursuivre la découverte de Dolibarr.
* Étudier les possibilités d'importation des données existantes.
* Commencer à réfléchir à l'automatisation de l'installation.
* Préparer la future dockerisation de Dolibarr et PostgreSQL.
* Organiser le dépôt Git pour les futurs scripts d'installation, d'importation et de sauvegarde.

### Travail réalisé

#### 1. Découverte de l'importation des données

* Accès au menu **Outils → Importations / Exportations** de Dolibarr.

* Découverte de l'assistant d'importation intégré.

* Identification des différents lots de données pouvant être importés, notamment :

  * utilisateurs et groupes ;
  * adhérents ;
  * tiers ;
  * contacts et adresses ;
  * comptes bancaires ;
  * commerciaux ;
  * commandes ;
  * lignes de commandes ;
  * événements et autres données.

* Étude du format CSV attendu par Dolibarr pour l'importation des utilisateurs.

* Préparation d'un exemple de données utilisateur permettant de tester l'importation CSV.

#### 2. Étude de la base PostgreSQL

* Connexion directe à la base `dolibarr` avec PostgreSQL.

* Observation des tables créées par Dolibarr.

* Consultation de la table :

  ```text
  llx_user
  ```

* Observation des utilisateurs présents dans la base :

  * `admin`
  * `usertest`
  * `modou.diop`

* Identification du champ `rowid` comme identifiant interne des enregistrements.

* Consultation de la table :

  ```text
  llx_societe
  ```

* Constat qu'aucun tiers n'était encore présent dans cette table.

#### 3. Comparaison des deux méthodes d'importation

Deux possibilités prévues dans le cahier des charges ont été étudiées :

**Méthode 1 : importation via Dolibarr**

```text
CSV
 ↓
Menu Outils
 ↓
Importation Dolibarr
 ↓
Tables Dolibarr
```

Cette méthode est relativement simple et permet à Dolibarr de contrôler l'importation, mais elle nécessite une intervention dans l'interface.

**Méthode 2 : importation directe dans PostgreSQL**

```text
CSV
 ↓
Script d'importation
 ↓
PostgreSQL
 ↓
Tables llx_*
```

Cette méthode est plus complexe car il faut comprendre précisément la structure de la base Dolibarr et les relations entre les tables, mais elle présente un intérêt pour l'automatisation demandée dans le cahier des charges.

#### 4. Préparation de la dockerisation

Une première arborescence de travail a été créée dans le dépôt :

```text
sae-dolibarr/
├── backups/
├── data/
│   └── csv/
├── docker/
│   ├── dolibarr/
│   └── postgres/
├── docs/
└── scripts/
```

Cette organisation est destinée à accueillir progressivement :

* les fichiers liés aux conteneurs Docker ;
* les fichiers CSV provenant de l'ancien ERP/CRM ;
* les scripts d'installation ;
* les scripts d'importation ;
* les sauvegardes ;
* la documentation du projet.

#### 5. Vérification de Git

* Vérification de l'état du dépôt :

  ```bash
  git status
  ```
* Vérification de l'historique :

  ```bash
  git log --oneline -3
  ```
* Confirmation que la branche de travail est :

  ```text
  test
  ```
* Confirmation que la branche locale est synchronisée avec :

  ```text
  origin/test
  ```

#### 6. Préparation de Docker

* Vérification de Docker Desktop sous Windows.
* Docker est installé et fonctionnel côté Windows :

  ```text
  Docker version 29.8.0
  Docker Compose version v5.5.1
  ```
* Constat que Docker n'est pas encore accessible depuis la distribution WSL utilisée pour le projet.
* Identification de la nécessité d'activer l'intégration **Docker Desktop / WSL2** avant de commencer la dockerisation.

### État d'avancement à la fin de la séance

La phase de découverte et d'installation manuelle de Dolibarr est fonctionnelle.

L'environnement actuel permet :

```text
Apache
   ↓
Dolibarr 24.0.1
   ↓
PostgreSQL
```

La prochaine étape sera de mettre en place progressivement une architecture Docker séparant :

```text
┌─────────────────┐
│    Dolibarr     │
│  Apache + PHP   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   PostgreSQL    │
│      SGBD       │
└─────────────────┘
```

Puis seront développés les scripts prévus par le cahier des charges :

* `install.sh` pour automatiser l'installation ;
* `import_csv.sh` pour automatiser l'importation des données ;
* une procédure de sauvegarde/restauration permettant de répondre au besoin de PRA.

## Séance 3 - [05/10/2026]

### Objectifs prévus pour la séance

* Commencer concrètement la dockerisation de Dolibarr et PostgreSQL.
* Mettre en place une architecture avec deux conteneurs séparés.
* Créer notre propre `Dockerfile` pour Dolibarr plutôt que d'utiliser directement une image Dolibarr préexistante.
* Créer un fichier `docker-compose.yml` permettant d'orchestrer les différents services.
* Vérifier la communication entre Dolibarr et PostgreSQL.
* Tester l'accès à Dolibarr depuis le navigateur.
* Commencer à résoudre les problèmes liés à la configuration Apache et aux anciens services installés sur la machine.
* Versionner les fichiers Docker dans le dépôt Git afin de permettre au binôme de travailler sur la même configuration.

### Travail réalisé

#### 1. Vérification de l'environnement Docker

Docker a été vérifié depuis l'environnement Linux/WSL2.

Versions utilisées :

```text
Docker version 29.8.0
Docker Compose version v5.5.1
```

Une différence mineure de version Docker existe avec la machine du binôme, mais cette différence ne bloque pas l'utilisation du projet :

```text
Machine d'Abdoulaye : Docker 29.8.0
Machine du binôme : Docker 29.8.1
```

Le projet utilise Docker Compose afin de limiter l'impact de ces différences de version.

#### 2. Choix de l'architecture Docker

Conformément au cahier des charges, le choix a été fait de séparer Dolibarr et PostgreSQL dans deux conteneurs.

Architecture retenue :

```text
                  Docker Compose
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
┌───────────────────┐     ┌───────────────────┐
│     Dolibarr      │     │    PostgreSQL     │
│                   │     │                   │
│ Apache + PHP      │────▶│ PostgreSQL 16     │
│ Dolibarr 24.0.1   │     │                   │
└───────────────────┘     └───────────────────┘
          │
          │ port publié
          ▼
     localhost:8090
```

Cette architecture permet de respecter la séparation entre l'application ERP/CRM et son SGBD.

Elle facilite également :

* la maintenance des services ;
* les sauvegardes de la base de données ;
* le remplacement d'un service indépendamment de l'autre ;
* la reproduction de l'environnement sur une autre machine.

#### 3. Création de notre propre Dockerfile

Un `Dockerfile` a été créé dans :

```text
docker/dolibarr/Dockerfile
```

L'objectif est de construire nous-mêmes l'image Docker de Dolibarr.

L'image repose sur une base Debian avec Apache et PHP.

Les principales étapes du Dockerfile sont :

```text
Image de base
     ↓
Installation d'Apache
     ↓
Installation de PHP et des extensions nécessaires
     ↓
Téléchargement de Dolibarr
     ↓
Extraction des fichiers
     ↓
Installation dans /var/www/html/dolibarr
     ↓
Configuration des droits
     ↓
Lancement d'Apache
```

Cette approche répond à l'objectif du cahier des charges de créer un environnement reproductible et automatisable.

#### 4. Problème rencontré lors du téléchargement de Dolibarr

Une première URL GitHub utilisée pour récupérer Dolibarr 24.0.1 renvoyait une erreur `404 Not Found`.

Test réalisé :

```bash
wget -S --spider https://github.com/Dolibarr/dolibarr/releases/download/24.0.1/dolibarr-24.0.1.zip
```

Résultat :

```text
HTTP/1.1 404 Not Found
```

Une autre source officielle de téléchargement a ensuite été testée :

```text
https://www.dolibarr.org/files/stable/standard/dolibarr-24.0.1.zip
```

Cette URL a correctement répondu :

```text
HTTP/1.1 200 OK
Content-Type: application/zip
```

Le Dockerfile a donc été adapté pour utiliser cette source.

Cette étape a permis de vérifier que le problème ne venait pas de la variable `${DOLIBARR_VERSION}`, mais de l'URL de téléchargement utilisée.

#### 5. Création du service PostgreSQL

Un second service a été défini dans Docker Compose pour PostgreSQL.

Version utilisée :

```text
postgres:16
```

Le conteneur créé est :

```text
sae-dolibarr-postgres
```

Le démarrage des logs PostgreSQL a permis de vérifier que la base était correctement initialisée :

```text
database system is ready to accept connections
```

PostgreSQL écoute sur le port :

```text
5432
```

Le port n'a pas besoin d'être publié sur la machine hôte pour que Dolibarr puisse communiquer avec PostgreSQL, puisque les deux services communiquent à travers le réseau Docker Compose.

#### 6. Création du service Dolibarr

Le conteneur Dolibarr créé est :

```text
sae-dolibarr
```

L'image construite localement est :

```text
sae-dolibarr:24.0.1
```

Vérification des conteneurs :

```bash
docker compose ps
```

Résultat obtenu :

```text
NAME                    IMAGE                 SERVICE
sae-dolibarr            sae-dolibarr:24.0.1  dolibarr
sae-dolibarr-postgres   postgres:16           postgres
```

Les deux conteneurs sont en fonctionnement.

#### 7. Vérification des logs

Les logs Docker Compose ont été consultés avec :

```bash
docker compose logs --tail=30
```

Les logs PostgreSQL indiquent que le serveur est prêt à accepter les connexions.

Les logs Apache indiquent également que le serveur web démarre correctement dans le conteneur :

```text
Apache/2.4.68 (Debian) PHP/8.2.34 configured
```

Le serveur Apache fonctionne donc à l'intérieur du conteneur Dolibarr.

#### 8. Vérification de l'installation de Dolibarr dans le conteneur

Le contenu du répertoire web a été vérifié avec :

```bash
docker exec sae-dolibarr ls -la /var/www/html/
```

Le résultat montre :

```text
/var/www/html/
└── dolibarr/
```

Puis le contenu de Dolibarr a été vérifié :

```bash
docker exec sae-dolibarr ls -la /var/www/html/dolibarr/
```

Le répertoire contient notamment :

```text
htdocs/
doc/
dev/
scripts/
README.md
COPYING
```

Le répertoire principal de l'application web Dolibarr est donc :

```text
/var/www/html/dolibarr/htdocs
```

#### 9. Problème rencontré avec le DocumentRoot Apache

Lors du premier test, l'accès à :

```text
http://localhost:8090
```

renvoyait :

```text
HTTP/1.1 403 Forbidden
```

L'analyse de la configuration Apache a montré que le `DocumentRoot` était configuré sur :

```text
/var/www/html/dolibarr
```

alors que les fichiers web de Dolibarr sont situés dans :

```text
/var/www/html/dolibarr/htdocs
```

La configuration Apache doit donc être adaptée afin de servir directement le répertoire `htdocs`.

La configuration souhaitée est :

```text
DocumentRoot /var/www/html/dolibarr/htdocs
```

Cette modification est intégrée au travail sur le Dockerfile afin que la configuration soit automatiquement reproduite lors de la construction de l'image.

#### 10. Nettoyage de l'ancien environnement Apache/Nginx

L'ancien environnement de test sur la machine WSL utilisait également des services web installés directement sur le système.

Un ancien service Apache était encore présent et avait précédemment rencontré un conflit sur le port 80 :

```text
Address already in use
could not bind to address 0.0.0.0:80
```

Comme Apache doit maintenant être exécuté dans le conteneur Docker, l'ancien service Apache système a été désactivé :

```bash
sudo systemctl disable apache2
sudo systemctl stop apache2
```

Le serveur web utilisé pour le projet est désormais celui du conteneur Docker.

L'ancien environnement Nginx n'est également plus utilisé pour le projet.

#### 11. Gestion du port d'accès

Afin d'éviter les conflits avec les anciens services web présents sur la machine, le port du conteneur Apache est publié sur un port de la machine hôte.

Configuration retenue :

```text
Machine hôte : 8090
        ↓
Conteneur Dolibarr : 80
```

La correspondance est donc :

```text
0.0.0.0:8090 → port 80 du conteneur
```

Vérification avec :

```bash
docker compose ps
```

Le port apparaît sous la forme :

```text
0.0.0.0:8090->80/tcp
```

L'accès à l'application est donc prévu avec :

```text
http://localhost:8090
```

#### 12. Vérification de Git et collaboration

Le dépôt commun utilisé par les deux membres du binôme est :

```text
sae-dolibarr
```

La branche de travail utilisée est :

```text
test
```

Les modifications liées à la dockerisation sont versionnées dans Git afin que le binôme puisse récupérer la même configuration.

Les commandes utilisées sont notamment :

```bash
git status
git add
git commit
git push
git pull
```

Une attention particulière a été portée à la sélection des fichiers avant les commits afin de ne pas envoyer par erreur des fichiers temporaires ou des fichiers de test.

### État d'avancement à la fin de la séance

À la fin de la séance, la première version de l'environnement Docker est fonctionnelle.

Les deux services sont démarrés :

```text
┌──────────────────────────┐
│ Docker Compose           │
│                          │
│  ┌────────────────────┐  │
│  │ sae-dolibarr       │  │
│  │ Apache + PHP       │  │
│  │ Dolibarr 24.0.1   │  │
│  └─────────┬──────────┘  │
│            │              │
│            ▼              │
│  ┌────────────────────┐  │
│  │ sae-dolibarr-      │  │
│  │ postgres            │  │
│  │ PostgreSQL 16       │  │
│  └────────────────────┘  │
└──────────────────────────┘
```

Les principaux points restant à finaliser sont :

* corriger définitivement le `DocumentRoot` Apache vers `htdocs` ;
* valider l'accès complet à l'interface Dolibarr depuis `http://localhost:8090` ;
* vérifier la connexion de Dolibarr au conteneur PostgreSQL ;
* mettre en place les volumes persistants ;
* préparer les scripts d'installation ;
* préparer le script d'importation CSV ;
* préparer les procédures de sauvegarde et de restauration ;
* tester la reconstruction complète de l'environnement sur une machine vierge ;
* documenter les commandes nécessaires au déploiement pour le binôme.

La prochaine étape sera donc de stabiliser l'image Docker Dolibarr et le fichier `docker-compose.yml`, puis de commencer l'automatisation de l'importation des données et des sauvegardes.
