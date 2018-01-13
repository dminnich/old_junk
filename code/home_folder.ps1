#RUN ME IN AN ELEVATED POWERSHELL WINDOW WITHOUT SIGNING ENABLED!
#
#This is an ugly powershell script that will take a text file full of usernames and create home
#like directories for them.  
#
#users.txt must exsist in the directory that houses this script and where
#you eventually want their folders.  Users must be listed one per line and contain no spaces
#or weird characters.  

#NOTE: Lots of things are hard coded. 
#You will need to change the DOMAIN definition, the group names and the quota size.
#Also, it is a good idea to check a few dirs by hand when you are done.
#DM


#Create the directories.  
foreach ($user in get-content users.txt) {
mkdir $user
}



#Give the local machine administrators group 
#full access to the folders.  
foreach ($user in get-content users.txt) {
echo y| cacls $user /C /p Administrators:F Administrator:F
}




#Give other groups in the domain full access to the folders. 
foreach ($user in get-content users.txt) { 
icacls $user /grant DOMAIN\SYSADMINS:`(OI`)`(CI`)F
icacls $user /grant DOMAIN\TEACHERS:`(OI`)`(CI`)F
icacls $user /grant DOMAIN\LabAdmins:`(OI`)`(CI`)F
}



#Give the user FULL access to their folder.  
foreach ($user in get-content users.txt) {
$fquser="DOMAIN\$user"
$colon=":"
icacls $user /grant $fquser$colon`(OI`)`(CI`)F
}





#Make the user the owner of the folder and all subfolders
foreach ($user in get-content users.txt) {
icacls $user /setowner $user /T /C /L
}





#Remove any previously inherited permissions.
foreach ($user in get-content users.txt) {
icacls $user /inheritance:r
}



#Set quotas on the folders
$cwd = (pwd).path
dirquota quota add /Path:$cwd\* /Limit:10gb /Type:Hard /Status:Enabled /Overwrite 

