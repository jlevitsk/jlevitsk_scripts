#!/bin/csh

###############
# 
# This app will fix VPN addresses on Macs 
# Created by Joshua Levitsky <jlevitsk@joshie.com>
# Revision 2010100601
#
##################

set ID="/usr/bin/id"
set WHOAMI=`$ID|sed -e 's/(.*//'`

if ( "$WHOAMI" != "uid=0" ) then
	echo "Sorry, you need super user access to run this script."
	exit 1
endif


cd /private/etc/opt/cisco-vpnclient/Profiles/
# For each subdirectory, we're going to to do something.
foreach d ( * )
  # If this isn't the shared directory, it's a user directory, so
  # we need to eliminate Internet cache files from it.
	echo Fixing VPN Profiles in $d...

	sed s/64.236.246.210/nycvpn.timeinc.com/g  /private/etc/opt/cisco-vpnclient/Profiles/$d > /private/etc/opt/cisco-vpnclient/Profiles/$d.1
	sed s/64.236.226.14/tmpvpn.timeinc.com/g  /private/etc/opt/cisco-vpnclient/Profiles/$d.1 > /private/etc/opt/cisco-vpnclient/Profiles/$d.2
	sed s/64.236.227.160/lonvpn.timeinc.com/g  /private/etc/opt/cisco-vpnclient/Profiles/$d.2 > /private/etc/opt/cisco-vpnclient/Profiles/$d.3
	sed s/64.236.80.138/lonvpn.timeinc.com/g  /private/etc/opt/cisco-vpnclient/Profiles/$d.3 > /private/etc/opt/cisco-vpnclient/Profiles/$d.4
	sed s/202.130.154.118/hkvpn.timeinc.com/g  /private/etc/opt/cisco-vpnclient/Profiles/$d.4 > /private/etc/opt/cisco-vpnclient/Profiles/$d.5
	
		
	rm /private/etc/opt/cisco-vpnclient/Profiles/$d
	rm /private/etc/opt/cisco-vpnclient/Profiles/$d.1
	rm /private/etc/opt/cisco-vpnclient/Profiles/$d.2
	rm /private/etc/opt/cisco-vpnclient/Profiles/$d.3
	rm /private/etc/opt/cisco-vpnclient/Profiles/$d.4
	mv /private/etc/opt/cisco-vpnclient/Profiles/$d.5 /private/etc/opt/cisco-vpnclient/Profiles/$d
	chmod 666 /private/etc/opt/cisco-vpnclient/Profiles/$d


	echo Finished with VPN code on $d...
		
end


echo Exiting script

exit

