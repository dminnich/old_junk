#!/bin/bash 
#Ugly bash script used by nagios to check for read only filesystem mounts.  
#Useful to see if a filesystem got corrupted.
#DM
CHECK=`mount | grep -e "(rw.*)" -v`
if [ -n "${CHECK}" ]
then
        echo "Read Only mount detected on: "${CHECK}  
        EXITSTATUS=2
else
        echo "OK."
        EXITSTATUS=0
fi
exit $EXITSTATUS
