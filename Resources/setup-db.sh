#!/bin/bash

set -e

# This will create a new patchman DB but only if
# it does not already exist or exists but is empty.

patchman_db_path="/var/lib/patchman/db/patchman.db"

if [ -s "$patchman_db_path" ]; then
    echo "cannot create DB as patchman DB already exists at '$patchman_db_path'"
    exit 0
fi

# Create the database and set the superuser account.
patchman-manage migrate --run-syncdb
patchman-manage createsuperuser
chown -R www-data:root /var/lib/patchman/db/

echo "Done!"

exit 0


