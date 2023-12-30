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
    b = subprocess.run(["ssh", u + "@" + h, "zfs", "list", 
                    "-t", "snapshot", 
                    "-o", "name", v],
                    stdout=subprocess.PIPE)
    return b

# Take a local zfs volume name (v), and output a byte formatted list (b) of volume snapshots
def local_snapshots(v):
    b = subprocess.run(["zfs", "list", 
                        "-t", "snapshot",
                        "-o", "name", v],
                        stdout=subprocess.PIPE)
    return b

# Main program
latest_snapshot_byte = remote_snapshots(host_name, user_name, volume_name)
latest_snapshot_list = clean_output(latest_snapshot_byte)
latest_snapshot_list = grep_lines(latest_snapshot_list, "daily")
latest_snapshot = latest_snapshot_list[-1]

old_snapshot_byte = local_snapshots(volume_name)
old_snapshot_list = clean_output(old_snapshot_byte)
old_snapshot_list = grep_lines(old_snapshot_list, "daily")
old_snapshot = old_snapshot_list[-1]

# print("ssh " + host_name + "zfs send -i" + old_snapshot + latest_snapshot + "zfs recv" + volume_name)

if old_snapshot < latest_snapshot:
    print(old_snapshot + " is smaller")
    email_body_byte = subprocess.run(["ssh", host_name,
                                    "zfs", "send",
                                    "-i", old_snapshot, latest_snapshot, "|",
                                    "zfs", "recv", volume_name])
    email_body_list = clean_output(email_body_byte)
    print(email_body)
    email_body = ""
    for i in email_body_list:
        email_body = i + "\n"
    print(email_body)
else:
    email_body = "No backup performed because the latest snapshot on the target volume was not newer than the backup snapshot."

# print(email_body)