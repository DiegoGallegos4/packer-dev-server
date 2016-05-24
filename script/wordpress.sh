#! /usr/bin/env bash
DBHOST=localhost
WP_DBNAME="wordpress"
WP_USER="dgallegos"
WP_PASSWD="gallegos1991"
WP_PATH='/var/www/html'

APACHE_USER="www-data"

mkdir /home/${APACHE_USER}
chown ${APACHE_USER}:${APACHE_USER} /home/${APACHE_USER}
sed -i \
  "s/^\(${APACHE_USER}:.*\):\/var\/www:\/usr\/sbin\/nologin$/\1:\/home\/${APACHE_USER}:\/bin\/bash/" \
  /etc/passwd

echo -e "\n--- Downloading and uncompressing Wordpress ---\n"

wget https://wordpress.org/latest.tar.gz > /dev/null 2>&1
tar -xzvf latest.tar.gz 


# ----------------------------------------------------------------------------
# Install WP-CLI.
# ----------------------------------------------------------------------------

curl -sS -O \
  https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

mkdir -p "${WP_PATH}"
chown ${APACHE_USER}:${APACHE_USER} "${WP_PATH}"
chmod 755 "${WP_PATH}"

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
create database wp;
CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';

grant all on ${MYSQL_DATABASE}.* to '${MYSQL_USER}'@'localhost' identified by '${MYSQL_PASS}';

FLUSH PRIVILEGES;
EOF

cd ~/wordpress
cp wp-config-sample.php wp-config.php


sudo rsync -avP ~/wordpress/ /var/www/html/
