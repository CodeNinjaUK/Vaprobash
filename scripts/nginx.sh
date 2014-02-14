#!/usr/bin/env bash

echo ">>> Installing Nginx"

source /tmp/vaprobash_exports.sh

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

[[ -z "$VAPROBASH_GIT_USER" ]] && { echo "!!! Could not find Vaprobash git details. Check the Vagrant file."; exit 1; }

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -y nginx

echo ">>> Configuring Nginx"

# Set server name from config or default
server_name="$1.xip.io"

if [ "$2" ]; then
    server_name=$2
fi

echo ">>> Nginx server name set to $server_name"

# Set document root from config or default
document_root="/vagrant"

if [ "$3" ]; then
    document_root=$3
fi

echo ">>> Nginx document root set to $document_root"

# Set server alias
if [ "$4" ]; then
    # This gets all arguments passed in from the 4th onwards
    server_aliases=${@:4}
fi

echo ">>> Nginx alias set to \"$server_aliases\""

# Turn off sendfile to be more compatible with Windows, which can't use NFS
sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

# Nginx enabling and disabling virtual hosts
curl https://gist.github.com/fideloper/8261546/raw/ngxen > ngxen
curl https://gist.github.com/fideloper/8261546/raw/ngxdis > ngxdis

# setup the vhost generator script for nginx
curl https://raw.github.com/$VAPROBASH_GIT_USER/$VAPROBASH_GIT_REPO/$VAPROBASH_GIT_BRANCH/scripts/nginx_vhost.sh > ngxvhost


sudo chmod guo+x ngxen ngxdis ngxvhost
sudo chown root:root ngxvhost
sudo mv ngxvhost ngxen ngxdis /usr/local/bin

echo "ngxvhost -s $server_name -d $document_root -a \"$server_aliases\""

# Create a virtualhost to start
sudo ngxvhost -s $server_name -d $document_root -a "$server_aliases"

# Disable the default virtual host
sudo ngxdis default

# PHP Config for Nginx
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

sudo service php5-fpm restart
sudo service nginx restart
