FROM php:8.2-apache

ARG DOLIBARR_VERSION=24.0.1

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
        zip \
        opcache \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

RUN wget -q \
    https://www.dolibarr.org/files/stable/standard/dolibarr-${DOLIBARR_VERSION}.zip \
    -O /tmp/dolibarr.zip \
    && unzip /tmp/dolibarr.zip -d /tmp \
    && mv /tmp/dolibarr-${DOLIBARR_VERSION} /var/www/html/dolibarr \
    && rm /tmp/dolibarr.zip

RUN mkdir -p /var/lib/dolibarr/documents \
    && chown -R www-data:www-data /var/www/html/dolibarr \
    && chown -R www-data:www-data /var/lib/dolibarr

RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/dolibarr|' \
    /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD ["apache2-foreground"]