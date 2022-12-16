## Automation of an install

There are a number of ways to automate an install. The way I am going to show you is how to script this using a standard unix shell (sh).

For this example there are 2 main scripts:

1. `copy_files.sh` - copies all the software to the CentOS host.
2. `setup.sh` - runs a "hands off" installation.

### A note on software you need to provide.

The scripts are going to assume you are providing:

1. A single RPM for PCE Core has been provided
1. A single RPM for PCE UI has been provided
1. A single VEN Bundle file has been provided if it is desired to be installed.
1. The latest compatibility matrix.

Put these files in the current working directory. They will be copied to the proper locations on the CentOS host by the copy_files.sh script. These files will be used by the setup.sh script that is copied in the root directory of the CentOS host.

Once the copy_files.sh script is run login as root to the CentOS host and run the setup.sh script located in the /root directory. If you like the defaults set up in the script it will run as-is. Or modify to your liking.

As a side note, I used the resizing scripts to resize a hard drive system for a project I was working on which had to be delivered on a DVD. Once onsite, the resizing expands the physical and virtual volumes of a hard drive system. You don't need them if you have already set up your hard drive to the size of your liking.