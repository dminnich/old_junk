#!/bin/bash
#This script looks for new and important information in our remote hosts logs on our syslog server. 

#Assumptions:
#You are running this on a syslog server. 
#It is storing others hosts logs like this
#/logs/hosts/hosta/messages
#You only care about messages and secure. 
#You want messages from the last 3 days.  

##These things are easy to chage.  
#change find /logs/hosts/ to find /var/log/ for use on a single machine. 
#add extra -o -name logname sets to the find command to look inside more logs.

#NOTE: This is slow and an ugly hack.  I'm sure there are better tools and better languages to use when doing stuff like this.


#
#Remove any left over files from last run
rm -f /root/gs_file_list
rm -f /root/gs_output
#
#Create a list of all of the logs that grep needs to step through. 
#Only look at secure and messages
find /logs/hosts \( -name "messages" -o -name "secure" \) -print > /root/gs_file_list
#Sort the file
sort -bfi -o /root/gs_file_list /root/gs_file_list
#I want to look at a backlog of 3 days worth of messages.  
#NOTE: Will NOT work if log files that aren't kept in Abr Month day format.  Thats (Oct  7).  Note 2 spaces and no zero padding on the date.  
#Set the day variables
TODAY=$(date +"%b %e")
YESTERDAY=$(date -d "yesterday" +"%b %e")
DBF=$(date -d "-48 hours" +"%b %e")

#There are a lot of messages in the logs I consider normal.  I want to find messages in the logs that do NOT match the following.  Uncomment or add a new one, then add it to the grep command below following established syntax.
EXCLUDE1="authenticated unmount request from"
EXCLUDE2="authenticated mount request from"


#For each line in the log list file--- copy the line (path) to the sanatized final ouput so you know where the messages came from. Then find lines in the file that occured during the last 3 days. Finally, pipe that to another grep that takes out the exclude lines and save the results to the output file.  
cat /root/gs_file_list | while read LINE;
do 
	echo $LINE>>/root/gs_output; 
	grep ".*`echo "$TODAY"`.*\|.*`echo "$YESTERDAY"`.*\|.*`echo "$DBF"`.*" $LINE | grep -e "${EXCLUDE1}" -e "${EXCLUDE2}" -v>>/root/gs_output;
done


