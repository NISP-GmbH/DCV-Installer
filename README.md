# Guided Installer for NICE DCV, DCV Session Manager, DCV Connection Gateway

## Supported Operating Systems

- RedHat based Linux distros (RedHat, Centos, AlmaLinux, Rocky Linux and Oracle Linux); Versions: EL7, EL8 and EL9
- Ubuntu based Linux distros; Versions: 18.04, 20.04, 22.04 and 24.04

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
wget -q https://raw.githubusercontent.com/NISP-GmbH/DCV-Installer/main/DCV_Installer.sh && /bin/bash DCV_Installer.sh
```
or
```bash
bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/DCV-Installer/main/DCV_Installer.sh)
```

## How to install DCV and DCV SM components without interaction

You need to add "--without-interaction" parameter and add extra parameters.

If you do not provide one of them, the default value will be false.

To install just DCV Server:

```bash
bash DCV_Installer.sh --without-interaction --dcv_server_install=true
```

DCV Server with GPU acceleration:

```bash
bash DCV_Installer.sh --without-interaction --dcv_server_install=true --dcv_server_gpu_nvidia=true
bash DCV_Installer.sh --without-interaction --dcv_server_install=true --dcv_server_gpu_amd=true
```

DCV Server with GPU acceleration and DCV Session Manager components:

```bash
bash DCV_Installer.sh --without-interaction --dcv_server_install=true --dcv_server_gpu_nvidia=true --dcv_broker=true --dcv_agent=true --dcv_cli=true --dcv_gateway=true --dcv_firewall=true
``` 

DCV Server without GPU and without OS packages upgrades:
```bash
bash DCV_Installer.sh --without-interaction --dcv_server_install=true --enable_os_upgrade=false
```

## Possible parameters
- __--without-interaction :__ Do everything without interaction
- __--dcv_server_install=true :__ Install DCV Server
- __--dcv_broker=true :__ Install DCV Broker
- __--dcv_agent=true :__ Install DCV Agent
- __--dcv_cli=true :__ Install DCV CLI
- __--dcv_gateway=true :__ Install DCV Gateway
- __--dcv_firewall=true :__ Allow TCP/UDP ports in firewalld
- __--dcv_server_gpu_nvidia=true :__ Setup NVIDIA driver
- __--dcv_server_gpu_amd=true :__ Install AMD driver
- __--enable_os_upgrade=false :__ Allow OS packages upgrade or not
- __--force :__ If your distribution version is not being recognized, you can try to force the setup
