This script gets built in to a package that puts CocoaDialog in to /Library/Management/ and then executes repair.sh on the machine. At the tail end the package actually reboots the machine. 

The idea of this script is that you would load it in to Casper or Absolute Manage as an On Demand package. A user could run it before calling desktop support and in many many cases it would repair the issue at hand. So many times we bang our heads against the wall trying to fix a machine when it turns out the problem was something silly like a corrupt Cache file or a permissions issue. You can also just run this PKG by itself without a system management product like Casper or Absolute, but the real benefit is employee self-help and empowering your employees to help themselves so they don't need to call you up at 3am for something silly. 

Please let me know if you have any feedback at all on anything you see that scares you in the script or anything to add to it. Definitely would like to do more things like I plan to use memtest to check RAM and perhaps throw up a dialog for the user. I also had thoughts about doing a verify of the hard drive and checking the SMART status. If you can write scripts and want to share code I'll post it in the script. Even if I don't choose to use it for me I will include it commented out so others can use or not use it.

-Josh -= josh@joshie.com =-
