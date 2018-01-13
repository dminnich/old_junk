#!/bin/bash

#I have some servers at various places that are running off of "consumer grade" ISP connections. 
#Since cable and DSL companies rarely give consumers static IPs, hosting a domain on one of 
#these such connections becomes a painful task.  

#I used to use no-ip.com, dyndns.com and afraid.org to give these machines dynamic dns subdomains.
#One day I grew tired of them pressuring me for money and I wanted to find a way to do something
#similar with a domain I owned.  A bonus doing things this way is that it looks more professional as well. 
#IE: remoteoffice1.mydomain.com instead of remote1-business.no-ip.com.  

#This script is the client piece of the puzzle.  You need to run this from cron on your 
#remote office machines or at the box at your hose.  For this to work, you will need
#to also configure the server piece on a machine that is always on and has a static IP.

#Most of the work below was shamelessly stolen and updated from places around the net. 
#Credit and links to documentation expalining how to setup the server pice:
#http://linux.yyz.us/nsupdate/
#http://linux.yyz.us/dns/ddns-server.html
#http://linuxpoison.wordpress.com/2007/05/04/dynamic-dns-setup/
#http://www.ops.ietf.org/dns/dynupd/secure-ddns-howto.html
#http://www.freebsdwiki.net/index.php/BIND,_dynamic_DNS

###AGAIN, YOU NEED A PROPERLY CONFIGURED BIND SERVER FOR ANY OF THIS TO WORK. 
###LOOK AT THE LINKS AND SET ONE UP BEFORE PROCEEDING.
#server you will be sending the updates to
SERVER="ns1.mydomain.com"
#BIND zone you will be udating on the server
ZONE="mydomain.com"
#full hostname of this machine
HOSTNAME="remoteoffice1.mydomain.com."
#key you got from the server
KEYFILE="/var/named/*.key"
#how long the record is considered good for in secs
TTL=300
#Where to store logged output
LOG="/tmp/ddns_log"
#where to store what we think the current public IP is.
IP_FILE="/tmp/ddns_ip"
#get the current public IP from whatismyip.com.
NEW_IP=`wget www.whatismyip.com/automation/n09230945.asp -O - -q`


#the nsupdate commands to run if a new IP is found.
function do_nsupdate {

echo "New IP address (${NEW_IP}) found. Updating..." >> $LOG

echo $NEW_IP > $IP_FILE

nsupdate -k $KEYFILE >> $LOG << EOF

server $SERVER

zone $ZONE

update delete $HOSTNAME A

update add $HOSTNAME $TTL A $NEW_IP

send

quit

EOF

}


#if we don't currently have a file that says what our IP is, 
#create one and contact the server with the changes
if [ ! -f $IP_FILE ]; then

echo "Creating $IP_FILE..." >> $LOG

do_nsupdate

else

#if we have a file that says what our IP is, compare it
#to the new resluts. If they are they same, log that and 
#stop working.  If they are different, take the new IP,
#send it to the server, record it in the file and 
#log all of this.
OLD_IP=`cat $IP_FILE`

if [ "$NEW_IP" = "$OLD_IP" ]; then

echo "new and old IPs (${OLD_IP}) are same. Exiting..." >> $LOG

exit 0

else

do_nsupdate

fi

fi

exit 0
