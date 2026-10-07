#!/bin/sh
set -eu

CONF="/var/www/html/dolibarr/htdocs/conf/conf.php"

if [ ! -f "$CONF" ]; then
    echo "Création automatique de conf.php..."

    cat > "$CONF" <<PHP
<?php
\$dolibarr_main_url_root="${DOLIBARR_URL_ROOT}";
\$dolibarr_main_document_root="/var/www/html/dolibarr/htdocs";
\$dolibarr_main_data_root="/var/lib/dolibarr/documents";

\$dolibarr_main_db_host="${DOLIBARR_DB_HOST}";
\$dolibarr_main_db_port="${DOLIBARR_DB_PORT}";
\$dolibarr_main_db_name="${DOLIBARR_DB_NAME}";
\$dolibarr_main_db_user="${DOLIBARR_DB_USER}";
\$dolibarr_main_db_pass="${DOLIBARR_DB_PASSWORD}";
\$dolibarr_main_db_type="pgsql";

\$dolibarr_main_db_character_set="utf8";
\$dolibarr_main_db_collation="";

\$dolibarr_main_authentication="dolibarr";
\$dolibarr_main_prod="0";

\$dolibarr_main_instance_unique_id="${DOLIBARR_INSTANCE_UNIQUE_ID}";
PHP

    chown www-data:www-data "$CONF"
    chmod 640 "$CONF"

    echo "conf.php créé."
else
    echo "conf.php déjà présent."
fi

exec "$@"
