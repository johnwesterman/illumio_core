# Illumio Core PCE install Cliff Notes

## Simplified step by step for the PCE core install

```
Author: John Westerman, Illumio, Inc.
Serial number for this document is 20240322160033;
Version 2024.3
Friday March 22, 2024 16:00

Changed:
1. Updated some VEN bundle managment wording.
```

## Install base packages

Note: Some of this is used during testing of PCE connectivity and will not be installed in production. Almost all of this is optional. You may find you do not need any of it to get your project off the ground.

There are two ways I do this. The first is "bare minimum software" which will get you up and running in the shortest amount of time. The second are tools to do onsite troubleshooting for networking and such.

For bare minimum:
```
dnf update -y
```
```
dnf install -y net-tools bzip2 ntp tmux htop
```

for CentOS/REHL/Rocky release 8+:
All of the above tools come with the minimal image. C8 uses chronyd (not ntp) which also will come installed.

For all the gadgets for testing (optional):
```
dnf install -y epel-release; dnf update -y
```
```
dnf install -y bind-utils openssh-clients patch traceroute tcpdump ipset postfix logrotate ca-certificates procps-ng util-linux net-tools
```
You will find that the above list of software is already installed. It is good to make sure though.

## Firewall and SE Linux configuration

Turn off the firewall:

on CentOS/REHL/Rocky 7.x:
```
systemctl start ntpd.service
```
```
systemctl enable ntpd.service
```
```
systemctl stop firewalld
```
```
systemctl disable firewalld
```

on CentOS/REHL/Rocky 8+:
Note: ntp should be installed but now is service chronyd (systemctl status chronyd). You will likely find that it is already running.
```
systemctl stop firewalld
```
```
systemctl disable firewalld
```

selinux can be in any mode including enforcing. I prefer it to be in permissive or disabled mode for testing. In production the parameter will be enforcing.

```
vi /etc/selinux/config
```
For testing, change from **enforcing** to **disabled**. Although you really don't need to do this. This is done to remove any initial problems. This can all be undone later.

### File and Process Limits

##### For PCE ONLY: Process and File Limits. Only required if workload count above 100. Skip to Install the PCE RPM step below if this change not needed. If you need to change these reference this file.

If you need to change the file and process limits [reference this document](PROCESSLIMITS.md).

## Set the hostname properly

Set the host name properly:
```
hostnamectl set-hostname [your-new-hostname]
```

Make sure the /etc/hosts name for this FQDN is the same as /etc/sysconfig/network host name.

### First (generally unnecessary these days):
```
vi /etc/sysconfig/network
```
File contents:
```
NETWORKING=yes
HOSTNAME=[your-new-hostname]
```

### Second:
File contents:
```
x.x.x.x	xxx
vi /etc/resolv.conf
nameserver x.x.x.x
```
Note that if you have good resolution via the DNS server above and have A-records for all of your nodes updateing the hosts file is unnecessary. If you do not have A-records defined for your environment you will need to modifiy the hosts file for all of the nodes in the cluster as well as any VEN enabled workload that will touch the cluster. It is a lot easier to set up the DNS before starting this project but often that is not possible so edit the hosts files as required for your environment.
```
vi /etc/hosts
```

## Install the PCE and UI software.

Illumio Core uses bzip2. This will insure it is installed for use.
```
dnf -y install bzip2
```
```
dnf install [illumio_pce_core.rpm] [illumio_pce_core_ui.rpm]
```
note: If you upgrading your environment, see my upgrade notes towards the end of this file.

## Set up for command aliasing (optional).

The remainder of this document will call these commands this way.
This step saves a lot of typing in the future.
Put the following in a file named "pcealiases" (or your file name of choice)

```
alias ctl='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl'
alias ctldb='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management'
alias ctlenv='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-env'
```

Then put these in the alias list using this command:
```
source ./pcealiases
```

I prefer to have these aliases in my login script. I will modify .bash_profile and add these aliases to the bottom of that file so when I login next time I don't have to use the 'source' command to pull them in my environment.

The other thing I do on my PCE installations is add '.' to my path. This keeps me from having to put './' in front of all the commands I just want to run from the command line without all the fuss.

All combined my .bash_profile will look like this:

```
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:.

export PATH

alias ctl='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl'
alias ctldb='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management'
alias ctlenv='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-env'
alias ll='ls -al'
```

NOTE: To make this permanent edit ~/.bash_profile and put the above commands there so they will be there every time you log in.

If you have made many software updates, especially a kernel update or to apply the new hostname and the like, a system reboot might be required, issue **one** of the following commands in order to reboot a Linux machine.

```
init 6
```
-or-
```
systemctl reboot
```
-or-
```
shutdown -r now
```

## Certificate installation(s)

On a personal note, I encourage you to go through the full process of generating a valid certificate for your PCE installation. This certificate should be globally trusted by all systems that will use the PCE for security policy. You can use certificates that are self-signed or otherwise not valid but your life will be much easier if you provide valid certificates up front and keep those certificates updated as time moves forward.

NOTE: By default the installer will place certificates and private key as follows:
```
web_service_private_key [/var/lib/illumio-pce/cert/server.key]
web_service_certificate [/var/lib/illumio-pce/cert/server.crt]
trusted_ca_bundle [/etc/ssl/certs/ca-bundle.crt]
```

NOTE: Once you have a private key and certificate bundle the same will be used on each of the nodes in a cluster. If you are using an SNC you only need to place it in the proper place once. If you are using an MNC you will need to replicate the data across all of the nodes. The good news is that the same information is used for all nodes. Unique certificates are not required.

## PCE System Setup

**AS ROOT** user:
```
/opt/illumio-pce/illumio-pce-env setup --generate-cert
```
-or-
```
/opt/illumio-pce/illumio-pce-env setup
```
And check the environment after the setup is complete:
```
ctlenv check
```
--or--
```
sudo -u ilo-pce illumio-pce-env check
```
**NOTE: If you don't get "OK" at this piont then go back and sort things out before moving forward. This system will not work without a working certificate of some kind.**

The **--generate-cert** option generates a self-signed certificate, installs that certificate and related private key with proper permissions. Doing this sets up the PCE for a 90 day trial. If you leave that off you will be required to install your certificate in the directories with file names mentioned above or change the **/etc/illumio-pec/runtime_env.yml** file with the settings you want to use.

It is possible to use your own self signed certificate. Keep in mind it has to be in a certain format with extended attributes, verified and installed by hand. It's possible but I am not going to cover that topic here.

**NOTE**: The server certificate is going to be a combination of the server certificate, the certificate chain including all intermediate certificates and the root certificate, in that order. If the certificate file does not have all of these certificates contained with it you will want to used an editor and make it so. Use the following commands to validate the certificate file.

The newest versions of the PCE will not run without a valid certificate. If your certificate expires the services will not start. I encourage you to use a valid, globally trusted certificate for your PCE.

For more information on **setting up, validating and testing certificates** [reference this document](CERTIFICATE.md).

## <a name=pce-start>Start and run the PCE</a>

##### Note: This is also the start point for a system "reset" described at the end of this document.

Start the PCE Software (on each node if running an MNC):

```
ctl start --runlevel 1; ctl status -svw
```

NOTE: if PCE doesn't have running status in a minute or two go back and check your work

If a multi-node cluster is being used, verify the Data "Master NODE" election:

```
ctldb show-primary
```

NOTE: You will use the master node information in the next step. The command above will return the IP address of the master node. Do to initialize the PCE you will do so on the master data node.

## Initialize the PCE Software:
NOTE: Do the following ON THE DATABASE MASTER NODE determined FROM ABOVE

```
ctldb setup
```
 ... to set up the database.
```
ctl set-runlevel 5
```
... set the runlevel on all nodes.
```
ctl status -svw
```
```
ctl cluster-status
```

If above everything statuses good open a browser and go to:

```
https://[pce_fqdn]:8443/login
```

should get you in to the landing page.

### Now, create a new user:

**NOTE: Do the following on SNC0 (CORE0 node in a multi-node cluster)**

```
ctldb create-domain --user-name demo@illumio.com --full-name 'Demo User' --org-name 'Illumio'
```
**NOTE** Use your own user-name, full-name and org-name. The above is simply a template of the command to be used.

At this point, you are done setting up the core system. The PCE should be up and running. You should have a clean, freshly installed system ready to pair workloads. You can log into the system and start pairing workloads now.

## Setting up and modifying the VEN repository.  

It is recommended that you use the PCE to be a repository for the VEN software. This section will walk you through that process. You will need to get the VEN bundles you want to use from the Illumio Support web site. They will be clearly identified in the VEN download section of the software download area. They will have a .bz2 extension.

As part of setting up the VEN Library you must also use the VEN upgrade compatibility matrix. The compatibility matrix contains information about valid VEN upgrade paths and VEN to PCE version compatibility. To use the PCE web console and the Illumio Core REST API, you must upload this matrix for VEN upgrades to be successful.

Once you obtain these files copy them to the /tmp directory of the core0/snc node. The reason to use the /tmp is ilo-pce will need access to this file and will not have the proper access unless you put it here. If you put it somewhere else just remember ilo-pce needs to read the file so permissions will need to be set. /tmp is the easiest path to success.

To do the following make sure you have a VEN bundle file as well as the compatibility matrix file. All are downloadable from the support web site.

Copy the installation files to the /tmp directory in the examples that follow. Any user can pull from /tmp. It is important because the ilo-pce user is used for this set of commands (not root).

### Installing the VEN Bundle

This command installs the VEN bundle:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/[illumio-ven-bundle-NNNNNNNNN.tar.bz2] --compatibility-matrix /tmp/[illumio-release-compatibility-YYY.tar.bz2] --orgs all --default --no-prompt
```

If you are command line lazy (like me) and have copied the files without duplicates to the /tmp directory you can install the software with this command:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/`ls illumio-ven-bundle-*` --compatibility-matrix /tmp/`ls illumio-release-compatibility-*` --orgs all --default --no-prompt
```

where NNNNNNNN is the build version downloaded from the web site and YYY is the latest compatability matrix file number. And if you desire to be prompted remove the --no-prompt option.

For example:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/illumio-ven-bundle-19.3.0-6104.tar.bz2 --compatibility-matrix /tmp/illumio-release-compatibility-8.tar.bz2 --orgs all --default --no-prompt
```

**NOTE:** Keep this in mind; Make sure you use fully qualified names for the file for this process. For example, if you are in the /tmp directory don't expect illumio-pce-ctl to find this in the local working directory (it is not looking for it there). For whatever reason the tool will not look in to your current working directory for this file so be sure and specify the path. In the case above, I have supplied the full file path and file name. ilo-pce will also need at least read capability for these files since the command is done using ilo-pce permissions.

### Listing the VEN bundles that are installed

This command will list the bundle files that are currently installed:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-releases-list | grep release:
```

### Removing an existing VEN bundle from a PCE

This command can be used to remove a specific bundle release. You can get the releases that are installed in the command above and the replace [release] below with that number you want to remove.

```
sudo -u ilo-pce illumio-pce-ctl ven-software-release-delete [release]
```

## runtime_env settings and suggested settings

While none of the following is required, I recommend you consider adding the following to the runtime_env.yml file. Especially the internal_service_ip option. If you do not bind to an IP address and let the PCE decide for itself things can get weird if you have multiple IP addresses or non RFC1918 addresses in use. If you do not specify an IP address and there are multiple addresses in use in the cluster the PCE will use the highest numbered interface. So if you don't want to deal with crazy, don't let the PCE choose this on it's own.

```
#
# Updated October 20, 2017 11:45
# I recommend you bind to the IP address. Especially if you are using non-RFC1918
# IP addressing using this in the runtime_env.yml:
#
internal_service_ip: XXX.XXX.XXX.XXX

# Use the following for exposing the e-mail link to set up new users
expose_user_invitation_link: true

# If you want to export syslog add this to runtime_env.yml:
export_flow_summaries_to_syslog:
- blocked
- potentially_blocked
- unknown
#- accepted
```

## Upgrade the PCE

This section will describe the abbreviated (SNC) upgrade process.

Note: new in 19.3+ the PCE base and UI software are separate packages. Keep in mind that when updating both the PCE and UI in order to make sure you have all the dependencies put both on the RPM update as I've indicated below so you get it all without error messages. This is not clear in the current documenation so I've made a note of it here. It's optional for an RPM update so I've made it look that way.

for the PCE base software:
```
ctl status
```
Back up the database and runtime files. I have created some shortcuts so this is more automatic. I am assuming you have put the files in the /tmp directory. If you put them somewhere else or want to use the full file name do your own subsitution.
```
ctldb dump --file /tmp/`/usr/bin/date '+%Y-%m-%d-'`pce-database
cp /etc/illumio-pce/runtime_env.yml /tmp/`/usr/bin/date '+%Y-%m-%d-'`runtime-env.yml

```
```
ctl stop
```
Upgrade both the core and UI software. Note that I am doing system subsitutions. I am assuming you put the two files in the /tmp directory and they have standard naming conventions. If not, do your own substitutions.
```
rpm -Uvh `ls /tmp/illumio-pce-[0-9]*` `ls /tmp/illumio-pce-ui-*`
```
... Check to make sure things are still ok:
```
ctlenv check
```
```
ctl start --runlevel 1;ctl status -svw
```
-- wait for the nodes to come up in run level 1 state
To figure out which DB is the DB "master":
```
ctldb show-primary
```
Do the following on the master database node only:
```
ctldb migrate
```
```
ctl set-runlevel 5; ctl status -svw
```
Once the nodes are all running in run level 5 the PCE will be accessible.

## Preparing the PCE environment for production (hardening)

[See this document](HARDENING.md) for more information on how to harden a system to be put in the wild.

## Reseting an environment

While rare it has been known that a false start or mis-configuration will cause a system to need to be reset. Or maybe you just want to start over after a lengthy POC. This command should be used with caution as it will reset the persistent data store and other critical data in the system. If you are using a MNC this will need to be done on every data node that is in a cluster.

The command is very destructive to a running system. This is essentially starting over. All of the database contents will be irreversably deleted. [You should have a backup](#backups) of your data before doing this if that is desired.

Set the system(s) in run level 1. If you try to do this in runlevel 5 on an MNC the system will failover and you will never be successful resetting the devices. You need to be in runlevel 1 so failover will not occur.
```
ctl start --runlevel 1
```
**On each DATA node** in the system do the following:

```
sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl reset
```
-or if you are using aliases:
```
ctl reset
```
**NOTE:** On an MNC you will need to run this command on **each** of the DATA nodes.

Once you have reset each DATA node go back into run level 5 and check the status before moving forward.

```
ctl set-runlevel 5; ctl status -svw
```

Once you do a reset you will need to start the PCE. Reference the section titled ["Start and run the PCE"](#pce-start) and "Initialize the PCE Software" above. Once the PCE is in runlevel 1 you will need to recreate the database and set up the org as mentioned above.  

If you have installed a VEN repo you do not have to recreate that step in the reset process.

You have to rebuild the certificate unless that is something you want to do as a part of the reset. But do remember if you reset the certificate and have VENs paired they will need to be re-paired with the new certificate to work properly. Best to unpair, create new certificate and re-pair the workloads.

If you are resetting because of an IP address change make sure that the IP address in DNS matches the IP address of the PCE. If you are doing local hosts reslolution make sure the IP addresses are correct there. Make sure that the ip addresses used in the runtime file (/etc/illumio-pce/runtime_env.yml) are correct. Any failure to rebuild properly should be corrected with a reset and database rebuild to set up the org properly.

## Automation of an install

[See this document](automation/AUTOMATION.md) for more information on how to automate the installation process with a simple script that will setup and run a single node cluster in about 5 minutes.

## <a name=backups>Backing up the database </a>

You can find more information on backing up the data in a PCE by going to [Illumio Documentation](https://docs.illumio.com/). When I create an SNC that I am going to use for a while I'll make sure I have regular backups. Even if you have an MNC you should do backups and make sure the backup is off the systems and put in a safe place. **Also remember no crazy stuff here. If you backup the database on one set of IP addressess you can't restore it to another. The restore will fail. Changing the IP address of an SNC or MNC takes planning. You are best to reach out to your SE or PS team mate to help with this.** This example is how to backup an SNC0 and then restore that database to the same IP address as it was pulled from.

### Back up the database

An example of backing up the database will look like this. You will want to be in full running status to take the backup (run level 5). I will get backups of both the database as well as the runtime file like this:
```
ctldb dump --file /tmp/[serial_number]_pce_database
```
```
cp /etc/illumio-pce/runtime_env.yml /tmp/[serial_number]_runtime_env.yml
```
Or if you are lazy like me use this method to auto-name the files for you:
```
ctldb dump --file /tmp/`/usr/bin/date '+%Y-%m-%d-'`pce-database
cp /etc/illumio-pce/runtime_env.yml /tmp/`/usr/bin/date '+%Y-%m-%d-'`runtime-env.yml

```

### Restore the database

In order to restore a database that you backed up in the example above you will essentially reverse the process. You will need to be in run level 1 to do the restore. Once the restore is complete you will need to go back to run level 5.

The three steps to restore are as follows:

```
ctl start --runlevel 1
```
```
ctldb restore --file /tmp/[serial_number]_pce_database
```
```
ctl set-runlevel 5; ctl status -svw
```

### Listen-only Mode

Once you do a restore the PCE will be in "listen-only mode" until you turn this mode off. To turn listen-only mode off:

```
sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl listen-only-mode disable
```
or, if you have the aliases installed:
```
ctl listen-only-mode disable
```

### Using CRON to automate things

I will automate the backup process with cron. If you do this in production it may look a little different. The important thing about the back up is to make it first but then to get it off the box so if anything happens your backup easily recovered and can be used to re-instantiate a system.

```
My crontab looks like this:
MAILTO = (your e-mail address)
SHELL=/bin/bash

1 0 * * * : Backup PCE database ; sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management dump --file /home/ilo-pce/pce_backups/`/bin/date +'\%Y_\%m_\%d_\%H\%M'`_automated_backup_pce_database

# only keep the last 60 backups
0 0 * * * find /home/ilo-pce/pce_backups -mtime +60 -delete
```

What the above will do is every morning at 1am a backup will be made and put in a specific directory. It will also make sure there are no more than X copies of the database files; in this case 60 days worth.

## Changing an IP address of a PCE

**Warning: You are swimming with sharks here. Be careful. Back up your database now.**

The following comments are unsupported guidance to be used as interesting information only.

These are just notes. Things to consider. In the example I am not changing the FQDN, only the IP address. I want to put down things to consider when doing this.

1. It is best that you reach out to your SE, PS or official support contacts to help you with this. Whether an SNC or MNC changing the IP address has some operational conciderations since so much security comes with some trusted IP address(es) and FQDNs.
1. The guaranteed way after letting the VEN's get the new IP from the PCE runtime is to take a backup of the PCE, reset the PCE and restore the DB.
1. Update the PCE runtime_env.yml with the new IP and let the VENs soak in the changes before making the PCE side change.
1. We typically like to make the PCE runtime addition with the new IP and leave the old IP for at least 30 mins to make sure the VENs check in and get the new IP.
1. If done properly you should not have to "unpair/repair" any VENs.
1. You could go into "visibility" mode (not using enforcement mode) before making the change. This way the VEN will have no problem physically connecting to the new IP address. In this mode, you will not be blocking any traffic (keep this in mind).
1. You cannot change the VEN enforcement mode from the VEN side. It must be done from the PCE.

## Setting up FIPS operational mode (CENTOS/REHL 8/9)

To enable the cryptographic module self-checks mandated by the Federal Information Processing Standard (FIPS) 140-3, you must operate RHEL 8 in FIPS mode. Starting the installation in FIPS mode is the recommended method if you aim for FIPS compliance.

 The Federal Information Processing Standards (FIPS) Publication 140 is a series of computer security standards developed by the National Institute of Standards and Technology (NIST) to ensure the quality of cryptographic modules. The FIPS 140 standard ensures that cryptographic tools implement their algorithms correctly. Runtime cryptographic algorithm and integrity self-tests are some of the mechanisms to ensure a system uses cryptography that meets the requirements of the standard.

To ensure that your RHEL system generates and uses all cryptographic keys only with FIPS-approved algorithms, you must switch RHEL to FIPS mode. 

To do this there are three commands to follow:

1. fips-mode-setup --enable

```
Command ouput:
Kernel initramdisks are being regenerated. This might take some time.
Setting system policy to FIPS
Note: System-wide crypto policies are applied on application start-up.
It is recommended to restart the system for the change of policies
to fully take place.
FIPS mode will be enabled.
Please reboot the system for the setting to take effect.
```
2. reboot

```
Machine will reboot.
```

3. fips-mode-setup --check

```
Command ouput:
FIPS mode is enabled.
```
