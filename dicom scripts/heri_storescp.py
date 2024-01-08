#!/usr/bin/env python3

# Simple rewrite of the original bash script heri_storescp.sh
import os
import subprocess

## Let's set the command line options for storescp
out_dir = "/Volumes/Studies/landing"
eos_timeout = "5"
dicom_port = "11112"
add_to_path = "/usr/share/dcmtk-current/bin"
dcmdictpath = "/usr/share/dcmtk-current/share/dcmtk/dicom.dic"
tcp_buffer_length = "0"
xcs_path = "/home/mri/scripts/dicom_decoder.csh"

# Setup the system variables
os.environ['PATH'] = add_to_path + ":" + str(os.getenv('PATH'))
os.environ['DCMDICTPATH'] = dcmdictpath
os.environ['TCP_BUFFER_LENGTH'] = tcp_buffer_length

subprocess.run(['storescp',
                '--verbose',
                '--unique-filenames',
                '--output-directory', out_dir,
                '-xcs', xcs_path, '#p',
                '--sort-conc-studies', 'heri',
                '--eostudy-timeout', eos_timeout,
                dicom_port])