#!/bin/bash

# Backs up the current topology
#
# This will stop/start the ASM server
#
# 4/4/20 - Jason Cress

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

read -p "This script will stop ASM and back up the current topology, and restart ASM. Continue? ([y]es/[n]o/[c]ancel)" YESNO
case $YESNO in
	[Yy]* )
		echo "Stopping ASM" 
		$ASM_HOME/bin/asm_stop.sh
		CURRDATE=`date |sed s/[\ \:]/-/g`
		echo "Backing up the ASM topology to file $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar"
		tar -cpf $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar -C $ASM_HOME data
		tar -upf $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar -C $ASM_HOME logs
		gzip $ASM_HOME/cleantopology/backups/ASMBACKUP$CURRDATE.tar
		echo "Restarting ASM"
		$ASM_HOME/bin/asm_start.sh
		# Sleep for 30 seconds to allow ASM to start
                ;;
	* )
		echo "Cancelling install"
		exit
		;;
	esac

