#!/bin/bash
#This script will allow you to send mass customized emails.  I can think of
#several different scenarios in which people would like to do this.  Please
#read through the script and un-comment sections (or modify sections if
#necessary) so it will meet your needs.  

#You will need a properly configured MTA, like sendmail or postfix, on the host
#that you run this script on.  Don't ask me for help in doing this!

#Scenario list: 

#1- 
#Take a list of email addresses and send them all the same
#static message, just updating the salutation. 
#HEADER= "Dear X". (X updated to be persons name on the fly).  
#BODY=  You are invited to my birthday party on november 12th.  
#FOOTER= Love, Dusty.  

#2-
#Send customers reporting data from a script or database query. 
#HEADER= "Dear Mr. X" (X updated ot persons name on the fly).  
#BODY= You are over your bandwidth limitation.  
#DYNAMIC_BODY=You have used X of X allowed (pulled from a script or database
#query you write.) gigs. 
#FOOTER= Your bill this month will include an additional $5 for every Gig of
#overage above.  If you have any questions, please contact us.

#3-
#Send people emails that includes lots of data you pull from a text based
#database/spreadsheet.   
#HEADER= "Dear X," (name updated on the fly).  
#BODY=Our current contact information for you is as follows:
#DYNAMIC_BODY: AWK a text file for columns of information. 
#FOOTER=If any of the above is incorrect please reply
#to this email stating the corrections.   

#QUICK NOTES:
#PLEASE DO NOT USE THIS FOR SPAMMING!
#This script requires a recent version of bash. 
#PLEASE DO NOT USE THIS FOR SPAMMING!
#I wrote this script for my own personal use. It has no error checking
#and is very un-optimized.  In other words, it is not production quality, 
#and should be looked at more as a block of code to learn from.  
#PLEASE DO NOT USE THIS FOR SPAMMING!
#This is the only planned version of this script and I will not be 
#offering any support for it. In short--don't contact me. 
#PLEASE DO NOT USE THIS FOR SPAMMING!
#If you need to insert some dynamic information inside a block of static
# text, the easiest thing to do is to add the static text before and after
#the dynamic text to the spreadsheet/database.  For example: If you want
#to say "Congratulations Dustin! You may have already won."  I would make
#column X in the spreadsheet "Congratulations " column A all my names and
#column Y in the spreadsheet "! You may have already won." .  Then 
#you could AWK X A Y. This is ugly, but it is an easy way to accomplish 
#what you would like to do. My suggestion is this: try to make all of your
#dynamic information appear in its own block outside of the static text
#see example 3.  
#PLEASE DO NOT USE THIS FOR SPAMMING!

##### START SCRIPT #####

#Please choose a way you would like to use this script.  See scenarios above
#and look in the script for further examples. By default it does a static 
#email to with name replacement.  
SCENARIO=1


#SCENARIO 1.  
#Static email with name replacement.  Good for friends. 
if [ $SCENARIO = "1" ]; 

###Files needed:
##generic_header.txt
#What will be at the top of your emails.  Dear _PARTNER_, 
#You must have _PARTNER_ like that.  Also include 
#anything else you would like at the top of the email.
##generic_email_list.txt
#A tab delimited file email address to name list. 
#bill.gates@microsoft.com	Bill Gates
##generic_body.txt
#The actual body of your email. 
##generic_footer.txt
#What will be at the bottom of your emails.  
then {

#Delete any files left over by previous runs of this script. 
rm -f *:EMAILOUT
rm -f *:MASSMAILTMP
#Create an EMAILOUT file for each email address in generic_email_list.txt.
#These will be the files that get appended to and will eventually be the
#emails that will go out.  
for i in `cat generic_email_list.txt | awk '{ print $1}'`
do touch $i:EMAILOUT
done
#Insert header in all EMAILOUT files.  
for i in `ls *:EMAILOUT`
do cat generic_header.txt>>$i
done
#Replace _PARTNER_ with the name of the file, 
#minus the EMAILOUT part. 
#Meaning Dear _PARTNER_, will turn into Dear 
#bill.gates@microsfot.com.   
for i in `ls *:EMAILOUT`
do sed -i "s/_PARTNER_/${i%%:EMAILOUT}/" $i
done

#Use the filename to determine the email address. Replace that email address
#in the files with whatever the email address resolves to in
#generic_email_list.txt.  In other words convert Dear bill.gates@micrsoft.com
#to Dear Bill Gates.
#NOTE: The awk replacement leaves an extra space.  Dear  Bill Gates.  If that 
#bothers you just change your header to Dear_PARTNER_. 
for i in `ls *:EMAILOUT`
do sed -i "s/${i%%:EMAILOUT}/`grep ${i%%:EMAILOUT} generic_email_list.txt | awk '{$1 =""; print}' -`/" $i
done

#Insert the contents of generic_body.txt into the emails.  
for i in `ls *:EMAILOUT`
do cat generic_body.txt>>$i
done

#Insert the contents of generic_footer.txt into the emails.  
for i in `ls *:EMAILOUT`
do cat generic_footer.txt>>$i
done

#Send the emails!
#Pipe the email files to mail.  Use the filename minus
#the :EMAILOUT as the email address(es) to send it to. 
#Set the subject below.
SUBJECT='Birthday Invite!'
for i in `ls *:EMAILOUT`
do cat ${i} | mail -s "$SUBJECT" ${i%%:EMAILOUT}
done
}





#SCENARIO 2
#Good for combining dynamic data out of a 
#database server (like MySQL) with static 
#text.  
elif [ $SCENARIO = "2" ];
then {
###Files needed:
##db_header.txt
#What will be at the top of your emails.  Mr. _PARTNER_, 
#You must have _PARTNER_ like that.  Also include 
#anything else you would like at the top of the email.
##db_body_head.txt
#The body of your email before the inserted content. 
##The actual database
#Must include the dynamic content and the static content directly around it.
##db_body_foot.txt
#The body of your email after the inserted content.  
##db_footer.txt
#What will be at the bottom of your emails.  

#Delete any files left over by previous runs of this script. 
#NOTE: A comma was chosen as a delimiter because it is an illegal
#email address character, and because cut can use it in scripts. 
rm -f *:EMAILOUT
rm -f *:MASSMAILTMP

#Create an EMAILOUT file for each email address in the database.
#These will be the files that get appended to and will eventually be the
#emails that will go out.  
#DO CUSTOM DB CALLS to pull this off.  

#Insert header in all EMAILOUT files.  
##Mr. _PARTNER_,
for i in `ls *:EMAILOUT`
do cat db_header.txt>>$i
done

#Replace _PARTNER_ with the name of the file, 
#minus the EMAILOUT part. 
#Meaning Mr. _PARTNER_, will turn into Mr. 
#bill.gates@microsfot.com.   
for i in `ls *:EMAILOUT`
do sed -i "s/_PARTNER_/${i%%:EMAILOUT}/" $i
done

#Use the filename to determine the email address. Replace that email address
#in the files with whatever last name relates to that email address
#in the database.  In other words convert Mr: bill.gates@micrsoft.com:
#to Mr. Gates:.
#for i in `ls *:EMAILOUT`
#DO CUSTOM DB CALLS to pull this off. 

#Insert the static body header.  
##This email is to inform you that your site recently surpassed its bandwidth
#quota.  
for i in `ls *:EMAILOUT`
do cat db_body_head.txt>>"${i}";
done

#Insert the dynamic content and the static content directly around it from the
#database. 
##You have now used X gigs out of your allocated X gigs of bandwidth this month.  
#DO CUSTOM DB CALLS to pull this off.

#Insert the static body footer.  
#Your bill this month will include an additional $5 for every gig of overage
#stated above.
for i in `ls *:EMAILOUT`
do cat db_body_foot.txt>>"${i}";
done

#Insert the footer
#If you have any questions or concerns please feel free to contact us.  
#Thank You, Fake Host.  
for i
in `ls *:EMAILOUT`
do cat db_footer.txt>>"${i}";
done

#Send the emails!
#Pipe the email files to mail.  Use the filename minus
#the :EMAILOUT as the email address(es) to send it to. 
#Set the subject below.
SUBJECT='Fake Hosts Bandwidth Overage Notice'
for i in `ls *:EMAILOUT`
do cat ${i} | mail -s "$SUBJECT" ${i%%:EMAILOUT}
done
}






#SCENARIO 3.
#Good for pulling lots of data out of a text file
#database/spreadsheet you have constructed.  

elif [ $SCENARIO = "3" ];
then {

###Files needed:
##txtdb_header.txt
#What will be at the top of your emails.  Dear _PARTNER_, 
#You must have _PARTNER_ like that.  Also include 
#anything else you would like at the top of the email.
##txtdb_body_head.txt
#The body of your email before the inserted content. 
##txtdb_db.txt
#A comma seperated spreadsheet/database in UNIX breaking
#format that we will use to build the dynamic part of the
#email.  This will be referred to as the dynamic body. 
##txtdb_body_foot.txt
#The body of your email after the inserted content.  
##txtdb_footer.txt
#What will be at the bottom of your emails.  


#txtdb_db.txt will have the following syntax in our example:
#email address, First Name, Last Name, Address, Phone Number, (empty space),
#The space is needed for formatting.  Basically, if you print 2 awked values
#next to each other you sometimes need a space.  Printing $2 $3 in this example
#would print BillGates, now if we print $2 $6 $3 it will be Bill Gates.  I know
#this is an ugly hack, but hey, it works :). NOTE: The space entry will end up
#looking like this , ,.  NOTE: It is very important to make sure that entries
#in the database do NOT include commas, quotes, or any other special 
#characters.    

#NOTE: A comma was chosen as a delimiter in operations below because it is an
#illegal email address character, and because cut can use it in scripts. 

#Delete any files left over by previous runs of this script. 
rm -f *:EMAILOUT
rm -f *:MASSMAILTMP

#make sure the csv text file is unix readable
dos2unix txtdb_db.txt

#Create an EMAILOUT file for each email address in txtdb_db.txt.
#These will be the files that get appended to and will eventually be the
#emails that will go out.  
cat txtdb_db.txt | awk -F"," '{ print $1 }' | while read LINE;
do touch "${LINE}".:EMAILOUT;
done

#Insert our header into all the files.
##Dear _PARTNER_,
for i in `ls *:EMAILOUT`
do cat txtdb_header.txt>>"${i}";
done

#Replace _PARTNER_ with the name of the file, 
#minus the EMAILOUT part. 
#Meaning Dear _PARTNER_, will turn into Dear 
#bill.gates@microsfot.com.   
for i in `ls *:EMAILOUT`
do sed -i "s/_PARTNER_/${i%%:EMAILOUT}/" $i
done

#Use the filename to determine the email address. Replace that email address
#in the files with whatever first and last name relates to that email address
#in txtdb_db.txt  In other words convert Dear bill.gates@micrsoft.com
#to Dear Bill Gates.
for i in `ls *:EMAILOUT`
do sed -i "s/${i%%:EMAILOUT}/`grep ${i%%:EMAILOUT} txtdb_db.txt | awk -F"," '{print $2 $6 $3}' -`/" $i
done

#Insert the static body header.  
##Our current contact information for you is as follows: 
for i in `ls *:EMAILOUT`
do cat txtdb_body_head.txt>>"${i}";
done

#We will now begin inserting the dynamic body. We 
#will do this across several statements so that 
#we can have line breaks.  

#Insert name
for i in `ls *:EMAILOUT`
do cat txtdb_db.txt | grep ${i%%:EMAILOUT} | awk -F"," '{ print $2 $6 $3 }'>>${i}
done

#Insert address
for i in `ls *:EMAILOUT`
do cat txtdb_db.txt | grep ${i%%:EMAILOUT} | awk -F"," '{ print $4 }'>>${i}
done

#Insert phone number
for i in `ls *:EMAILOUT`
do cat txtdb_db.txt | grep ${i%%:EMAILOUT} | awk -F"," '{ print $5 }'>>${i}
done

#Insert email address
for i in `ls *:EMAILOUT`
do cat txtdb_db.txt | grep ${i%%:EMAILOUT} | awk -F"," '{ print $1 }'>>${i}
done

#Insert the static body footer.  
##If any of the above is incorrect please reply
#to this email stating the corrections. 
for i in `ls *:EMAILOUT`
do cat txtdb_body_foot.txt>>"${i}";
done

#Insert the footer
##Thank You, Fake Corp
for i in `ls *:EMAILOUT`
do cat txtdb_footer.txt>>"${i}";
done

#Send the emails!
#Pipe the email files to mail.  Use the filename minus
#the :EMAILOUT as the email address(es) to send it to. 
#Set the subject below.
SUBJECT='Fake Corps Yearly Customer Contact Information Check Up'
for i in `ls *:EMAILOUT`
do cat ${i} | mail -s "$SUBJECT" ${i%%:EMAILOUT}
done

}

else 
echo Improper scenario chosen. 

fi
