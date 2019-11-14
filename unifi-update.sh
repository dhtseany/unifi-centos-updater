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
		echo "[Info] $TmpDir does not exist. Creating."
		mkdir $TmpDir
	else
		echo "[Info] $TmpDir already exists."
fi

if [ -d $BackupDir ];
	then
		echo "[Info] $BackupDir does not exist. Creating."
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

# Stopping Services
echo "[Stopping Service] Unifi"
systemctl stop unifi
echo "[Stopping Service] mongod"
systemctl stop mongod

echo "I am ready to begin the backup of $UnifiDataDir"
read -e -p "Shall I continue? [Y/n] : " tarStart

if [[ ("$tarStart" == "y" || "$tarStart" == "Y") ]]; 
	then
		# clear
		# take a backup of the data directory
		echo "[Info] Creating a tar.gz backup of $UnifiDataDir to $BackupFile, please wait..."
		START_DATE=$(date)
		echo "[Info] Started tar backup at: $START_DATE"
		tar zcf $BackupFile $UnifiDataDir
		END_DATE=$(date)
		echo "[Info] Ended tar backup at: $END_DATE"
	else
		echo "[FAIL] User to chose halt the process."
		echo "[FAIL] No data has been altered."
		exit 1
fi

# cd to TmpDir and fetch latest installer
cd $TmpDir

if [ -f "$TmpDir/Unifi.unix.zip" ];
	then
		echo "[Notice] $TmpDir/Unifi.unix.zip already exists. Removing."
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

echo "[Notice] I am ready to begin the upgrade of $UnifiDataDir"
echo "[Notice] This is your last chance to cancel prior to any destructive operations."
read -e -p "Shall I continue? [Y/n] : " upgradeStart

if [[ ("$upgradeStart" == "y" || "$upgradeStart" == "Y") ]]; 
	then
		# Unzip the download into place
		echo "Unzipping UniFi.unix.zip"
		unzip -qo UniFi.unix.zip -d /opt
		
		# Untar the backup into place
		echo "Restoring $BackupFile to $UnifiDataDir"
		# tar xzf $BackupFile -C $UnifiDataDir
		tar xzf $BackupFile -C /
		
		# Take ownership of the unzipped dir
		echo "Taking ownership of the updated Unifi directory"
		chown -R ubnt:ubnt /opt/UniFi
	else
		echo "[FAIL] User to chose halt the process."
		echo "[FAIL] No data has been altered."
		exit 1
fi

# Starting Services
echo "[Starting Service] unifi"
systemctl start unifi
echo "[Starting Service] mongod"
systemctl stop mongod

# Complete
echo "Process is completed."
exit 0