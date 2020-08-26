[[_TOC_]]

# Patchman docker container

Dockerization of Patchman (Patch management tool). See the [Patchman
GitHub](https://github.com/furlongm/patchman) page for more details on
Patchman itself.

The Docker container runs Patchman under Apache 2.4. Most of the
configuration described below involves Apache.

# Quick Start

1. Build Image (Change to the directory where Dockerfile exists)

```
   docker build -t patchman .
```

2. Run the container in detach mode

```
   ## If you don't want to enable HTTPS then use enivonment variable USE_SSL=NO (FALSE).
   ##
   ## By default, USE_SSL is YES.

   ## To Disable SSL, Run the below command


   docker run -d -it -h patchman-dev.example.com -p 80:80 -e USE_SSL=NO \
	-v  /var/log/apache2:/var/log/apache2 \
	-v /etc/apache2/patchman.htpasswd:/etc/apache2/patchman.htpasswd \
	-v /root/patchman-db/patchman.db:/var/lib/patchman/db/patchman.db \
        -v /etc/patchman/patchman.netrc:/etc/patchman/patchman.netrc \
	--name=patchman patchman

    ## To Enable SSL, Run the below command
    ## By default, we assign USE_SSL value to YES. So giving -e USE_SSL=YES variable in the
    ## below command is Optional.

   docker run -d -it -h patchman-dev.example.com -p 443:443 -p 80:80 -e USE_SSL=YES \
	-v /etc/ssl/certs/server.pem:/etc/ssl/certs/server.pem \
	-v /etc/ssl/private/server.key:/etc/ssl/private/server.key \
	-v  /var/log/apache2:/var/log/apache2 \
	-v /etc/apache2/patchman.htpasswd:/etc/apache2/patchman.htpasswd \
	-v /root/patchman-db/patchman.db:/var/lib/patchman/db/patchman.db \
        -v /etc/patchman/patchman.netrc:/etc/patchman/patchman.netrc \
	--name=patchman patchman

   OR

   docker run -d -it -h patchman-dev.example.com -p 443:443 -p 80:80 \
	-v /etc/ssl/certs/server.pem:/etc/ssl/certs/server.pem \
	-v /etc/ssl/private/server.key:/etc/ssl/private/server.key \
	-v  /var/log/apache2:/var/log/apache2 \
	-v /etc/apache2/patchman.htpasswd:/etc/apache2/patchman.htpasswd \
	-v /root/patchman-db/patchman.db:/var/lib/patchman/db/patchman.db \
        -v /etc/patchman/patchman.netrc:/etc/patchman/patchman.netrc \
	--name=patchman patchman

```

   NOTE: patchman.db must be owned by www-data:root

3. Script to setup the database and create admin user. This script exits with success
   code "0" if the database is already created or exists.
```
docker exec -it patchman bash

/root/setup-db.sh   # Create admin user
```

# Configuration

## Apache configuration

### `HTTP_PORT` environment variable

The port that Apache listens on. If this environment variable is not set
it defaults to 443.

### `SERVERNAME` environment variable

Apache will use HOSTNAME as its `ServerName` unless the environment
SERVERNAME is defined. When defining SERVERNAME be sure it is
fully-qualified.

### `USE_SSL` environment variable

This variable should be set to either `YES` or `NO`.
Apache is configured to use SSL if `USE_SSL` is set to `YES` and
configured to use plain HTTP if set `USE_SSL` is set to `NO`.

Setting `USE_SSL` to `NO` is useful when running this container behind a
load-balancer that acts as the TLS front-end.

Note that setting `USE_SSL` to `YES` does not automatically set
`HTTP_PORT` to 443; likewise, setting `USE_SSL` to `NO` does not
automatically set `HTTP_PORT` to 80. Thus, be sure to set _both_
`HTTP_PORT` and `USE_SSL`.

### SSL certificate and private key

If Apache is configured to use SSL (the default), Apache expects to find
the private key and certificate in the usual Debian location. That is,
they must be mapped as follows:

    cetificate:  /etc/ssl/certs/server.pem
    private key: /etc/ssl/private/server.key

## Other configuration

### Process Reports Delay

The container will periodically process all received reports and update
its repository information. It does this by running the report process,
sleeping a while, and then repeating. The amount of time it sleeps between
reports processing is controlled by the environment variable
`PROCESS_REPORT_SLEEP_SECONDS`. The default value for
`PROCESS_REPORT_SLEEP_SECONDS` is 86400 (the number of seconds in one
day).

Note that on container start-up the reports process _first_ sleeps
for `PROCESS_REPORT_SLEEP_SECONDS` seconds and _then_ runs.

### Application debug mode

To turn on Patchman debug mode

Edit the file `/etc/patchman/local_settings.py` and change the line
```
Debug = False
```
to
```
Debug = True
```
Note that the debug messages will show up in the web browser itself.

# The `patchman-client` user

This Patchman server is configured so that the endpoint
(`/patchman/reports/upload`) that receives Patchman client reports
requires basic authentication (see also
`/etc/apache2/sites-available/patchman.conf`).

The basic authentication uses the htpasswd file
`/etc/apache2/patchman.htpasswd`. So it is up to _you_ to create this file
and mount it into the Docker container. The usual username is
`patchman-client` but it can be anything you want _as long as_ it matches
the username used by the Patchman clients.

The container will act as a Patchman client as long as you map the a
"netrc" file to `/etc/patchman/patchman.netrc`. This file should look
something like this:
```
# /etc/patchman/patchman.netrc
machine patchman.example.com
login patchman-client
password my_secret_password
```
Note that the value for `machine` above should match the Patchman server name.
