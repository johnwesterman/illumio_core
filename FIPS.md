```
Author: John Westerman, Illumio, Inc.
Friday May 03, 2024 10:16

Changed:
1. First version of these words.
```

# Running OS in FIPS mode

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
