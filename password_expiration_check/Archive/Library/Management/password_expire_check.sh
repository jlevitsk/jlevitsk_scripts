#!/bin/sh
#############################
#
# Password expiration check for AD
# By Armando Rivera, Gary Lou from a script by Peter Bukowinski <pmbuko@gmail.com>
# Converted from AppleScript to shell script by Joshua Levitsky <jlevitsk@joshie.com>
# July 23, 2010
#
#############################

# Life of an AD password in days
PswdMaxAge=90

# Days at which we warn a password will expire
warningDays=10

# Base DN to search in AD for accounts
# This only matters if you are searching AD for expiration info
mySearchBase="DC=corp,DC=ad,DC=mycompany,DC=com"

# AD Server to query that accounts live in
# This only matters if you are searching AD for expiration info
myDomain="corp.ad.mycompany.com"

# Set to 0 if you get kerberos errors despite a valid ticket
kerbCheck=0

# Set to 0 to disable debug dialogs. 1 is useful for testing
debugDialogs=0

# Get the value of 'a' in "Mac OS X 10.a.b"
# 10.5 returns a 5 and 10.6 a 6. This script won't work on 10.4 or lower
osVersion=`system_profiler SPSoftwareDataType | awk -F. '/System Version/ {print $2}'`


############ FUNCTIONS ###############

function EnableUIScriptingChk {
if [ -f "/private/var/db/.AccessibilityAPIEnabled" ]; then
	echo "Password Expire Checker: GUI Scripting is enabled."
else
	echo "Password Expire Checker: GUI Scripting is disabled. Notify and exit."
	/usr/bin/osascript <<-EOF
tell application "System Events" to set isUIScriptingEnabled to UI elements enabled
if isUIScriptingEnabled = false then
   tell application "System Preferences"
      activate
      set current pane to pane "com.apple.preference.universalaccess"
      display dialog "Your system is not properly configured to run this script\n\nselect the \"Enable access for assistive devices\" checkbox and run again."
      return
   end tell
end if
EOF
	exit
fi
		}
		
function ChangePassFunc {
	/usr/bin/osascript <<-EOF
tell application "System Preferences"
	try -- to use UI scripting
		set current pane to pane "Accounts"
		tell application "System Events"
			tell application process "System Preferences"
				click button "Change Password…" of tab group 1 of window "Accounts"
			end tell
		end tell
	end try
	activate
end tell
EOF
           }

function CheckNagTimeFunc {
	# Check if we have done this today already. Too annoying to prompt every hour.
	# Every 18 hours we want to nag them. This function is only used for the daily nags leading up to full expiration.
	count=`find "/Users/$USER/Library/Logs/" -name TI_Password_Check.log -a -mmin -1080 -print | wc -l` > /dev/null
	if [ $count -eq 1 ]
	then
		echo "Password Expire Checker: We appear to have nagged them once already today. Exiting."
		exit
	fi

	echo "Password Expire Checker: We ran over 1080 Minutes ago. Begin Nagging."

	# Let's recreate the status file so we know we ran.
	/bin/rm -f "/Users/$USER/Library/Logs/TI_Password_Check.log"
	/usr/bin/touch "/Users/$USER/Library/Logs/TI_Password_Check.log"

			}

############ MAIN SCRIPT #############

# Exit if less than 10.5
if [ "$osVersion" -lt "5" ]; then
	echo "Password Expire Checker: This will not work on anything less than 10.5"
	exit
fi

# Run the check for UI Scripting
# This has a negative that the Sys Prefs icon will bounce once a day when this runs.
EnableUIScriptingChk

echo "Password Expire Checker: UI Check done"

echo "Password Expire Checker: Testing for 20 minutes to see if we can hit AD."

# This will test for reliable connectivity for 20 minutes more or less
N=0
while [ "$N" -le "60" ] && [ "$network" != "Reachable" ] && [ "$network" != "Reachable,Transient Connection" ]; do
		N=$[N+1]                
		network=`/usr/sbin/scutil -r $myDomain`
		echo "Password Expire Checker: Domain status is - "$network
		sleep 20
done

if [ $N -gt "59" ] ; then                
	echo "Password Expire Checker: We waited 20 minutes and are unable to reach AD."
	echo "Password Expire Checker: Exiting."
	exit
fi

echo "Password Expire Checker: We can reach the AD. We need to sleep 2 min to be sure we can get expiration info."
sleep 120


# Check for active kerberos ticket. We know we can reach the domain.
# Users who VPN in might not have a ticket for some time so let's loop for a while.
# Really only needed if running script manually or on a schedule.
# This shouldn't really be needed so we default to off.
if [ "$kerbCheck" -eq "1" ]; then
	N=0
	kerbOK=0
	while [ "$N" -le "60" ] && [ "$kerbOK" != "1" ]; do
		kerbStatus=$(/usr/bin/klist 2>&1)
		echo "Password Expire checker: Kerberos Status - "$kerbStatus
		kerbStatus=`echo $kerbStatus | grep "Kerberos 5 ticket cache" `
		if [ "$kerbStatus" ]; then
			kerbOK=1
		else
			sleep 20
		fi
	done

	echo "Password Expire Checker: kerbCheck done"
fi

# Get the date the password was last set, with NT-->UNIX date conversion
# need to take the above value and do the below math... to go NT-->UNIX
PswdLastChg=`/usr/bin/dscl /Search -read /Users/$USER | /usr/bin/grep pwdLastSet | awk '{ print $2 }'`

if [ "$PswdLastChg" = "" ]; then
	echo "Password Expire Checker: We don't seem to have a password last set. Exiting."
	exit
fi

PswdLastChgSecs=$(($PswdLastChg/10000000-11644473600))

# Time now in Unix secs
TodaySecs=`date +%s`

# I'm not using this because I know everyone is 90 day expire and I don't want to make extra traffic to DC's.
# Max age password is allowed to be according to directory root policy
#PswdMaxAge=`ldapsearch -LLL -Q -s base -H ldap://$myDomain "-b" "$mySearchBase" | grep maxPwdAge | awk -F - '{ print $2}'`
#PswdMaxAgeSecs=`expr $PswdMaxAge / 10000000`

# Take the expire max in days to seconds. Max Age defined in days at top of script
PswdMaxAgeSecs=$(($PswdMaxAge*86400))

# Calculate how close to expiration we are in seconds
SecsTilChange=$(($PswdMaxAgeSecs-$TodaySecs+$PswdLastChgSecs))

# Take the seconds out to how many days we have.
DaysTilChange=$(($SecsTilChange/86400))

if [ "$debugDialogs" -eq "1" ]; then
	echo "Password Expire Checker: Debug Info Follows"
	echo "PswdMaxAge "$PswdMaxAge
	echo "PswdMaxAgeSecs "$PswdMaxAgeSecs
	echo "SecsTilChange "$SecsTilChange
	echo "TodaySecs "$TodaySecs
	echo "PswdLastChg "$PswdLastChg
	echo "PswdLastChgSecs "$PswdLastChgSecs
fi

# You can fake things for testing by enabling the next line.
#DaysTilChange=2

echo "Password Expire Checker: Days Left "$DaysTilChange

# if days left is greater than the 10 days warning then it will just display how many days are left. 
# This will only show if debutDialogs is enabled. 
if [ "$DaysTilChange" -gt "$warningDays" ] && [ "$debugDialogs" -eq "1" ]; then
#	CheckNagTimeFunc
	/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog ok-msgbox --text "Password Expired" \
    --informative-text "Debug Message: Your computer and email password will expire in $DaysTilChange day(s)." \
    --no-cancel --no-newline --float
fi	
	
if [ "$DaysTilChange" -lt "$warningDays" ] && [ "$DaysTilChange" -gt "1" ]; then
	CheckNagTimeFunc
	promptAnswer=`/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog yesno-msgbox --text "Password Expired" \
    --informative-text "Your computer and email password will expire in $DaysTilChange days. If you would like you change your password now please click Yes." \
    --no-cancel --no-newline --float`
	if [ "$promptAnswer" == "1" ]; then
		echo "Password Expire Checker: User is changing their expiring password."
		ChangePassFunc
	elif [ "$promptAnswer" == "2" ]; then
		echo "Password Expire Checker: Touching the log so they don't get an immediate nag after this."
		/usr/bin/touch "/Users/$USER/Library/Logs/TI_Password_Check.log"
		echo "Password Expire Checker: User does not want to change their expiring password."
	fi
fi
	
	
# if days left expired or = 0 then it will prompt to change the password. 
# Really if it's 1 day or less I consider it expired because if we are really fully expired the screensaver can't be unlocked.
# I want to save the users from that.
if [ "$DaysTilChange" -lt "$warningDays" ] && [ "$DaysTilChange" -lt "2" ]; then
	/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog ok-msgbox --text "Password Expired" \
    --informative-text "Your computer and email password has expired. When you click OK you will be taken to a form to update your password." \
    --no-cancel --no-newline --float
	echo "Password Expire Checker: User is changing their expiring password."
	ChangePassFunc
fi	


echo "Password Expire Checker: All Done."

exit
