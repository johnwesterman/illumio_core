## PAIRING VENs for LINUX Examples

### Example of VEN pairing and activating in IDLE mode
```
/opt/illumio_ven/illumio-ven-ctl activate \
--management-server [management-server]:8443 \
--activation-code [your activation code] \
--mode idle
```
``` 
/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server [management-server]:8443 \
 --activation-code [your activation code]\
 --mode illuminated
```
### Example of VEN pairing and activating in VISIBILITY mode
```
/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server https://[management-server]:8443 \
 --activation-code [your activation code] \
 --mode illuminated
```
### Example of VEN pairing and activating in VISIBILITY mode using AUTOMATION
```
You can use environment variables (CHEF/PUPPET/ANSIBLE):
VEN_MANAGEMENT_SERVER=[management-server]:8443 \
VEN_ACTIVATION_CODE=[your activation code] \
VEN_INSTALL_ACTION=activate \
rpm -ivh illumio-ven*.rpm
```
### Example of VEN pairing and activating in ENFORCING mode using AUTOMATION
```
VEN_MANAGEMENT_SERVER=[management-server]:8443 \
VEN_ACTIVATION_CODE=[your activation code] \
VEN_INSTALL_ACTION=enforcing \
/opt/illumio_ven/illumio-ven-ctl
```
```
/opt/illumio_ven/illumio-ven-ctl activate \
 --management-server [management-server]:8443 \
 --activation-code [your activation code]\
 --mode enforced
```
### Example of VEN installation, pairing and activating in ENFORCING mode using AUTOMATION for CENTOS/REHL
```
VEN_MANAGEMENT_SERVER=[management-server]:8443 VEN_ACTIVATION_CODE=[your activation code] VEN_INSTALL_ACTION=activate rpm -ivh illumio-ven*.rpm
```
### Removing VEN software with RPM
```
To remove an RPM use the -e option with the software that is installed on the system:
rpm -e illumio-ven-17.2.0-20170809013111c7.x86_64
```
```
Solaris example:
/opt/illumio_ven/illumio-ven-ctl activate --management-server pcecluster.poc.segmentationpov.com:8443 --activation-code [your activation code] --mode illuminated
```

### UNPAIRING A LINUX VEN

```
/opt/illumio_ven/illumio-ven-ctl –help
```
```
Reveals:

Usage:  {activate|backup|check-env|conncheck|connectivity-test|deactivate|gen-supportreport|prepare|restart|restore|start|status|stop|suspend|unpair|unsuspend|version|workloads}
```
### Unpair options
```
Unpair Options:
   <no option>    Display this help menu.

   recommended    Remove all firewall rules and apply recommended policy (Allow SSH/22 and ICMP only).

   saved          Remove all applied Illumio rules and policy from the current firewall

   open           Remove all firewall rules and leave all ports open.
```
One way to unpair is to put things back like they were before installation:

/opt/illuimo_ven/Illumio-ven-ctl unpair saved

### WINDOWS

The Windows version will be similar in command structure (See below)

[Options for unpairing the VEN can be find here.](OPTIONSPAIR.md)