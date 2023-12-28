#!/usr/bin/env python3

## Script to update a remote zfs volume with the latest 
## snapshot version

import subprocess
import datetime
import smtplib

volume_name = "data/psy-vm"
host_name = "psy-fs-hestia"
user_name = "deretzlaff-ou"
email_server = 'palazzo.psychiatry.wisc.edu'
email_from = "deretzlaff@wisc.edu"
email_to = "deretzlaff@wisc.edu"
email_subject = "Subject: " + volume_name + " snapshot backup results for " + datetime.datetime.now().strftime("%m-%d-%Y") + "\n"

# Take the input list (s), convert it to a list (l), and outputs a list (l) that containes only the lines that contain the search term (g)
def grep_lines(s, g):
    l = []
    for i in s:
        if i.find(g) != -1:
            l.append(i)
    return l

# Take the byte type output of subprocess.run (b) and output a list of clean output (l)
def clean_output(b):
    b = b.stdout
    s = b.decode('utf-8')
    s = s.rstrip('\n')
    l = s.split()
    return l 

# Take a email server name (s) a From email address (f) a To email address (t) and a message and send an email
def send_email(s, f, t, m):
    e = smtplib.SMTP(s)
    e.sendmail(f, t, m)

# Take a hostname (h), a username (u), a zfs volume name (v), and output a byte formatted list (b) of volume snapshots
def remote_snapshots(h, u, v):
    b = subprocess.run(["ssh", h, "zfs", "list", 
                    "-t", "snapshot", 
                    "-o", "name", volume_name],
                    stdout=subprocess.PIPE)
    return b


# Main program
last_snapshot_byte = remote_snapshots(host_name, user_name, volume_name)
last_snapshot_list = clean_output(last_snapshot_byte)
last_snapshot_list = grep_lines(last_snapshot_list, "daily")
last_snapshot = last_snapshot_list[-1]

print(last_snapshot)

