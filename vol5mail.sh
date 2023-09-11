#!/bin/bash

OUTPUTTXTFILE=/home/localadmin/Scripts/vol5space.txt

du -hsc --si /Volumes/Vol5/* > $OUTPUTTXTFILE
echo " " >> $OUTPUTTXTFILE
echo "Size  Used Avail Use% Mounted on" >> $OUTPUTTXTFILE
df --output=size,used,avail,pcent,target --human-readable --type nfs | grep \/Volumes\/Vol5 >> $OUTPUTTXTFILE

s-nail -r root@psy-fractal -S smtp=palazzo.psychiatry.wisc.edu -s "Vol5 Storage Assessment for $(date +"%m-%d-%y")"  lewilliams4@wisc.edu deretzlaff@wisc.edu < $OUTPUTTXTFILE