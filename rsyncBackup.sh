#!/bin/bash

# User rsync to perform a backup from $IN_FOLDER to $OUT_FOLDER

IN_FOLDER=$1
OUT_FOLDER=$2
RSYNC_OPTIONS="--recursive --progress --links --times --group --owner --dry-run"

time rsync $RSYNC_OPTIONS $IN_FOLDER $OUT_FOLDER | tee >(gzip > /tmp/backup_report.gz)

