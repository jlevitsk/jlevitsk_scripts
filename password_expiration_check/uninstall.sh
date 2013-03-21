#!/bin/sh

if [ -f /usr/bin/adinfo ]; then
        if [ -f /Library/LaunchAgents/com.timeinc.passwd_check.plist ]; then
                echo removing password check
                rm -f /Library/LaunchAgents/com.timeinc.passwd_check.plist
                rm -f /Library/Management/password_expire_check.sh
                rm -f /Library/Management/Archive/password_expire_check_ORIG.sh
                pkgutil --forget com.timeinc.pkg.password_expire_check.passwordExpireCheckTi.Archive.pkg
        else
        echo password already removed
        exit 0
        fi
        exit 0
else
	echo Centrify not installed
          exit 0
fi

exit 0