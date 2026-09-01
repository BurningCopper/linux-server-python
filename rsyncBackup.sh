#!/bin/bash

# User rsync to perform a backup from $IN_FOLDER to $OUT_FOLDER

IN_FOLDER=$1
OUT_FOLDER=$2
REPORT_LOCATION=/tmp/backup_report.txt
RSYNC_OPTIONS="--recursive --stats --links --times --owner --group"

(time rsync $RSYNC_OPTIONS $IN_FOLDER $OUT_FOLDER) 2>&1 | tee $REPORT_LOCATION

echo "Compressed report can be read directly in VIM" | mutt -s "Backup Report for $IN_FOLDER on $(date "+%A %m-%d-%Y")" -a $REPORT_LOCATION -- deretzlaff@wisc.edu