#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
    echo "You must be root: \"sudo vhost\""
    exit 1
fi

# May need to run this as sudo!
# I have it in /usr/local/bin and run command 'vhost' from anywhere, using sudo.

#
#   Show Usage, Output to STDERR
#

function show_usage {
cat <<- _EOF_

Create a new vHost in Ubuntu Server
Assumes /etc/apache2/sites-available and /etc/apache2/sites-enabled setup used

    -d    DocumentRoot - i.e. /var/www/yoursite
    -h    Help - Show this menu.
    -s    ServerName - i.e. example.com or sub.example.com
    -a    ServerAliases - i.e. "www.example.com othersub.example.com". Default: *
_EOF_
exit 1
}


#
#   Output vHost skeleton, fill with userinput
#   To be outputted into new file
#
function create_vhost {
cat <<- _EOF_
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $ServerName
    ServerAlias $ServerAlias

    DocumentRoot $DocumentRoot

    <Directory $DocumentRoot>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$ServerName-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/$ServerName-access.log combined


</VirtualHost>
_EOF_
}

#Parse flags
while getopts "d:s:a:" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        d)
            DocumentRoot=$OPTARG
            ;;
        s)
            ServerName=$OPTARG
            ;;
        a)
            ServerAlias=$OPTARG
            ;;
        *)
            show_usage
            ;;
    esac
done

#Check for required fields.
if [[ -z $DocumentRoot ]] || [[ -z $ServerName ]]; then
    echo ">>> ERROR: Document Root (-d) and Server Name (-s) are required"
	show_usage
fi

if [ ! -d $DocumentRoot ]; then
    mkdir -p $DocumentRoot
    #chown USER:USER $DocumentRoot #POSSIBLE IMPLEMENTATION, new flag -u ?
fi

if [ -f "$DocumentRoot/$ServerName.conf" ]; then
    echo 'vHost already exists. Aborting'
    show_usage
else
    create_vhost > /etc/apache2/sites-available/${ServerName}.conf
    cd /etc/apache2/sites-available/ && a2ensite ${ServerName}.conf #Enable site
    service apache2 reload #Optional implementation
fi
