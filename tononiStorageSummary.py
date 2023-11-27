#!/usr/bin/env python3
#Script to generate a daily email on the status of Tononi storage
import smtplib
import subprocess
import datetime

drive_mount = ["neuropixel_archive", "paxilline", "opto_loc", "mouse_ncc", "em_storage", "jazz", "non_nccam", "nccam", "vision", "uwmf_orig_rec", "epilepsy"]
email_server = 'palazzo.psychiatry.wisc.edu'
email_from = "deretzlaff@wisc.edu"
email_to = ["smith1@wisc.edu", "deretzlaff@wisc.edu"]
email_subject = "Subject: Tononi-NAS Storage Assessment for " + datetime.datetime.now().strftime("%m-%d-%Y") + " \n"
email_body_formatting = ["Content-type:text/html \n<html><font face=\"Courier New, Courier, monospace\">", "</font></html>"]

# Output a string (s) that contains the formatted output of df
def df_output():
    d = subprocess.run(["/usr/bin/df", "--human-readable", "--output=size,used,avail,pcent,target"], stdout=subprocess.PIPE)
    d = d.stdout
    s = d.decode('utf-8')
    s = s.rstrip("\n")
    return s

# Take the input string (s), convert it to a list (l), and outputs a string (s) that contains only the lines that contain the grep search term (g)
def grep_lines(s, g):
    l = s.split("\n")
    s = ""
    for i in l:
        if i.find(g) != -1:
            s = s + i + "\n"
    return s

drive_usage_totals = "<pre>" + grep_lines(df_output(), "Size") 

for i in drive_mount:
    drive_usage_totals = drive_usage_totals + grep_lines(df_output(), i) 

drive_usage_totals = drive_usage_totals + "</pre>" 

email_message = email_subject + email_body_formatting[0] + drive_usage_totals + email_body_formatting[1]

server = smtplib.SMTP(email_server)
server.sendmail(email_from, email_to, email_message)
