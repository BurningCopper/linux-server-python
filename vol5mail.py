#!/usr/bin/env python3
#Script to generate a daily email on the status of Vol5 
import smtplib
import subprocess
import datetime

input_folder = "/home/deretzlaff-ou@ad.wisc.edu"
drive_mount = "run"
email_server = 'smtp.wiscmail.wisc.edu'
email_from = "deretzlaff@wisc.edu"
email_to = "deretzlaff@wisc.edu"
email_subject = "Subject: Vol5 Storage Assessment for " + datetime.datetime.now().strftime("%m-%d-%Y") + " \n"
email_body_formatting = ["Content-type:text/html \n<html><font face=\"Courier New, Courier, monospace\">", "</font></html>"]


# Take the byte type output of subprocess.run (b) and output a list of clean output (l)
def clean_output(b):
    b = b.stdout
    s = b.decode('utf-8')
    s = s.rstrip("\n")
    l = s.split('\n')
    return l

# Take the input directory (dir_in) and output the total disk usage for the directory as a string (dir_out)
def disk_usage(dir_in):
    du_subprocess = subprocess.run(["/usr/bin/du", "--summarize", "--human-readable", dir_in], cwd=input_folder, stdout=subprocess.PIPE)
    du_subprocess = du_subprocess.stdout
    dir_out = du_subprocess.decode('utf-8')
    dir_out = dir_out.rstrip("\n")
    return dir_out

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

#Take the input string (s), convert it to a list (l), and output an html formatted table (h)
def format_html_table(s):
    l = s.split('\n')
    h = "<p><table>\n"
    for i in l:
        i = i.replace('\t', '</td><td>')
        i = i.replace('\n', '</td></tr>')
        h = h + "<tr><td>" + i + "\n"
    h = h + "</table></p>"
    return h


# Begin the main program
ls_output = subprocess.run(["/usr/bin/ls", "--format", "single-column"], cwd=input_folder, stdout=subprocess.PIPE)

directories = clean_output(ls_output)

storage_report = "Folder size&nbsp&nbsp&nbsp\tFolder\n"

for directory in directories:
    storage_item = disk_usage(directory)
    storage_report = storage_report + storage_item + "\n"

drive_usage_totals = ""

drive_usage_totals = drive_usage_totals + "<pre>" + grep_lines(df_output(), "Size") + grep_lines(df_output(), drive_mount) + "</pre>"

storage_report = format_html_table(storage_report) + drive_usage_totals

email_message = email_subject + email_body_formatting[0] + storage_report + email_body_formatting[1]

server = smtplib.SMTP(email_server)
server.sendmail(email_from, email_to, email_message)