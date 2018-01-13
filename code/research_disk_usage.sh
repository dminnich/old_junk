#!/bin/bash
#simple and ugly script to gather DF statistics for similarly named devices or mounts.

#We create logical volumes for each research lab we support on various servers and mount
#them in similar locaions, ie:
#/mnt/research/lv00/lab1_name
#/mnt/research/lv01/lab2_name
#DM

#remove any leftover trash from the last run
rm -f /root/space_usage*

#replace research with the name of the mount point or device you want to match on. 
#replace THIS_SERVERS_NAME with the hostname of this box. This lets you know what volumes are on what boxes
#if you have more than one file server.
#1-5 are Filesystem             Size   Used  Avail Use% Mounted on. 
df -H | grep research | awk ' { print "THIS_SERVERS_NAME,"$1","$2","$3","$4","$5 }' >> /root/space_usage.txt
#open the previously created file
cat /root/space_usage.txt | while read LINE; 
#for each mount that matched the search do..
        do
#store the directoy listing of the Mounted On piece  (ie: lab1_name) as a var. 
        VAR=$(ls `echo $LINE|awk -F, '{print $6}'`)
#create a new file where this in incorporated in the csv.  
#remove lost+found. replace any comma spaces with just a comma.
        echo ${LINE},${VAR}|sed s/lost+found//|sed 's/, /,/'>>/root/space_usage2.txt;
done
#space_usage2.txt now looks like this:
#THIS_SERERS_NAME,100G,100G,0G,100%,/mnt/research/lv00,lab1_name
#Box hosting the share,total volume size, used space, free space, percentage of space in use, mount location, listing of directories under the mount location (in our case the name of the lab).  

#I now copy the output of all of these files into OO Calc and build some charts.  
