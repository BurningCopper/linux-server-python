#!/usr/bin/env python3
#Script meant to generate a quarterly email report of Storage usage
import smtplib
import subprocess
import datetime

# Check the current month and decide which quarter should be used for the report
def print_quarter():
    q1 = {3, 4, 5}
    q2 = {6, 7, 8}
    q3 = {9, 10, 11}
    q4 = {12, 1, 2}
    if datetime.datetime.now().month in q1:
        q = "Q1"
    if datetime.datetime.now().month in q2:
        q = "Q2"
    if datetime.datetime.now().month in q3:
        q = "Q3"
    if datetime.datetime.now().month in q4:
        q = "Q4"
    return(q)

input_volumes = [["Cisler Lab", "/Volumes/Vol2"], ["Koenigs Lab", "/Volumes/Vol3"], ["Kalin Lab", "/Volumes/Vol5"], ["Herringa Lab", "/Volumes/Vol6"], ["Plante Lab", "/Volumes/Vol7"]]
email_server = "palazzo.psychiatry.wisc.edu"
price_per_t = 120
email_from = "deretzlaff@wisc.edu"
email_to = "deretzlaff@wisc.edu" # weitzman2@wisc.edu, iakere@wisc.edu, wempner@wisc.edu, kkern3@wisc.edu, rashton@wisc.edu"
email_subject = print_quarter() + " " + datetime.datetime.now().strftime("%Y") + " Storage report for MRI-NAS \n"
email_body_formatting = ["Content-type:text/html \n<html><font face=\"Courier New, Courier, monospace\">", "</font></html>"]
email_spacer = "====================\n"

# Take the input string (s), convert it to a list (l), and outputs a string (s) that contains only the lines that contain the grep search term (g)
def grep_lines(s, g):
    l = s.split("\n")
    s = ""
    for i in l:
        if i.find(g) != -1:
            s = s + i + "\n"
    return s

# Take the input mount name (drive_in) and output the space used in bytes
def df_value(drive_in):
    df_subprocess = subprocess.run(["/usr/bin/df", "--output=used,target"], stdout=subprocess.PIPE)
    df_subprocess = df_subprocess.stdout
    size_out = df_subprocess.decode('utf-8')
    str_out = grep_lines(size_out, drive_in)
    str_out = str_out.replace(drive_in, "")
    str_out = str_out.replace(" ", "")
    str_out = str_out.rstrip("\n")
    return str_out


# Take the input mount name (drive_in) and output the space used in human readable output
def df_value_human(drive_in):
    df_subprocess = subprocess.run(["/usr/bin/df", "--human-readable", "--output=used,target"], stdout=subprocess.PIPE)
    df_subprocess = df_subprocess.stdout
    size_out = df_subprocess.decode('utf-8')
    str_out = grep_lines(size_out, drive_in)
    str_out = str_out.replace(drive_in, "")
    str_out = str_out.replace(" ", "")
    str_out = str_out.rstrip("\n")
    return str_out


# Takes storage_used in bytes and finds cost of storage per quarter 
def quarterly_price(storage_used):
    storage_used_float = float(storage_used)
    price_float = float(price_per_t)
    cost = (storage_used_float / (1000 ** 3)) * price_float * .25
    return cost

# Main program
storage_report = "Please find below the " + email_subject + "\n"

for i in input_volumes:
    storage_report = storage_report + email_spacer + "Storage Report for the " + i[0] + " (" + i[1] + "):\n"
    storage_report = storage_report + df_value_human(i[1]) + " Used * $" + str(price_per_t) + "/TB/Year * .25 = $" + str(round(quarterly_price(df_value(i[1])),2)) + "\n\n"

print(storage_report)



'''
Needed for report:
- Get the storage usage of each of the important volumes
- Calculate the cost of the storage per year
- calculate the storage cost per quarter 
- format output for email
- send email to important people
'''
