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
runCommand=$1
runOption=$2

# Misc Variables
UnifiDataDir=/opt/UniFi/data
BackupDir=/UnifiBackup
BackupFile=$BackupDir/backup$YEAR$MONTH$DOW.tar.gz
TmpDir=/tmp/unifi-updater

# PKG_VER=5.10.25
# PKG_VER=5.11.39
PKG_VER=5.12.22

PKG_URL="https://dl.ubnt.com/unifi/${PKG_VER}/UniFi.unix.zip"

# Command input checks
if [ -z $runCommand ]
	then
		echo "[ERROR] You must specific a run option to proceed."
		echo "Currently supported run options:"
		echo "install"
		echo "upgrade"
		echo "repair (still in developement)"
		exit 1
fi

if [ $runCommand = "install" ]
	then
		if [ -z $runOption ]
			then
				echo "[ERROR] You have chosen to install to a new system however you have not specified a backup file to restore from."
				echo "Usage:"
				echo "$ sudo ./unifi-update.sh install /path/to/backup/file.tar.gz"
				echo ""
				echo "If you want to run a new install without restoring an existing config use:"
				echo "$ sudo ./unifi-update.sh install fresh"
				exit 1
		fi
fi

### Functions Start ###
executeDirSetup() {
	# Create TmpDir
	#mkdir -p /tmp/unifi-updater
	if [ ! -d $TmpDir ];
		then
			echo "[Info] $TmpDir does not exist. Creating."
			mkdir -p $TmpDir
		else
			echo "[Info] $TmpDir already exists."
	fi

	if [ ! -d $BackupDir ];
		then
			echo "[Info] $BackupDir does not exist. Creating."
			mkdir -p $BackupDir
		else
			echo "[Info] $BackupDir already exists."
	fi
}

# Check if existing backup file exists
executeChkBackupFile() {
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
					echo "[Info] User to chose to keep old backup."
					mv $BackupFile $BackupFile.bak
			fi

		else
			echo "[Info] No backup files found. Proceeding."
	fi
}

executeTarStart() {
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
}

executeExistingInstallerCheck () {
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
}

executeInstallerFetch () {
	echo "[Fetching] $PKG_URL"
	#wget https://dl.ubnt.com/unifi/${PKG_VER}/UniFi.unix.zip
	wget $PKG_URL
}

executeServicesStop() {
	# Stopping Services
	echo "[Stopping Service] Unifi"
	systemctl stop unifi
	echo "[Stopping Service] mongod"
	systemctl stop mongod
}

executeServicesStart () {
	# Starting Services
	echo "[Starting Service] unifi"
	systemctl start unifi
	echo "[Starting Service] mongod"
	systemctl stop mongod
}

executeUpgrade () {
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
}

executeInstall () {
	echo "[Notice] I am ready to begin a fresh installation of Unifi $PKG_VER"
	echo "[Notice] This is your last chance to cancel prior to any destructive operations."
	read -e -p "Shall I continue? [Y/n] : " installStart

	if [[ ("$installStart" == "y" || "$installStart" == "Y") ]]; 
		then
			# Unzip the download into place
			echo "[Install] Unzipping UniFi.unix.zip"
			unzip -qo UniFi.unix.zip -d /opt
			
			# # Untar the backup into place
			# echo "[Install] Restoring $BackupFile to $UnifiDataDir"
			# # tar xzf $BackupFile -C $UnifiDataDir
			# tar xzf $BackupFile -C /
			
			# Take ownership of the unzipped dir
			echo "[Install] Taking ownership of the updated Unifi directory"
			chown -R ubnt:ubnt /opt/UniFi
		else
			echo "[FAIL] User to chose halt the process."
			echo "[FAIL] No data has been altered."
			exit 1
	fi
}



##############################
## Start of the actual work ##
##############################

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

# New install
if [[ ("$runCommand" == "install") ]];
	then

		executeServicesStop
		executeDirSetup

		cd $TmpDir

		executeInstallerFetch
		executeInstall
		executeServicesStart
fi

# Upgrade existing system
if [[ ("$runCommand" == "upgrade") ]];
	then
		executeServicesStop
		executeDirSetup
		
		cd $TmpDir
		
		executeChkBackupFile		
		executeTarStart
		executeExistingInstallerCheck
		executeUpgrade
fi

##############################
### End of the actual work ###
##############################


# Complete
echo "Process is completed."
exit 0