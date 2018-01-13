# old_junk
This repo exists mainly for archival purposes.  It contains documentation, PHP, shell scripts, etc that I wrote for jobs or for learning purposes long long ago.  Some of this stuff is over a decade old at this point.  I STRONGLY SUGGEST you search for other ways to solve your problems.  




## Documentation

 - cloning.pdf - Steps I used to use clone data from complex linux server installs.  Has notes about LVM, mdadam, etc. STATUS: Parts of this may still be useful.  
 - debian_preseed.txt - Write up on how I used to quickly image old computers to run Debian and then sell them at reduced prices to the elderly or people in need. STATUS: Likely too old to be useful. 
 - dvd.txt - How I used to backup dual layer DVDs on linux machines. STATUS: Nobody cares about DVDs anymore. 
 - imager.pdf -  Used a long time ago as a home-grown solution to create restore partitions on Windows XP machines. STATUS: Likely too old to be useful. 
 - linux_AD_interoperbility.txt - How I used to join linux samba file servers to an AD domain and the settings that were needed on both sides.  STATUS: Likely too old to be useful.
 - linux_home_server.txt - A document I put together a long time ago when I installed countless services on a home server.  STATUS: Likely too old to be useful.
 - linux_tips.pdf - A presentation I gave to researchers who were linux novices.  STATUS: Still useful for beginners. 
 - samba.txt - How to create a publicly readable and writable samba share.  STATUS: Likely too old to be useful. 
- transfer_quotas.txt - How to copy linux quoats from one machine to another.  STATUS: Too simplistic, not worth using. Likely better documentation elsewhere.
- usb_kickstart.txt - How I used to make RHEL6 kickstart USB media.  STATUS: Too simplistic, not worth using. Likely better documentation elsewhere.
- webhost.txt - How to setup a ~username web server.  STATUS: Likely too old to be useful.

## Code

 - adscripts.tar.gz - Used a long time ago to create and edit users and groups inside of  AD via ldap commands. STATUS: Too simplistic, not worth using. 
 - autorun0 - part of imager.pdf.  Used a long time ago as a home-grown solution to create restore partitions on Windows 7 machines. STATUS: Likely too old to be useful. 
 - bind_dyndns.sh - Use your own BIND servers and nsupdate to do dynamic DNS. STATUS: Probably still works. 
 - blacklist2.sh - Stupid simple script I used to ban people by IP address on FTP and game servers.  STATUS: Too simplistic, not worth using.
 - genpw.sh - Generates deterministic passwords.  STATUS: Too simplistic, not worth using.
 - grepscript.sh - Crawls logs from and outputs things you didn't exclude. STATUS: Use Splunk, ELK, etc instead. 
 - home_folder.ps1 - How I used to batch create directories with specific permissions on AD boxes.  STATUS: Too simplistic, not worth using.
 - inactive_user_check.sh- How I used to look for accounts that hadn't touched files in multiple years so their data could be moved to cold storage. STATUS: Too simplistic, not worth using.
 - iptablesgw.sh - Used to run this to turn a linux box into a router.  STATUS: Use pfsense, ipfire, etc instead. 
 - ldapbackup.sh - Used to run this to backup openldap servers.  STATUS: Too simplistic, not worth using.
 - packages.txt - Goes along with the debian_preseed.txt documentation. STATUS: Likely too old to be useful. 
 - MASSautorun2 - part of imager.pdf.  Used a long time ago as a home-grown solution to create restore partitions on Windows 7 machines. STATUS: Likely too old to be useful. 
 - massemail.sh - A simplistic script that does basic mail-merge type stuff.  STATUS: Too simplistic, not worth using. Use mailchimp or some other service. 
 - mysqlbackup.sh - Used to use this to backup mysql servers.  STATUS: Too simplistic, not worth using.
 - nagios_check_rdiff.sh - NRPE monitoring script to check the status of rdiff backups.  STATUS: Pretty simplistic but may still be useful.  
 - nagios_check_ro_mount.sh - NRPE monitoring script to check for RO filesystmes.  STATUS: Too simplistic, not worth using.
 - nis_to_ad.tar - Scripts used a long time ago to migrate linux users to an AD environment.  STATUS: Too simplistic, not worth using.
 - php_simple_fileed.tar.gz - Allows you to browse and edit text files live in your browser. STATUS: Likely too old to be useful. Use pydio or eXtplorer or owncloud. 
 - php_simple_file_sharer.tar.gz - A mediafire, rapidshare,etc like thing.  STATUS: Likely too old to be useful. Use projectsend?
 - php_simple_gallery.tar.gz - Image gallery script.  STATUS: Likely too old to be useful. Use gallery or Coppermine.
 - php_simple_image.tar.gz - Displays a random image.   STATUS: Likely too old to be useful. Too simplistic, not worth using.
 - php_simple_indexer.tar.gz - Allows you to customize directory indexes.  STATUS: Likely too old to be useful. Use h5ai. 
 - php_simple_news.tar.gz - Simple news or blogging script.  STATUS: Likely too old to be useful. Use wordpress, htmly or countless others. 
 - php_simple_quote.tar.gz - Displays a random quote.   STATUS: Likely too old to be useful. Too simplistic, not worth using.
 - ps.conf - Goes along with the debian_preseed.txt documentation. STATUS: Likely too old to be useful. 
 - qos.sh - Script I used to use on my linux based router to control traffic shaping.  STATUS: Too simplistic, not worth using.  Use pfsense, ipfire.  
 - research_disk_usage.sh - Super simplistic disk usage gathering script that I used to use to draw trends. STATUS: Too simplistic, not worth using.
 - remote_copy.ps1 - Script I used to use to copy another script to a list of windows machines and then execute that script.  STATUS: Too simplistic, not worth using.  Use Ansible.
 - rsync.sh - Super simple script that keeps two drives in sync while keeping the backup drive in RO mode most of the time to ensure no slip ups happen.  STATUS: Too simplistic, not worth using. Use rsnapshot or any other decent backup software. 
 - setup.sh - Goes along with the debian_preseed.txt documentation. STATUS: Likely too old to be useful. 
 - status2.sh - Simple cronable server info gathering script.  STATUS: Too simplistic, not worth using. Use logwatch, splunk, nagios, etc.  
 - systembackup.sh - Simple script that tars of folders on a system for backups.  STATUS: Too simplistic, not worth using. Use rsnapshot or any other decent backup software. 
 - user_disk_usage.sh - Dead simple script to make a csv for trend drawing out of user home directory disk usage. STATUS: Too simplistic, not worth using.


