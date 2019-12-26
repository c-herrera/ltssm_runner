#!/bin/bash
# File          : ltssmtool_runner
# Purpose       : Run the complete testcase of LTSSM
# Description   : A simple script to run LTSSMtool without missing any argument
#                 
#                 
# Version       : 0.0.1
# Date          : 
# Created by    : Carlos Herrera.
# Notes         : 
#                 
# Scope         : 
#               : Do not remove this header, thanks!

# Fun times on errors!
set +x
# set otherwise for fun !!!

#var setup
address=$1
buswidth=$2
busspeed=$3

#file patterns
sbr_file_name=SBRlog*.txt
flr_file_name=flr.log*.txt
linkDisable_file_name=linkDisablelog.*.txt
linkretrain_file_name=linkRetrainlog.*.txt
pml_file_name=pml1log.*.txt
speedchng_file_name=speedChangeLog.*.txt
txteq_file_name=txEqRedolog.*.txt

#folders and files
localfolder=folder
summaryfile=summary.txt

#Pause function

function remove_old_logs {
	echo "Cleaning past borked attempts (if any) "
	rm $sbr_file_name
	rm $flr_file_name
	rm $linkDisable_file_name
	rm $linkretrain_file_name
	rm $pml_file_name
	rm $speedchng_file_name
	rm $txteq_file_name
}


function pause(){
	echo "Press the Enter key to continue..."
	read -p "$*"
}

function test_header() {
	text=$1
	echo  " $(date +%Y:%m:%d:%H:%M:%S)"
	echo  " Running LTMSS $text with [$address,$buswidth,$busspeed] "
}

function  create_sys_logs {
	echo  " $(date +%Y:%m:%d:%H:%M:%S) " > dmesg-01.txt
	echo  " $(date +%Y:%m:%d:%H:%M:%S) " > dmesg-02.txt
	echo  " $(date +%Y:%m:%d:%H:%M:%S) " > journal.txt
	echo  " $(date +%Y:%m:%d:%H:%M:%S) " > messages.txt
}

function save_logs {
	if [ -x "$(command -v selview)" ]; then 
		selview -f sel_events.sel
	fi 

	echo "Moving files to : $folder "
	dmesg --human --decode --kernel >> dmesg-02.txt
	journalctl >> journal.txt
	cat /var/log/messages >> messages.txt
	if [ -f sel_events.sel ]; then 
		mv *.sel $folder
	fi 
	#save them into $folder
	mv *.txt $folder
}
#it begins :)
clear
echo "This script helps on running LTMSS tool with "
echo "only the required PCI device address"
echo "Before runnging the tool, clear the "
echo "SEL Log events, dmesg or any other log entry"
#clean preovious log files runs (if any)
remove_old_logs
create_sys_logs

dmesg --decode --human >> dmesg-01.txt
echo "Clearing dmesg..."
dmesg --clear
read -p "Enter a folder name to save all the logs, no spaces, no special chars : " folder
mkdir --verbose ./$folder

echo "Running LTSSMTool with the next arguments"
echo "Address   = $1"
echo "Bus width = $2"
echo "Generation= $3"
sleep 2

test_header "pml1 1000" | tee -a $summaryfile

./LTSSMtool pml1 1000 [$address,$buswidth,$busspeed]

test_header "linkretrain 100" | tee -a $summaryfile
./LTSSMtool linkRetrain 100 [$address,$buswidth,$busspeed]

test_header "linkdisable 100" | tee -a $summaryfile 
./LTSSMtool linkDisable 100 [$address,$buswidth,$busspeed]

test_header "speedchange 100" | tee -a $summaryfile 
./LTSSMtool speedChange 100 [$address,$buswidth,$busspeed] -all

test_header "flr 100" | tee -a $summaryfile 
./LTSSMtool flr 100 [$address,$buswidth,$busspeed]

test_header "txEqredo 100" | tee -a $summaryfile 
./LTSSMtool txEqRedo 100 [$address,$buswidth,$busspeed]

test_header "SBR 1000" | tee -a $summaryfile 
./LTSSMtool sbr 1000 [$address,$buswidth,$busspeed]

#gathering info
save_logs

pause
echo "Done."
exit





