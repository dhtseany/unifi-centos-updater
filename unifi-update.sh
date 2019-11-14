#!/bin/bash

## Hey, you... the person reading this code... Don't use this yet. I'm still very much building in safety measures and feature updates. 
## One day in the hopefully near future I'll have it to a beta status but for now I'm just pushing every update to Master.
## You've been warned!

clear

# System Variables
DATE=$(date)
DOW=$(date +%u)
WEEK=$(date +%V)
MONTH=$(date +"%m")
YEAR=$(date +"%y")

# Misc Variables
UnifiDataDir=/opt/UniFi/data
BackupDir=/UnifiBackup
BackupFile=$BackupDir/backup$YEAR$MONTH$DOW.tar.gz
TmpDir=/tmp/unifi-updater

# PKG_VER=5.10.25
# PKG_VER=5.11.39
PKG_VER=5.12.22

runCommand=$1

if [[ ("$runCommand" == "repair") ]];
	then
		systemctl stop unifi
		systemctl stop mongod
		#/usr/bin/mongod --dbpath /opt/UniFi/data/db --port 27117 --unixSocketPrefix /opt/UniFi/run/ --logappend --logpath /opt/UniFi/logs/mongod.log --nohttpinterface --bind_ip 127.0.0.1
		mongod --dbpath=/opt/UniFi/data/db --smallfiles --logpath /opt/UniFi/logs/server.log --repair
		#chown -R ubnt:ubnt /opt/Unifi/data
		chown -R ubnt:ubnt /opt/UniFi/data/
		systemctl start mongod
		systemctl start unifi
fi
exit 0

#manualURL=$1
#if [ -z $manualURL ];
#	then
#		PKG_URL="https://dl.ubnt.com/unifi/${PKG_VER}/UniFi.unix.zip"
#		echo "[PKG_URL] $PKG_URL"
#		# exit 0
#	else
#		PKG_URL="manualURL"
#		echo "[PKG_URL] $PKG_URL"
#		# exit 0
#fi


# Create TmpDir
#mkdir -p /tmp/unifi-updater
if [ -d $TmpDir ];
	then
		mkdir $TmpDir
	else
		echo "[Info] $TmpDir already exists."
fi

if [ -d $BackupDir ];
	then
		mkdir $BackupDir
	else
		echo "[Info] $BackupDir already exists."
fi

# Check if existing backup file exists
if [ -e $BackupFile ]; 
    then
        echo "You have chosen to launch the installer but I've detected an existing backup."
        read -e -p "Shall I remove the existing backup file? [N/y] : " KILL_BACKUP

        if [[ ("$KILL_BACKUP" == "y" || "$KILL_BACKUP" == "Y") ]]; 
            then
                clear
                rm $BackupFile
            else
                clear
                echo "User to chose to keep old backup."
                mv $BackupFile $BackupFile.bak
        fi

    else
        echo "No backup files found. Proceeding."
fi

# stop the unifi service
echo "Stopping the Unifi service..."
systemctl stop unifi

# take a backup of the data directory
echo "Creating a tar.gz backup of $UnifiDataDir to $BackupFile, please wait..."
START_DATE=$(date)
echo "Started at: $START_DATE"
tar zcf $BackupFile $UnifiDataDir
END_DATE=$(date)
echo "Ended at: $END_DATE"
#tar zcf - /opt/Unifi/data | (pv -p --timer --rate --bytes > $BackupFile)



# cd to TmpDir and fetch latest installer
cd $TmpDir

if [ -f "$TmpDir/Unifi.unix.zip" ];
	then
		echo "[Yes] $TmpDir/Unifi.unix.zip"
		rm $TmpDir/Unifi.unix.zip
		read -e -p "Is that file actually gone? " readFileGone
		if [ "$readFileGone" = "y" ]; 
	                then
				echo "[great!]"
			else
				echo "[FAIL] User said the task failed. Exiting."
				exit 1
		fi
	else
            	echo "[No] $TmpDir/Unifi.unix.zip"
                read -e -p "Is that file actually gone? " readFileGone
                if [ "$readFileGone" = "y" ];
                        then
                            	echo "[great!]"
                        else
                            	echo "[FAIL] User said the task failed. Exiting."
                                exit 1
                fi

fi

echo "[Fetching] $PKG_URL"
#wget https://dl.ubnt.com/unifi/${PKG_VER}/UniFi.unix.zip
wget $PKG_URL

# Unzip the download into place
echo "Unzipping UniFi.unix.zip"
unzip -qo UniFi.unix.zip -d /opt

# Take ownership of the unzipped dir
# echo "Taking ownership of the updated Unifi directory"
# chown -R ubnt:ubnt /opt/UniFi

# Untar the backup into place
echo "Restoring $BackupFile to $UnifiDataDir"
# tar xzf $BackupFile -C $UnifiDataDir
tar xzf $BackupFile -C /

# Take ownership of the unzipped dir
echo "Taking ownership of the updated Unifi directory"
chown -R ubnt:ubnt /opt/UniFi

# Start the Unifi service
echo "Starting to Unifi service..."
systemctl start unifi

# Complete
echo "Process is completed."
exit 0