#!/bin/sh
#
#
###ABOUT###
#This script will allow you to turn a computer into a gateway/firewall. In
#other words, you can replace that ugly Linkysys/Netgear box on the desk at
#your house with an old or cheap computer you got laying around.  This will
#give you greater flexibility and more stability, especially when you start
#transferring lots of traffic (I'm looking at you torrent users).  
#
###LEGAL###
#This script is free in all senses.  Use it however you want: to protect your
#home network, in a project you are working on, claim it as your own work,
#modify it, sell it, do whatever-- I don't care.  
#
#BTW, I'm human, I make mistakes and I don't know everything. Therefore, if
#this doesn't work for you, or if it breaks something of yours, you can't 
#hold me responsible. And honestly, I really don't care to hear about your
#problems unless you provide a fix as well.  :)
#
#
#By: Dustin Minnich
#http://www.dminnich.com
#
#
###ASSUMPTIONS###
#You have a machine with 2 network cards you will use as the router and a
#switch that the other machines will plug into.  The machine is running CentOS
#and is already up to date and has iptables installed. You use the bash
#shell and have basic OS tools installed: ifconfig, modprobe, depmod, grep, sed,
#awk, dhclient, etc.  
#NOTE: Other RPM based distros *should* work, Debian distros should work with
#some modifications, but none of this has been tested.  
#
#You have a good understanding of networking and Linux and their terminology. 
#
#You know exactly the kind of setup you want for your home network.
#
#You know iptables basics or you aren't afraid to dig in the man pages a bit. 
#
#It is expected that you will use this script for the "normal" home network
#setup.  This means you have 1 public IP address given to you by your ISP, and
#that you get this IP through a DHCP pull. This 1 public IP address will be
#placed on this router and the other network card will have a private
#192.168.1.x address.  A cable from the NIC with the 192.168.1.x address will
#go to a switch where other machines jack in and also have statically assigned
#192.168.1.x addresses with their default gateway being the 192.168.1.x
#address of the routers interface.  The machines on your LAN will have their
#DNS servers set to the DNS servers your ISP provides. The router itself will
#host some public and private services and some machines on the LAN will host
#some public services as well (port forwarding). Additionally, only incoming
#traffic will be filtered.  In other words, all outgoing traffic from your
#router and machines on your LAN will be trusted and will not be inspected
#at all. 
#NOTE: It is a *very* good idea to setup your router to act as a DNS caching
#server and a DHCP server, but I will NOT be covering those steps. 
#NOTE: Documentation on how to use a static IP from your ISP instead of
# a DCHP pull is provided in the tips section.  
#
###DOWNFALLS###
#This script is for a CLI geek.  There is no pretty web gui. Look at ipcop if
#you want something like that.  
#
#This is just a firewall script.  Most physical firewall boxes and firewall
#distros also include DHCP servers and DNS caching servers.  These are very
#nice features and you should probably look into deploying BIND and DHCPD on
#the firewall box to accomplish these things.  
#
#Open port rules are not in high usage order. You can fix this if you are very
#careful how you create the rules below.  But honestly, if you are using decent
#hardware and have less than 100 rules I don't think those couple milliseconds
#of extra traversal time will even be noticed.  
#
#TCP and UDP ports are opened for each port you list.  It could be argued that
#this is less secure than only opening the port for the needed protocol. 
#
#Issuing a stop doesn't put the machine back in its true original state. Proc
#settings are still applied, modules are still loaded, and servers are still
#running.  This is to allow for easier testing and because I'm lazy.  
#
#This script does not have any advanced error checking.  If something isn't
#working for you, you may need to do a line by line check to see where things
#went wrong.  
#
#This script is limited in scope and should help the standard geek home user,
#but it isn't really flexible enough to address various business needs
#like VPNs, QOS, IPV6, and DMZ setups.  
#
#
###INSTALLATION AND USAGE###
#INSTALL
#Remove the chance of using the wrong iptables script.  
#/etc/init.d/iptables stop
#chkconfig iptables off
#chmod 444 /etc/init.d/iptables 
#mv /etc/init.d/iptables /etc/init.d/iptables.bak
#/etc/init.d/ip6tables stop
#chkconfig ip6tables off
#chmod 444 /etc/init.d/ip6tables
#mv /etc/init.d/ip6tables /etc/init.d/ip6tables.bak
#
#Put this script in place.
#cp iptablesgw /etc/iptablesgw
#chmod 755 /etc/iptablesgw
#
#Setup logging.  If your syslog configuration already places
# kernel debugging messages somewhere, you can find the logging
# in that file and won't need to change anything. Otherwise, 
#Add the following line to /etc/syslog.conf:
#kern.debug   /var/log/kerndebug 
#touch /var/log/kerndebug
#chmod 744 /var/log/kerndebug
#/etc/init.d/syslog restart
#
#Make sure your network interfaces aren't configured by the OS
# at boot.  This script will do that work.  
#Put ONBOOT=NO lines in your 
#/etc/sysconfig/network-scripts/ifcfg-ethX files.  
#
#Disable any network services that the router will be starting at boot.  
# You will specify them at the end of this script and they will be 
# brought up once the network is in a good state.  
#chkconfig ntpd off
#chkconfig dhcpd off
#chkconfig named off
#You will need to do this and add the name of the service to the 
# services array every time you install a new network enabled service.  
#
#Read through the ENTIRE file and make your changes.  
#vim /etc/iptablesgw 
#
#Make this script run when the system boots. 
#Add the following line to the /etc/rc.local file:
#/etc/iptablesgw start
#
#Reboot and give it a shot.  
#
#USAGE
#/etc/iptablesgw
#start - Sets up your interfaces, loads your configuration, starts iptables,
#starts your servers and runs any other commands you want it to. 
#stop - Flushes all firewall rules and leaves iptables running in an open state.
#restart - Does a stop and then a start.  It does do the interface work again. 
#This may be useful if your network settings get messed up or if you need a
#new dhcp pull from your ISP.
#reload - Flushes all rules and then re-adds all the rules in the file. Run
#this if you already have a functioning firewall and you just want a change
#you made to take effect.  
#status - View a listing of all your rules, in a somewhat readable format.  
#
#
###REFERENCES###
#http://iptables-tutorial.frozentux.net/iptables-tutorial.html
#http://www.linuxhomenetworking.com/wiki/index.php
#http://wiki.openvz.org/Setting_up_an_iptables_firewall
#http://amitsharma.linuxbloggers.com/portforwarding.htm 
#http://kreiger.linuxgods.com/kiki/?Port+forwarding+with+netfilter
#http://nesbitt.yi.org:6690/files/script_bits.shtml
#http://www.securityfocus.com/infocus/1711
#http://www.gotroot.com/tiki-index.php?page=Linux+Firewall+kernel+settings
#http://www.mjmwired.net/kernel/Documentation/filesystems/proc.txt
#http://hacks.oreilly.com/pub/h/45
#http://www.docunext.com/blog/tools/iptables-rule-generator/
#http://easyfwgen.morizot.net/gen/
#Test your setup...
#http://www.pcflank.com/scanner1.htm
#http://sigma.hackerwhacker.com
#https://www.grc.com
#http://nmap.org/
#
#
#
###VARIABLES TO DEFINE###
#YOU MUST DEFINE THESE.  
#Use "which" to find out where the binaries are on your router.  Use ifconfig
#and dhclient to figure out the interface info.  You should know the rest of
#the stuff.  
#Outside (WAN) interface.
EXTIF=eth0
#Inside (LAN) interface.
INTIF=eth1
#Loopback interface.
LOOPIF=lo
#Internal network IP range.
LAN_IP_RANGE=192.168.1.0/24
#Your ISPs DHCP server. Get it from dhclient.
DHCP_SERVER=10.111.15.23
#Loopback IP.
LOOPIP=127.0.0.1
#Internal IP.
INTIP=192.168.1.1
#Your external public IP address is grabbed from ifconfig later in this script.
#Internal netmask.
INTMASK=255.255.255.0
#Executable locations.
#Hopefully these "type" commands will make things automatically work on your
#system. If not, comment them out, change the variables below them to match
#the location of the executables on your system and uncomment them.  
DHCLIENT=`type -p dhclient`
IFCONFIG=`type -p ifconfig`
IPTABLES=`type -p iptables` 
MODPROBE=`type -p modprobe`
DEPMOD=`type -p depmod`
AWK=`type -p awk`
SED=`type -p sed`
GREP=`type -p grep`
#DHCLIENT=/sbin/dhclient
#IFCONFIG=/sbin/ifconfig
#IPTABLES=/usr/sbin/iptables 
#MODPROBE=/sbin/modprobe
#DEPMOD=/sbin/depmod
#AWK=/bin/awk
#SED=/bin/sed
#GREP=/bin/grep
#The list files below allow or deny traffic based on IPs and IP ranges you
# specify in normal text files.  These custom rules are inserted in the 
# INPUT, FORWARD, and OUTPUT chains of the FILTER table. They affect 
# basically everything.  The whitelist rule set is always at the top 
# of the chains, so traffic from IPs in this file is allowed even 
# if later rules, (including the blacklist which is the 2nd rule in the chain) 
# would otherwise deny it.  IPs and ranges are specified one to a line in
# standard IP/MASK format.  The list files must be chmoded 744 or greater and
# have unix line breaks to work. Also, this script only reads these files when
# it is started; so if you add new lines to one of the files be sure to
# run a iptablesgw reload. If you don't want to use this feature, either
# create blank files or point the below variables to files that don't exist.
# NOTE: These are the only variables in this script that effect OUTGOING
# traffic. Do NOT whitelist private IP addresses, it is not 
# necessary and may open some holes for spoofers.  In fact, be *very* careful
# with the whitelist, allowing traffic from any IP to pass through the firewall
# in any direction at any time and access anything is extremely dangerous.  
# I repeat, DO NOT USE THE WHITELIST UNLESS YOU KNOW WHAT YOU ARE DOING.  
WHITELIST=/etc/whitelist.txt
BLACKLIST=/etc/blacklist.txt
#
#
#
#
#
#
###BEGIN CODE###
#You need to read through everything below and change things as needed.  
#
#
###START###
#This huge piece of code is ran when the machine boots and also when you issue
#an iptabesgw start.  It sets up all the rules you define and puts
#your gateway into a useful state.  
init () {
#
###PROC SETUP###
#0-off 1-on
echo -en "\033[0;31m"
echo "Applying PROC settings..."
tput sgr0
#Enable forwarding between interfaces
#Required to make this machine a gateway.
echo "1" > /proc/sys/net/ipv4/ip_forward
echo -en "\033[0;31m"
echo "Interface forwarding enabled."
tput sgr0
#
#Extra proc config.
#Hardening...
#Don't respond to broadcasted pings. 
#Should be safe for most setups.  
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
#Don't allow hosts to specify their own routing paths to things.
#Should be safe for most setups.  
echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route
#Prevent internal address spoofing by only allowing responses to go out same
#interface they came in on.  
#May cause issues if your network changes frequently or if you have multipath
#or fail-over links defined. Should be helpful and not hurtful for most home
#setups.  
echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter
#Prevent man in the middle attacks by not listening to ICMP re-directs.  
#If the route to something has changed and a router on the way to that 
#device tells your host to use a new router to get to the device instead
#your machine will not listen to it.  I don't think ICMP redirects are used
#all that often so this should be fairly safe.  
#May need to be set to 1 if your router uses any virtualization software. 
echo "0" > /proc/sys/net/ipv4/conf/all/accept_redirects
#Prevent man in the middle attacks by not listening to ICMP re-directs.  
#See above, but only applies to your default gateway.  
#May need to be set to 1 if your router uses any virtualization software. 
echo "0" > /proc/sys/net/ipv4/conf/all/secure_redirects
#Don't let your router send out better route information to clients.  
#Basically, the opposite of above.  This needs to be turned ON if your network
#has multiple routers and multiple paths to devices.  
#This also needs to be ON if your router uses any virtualization software.  
echo "0" > /proc/sys/net/ipv4/conf/all/send_redirects
#Prevent DOS SYN flood attacks.
echo "1" > /proc/sys/net/ipv4/tcp_syncookies
#
#
#Logging settings...
#Don't log packets that are invalid responses to broadcast frames. 
echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
#Log packets with source addresses that the router has no known path back to.
echo "1" > /proc/sys/net/ipv4/conf/all/log_martians
#
#Your preference...
#Don't respond to any pings. 
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all
#Proxy arp
#Router can try to answer requests on other subnets its connected to without static routes.
#This should be set to 0 if your router uses any virtualization software.  
echo "0" > /proc/sys/net/ipv4/conf/all/proxy_arp
#Allow dynamic address changing on outgoing packets (useful for dhcp)
echo "1" > /proc/sys/net/ipv4/ip_dynaddr
#
#
echo -en "\033[0;31m"
echo "Other PROC settings applied."
tput sgr0
#
echo -en "\033[0;31m"
echo "Done!"
tput sgr0
###MODULE SETUP###
echo -en "\033[0;31m"
echo "Loading modules (errors could mean you have kernel built ins--things could still work)..."
tput sgr0
$DEPMOD -a
$MODPROBE ip_conntrack
$MODPROBE ip_tables
$MODPROBE iptable_filter
$MODPROBE iptable_mangle
$MODPROBE iptable_nat
$MODPROBE ipt_LOG
$MODPROBE ipt_limit
$MODPROBE ipt_MASQUERADE
$MODPROBE ipt_state
$MODPROBE ipt_owner
$MODPROBE ipt_REJECT
$MODPROBE ipt_mark
$MODPROBE ipt_multiport
$MODPROBE ip_conntrack
$MODPROBE ip_conntrack_ftp
$MODPROBE ip_conntrack_irc
$MODPROBE ip_nat_ftp
$MODPROBE ip_nat_irc
$MODPROBE nfnetlink
$MODPROBE nfnetlink_queue
$MODPROBE nfnetlink_log
$MODPROBE xt_NFQUEUE
$MODPROBE ip_queue
#FATAL errors may just mean you have the features compiled into the kernel, in which case, they will still work.
echo -en "\033[0;31m"
echo "Done!"
tput sgr0
#
##
###INTERFACE SETUP###
echo -en "\033[0;31m"
echo "Configuring interfaces..."
tput sgr0
#Get outside ip
echo -en "\033[0;31m"
echo "Getting external IP address from DHCP."
tput sgr0
$DHCLIENT $EXTIF
$IFCONFIG $EXTIF up
# NOTE: If your ISP provides you with a static IP, the tips section has the
# steps necessary to make this script use that information instead of doing a
# DHCP pull.  
echo -en "\033[0;31m"
echo "Sleeping briefly."
tput sgr0
sleep 15s
#Grab the external IP from ifconfig and store it in the variable EXTIP.  This
#is necessary for the DNAT rules later.  If your IP changes you will need to
#re-run this script to allow access to the DNATed services again. If your IP
#changes often you will need to write a funky cron job to handle these tasks.
#If anybody knows a better way to do this (even if its a dyndns solution) let
#me know.  
#
EXTIP="`$IFCONFIG -a|$GREP -A 2 $EXTIF|$AWK '/inet/ { print $2 }'|$SED -e s/addr://`"
#
echo -en "\033[0;31m"
echo "Your external IP is $EXTIP!"
tput sgr0
#
##Setup the IP on internal interface
echo -en "\033[0;31m"
echo "Setting up the internal interface."
tput sgr0
$IFCONFIG $INTIF $INTIP netmask $INTMASK up
echo -en "\033[0;31m"
echo "Sleeping briefly."
tput sgr0
sleep 5s
echo -en "\033[0;31m"
echo "Your internal network setup looks like this!"
tput sgr0
$IFCONFIG $INTIF
#
echo -en "\033[0;31m"
echo "Done!"
tput sgr0
}
setup () {
#
###RULES###
#
#EXTIP must be defined in the setup section as well so that reload will work.
EXTIP="`$IFCONFIG -a|$GREP -A 2 $EXTIF|$AWK '/inet/ { print $2 }'|$SED -e s/addr://`"
echo -en "\033[0;31m"
echo "Adding rules..."
tput sgr0
#
#
###BASIC SETUP PART 1###
#Change default action to drop
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP
echo -en "\033[0;31m"
echo "Default policy action is now DROP."
tput sgr0

#Drop malformed TCP packets from the outside.  By default, we let the 
# router and the LAN misbehave if they want.  If you want to try to 
# tighten things up even more, uncomment the OUTPUT lines below and 
# remove the -i $EXTIF definitions from the INPUT and FORWARD lines.  
#New not syn.  
$IPTABLES -A INPUT -i $EXTIF -p tcp ! --syn -m state --state NEW -j DROP 
$IPTABLES -A FORWARD -i $EXTIF -p tcp ! --syn -m state --state NEW -j DROP 
#$IPTABLES -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP 
#Fragmented packets.  
$IPTABLES -A INPUT -i $EXTIF -f -j DROP
$IPTABLES -A FORWARD -i $EXTIF -f -j DROP
#Bad states.  
$IPTABLES -A INPUT -i $EXTIF -p tcp -m state --state INVALID -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m state --state INVALID -j DROP
#$IPTABLES -A OUTPUT -p tcp -m state --state INVALID -j DROP
#Shamelessly stolen from various websites.  
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags ALL NONE -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags ALL NONE -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags ALL ALL -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags ALL ALL -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
#
$IPTABLES -A INPUT -i $EXTIF -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp -m tcp --tcp-flags PSH,ACK PSH -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m tcp --tcp-flags PSH,ACK PSH -j DROP
$IPTABLES -A INPUT -i $EXTIF -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
$IPTABLES -A FORWARD -i $EXTIF -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
#ICMP fragments. 
$IPTABLES -A INPUT -i $EXTIF --fragment -p ICMP -j DROP
$IPTABLES -A FORWARD -i $EXTIF --fragment -p ICMP -j DROP
#
#Allow DHCP traffic from your ISP
$IPTABLES -A INPUT -p UDP -s $DHCP_SERVER --sport 67 --dport 68 -j ACCEPT
#
#Block traffic with bad source addresses (help stop spoofers) 
$IPTABLES -A INPUT -i $EXTIF -s 10.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 172.16.0.0/12 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 192.168.0.0/16 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 224.0.0.0/4 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 240.0.0.0/5 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 127.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i $EXTIF -s 0.0.0.0/8 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 10.0.0.0/8 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 172.16.0.0/12 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 192.168.0.0/16 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 224.0.0.0/4 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 240.0.0.0/5 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 127.0.0.0/8 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 0.0.0.0/8 -j DROP
#$IPTABLES -A OUTPUT -o $EXTIF -d 224.0.0.0/4 -j DROP
#$IPTABLES -A FORWARD -o $EXTIF -d 224.0.0.0/4 -j DROP
#Drop broadcast traffic
$IPTABLES -A INPUT -i $EXTIF -d 255.255.255.255 -j DROP
$IPTABLES -A INPUT -i $EXTIF -d 0.0.0.255/0.0.0.255 -j DROP
$IPTABLES -A INPUT -i $EXTIF -d 224.0.0.1 -j DROP
$IPTABLES -A INPUT -i $EXTIF -m pkttype --pkt-type broadcast -j DROP
$IPTABLES -A FORWARD -i $EXTIF -d 255.255.255.255 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -d 0.0.0.255/0.0.0.255 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -d 224.0.0.1 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -m pkttype --pkt-type broadcast -j DROP
#Block samba broadcast traffic from the outside world
$IPTABLES -A INPUT -p UDP -i $EXTIF --destination-port 135:139 -j DROP
$IPTABLES -A INPUT -i $EXTIF -d 224.0.0.0/8 -j DROP
$IPTABLES -A FORWARD -p UDP -i $EXTIF --destination-port 135:139 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -d 224.0.0.0/8 -j DROP
#DHCP ?
$IPTABLES -A INPUT -i $EXTIF -s 169.254.0.0/16 -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s 169.254.0.0/16 -j DROP
#Drop packets that look like they came from our self.  
$IPTABLES -A INPUT -i $EXTIF -s $EXTIP -j DROP
$IPTABLES -A FORWARD -i $EXTIF -s $EXTIP -j DROP
#
#Setup the blacklist and whitelist
#These lists allow or deny traffic based on IPs and are very dangerous.
# They allow/deny traffic in all directions, on all interfaces, all the 
# time and take preference over most of the other rules in this file.  
# DO NOT use this feature unless you have a firm understanding of 
# iptables and know exactly what you are doing. 
# By default, an entry in one of the lists accepts/denies traffic in all 
# directions.  IE: if you blacklist the RIAA, they can't connect to any of your
# services, but people on your LAN also can't go to the RIAA's website.  
# This is done so you can have a cheap form of content filtering and LAN 
# control as well.   
# If you have no need to blacklist people on the LAN from accessing anything on
# the internet (ie: content filtering) and don't need to prohibit certain PCs
# access to the internet or to services on the router itself, use the commented
# out values that include -i $EXTIF instead. The commented rules will only
# apply the lists to traffic coming in from the outside world that is trying to
# reach a service offered by the router or a machine on the LAN.  This isn't as
# secure as the default setting though.  Think of this, you are allowed to hit a 
# rogue RIAA tracker because there is no output filtering.  They will then know
# that you were at least trying to do something bad, even though you should not 
# have gotten any packets back from that blacklisted IP. I don't know if any legal
# charges can be filed without an actual transfer, but I doubt it.  Also, be
# careful, some of this traffic may be considered related and allowed to pass
# if you don't write and check your rules properly.  
$IPTABLES -N black
$IPTABLES -N white
#Use the lists in the default bidirectional manner.  
$IPTABLES -A INPUT -p ALL -j white
$IPTABLES -A FORWARD -p ALL -j white
$IPTABLES -A OUTPUT -p ALL -j white
$IPTABLES -A INPUT -p ALL -j black
$IPTABLES -A FORWARD -p ALL -j black
$IPTABLES -A OUTPUT -p ALL -j black
#Use the lists to affect incoming traffic only.  
#$IPTABLES -A INPUT -i $EXTIF -p ALL -j white
#$IPTABLES -A FORWARD -i $EXTIF -p ALL -j white
#$IPTABLES -A INPUT -i $EXTIF -p ALL -j black
#$IPTABLES -A FORWARD -i $EXTIF -p ALL -j black
#
#
#Allow people on the LAN to access anything and everything offered by the router. 
# Kills the usefulness of the private service section below.  
#$IPTABLES -A INPUT -p ALL -i $INTIF -s $LAN_IP_RANGE -j ACCEPT
#Allow people on the LAN to reach the internet
$IPTABLES -A FORWARD -i $INTIF -s $LAN_IP_RANGE -j ACCEPT
#Allow the router to talk to the LAN and the outside world.  
$IPTABLES -A OUTPUT -p ALL -d $LAN_IP_RANGE -o $INTIF -j ACCEPT
$IPTABLES -A OUTPUT -p ALL -o $EXTIF -j ACCEPT
#Allow all loopback communication.
$IPTABLES -A INPUT -i $LOOPIF -j ACCEPT
$IPTABLES -A OUTPUT -o $LOOPIF -j ACCEPT
#
#ICMP rules -- Open ICMP ports on router. 
#Comment the rules below to disallow pings and TTLs from internet.
#Visit the link below to find out what else you might want to allow.
#http://iptables-tutorial.frozentux.net/iptables-tutorial.html#ICMPTYPES
$IPTABLES -A INPUT -p ICMP -s 0/0 --icmp-type 8 -j ACCEPT
$IPTABLES -A INPUT -p ICMP -s 0/0 --icmp-type 11 -j ACCEPT

echo -en "\033[0;31m"
echo "General nonsense is now blocked."
tput sgr0

###WHITELIST###
if [ -r $WHITELIST ];
then 
for x in `cat $WHITELIST`; do
echo "Whitelisting $x"
#Allow whitelisted traffic
$IPTABLES -A white -s $x -j ACCEPT
done
echo -en "\033[0;31m"
echo "The IPs in your whitelist file have been processed."
tput sgr0

else

echo -en "\033[0;31m"
echo "Whitelist file not found. Skipping custom table creation."
tput sgr0

fi
###BLACKLIST###
if [ -r $BLACKLIST ];
then
for x in `cat $BLACKLIST`; do
echo "Blacklisting $x"
#Log blacklisted traffic
$IPTABLES -A black -s $x -j LOG --log-prefix "Blocked $x:" 
#Drop blacklisted traffic
$IPTABLES -A black -s $x -j DROP
done
echo -en "\033[0;31m"
echo "The IPs in your blacklist file have been processed."
tput sgr0

else

echo -en "\033[0;31m"
echo "Blacklist file not found. Skipping custom table creation."
tput sgr0

fi

###PUBLIC SERVICES - RAN ON THE ROUTER ACCESSIBLE BY ANYONE###
#If your router is also going to be a general purpose server,
# you will need to specify the ports that correlate to the 
# daemons that the router will be running and you want the
# world (people on the internet and people on your LAN) to
# have access to.  Ports are separated by spaces.  
# NOTE: A port can only be opened/listed in one section
# of this file.  IE: You can not open port 22 in the 
# public service section to get a shell on the router
# and also forward port 22 to a machine in your LAN in the
# port forwarding section below.  
#
#NOTE: You can specify a port range by doing
# beginning_port:ending_port.  
#NOTE: Running a SSH server? Don't just open port 22 here!  
# Look in the tips section for some more advanced and secure rules
# you can add to your custom rule section.   

#router_public_ports="80 443"
router_public_ports=""
for publicport in $router_public_ports ;  do
$IPTABLES -A INPUT -i $INTIF -s $LAN_IP_RANGE -p tcp  --dport $publicport -j ACCEPT
$IPTABLES -A INPUT -i $INTIF -s $LAN_IP_RANGE -p udp  --dport $publicport -j ACCEPT
$IPTABLES -A INPUT -p tcp --dport $publicport -m state --state NEW -j ACCEPT
$IPTABLES -A INPUT -p udp --dport $publicport -j ACCEPT
done

echo -en "\033[0;31m"
echo "The following ports have been opened for public access on the router: ${router_public_ports[*]}."
tput sgr0

###PRIVATE SERVICES - RUN ON THE ROUTER ACCESSIBLE BY THE LAN###
#If your router is also going to be a general purpose server,
# you will need to specify the ports that correlate to the 
# daemons that the router will be running and you want only the people on your
# LAN to have access to (samba is a good example).  Ports are separated by
# spaces.  
#NOTE: A port can only be opened/listed in one section
# of this file.  IE: You can not open port 22 in the 
# private service and the port forwarding section.   
#NOTE: You can specify a port range by doing
# beginning_port:ending_port.  
#NOTE: Running a DHCP server?  Opening port 67 here should work, but if want
# a more secure solution check out the tips section for a rule you can add
# to the custom section.  
#
#router_lan_ports="123 137:139 445"
router_lan_ports=""
for lanport in $router_lan_ports ;  do
$IPTABLES -A INPUT -i $INTIF -s $LAN_IP_RANGE -p tcp --dport $lanport -j ACCEPT
$IPTABLES -A INPUT -i $INTIF -s $LAN_IP_RANGE -p udp --dport $lanport -j ACCEPT
done 

echo -en "\033[0;31m"
echo "The following ports have been opened for LAN only access on the router: ${router_lan_ports[*]}."
tput sgr0
#
###PORT FORWARDING - PUBLIC SERVICES OFFERED BY MACHINES ON THE LAN###
#Usage: 
#1) Add the hostname of the new "server" to the SERVERS variable.  
# Everything is separated by spaces.  
#2) Copy a HOSTNAME_IP and HOSTNAME_PORTS stanza and modify them to meet
# the new servers needs.  The HOSTNAME part has to match what you
# added to the SERVERS variable exactly.  
#3) IPs must be the private 192.168.1.x address and ports can only
# be opened once.  Meaning, you can't have two machines running web
# servers and port 80 forwarding to both of them. Additionally, 
# you can not open a port in more than one section of this script. 
# If your router is offering a service on port 80 in the "public 
# services" part of this script, port 80 can not be forwarded to
# a machine in your LAN in this section, and vice versa.  
#
#Port forwarding with iptables is rather complicated.  Here is a run down of
#the rules, assuming a web server, in case you are interested.  
#PREROUTING DNAT - Router listens on EXTIP and when it gets hit on port 80
# it rewrites the destination address to be the internal IP of the server
# running the web server software.  
#     From 152.5.17.3:any --> To: 68.10.15.5:80
#     Becomes  From 152.5.17.3:any --> To: 192.168.1.12:80
#FORWARD ACCEPT - Now that the router has a packet that isn't destined for 
# itself it must forward it to its final destination.  Adding rules here
# allows this. They are further tightened by only allowing new connections
# on the needed ports. 
#	Packets are passed and no re-writing takes place here.  
#POSTROUTING SNAT - This allows machines on your LAN to access services
# offered by other machines on your LAN.  It rewrites the source address
# of the original packet to be the INTIP.  If this wasn't in place, when 
# the server responded it would send traffic directly to the LAN host
# that requested the info and then that host would drop it because it
# got a reply from someone else (an internal IP instead of the public
# IP it sent the request to).  
# 	 From 192.168.1.13 (LAN client) --> to 68.10.15.5:80 (EXTIP)
#	 becomes From 192.168.1.13 --> to 192.168.1.12:80
#	 SNAT rules turn this into From 192.168.1.1 --> to 192.168.1.12:80
#	 Packet reaches http server and the server sends its response back
#	 to the router that then sends it to the requesting host after 
#	 MASQing it.  
#
#	 If SNAT rules were not in place, the packet would look like this
#	 From 192.168.1.13 --> to 192.168.1.12:80 when it got to the web 
#	 server.  Then, the web server would notice the source is on the LAN
#	 and do the "smart" thing and send the reply to 192.168.1.13. The
#	 client would then drop this packet because it would not be expecting
#	 a reply from 192.168.1.12, it instead wants a reply from 68.10.15.5.  
#
#	 This isn't a problem with traffic from the outside because when the 
#	 when the web server gets the packet it doesn't think it knows a better
#	 way to get to X public IP address so it passes it to its default gateway
#	 and then the router does its magic.  
#
#OUTPUT DNAT - This allows the router itself to access services offered
# by other machines (and itself) on the LAN. This is just like the PREROUTING
# DNAT rule but it is for the firewall itself. This is necessary because
# traffic generated at the router doesn't go through the PREROUTING NAT table.  
#
#NOTE: You can specify a port range by doing
# beginning_port:ending_port.  
#NOTE: Running a SSH server? Don't just open port 22 here!  
# Look in the tips section for some more advanced and secure rules
# you can add to your custom rule section.   


#SERVERS="MAIL"
#MAIL_IP="192.168.1.5"
#MAIL_PORTS="25 110 993"
SERVERS=""
for box in $SERVERS; do
	eval boxip=\$"${box}"_IP
	eval boxports=\$"${box}"_PORTS
	for allowedport in $boxports; do
	$IPTABLES -t nat -A PREROUTING -p tcp --dport $allowedport -d $EXTIP -j DNAT --to-destination $boxip
	$IPTABLES -t nat -A PREROUTING -p udp --dport $allowedport -d $EXTIP -j DNAT --to-destination $boxip
	$IPTABLES -A FORWARD -i $INTIF -s $LAN_IP_RANGE -p tcp --dport $allowedport -d $boxip -j ACCEPT
	$IPTABLES -A FORWARD -i $INTIF -s $LAN_IP_RANGE -p udp --dport $allowedport -d $boxip -j ACCEPT
	$IPTABLES -A FORWARD -p tcp --dport $allowedport -d $boxip -m state --state NEW -j ACCEPT
	$IPTABLES -A FORWARD -p udp --dport $allowedport -d $boxip -j ACCEPT
	$IPTABLES -t nat -A POSTROUTING -p tcp -s $LAN_IP_RANGE -d $boxip --dport $allowedport -j SNAT --to-source $INTIP
	$IPTABLES -t nat -A POSTROUTING -p udp -s $LAN_IP_RANGE -d $boxip --dport $allowedport -j SNAT --to-source $INTIP
	$IPTABLES -t nat -A OUTPUT -p tcp --dport $allowedport -d $EXTIP -j DNAT --to-destination $boxip
	$IPTABLES -t nat -A OUTPUT -p udp --dport $allowedport -d $EXTIP -j DNAT --to-destination $boxip
	done
	echo -en "\033[0;31m"
	echo "The following ports have been opened for ${boxip}: ${boxports}." 
	tput sgr0
done


#
###CUSTOM USER DEFINED IPTABLES RULES###
#Put your rules here.  
#
echo -en "\033[0;31m"
echo "Your custom rules have been added."
tput sgr0


###BASIC SETUP PART 2###
#Allow returning internet traffic to your router and allow continued public
#service connections. 
$IPTABLES -A INPUT -p ALL -i $EXTIF -m state --state RELATED,ESTABLISHED -j ACCEPT
#Allow returning LAN traffic to your router and allow continued private
#service connections. 
$IPTABLES -A INPUT -p ALL -i $INTIF -m state --state RELATED,ESTABLISHED -j ACCEPT
#Allow requested internet traffic to return to your LAN.  
$IPTABLES -A FORWARD -p ALL -i $EXTIF -m state --state RELATED,ESTABLISHED -j ACCEPT
#Setup MASQ.  This is what makes all the packets originating on your LAN 
# look like they came from your public IP.  
$IPTABLES -t nat -A POSTROUTING -o $EXTIF -s $LAN_IP_RANGE -d 0/0 -j SNAT --to-source $EXTIP

####VIRTUALIZATION RULE EXAMPLES####
# NOTE: Almost everybody can completely ignore this 
# section.  Just keep it commented out and move on!  
#I use one box as a router, LAN service provider 
# and public service provider.  To make things 
# more secure, all of my public services are 
# sandboxed inside openvz containers. I use
# the rules below to allow inter network/interface
# communications with my containers.  I then just
# setup port forwarding rules for the daemons
# the containers run and things work like they should. 
# I put these here because this is where they need
# to be logically and I figured if anybody else had a
# VM setup they may be able to modify or at least get ideas from them.  If you
# do have a VM setup, be sure to set your proc settings correctly.  I have made
# notes where I think they apply. 
#Again, if you have no idea what I'm talking about, just skip this section.  
#Allow the VM to talk to any service the router offers. 
#$IPTABLES -A INPUT -p ALL -i venet0 -s $LAN_IP_RANGE -d $INTIP -j ACCEPT
#Allow the VM to talk to any service the router offers if it uses
#the public IP instead of the private IP. 
#$IPTABLES -A INPUT -p ALL -i venet0 -s $LAN_IP_RANGE -d $EXTIP -j ACCEPT
#Allow the router to talk to the VM.  
#$IPTABLES -A OUTPUT -p ALL -d $LAN_IP_RANGE -o venet0 -j ACCEPT
#Allow the VM to get to the internet.
#$IPTABLES -A FORWARD -i venet0 -s $LAN_IP_RANGE -j ACCEPT
#####
#
#End of the road. 
#If the traffic hasn't been accepted yet, log it and then drop it in a clean
# fashion.
$IPTABLES -A INPUT -m limit --limit 3/minute --limit-burst 3 -j LOG --log-level DEBUG --log-prefix "Input packet dropped:"
$IPTABLES -A FORWARD -m limit --limit 3/minute --limit-burst 3 -j LOG --log-level DEBUG --log-prefix "Forward packet dropped:"
$IPTABLES -A OUTPUT -m limit --limit 3/minute --limit-burst 3 -j LOG --log-level DEBUG --log-prefix "Output packet dropped:"
$IPTABLES -A INPUT -p tcp -j REJECT --reject-with tcp-reset 
$IPTABLES -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable 
$IPTABLES -A INPUT -j REJECT --reject-with icmp-proto-unreachable 
$IPTABLES -A FORWARD -p tcp -j REJECT --reject-with tcp-reset 
$IPTABLES -A FORWARD -p udp -j REJECT --reject-with icmp-port-unreachable 
$IPTABLES -A FORWARD -j REJECT --reject-with icmp-proto-unreachable 
#Use the DROP lines below instead of the REJECT lines above if 
# you want "stealth" results on port scans.  Whether this is more
# secure or not is debatable. When using REJECT, if someone requests a
# non-provided service your router follows protocol and nicely 
# tells the client that no such thing exists. Paranoid people argue that this
# is bad because the client then knows that your computer is at least on the
# internet.  When using DROP your router breaks protocol and just 
# ignores requests for non-offered services. IMHO a port listed as 
# closed or stealth in a scan can be considered *perfectly* secured, and if
# no unknown ports show up as open, you have a secure machine, so whats it
# matter if people know it exists, but that's just my 2 cents...
#$IPTABLES -A INPUT -p tcp -j DROP
#$IPTABLES -A INPUT -p udp -j DROP
#$IPTABLES -A INPUT -j DROP
#$IPTABLES -A FORWARD -p tcp -j DROP
#$IPTABLES -A FORWARD -p udp -j DROP
#$IPTABLES -A FORWARD -j DROP
      
echo -en "\033[0;31m"
echo "Done!"
tput sgr0
#
echo -en "\033[0;32m"
echo "YOUR FIREWALL IS NOW UP!"
tput sgr0
#
}
#
postcmd () {
###DAEMONS TO START###
#List the network daemons that you want the router to start, in the order that
# you want them to be started, in the services array below.  You must always 
# tell the operating system not to start network services at boot (using
# chkconfig) and then add them to this file so they will only be started 
# once and they will started AFTER the firewall is up. Remember to do 
# this whenever you install a new daemon!  
#
echo -en "\033[0;31m"
echo "Starting network daemons..."
tput sgr0
#
#services="sshd dhcpd named ntpd cups smb"
services=""

for daemon in $services ;  do
/etc/init.d/$daemon start
done 

echo -en "\033[0;31m"
echo "Done!"
tput sgr0

###MISC COMMANDS TO RUN###
#Put any other various commands you want to run here.  
#
echo -en "\033[0;31m"
echo "Running custom commands..."
tput sgr0
#
#Mount network file systems in fstab that couldn't be mounted at boot.  
#mount -a 
#
echo -en "\033[0;31m"
echo "Done!"
tput sgr0

echo -en "\033[0;32m"
echo "YOUR ROUTER IS NOW IN A FULLY FUNCTIONAL STATE!"
tput sgr0
}
#
###TIPS AND CODE SNIPPETS###
#If your router is also a DCHP server, use the rules below
# in the custom section instead of opening port 67 in the private
# services section for slightly more secure operations.  
#$IPTABLES -A INPUT -i $INTIF -p tcp --sport 68 --dport 67 -j ACCEPT
#$IPTABLES -A INPUT -i $INTIF -p udp --sport 68 --dport 67 -j ACCEPT
#
#
#If your router or a machine on your LAN will offer SSH as a
# publicly accessible service, use the rules below in the custom 
# section instead of opening port 22 in another
# section for more secure operations.  
#What they do: Help prevent SSH brute force password attacks.  
#
#Router / Public Service example:
#Always accept ssh connections from the LAN.  
#$IPTABLES -A INPUT -i $INTIF -s $LAN_IP_RANGE -p tcp --dport 22 -j ACCEPT
#The first time someone tries to make an SSH connection, tag it as SSH and accept it.   
#$IPTABLES -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH -j ACCEPT
#Remove the SSH tag from your other public IP's (IE: your office).  Basically,
#never consider them "hackers".  
#$IPTABLES -A INPUT -s YOUR_TRUSTED_IP_HERE -m recent --remove --name SSH -j ACCEPT
#The next time that same IP tries to make an SSH connection, increment a counter. 
#If this counter reaches 4, or if the same IP tries to SSH in more than 4 times in 1 minute 
#log the traffic and temporarily ban the offending IP.  
#$IPTABLES -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j LOG --log-prefix "SSH_brute_force "
#$IPTABLES -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j DROP
#
#Port Forwarding example (modify as needed):
#$IPTABLES -t nat -A PREROUTING -p tcp --dport 22 -d $EXTIP -j DNAT --to-destination IP_OF_SSH_SERVER:22
#$IPTABLES -t nat -A POSTROUTING -p tcp -s $LAN_IP_RANGE -d IP_OF_SSH_SERVER --dport 22 -j SNAT --to-source $INTIP
#$IPTABLES -t nat -A OUTPUT -p tcp --dport 22 -d $EXTIP -j DNAT --to-destination IP_OF_SSH_SERVER:22
#Always accept ssh connections from the LAN.  
#$IPTABLES -A FORWARD -i $INTIF -s $LAN_IP_RANGE -p tcp --dport 22 -j ACCEPT
#The first time someone tries to make an SSH connection, tag it as SSH and accept it.   
#$IPTABLES -A FORWARD -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH -j ACCEPT
#Remove the SSH tag from your other public IP's (IE: your office).  Basically,
#never consider them "hackers".  
#$IPTABLES -A FORWARD -s YOUR_TRUSTED_IP_HERE -m recent --remove --name SSH -j ACCEPT
#The next time that same IP tries to make an SSH connection, increment a counter. 
#If this counter reaches 4, or if the same IP tries to SSH in more than 4 times in 1 minute 
#log the traffic and temporarily ban the offending IP.  
#$IPTABLES -A FORWARD -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j LOG --log-prefix "SSH_brute_force "
#$IPTABLES -A FORWARD -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j DROP
#
#
#How to use this script when your ISP provides you with a static IP:
#Find and comment out everything between the lines that look
# like this  "Get outside ip" and "Setup the IP on internal interface". 
# Modify the lines below and add them to your variables section
# EXTIP=YOUR_ISP_ASSIGNED_IP
# EXTMASK=YOUR_ISP_ASSIGNED_NETMASK
# Finally, place the code below directly above the "Get outside ip" line. 
##Setup the IP on external interface
#echo -en "\033[0;31m"
#echo "Setting up the external interface."
#tput sgr0
#$IFCONFIG $EXTIF $EXTIP netmask $EXTMASK up
#echo -en "\033[0;31m"
#echo "Sleeping briefly."
#tput sgr0
#sleep 5s
#echo -en "\033[0;31m"
#echo "Your external network setup looks like this!"
#tput sgr0
#$IFCONFIG $EXTIF
#
#How I imagine you would add DMZ support.  Completely theoretical and untested.  
# This is for 1:1 DMZ mapping and not the usual DMZ network setup.  
# If you want the typical setup you will need two switches, different network
# settings on different machines, 3 NICS, several public IPs and other various
# things.  Look at the following links for more info: 
# http://iptables-tutorial.frozentux.net/scripts/rc.DMZ.firewall.txt
# http://www.cyberciti.biz/faq/linux-demilitarized-zone-howto/
# With the setup below all you need is 3 NICs, two public IPs and 1 switch. 
# NOTE: This setup is not as secure or as flexible as the DMZ network setup.
# I chose to go with it because it more  closely mimics the features found
# in the standard SOHO routers people are familiar with.  Basically, all we are
# doing is mapping 1 public IP to a machine that is already setup in your LAN.
#
#First, use your primary static public IP and setup your router using the steps
# above.  Next, modify the lines below and add them to your variables section.  
# DMZEXTIP=YOUR_2ND_ISP_ASSIGNED_STATIC_IP
# DMZIF=THE_INTERFACE_HOOKED_UP_TO_THE_ISPs_DMZ_OUTPUT
# NOTE: You may be able to use virtual interfaces. I'm not really sure, and
# that could be dangerous.  
# DMZINTIP=THE_PRIVATE(192)_IP_OF_THE_SERVER_YOU_WANT_ON_THE_DMZ
# Next, copy the lines below and place them below the "$IFCONFIG $EXTIF" line.  
#Setup the IP on DMZ interface
#echo -en "\033[0;31m"
#echo "Setting up the DMZ interface."
#tput sgr0
#$IFCONFIG $DMZIF $DMZEXTIP netmask $EXTMASK up
#echo -en "\033[0;31m"
#echo "Sleeping briefly."
#tput sgr0
#sleep 5s
#echo -en "\033[0;31m"
#echo "Your DMZ network setup looks like this!"
#tput sgr0
#$IFCONFIG $DMZIF
#Finally, add these rules to your custom section and give it a shot. 
#*Everything* going to your secondary public IP will be forwarded to the 
# internal IP of your DMZ host.  
#$IPTABLES -t nat -A PREROUTING -d $DMZEXTIP -j DNAT --to-destination $DMZINTIP
#Allow all traffic to the DMZ host to  pass unfiltered and uninspected.  
#$IPTABLES -A FORWARD -p all -d $DMZINTIP -j ACCEPT
#Make outgoing traffic look like it came from the DMZ IP instead of the standard MASQ rule. 
#$IPTABLES -t nat -A POSTROUTING -s $DMZINTIP -o $DMZIF -j SNAT --to-source $DMZEXTIP
# You may need the rules below, or something similar, to allow  all LAN-WAN and
# WAN-LAN traffic to work as expected. Read the port forwarding section for more details.  
#$IPTABLES -t nat -A POSTROUTING -p all -s $LAN_IP_RANGE -d $DMZINTIP -j SNAT --to-source $INTIP
#$IPTABLES -t nat -A OUTPUT -d $DMZEXTIP -j DNAT --to-destination $DMZINTIP
#NOTE: You will probably have edit these rules, possibly add some more, and re-arrange them in 
# the script.  This is basically a brain storm and I have no way of testing it. Good luck!      
#
###STATUS###
#The status section of code is used to print the current iptables
#configuration.
printstatus() {
echo -en "\033[0;31m"
echo "Mangle table entries (QOS, probably nothing)..."
tput sgr0
$IPTABLES -t mangle -L --verbose --numeric
echo -en "\033[0;31m"
echo "NAT table entries (port forwarding and MASQ)..."
tput sgr0
$IPTABLES -t nat -L --verbose --numeric
echo -en "\033[0;31m"
echo "Filter table entries (port forwarding and open ports on the router)..."
tput sgr0
$IPTABLES -L --verbose --numeric
        }
#
###STOP###
#The purge section of code is used to set iptables to full ALLOW mode.  All
#filtering is stopped.  This is used when you issue a stop, restart or reload
#command.  With restart and reload, things are flushed and then all rules are
#reloaded. 
purge() {
echo -en "\033[0;31m"
echo -n "Purging config and allowing all traffic..."
tput sgr0
#Set all rule sets to accept by default.  
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT
$IPTABLES -t mangle -P PREROUTING ACCEPT
$IPTABLES -t mangle -P POSTROUTING ACCEPT
$IPTABLES -t mangle -P INPUT ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -t mangle -P FORWARD ACCEPT
#Flush current rules from all rule sets.  
$IPTABLES -F
$IPTABLES -t nat -F
$IPTABLES -t mangle -F
#Remove all user defined rule sets. 
$IPTABLES -X
$IPTABLES -t nat -X
$IPTABLES -t mangle -X
#Zero the counters
$IPTABLES -Z
echo ""
echo -en "\033[0;31m"
echo "Done!"
tput sgr0
echo -en "\033[0;32m"
echo "YOUR FIREWALL IS NOW WIDE OPEN!"
tput sgr0
        }
#
#
#The first word after the /etc/iptablesgw command determines what the
#script does by using the case statements below. These cases then reference
#earlier sections in the code.  
#
case "$1" in
  start)
    echo -en "\033[0;32m"
    echo "STARTING THE FIREWALL"
    tput sgr0
    purge
    init
    setup
    postcmd
    ;;
  stop)
    echo -en "\033[0;32m"
    echo "STOPPING THE FIREWALL"
    tput sgr0
    purge
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  reload)
    echo -en "\033[0;32m"
    echo "RELOADING THE FIREWALL RULES"
    tput sgr0
    purge
    setup
    ;;
  status)
   echo -en "\033[0;32m"
   echo "PRINTING CURRENT CONFIG"
   tput sgr0
   printstatus
    ;;
  *)
    echo -en "\033[0;32m"
    echo "Usage: $0 <start|stop|restart|reload|status>"
    tput sgr0
    ;;
esac

