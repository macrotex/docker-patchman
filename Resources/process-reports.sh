#!/bin/bash

# Process all received reports and update the package information from all
# repositories. Run once per day.

set -e

# -q: quiet
time /usr/bin/patchman -a -q
