#!/bin/bash
#This script will check for defunct user accounts.  
#In short, it assumes that anybody who hasn't modified any files in their home
#directory in the past two years is likely a defunct user.   
#I usually follow up these checks with emails and queries to the personnel department.


#Assumptions:
#Your home folder structure is like this
#/home/a/alice
#/home/b/bob
#If it isn't, just remove the cd ${i} and cd .. lines.

#Debugging
#set -x

#Location of the home parent folder. 
BASEDIR="/home"
#Where to write the list of inactive users. 
BADUSERS="/root/inactive_users.txt"

#Cleanup past runs trash
rm -f ${BADUSERS}

#Do the work
cd ${BASEDIR}
#for a, b, c, etc
for i in *
do
#remove this if you use a flat home structure 
cd ${i}
#for the user folders a, b, c, etc
	for x in *
	do
	AGECHECK="$(find $x -type f ! -mtime +730 -print)"
#if no files are found newer than 2 years add the user to a list. 
		if [ -z "${AGECHECK}" ]
		then
		echo $x >> ${BADUSERS}
		fi
	done
#Done with the user dirs, go back up the the letter folders. 
#remove this if you use a flat home structure
cd ..
done
