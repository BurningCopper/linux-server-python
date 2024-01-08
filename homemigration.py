#!/usr/bin/env python3

## App that logs user into a VM to authenticate their
## user priveledges under LDAP, then copies their old
## home folder files into a folder (backup_home) inside
## their AD account

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

subprocess.call(["rsync",
                "--recursive",
                "--progress",
                "--update",
                "--append-verify",
                "--links",
                "--sparse",
                "--times",
                "--checksum",
                "--compress",
                user_name + "@" + server_ip + ":~/", download_location])

