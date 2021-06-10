# Illumio Core PCE install Cliff Notes

## Simplified step by step for the PCE core install

```
Written by John Westerman.
Illumio, Inc.
Serial number for this document is 20210607145010;
Version 2021.6
Monday June 07, 2021 14:50

Things I changed:
1. Introduction of CentOS8 notes and process. As of this writing installing the PCE on CentOS8 is not supported.
2. A few notes on how to upgrade the PCE/UI.
3. Move to markdown language for better display on github.
4. Added more on setting up and running a multi-node cluster (MNC).
5. Focus on the ability to cut and pasted from this document into a command line as-is.
6. Added automation script and languange on how to do an automated install from a simple shell command line.
7. Added some in-document links to make navigation easier.
8. Added my method for backing up the datbase on an SNC
9. Removed reference to vim using vi instead.
```

## Install base packages

Note: Some of this is used during testing of PCE connectivity and will not be installed in production. Almost all of this is optional. You may find you do not need any of it to get your project off the ground.

There are two ways I do this. The first is "bare minimum software" which will get you up and running in the shortest amount of time. The second is a ton of tools to do onsite troubleshooting for networking and such.

For bare minimum:
```
yum update -y
yum install -y net-tools bzip2 ntp

for CentOS8:
All of the above tools come with the minimal image. C8 uses chronyd (not ntp) which also will come installed.
```

For all the gadgets for testing (optional):
```
yum install -y epel-release
yum update -y
yum install -y bind-utils openssh-clients telnet syslog-ng traceroute tcpdump ipset postfix logrotate ca-certificates ntp procps-ng util-linux net-tools
```
## Firewall and SE Linux configuration

Turn off the firewall:

on CentOS 6.x:
```
service ntpd start 
chkconfig ntpd on 
service iptables stop 
chkconfig iptables off
```

on CentOS 7.x:
```
systemctl start ntpd.service
systemctl enable ntpd.service
systemctl stop firewalld
systemctl disable firewalld
```

on CentOS 8.x:
Note: ntp should be installed but now is service chronyd (systemctl status chronyd). You will likely find that it is already running.
```
systemctl stop firewalld
systemctl disable firewalld
```

selinux can be in any mode including enforcing. I prefer it to be in permissive or disabled mode for testing. In production the parameter will be enforcing.
```
vi /etc/selinux/config
```
For testing, change from enforcing to disabled.

### PCE ONLY: Process and File Limits. Only required if workload count above 100. Skip to Install the PCE RPM step below if this change not needed.

```
vi /etc/security/limits.conf
```
add this to the bottom of this file:
```
* soft core unlimited
* hard core unlimited
* hard nproc 65535
* soft nproc 65535
* hard nofile 65535
* soft nofile 65535
```
Edit nproc file specific to the OS you are using ...

For CentOS 6.x:
```
vi /etc/security/limits.d/90-nproc.conf
```
For CentOS 7.x:
```
vi /etc/security/limits.d/20-nproc.conf
```
... and add the following (clean up any duplication):

```
* hard nproc 65535
* soft nproc 65535
```

For PCE version 18.x and above:
```
vi /etc/sysctl.conf
```

core nodes:
```
fs.file-max        = 2000000
net.core.somaxconn = 16384
```

data nodes:
```
fs.file-max          = 2000000
kernel.shmmax        = 60000000
vm.overcommit_memory = 1
```
snc0 nodes:
```
fs.file-max          = 2000000
net.core.somaxconn   = 16384
kernel.shmmax        = 60000000
vm.overcommit_memory = 1
```

## Set the hostname properly

CentOS7: Set the host name:
```
hostnamectl set-hostname [your-new-hostname]
```

Make sure the /etc/hosts name for this FQDN is the same as /etc/sysconfig/network host name.

### First:
```
vi /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=[your-new-hostname]
```

### Second:
```
vi /etc/hosts
x.x.x.x	xxx
vi /etc/resolv.conf
nameserver x.x.x.x
```

## Install the PCE and UI software via RPM:

(installing bzip2 is required if you are using CentOS 7.x)
```
yum -y install bzip2  
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

NOTE: To make this permanent edit ~/.bash_profile and put the above commands there so they will be there every time you log in.

In order to apply the new hostname, a system reboot is required, issue **one** of the following commands in order to reboot a CentOS 7 machine.

```
1: init 6
2: systemctl reboot
3: shutdown -r now
```

## Certificate installation(s)

NOTE: By default the installer will place certificates and private key as follows:
```
web_service_private_key [/var/lib/illumio-pce/cert/server.key]
web_service_certificate [/var/lib/illumio-pce/cert/server.crt]
trusted_ca_bundle [/etc/ssl/certs/ca-bundle.crt]
```

NOTE: Once you have a private key and certificate bundle the same will be used on each of the nodes in a cluster. If you are using an SNC you only need to place it in the proper place once. If you are using an MNC you will need to replicate the data across all of the nodes. The good news is that the same information is used for all nodes. Unique certificates are not required.

## Set up the PCE environment

AS ROOT user:
```
/opt/illumio-pce/illumio-pce-env setup --generate-cert
```
-or-
```
/opt/illumio-pce/illumio-pce-env setup
```
And check the environment:
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

NOTE: The server certificate is going to be a combination of the server certificate, the certificate chain including all intermediate certificates and the root certificate, in that order. If the certificate file does not have all of these certificates contained with it you will want to used an editor and make it so. Use the following commands to validate the certificate file.

## Creating the certificates

Certificates are used for 3 major components in the PCE software installation that use TLS:
- Web Service – Used to secure access to the PCE web console, as well as that provided by the Illumio ASP REST API.
- Event Service – Provides continuous, secure connectivity from the PCE to the VENs under management and provides a notification capability so that VENs can be instructed to update policy on the host Workloads.
- Service Discovery – Used for cluster management between PCE node members in the cluster and allows real time alerting on service availability and status.

When building your certificate it will be important to remember these key attributes included with the certificate:

- TLS Web Server Authentication Extended Key Usage
- TLS Web Client Authentication Extended Key Usage
- Subject Alternative Names (SAN) are included for the PCE cluster VIP name (load balancer FQDN) and core node names. You do not need to include the data nodes or any IP addresses in the SAN field of the certificate.

A common certificate will be used for all these functions but it is important that all the right options are present in the certificate to allow for secure communication of the software.

## Validating the Certificate.

Your certificate file should be in PEM format. If you look at the file, it will be text with "_BEGIN CERTIFICATE_" and _"END CERTIFICATE"_ in the text. Cat the certificate and make sure it's not encrypted.

Check the certificate to be valid:
```
openssl x509 -text -noout -in <certificate_name>
```
And another check that is displayed a little easier to read is to ask the PCE about the certificate. The following command will look at all of the certificates in the certificate chain and display information for each of them. If there is a problem with the certificate chain it will show up in this data.

```
ctlenv setup -ql --test 5

-or-

 /opt/illumio-pce/illumio-pce-env setup --test 5 --list
```

NOTE: You should see the full chain here. You also want the following extended attributes:
```
X509v3 Extended Key Usage:
TLS Web Server Authentication, TLS Web Client Authentication
```
*If you do not have TLS web and client you will need to generate a new certificate that include these attributes.*

Check to insure that the Private Key and the Certificate are related:
```
openssl rsa -modulus -noout -in server.key | openssl md5
openssl x509 -modulus -noout -in server.crt | openssl md5
```

NOTE: For the evaluation certificates, the file names I am working with are:
```
star_poc_segmentationpov_com.pem - Server private key
star_poc_segmentationpov_com_bundle.crt - Certificate bundle
```

## Preparing the certificate and key files to be used

The Illumio PCE installer program installs the certificate and private keys as follows:

The private key is at /var/lib/illumio-pce/cert/server.key. Make sure it has the following file attributes:
```
chmod 400 server.key
chown ilo-pce:ilo-pce server.key
```

The server certificate bundle is at */var/lib/illumio-pce/cert/server.crt*

NOTE: this is a bundle file with full chain of trust in PEM format that will include all root and intermediate certificates in this order:

1. PCE certificate
2. Intermediate certificate(s) in order of trust
3. Root certificate

Make sure the certificate file has the proper permissions:
```
chmod 440 server.crt
chown ilo-pce:ilo-pce server.crt
```

If necessary (it usually isn't) the trusted CA bundle into /etc/ssl/certs/ca-bundle.crt
- this is not important and no need to copy anything here using the illumioeval certificates
- the full chain of trust is established in the server certificate with CA bundle above
- the CA will be known to the PCE/VEN because the ca-certificates package has been installed and COCOMO is defined.

##  UPDATING CA-trust (if required)

There should be no reason to do this with a valid certificate. This will only be required when there is no CA or the certificate chain can not be validated by the host. Sometimes (COMODO) there are more than 1 (often 2) intermediate certificates in use. You will need to combine the server certificate with all the intermedia and finally the root certificate chain. And do so in order: Server, then all intermediates, then the root certificate in one file.

Note: If either the PCE or the VENs do not have access to the CA (that is, the CA is *not* known internally) copy the root and intermediate certificates using any file name to: /etc/pki/ca-trust/source/anchors/ then run these commands:
```
update-ca-trust force-enable
update-ca-trust extract
update-ca-trust check
```

To do the same for Ubuntu:

Go to /usr/local/share/ca-certificates/
Create a new folder, i.e. "sudo mkdir <any_folder_name>"
Copy the .crt file into the "any_folder_name" folder
Make sure the permissions are OK (755 for the folder, 644 for the file)
Finally, run "sudo update-ca-certificates"

## A note on setting up an Multi-Node Cluster (MNC)

**If you are not setting up an MNC you can safely skip this section.**

In most cases this document is used to set up a quick testing environment for functional testing using a single node (SNC). Normally a SNC is not used in production. Occasionally there is a need to set up a multi-node cluster (MNC) in a test environment. Here are some of my thoughts with that process.

Typically the setup will be run ("illumio-pce-env setup") on one core node only. That will generate a runtime yaml file and put it in the /etc/illumio-pce/runtime_env.yml file. This file will be a template in for all of the nodes constituting the MNC. In that file there are things that need to be consistent in the cluster:

* The certificate used in this process is the certificate used on all of the nodes. There will be only one certificate and one private key for all nodes. The certificate and private key are the same for all nodes. The point is once you have generated a proper certificate above you have what you need for the cluster nodes.
* The runtime_env.yml file will be mostly the same between all the nodes. The only thing that will likely be different is the **"node_type:"** directive. For the cores it is "core" and for the data nodes it's "data1" and "data2" in a 4 node cluster.
* The **"pce_fqdn:"** directive should never be a core node FQDN. It should always be a separate name which is usually the FQDN of the load balancer VIP IP for the PCE cluster.
* The **"service_discovery_fqdn:"** directive should all be the same. Usually we recommend point to the core0 FQDN or IP address.

So how to go about doing this.

* Run the setup on core0.
* Copy the **/etc/illumio-pce/runtime_env.yml** to each of the other nodes **/etc/illumio-pce/runtime_env**.
* Make relevant changes as indicated above to each of the other nodes changing their "node_type" to reflect the function of the node.

Once you have completed the work above you can continue to start and run the PCE MNC just like you would for an SNC. These steps follow.

## <a name=pce-start>Start and run the PCE</a>

##### Note: This is also the start point for a system "reset" described at the end of this document.

Start the PCE Software (on each node if running an MNC):

```
ctl start --runlevel 1
ctl status -svw
```

NOTE: if PCE doesn't have running status in a minute or two go back and check your work

If a multi-node cluster is being used, verify the Data "Master NODE" election:

```
ctldb show-master
```

NOTE: You will use the master node information in the next step. The command above will return the IP address of the master node. Do to initialize the PCE you will do so on the master data node.

## Initialize the PCE Software:
NOTE: Do the following ON THE DATABASE MASTER NODE determined FROM ABOVE

```
ctldb setup
ctl set-runlevel 5 (this will set the runlevel on all nodes)
ctl status -svw
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
ctldb create-domain --user-name user@your_domain.com --full-name 'Demo User' --org-name 'Illumio'
```

You are done.

Now, log into the system and start pairing.

The PCE is up and running at this point. You should have a clean, freshly installed system ready to pair workloads.

## Set up the VEN repository.  

It is recommended that you use the cluster to also be a repository for the VEN software. This section will walk you through that process. You will need to get the VEN bundles you will need from the Illumio Support web site. They will be clearly identified in the VEN download section of the software download area. They will have a .bz2 extenstion.

Once you obtain this file copy it to the /tmp directory of the core0 node. The reason for /tmp is because ilo-pce will need access to this file and will not have the proper access unless you put it here. If you put it somewhere else just remember ilo-pce needs to read the file so permissions will need to be set. /tmp is the easiest path to success.

I am assuming you install the tar file to the /tmp directory in the examples that follow.

This command installs the PCE bundle:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/illumio-ven-bundle-NNNNNNNNN.tar.bz2 --orgs all --default --no-prompt
```

where NNNNNNNN is the build version downloaded from the web site. And if you desire to be prompted remove the --no-prompt option.

For example:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-install /tmp/illumio-ven-bundle-19.3.0-6104.tar.bz2 --orgs all --default --no-prompt
```

to set it as the default, you'd run this:

```
sudo -u ilo-pce illumio-pce-ctl ven-software-release-set-default 19.3.0-6104
```

## PAIRING VENs for LINUX Examples

```
/opt/illumio_ven/illumio-ven-ctl activate \
--management-server https://[management-server]:8443 \
--activation-code [your activation code] \
--mode illuminated

/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server https://[management-server]:8443 \
 --activation-code [your activation code] \
 --mode illuminated

You can use environment variables (CHEF/PUPPET/ANSIBLE):
VEN_MANAGEMENT_SERVER=[management-server]:8443 \
VEN_ACTIVATION_CODE=[your activation code] \
VEN_INSTALL_ACTION=activate \
rpm -ivh illumio-ven*.rpm

VEN_MANAGEMENT_SERVER=[management-server]:8443 \
VEN_ACTIVATION_CODE=[your activation code] \
VEN_INSTALL_ACTION=enforcing \
/opt/illumio_ven/illumio-ven-ctl

/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server [management-server]:8443 \
 --activation-code [your activation code]\
 --mode enforced
 
/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server [management-server]:8443 \
 --activation-code [your activation code]\
 --mode illuminated

VEN_MANAGEMENT_SERVER=[management-server]:8443 VEN_ACTIVATION_CODE=[your activation code] VEN_INSTALL_ACTION=activate rpm -ivh illumio-ven*.rpm

To remove an RPM use the -e option with the software that is installed on the system:
rpm -e illumio-ven-17.2.0-20170809013111c7.x86_64

Solaris:
/opt/illumio_ven/illumio-ven-ctl activate --management-server pcecluster.poc.segmentationpov.com:8443 --activation-code [your activation code] --mode illuminated
```

## UNPAIRING A LINUX VEN

```
/opt/illumio_ven/illumio-ven-ctl –help

Reveals:

Usage:  {activate|backup|check-env|conncheck|connectivity-test|deactivate|gen-supportreport|prepare|restart|restore|start|status|stop|suspend|unpair|unsuspend|version|workloads}

So what you are going to want to do is this:

/opt/illuimo_ven/Illumio-ven-ctl unpair open

Other options for unpairing are:

/opt/illumio_ven/illumio-ven-ctl unpair --help

usage: /opt/illumio_ven/admin/unpair.sh option

This script will remove this workload from Illumio and
apply the selected interim firewall policy option.

Note: Interim firewall policy is non-persistent and will only be in effect
      until the workload restarts.

Options:
   <no option>    Display this help menu.

   recommended    Remove all firewall rules and apply recommended policy (Allow SSH/22 and ICMP only).

   saved          Remove all applied Illumio rules and policy from the current firewall

   open           Remove all firewall rules and leave all ports open.

The Windows version will be similar in command structure (See below)
```

## PAIRING VENs for WINDOWS Examples

All of the following is done via Powershell. You need to run Powershell as **ADMINISTRATOR**.

The VEN admin files are stored here: c:/program files/illumio/admin/*

When installing the MSI package use this method so there is a log of the install:

```
msiexec /i ven-install.msi /qn /l*vx VENInstaller.log
```

This allows you to run scripts from the command line:

```
Set-ExecutionPolicy -Scope process remotesigned -Force;
```

### This is typical for a repo:

```
Set-ExecutionPolicy -Scope process remotesigned -Force; Start-Sleep -s 3; (New-Object System.Net.WebClient).DownloadFile("[management-server]/17.2-lfIrs0yeKQ8mcOpdnIpLQ5AFzyB/pair.ps1", "$pwd\Pair.ps1"); .\Pair.ps1 -repo-host repo.illum.io -repo-dir 17.2-lfIrs0yeKQ8mcOpdnIpLQ5AFzyB/ -repo-https-port 443 -management-server demo4.illum.io:443 -activation-code  [your activation code]; Set-ExecutionPolicy -Scope process undefined -Force;
```

This command is located in c:/windows/program files/illumio/   (not bin)

1. Install the MSI package
2. cd c:\windows\program files\illumio
3. ./illumio-ven-ctl activate -management-server [management-server]:8443 -activation-code  [your activation code]

If you get a certificate error you may have to install the certificate bundle. [Find out how to install bundle on Windows with this link](
http://www.thewindowsclub.com/manage-trusted-root-certificates-windows).

If you want to see the filters Once the VEN is installed on Windows: the "iptables --list -an" eqivalent Windows command is: "**netsh wfp show filters**"

To unpair a windows workload:

```
c:/program files/illumio/admin/unpair.ps1 open
```

## runtime_env settings and suggested settings
NOTE: I strongly recommend you consider adding the following to the runtime_env.yml file.
Especially the internal_service_ip option. If you do no bind to an IP address and let the
PCE decide for itself things can get weird if you have multiple IP addresses or non RFC1918
addresses in use. If you do not specify an IP address and there are multiple addresses in
use the PCE will use the highest numbered interface. Don't let it choose this on it's own.

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
#- accepted
```

## UPGRADE PROCESS

The abbreviated (snc) upgrade process is as follows:

Note: new in 19.3+ the PCE base and UI software are separate packages. Keep in mind that when updating both the PCE and UI in order to make sure you have all the dependencies put both on the RPM update as I've indicated below so you get it all without error messages. This is not clear in the current documenation so I've made a note of it here. It's optional for an RPM update so I've made it look that way.

for the PCE base software:
```
ctl status
ctldb dump --file /tmp/<serial_number>_pce_database
cp /etc/illumio-pce/runtime_env.yml /tmp/<serial_number>_runtime_env.yml
ctl stop
rpm -Uvh illumio-pce-19.3.0-16584.x86_64.rpm [<substitute_illumio_pce_UI_install_filename_here.rpm>]
ctlenv check
ctl start --runlevel 1;ctl status -svw
```
-- wait for the nodes to come up in run level 1 state
To figure out which DB is the DB "master":
```
ctldb show-master
```
Do the following on the master database node only:
```
ctldb migrate
ctl set-runlevel 5; ctl status -svw
```
Once the nodes are all running in run level 5 the PCE will be accessible.

Upgrading the PCE UI software:
```
rpm -Uvh <substitute_illumio_pce_UI_install_filename_here.rpm>
```

## Preparing the PCE environment for production (hardening)

### SUMMARY

Note: This document is intended for technical users who will be implementing the solution described below. This document is not intended for non-technical audiences. Refer to the Illumio Security Alert: Insecure Network Transmission (KB article 2894) which is intended for Security professional and non-technical audience. See the Frequently Asked Questions section below for more information.

Supported PCE Versions: 17.1.x, 18.2.x, and later

### INTRODUCTION
When the Illumio Policy Compute Engine (PCE) is deployed in a multi-node cluster, there are several connections between PCE components running on different nodes.

Within the cluster, connections may be encrypted or plaintext. Some plaintext connections can contain user and system credentials and other sensitive data. Depending on the customer network configuration, this data may be interceptable on the wire using packet sniffers, network taps, or similar tools. This risk exists in PCE multi-node cluster deployments. Splitting the cluster’s nodes across data centers or WAN links may increase this risk, especially if the WAN links are accessible by third parties.

This risk applies only to connections between nodes in one PCE cluster. The following are NOT impacted:

1. Connections to the PCE by the Virtual Enforcement Node (VEN) or web console. These always use TLS.
1. Connections between PCE clusters in a supercluster configuration. These always use TLS.
1. Single-node cluster (SNC) deployments, which do not make any outbound connections.
1. Customers using Illumio’s SaaS Cloud Edition PCE. This applies only to on-premise customer deployments.

Technically speaking, on the IIlumio PCE cluster, REST API over HTTPS calls are received by a PCE core node. The HTTPS (TLS/SSL) portion is terminated on the core node. Subsequently, some intra-cluster communication (between PCE nodes) happens over TLS, and some intra-cluster communication occurs using plaintext protocols. For example, if a REST call needs to be load balanced to the other core node, the REST call is forwarded using HTTP (plaintext). If the other PCE core node is in a different data center, then the REST traffic could potentially could be sent over a insecure (e.g. shared) WAN link. REST calls contain an Authentication header, which has a base64-encoded username:password string. If this plaintext traffic is snooped on the WAN link, then it's possible for the authentication data to be read.

### ILO-PIPGEN for single-node security

When the Illumio Policy Compute Engine (PCE) is deployed on-premise, there are several connections between PCE components running on different nodes. Illumio recommends restricting connectivity to PCE hosts such that connections to these components cannot be made from external sources.

All PCE components listen for connections on TCP and UDP ports in stable, documented ranges. Illumio requires that all PCE nodes be allowed to communicate freely with each other but recommends that no other inbound connections be accepted to ports in these ranges.

Illumio ASP protects critical assets using microsegmentation, and this control can be provided to all other applications using the Virtual Enforcement Node (VEN). However, running the VEN on the hosts running Illumio’s PCE is not supported at this time for operational reasons.

Illumio has provided a utility to help customers configure iptables on each PCE host in such a way that PCE components are protected but other services are unaffected. This utility, called ilo-pipgen (attached below), can be used with new or existing PCE deployments. With this solution, inbound connections to PCE components are permitted only from other PCE hosts and not from any other sources.

To obtain and use instructions for ilo-pipgen [go here](https://support.illumio.com/knowledge-base/articles/Configuring-iptables-on-PCE-hosts-with-ilo-pipgen.html). It can also be obtained from Illumio Support, an Illumio SE or Illumio PS team members.

Here is an example of a script that I generated with a DROP policy (vs ALLOW) that will only allow the outside world to communicate inbound on 22/8443/8444 TCP. And I would remove 22 TCP in a production environment or be more strict with its usage like changing the source network. You can use this script by changing the IP address used to be your own SNC server address.

```
#
# Generated by ./ilo-pipgen on pce.illumio.test
# Tue Apr 20 10:01:16 EDT 2021
#
# Modified April 30, 2021 10:53 by John Westerman to
#   change input policy form ALLOW to DROP and add SSH
#   to the input policy for ACCEPT. All else is DROPPED.
# 

*raw

:PREROUTING ACCEPT
:OUTPUT     ACCEPT

-A PREROUTING -i lo -j NOTRACK
-A OUTPUT     -o lo -j NOTRACK

COMMIT

*filter

:INPUT   DROP
:FORWARD DROP
:OUTPUT  ACCEPT

-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT

# Allow public ports

-A INPUT -p tcp -m multiport --dports 8443,8444 -m conntrack --ctstate NEW -j ACCEPT

# Allow from 10.8.1.1

-A INPUT -p tcp -s 10.8.1.1 --dport 3100:3600 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 5100:6300 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 8000:8400 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p udp -s 10.8.1.1 --dport 8000:8400 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 11200:11300 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 24200:25300 -m conntrack --ctstate NEW -j ACCEPT

# Block all other traffic to Illumio ports

-A INPUT -p tcp --dport 3100:3600 -j DROP
-A INPUT -p tcp --dport 5100:6300 -j DROP
-A INPUT -p tcp --dport 8000:8400 -j DROP
-A INPUT -p udp --dport 8000:8400 -j DROP
-A INPUT -p tcp --dport 11200:11300 -j DROP
-A INPUT -p tcp --dport 24200:25300 -j DROP

# Insert custom rules here if desired:

-A INPUT -p tcp -m multiport --dports 22 -m conntrack --ctstate NEW -j ACCEPT

# Done

COMMIT

```

### ILO-VPNGEN for multi-node security

The file ilo-vpngen.sh can be obtained from Illumio Support, an Illumio SE or Illumio PS team member. Also reference the official web site above for all of the details. [Illumio Support for ilo-vpngen.](https://support.illumio.com/knowledge-base/articles/Enabling-encryption-with-ilo-vpngen.html)

## Reseting an environment

While rare it has been known that a false start or mis-configuration will cause a system to need to be reset. This command should be used with caution as it will reset the persistent data store and other critical data in the system. If you are using a MNC this will need to be done on every node that is in a cluster.

The command is very destructive to a running system. This is essentially starting over. All of the database contents will be irreversably deleted. [You should have a backup](#backups) of your data before doing this if that is desired.

```
sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl reset
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
