#!/bin/bash 
#This ugly script will take a list of users in userlist.txt and then search
#through our home directory structure for them.  If they are found, a du -Hs is ran
#against them and then outputted into disk_usage_summary.txt.  
#
#For this to work, your home directory structure must look like this:
#/home/a/alice
#/home/b/bob. 
#If it does not, you will need to edit the find mindepth and maxdepth
#and the gawk -F"/" '{print $4}' stuff to meet your structual needs.
#DM 

INPUT="userlist.txt"
OUTPUT="disk_usage_summary.txt"
BASEDIR=/home

#debugging 
#set -x 

#remove any stale files
rm -f ${OUTPUT}
rm -f ${OUTPUT}.tmp

#do the work
#for each user in the input file, look up to two directories deep for it 
#and if it is found do a du -hs on it and put it in a temp file. 
#doing it this way prevents excess load when compared to a du -hs * or similar. 
cat ${INPUT} | while read LINE
do
        find ${BASEDIR} -type d -mindepth 1 -maxdepth 2 -iname $LINE | xargs du -hs >> ${OUTPUT}.tmp
done

#looks like 
#5.3Gb  /home/d/dminnich 

#make the output pretty 
#/home/d/dminnich,5.3G | dminnich,5.3G | remove garbage | sort by username
gawk -F" " '{ print $2","$1}' ${OUTPUT}.tmp | gawk -F"/" '{print $4}' | gawk '$0!~/^$/ {print $0}' | sort > ${OUTPUT}
#remove the temp file
rm -f ${OUTPUT}.tmp
#At this point a open the CSV in OO Calc and do some graphing stuff.
