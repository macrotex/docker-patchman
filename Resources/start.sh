#!/bin/bash

### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##
### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##
# Get the number of seconds until next report run. Sets the variable
# PROCESS_REPORT_SLEEP_SECONDS. Requires that the variable RUN_TIMES_ARRAY
# be set to an array of times, for example, ("02:10" "10:15" "12:04")
function time_to_sleep()
{
    local secs_to_sleep_min
    local secs_to_sleep
    local today_run_time_cmd
    local tomorrow_run_time_cmd
    local today_run_time
    local tomorrow_run_time
    local now

    secs_to_sleep_min=86400
    for run_time in ${RUN_TIMES[@]}; do

        today_run_time_cmd="date -d 'today $run_time' +%s"
        tomorrow_run_time_cmd="date -d 'tomorrow $run_time' +%s"

        today_run_time=$(eval $today_run_time_cmd)
        tomorrow_run_time=$(eval $tomorrow_run_time_cmd)
        now=$(date +%s)

        if (( today_run_time < now )); then
            # Today's run time is already past, so use tomorrows run time.
            secs_to_sleep="$(($tomorrow_run_time - $now))"
        else
            # Today's run time has not past, so use today's run time.
            secs_to_sleep="$(($today_run_time - $now))"
        fi

        # Is this the minimum secs_to_sleep we have seen so far?
        if (( secs_to_sleep < secs_to_sleep_min )); then
            secs_to_sleep_min="$secs_to_sleep"
        fi
    done
    PROCESS_REPORT_SLEEP_SECONDS="$secs_to_sleep_min"
}
### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##
### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##


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

# Create RUN_TIMES_ARRAY from RUN_TIMES. If not defined, use a reasonable
# default.
if [ -z "$RUN_TIMES" ]; then
    RUN_TIMES="02:00"
fi
RUN_TIMES_ARRAY=($RUN_TIMES)


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
    patchman-client -s "https://${SERVERNAME}/patchman"

    # Call time_to_sleep function to set PROCESS_REPORT_SLEEP_SECONDS and
    # then sleep.
    time_to_sleep
    echo "sleeping for $PROCESS_REPORT_SLEEP_SECONDS seconds before next report processing"
    sleep "$PROCESS_REPORT_SLEEP_SECONDS"

    # Process reports.
    /root/process-reports.sh

done
