# Image de base : PHP 8.2 avec Apache
FROM php:8.2-apache

# Version de Dolibarr utilisée dans le projet
ARG DOLIBARR_VERSION=24.0.1

# Installation des dépendances système et des extensions PHP nécessaires
# à Dolibarr et à la connexion PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    unzip \
    wget \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        gd \
        intl \
        pdo \
        pdo_pgsql \
        pgsql \
        zip \
        opcache \
    && rm -rf /var/lib/apt/lists/*

# Activation du module Apache rewrite utilisé par Dolibarr
RUN a2enmod rewrite

# Téléchargement et installation de Dolibarr
RUN wget -q \
    https://www.dolibarr.org/files/stable/standard/dolibarr-${DOLIBARR_VERSION}.zip \
    -O /tmp/dolibarr.zip \
    && unzip /tmp/dolibarr.zip -d /tmp \
    && mv /tmp/dolibarr-${DOLIBARR_VERSION} /var/www/html/dolibarr \
    && rm /tmp/dolibarr.zip

# Création du répertoire destiné aux documents Dolibarr
# et attribution des droits à l'utilisateur Apache
RUN mkdir -p /var/lib/dolibarr/documents \
    && chown -R www-data:www-data /var/www/html/dolibarr \
    && chown -R www-data:www-data /var/lib/dolibarr

# Configuration d'Apache pour utiliser le répertoire htdocs de Dolibarr
# comme racine du site web
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/dolibarr/htdocs|' \
    /etc/apache2/sites-available/000-default.conf

# Copie du script d'entrée dans l'image Docker
# Ce script prépare notamment la configuration de connexion à PostgreSQL
COPY docker-entrypoint.sh /usr/local/bin/dolibarr-entrypoint.sh

# Rend le script d'entrée exécutable
RUN chmod +x /usr/local/bin/dolibarr-entrypoint.sh

# Script exécuté au démarrage du conteneur
ENTRYPOINT ["dolibarr-entrypoint.sh"]

# Port HTTP utilisé par Apache dans le conteneur
EXPOSE 80

# Démarrage d'Apache au premier plan
CMD ["apache2-foreground"]
