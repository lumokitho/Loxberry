#!/usr/bin/perl

# Input parameters from loxberryupdate.pl:
# 	release: the final version update is going to (not the version of the script)
#   logfilename: The filename of LoxBerry::Log where the script can append
#   updatedir: The directory where the update resides
#   cron: If 1, the update was triggered automatically by cron

use LoxBerry::Update;

$LoxBerry::System::DEBUG = 1;

init();

# Update Kernel and Firmware
if (-e "$lbhomedir/config/system/is_raspberry.cfg" && !-e "$lbhomedir/config/system/is_odroidxu3xu4.cfg") {
	LOGINF "Preparing Guru Meditation...";
	LOGINF "This will take some time now. We suggest getting a coffee or a second beer :-)";
	LOGINF "Upgrading system kernel and firmware. Takes up to 10 minutes or longer! Be patient and do NOT reboot!";

	my $output = qx { SKIP_WARNING=1 SKIP_BACKUP=1 BRANCH=stable /usr/bin/rpi-update f8c5a8734cde51ab94e07c204c97563a65a68636 };
	my $exitcode  = $? >> 8;
	if ($exitcode != 0) {
        	LOGERR "Error upgrading kernel and firmware - Error $exitcode";
        	LOGDEB $output;
                $errors++;
	} else {
        	LOGOK "Upgrading kernel and firmware successfully.";
	}
}

# Copy new ~/system/systemd to installation
LOGINF "Install ~/system/systemd to your Loxberry...";
&copy_to_loxberry('/system/systemd');

# Link usb-mount@.service
if ( -e "/etc/systemd/system/usb-mount@.service" ) {
	LOGINF "Remove /etc/systemd/system/usb-mount@.service...";
	unlink ("/etc/systemd/system/usb-mount@.service");
}
LOGINF "Install usb-mount@.service...";
system( "ln -s $lbhomedir/system/systemd/usb-mount@.service /etc/systemd/system/usb-mount@.service" );

LOGINF "Re-Install ssdpd service...";
if ( -e "/etc/systemd/system/usb-mount@.service" ) {
	unlink ("/etc/systemd/system/ssdpd.service");
	system ("ln -s $lbhomedir/system/systemd/ssdpd.service /etc/systemd/system/ssdpd.service");
	system ("/bin/systemctl daemon-reload");
	system ("/bin/systemctl start ssdpd");
}

# Link loxberry.service
if ( -e "/etc/init.d/loxberry" ) {
	LOGINF "Remove old loxberry init script...";
	unlink ("/etc/init.d/loxberry");
}
if ( -e "/etc/systemd/system/loxberry.service" ) {
	LOGINF "Remove /etc/systemd/system/loxberry.service...";
	unlink ("/etc/systemd/system/loxberry.service");
}
LOGINF "Install loxberry.service...";
system( "ln -s $lbhomedir/system/systemd/loxberry.service /etc/systemd/system/loxberry.service" );

# Link createtmpfs.service
if ( -e "/etc/init.d/createtmpfsfoldersinit" ) {
	LOGINF "Remove old createtmpfs init script...";
	unlink ("/etc/init.d/createtmpfsfoldersinit");
}
if ( -e "/etc/systemd/system/createtmpfs.service" ) {
	LOGINF "Remove /etc/systemd/system/createtmpfs.service...";
	unlink ("/etc/systemd/system/createtmpfs.service");
}
LOGINF "Install createtmpfs.service...";
system( "ln -s $lbhomedir/system/systemd/createtmpfs.service /etc/systemd/system/createtmpfs.service" );

LOGINF "Disable already deinstalled dhcpcd.service...";
system( "systemctl disable dhcpcd" );

system ("/bin/systemctl daemon-reload");
system ("/bin/systemctl enable loxberry.service");
system ("/bin/systemctl enable createtmpfs.service");

## If this script needs a reboot, a reboot.required file will be created or appended
LOGWARN "Update file $0 requests a reboot of LoxBerry. Please reboot your LoxBerry after the installation has finished.";
reboot_required("LoxBerry Update requests a reboot.");

LOGOK "Update script $0 finished." if ($errors == 0);
LOGERR "Update script $0 finished with errors." if ($errors != 0);

# End of script
exit($errors);