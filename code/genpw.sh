#!/bin/bash
#This script will help you come up with secure passwords.  It works
#by creating predictable passwords in a creative fashion. Basically, it 
#mixes hashes from  special, never changing, files on your machine
#with the input you feed the script and a hash of the input you feed it.  
#I usually use three different files as a way to create tiers of access 
#and feed the sites name plus my initials or username as the input of the script.  
#
#To make things even more unique, you can customize how many times your files
#and input go through the md5 cycle, how many characters to skip when
#constructing the final password from the hashes and how long the final
#passowrd should be.  One final note, make sure you keep a bit by bit backup of
#your 3 files and this script so you can re-generate your passwords whenever
#you need to. 
#
#
#Also note that this script outputs your passwords to your terminal.  
#Keep the local workstation secure and clear your history reguarlly or
#preface every execution of this script with a SPACE so it won't be
#stored in history if you are super paranoid.   
#
#
#Yes. This is ugly and comes with no gurantees.  
#DM 
#
#
#Example of how this works. 
#1 Skip, 1 md5 cycle, 12 character limit
#special file: md5sum weddingpic.jpg 4962e005167a3235ce76a6d2f4b5b8b4
#input: Dtarget.comM
#hash of input: echo "Dtarget.comM" | md5sum 17943f8391baebe6437d38d7f8ea24b4 
#password is 4 chunks from each: 46e0Dagtc1938

#Debugging
#set -x




###VARIABLES
#Security level file definitions
LOW="/home/dminnich/a.jpg"
MED="/home/dminnich/b.jpg"
HIGH="/home/dminnich/c.jpg"
#Number of times to put input and file through MD5
CYCLES=5
#Characters to skip when creating password
SKIP=2
#Passowrd character limit. MUST BE A MULTIPLE OF 3. 
#How high this value and the skip value are determine
#how long your input must be.  Look for the confusting
#math later in the script for more details.  
LIMIT=15
#
#
#


####SANITY CHECKS####
#If not enough info is passed to the script display the usage info. 
if [ $# -lt 3 ]; then 
echo "usage: genpw -l low|med|high input"
exit 1
fi

#If a proper password level isn't given, complain and show usage.
if [ "$2" != "low" -a "$2" != "med" -a "$2" != "high" ]; then
echo "bad password level definition"
echo "usage: genpw -l low|med|high input"
exit 1 
fi

#If the low security file doesn't exist complain
if [ "$2" == "low" -a ! -e ${LOW} ]; then
echo "your low security file does not exist or can not be accessed."
exit 1
fi

#If the medium security file doesn't exist complain
if [ "$2" == "med" -a ! -e ${MED} ]; then
echo "your medium security file does not exist or can not be accessed."
exit 1
fi

#If the high  security file doesn't exist complain
if [ "$2" == "high" -a ! -e ${HIGH} ]; then
echo "your high security file does not exist or can not be accessed."
exit 1
fi

#The input must be longer than the LIMIT divided by 3 times the skip value plus
#one. Otherwise, the script wouldn't be able to get enough characters from it
#to create its part of the password. 

#Fail Example (limit 15 and skip 2):
#input: a.com
#15/3 = 5
#2+1 = 3
#5*3 = 15
#In this example it would grab "ao" and it since it needs 5 characters it would fail. 

#Working example (limit 15 and skip 2):
#input: alongstorename.com
#15/3 = 5
#2+1 = 3
#5*3 = 15
#Would grab "antem". 

INPUT=$3
REQUIREDLENGTH=$(($LIMIT / 3))
SKIPP1=$(($SKIP + 1))
REQUIREDLENGTH=$(($REQUIREDLENGTH * $SKIPP1))
if [ ${#INPUT} -lt ${REQUIREDLENGTH} ]; then
echo "your input was not long enough.  it must be at least ${REQUIREDLENGTH} characters long."
exit 1
fi



####CYCLE EXPRESSION CONSTRUCTION####
CYCLEEXP=""
for ((i=$CYCLES; i>0; i=i-1))
do
#5 cycles means 5 of these appended to each other. 
#Your cycle value is subtracted by one each run until it gets to zero.
CYCLEEXP="$CYCLEEXP | md5sum"
done
#
#


####INPUT HASH CONSTRUCTION###  
#what you typed plus all the md5sum cycles constructed above.  
INPUTHASH="echo $INPUT ${CYCLEEXP}"
#store the results
INPUTHASH=`eval $INPUTHASH | awk '{ print $1 }'`
#echo INPUTHASHED VALUE IS $INPUTHASH




####LOW FILE HASH CONSTRUCTION.###
LOWHASH="md5sum $LOW ${CYCLEEXP}"
#only do this work if low was specified
if [ "$2" == "low" ]; then
LOWHASH=`eval $LOWHASH | awk '{ print $1 }'`
FILEHASH=$LOWHASH
#echo $LOWHASH
fi


####MED FILE HASH CONSTRUCTION.####  
MEDHASH="md5sum $MED ${CYCLEEXP}"
if [ "$2" == "med" ]; then
MEDHASH=`eval $MEDHASH | awk '{ print $1 }'`
FILEHASH=$MEDHASH
#echo $MEDHASH
fi


####HIGH FILE HASH CONSTRUCTION.###  
HIGHHASH="md5sum $HIGH ${CYCLEEXP}"
if [ "$2" == "high" ]; then
HIGHHASH=`eval $HIGHHASH | awk '{ print $1 }'`
FILEHASH=$HIGHHASH
#echo $HIGHHASH
fi

#echo FILEHASH IS $FILEHASH

####GRAB THE FIRST PASSWORD CHARACTERS FROM THE FILE HASH###
#Figure out how many characters we are getting from this string. 
CHARSTOGRAB=$(($LIMIT / 3))
#Where to start skipping at.  
CHAR=1
#Stop loop counter.
COUNTER=0
#We need one more than skip since string starts at 1.  
SKIPP1=$(($SKIP + 1))
#Create an empty placeholder for this sequence of chars.
FHPW=""
#Start loop at zero and add one for each itteration
#until it equals the CHARSTOGRAB value.
for((i=$COUNTER; i!=$CHARSTOGRAB; i++));
do
#Get the character from the filehash at character 
#position X (char) and get only that character 
#length of 1.  
GRABBEDCHAR=`expr substr $FILEHASH $CHAR 1`
#Each time we go through the loop add the last character
#to the eventual password hash.  
FHPW="$FHPW$GRABBEDCHAR"
#echo $FHPW
#echo $CHAR
CHAR=$(( $CHAR +$SKIPP1 ))
done
#echo PASSWORD PART OF FILEHASH IS $FHPW


####GRAB THE MIDDLE PASSWORD CHAREACTERS FROM THE STANDARD INPUT###
#Figure out how many characters we are getting from this string. 
CHARSTOGRAB=$(($LIMIT / 3))
#Where to start skipping at.  
CHAR=1
#Stop loop counter.
COUNTER=0
#We need one more than skip since string starts at 1.  
SKIPP1=$(($SKIP + 1))
#Create an empty placeholder for this sequence of chars.
SIPW=""
#Start loop at zero and add one for each itteration
#until it equals the CHARSTOGRAB value.
for((i=$COUNTER; i!=$CHARSTOGRAB; i++));
do
#Get the character from the filehash at character 
#position X (char) and get only that character 
#length of 1.  
GRABBEDCHAR=`expr substr $INPUT $CHAR 1`
#Each time we go through the loop add the last character
#to the eventual password hash.  
SIPW="$SIPW$GRABBEDCHAR"
#echo $SIPW
#echo $CHAR
CHAR=$(( $CHAR +$SKIPP1 ))
done
#echo INPUT PART OF PASSWORD HASH IS $SIPW


####GRAB THE LAST PASSWORD CHAREACTERS FROM THE HAHED INPUT###
#Figure out how many characters we are getting from this string. 
CHARSTOGRAB=$(($LIMIT / 3))
#Where to start skipping at.  
CHAR=1
#Stop loop counter.
COUNTER=0
#We need one more than skip since string starts at 1.  
SKIPP1=$(($SKIP + 1))
#Create an empty placeholder for this sequence of chars.
IHPW=""
#Start loop at zero and add one for each itteration
#until it equals the CHARSTOGRAB value.
for((i=$COUNTER; i!=$CHARSTOGRAB; i++));
do
#Get the character from the filehash at character 
#position X (char) and get only that character 
#length of 1.  
GRABBEDCHAR=`expr substr $INPUTHASH $CHAR 1`
#Each time we go through the loop add the last character
#to the eventual password hash.  
IHPW="$IHPW$GRABBEDCHAR"
#echo $SIPW
#echo $CHAR
CHAR=$(( $CHAR +$SKIPP1 ))
done
#echo INPUT HASH PART OF PASSOWRD IS $IHPW


####PUT THE PASSWORD TOGETHER AND OUTPUT IT####
PW="$FHPW$SIPW$IHPW"
echo $PW
