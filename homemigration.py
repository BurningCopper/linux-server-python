#!/usr/bin/env python3

## App that creates AD authenticating folders from 
## current LDAP folders held in the mri-users
## nfs share.  The app reads a csv file and uses the
## data to map LDAP userids to the new AD userids,
## creates a new home folder based on the users netid,
## moves the contents of the users LDAP users folder,
## and sets the correct permissions for the folder. 

import subprocess
import os

download_location = os.path.expandvars('$HOME') + '/' + 'backup_home'
server_ip = "128.104.152.42"

# Take username as input and remove any extra spaces
def clean_name(s):
    s = s.strip()
    return s

# Check if the path exists in the users home directory
def path_exists(path):
    b = os.path.isdir(path)
    return b

# Create a directory
def make_directory(s):
    os.makedirs(s)

# Begin main program
user_name = input("Please enter your username: ")
user_name = clean_name(user_name)

if path_exists(download_location):
    exit
else:
    make_directory(download_location)

subprocess.call(["rsync", "-r", "--progress", user_name + "@" + server_ip + ":~/", download_location])