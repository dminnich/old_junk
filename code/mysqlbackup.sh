#!/bin/sh
###ABOUT###
#This is a simple backup script that uses tar.  
#It is not very flexible or powerful.  It is 
# intended for people that have only a few computers
# and not much data to backup. Example: configure this 
# script on each client and automate its running by 
# creating a cron job for it, have the destination set
# to a NFS share on a central server. All clients are
# now backing up their core files to one place.  
###LEGAL###      
# This script free in all senses.  Use it however you
# want. Feel free to claim it, modify it, use it, sell
# it, etc. Additionally, you may not hold me responsible
# for any pain and suffering this script may inflict on 
# you or your machines.  

#NOTES: 
#This script deletes EVERYTHING in the destination directory 
# that is over 7 days old.  This is to prune backups.  Don't
# keep anything but backups in the destination directory or 
# it will eventually go away.  YOU HAVE BEEN WARNED.  
#RHEL5 or higher is needed for tar to backup
# acls and xattrs.  If the script throws errors and 
# you don't care about such things, simply remove those
# parmaters from the tar line. You may also want to look into
# star.  
#Try not to use spaces in any of the variable assignments. 
# IE don't let one of the source dirs be "/Data For Backup". 
# It may work or it may not.  I haven't tested it.      

#Destination directory.  Where to put the backups. 
DESTINATION=/opt/mysql_backups
#Put todays date in a variable. Will be used in the filename. 
DATE=`date +%F`
#Hostname of the server.  Will be used in the filename.
HOSTNAME=`echo $HOSTNAME`
#Location of bzip2. Set manually if below doesn't work. 
BZIP2=`type -p bzip2`
#Location of mysqldump. Set manually if below doesn't work. 
MYSQLDUMP=`type -p mysqldump`
#Location of find. Set manually if below doesn't work. 
FIND=`type -p find`
#Location of xargs. Set manually if below doesn't work. 
XARGS=`type -p xargs`
#Location of rm. Set manually if below doesn't work. 
RM=`type -p rm`
#Location of cp. Set manually if below doesn't work. 
CP=`type -p cp`

#Remove ALL FILES in the destination directory that are over a week old. Change
# "7" to keep more/less.  This is used to prune backups.   
$FIND $DESTINATION -type f -atime +7 -print | $XARGS $RM
#Backup the databases.  
$MYSQLDUMP --add-drop-table --all-databases | $BZIP2 -c >$DESTINATION/$HOSTNAME-$DATE.bz2
