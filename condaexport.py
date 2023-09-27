#!/usr/bin/env python3

## App that creates a list of all the users conda
## environments and exports all of them to separate
## named files inside the folder $HOME/conda_envs

import os
import subprocess

folder_location = os.path.expandvars('$HOME') + '/' + 'conda_envs'

# Check if the path exists in the users home directory
def path_exists(path):
    b = os.path.isdir(path)
    return b

# Create a directory 
def make_directory(s):
    os.makedirs(s)

# Find unwanted lines (g) and remove them from a string (s)
def grep_lines(s,g):
    l = s.split('\n')
    s = ''
    for i in l:
        if i.find(g) == -1:
            s = s + i + "\n"
    s = s.rstrip('\n')
    return s

# Import a string (s) and output a list (o) of the first words of each line 
def grab_first_word(s):
    l = s.split('\n')
    o = []
    for line in l:
        word = line.split()
        o.append(word[0])
    return o
    

# List conda environments
def list_conda_env():
    b = subprocess.run(['conda',
                         'env',
                         'list'],
                         stdout=subprocess.PIPE)
    b=b.stdout
    s = b.decode('utf-8')
    s = s.rstrip('\n')
    s = grep_lines(s, "#")
    l = grab_first_word(s)
    return l

# Import a string (s) with the name of a conda env and export a yml file
def export_conda_env(s):
    file_name = folder_location + '/' + s +'.yml'
    if os.path.exists(file_name):
        print("File " + file_name + " already exists!")
    else:
        with open(file_name, "w") as file_object:
            b = subprocess.run(['conda',
                                'env',
                                'export',
                                '--name',
                                s],
                                stdout=subprocess.PIPE)
            b = b.stdout
            f = b.decode('utf-8')
            f = f.rstrip('\n')
            file_object.write(f)

#Begin main program
if path_exists(folder_location):
    exit
else:
    make_directory(folder_location)

conda_envs = list_conda_env()

for conda_env in conda_envs:
    export_conda_env(conda_env)
