#!/bin/bash

if [ -z "$SERVERNAME" ]; then
    SERVERNAME="$HOSTNAME"
fi
export SERVERNAME

# Create Apache patchman configuration file depending on environment variable USE_SSL and
# SERVERNAME.
/usr/bin/erb -T- /root/patchman_apache_conf.erb > /etc/apache2/sites-available/patchman.conf

# Enable SSL Module
if [ "$USE_SSL" == "YES" ]; then
    /usr/sbin/a2enmod ssl
fi

# Enable patchman site
/usr/sbin/a2dissite 000-default
/usr/sbin/a2ensite  patchman

/usr/sbin/apache2ctl -DFOREGROUND

# Send client report every 24 hours
while true; do

    if [ "$USE_SSL" == "YES" ]; then
        patchman-client -s https://${SERVERNAME}/patchman
    else
        patchman-client -s http://${SERVERNAME}/patchman
    fi

    sleep 86400

done
