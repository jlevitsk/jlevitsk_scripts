#!/bin/sh

################
#
# Joshies Nav Updater
# josh@joshie.com
# 2005050101
#
#################

################################################################################
# Change these
#
basenm=`basename $0`
logger="/usr/bin/logger -i -t $basenm"

$logger "Started."
$logger "Testing age of liveupdt.log file..."
count=`find "/Library/Application Support/Symantec/LiveUpdate/" -name liveupdt.log -a -mtime -3 -print | wc -l` > /dev/null
if [ $count -eq 1 ]
then
 	$logger "The file is under 3 days... ending check..."
	exit 0
fi


$logger "Sleeping for a min before checking ethernet"
sleep 60

en0status=`ifconfig en0 | /usr/bin/awk '/status: active/ {print $1}'`
en1status=`ifconfig en1 | /usr/bin/awk '/status: active/ {print $1}'`

if [ $en0status ] || [ $en1status ]; then
	# This will test for reliable connectivity for 10 minutes more or less
	N=0
	while [ "$N" -le "60" ] && [ "$network" != "Reachable" ]; do
		N=$[N+1]
		network=`/usr/sbin/scutil -r liveupdate.mycompany.com`
		sleep 10
	done

	if [ $N -gt "59" ] ; then
		$logger "LU: en0 or en1 was active but there was not a reliable connection. Aborting."
		exit 1
	fi

	$logger "Connection found..."
	if [ -f "/Applications/Symantec Solutions/LiveUpdate.app/Contents/MacOS/Liveupdate" ]
	then
		$logger "LiveUpdating Silently"
		"/Applications/Symantec Solutions/LiveUpdate.app/Contents/MacOS/LiveUpdate" -liveupdateautoquit YES -update LUal -liveupdatequiet YES
		$logger "LiveUpdating Completed"
	else
		$logger "LiveUpdate is missing!"
		osascript -e 'tell app "Finder" to activate' -e 'tell app "Finder" to display dialog "ALERT: Please contact the Service Desk at (212) 522-7777. Your AntiVirus software needs repair. LiveUpdate could not be found in the expected location."'
	fi
	$logger "Terminating Normally"
	exit 0
fi

$logger "There was no connection available to liveupdate.mycompany.com"
exit 0
