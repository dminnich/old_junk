#!/bin/bash
#this is an ugly script i created to do post setup stuff after a debian preseed.  
#you could run it from the preseed or do some of this work in the preseed
#itself, but I prefer to do it after the fact and to keep the preseed and
#initial install as basic as possible. 
#DM

###VARS####
LOG="setup.log"

###CLEANUP###
#remove the previous log
rm -f "${LOG}"


###UPDATES###
echo -e '\E[34;40m Updating package database...'; tput sgr0
apt-get -y update
if [ "$?" -ne "0" ];
then
	echo -e '\E[31;40m Failed to update the package database!'; tput sgr0
	echo "Failed to update the package database!" >> "${LOG}"
else 
	echo -e '\E[34;40m Successfully updated the package database.'; tput sgr0
	echo "Successfully updated the package database." >> "${LOG}"
fi
echo -e '\E[34;40m Installing updates...'; tput sgr0
apt-get -y upgrade
if [ "$?" -ne "0" ];
then
	echo -e '\E[31;40m Failed to install updates!'; tput sgr0
	echo "Failed to install updates!" >> "${LOG}"
else 
	echo -e '\E[34;40m Successfully installed updates.'; tput sgr0
	echo "Successfully installed updates." >> "${LOG}"
fi


###PACKGE GROUPS/TASKS###
#get with tasksel --list-tasks
PKGGROUPS="desktop"
for i in ${PKGGROUPS}
do
#	PKGGROUPINSTALLED=$(tasksel --list-tasks | grep "${i}" | awk -F" " '{print $1 }')
	PKGGROUPINSTALLED=$(tasksel --list-tasks | awk -F" " '{print $2 "," $1}' | grep -c "^${i},i$")
#if [ "${PKGGROUPINSTALLED}" == "u" ]
	if [ "${PKGGROUPINSTALLED}" -lt "1" ]
	then
		echo -e '\E[34;40m' "Installing the ${i} package group..."; tput sgr0
		tasksel install "${i}"
			if [ "$?" -ne "0" ];
			then
				echo -e '\E[31;40m' "Failed to install the "${i}" package group!"; tput sgr0
				echo "Failed to install the "${i}" package group!" >> "${LOG}"
			else 
				echo -e '\E[34;40m' "Successfully installed the "${i}" package group."; tput sgr0
				echo "Successfully installed the "${i}" package group." >> "${LOG}"
			fi
	else
		echo -e '\E[34;40m' ""${i}" package group is already installed."; tput sgr0
		echo ""${i}" package group is already installed." >> "${LOG}"
		continue
	fi 
done

###PACKAGING###
#read the list of packages one full package name per line from packages.txt
#and do the install work and log what has been done. 
while read LINE
do 
#echo "${line}"
#INSTALLEDPKGCOUNT=$(dpkg --get-selections | grep -i -c "^${LINE}$")
#INSTALLEDPKGCOUNT=$(dpkg --get-selections | awk -F"\t" '{print $1 }' | grep -i -c "^${LINE}$")
	INSTALLEDPKGCOUNT=$(dpkg --list | awk -F" " '{print $2 "," $1}' | grep -c "^${LINE},ii$")

	if [ "${INSTALLEDPKGCOUNT}" -lt "1" ]
	then 
		echo -e '\E[34;40m' "Installing "${LINE}"..."; tput sgr0
		apt-get install -y "${LINE}"
		if [ "$?" -ne "0" ];
                then
			echo -e '\E[31;40m' "Failed to install "${LINE}"!"; tput sgr0
			echo "Failed to install "${LINE}"!" >> "${LOG}"
		else 
			echo -e '\E[34;40m' "Successfully installed "${LINE}"."; tput sgr0
			echo "Successfully installed "${LINE}"." >> "${LOG}"
		fi
		
	else
		echo -e '\E[34;40m' ""${LINE}" is already installed."; tput sgr0
		echo ""${LINE}" is already installed." >> "${LOG}"
		continue
	fi 
done < "packages.txt"



###DONE###
echo -e '\E[32;40m' "The auto-setup script is now done running.  Be sure to check the log file for errors."; tput sgr0
