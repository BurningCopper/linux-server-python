#!/usr/bin/env python3

## App that creates AD authenticating folders from 
## current LDAP folders held in the mri-users
## nfs share.  The app reads a csv file and uses the
## data to map LDAP userids to the new AD userids,
## creates a new home folder based on the users netid,
## moves the contents of the users LDAP users folder,
## and sets the correct permissions for the folder. 

import csv
import subprocess

