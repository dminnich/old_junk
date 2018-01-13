#!/bin/bash
#
#
###ABOUT###
#This script is intended to help you shape your outgoing upload bandwidth on
#your linux firewall/gateway device (see my iptablesgw script if you haven't
#set that part up yet). 

#This is necessary because most consumer grade internet connections offered
#through companies like Time Warner and Embarq are grossly asymmetrical in
#nature. 20Mbps down and 1Mbps up is cool but far from perfect due to the way
#that TCP/IP is designed.  Every time you get a packet from somebody you have
#to send out an ACK packet saying "i got it, send me the next one".  P2P
#applications, especially BT, get chunks of data from TONs of people all at the
#same time.  What ends up happening is your router needs to send out so many 
#ACK packets to your P2P friends that it overloads your upload pipe and these
#and other ACK packets start sitting in a queue waiting to get sent out.  If
#your router doesn't have QOS rules in place it treats all these outgoing ACKs
#the same way and sends them in first come first go basis.  Basically, your
#router eventually becomes so busy sending out P2P ACKs that other things like
#web browsing and online games start to suffer and become laggy.  

#The QOS setup below will alleviate these problems by limiting how much upload
#bandwidth P2P applications can use and by saying web browsing and other
#packets are more important than P2P, so always deal with them first.  

#I suggest reading through this whole script and modifying it to fit your
#needs.  Out of the box it is very simple and groups all "normal" things in
#one class and everything else into a junk class that has more limitations.
#Additionally, these classes apply only to outgoing client traffic.  IE: it
#helps machines on your LAN going to web pages, but it does nothing for the
#scenario where your router is a web server that others access from around the
#globe. I have more notes on this deeper in the script, but for the time being
#know that normal client traffic is DNS, DHCP, HTTP, HTTPS, SSH, VNC and RDP.
#Everything else is JUNK and throttled.  You can alter all of this easily
#deeper in the script.  

###REQUIREMENTS##
#A recent distro, CENT 5 or newer with iptables and its classify target and
#mangle tables.  Iproute2's tc and htb and sfc qdiscs.  Most people should have
#all of this by default.  

###LEGAL###
#This script is free in all senses.  Use it however you want.
#
#BTW, I'm human, I make mistakes and I don't know everything. Therefore, if
#this doesn't work for you, or if it breaks something of yours, you can't hold
#me responsible. And honestly, I really don't care to hear about your or my
#problems unless you provide a fix as well.  :)
#
#
#By: Dustin Minnich
#http://www.dminnich.com

#Sources
#http://www.virtualroadside.com/blog/index.php/2007/11/17/make-bittorrentp2p-less-annoying-at-home-using-linux-iptables-and-qos/
#https://www.linux.com/learn/tutorials/330252-weekend-project-configuring-qos-for-linux-routers-gateways
#http://luxik.cdi.cz/~devik/qos/htb/manual/userg.htm
#http://en.gentoo-wiki.com/wiki/QoS
#http://en.gentoo-wiki.com/wiki/QoS-Applied
#http://phix.me/dm/
#http://linux-ip.net/articles/hfsc.en/
#http://codelink.info/qos.php
#http://www.lartc.org/lartc.html
#http://blog.edseek.com/~jasonb/articles/traffic_shaping/
#http://www.shorewall.net/traffic_shaping.htm
#http://linux-ip.net/articles/Traffic-Control-HOWTO/classful-qdiscs.html
#http://www.docum.org/docum.org/docs/htb/
#http://www.docum.org/docum.org/tests/htb/burst/
#http://lartc.org/howto/lartc.qdisc.classless.html#LARTC.SFQ
#http://www.topwebhosts.org/tools/traffic-control.php
#http://opalsoft.net/qos/DS-21.htm
#https://gist.github.com/940616

#Further reading for people who need more features
#IMQ - http://www.linuximq.net/ - Incoming traffic shaping
#HFSC - http://linux-ip.net/articles/hfsc.en/ - A different and supposedly better qdisc
#IPP2P - http://www.ipp2p.org/ - deep packet inspection classification
#L7-filter - http://l7-filter.sourceforge.net/ - deep packet inspection classification 



###CONFIG###
#Outside (WAN) interface.
EXTIF=eth0
#Inside (LAN) interface.
INTIF=eth1
#User defined chain in which to store the mangle rules
CHAIN=SHAPE
#Your total upload bandwidth in kilo bits per sec.  Get it by testing your
#connection on a few sites like speakeasy and others.  Covert it to kilo bits if 
#necessary.  Then take 90% of that number.  Not using 100% is a fail safe and
#using actual rates instead of the advertised rate that you pay for only makes
#sense.  
#5Mbps  5.10Mbs observed.
MAXUP=5120
#The max speed in kilo bits per sec that P2P and any other non-classified
#connections can send data at. Set this throttle lower than MAXUP.  
#1Mbps
JUNKMAXUP=1024
#The guaranteed minimal rate that normal traffic/applications can *always* send
#at.  Note that if they don't need this much bandwidth they will use less.
#Also note that if there is extra unused bandwidth in the JUNK class they will
#use it.  In other words normal apps can transfer below NORMRATE if nothing is
#going on, at NORMRATE if the pipe is saturated and above NORMRATE if NORMRATE
#is maxed and JUNKRATE isn't at max.  If it sends above NORMRATE, it will never
#send faster than MAXUP.  kilo bits per sec.
#NOTE: NORMRATE and JUNKRATE must be equal or less than MAXUP when added together.  
#4Mbps
NORMRATE=4096
#The guaranteed minimal rate that P2P and other non-classified
#applications/connections can *always* send data at.  Note that if they don't
#need this much bandwidth, they will use less.  Also note that if they are busy
#and there is extra unused bandwidth in NORMRATE they will use it up to
#JUNKMAXUP.  In other words, junk apps can transfer below JUNKRATE if nothing
#is going on in their world.  They can transfer at JUNKRATE if the pipe is
#saturated and  can send above JUNKRATE and up to JUNKMAXUP if JUNKRATE is
#maxed out and NORMRATE has some extra bandwidth. They will never send faster
#than JUNKMAXUP or MAXUP. kilo bits per sec.   
#NOTE: NORMRATE and JUNKRATE must be equal MAXUP when added together.  
#.5Mbps
JUNKRATE=512
#A logical class number to be associated with normal application traffic.
NORMCLASS=10
#A logical class number to be associate with junk application traffic.
JUNKCLASS=20
#Executable locations.
#Hopefully these "type" commands will make things automatically work on your
#system. If not, set them manually.
IFCONFIG=`type -p ifconfig`
IPTABLES=`type -p iptables`
TC=`type -p tc`



###SHOW###
if [ "$1" = "show" ]
then
#show discipline info
        echo "[qdisc]"
        $TC -s qdisc show dev $EXTIF
#show class info
        echo "[class]"
        $TC -s class show dev $EXTIF
#show what traffic goes to each class
        echo "[filter]"
        $TC -s filter show dev $EXTIF
#show how and which packets are classified
        echo "[iptables]"
	$IPTABLES -t mangle -vL $CHAIN
        exit
fi






###STOP###
if [ "$1" = "stop" ]
then
	echo "Disabling Outbound Traffic Shaping on $EXTIF"
#destory the traffic shaping discipline on the interface
	$TC qdisc del dev $EXTIF root 
	echo "Flushing iptables mangle chains"
#delete our custom shaping chain from postrouting table
	$IPTABLES -t mangle -D POSTROUTING -o $EXTIF -j $CHAIN 
#flush/erase our custom shaping chain
	$IPTABLES -t mangle -F $CHAIN 
#delete our custom shaping chain
	$IPTABLES -t mangle -X $CHAIN
	echo "Traffic shaping is disabled."
	exit
fi








###START###
if [ "$1" = "start" ]
then


#START FROM SCRATCH!
	echo "Trashing everything and starting fresh!"
	echo "Disabling Outbound Traffic Shaping on $EXTIF"
#destroy the traffic shaping discipline on the interface
	$TC qdisc del dev $EXTIF root
	echo "Flusing iptables mangle chains."
#delete our custom shaping chain from postrouting table
	$IPTABLES -t mangle -D POSTROUTING -o $EXTIF -j $CHAIN
#flush/erase our custom shaping chain
	$IPTABLES -t mangle -F $CHAIN
#delete our custom shaping chain
	$IPTABLES -t mangle -X $CHAIN
	echo "Traffic shaping is disabled."
	


#create our custom shape chain
	echo "Starting iptables work:"
	echo "Creating custom shaping chain."
	$IPTABLES -t mangle -N $CHAIN
	echo "Filling custom shaping chain..."




###ALL ENCOMPASSING RULES###
#DHCLP Client
echo "Adding rule for DHCP."  
$IPTABLES -t mangle -A $CHAIN -p udp --sport 68 --dport 67 -j CLASSIFY --set-class 1:$NORMCLASS
#ICMP traffic.  Pings, traceroutes, etc.
echo "Adding rule for ICMP."  
$IPTABLES -t mangle -A $CHAIN -p icmp -j CLASSIFY --set-class 1:$NORMCLASS
#Control and small packets
echo "Adding small TCP and UDP control packets rules."  
#This should catch the "got it, send me more" ACKs but not the payload ACKs
#where you actually upload data.  It should also catch other TCP things like
#connection closing and what not.  Small packets also fit in here.  Small
#upload bursts aren't a problem, BT and other things want to upload huge
#payload ACKs and that is what saturates pipes.  
#a connection is established and remote server wants to close it. say "yes,
#close the connection" 
$IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK FIN,ACK -j CLASSIFY --set-class 1:$NORMCLASS
#a connection is being built by the remote side contacting us. say "things are
#good lets establish a connection". 
 $IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK SYN,ACK -j CLASSIFY --set-class 1:$NORMCLASS
#remote side detected an error and wants to try again.  #say "yeah, i know
#something went wrong and we are going to try again"
$IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK RST,ACK -j CLASSIFY --set-class 1:$NORMCLASS
#we noticed something went wrong.  tell the remote side to try again. say
#"something went wrong lets try again" 
$IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK RST -j CLASSIFY --set-class 1:$NORMCLASS
#we want to close the connection.  say "start termination handshake" to remote
#side
 $IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK FIN -j CLASSIFY --set-class 1:$NORMCLASS
#say "lets start a new connection" to the remote side
$IPTABLES -t mangle -A $CHAIN -p tcp --syn -j CLASSIFY --set-class 1:$NORMCLASS
#send other small TCP and UDP packets.  This includes most non-payload data.
#Tweak the size if you want.  Packets less than 128 bytes in size move quickly. 
$IPTABLES -t mangle -A $CHAIN -p tcp --tcp-flags FIN,SYN,RST,ACK ACK -m length --length 0:128 -j CLASSIFY --set-class 1:$NORMCLASS
$IPTABLES -t mangle -A $CHAIN -p udp -m length --length 0:128 -j CLASSIFY --set-class 1:$NORMCLASS




###CUSTOM ODD RULES###
echo "Adding custom odd rules."  
#put only small http requests in the fast lane.  fixes megaupload, facebook,
#etc saturation.  
echo "Adding HTTP upload size restriction rule."
$IPTABLES -t mangle -A $CHAIN -p tcp --dport 80 -m length --length 0:700 -j CLASSIFY --set-class 1:$NORMCLASS



###OUTGOING CLIENT PORTS###
#Machines on your LAN connecting to these ports on machines on the internet get
#shoved in the fast lane.  IE: Your laptop SSHing into a machine at work.  
echo "Adding outgoing client rules."
#Add ports for interactive services that you connect to on a regular basis.
#Don't put 80 here and use the custom odd rule at the same time.  
#443 - SSL HTTP, 5900 - VNC, 3389 - Remote Desktop, 22 - SSH, 53 - DNS
#We open tcp and udp both just in case 
client_ports="443 5900 3389 22 53"
for outgoingport in $client_ports ;  do
$IPTABLES -t mangle -A $CHAIN -p tcp --dport $outgoingport -j CLASSIFY --set-class 1:$NORMCLASS
$IPTABLES -t mangle -A $CHAIN -p udp --dport $outgoingport -j CLASSIFY --set-class 1:$NORMCLASS
done
echo "The following outgoing client ports have been shoved in the fast lane: ${client_ports[*]}."




####INCOMING SERVER PORTS###
#If your firewall also acts as a public server on the internet, it will be able
#to send data out of the ports below quickly.  IE: Router is a web server.
#Answer all requests for data on port 80 pronto.  
echo "Adding incoming server rules."
#22 - SSH
#We open tcp and udp both just in case 
server_ports="22"
for incomingport in $server_ports ;  do
$IPTABLES -t mangle -A $CHAIN -p tcp --sport $incomingport -j CLASSIFY --set-class 1:$NORMCLASS
$IPTABLES -t mangle -A $CHAIN -p udp --sport $incomingport -j CLASSIFY --set-class 1:$NORMCLASS
done
echo "The following incoming server ports have been shoved in the fast lane: ${server_ports[*]}."



###Final iptables work
#everything not specified above should be considered junk or p2p and put into
#the restricted junk class
$IPTABLES -t mangle -A $CHAIN -j CLASSIFY --set-class 1:$JUNKCLASS
echo "Done filling the custom shaping chain!"
echo "Making custom shaping chain transversable."
$IPTABLES -t mangle -A POSTROUTING -o $EXTIF -j $CHAIN
echo "iptables work complete!"



##TC work
echo "Starting TC work:"
echo "Adding queue discipline to interface."
#Attach the HTB qdisc to the external interface.  Give it the name 1:0.
#Unclassified packets will use the fast track.  This is counter-intuitive.
#Truth be told all IP traffic will go through iptables and if it doesn't match
#any specified exceptions, it will be placed in the JUNKCLASS.  We specify
#NORMCLASS as the default here due to concerns raised here http://phix.me/dm/.
#The site states that ARP requests (layer 2) aren't seen by iptables but are
#seen by TC.  You don't won't those going to the slow lane so we set the TC
#default to NORMCLASS.
$TC qdisc add dev $EXTIF root handle 1:0 htb default $NORMCLASS
echo "Creating root class."
#This class is a parent class whose bandwidth will be subdivided into our other
#two classes.  It's parent is the qdisc we just created and its name is 1:1.
#It's max upload speed is speed of your connection.  
$TC class add dev $EXTIF parent 1:0 classid 1:1 htb rate ${MAXUP}kbit 
#Here is an example of how to add burst to the root class.  I add the
#difference between my observed bandwidth test rate and MAXUP.  It must be
#converted to kiloBytes.  I'm not sure if this is right, see my burst notes for
#more info. 
#$TC class add dev $EXTIF parent 1:0 classid 1:1 htb rate ${MAXUP}kbit burst 12kb
echo "Creating sub-classes."
#These are the subclasses.  Rate sets the guaranteed rate at which the class
#can send data at even if the pipe is saturated.  Ceil sets the max rate it can
#ever send at.  If the pipe isn't saturated and the other class isn't busy, it
#can borrow from the other class until it gets up to ceil bps of bandwidth.
#Prio sets the borrowing priority. Lower number has more strength.  This isn't
#really useful with two classes, but basically what happens is as classes reach
#their rates they can borrow up to their ceil from other classes--if multiple
#classes are at this point, and the pipe isn't saturated, the classes with the
#lowest priority number get to borrow bandwidth first.  
$TC class add dev $EXTIF parent 1:1 classid 1:${NORMCLASS} htb rate ${NORMRATE}kbit ceil ${MAXUP}kbit prio 1
#Since this classes ceil is MAXUP, it makes sense that its burst should be the
#same as the root class.  I'm not sure if this is right. Read my burst notes
#below.  
#$TC class add dev $EXTIF parent 1:1 classid 1:${NORMCLASS} htb rate ${NORMRATE}kbit ceil ${MAXUP}kbit prio 1 burst 12kb
$TC class add dev $EXTIF parent 1:1 classid 1:${JUNKCLASS} htb rate ${JUNKRATE}kbit ceil ${JUNKMAXUP}kbit prio 2


#UNUSED OPTIONS
#quantum and r2q settings may be needed if you have multiple classes with the
#same rate and ceil.  We won't, so we won't be using those options.  

#the burst and cburst options are confusing to me.  I think they indicate how
#much data a class can send at or above rate or ceil out of the gate for short
#periods of time before they get re-evaluated and limited to rate or ceil.

#If you are a tweaker and you want to adjust the burst settings, here is how I
#think you would do it.  Remember how I told you to set MAXUP equal to 90
#percent of your upload bandwidth?  Well, subtract your measured bandwidth from
#MAXUP and add burst and cburst options to the parent class using a range of 
#this number converted to kilobytes.  
#Next, make the sum of your NORMRATE and JUNKRATE smaller than MAXUP by the
#amount you want to burst by across all the subclasses.  This prevents normal
#non-burst bandwidth starvation. 
#Next, make the ceil of the classes that are going to burst smaller than 
#MAXUP by the amount you want to cburst.  
#I would probably only apply bursts to the NORMCLASS.  

#IE: 
#Measured upload bandwidth: 500 kilo bits per sec
#MAXUP: 450 kilo bits per sec -- 90%
#NORMRATE: 200 kilo bits per sec
#JUNKRATE: 150 kilo bits per sec
#Note the 100 extra  
#Norm ceil: 350 kilo bits per sec -- notice 100 extra
#Junk ceil: 250 kilo bits per sec -- not bursting
#Parent burst, cburst: 4,2kiloBytes  
#500 - 450 = 50 converted to kilobytes = 6 
#surge to 500 kilo bits if necessary.
#Normal class burst,cburst: 9,3kiloBytes 
#100kbits converted to kiloBytes = 12
#Surge can reach but not surpass MAXUP. 
#That is just a guess though.  I really don't know what I'm doing.


echo "Assigning SFQ discipline to the subclasses."
#by default when packets leave our classes and go to the wire they use a simple
#fifo queue to figure out how to get there. SFQ does a more equal and fair job
#dividing up these packets and it does it in a more resource friendly manner
#by using hashes.  Because of this, we assign SFQ qdiscs to our HTB qdisc.
#Perturb 10 is the suggested value.  It means generate a new hash every 10
#seconds. 
$TC qdisc add dev $EXTIF parent 1:${NORMCLASS} handle ${NORMCLASS}: sfq perturb 10
$TC qdisc add dev $EXTIF parent 1:${JUNKCLASS} handle ${JUNKCLASS}: sfq perturb 10


echo "tc work complete!"
echo "Outbound Traffic Shaping is now enabled on $EXTIF"

	exit
fi



###USAGE###
echo "Usage: $0 (start|stop|show)"
exit
