#!/bin/sh

#This script was written for some specific servers that I administer. However, it should not be hard to adapt it to your   enviroment. Just change the location of the 'CMD...' vars if necessary. Obviously you will need all the applications and   executable permissions to all the applications below to get the output we want. Generally it is best to run this script as root. You will probably want to setup a cron job to run this script on a regular basis.   

##If you choose not to use a certain application or part of this script you _must_ comment it out.  Otherwise the script   will throw errors when you run it.  


###Note:  I am positive there are more efficient ways to accomplish this same task.  This is just something I threw        together in a day. If you have  any suggestions please email me them.


##Define file name
#File will be put in the same directory as this script.  So you will need write permissions.    

OUTPUT=status.txt
##Does file exsist?  Yes, create 1 backup.  No, create file.
if [ -e "$OUTPUT" ]; then 			
mv -f $OUTPUT $OUTPUT.old
touch $OUTPUT
else 
touch $OUTPUT
fi 	
	
##Machine name
echo MACHINE:>>$OUTPUT
echo $HOSTNAME>>$OUTPUT

#Breaking line, to make the output look pretty.
echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

#Machine uptime
CMDUPTIME=/usr/bin/uptime
echo UPTIME:>>$OUTPUT
$CMDUPTIME>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

##Free Disk Space
CMDDF=/bin/df
echo FREE DISK SPACE:>>$OUTPUT
$CMDDF -l>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT


##Free Memory 
CMDFREE=/usr/bin/free
echo MEMORY USAGE:>>$OUTPUT
$CMDFREE -mt>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT


##Hard Drive Status
#This requires smartmontools and for smart to be enabled on your hard drives.  See smartmontools docs for more info.       Comment out the drives you don't have / don't want status for.  Add any drives that aren't listed below.  
#CMDSMARTCTL=/usr/sbin/smartctl
#echo STATUS OF HDA:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hda>>$OUTPUT

#Single line "-" to indicate output of same command but on different device.
#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDB:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hdb>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDC:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hdc>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDD:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hdd>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDE:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hde>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDF:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hdf>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo STATUS OF HDG:>>$OUTPUT
#$CMDSMARTCTL -a /dev/hdg>>$OUTPUT

#echo --------------------------------------------------------->>$OUTPUT
#echo $'\n'>>$OUTPUT

#echo ========================================================>>$OUTPUT
#echo $'\n'>>$OUTPUT

##Network Status and Stats
CMDIFCONFIG=/sbin/ifconfig
echo NETWORK STATS:>>$OUTPUT
$CMDIFCONFIG>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

##Random useful commands
#Disk usage of specfic folders
#Useful for various things.  Temp dir, squid cache, 'bad' user home dirs, check to see if rsync is behaving, etc.
#CMDDU=/usr/bin/du
#echo VITAL DISK USAGE STATS:>>$OUTPUT
#echo USAGE OF CACHE:>>$OUTPUT
#$CMDDU -hs /cache/>>$OUTPUT
#echo USAGE OF NIX2BACKUPS>>$OUTPUT
#$CMDDU -hs /nix2backups/>>$OUTPUT
#echo USAGE OF MOUNTED NIX2>>$OUTPUT
#$CMDDU -hs /mnt/nix2/>>$OUTPUT

#echo ========================================================>>$OUTPUT
#echo $'\n'>>$OUTPUT


#Check to see if there are lots of emails in the queue directory (which could indicate problems).                            Must be sendmail or sendmail compatible.
CMDMAILQ=/usr/bin/mailq
echo MAILQ INFO:>>$OUTPUT
$CMDMAILQ>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

#Update antivirus assuming clamav.
CMDFRESHCLAM=/usr/bin/freshclam
echo UPDATING ANTIVIRUS...>>$OUTPUT
$CMDFRESHCLAM>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

###Manually assure all mounts are fresh.
CMDMOUNT=/bin/mount 
echo ISSUING MOUNT -A...>>$OUTPUT
$CMDMOUNT -a

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT

#List files in specific directories.  Useful to see if automated backups are occuring.  
#CMDLS=/bin/ls
#echo LS OF BACKUPS:>>$OUTPUT
#$CMDLS -lhRa /backups/>>$OUTPUT

#echo ========================================================>>$OUTPUT
#echo $'\n'>>$OUTPUT


#---Check removeable backup device?
#echo MOUNTING REV DISK...>>$OUTPUT
#$CMDMOUNT /dev/hdc /mnt/rev/>>$OUTPUT
#echo LS OF /MNT/REV:>>$OUTPUT
#$CMDLS -lhRa /mnt/rev/>>$OUTPUT
#CMDUMOUNT=/bin/umount
#echo UNMOUNTING REV DISK...>>$OUTPUT
#$CMDUMOUNT /mnt/rev/>>$OUTPUT

#echo ========================================================>>$OUTPUT
#echo $'\n'>>$OUTPUT


##Time to make this file long....

##PS Snapshot -- Make sure no applications have gone ape shit.  
CMDPS=/bin/ps
echo PS AUX SNAPSHOT:>>$OUTPUT
$CMDPS aux>>$OUTPUT

echo ========================================================>>$OUTPUT
echo $'\n'>>$OUTPUT


#Syslog contents
CMDCAT=/bin/cat
SYSLOG=/var/log/syslog
#change above to the location of your syslog.  A lot of distros use /var/log/messages
echo CONTENTS OF SYSLOG:>>$OUTPUT
$CMDCAT $SYSLOG>>$OUTPUT

#--Mail logs?  Or need to remove useless info? Use regular expressions in the EXCLUDES.  
#CMDGREP=/bin/grep
#echo CONTENTS OF SYSLOG:>>$OUTPUT
#EXCLUDE1=".*amavis.*"
#EXCLUDE2=".*postfix.*"
#$CMDGREP -e $EXCLUDE1 -e $EXCLUDE2 -v $SYSLOG>>$OUTPUT

#####Email the $OUTPUT file to the sysadmin.  You will need a properly setup MTA. 
CMDDATE=/bin/date
CMDMAIL=/bin/mail
CMDHOSTNAME=/bin/hostname
SYSADMINEMAIL=root@localhost
##Replace the above with whatever email address you want the reports to be sent to. 
$CMDMAIL -s "`$CMDHOSTNAME` Status for `$CMDDATE`" $SYSADMINEMAIL < ./$OUTPUT  
