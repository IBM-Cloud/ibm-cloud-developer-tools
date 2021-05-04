# IBM Developer Tools CLI Installer (idt-installer) for Windows

[![](https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg)](https://bluemix.net)
![Platform](https://img.shields.io/badge/platform-Powershell-lightgrey.svg?style=flat)

### Table of Contents
* [Summary](#summary)
* [Install](#installation)
* [Updating](#updating)
* [Uninstall](#uninstall)
* [Pre-Requisites](#pre-requisites)
* [Usage](#usage)
* [Internal IBM users](#internal-ibm-users)


## Summary

PowerShell script that downloads and installs the IBM Cloud CLI, plugins and all of its dependencies on Windows 10 or newer systems. The CLI consists of the 'dev' (and several other) plugins to the IBM Cloud CLI. Our general target environment is the IBM Cloud, including public, dedicated, and local hybrid.


## Installation

### Single-line Running
This action will install (or update) the IBM Cloud Developer Tools to your windows system in a single command.

1. Open Windows PowerShell by right-clicking and select "Run as Administrator".
2. Run this command:
```
Set-ExecutionPolicy Unrestricted; iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')
```

Once the installation has completed, and you have rebooted your system (as needed), there will be an added shortcut defined to access the IBM Cloud cli:
- `ic`: shortcut for the `ibmcloud` command


### Running from Download
Alternatively, you can use the following approach to perform an installation. This will give you an opportunity to better inspect the activities performed, especially if you are having any issues during installation (shown below).

1. Download the `idt-win-installer.ps1` file, or clone this repository.
2. Open Windows PowerShell by right-clicking and selecting "Run as administrator".
3. Change directory to wherever the `idt-win-installer.ps1` script is located.
4. Run the following commands:
```
Set-ExecutionPolicy Unrestricted
.\idt-win-installer.ps1
```

### Debugging

If you have any issues with the installer, try running with the `--trace` argument which will produce verbose output to assist us in diagnosing your problem:

```
Set-ExecutionPolicy Unrestricted
.\idt-win-installer.ps1 --trace
```

If updating an existing IBM Cloud CLI installation, you can run the following:
```
ibmcloud update
```


## Updating

If you wish to update the IBM Developer Tools CLI, run:

```
ibmcloud plugin update dev
```

This command is simply a shortcut defined during initial install that runs (in admin mode) the installer as shown here:

```
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted ""iex(New-Object Net.WebClient).DownloadString(""""http://ibm.biz/idt-win-installer"""")"" ""%2"" ""%3"" ' -Verb RunAs}"
```


## Pre-Requisites

The script will check for the following prereqs, and attempt to install them if not found.
- Git command line
- Docker command line
- Kubernetes CLI (kubectl)


## Usage
```
Usage: idt-win-installer [<args>]

Where <args> is:
    install | update    [Default] Perform full install (or update) of all needed CLIs and Plugins
    help | -h | -?      Show this help
    --force             Force updates of dependencies and other settings during update
    --trace             Eanble verbose tracing of all activity


If "install" (or no action provided), a full CLI installation (or update) will occur:
  1. Pre-req check for 'git', 'docker', and 'kubectl'
  2. Install latest IBM Cloud 'ibmcloud' CLI
  3. Install all required plugins
  4. Defines aliases to improve useability
      - ic : Shortcut for "ibmcloud" command


Chat with us on Slack: https://slack-invite-ibm-cloud-tech.mybluemix.net/
Submit any issues to : https://github.com/IBM-Cloud/ibm-cloud-developer-tools/issues

```


## Internal IBM users

IBM users can use pre-release versions of the IDT (ibmcloud and all plugins). The installer will check if you have the internal "stage1" plugin repo defined, and ask if you want to use it for updates.  Note: Since during initial install of the ibmcloud CLI does not have extra plugin repos defined, it only applies during subsequent updates.


