#!/user/bin/env python3

# Import libraries
import os
import subprocess
import sys

# define paths
RootPath    = "/Volumes/Studies/landing" # Should always include 'landing'. Do not change this to just /Volumes/Studies
SriptPath   = "/home/mri/scripts"
TmpPath     = RootPath + "/tmp"
LogPath     = RootPath + "/log"
OutPath     = "/Volumes/Studies"
DefOutPath  = "/Volumes/Studies/homeless"
Log_File    = LogPath + "/log_debug.txt"
Log_Info    = LogPath + "/log_scaninfo.txt"
Log_Error   = LogPath + "/log_error.txt" # for bad errors
Debug       = "1" # Print extra debug info to see where the script is stuck, taking a long time, or crashing
Debug2      = "1" # Finder level of debug
Debug3      = "0" # Even finer level of debug
Save_Dup_Tar = "1"
CleanUp     = "1"

# Check to make sure directory name is passed to this script
if sys.argv[0] is None:
    