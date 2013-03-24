#!/bin/csh

###############
# 
# This app will fix homepages and bookmarks from www.mycompany.com to www.mycompanyNEWSITE.com 
# default user profiles as well. 
# Created by Joshua Levitsky <jlevitsk@joshie.com>
# Revision 2007090701
#
##################

set ID="/usr/bin/id"
set WHOAMI=`$ID|sed -e 's/(.*//'`

if ( "$WHOAMI" != "uid=0" ) then
	echo "Sorry, you need super user access to run this script."
	exit 1
endif


cd /Users
#echo -------------------------
#echo This is the list of user accts:
#ls -l
#echo -------------------------

# For each subdirectory, we're going to to do something.
foreach d ( * )
  # If this isn't the shared directory, it's a user directory, so
  # we need to eliminate Internet cache files from it.
  if ($d != "Shared") then
     echo Fixing Safari homepage for $d...
	 if ( -f /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist ) then
		#echo --------- BEGIN DIAGS for $d -----------
		#echo Diagnostic output: before changes
		#ls -l /Users/$d/Library/Preferences/ | grep "com.apple.internet"
		#ls -l /Users/$d/Library/Safari/
		#echo --------- END DIAGS for $d -------------

		echo Using Tiger / Leopard homepage code on $d...
		cp -f /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist.bak 
		plutil -convert xml1 /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist.bak
		unlink /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist
		sed s/www.mycompany.com/www.mycompanyNEWSITE.com/g  /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist.bak > /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist
		chown $d /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist
		chmod 600 /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist
		unlink /Users/$d/Library/Preferences/com.apple.internetconfigpriv.plist.bak
		echo Finished with Tiger / Leopard homepage code on $d...
		
		if ( -f /Users/$d/Library/Safari/Bookmarks.plist ) then
			echo Using Tiger / Leopard bookmark cleanup code on $d...
			cp -f /Users/$d/Library/Safari/Bookmarks.plist /Users/$d/Library/Safari/Bookmarks.plist.bak
			plutil -convert xml1 /Users/$d/Library/Safari/Bookmarks.plist.bak
			unlink /Users/$d/Library/Safari/Bookmarks.plist
			sed s/www.mycompany.com/www.mycompanyNEWSITE.com/g /Users/$d/Library/Safari/Bookmarks.plist.bak > /Users/$d/Library/Safari/Bookmarks.plist
			chown $d /Users/$d/Library/Safari/Bookmarks.plist
			chmod 600 /Users/$d/Library/Safari/Bookmarks.plist
			unlink /Users/$d/Library/Safari/Bookmarks.plist.bak
			echo Finished with Tiger / Leopard bookmark cleanup code on $d...
		endif
		
		#echo --------- BEGIN DIAGS for $d -----------
		#echo Diagnostic output: after changes
		#ls -l /Users/$d/Library/Preferences/ | grep "com.apple.internet"
		#ls -l /Users/$d/Library/Safari/
		#echo --------- END DIAGS for $d -------------
	 else
		#echo --------- BEGIN DIAGS for $d -----------
		#echo Diagnostic output: before changes
		#ls -l /Users/$d/Library/Preferences/ | grep "com.apple.internet"
		#ls -l /Users/$d/Library/Safari/
		#echo --------- END DIAGS for $d -------------

		echo Using Panther homepage code on $d...
		cp -f /Users/$d/Library/Preferences/com.apple.internetconfig.plist /Users/$d/Library/Preferences/com.apple.internetconfig.plist.bak
		plutil -convert xml1 /Users/$d/Library/Preferences/com.apple.internetconfig.plist.bak
		rm -f /Users/$d/Library/Preferences/com.apple.internetconfig.plist
        sed s/www.mycompany.com/www.mycompanyNEWSITE.com/g  /Users/$d/Library/Preferences/com.apple.internetconfig.plist.bak > /Users/$d/Library/Preferences/com.apple.internetconfig.plist
		chown $d /Users/$d/Library/Preferences/com.apple.internetconfig.plist
		chmod 600 /Users/$d/Library/Preferences/com.apple.internetconfig.plist
        rm -f /Users/$d/Library/Preferences/com.apple.internetconfig.plist.bak
		echo Finished with Panther homepage code on $d...

		if ( -f /Users/$d/Library/Safari/Bookmarks.plist ) then
			echo Using Panther bookmark cleanup code on $d...
			cp -f /Users/$d/Library/Safari/Bookmarks.plist /Users/$d/Library/Safari/Bookmarks.plist.bak
			plutil -convert xml1 /Users/$d/Library/Safari/Bookmarks.plist.bak
			rm -f /Users/$d/Library/Safari/Bookmarks.plist
			sed s/www.mycompany.com/www.mycompanyNEWSITE.com/g /Users/$d/Library/Safari/Bookmarks.plist.bak > /Users/$d/Library/Safari/Bookmarks.plist
			chown $d /Users/$d/Library/Safari/Bookmarks.plist
			chmod 600 /Users/$d/Library/Safari/Bookmarks.plist
			rm -f /Users/$d/Library/Safari/Bookmarks.plist.bak
			echo Finished with Panther bookmark cleanup code on $d...
		endif
		
		#echo --------- BEGIN DIAGS for $d -----------
		#echo Diagnostic output: after changes
		#ls -l /Users/$d/Library/Preferences/ | grep "com.apple.internet"
		#ls -l /Users/$d/Library/Safari/
		#echo --------- END DIAGS for $d -------------
	endif
endif
end


#echo --------- BEGIN DIAGS for default -----------
#echo Diagnostic output: before changes
#ls -l /System/Library/User\ Template/English.lproj/Library/Preferences/ | grep "com.apple.internet"
#echo --------- END DIAGS for default -------------
		
echo Updating homepage for Default User template
mv /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist.bak
sed s/www.mycompany.com/www.mycompanyNEWSITE.com/g /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist.bak > /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist
chmod 664 /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist
rm -f /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.internetconfig.plist.bak
echo Finished updating homepage for Default User template

#echo --------- BEGIN DIAGS for default -----------
#echo Diagnostic output: after changes
#ls -l /System/Library/User\ Template/English.lproj/Library/Preferences/ | grep "com.apple.internet"
#echo --------- END DIAGS for default -------------


echo Exiting script

exit

