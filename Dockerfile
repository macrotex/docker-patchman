FROM debian:buster-slim

LABEL maintainer="psr123@stanford.edu"

ENV DEBIAN_FRONTEND noninteractive

ENV USE_SSL YES

RUN apt-get update && apt-get -qqy install wget gnupg ca-certificates

## Add the openbytes apt-key
ADD Resources/sourceslist/openbytes.list /etc/apt/sources.list.d/openbytes.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0412F522

## Add ROOT Certificates
ADD Resources/certs/incommon-usertrust-2024.pem           /etc/ssl/certs/incommon-usertrust-2024.pem
ADD Resources/certs/incommon2024-usertrust2038-bundle.pem /etc/ssl/certs/incommon2024-usertrust2038-bundle.pem

# Docker image containing api-gateway
RUN apt-get update && apt-get -qqy install \
		apache2 \
                git \
		python-2.7 \
		ruby \
		libapache2-mod-wsgi \
                apt-utils \
                vim \
                procps \
                adduser \
                rsyslog

RUN apt-get update && apt-get install -qqy \
		python-patchman \
                patchman-client

# We don't need the patchman apt hook.
RUN rm /etc/apt/apt.conf.d/05patchman

# Remove some unneeded packages to save space. Also clean the package cache.
RUN apt-get remove --yes gcc gcc-8 \
  && apt-get clean

## Apache2 Configuration. Note that the Dockerfile image does not contain
## the Apache configuration file, rather the start script generates the
## Apache configuration file on container start-up.
ADD Resources/patchman_apache_conf.erb /root/patchman_apache_conf.erb

## Add start.sh file
ADD Resources/start.sh /root/start.sh

## Setup script to initialise the database and create admin user.
ADD Resources/setup-db.sh /root/setup-db.sh

## ADD the script to process reports.
ADD Resources/process-reports.sh /root/process-reports.sh

## ADD patchman-client conf file
ADD Resources/patchman-client.conf /etc/patchman/patchman-client.conf

RUN mkdir -p /var/lib/patchman/media
RUN chown -R www-data:root /var/lib/patchman/

EXPOSE 80 443

CMD ["/root/start.sh"]
