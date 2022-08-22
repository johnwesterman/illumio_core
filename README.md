# Illumio Core PCE install Cliff Notes

## Simplified step by step for the PCE core install

```
Author: John Westerman, Illumio, Inc.
Serial number for this document is 20220822150344;
Version 2022.08
Monday August 22, 2022 15:03

Changed:
1. Minor updates to a few sections.
2. Moved process limits details to it's own section since not often done in small POCs.
```

## Install base packages

Note: Some of this is used during testing of PCE connectivity and will not be installed in production. Almost all of this is optional. You may find you do not need any of it to get your project off the ground.

There are two ways I do this. The first is "bare minimum software" which will get you up and running in the shortest amount of time. The second is a ton of tools to do onsite troubleshooting for networking and such.

For bare minimum:
```
yum update -y
```
```
yum install -y net-tools bzip2 ntp
```

for CentOS8:
All of the above tools come with the minimal image. C8 uses chronyd (not ntp) which also will come installed.

For all the gadgets for testing (optional):
```
yum install -y epel-release; yum update -y
```
```
yum install -y bind-utils openssh-clients patch syslog-ng traceroute tcpdump ipset postfix logrotate ca-certificates ntp procps-ng util-linux net-tools
```
## Firewall and SE Linux configuration

Turn off the firewall:

on CentOS 7.x:
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

on CentOS 8.x:
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

###File and Process Limits
#####For PCE ONLY: Process and File Limits. Only required if workload count above 100. Skip to Install the PCE RPM step below if this change not needed. If you need to change these reference this file.

If you need to change the file and process limits [reference this document](PROCESSLIMITS.md).

## Set the hostname properly

CentOS 7+, Set the host name:
```
hostnamectl set-hostname [your-new-hostname]
```

Make sure the /etc/hosts name for this FQDN is the same as /etc/sysconfig/network host name.

### First:
```
vi /etc/sysconfig/network
```
File contents:
```
NETWORKING=yes
HOSTNAME=[your-new-hostname]
```

### Second:
```
vi /etc/hosts
```
File contents:
```
x.x.x.x	xxx
vi /etc/resolv.conf
nameserver x.x.x.x
```

## Install the PCE and UI software via RPM:

(installing bzip2 is required if you are using CentOS < 8.x)
```
yum -y install bzip2
```
```
rpm -ivh <illumio_pce_core.rpm> illumio_pce_core_ui.rpm>
```
note: If you upgrading your environment, see my upgrade notes towards the end of this file.

## Set up for command aliasing (optional).

The remainder of this document will call these commands this way.
This step saves a ton of typing in the future.
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

On my own PCE I prefer to have these aliases in my login script. I will modify .bash_profile and add these aliases to the bottom of that file so when I login next time I don't have to use the 'source' command to pull them in my environment.

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

In order to apply the new hostname, a system reboot is required, issue **one** of the following commands in order to reboot a CentOS 7 machine.

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

NOTE: By default the installer will place certificates and private key as follows:
```
web_service_private_key [/var/lib/illumio-pce/cert/server.key]
web_service_certificate [/var/lib/illumio-pce/cert/server.crt]
trusted_ca_bundle [/etc/ssl/certs/ca-bundle.crt]
```

NOTE: Once you have a private key and certificate bundle the same will be used on each of the nodes in a cluster. If you are using an SNC you only need to place it in the proper place once. If you are using an MNC you will need to replicate the data across all of the nodes. The good news is that the same information is used for all nodes. Unique certificates are not required.

## Setting up the PCE environment

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
https://<pce_fqdn>:8443/login
```

should get you in to the landing page.

### Now, create a new user:

**NOTE: Do the following on SNC0 (CORE0 node in a multi-node cluster)**

```
ctldb create-domain --user-name demo@illumio.com --full-name 'Demo User' --org-name 'Illumio'
```
**NOTE** Use your own user-name, full-name and org-name. The above is simply a template of the command to be used.

At this point, you are done setting up the core system. The PCE should be up and running. You should have a clean, freshly installed system ready to pair workloads. You can log into the system and start pairing workloads now.

## VEN Compatibility Matrix

NOTE: The compatibility matrix must be uploaded to the PCE before you upload any VEN software bundles in the next step or you will get an error.

As part of setting up the VEN Library in the PCE, you must upload the VEN upgrade compatibility matrix to the PCE. The compatibility matrix contains information about valid VEN upgrade paths and VEN to PCE version compatibility. To use the PCE web console and the Illumio Core REST API, you must upload this matrix for VEN upgrades to be successful.

You will find the VEN Compatibility Matrix on the Illumio support site. Once this is obtained, copy to the /tmp directory of one of the PCE core nodes and run the following command:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install --compatibility-matrix [matrix_file_path_and_name]
```

NOTE: Make sure you use fully qualified names for the file. For example, if you are in the /tmp directory don't expect this to find this in the local working directory. Either use /temp/matrix_file_path_and_name or ./matrix_file_path_and_name. For whatever reason the tool will not look in to your current working directory for this file so be sure and specify the path.

## Set up the VEN repository.  

It is recommended that you use the cluster to also be a repository for the VEN software. This section will walk you through that process. You will need to get the VEN bundles you will need from the Illumio Support web site. They will be clearly identified in the VEN download section of the software download area. They will have a .bz2 extenstion.

Once you obtain this file copy it to the /tmp directory of the core0 node. The reason for /tmp is because ilo-pce will need access to this file and will not have the proper access unless you put it here. If you put it somewhere else just remember ilo-pce needs to read the file so permissions will need to be set. /tmp is the easiest path to success.

To do the following make sure you have a VEN bundle file as well as the compatibility matrix file. All are downloadable from the support web site.

Copy the installation files to the /tmp directory in the examples that follow. Any user can pull from /tmp. It is important because the ILO user is used for this.

This command installs the PCE bundle:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/illumio-ven-bundle-NNNNNNNNN.tar.bz2 --compatibility-matrix /tmp/illumio-release-compatibility-YYY.tar.bz2 --orgs all --default --no-prompt
```

where NNNNNNNN is the build version downloaded from the web site and YYY is the latest compatability matrix file number. And if you desire to be prompted remove the --no-prompt option.

For example:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/illumio-ven-bundle-19.3.0-6104.tar.bz2 --compatibility-matrix /tmp/illumio-release-compatibility-8.tar.bz2 --orgs all --default --no-prompt
```

**NOTE:** Keep this in mind; Make sure you use fully qualified names for the file for this process. For example, if you are in the /tmp directory don't expect illumio-pce-ctl to find this in the local working directory (it is not looking for it there). Either use /tmp/file_path_and_name or ./file_path_and_name. For whatever reason the tool will not look in to your current working directory for this file so be sure and specify the path. In the case above, I have supplied the full file path and file name. ilo-pce will also need at least read capability for these files since the command is done in it's name.

## runtime_env settings and suggested settings
NOTE: I strongly recommend you consider adding the following to the runtime_env.yml file. Especially the internal_service_ip option. If you do not bind to an IP address and let the PCE decide for itself things can get weird if you have multiple IP addresses or non RFC1918 addresses in use. If you do not specify an IP address and there are multiple addresses in use the PCE will use the highest numbered interface. So if you don't want to deal with crazy, don't let the PCE choose this on it's own.

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

## UPGRADE PROCESS

The abbreviated (snc) upgrade process is as follows:

Note: new in 19.3+ the PCE base and UI software are separate packages. Keep in mind that when updating both the PCE and UI in order to make sure you have all the dependencies put both on the RPM update as I've indicated below so you get it all without error messages. This is not clear in the current documenation so I've made a note of it here. It's optional for an RPM update so I've made it look that way.

for the PCE base software:
```
ctl status
```
```
ctldb dump --file /tmp/<serial_number>_pce_database
```
```
cp /etc/illumio-pce/runtime_env.yml /tmp/<serial_number>_runtime_env.yml
```
```
ctl stop
```
... upgrade both the core and UI software:
```
rpm -Uvh illumio-pce-xx.x.x-xxxxx.x86_64.rpm illumio-pce-ui-xx.x.x.UIx-x.x86_64.rpm
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

There are a number of ways to automate an install. The way I am going to show you is how to script this using a standard unix shell (sh).

For this example there are 2 main scripts:

1. `copy_files.sh` - copies all the software to the CentOS host.
2. `setup.sh` - runs a "hands off" installation.

### A note on software you need to provide.

The scripts are going to assume you are providing:

1. A single RPM for PCE Core has been provided
2. A single RPM for PCE UI has been provided
3. A single VEN Bundle file has been provided if it is desired to be installed.

Put these files in the current working directory. They will be copied to the proper locations on the CentOS host by the copy_files.sh script. These files will be used by the setup.sh script that is copied in the root directory of the CentOS host.

Once the copy_files.sh script is run login as root to the CentOS host and run the setup.sh script located in the /root directory. If you like the defaults set up in the script it will run as-is. Or modify to your liking.

I'll explain the resizedisk1.sh and resizedisk2.sh scripts at a later date.

## <a name=backups>Backing up the database </a>

You can find more information on backing up the data in a PCE by going to [Illumio Documenation](https://docs.illumio.com/). When I create an SNC that I am going to use for a while I'll make sure I have regular backups. I do this with cron. If you do this in production it may look a little different. The important thing about the back up is to make it first but then to get it off the box so if anything happens your backup easily recovered and can be used to re-instantiate a system.

```
My crontab looks like this:
MAILTO = (your e-mail address)
SHELL=/bin/bash

1 0 * * * : Backup PCE database ; sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management dump --file /home/ilo-pce/pce_backups/`/bin/date +'\%Y_\%m_\%d_\%H\%M'`_automated_backup_pce_database

# only keep the last 60 backups
0 0 * * * find /home/ilo-pce/pce_backups -mtime +60 -delete
```

What the above will do is every morning at 1am a backup will be made and put in a specific directory. It will also make sure there are no more than X copies of the database files; in this case 60 days worth.
