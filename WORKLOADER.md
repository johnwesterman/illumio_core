# Workloader Documentation

These are my personal notes on workloader.

## Obtaining software.

You can download the software from support.illumio.com or get the software from your SE. For this exercise I am using Version 12.1.6.

## Using software.

The software is command line driven. There is no UI.

To get help you can issue a command like:

Linux
```
workloader --help
```
Windows
```
workloader.exe --help
```

## Adding a PCE

The first thing you want to do is add your PCE.

These steps will use your username and password *to create an API key automatically*.

```
workloader pce-add
```

Will start to ask you lots of questions:

```
Default values will be shown in [brackets]. Press enter to accept default.

Name of PCE (no spaces or periods) [default-pce]: YOUR PCE NAME HERE
PCE FQDN: FULLY QUALIFIED DOMAIN NAME (no https://, just the name)
PCE Port: The port you are using. If SaaS it will be 443. If on-premise you will use the ports you defince. By default, 8443.
Email: YOUR LOGIN EMAIL
Password: YOUR LOGIN PASSWORD
Disable TLS verification (true/false) [false]: THIS A SECURITY TOOL. DO NOT DISABLE.
```

Once you answer all the above properly the system will create a YAML files named pce.yaml. Inside of that file these paramaters will be stored. Remember to keep that file both safe and in a location it can be used. It will inherit the same credential privilege as the use who created it.

Once it is created you can use the rest of the commands available to workloader.

## Adding PCE using API-KEY credentials.

The other way to add credentials is to use a slightly different format for the pce-add command.

It will take the form:

```
workloader pce-add -a --api-user api_username --api-secret API_SECRET
```

In order to get the API username and secret you have to log into the PCE, pull down your profile setings (top right) and select "My API KEYS". From there you can create a key-pair. Once you have the key-pair created use the command above or if you want to do it interactively:

```
workloader pce-add --api-key
```

Will walk you through similar prompts:

```
Default values will be shown in [brackets]. Press enter to accept default.

Name of PCE (no spaces or periods) [default-pce]: YOUR PCE NAME HERE
PCE FQDN: FULLY QUALIFIED DOMAIN NAME (no https://, just the name)
PCE Port: The port you are using. If SaaS it will be 443. If on-premise you will use the ports you defince. By default, 8443.
API Authentication Username: The API username (api_xxxxxx) created in the key creation process.
API Secret: The associated API key created in the key creation process.
Org: Your ORGANIZATION number
Disable TLS verification (true/false) [false]: THIS A SECURITY TOOL. DO NOT DISABLE.
```

## Example usage.

Lets say you wanted to increase the VEN update rate for an application call "HR". The command would be as follows:

```
workloader increase-ven-rate --app HR
```

For Windows version of workloader:

```
workloader.exe increase-ven-rate --app HR
```


This command would tell the PCE to update the VEN update rate for anything with the applicatin label of "HR". If you want to be more specific you can add any of the other labels associated with a workload.

## Conclusion

Following the steps above will get workloader setup and ready to use. This document does not go into the full usage of the tool but it is fairly self explaining once you get comfortable with the tool.