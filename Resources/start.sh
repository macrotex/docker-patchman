#!/bin/bash

## Step 1. Set some defaults and do error checking.
if [ -z "$SERVERNAME" ]; then
    SERVERNAME="$HOSTNAME"
fi
export SERVERNAME

if [ -z "$PROCESS_REPORT_SLEEP_SECONDS" ]; then
    PROCESS_REPORT_SLEEP_SECONDS=186400
fi
export PROCESS_REPORT_SLEEP_SECONDS

# Set HTTP_PORT to 80 if not set.
if [ -z "$HTTP_PORT" ]; then
    HTTP_PORT=80
fi
export HTTP_PORT

# Check that USE_SSL is set to either YES or NO. Default to YES.
if [ -z "$USE_SSL" ]; then
    USE_SSL="YES"
else
    # Make USE_SSL uppercase
    USE_SSL=${USE_SSL^^}
fi

usessl_rx='^(YES|NO)$'
if [[ ! "$USE_SSL" =~ $usessl_rx ]]; then
    echo "error: USE_SSL must be set to either 'YES' or 'NO'"
    exit 1
fi
export USE_SSL

## Step 2. Create Apache patchman configuration file depending on
## environment variables USE_SSL, SERVERNAME, and HTTP_PORT.
/usr/bin/erb -T- /root/patchman_apache_conf.erb > /etc/apache2/sites-available/patchman.conf

# Enable SSL Module
if [ "$USE_SSL" == "YES" ]; then
    /usr/sbin/a2enmod ssl
fi


# Enable patchman site
/usr/sbin/a2dissite 000-default
/usr/sbin/a2ensite  patchman

/usr/sbin/apache2ctl -DFOREGROUND

# Process reports, sleep, then repeat.
while true; do

    # Send our own report.
    if [ "$USE_SSL" == "YES" ]; then
        patchman-client -s https://${SERVERNAME}/patchman
    else
        patchman-client -s http://${SERVERNAME}/patchman
    fi

    sleep "$PROCESS_REPORT_SLEEP_SECONDS"

    # Process reports.
    /root/process-reports.sh

done
