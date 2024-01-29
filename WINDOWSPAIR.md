## Examples for PAIRING VENs (PEP) software for WINDOWS.

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

### This is typical pulling from VEN (PEP) repository:

This script would be pulled from a "pairing profile" from the Policy Engine (PDP):

```
Set-ExecutionPolicy -Scope process remotesigned -Force; Start-Sleep -s 3; (New-Object System.Net.WebClient).DownloadFile("[management-server]/17.2-lfIrs0yeKQ8mcOpdnIpLQ5AFzyB/pair.ps1", "$pwd\Pair.ps1"); .\Pair.ps1 -repo-host repo.illum.io -repo-dir 17.2-lfIrs0yeKQ8mcOpdnIpLQ5AFzyB/ -repo-https-port 443 -management-server demo4.illum.io:443 -activation-code  [your activation code]; Set-ExecutionPolicy -Scope process undefined -Force;
```
### Doing the VEN (PEP) pairing by hand.

This command to run the pairing by hand is located in "c:\Program Files\Illumio" (not bin)

1. Install the MSI package located in the VEN repository or downloaded from the Illumio support site.
2. cd "c:\Program Files\Illumio"
3. .\illumio-ven-ctl activate -management-server [management-server]:8443 -activation-code  [your activation code]

If you get a certificate error you may have to install the certificate bundle. [Find out how to install bundle on Windows with this link](
http://www.thewindowsclub.com/manage-trusted-root-certificates-windows).

If you want to see the filters Once the VEN is installed on Windows: the "iptables --list -an" equivalent Windows command is: "**netsh wfp show filters**"

### Deactivating a VEN.

To deactivate a Windows VEN:

Deactivating a VEN will "unpair" the VEN from the PCE without removing the VEN software from the host. This can be done when unpairing is desired with a subsequent repair with a different pairing profile.

```
PS C:\Program Files\Illumio> .\illumio-ven-ctl.ps1 deactivate
```

### Unpairing a VEN enabled workload.

To "unpair" a windows workload:

"Unpairing" a VEN like we are doing here will perform both an unpair operation as well as full software removal. In the example below it will also remove any rules and put the machine in a completely open state without any firewalling at the kernel.

```
"c:/program files/illumio/admin/unpair.ps1" open
```
[Options for unpairing the VEN can be find here.](OPTIONSPAIR.md)