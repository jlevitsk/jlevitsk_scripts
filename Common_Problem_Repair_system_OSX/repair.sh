#!/bin/sh
##########################################################
#
# Common Problem Repair System (CPRs)
# A simple creation by Josh Levitsky <josh@joshie.com>
# Feel free to take my ideas and use them if they work.
# You need to reboot after this script because you will be unstable
# This is ONLY for 10.7 and beyond
#
##########################################################


kickstart="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
systemsetup="/usr/sbin/systemsetup"
networksetup="/usr/sbin/networksetup"
scutil="/usr/sbin/scutil"
diskutil="/usr/sbin/diskutil"
macModel=`system_profiler SPHardwareDataType | grep "Model Name:" | awk '{ print $3 }'`
OS=`/usr/bin/defaults read /System/Library/CoreServices/SystemVersion ProductVersion | awk '{print substr($1,1,4)}'`

echo "Starting Repair"

###########################
#
# Set expectations
#
###########################
#

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog ok-msgbox --title "Common System Problem Repair Tool" \
    --informative-text "This tool will try to fix common problems that usually require a technician to fix. This tool may or may not solve your problem, but we are hopeful that it will make your machine work better. More complex issues will still require Desktop Support. 
	
Please contact Desktop Support via the Service Desk if you have any issues with this process." \
    --no-cancel --no-newline --timeout 30 --float --icon "computer"

###########################
#
# Create progress window
#
###########################
#
# create a named pipe
rm -f /tmp/hpipe
mkfifo /tmp/hpipe

#start a barber poll
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog progressbar \
	--indeterminate --title "Common System Problem Repair Tool" \
	--text "Please wait a few minutes..." < /tmp/hpipe &

# associate file descriptor 3 with that pipe and send a character through the pipe
exec 3<> /tmp/hpipe
echo -n . >&3


###########################
#
# Fix settings that might be wrong
#
###########################
#

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Fixing System Settings" &

# Disable external accounts (i.e. accounts stored on drives other than the boot drive.)
defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false

# Don't show nearby computers
/usr/libexec/PlistBuddy -c "Add :networkbrowser dict" "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.sidebarlists.plist"
/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties dict" "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.sidebarlists.plist"
/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled bool false" "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.sidebarlists.plist"
/usr/libexec/PlistBuddy -c "Set :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled false" "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.sidebarlists.plist"

# make FireWire networking inactive
$networksetup -setnetworkserviceenabled FireWire off

# add current logged in user to _lpadmin at log in 
dscl . append /Groups/_lpadmin GroupMembership $USER 

# Enable access for assistive devices
echo -n 'a' | sudo tee /private/var/db/.AccessibilityAPIEnabled > /dev/null 2>&1
chmod 444 /private/var/db/.AccessibilityAPIEnabled

# Put Centrify back in licensed mode for GPOs
/usr/bin/adlicense -l

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Resetting Power Management" &
# Start up automatically after a power failure
/usr/bin/pmset -a autorestart 1
# Restart automatically if the computer freezes
/usr/bin/pmset -a panicrestart 15
# Wake for network access
/usr/bin/pmset -a womp 1
# Wake from tty activity
/usr/bin/pmset -a ttyskeepawake 1

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Fixing SSH" &
# enable SSH
/usr/sbin/systemsetup -setremotelogin on
/usr/sbin/dseditgroup -o create -q com.apple.access_ssh
/usr/sbin/dseditgroup -o edit -a timeadmin -t user com.apple.access_ssh
/usr/sbin/dseditgroup -o edit -a dsgadministrator -t user com.apple.access_ssh

# Hide DSGAdmin from the login window. Nobody needs to see it.
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array dsgadministrator
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES

# Fixes if AD isn't immediately available
/usr/libexec/PlistBuddy -c 'Add :StartupDelay integer 20' /Library/Preferences/com.apple.loginwindow.plist
/usr/libexec/PlistBuddy -c 'Add :StartupDelay integer 20' /private/var/root/Library/Preferences/com.apple.loginwindow.plist

#fix user account permissions
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Fixing Home Permissions" &
chmod -R –N $HOME
chown -R $USER $HOME

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Fixing User Settings" &
# Disable Adobe Reader Updates
for a in `ls /Users | grep -v "^\." | grep -v "Shared"`
do
        /usr/libexec/PlistBuddy -c "Set :10:AVGeneral:CheckForUpdatesAtStartup:1 false" /Users/$a/Library/Preferences/com.adobe.Reader.plist
done

# Let's walk the accounts and default prefs and set some junk
for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
    then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
      then
        mkdir -p "${USER_HOME}"/Library/Preferences
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ -d "${USER_HOME}"/Library/Preferences ]
      then
      	defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string "Always"
      	defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences NSNavPanelExpandedStateForSaveMode -bool true
      	defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences PMPrintingExpandedStateForPrint -bool true
      	defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences NSDocumentSaveNewDocumentsToCloud -bool false
      	defaults write "${USER_HOME}"/Library/Preferences/com.apple.print.PrintingPrefs "Quit When Finished" -bool true
      	defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
      	defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowRemovableMediaOnDesktop -bool true
      	# When performing a search, search the current folder by default
      	defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder FXDefaultSearchScope -string "SCcf"
      	defaults write "${USER_HOME}"/Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
      fi
    fi
  done

# Fixing authorizations
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Unlocking Privileges" &
# Unlock System Preferences for non admins.
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences:group everyone' /etc/authorization
# Unlock Accessibiltity preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.accessibility:group everyone' /etc/authorization
# Unlock Date and Time
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.datetime:group everyone' /etc/authorization
# Unlock Energy Saver preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.energysaver:group everyone' /etc/authorization
# Unlock Network Settings preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.network:group everyone' /etc/authorization
# Unlock Print & Scan Preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.printing:group everyone' /etc/authorization
# Unlock Startup Disk Preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.startupdisk:group everyone' /etc/authorization
# Unlock Time Machine preference pane
/usr/libexec/PlistBuddy -c 'Set :rights:system.preferences.timemachine:group everyone' /etc/authorization
echo "Given rights to the everyone group to unlock secure system preferences for OS $OS..."
# Make it so anyone can unlock the screensaver
/usr/libexec/PlistBuddy -c "Set :rights:system.login.screensaver:comment \"(Use SecurityAgent.) The owner or any administrator can unlock the screensaver.\"" /etc/authorization
# Allow user to set DVD region once upon first insertion of disc
/usr/libexec/PlistBuddy -c "Set :rights:system.device.dvd.setregion.initial:class allow" "$3"/etc/authorization
# Allow user to change time zone, as documented: http://support.apple.com/kb/TA23576
/usr/libexec/PlistBuddy -c "Add :rights:system.preferences.dateandtime.changetimezone dict" "$3"/etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.preferences.dateandtime.changetimezone:class string allow" "$3"/etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.preferences.dateandtime.changetimezone:comment string 'This right is used by DateAndTime preference to allow any user to change the system timezone.'" "$3"/etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.preferences.dateandtime.changetimezone:shared bool true" "$3"/etc/authorization
echo "Unlocking region code setting using OS $OS..."
/usr/libexec/PlistBuddy -c "Set :rights:system.device.dvd.setregion.initial:class allow" /etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.device.dvd.setregion.change:class string allow" /etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.device.dvd.setregion.change:comment string “Allows any user to change the DVD region code after it has been set the first time.”" /etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.device.dvd.setregion.change:group string user" /etc/authorization
/usr/libexec/PlistBuddy -c "Add :rights:system.device.dvd.setregion.change:shared bool true" /etc/authorization

###########################
#
# Reset Safari
#
###########################
#

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Resetting Safari" &
rm -r "$HOME"/Library/Cookies/

###########################
#
# Fix core OS things that could be messed up
#
###########################
#

# update the caches
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Updating Shared Cache" &
/usr/bin/update_dyld_shared_cache

# Repairing permissions
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Repairing Permissions" &
echo "Repairing Disk Permissions"
/usr/sbin/diskutil repairPermissions /

# fix spotlight
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Fixing Spotlight" &
# disable indexing of the root volume
mdutil -i off
echo "Indexing has been disabled"
# delete the Spotlight index
rm -R /.Spotlight-v100
echo "Index file has been deleted"
# reset the data cache for your Mac’s hard drive:
mdutil -E /
echo "Data cache has been deleted"
#re-indexing your hard drive
mdutil -i on /
echo "Re-indexing your hard drive"

# Software Updates
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Installing OS Updates" &
/usr/sbin/softwareupdate -i -r

#flushing font caches
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Flushing Font Cache" &
atsutil databases -remove
atsutil server -shutdown
sleep 5
atsutil server -ping

# memory test
#/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Testing RAM" &

# Mac Maint scripts
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Running Maintenance" &
/usr/sbin/periodic daily
/usr/sbin/periodic weekly
/usr/sbin/periodic monthly

# Delete caches
/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Deleting System Caches" &
/bin/rm -r "$HOME/Library/Caches/"
/bin/rm -r /Library/Caches/
/bin/rm -r /System/Library/Caches/
/bin/rm -r /private/var/root/Library/Caches/

###########################
#
# Finished
#
###########################
#

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog bubble --title "Repair Status" --icon "hazard" --text "Repair Completed" &

echo "All Done"

# now turn off the progress bar by closing file descriptor 3
exec 3>&-

# wait for all background jobs to exit
wait
rm -f /tmp/hpipe

/Library/Management/CocoaDialog.app/Contents/MacOS/CocoaDialog ok-msgbox --title "Completed" \
    --informative-text "The system has completed the repair process. The system will restart in a few minutes. Please do not attempt to launch any applications." \
    --timeout 60 --no-cancel --no-newline --float --icon "computer"

sync

/sbin/reboot &

exit 0
