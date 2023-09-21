#!/usr/bin/env python3
#Script to generate a daily email on the status of Tononi storage
import smtplib
import subprocess
import datetime

# input_folder = ["/Volumes/neuropixel_archive", "/Volumes/paxilline", "/Volumes/opto_loc", "/Volumes/mouse_ncc", "/Volumes/em_storage", "/Volumes/jazz", "/Volumes/non_nccam", "/Volumes/nccam", "/Volumes/vision", "/Volumes/epilepsy", "/Volumes/nccam_scratch", "/Volumes/slap_mi", "/Volumes/uwmf_orig_rec", "/Volumes/white_elephant"]
drive_mount = ["neuropixel_archive", "paxilline", "opto_loc", "mouse_ncc", "em_storage", "jazz", "non_nccam", "nccam", "vision"]
email_server = 'palazzo.psychiatry.wisc.edu'
email_from = "deretzlaff@wisc.edu"
# email_to = ["smith1@wisc.edu", "deretzlaff@wisc.edu"]
email_to = ["deretzlaff@wisc.edu"]
email_subject = "Subject: Tononi Storage Assessment for " + datetime.datetime.now().strftime("%m-%d-%Y") + " \n"
email_body_formatting = ["Content-type:text/html \n<html><font face=\"Courier New, Courier, monospace\">", "</font></html>"]

# Take the input directory (dir_in) and output the total disk usage for the directory as a string (dir_out)
# def disk_usage(dir_in):
#         du_subprocess = subprocess.run(["/usr/bin/du", "--summarize", "--human-readable", dir_in], stdout=subprocess.PIPE)
#         du_subprocess = du_subprocess.stdout
#         dir_out = du_subprocess.decode('utf-8')
#         dir_out = dir_out.rstrip("\n")
#         return dir_out

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

# Take an input string (s) and output the individual disk usage of its contents (o)
def total_disk_usage(s):
    ls_subprocess = subprocess.run(["/usr/bin/ls", "--format", "single-column", s], stdout=subprocess.PIPE)
    ls_subprocess = ls_subprocess.stdout
    p = ls_subprocess.decode('utf-8')
    p = p.rstrip("\n")
    l = p.split("\n")
    o = s + "\t\n"
    for i in l:
        o = o + (disk_usage(s + "/" + i)) + "\n" 
    return o

# Begin main program
# storage_report = ""
# for i in input_folder:
#     storage_report = storage_report + total_disk_usage(i) 

drive_usage_totals = "<pre>" + grep_lines(df_output(), "Size") 

for i in drive_mount:
    drive_usage_totals = drive_usage_totals + grep_lines(df_output(), i) 

drive_usage_totals = drive_usage_totals + "</pre>" 

# storage_report = format_html_table(storage_report) + drive_usage_totals

email_message = email_subject + email_body_formatting[0] + drive_usage_totals + email_body_formatting[1]

server = smtplib.SMTP(email_server)
server.sendmail(email_from, email_to, email_message)
