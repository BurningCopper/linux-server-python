#!/usr/bin/env python3
#Script to run a daily backup of Psychiatry home folders and send an email report
import smtplib
import subprocess
import datetime

#input_folder = "/data/user-nfs-all/"
input_folder = "/Volumes/user-nfs-all/deretzlaff@ad.wisc.edu"
output_folder = "/Volumes/mri-users/"
email_server = 'smtp.wiscmail.wisc.edu'
email_from = "deretzlaff@wisc.edu"
email_to = ["deretzlaff@wisc.edu"] #, "wmanderson4@wisc.edu"]
email_subject = "Subject: Psychiatry Home Folder Backup status for " + datetime.datetime.now().strftime("%m-%d-%Y") + " \n"
email_body_formatting = ["Content-type:text/html \n<html><font face=\"Courier New, Courier, monospace\">", "</font></html>"]

# Take the input directory (dir_in) and output the total disk usage for the directory as a string (dir_out)
def rsync_backup(dir_in, dir_out):
        rsync_subprocess = subprocess.run(["/usr/bin/rsync", "--recursive", "--archive", "--progress", dir_in, dir_out], stdout=subprocess.PIPE)
        rsync_subprocess = rsync_subprocess.stdout
        rsync_output = rsync_subprocess.decode('utf-8')
        rsync_output = rsync_output.rstrip("\n")
        return rsync_output

# Take the input string (s), convert it to a list (l), and output an html formatted table (h)
def format_html_table(s):
    l = s.split('\n')
    h = "<p><table>\n<tr><td>"
    for i in l:
        i = i + "\n<tr><td>"
        i = i.replace('\t', '</td><td>')
        i = i.replace('\n', '</td></tr>')
        h = h + i + "\n"
    h = h + "</table></p>\n"
    return h

# Begin main program
rsync_report = ""

rsync_report = rsync_report + rsync_backup(input_folder, output_folder)

print(rsync_report)

#start here

#drive_usage_totals = "<pre>" + grep_lines(df_output(), "Size") 

#for i in drive_mount:
#    drive_usage_totals = drive_usage_totals + grep_lines(df_output(), i) 

#drive_usage_totals = drive_usage_totals + "</pre>" 

#storage_report = format_html_table(storage_report) + drive_usage_totals

#email_message = email_subject + email_body_formatting[0] + storage_report + email_body_formatting[1]

#server = smtplib.SMTP(email_server)
#server.sendmail(email_from, email_to, email_message)
