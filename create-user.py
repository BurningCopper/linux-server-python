#!/usr/bin/env python3
#Script to create a new user and create an ssh key for loging into psy-fs-transfer
import subprocess
import os
import smtplib

transfer_key_name = "transfer_rsa"
email_server = "palazo.psychiatry.wisc.edu"
email_from = "helpdesk@psychiatry.wisc.edu"

# Take username as input and remove any extra spaces
def clean_name(s):
    s = s.strip()
    return s

# check if an rsa key file exists
def key_exists(path):
    b = os.path.isfile(path)
    return b

# Take a netid and output their home directory
def find_home_path(user_name):
    s = subprocess.run(["/usr/bin/su",
                        "--command",
                        "echo $HOME",
                        user_name], stdout=subprocess.PIPE)
    s = s.stdout
    p = s.decode('utf-8')
    p = p.rstrip("\n")
    return p

# create users home directory and secret key
def create_user_key(user_name):
    subprocess.run(["/usr/bin/su",
                    "--command",
                    "ssh-keygen -N \"\" -f $HOME/.ssh/" + transfer_key_name,
                    user_name])

# Email the key to the end user
# def email_key(n):


netid = input("What is the new netid? ")
netid = clean_name(netid)

home_path = find_home_path(netid)
key_location = home_path + "/.ssh/" + transfer_key_name

if not key_exists(key_location):
    create_user_key(netid)
    email_key(netid)

# if key_exists(transfer_key_name,netid)

# subprocess.run(["/usr/bin/su",
#                 "--command",
#                 "ssh-keygen -N \"\" -f $HOME/.ssh/" + transfer_key_name,
#                 netid])

# subprocess.run

# login as user

# check for current key (if key exists, don't create a new key)

# create ssh key as User

# add ssh key to ~/.ssh/authorized_keys
