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

## `SERVERNAME` environment variable

Apache will use HOSTNAME as its `ServerName` unless the environment SERVERNAME. When
defining SERVERNAME be sure it is fully-qualified.

## `USE_SSL` environment variable

Apache assumes that SSL is enabled unless the environment variable
`USE_SSL` is set to `NO`.

## SSL certificate and private key

If Apache is configured to use SSL (the default) Apache expects to find
the private key and certificate in the usual Debian location. That is,
they must be mapped as follows:

    cetificate:  /etc/ssl/certs/server.pem
    private key: /etc/ssl/private/server.key

## Other configuration

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
