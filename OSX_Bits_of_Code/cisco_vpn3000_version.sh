#!/bin/bash

if [ -f "/Applications/VPNClient.app/Contents/Info.plist" ]; then
    defaults read /Applications/VPNClient.app/Contents/Info CFBundleShortVersionString
else
	echo "0"
fi
exit 0
