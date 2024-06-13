# Installer for DCV, DCV Session Manager, DCV Connection Gateway

## Supported Operating Systems

- RedHat based Linux distros (RedHat, Centos, AlmaLinux, Rocky Linux etc); Versions: EL7, EL8 and EL9
- Ubuntu based Linux distros; Versions: 18.04, 20.04 and 22.04

## Which services can be installed and configured

The script guides you through the different steps and asks you which components you want to install:

- DCV Server without GPU support
- DCV Server with GPU support (NVIDIA or AMD (on-request))
- DCV Session Manager Broker
- DCV Session Manager Agent
- DCV Session Manager Gateway
- DCV Session Manager CLI
- firewalld rules

Notes:
- For every service you will be asked if you want to install or not. And for the services that you answer yes, you will be asked about the ports to be used.
- If you do not want to add firewalld rules, just answer no for firewall configuration.

## How to install the DCV Services

The script to execute the Installer for the different compenents is:

```bash
/bin/bash DCV_Session_Manager_Installer.sh
```
## How to customize the DCV_Session_Manager_Installer.sh

If you need to customize anything, you can edit the following files:
- head.txt: script head (before any code)
- main.sh: the place where all functions will be called
- tail.txt: if main.sh does not exit with any exit code, the tail.txt code will be executed
- library.sh: where all bash functions live

After any customization, you can use create_end_user_script.sh script to create your customized DCV_Session_Manager_Installer.sh installer.
