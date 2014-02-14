#!/usr/bin/env bash

echo ">>> Installing Apache Server"

# Import variables, used to determine where to fetch
# the vhost creation script.
source /tmp/vaprobash_exports.sh

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

[[ -z "$VAPROBASH_GIT_USER" ]] && { echo "!!! Could not find Vaprobash git details. Check the Vagrant file."; exit 1; }

# Add repo for latest FULL stable Apache
# (Required to remove conflicts with PHP PPA due to partial Apache upgrade within it)
sudo add-apt-repository -y ppa:ondrej/apache2

# Update Again
sudo apt-get update

# Install Apache
sudo apt-get install -y apache2-mpm-event libapache2-mod-fastcgi

echo ">>> Configuring Apache"

# Apache Config
sudo a2enmod rewrite actions
curl https://raw.github.com/$VAPROBASH_GIT_USER/$VAPROBASH_GIT_REPO/$VAPROBASH_GIT_BRANCH/scripts/apache_vhost.sh > vhost
sudo chmod guo+x vhost
sudo mv vhost /usr/local/bin

# Set server name from config or default
server_name="$1.xip.io"

if [ "$2" ]; then
    server_name=$2
fi

echo ">>> Apache server name set to $server_name"

# Set document root from config or default
document_root="/vagrant"

if [ "$3" ]; then
    document_root=$3
fi

echo ">>> Apache document root set to $document_root"

# Set server alias
server_aliases="*"

if [ "$4" ]; then
    # This gets all arguments passed in from the 4th onwards
    server_aliases=${@:4}
fi

echo ">>> Apache server alias set to \"$server_aliases\""

# Create a virtualhost to start
sudo vhost -s $server_name -d $document_root -a "$server_aliases"

# Disable the default virtual host
sudo a2dissite 000-default

# PHP Config for Apache
cat > /etc/apache2/conf-available/php5-fpm.conf << EOF
<IfModule mod_fastcgi.c>
        AddHandler php5-fcgi .php
        Action php5-fcgi /php5-fcgi
        Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
        FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization
        <Directory /usr/lib/cgi-bin>
                Options ExecCGI FollowSymLinks
                SetHandler fastcgi-script
                Require all granted
        </Directory>
</IfModule>
EOF
sudo a2enconf php5-fpm

sudo service apache2 restart
