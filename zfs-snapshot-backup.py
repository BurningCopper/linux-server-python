#!/usr/bin/env python3

## Script to update a remote zfs volume with the latest 
## snapshot version

import subprocess

volume_name = "data/psy-vm"
host_name = "psy-fs-hestia"
user_name = "mimic"
email_server = 'palazzo.psychiatry.wisc.edu'
email_from = "deretzlaff@wisc.edu"