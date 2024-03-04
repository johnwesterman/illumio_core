### Options for unpairing

**recommended**: Uninstalls the VEN and temporarily allows only SSH/22 until reboot.

Security implications: If this workload is running a production application, it could break because this workload will no longer allow any connections to it other than SSH on port 22.

**saved**: Uninstalls the VEN and reverts to pre-Illumio policy from when the VEN was first installed. Revert the state of the workload's iptables to the state they were in at the moment before the VEN was installed. The dialog will display the amount of time that has passed since the VEN was installed.

Security implications: Depending on how old the iptables configuration are on the workload, VEN removal could impact the application.

**open**: Uninstalls the VEN and leaves all ports on the workload open.

Security implications: If iptables or Illumio were the only security being used for this workload, the workload will be opened up to anyone and become vulnerable to attack.
