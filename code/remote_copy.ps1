#This powershell script can be used to copy files and folders to a list of
#remote computers.  Specify the computers, one per line, in a file named
#computer-list.txt that is in the same directory as this script.  


#You can also use this script to install applications on remote computers.  
#If you want to do this, you will need to install PSTools 
#http://technet.microsoft.com/en-us/sysinternals/bb897553 on your machine under 
#c:\windows.  You will also need to set the INSTALLER variable to the full 
#path of where the installer will be on the remote computers once it is copied there.  


#Usage:
#Log into the domain on your desktop machine using an account that has admin rights 
#over the remote machines you want to work on.
#Put this script and a computer-list.txt file you construct in your home directory somewhere.
#Set the variables at the top of this script so that they meet your needs.
#Launch powershell. 
#cd to the directory holding this script in powershell. 
#create the source folder on your machine. place the files you want copied in it.
#run the script.

#DM



#where the files you want to copy are.
$SOURCE = "C:\Users\dminnich\workspace\batchtmp"
#where you want to put the files on the remote machines. be sure to set this in "share" format. 
$DESTINATION = "c$\batchtmp"
#where to log our results
$LOG = "C:\Users\dminnich\workspace\remote_copy.log"
#full path to where the application installer will be on the destination machine.
#$INSTALLER = "C:\batchtmp\FileZilla_3.3.5.1_win32-setup.exe"
$INSTALLER = ""
#parmaters to pass to the installer.  
$INSTALLERPARAMS = "/S"



#start the work
#remove remains from previous runs. don't display errors.
Remove-Item $LOG -ErrorAction SilentlyContinue
foreach ($computer in get-content computer-list.txt) {
#remove remains from previous runs. don't display errors.
Remove-Item \\$computer\$DESTINATION -recurse -ErrorAction SilentlyContinue
#copy the files including all sub-dirs even if they are empty.
#don't retry the copy if the machine isn't accessible.
#log and display all statistics
robocopy $SOURCE \\$computer\$DESTINATION /E /R:0 /W:0 /TEE /LOG+:$LOG


##APP INSTALL SECTION
#If the installer variable is set, attempt to install the app. 
#Show the progress on the screen and append it to the log file. 
#PStools uses standard error and standard out for messages. we want to see both and we want to see 
#both in real time and in the logs. PowerShell doesn't have tee with an append option so you have 
#to do this crazy crap.

if( $INSTALLER ) { 
psexec \\$computer $INSTALLER $INSTALLERPARAMS 2>&1 | tee-object -Variable teevar
out-file $LOG -InputObject $teevar -Append
#If all you wanted to do was install the app, you can remove the files you copied over now
Remove-Item \\$computer\$DESTINATION -recurse -ErrorAction SilentlyContinue
}
}

#spit out the errors in a more pronounced manner
Write-Host "THE FOLLOWING ERRORS OCCURRED:" -foregroundcolor red -backgroundcolor yellow
#errors from robocopy
FINDSTR ERROR $LOG
