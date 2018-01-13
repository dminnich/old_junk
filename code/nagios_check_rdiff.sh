#!/bin/bash
#This script should be ran by nagios via NRPE or SSH on your rdiff-backup server. 
#It checks to make sure the hosts backing up to it have had a good backup in the 
#last two days.  

#Assumptions:
#Your backups are stored in a manner similar to this
#/md2/backups/hosta
#/md3/backups/hostz


#Debugging
#set -x

#Full paths to the directories that hold the client folders and their backups.
#Basically, one level above the rdiff destinations.  
#Defining only one folder should be fine as well.  
BASEDIRS='/md2/backups /md3/backups'

#Folders/clients in the basedirs folders that we don't want to check for current
#backups for.  Basically, defunct clients. 
#You may need at least one exclude for the script to work, if so, just throw some 
#random characters together. 
EXCLUDELIST='oldhosta oldhostb' 
#The empty array that will hold all the excludes. 
EXCLUDEARR=( )
#The empty array that will hold all the valid rdiff clients. 
VALIDCLIENTS=( )
#The empty array to hold the problem hosts. 
BADHOSTS=( )
#The emplty arry to hold the hosts with good backups. 
GOODHOSTS=( )
#Today.  Will be used as a grep argument later. 
TODAY="$(date | cut --delimiter=" " -f1,2,3)"
#Yesterday.  Will be used as a grep argument later. 
YESTERDAY="$(date -d "yesterday" | cut --delimiter=" " -f1,2,3)"

#Build the exclude paramater array by processing the Excludes list. 
#This is a greedy match, if an exclude word is anywhere in the path it will 
#be dropped.
for y in `echo ${EXCLUDELIST}`
do
#basically building one long grep command piece by piece
	EXCLUDEARR[${#EXCLUDEARR[*]}]='-e '.*$y.*''
done

#For each directory that holds rdiff backup directories underneath it,
#list the directories minus the ones we want to exclude in the validclients array.
for x in ${BASEDIRS}
do
	VALIDCLIENTS=( "${VALIDCLIENTS[@]}" "`find $x -type d -maxdepth 1 -mindepth 1 | grep ${EXCLUDEARR[@]} -v`" )
done


#For every path in the validclients array run a rdiff list increments command, crop it
#to the current mirror and see if it occured in the last 48 hours.
for z in ${VALIDCLIENTS[@]}
do
###Standard output. Useful as a standalone script. 
###	echo $z
###	rdiff-backup --list-increments $z | tail -n 1 
#This command will return nothing if the current mirror happened in the last 48 hours. 
BACKUPCHECK="$(rdiff-backup --list-increments $z | tail -n 1 | grep -e "${TODAY}" -e "${YESTERDAY}" -v)"
#If the command returns anything at all, assume that its current mirror is either older than two days
#or that it is complaining about something else we need to see and add the client to the BADHOSTS
#array. 
if [ -n "${BACKUPCHECK}" ]
then
	BADHOSTS=( "${BADHOSTS[@]}" "$z" )
#If the backupcheck command returns no output assume that the host had a good backup in the 
#last 48 hours and add it to the goodhosts array.  
else
	GOODHOSTS=( "${GOODHOSTS[@]}" "$z" )
fi
done

#If the badhosts array has anything in it, exit with a critical status.  
if [ -n "${BADHOSTS}" ]
then
EXITSTATUS=2
else
EXITSTATUS=0
fi

echo "Hosts missing backups: ${BADHOSTS[@]}. Hosts with good backups: ${GOODHOSTS[@]}."
exit $EXITSTATUS
