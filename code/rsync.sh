###ABOUT###
# This file contains two pieces of code. When they are used
# together they create a semi-flexible backup solution
# using rsync.
# This setup really isn't all that powerful and probably
# shouldn't be used in anything larger than a simple SOHO
# environment.For a similar enterprise solution, 
# check out rdiff-backup.
###LEGAL###      
# This script free in all senses.  Use it however you
# want. Feel free to claim it, modify it, use it, sell
# it, etc. Additionally, you may not hold me responsible
# for any pain and suffering this script may inflict on 
# you or your machines. 
###INSTALL###
# Modify the code in the SCRIPT 1 section to meet your 
# requirements, then copy this code to a file named
# rsync.sh.  Make rsync.sh executable by
# issuing a chmod +x rsync.sh.  Create a cron 
# entry that runs this script at whatever interval
# you want to copy modified and new files to the 
# backup location (ie: daily).  Now modify the code 
# in the SCRIPT 2 section to meet your requirements, 
# then copy that code to a file named rsync-prune.sh. 
# chmod +x rsync-prune.sh.  Schedule cron to run this
# script occasionally based on how much space you have
# at the destination and how long you want to hold 
# "retention points" for (ie: monthly after a tape dump).  
###FLAWS IN THIS SETUP###
# Your backup directory will only retain the most
# recent version of a file and not any previous 
# revisions.  
# The prune job will delete all "retention points"
# and anything that has changed or went away on the source
# will go away on the destination.  If you are super paranoid,
# don't schedule rsync-prune to run from cron and only run 
# it manually when you are running out of space at the destination
# and after you have done a full backup to a removable media, like 
# tape.  
#
#
###SCRIPT 1 (rsync.sh)####
#!/bin/sh
#Source directory.  The root of what you want to backup.
SOURCE="/storage"
#Destination directory.  Where to put the backups. 
DESTINATION="/backups"
#Location of sleep. Set manually if below doesn't work. 
SLEEP=`type -p sleep`
#Location of mount. Set manually if below doesn't work. 
MOUNT=`type -p mount`
#Location of rsync. Set manually if below doesn't work. 
RSYNC=`type -p rsync`
#Wait briefly.  
$SLEEP 5
#My suggestion is to keep your destination backup directory
#mounted all the time by adding a line to your fstab. But I
#suggest keeping it mounted as read only except for when the 
#backup is running.  This way you can restore files if needed,
#and if you fat finger something big time, you want wipe out 
#your backups as well.   
#Remount the destination as writable.  
$MOUNT -o remount,rw $DESTINATION
#Wait for the mount to complete.
$SLEEP 10
#Do the backup using rsync.  Keep ACLs and extended
#attributes if your version of rsync and your filesystem 
#supports it.  If you get errors do a rsync --help and
#remove any options from below that you don't need and try
#again.  
$RSYNC -vaHxAXE --progress $SOURCE/ $DESTINATION/
#Wait for the backup to complete.
$SLEEP 10
#Make your destination directory read only again. 
$MOUNT -o remount,ro $DESTINATION
#
#
###SCRIPT 2 (rsync-prune.sh)####
#!/bin/sh
#Source directory.  The root of what you want to backup.
SOURCE="/storage"
#Destination directory.  Where to put the backups. 
DESTINATION="/backups"
#Location of sleep. Set manually if below doesn't work. 
SLEEP=`type -p sleep`
#Location of mount. Set manually if below doesn't work. 
MOUNT=`type -p mount`
#Location of rsync. Set manually if below doesn't work. 
RSYNC=`type -p rsync`
#Wait briefly.
$SLEEP 5
#My suggestion is to keep your destination backup directory
#mounted all the time by adding a line to your fstab. But I
#suggest keeping it mounted as read only except for when the 
#backup is running.  This way you can restore files if needed,
#and if you fat finger something big time, you want wipe out 
#your backups as well.   
#Remount the destination as writable.  
$MOUNT -o remount,rw $DESTINATION
#Wait for the mount to complete.
$SLEEP 10
#Do the backup using rsync.  Keep ACLs and extended
#attributes if your version of rsync and your filesystem 
#supports it.  If you get errors do a rsync --help and
#remove any options from below that you don't need and try
#again. In addition to doing this, remove any files from the
#destination that are no longer on the source.   
$RSYNC -vaHxAXE --progress --delete $SOURCE/ $DESTINATION/
#Wait for the backup to complete.
$SLEEP 10
#Make your destination directory read only again. 
$MOUNT -o remount,ro $DESTINATION
#
#
