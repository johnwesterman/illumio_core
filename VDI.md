```
Author: John Westerman, Illumio, Inc.
Monday March 04, 2024 09:00

Changed:
1. First version of these words.
```

# VDI Deployment best practice

## Software requirements

There are several software requirements:

1. VEN client software. The new method below should use software version 23.2.22 or above. 
2. [Workloader software](https://github.com/brian1917/workloader)
3. If you are using the older method described below you will also need [the logout script which can be downloaded from the support site with proper credentials](https://support.illumio.com/tools/citrix-ven-vdi-image-preparation-script/index.html)

## Two ways to deploy

### The old(er) way

It is important to note that using this method requires you to use a pairing profile for each golden image you plan on using.

1. Create a pairing profile using applying the labels you want for the VDI instance.
2. Install the VEN like you normally would on the golden image.
3. When the user shuts down the VDI session the [logout script](https://support.illumio.com/tools/citrix-ven-vdi-image-preparation-script/index.html) will need to be invoked to unpair the workload and put the image in a pre-paired state.
4. Occasionally, [workloader will be run](#workloader) to clean up any VDI orphans. This will be placed in a cron job on one of the PCE nodes or another machine dedicated to this task.

### The new way

Starting with VEN software 23.2.22 it is no longer required to use a shutdown PowerShell script.

1. Pair the VEN on the Golden image and label as needed.
2. Install the VEN like you normally would on the golden image. There is no need to use the logout script mentioned above in this process.
3. After the golden image is shutdown and the snapshot is taken, the golden image must be turned back on.
4. [Workloader will be run daily](#workloader) to clean up any VDI orphans. This will be placed in a cron job on one of the PCE nodes or another machine dedicated to this task.
5. The enforcement state of the golden image workload object in the PCE is how you change the enforcement state of the non-persistent VDI clones.

### Workloader

To check for orphaned VENs using workloader you will use this command structure:

```
workloader unpair --hours 40 --app [YOUR APPLICATION LABEL] --env [YOUR APPLICATION LABEL] --restore saved --update-pce --no-prompt
```

## Illumio Documentation

The official [documenation for VDI is located online here](https://docs.illumio.com/core/23.5/Content/Guides/security-policy/security-policy-objects/adaptive-user-segmentation.htm).