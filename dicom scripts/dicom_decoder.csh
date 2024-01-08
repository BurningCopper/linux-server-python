#!/bin/tcsh

#-----------------------------------------------------------
# This code is meant to be run on a directory of dicom files
# e.g. passed to it by storescp
#
# Author : R.M. Birn
# Created: January 23, 2018
#
# Changes:
# 2018-02-07: changed where temporary files go.
#             script now handles multiple exams per transfer
# 2018-02-12: Added transfer of physio. (Should work for multiple
#             exams in same transfer, but not tested)
# 2018-02-19: enabled/added cleanup
# 2018-02-27: added option to save duplicate tar file if data transferred again
# 2018-03-12: Go Live. changed path to Studies & dicoms. 
# 2018-04-13: Changed default output directory to 'homeless'
# 2018-09-12: Fixed bug that appended @cp_safe_dir rather than replaced lines.
# 2018-10-17: Fixed bug when list of dicom files is too long
# 2019-02-18: Fixed bug with series descriptions containing #
# 2019-02-21: Added option to transfer shim values
# 2019-11-26: Added checks to make sure incoming transfer is complete
# 2021-03-16: Added additional logging option (shim). Fixed shim xfer.
# 2022-05-17: Removed 'count'. use 'seq' instead.
# 2022-06-03: changed foreach loop to use 1deval (faster)
# 2022-07-19: added more debug info
# 2023-05-23: changed working output directory (in case two dicom_decoder processes run at same time)
#-----------------------------------------------------------
time 

#--- define paths ---
set RootPath     = /Volumes/Studies/landing #Should always include "landing". Do not change this to just /Volumes/Studies.
set ScriptPath   = /home/mri/scripts
set TmpPath      = $RootPath/tmp
set LogPath      = $RootPath/log
set OutPath      = /Volumes/Studies #$RootPath #
set DefOutPath   = /Volumes/Studies/homeless 
set LOG_FILE     = $LogPath/log_debug.txt
set LOG_INFO     = $LogPath/log_scaninfo.txt
set LOG_ERROR    = $LogPath/log_error.txt #for bad errors
set DEBUG        = 1 #Print extra debug info to see where the script is stuck, taking a long time, or crashing
set DEBUG2       = 1 #finer level of debug.
set DEBUG3       = 0 #even finer level of debug
set SAVE_DUP_TAR = 1
set CLEANUP      = 1

#--- check to make sure directory name is passed to this script ---
if ($#argv < 1) then
   echo "No directory specified on command line. Aborting script." |& tee -a $LOG_FILE
   exit()
endif

#--- directory passed by strorescp (including full path) ---
set dirX = $argv[1]   #heri_20180119_172221808 #heri_20180123_134709478 #storescp_20180117_165656923 #
set dir = `basename $dirX` #define 'dir' as only the directory without full path

#--- check to make sure directory exists and is not null ---
if (! -e $dirX || "$dir" == "") then
   echo "Could not read directory passed to script. Aborting script." |& tee -a $LOG_FILE
   exit()
endif

if ($DEBUG) echo "========================================" |& tee -a $LOG_FILE
if ($DEBUG) date                                            |& tee -a $LOG_FILE
if ($DEBUG) echo "----------------------------------------" |& tee -a $LOG_FILE
if ($DEBUG) echo "Starting dicom_decoder.csh for dir: $dir" |& tee -a $LOG_FILE

#--- define file that will contain header info ---
set header_info_file = $TmpPath/header_info.$dir.txt
if (-e $header_info_file) then
rm -f $header_info_file
endif

#--- define & create working output directory ---
set WorkPath = $RootPath/out.$dir
if (! -e $WorkPath) then
   echo "Creating $WorkPath ..."
   mkdir -p $WorkPath
endif

cd $dirX

#--------------------------------------------------------
# CHECK to make sure transfer is complete
#--------------------------------------------------------
set NumFiles1 = `/bin/ls $RootPath/$dir | wc -l`
sleep 1
set NumFiles2 = `/bin/ls $RootPath/$dir | wc -l`
set t_wait = 0
if ($NumFiles2 > $NumFiles1) then
   echo "[$dir] Detected that files are still being written into the current directory." |& tee -a $LOG_FILE
   echo "[$dir] Waiting until tranfer complete" |& tee -a $LOG_FILE
   while ($NumFiles2 > $NumFiles1) 
      set NumFiles1 = `/bin/ls $RootPath/$dir | wc -l`
      sleep 1
      set NumFiles2 = `/bin/ls $RootPath/$dir | wc -l`
      @ t_wait ++
      if ($t_wait > 10) then
         echo "[$dir] Maximum wait time exceeded. Continuing on." |& tee -a $LOG_FILE
	 break
      endif
   end
endif
      

#========================================================
# DUMP DICOM HEADERS 
#--------------------------------------------------------
if ($DEBUG2) echo "[$dir] starting dump ..." |& tee -a $LOG_FILE

#--- Split file list if necessary ---
# (can pass maximum of 32767 arguments on the command line to dcmdump)
set NumFiles = `/bin/ls $RootPath/$dir | wc -l`
if ($DEBUG) echo "[$dir] $NumFiles files found in $dir" |& tee -a $LOG_FILE
set MaxFiles = 10000
set FileList = ""
set NumFilesRemaining = $NumFiles
if ($NumFiles > $MaxFiles) then
   set NA = $MaxFiles
   while ($NA < $NumFiles) 
      if ($DEBUG2) echo "[$dir] ...processing up to file number $NA ..."
      #--- could use 'find' rather than 'ls' in order to get absolute filenames, but then argument string is very long ---
      #find $RootPath/$dir -type f | head -$NA | tail -$MaxFiles > $TmpPath/list.$dir.txt
      /bin/ls $RootPath/$dir | head -$NA | tail -$MaxFiles > $TmpPath/list.$dir.txt
      dcmdump +F --search "0020,0010" --search "0020,0011" --search "0020,0013" --search "0008,103e" --search "0020,1002" `cat $TmpPath/list.$dir.txt`  >> $header_info_file
      @ NumFilesRemaining = $NumFiles - $NA
      @ NA = $NA + $MaxFiles
   end
   if ($NA >= $MaxFiles) then
      if ($DEBUG2) echo "[$dir] ...processing last $NumFilesRemaining ..."
      #find $RootPath/$dir -type f | tail -$NumFilesRemaining > $TmpPath/list.$dir.txt
      /bin/ls $RootPath/$dir | tail -$NumFilesRemaining > $TmpPath/list.$dir.txt
      dcmdump +F --search "0020,0010" --search "0020,0011" --search "0020,0013" --search "0008,103e" --search "0020,1002" `cat $TmpPath/list.$dir.txt`  >> $header_info_file
   endif
else      
   #--- Read multiple dicom headers at once ---
   dcmdump +F --search "0020,0010" --search "0020,0011" --search "0020,0013" --search "0008,103e" --search "0020,1002" $RootPath/$dir/* > $header_info_file
endif

#========================================================
# PARSE DICOM HEADERS 
#--------------------------------------------------------

#--- Parse header info file to create renaming script ---
# (extracting the info into files and using 'paste' is a bit clunky, but MUCH faster than assembling everything in a foreach loop)
if ($DEBUG2) echo "[$dir] parsing..." |& tee -a $LOG_FILE
cat $header_info_file | grep dcmdump   | awk '{print $NF}' > $TmpPath/x.$dir.file
cat $header_info_file | grep 0020,0011 | awk -F[ '{print $2}' | awk -F] '{printf("%04d\n", $1)}'  > $TmpPath/x.$dir.series
cat $header_info_file | grep 0020,0013 | awk -F[ '{print $2}' | awk -F] '{printf("%06d\n", $1)}'  > $TmpPath/x.$dir.inst
cat $header_info_file | grep 0020,0010 | awk -F[ '{print $2}' | awk -F] '{print $1}'              > $TmpPath/x.$dir.exam

#--- Parse series description, removing special characters ( #&*?$:;,/|(){}[]`"'\ ) ---
set noglob
cat $header_info_file | strings | grep 0008,103e | awk -F[ '{print $2}' | awk -F] '{print $1}' | sed 's/ /_/g' | sed 's/[#&*?$:;,/|(){}`"'\'']//g' | sed 's/\[\]//g' | sed 's/\^//g' > $TmpPath/x.$dir.desc
unset noglob
#(N.B. "strings" was used because someone decided to use non-ASCII characters as part of the description, causing grep to fail)
#(     strings will not return strings shorter than 4 characters (by default), so this will fail if the description is only 1 character ([] are the other 2 characters)
#(     awk could be used instead of grep, as below)

#--- additional error check ---
#awk '/0008,103e/' $header_info_file | awk '{print $3}' > $TmpPath/x.$dir.desc0
#set check_blank = `awk '/\[\]/' $TmpPath/x.$dir.desc0`
#if ("$check_blank" != "") then
#   echo "Error encountered in parsing series description. It appears some of them are blank"
#   exit()
#endif

#---Alternate: NOT_YET_TESTED---
#set noglob
#awk '/0008,103e/' $header_info_file | awk -F[ '{print $2}' | awk -F] '{print $1}' > $TmpPath/x.$dir.desc1
#cat $TmpPath/x.$dir.desc1 | sed 's/ /_/g' | sed 's/[#&*?$:;,/|(){}`"'\'']//g' | sed 's/\[\]//g' | sed 's/\^//g' > $TmpPath/x.$dir.desc
#unset noglob 

#--- Check for errors ---
set NN1 = `wc -l < $TmpPath/x.$dir.exam`
set NN2 = `wc -l < $TmpPath/x.$dir.series`
set NN3 = `wc -l < $TmpPath/x.$dir.inst`
set NN4 = `wc -l < $TmpPath/x.$dir.desc`
if ($NN1 == 0 || $NN1 != $NN2 || $NN1 != $NN3 || $NN1 != $NN4) then
   echo "[$dir] Error in parsing dicom header: NN1:$NN1 NN2:$NN2 NN3:$NN3 NN4:$NN4. Aborting script." |& tee -a $LOG_FILE
   exit()
endif

#--- Create prefixes and copy command ---
if ($DEBUG2) echo "[$dir] Creating copy command (foreach)..." |& tee -a $LOG_FILE
#rm -f $TmpPath/x.$dir.0
#rm -f $TmpPath/x.$dir.i
#rm -f $TmpPath/x.$dir.s
#rm -f $TmpPath/x.$dir.d
#rm -f $TmpPath/x.$dir.e
#rm -f $TmpPath/x.$dir.p
#foreach i (`seq 1 $NN1`)
#   echo "cp -fp"    >> $TmpPath/x.$dir.0
#   echo "i"         >> $TmpPath/x.$dir.i
#   echo "s"         >> $TmpPath/x.$dir.s
#   echo "dcm"       >> $TmpPath/x.$dir.d
#   echo "E"         >> $TmpPath/x.$dir.e
#   echo "$RootPath" >> $TmpPath/x.$dir.p
#end
#(faster method)
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's/0/cp -fp/g'      > $TmpPath/x.$dir.0
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's/0/i/g'           > $TmpPath/x.$dir.i
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's/0/s/g'           > $TmpPath/x.$dir.s
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's/0/dcm/g'         > $TmpPath/x.$dir.d
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's/0/E/g'           > $TmpPath/x.$dir.e
1deval -num $NN1 -expr "0" | sed 's/ //g' | sed 's|0|'$WorkPath'|g' > $TmpPath/x.$dir.p

#--- Stick the different files together to create rename script ---
if ($DEBUG2) echo "[$dir] paste..." |& tee -a $LOG_FILE
paste --delimiters=''   $TmpPath/x.$dir.s     $TmpPath/x.$dir.series                   > $TmpPath/x.$dir.s2    #join "s" and series number            [s0001]
paste --delimiters=''   $TmpPath/x.$dir.e     $TmpPath/x.$dir.exam                     > $TmpPath/x.$dir.exam2 #join "E" and Exam number              [E12345]
paste --delimiters='.'  $TmpPath/x.$dir.s2    $TmpPath/x.$dir.desc                     > $TmpPath/x.$dir.dir   #join series and description           [s0001.Localizer]
paste --delimiters='.'  $TmpPath/x.$dir.i     $TmpPath/x.$dir.inst $TmpPath/x.$dir.d   > $TmpPath/x.$dir.out   #join prefix, image number, and suffix [i000001.dcm]
paste --delimiters='/'  $TmpPath/x.$dir.p     $TmpPath/x.$dir.exam2 $TmpPath/x.$dir.dir  $TmpPath/x.$dir.out > $TmpPath/x.$dir.full  #join output path and filename [/Volumes/Studies/landing/E12345/s0001.Localizer/i000001.dcm]
paste $TmpPath/x.$dir.0 $TmpPath/x.$dir.file  $TmpPath/x.$dir.full  > $LogPath/rename.$dir                     #join all parts to form rename command

#--- stick files together for physio check ---
paste --delimiters='.'  $TmpPath/x.$dir.exam2 $TmpPath/x.$dir.s2 > $TmpPath/x.$dir.es

#--- look for possible duplicate filenames ---
set NFf = `wc -l < $TmpPath/x.$dir.full`                   # number of all output path/filenames
set NFu = `cat $TmpPath/x.$dir.full | sort | uniq | wc -l` # number of unique output path/filenames
if ($NFf != $NFu) then
   echo "[$dir] DUPLICATE FILES DETECTED ($NFf - $NFu)" |& tee -a $LOG_FILE
   
   #--- find duplicate filenames ---
   cat $TmpPath/x.$dir.full | sort | uniq -d > $TmpPath/x.$dir.dup
      
   #--- Loop over duplicate files ---
   if (-e $TmpPath/x.$dir.dup2) rm -f $TmpPath/x.$dir.dup2
   foreach file_dup (`cat $TmpPath/x.$dir.dup`)
      
      #--- find that line in the rename script ---
      fgrep $file_dup $LogPath/rename.$dir >> $TmpPath/x.$dir.dup2
      
   end
   
   #--- find files that are not duplicated ---
   sort $TmpPath/x.$dir.dup2 > $TmpPath/x.$dir.dup2.s
   diff $LogPath/rename.$dir $TmpPath/x.$dir.dup2.s | sed 's|<||g' | grep -v , > $LogPath/rename_update.$dir
   
   #--- replace cp with safe-cp for duplicate files ---
   cat $TmpPath/x.$dir.dup2.s | sed 's|cp -fp|'$ScriptPath'/@cp_safe_dir|g' >> $LogPath/rename_update.$dir
   
   #--- overwrite/replace previous rename script ---
   mv -f $LogPath/rename_update.$dir $LogPath/rename.$dir
      
endif

#========================================================
# CREATE OUTPUT DIRECTORIES
#--------------------------------------------------------

#--- Create output directories ---
# (out_dirs contains both exam number and series+description (e.g. E12345/s000001.Localizer))

if ($DEBUG2) echo "[$dir] Creating dirs..." |& tee -a $LOG_FILE
#set out_dirs = `cat $TmpPath/x.$dir.dir | sort | uniq`
set out_dirs = `cat $LogPath/rename.$dir | awk -F/ '{print $(NF-2) "/" $(NF-1)}' | sort | uniq`
if ($DEBUG2) echo "[$dir] out_dirs: $out_dirs" |& tee -a $LOG_FILE

#--- Safety check: exit if out_dirs is null ---
set check_null = `echo $out_dirs | awk '{print $1}'`
if ("$check_null" == "") then
   echo "[$dir] Could not determine output directories. Aborting dicom_decoder." |& tee -a $LOG_FILE
   exit()
endif

foreach out_dir ($out_dirs)
   set out_dir_exam   = `echo $out_dir | awk -F/ '{print $1}'`
   set out_dir_series = `echo $out_dir | awk -F/ '{print $2}'`
   if (! -e $WorkPath/$out_dir_exam) then
      mkdir $WorkPath/$out_dir_exam
   endif
   if (! -e $WorkPath/$out_dir) then
      mkdir $WorkPath/$out_dir
      if ($DEBUG2) echo "[$dir] Created output dir $WorkPath/$out_dir for $dir" |& tee -a $LOG_FILE
      if ($DEBUG2) echo "[$dir] `date` " |& tee -a $LOG_FILE
   endif
   
   #--- check to make sure directory was successfully created ---
   if (! -e $WorkPath/$out_dir) then
      echo "[$dir] Error creating output directory: $WorkPath/$out_dir . Aborting script." |& tee -a $LOG_FILE
      exit()
   endif
   
end

#--- add output to check success of rename script ---
#echo "echo 1" >> $LogPath/rename.$dir

#========================================================
# RENAME DICOM FILES 
#--------------------------------------------------------

#--- Run renaming script ---
#set rename_success = 0
if ($DEBUG2) echo "[$dir] renaming..." |& tee -a $LOG_FILE
#set rename_success = `tcsh $LogPath/rename.$dir`
if ($DEBUG2) echo "[$dir] renaming $dir at (`date`)" |& tee -a $LOG_ERROR
tcsh $LogPath/rename.$dir |& tee -a $LOG_ERROR

#--- check for errors ---
#if ("$rename_success" == 1) then
#   echo "Success in renaming files." |& tee -a $LOG_FILE
#else
#   echo "Error in renaming files. Aborting script." |& tee -a $LOG_FILE
#   exit()
#endif

#========================================================
# ANONYMIZE DICOM FILES
#--------------------------------------------------------

#--- anonymize dicoms ---
foreach out_dir ($out_dirs)
   if ($DEBUG2) echo "[$dir] anonymizing $out_dir..." |& tee -a $LOG_FILE
   if ($DEBUG2) then
      echo "[$dir] start anonymize at: `date`" |& tee -a $LOG_FILE
      #date |& tee -a $LOG_FILE
   endif
   #Anonymizes the following fields:
   #   (0010,0010) = PatientName
   #   (0010,0030) = PatientBirthDate
   #   (0010,21b0) = AdditionalPatientHistory
   
   dcmodify --no-backup -ma "(0010,0010)=X" -ma "(0010,0030)=00000000" -ma "(0010,21b0)=X" $WorkPath/$out_dir/*dcm

   #dcmodify --no-backup -ma "(0010,0010)=X" -ma "(0010,0030)=00000000" -ma "(0010,0040)=X" -ma "(0010,1010)=X" -ma "(0010,1030)=0" -ma "(0010,21b0)=X" $RootPath/$out_dir/*dcm
   #ABOVE COMMENTED OUT to keep the following:
   #   (0010,0040) = PatientSex
   #   (0010,1010) = PatientAge
   #   (0010,1030) = PatientWeight
   
   if ($DEBUG2) then
      echo "[$dir] end anonymize at: `date`" |& tee -a $LOG_FILE
      #date |& tee -a $LOG_FILE
   endif
   
end

#TMP_DEBUG
#exit()

#(commented out - file count will be based on tar file)
#--- Save info for checking transfer status ---
#cd $RootPath/
#echo "==================================="       |& tee -a $LOG_INFO
#echo "Numbers of files in each directory:"       |& tee -a $LOG_INFO
#echo "-----------------------------------"       |& tee -a $LOG_INFO
#foreach out_dir ($out_dirs)
#   set NumFiles = `ls $RootPath/$out_dir | wc -l` 
#   echo "[`date`] Transferred $NumFiles files to $out_dir" |& tee -a $LOG_INFO
#end
#echo "-----------------------------------"       |& tee -a $LOG_INFO

#========================================================
# TAR DICOM FILES 
#--------------------------------------------------------
TAR:

#--- tar ---
set all_outputs_exist = 1
foreach out_dir ($out_dirs)

   if ($DEBUG2) echo "[$dir] Processing series: $out_dir ..." |& tee -a $LOG_FILE
   
   #--- split out_dir (E12345/s000001.Localizer) into Exam and Series ---
   set out_dir_exam   = `echo $out_dir | awk -F/ '{print $1}'`
   set out_dir_series = `echo $out_dir | awk -F/ '{print $2}'`
   set out_dir_series_num = `echo $out_dir | awk -F/ '{print $2}' | awk -F. '{print $1}'`
   
   #--- Determine output directory (/Volumes/Studies/<Investigator>/<StudyID>/<SubjID>)---
   #set dcm_file = `/bin/ls $RootPath/$out_dir/*dcm | head -1`
   set dcm_file = `find $WorkPath/$out_dir -name "*dcm" -print | head -1`
   set OutputPathString = `dcmdump --search "0008,0090" $dcm_file | awk -F[ '{print $2}' | awk -F] '{print $1}'`
   set OutStudyPath = `echo $OutputPathString | awk -F^ '{print $1}' | sed 's/ /_/g'`
   set SubjIDx      = `echo $OutputPathString | awk -F^ '{print $2}' | sed 's/ /_/g'`
   if ($DEBUG3) then
      echo "RootPath: $RootPath"
      echo "WorkPath: $WorkPath"
      echo "out_dir: $out_dir"
      echo "dcm_file: $dcm_file"
      echo "OutputPathString: $OutputPathString"
      echo "OutStudyPath: $OutStudyPath"
      echo "SubjIDx: $SubjIDx"
   endif
   
   #--- replace special characters in SubjID (&*?$:;,|(){}\) and replace slash (/) with dash (-) ---
   # (Note: certain characers ("'`) will still cause problems. These are harder to replace in tcsh, so let's not use those in SubjID, m'kay) 
   set noglob
   set SubjID = `echo $SubjIDx | sed 's/[&*?\$:;,|(){}\]//g' | sed 's/\//-/g'`
   unset noglob
   if ($DEBUG3) echo "SubjID: $SubjID"
   
   #--- Look for closest matches if output dirs do not exist ---
   if ($DEBUG3) echo "[$dir] Looking for Output Path $OutPath/$OutStudyPath" |& tee -a $LOG_FILE
   set use_default_dir = 0
   if (! -e $OutPath/$OutStudyPath) then
      echo "[$dir] Could not find output path: $OutPath/$OutStudyPath. Attempting to find closest match." |& tee -a $LOG_FILE
      
      set PathToSearch = $OutPath
      set ND = `echo $OutStudyPath | awk -F/ '{print NF}'`
      foreach nd (`seq 1 $ND`)
         
	 set dir_to_find = `echo $OutStudyPath | awk -F/ '{print $'$nd'}' | sed 's/ /_/g'`
	 
	 if (-e $PathToSearch/$dir_to_find) then
	    echo "[$dir] Found $dir_to_find in $PathToSearch ($nd of $ND)" |& tee -a $LOG_FILE
	    set PathToSearch = $PathToSearch/$dir_to_find
	    if ($nd == 1) then
	       set OutStudyPathCorrect = $dir_to_find
	    else
	       set OutStudyPathCorrect = $OutStudyPathCorrect/$dir_to_find
	    endif
	    
	 else
	    #--- Look for closest match ---
	    echo "[$dir] Looking for $dir_to_find in $PathToSearch ($nd of $ND)" |& tee -a $LOG_FILE
	    set dir_match = `$ScriptPath/find_closest_dir.sh $dir_to_find $PathToSearch`
	    if (! -e $PathToSearch/$dir_match) then
               echo "[$dir] Could not find closest match for study. Using Exam number as output dir." |& tee -a $LOG_FILE
               set use_default_dir = 1
	       continue
	    else
               echo "[$dir] Found match: $dir_match (in $PathToSearch)" |& tee -a $LOG_FILE
	       set PathToSearch = $PathToSearch/$dir_match
	       if ($nd == 1) then
		  set OutStudyPathCorrect = $dir_match
	       else
		  set OutStudyPathCorrect = $OutStudyPathCorrect/$dir_match
	       endif
	    endif
	 endif 
	    
      end
      if (! $use_default_dir) then
         set OutStudyPath = $OutStudyPathCorrect
	 echo "[$dir] using output path: $OutStudyPath" |& tee -a $LOG_FILE
      else
         echo "[$dir] using default output path" |& tee -a $LOG_FILE
      endif
      
   endif
   
   #--- check to make sure fields are not null ---
   if ("$OutStudyPath" == "" || "$SubjID" == "") then
      if ($DEBUG2) echo "[$dir] Output path or subject ID is null. Using default output path." |& tee -a $LOG_FILE
      set use_default_dir = 1
   endif
   
   #--- (Special Case) For some sequences, e.g. Fmap, wait for all images (2 x NZ) ---
   set psd = `dcmdump --search "0019,109c" $dcm_file | awk -F[ '{print $2}' | awk -F] '{print $1}'`
   set NZ  = `dcmdump --search "0020,1002" $dcm_file | awk -F[ '{print $2}' | awk -F] '{print $1}'`
   set NZ2 = `echo "$NZ * 2" | bc`
   set num_ims = `ls $RootPath/$out_dir | wc -l`
   if ("$psd" == "/usr/g/wpsd/fmap" && $NZ2 != $num_ims) then
      echo "[$dir] (fmap) Only found $num_ims images for $out_dir. Expecting $NZ2. Skipping to next run." |& tee -a $LOG_FILE
      #set all_outputs_exist = 0 #uncomment if you do not want to remove tmp, dicomdump, etc.
      continue
   endif
   
   #--- Create final output directory ---
   if ($use_default_dir) then
      set FinalPath0      = $DefOutPath/$out_dir_exam
      set FinalPath       = $DefOutPath/$out_dir_exam/dicoms
      set FinalPhysioPath = $DefOutPath/$out_dir_exam/ge_physio
      set FinalShimPath   = $DefOutPath/$out_dir_exam/shim_log
   else
      set FinalPath0      = $OutPath/$OutStudyPath/$SubjID 
      set FinalPath       = $OutPath/$OutStudyPath/$SubjID/dicoms 
      set FinalPhysioPath = $OutPath/$OutStudyPath/$SubjID/ge_physio
      set FinalShimPath   = $OutPath/$OutStudyPath/$SubjID/shim_log
   endif
   
   if (! -e $FinalPath0) then
      mkdir $FinalPath0
   endif
   if (! -e $FinalPath) then
      mkdir $FinalPath
   endif
   if (! -e $FinalPhysioPath) then
      mkdir $FinalPhysioPath
   endif
   if (! -e $FinalShimPath) then
      mkdir $FinalShimPath
   endif
   
   set tar_file = $out_dir_exam.$out_dir_series.tgz
   
   cd $WorkPath/$out_dir_exam
   if (! -e $FinalPath/$tar_file) then
      if ($DEBUG) echo "[$dir] tarring $out_dir_series... ($FinalPath/$tar_file)" |& tee -a $LOG_FILE
      tar -czvf $FinalPath/$tar_file $out_dir_series >& /dev/null
   else
      echo "[$dir] Output tar file ($FinalPath/$tar_file) already exists." |& tee -a $LOG_FILE
      if ($SAVE_DUP_TAR) then
         set new_suffix = `date +%F_%H-%M-%S`
         set tar_file = $out_dir_exam.$out_dir_series.$new_suffix.tgz
	 echo "[$dir] Creating new tar file from $out_dir_series with date and time as suffix.($tar_file)" |& tee -a $LOG_FILE
	 tar -czvf $FinalPath/$tar_file $out_dir_series >& /dev/null
      endif
   endif
   
   if (! -e $FinalPath/$tar_file || -z $FinalPath/$tar_file) then
      echo "[$dir] Error in creating tar file $tar_file" |& tee -a $LOG_FILE
      #continue
   else
      set NumFiles1 = `tar -tzvf $FinalPath/$tar_file | wc -l` 
      @ NumFiles = $NumFiles1 - 1 #tar also lists the root directory, so the file count is too high by 1
      echo "[`date`] Transferred $NumFiles files to $FinalPath/$tar_file" |& tee -a $LOG_INFO
   endif
   
   #--- Create series_info.txt file (useful info from dicom header) ---
   if ($DEBUG2) echo "[$dir] Adding to exam info file ($FinalPath/info.$out_dir_exam.txt) ..." |& tee -a $LOG_FILE
   $ScriptPath/create_exam_info_file.csh $dcm_file $FinalPath/info.$out_dir_exam.txt
   
   #--- Look for physio and move it to output ---
   if ($DEBUG2) echo "[$dir] Checking for physio..." |& tee -a $LOG_FILE
   set PhysioPath = /Volumes/.tmp_physio
   set physio_file = physio.$out_dir_exam.$out_dir_series_num.tar
   if (-e $PhysioPath/$physio_file) then
      if (! -e $FinalPhysioPath/$physio_file) then
         mv $PhysioPath/$physio_file $FinalPhysioPath/
      else
         echo "[$dir] Physio file $physio_file already exists in $FinalPhysioPath" |& tee -a $LOG_FILE
	 #--- check to see if physio files are the same ---
	 set check_diff = `diff $PhysioPath/$physio_file $FinalPhysioPath/$physio_file | head -1 | awk '{print $1}'`
	 
	 #--- if not the same, create a new filename ---
	 if ("$check_diff" != "") then
	    set new_suffix = `date +%F_%H-%M-%S`
	    set physio_file_new = physio.$out_dir_exam.$out_dir_series_num.$new_suffix.tar
	    if (! -e $FinalPhysioPath/$physio_file_new) then
	       mv $PhysioPath/$physio_file $FinalPhysioPath/$physio_file_new
	    else
	       echo "[$dir] For some reason there is already a physio file with the exact same time-stamp-encoded filename." |& tee -a $LOG_FILE
	       echo "[$dir] Physio file will not be transferred." |& tee -a $LOG_FILE
	    endif
	 else
	    echo "[$dir] Physio file ($physio_file) already exists in $FinalPhysioPath and is identical. Not transferring physio." |& tee -a $LOG_FILE
	 endif
      endif
   endif
   
   #--- Look for shim info and move it to output ---
   if ($DEBUG2) echo "[$dir] Checking for shim info..." |& tee -a $LOG_FILE
   ##COMMENTED OUT - fix filenames for shim files instead
   ##(get rid of E and s which are part of exam and series num)
   #set out_dir_examX = `echo $out_dir_exam | sed 's/E//g'`
   #set out_dir_series_numX = `echo $out_dir_series_num | sed 's/s//g'`
   set shim_file = log_shim.$out_dir_exam.$out_dir_series_num.txt 
   if (-e $PhysioPath/$shim_file) then
      if (! -e $FinalShimPath/$shim_file) then
         echo "[$dir] Moving shim file ($PhysioPath/$shim_file) to $FinalShimPath" |& tee -a $LOG_FILE
         mv $PhysioPath/$shim_file $FinalShimPath/
      else
         echo "[$dir] shim file $shim_file already exists in $FinalShimPath" |& tee -a $LOG_FILE
	 #--- check to see if shim files are the same ---
	 set check_diff = `diff $PhysioPath/$shim_file $FinalShimPath/$shim_file | head -1 | awk '{print $1}'`
	 
	 #--- if not the same, create a new filename ---
	 if ("$check_diff" != "") then
	    set new_suffix = `date +%F_%H-%M-%S`
	    set shim_file_new = log_shim.$out_dir_exam.$out_dir_series_num.$new_suffix.tar
	    if (! -e $FinalShimPath/$shim_file_new) then
	       mv $PhysioPath/$shim_file $FinalShimPath/$shim_file_new
	    else
	       echo "[$dir] For some reason there is already a shim file with the exact same time-stamp-encoded filename." |& tee -a $LOG_FILE
	       echo "[$dir] shim file will not be transferred." |& tee -a $LOG_FILE
	    endif
	 else
	    echo "[$dir] shim file ($shim_file) already exists in $FinalShimPath and is identical. Not transferring physio." |& tee -a $LOG_FILE
	 endif
      endif
   else
      echo "[$dir] shim file ($PhysioPath/$shim_file) does not exist." |& tee -a $LOG_FILE
   endif
   
   #=== Cleanup ===
   if (-e $FinalPath/$tar_file && ! -z $FinalPath/$tar_file) then
      
      #--- safety catch to make sure we do not remove $RootPath ---
      set check_null = `echo $out_dir | awk '{print $1}'`
      if ("$check_null" == "") then
         echo "[$dir] output (working) dir does not exist. (This should not happen.)" |& tee -a $LOG_FILE
	 continue
      endif
      
      #--- check WorkPath ---
      if ($WorkPath != $RootPath/out.$dir) then
         echo "WorkPath ($WorkPath) is incorrectly defined. (This should not happen.)" |&  tee -a $LOG_FILE
	 continue
      endif
      
      if ($DEBUG) echo "[$dir] tar file exists. Removing output (working) directory..." |& tee -a $LOG_FILE
      if (-e $RootPath/out.$dir/$out_dir) then
         if ($DEBUG2) echo "[$dir] Removing $RootPath/out.$dir/$out_dir ($dir) (`date`)" |& tee -a $LOG_FILE
	 #if ($DEBUG2) date |& tee -a $LOG_FILE
	 #rm -rf $WorkPath/$out_dir
	 #NOTE: I've gone to a more hard-coded version of the rm command to avoid potential problems if the WorkPath is misdefined
	 rm -rf $RootPath/out.$dir/$out_dir
      else
         echo "[$dir] Could not find output (working) directory $out_dir." |& tee -a $LOG_FILE
      endif
      
   else
      set all_outputs_exist = 0
   endif

   
end 

#========================================================
# CLEANUP
#--------------------------------------------------------

#=== Cleanup ===
if ($CLEANUP) then
if ($all_outputs_exist) then
   
   #--- keep the following around for a bit for debugging purposes ---
   if (! -e $LogPath/rename.$dir.gz) then
      gzip $LogPath/rename.$dir
   endif
   
   #--- Remove temporary files ---
   if ($DEBUG2) echo "[$dir] Cleaning tmp..." |& tee -a $LOG_FILE
   rm -f $TmpPath/x.$dir.0
   rm -f $TmpPath/x.$dir.i
   rm -f $TmpPath/x.$dir.s
   rm -f $TmpPath/x.$dir.d
   rm -f $TmpPath/x.$dir.e
   rm -f $TmpPath/x.$dir.p
   rm -f $TmpPath/x.$dir.s2
   rm -f $TmpPath/x.$dir.dir
   rm -f $TmpPath/x.$dir.out
   rm -f $TmpPath/x.$dir.full
   rm -f $TmpPath/x.$dir.file
   rm -f $TmpPath/x.$dir.exam
   rm -f $TmpPath/x.$dir.exam2
   rm -f $TmpPath/x.$dir.series
   rm -f $TmpPath/x.$dir.inst
   rm -f $TmpPath/x.$dir.desc
   rm -f $TmpPath/x.$dir.dup
   rm -f $TmpPath/x.$dir.dup.s
   rm -f $TmpPath/x.$dir.dup2
   rm -f $TmpPath/x.$dir.es
   rm -f $TmpPath/list.$dir.txt

   #--- remove header_info_file = dicom header info (key fields) for each image. This file can be quite large ---
   if (-e $header_info_file) then
      if ($DEBUG2) echo "[$dir] Removing $header_info_file ..." |& tee -a $LOG_FILE
      rm -f $header_info_file
   endif
   
   #--- safety catch to make sure we do not remove $RootPath ---
   set check_null = `echo $dir | awk '{print $1}'`
   if ("$check_null" == "") then
      echo "[$dir] Odd. For some reason storescp landing dir ($dir) is null. Aborting cleanup." |& tee -a $LOG_FILE
      exit()
   endif
   
   #--- remove storescp's landing dir ($RootPath/$dir) ---
   if (-e $RootPath/$dir) then
      if ($DEBUG2) echo "[$dir] Removing $RootPath/$dir ..." |& tee -a $LOG_FILE
      rm -rf $RootPath/$dir
   endif
   
   #--- Remove temporary processing directory (if empty) ---
   rmdir --ignore-fail-on-non-empty $RootPath/out.$dir/$out_dir_exam/dicoms
   rmdir --ignore-fail-on-non-empty $RootPath/out.$dir/$out_dir_exam/ge_physio
   rmdir --ignore-fail-on-non-empty $RootPath/out.$dir/$out_dir_exam/shim_log
   rmdir --ignore-fail-on-non-empty $RootPath/out.$dir/$out_dir_exam
   rmdir --ignore-fail-on-non-empty $RootPath/out.$dir/
   
   
endif
endif #CLEANUP

echo "[$dir] dicom_decoder.csh done at `date`" |& tee -a $LOG_FILE
time |& tee -a $LOG_FILE
exit()


