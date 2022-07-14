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

[Options for unpairing the VEN can be find here.](OPTIONSPAIR.md)