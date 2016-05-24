#! /usr/bin/env bash

# Variables
APPENV=local
DBHOST=localhost
DBNAME="test"
DBUSER="dev"
DBPASSWD="dev"

echo -e "\n--- Mkay, installing now... ---\n"

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential proftd rsync python-software-properties git > /dev/null 2>&1

echo -e "\n--- Add some repos to update our distro ---\n"
add-apt-repository ppa:ondrej/php5 > /dev/null 2>&1
add-apt-repository ppa:chris-lea/node.js > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
apt-get -y install mysql-server-5.5 phpmyadmin > /dev/null 2>&1

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"


echo -e "\n--- Install Postgres specific packages and settings ---\n"
apt-get -y install postgresql-9.4 postgresql-client-9.4 > /dev/null 2>&1


echo -e "\n--- Installing PHP-specific packages ---\n"
apt-get -y install php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php5-pgsql php-apc > /dev/null 2>&1


echo -e "\n--- Installing Nginx ---\n"
systemctl stop apache2.service
apt-get -y install nginx-full
# cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
# server {
#  listen 4000;
#  listen [::]:4000;

#  server_name example.com;

#  root /var/www/example.com;
#  index index.html;

#  location / {
#          try_files $uri $uri/ =404;
#  }
# }
# EOF
systemctl start apache2.service

echo -e "\n--- Enabling mod-rewrite ---\n"
a2enmod rewrite > /dev/null 2>&1

echo -e "\n--- Allowing Apache override to all ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

echo -e "\n--- Turn off disabled pcntl functions so we can use Boris ---\n"
sed -i "s/disable_functions = .*//" /etc/php5/cli/php.ini

echo -e "\n--- Configure Apache to use phpmyadmin ---\n"
echo -e "\n\nListen 81\n" >> /etc/apache2/ports.conf
cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
<VirtualHost *:81>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/phpmyadmin
    DirectoryIndex index.php
    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin-error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin-access.log combined
</VirtualHost>
EOF

a2enconf phpmyadmin > /dev/null 2>&1

echo -e "\n--- Add environment variables to Apache ---\n"
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    ServerName test.dev
    DocumentRoot /var/www/test.dev
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory "var/www/html">
      RewriteEngine On
      RewriteCond %{REQUEST_FILENAME} !-f
      RewriteCond %{REQUEST_FILENAME} !-d
      RewriteRule . index.php
    </Directory>
</VirtualHost>
EOF

echo -e "\n--- Restarting Apache ---\n"
systemctl restart apache2 > /dev/null 2>&1

echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
mv composer.phar /usr/local/bin/composer

echo -e "\n--- Changing permissions on composer dirs and /var/www ---\n"
chown -R vagrant:vagrant /home/vagrant/.cache/
chown -R vagrant:vagrant /home/vagrant/.composer/
chown -R www-data:www-data /var/www/
usermod -G www-data vagrant

# echo -e "\n--- Locales ---\n"
# locale-gen "en_US.UTF-8"
# dpkg-reconfigure locales

echo -e "\n--- Creating Yii Project ---\n"
composer global require "fxp/composer-asset-plugin:~1.1.1" 
composer create-project --prefer-dist yiisoft/yii2-app-advanced test.dev> /dev/null 2>&1
composer self-update > /dev/null 2>&1


echo -e "\n--- Installing NodeJS and NPM ---\n"
apt-get -y install nodejs > /dev/null 2>&1
ln -s /usr/bin/nodejs /usr/bin/node

curl --silent -0 -L https://npmjs.org/install.sh | sh > /dev/null 2>&1

echo -e "\n--- Installing javascript components ---\n"
npm install -g gulp bower > /dev/null 2>&1
npm install -g pm2 > /dev/null 2>&1
npm install -g nodemon > /dev/null 2>&1

