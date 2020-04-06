#!/bin/bash

# Resets the ASM topology to a blank slate
# Backs up the current topology
#
# 4/3/20 - Jason Cress

#Verify ASM_HOME is set and this script directory exists
if [ -z "$ASM_HOME" ] 
then
	echo "ASM_HOME is not set. Please ensure that your ASM environment is configured properly."
	exit 1
fi

if [ ! -d "$ASM_HOME/cleantopology/workingdir" ]
then
	echo "Unable to find this script's working directory $ASM_HOME/cleantopology/workingdir. Ensure it is installed properly."
	exit 1  
fi

if [ ! -f "$ASM_HOME/cleantopology/pristine/data-pristine.tar" ] 
then
	echo "Unable to find pristine data file ($ASM_HOME/cleantopology/data-pristine.tar"
	exit 1
fi

if [ ! -f "$ASM_HOME/cleantopology/pristine/logs-pristine.tar" ] 
then
	echo "Unable to find pristine logs file ($ASM_HOME/cleantopology/logs-pristine.tar"
	exit 1
fi

echo "WARNING: This script WILL STOP ASM and CLEAR the ASM topology, resetting to a pristine state"
echo "Are you sure you wish to proceed? (enter \"I am sure\" to proceed)"
read confirm 
if [ "$confirm" != "I am sure" ]
then
  echo "Exiting..."
  exit 1 
fi
echo "Continuing..."
while true; do
	read -p "Do you wish to maintain custom UI configurations e.g. tools or icons in the pristine topology? ([y]es/[n]o/[c]ancel)" YESNO
	case $YESNO in
		[Yy]* ) 
			echo "Saving UI customizations" 
			savetools="Y"
			$ASM_HOME/bin/backup_ui_config.sh -force -out ui_customizations.out
			cp $ASM_HOME/data/tools/ui_customizations.out $ASM_HOME/cleantopology/workingdir
			break
		;; 
		[Nn]* ) 
			echo "Discarding UI customizations" 
			savetools="N"
			break
		;; 
		[Cc]* ) 
			echo "Cancelling install"
			exit
		;;
		* ) 
			echo "Please answer y, n, or c"
		;;
	esac
done
YESNO=""
read -p "Preparing to stop ASM, back up the existing topology, reset the topology, and restart ASM. Do you wish to continue? ([y]es/[n]o/[c]ancel)" YESNO
case $YESNO in
	[Yy]* )
		echo "Stopping ASM" 
		$ASM_HOME/bin/asm_stop.sh
		CURRDATE=`date |sed s/[\ \:]/-/g`
		echo "Backing up the ASM topology to file $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar"
		tar -cpf $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar -C $ASM_HOME data
		tar -upf $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar -C $ASM_HOME logs
		gzip $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar
		echo "Resetting the topology to pristine"
		sudo rm -rf $ASM_HOME/data
		sudo rm -rf $ASM_HOME/logs
		sudo tar --same-owner -xf $ASM_HOME/cleantopology/pristine/data-pristine.tar --directory $ASM_HOME/
		sudo tar --same-owner -xf $ASM_HOME/cleantopology/pristine/logs-pristine.tar --directory $ASM_HOME/
		echo "Restarting ASM"
		$ASM_HOME/bin/asm_start.sh
		# Sleep for 30 seconds to allow ASM to start
		sleep 60
		if [ "$savetools" = "Y" ]
		then
			echo "Restoring UI customizations"
			cp $ASM_HOME/cleantopology/workingdir/ui_customizations.out $ASM_HOME/data/tools/asm_ui_config.txt
			$ASM_HOME/bin/import_ui_config.sh -file asm_ui_config.txt
			mv $ASM_HOME/cleantopology/workingdir/ui_customizations.out $ASM_HOME/cleantopology/workingdir/ui_customizations-$CURRDATE.out
		fi
                ;;
	* )
		echo "Cancelling install"
		exit
		;;
	esac

