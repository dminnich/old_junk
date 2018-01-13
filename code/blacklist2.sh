#!/bin/bash
##Super simple script that blocks all network access from certian IP addresses.  Place the IPs you wish to block in the badips.txt file.  Seperate each IP by a new line.  And in case you couldn't tell you need iptables installed and working.    
if [ -f "/etc/badips.txt" ]
then
        for BAD_IP in `cat /etc/badips.txt`
        do
                iptables -I INPUT -s $BAD_IP -j DROP
        done
else
        echo "Can't read badips.txt Please make sure that it exsists and that it is writable."
fi
