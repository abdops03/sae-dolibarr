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
