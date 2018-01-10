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

PowerShell script that downloads and installs the IBM Cloud Developer Tools (IDT) CLI Plugin and all of its dependencies on Windows 10 or newer systems. The IDT consists of the 'dev' (and several other) plugins to the IBM Cloud CLI. Our general target environment is the IBM Cloud, including public, dedicated, and local hybrid.


## Installation

### Single-line Running
This action will install (or update) the IBM Cloud Developer Toolsto your windows system in a single command.

1. Open Windows PowerShell by right-clicking and select "Run as Administrator".
2. Run this command:
```
Set-ExecutionPolicy Unrestricted; iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')
```

Once the installation has completed, and you have rebooted your system (as needed), there will be three added shortcuts defined to access the IDT:
- `idt` : Main command line tool for IBM cloud native development (shortcut to 'bx dev' command)
- `idt update` : Update your IDT environment to the latest versions
- `idt uninstall` : Uninstall the IBM Developer Tools


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

If updating an existing IDT installation, you can run the following:
```
idt update --trace
```


## Updating

If you wish to update the IBM Developer Tools CLI, run:

```
idt update [--force] [--trace]
```

The `--force` argument that will force update to all dependencies too.

This command is simply a shortcut defined during initial install that runs (in admin mode) the installer as shown here:

```
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted ""iex(New-Object Net.WebClient).DownloadString(""""http://ibm.biz/idt-win-installer"""")"" ""%2"" ""%3"" ' -Verb RunAs}"
```

## Uninstall

If you wish to remove the IBM Developer Tools CLI, run:

```
idt uninstall [--trace]
```

This command is simply a shortcut defined during install that runs (in admin mode)  the installer's uninstall action as shown here:

```
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted ""iex(New-Object Net.WebClient).DownloadString(""""http://ibm.biz/idt-win-installer"""")"" ""uninstall"" ""%2"" ' -Verb RunAs}"
```


## Pre-Requisites

The script will check for the following prereqs, and attempt to install them if not found.
- Git command line
- Docker command line
- Kubernetes CLI (kubectl)
- Kubernetes helm


## Usage
```
Usage: idt-win-installer [<args>]

Where <args> is:
    install | update    [Default] Perform full install (or update) of all needed CLIs and Plugins
    uninstall           Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    help | -h | -?      Show this help
    --force             Force updates of dependencies and other settings during update
    --trace             Eanble verbose tracing of all activity


If "install" (or no action provided), a full CLI installation (or update) will occur:
  1. Pre-req check for 'git', 'docker', 'kubectl', and 'helm'
  2. Install latest IBM Cloud 'bx' CLI
  3. Install all required plugins
  4. Defines aliases to improve useability
      - idt : Shortcut for normal "bx dev" command
      - idt update : Runs this installer checking for and installing any updates
      - idt uninstall : Uninstalls IDT, including the 'bx cli' and all plugins

If "uninstall", the IBM Cloud CLI and plugins are removed from the system, including personal metadata.
    Note: Pre-req CLIs listed above are NOT uninstalled.

Chat with us on Slack: https://slack-invite-ibm-cloud-tech.mybluemix.net/
Submit any issues to : https://github.com/IBM-Cloud/ibm-cloud-developer-tools/issues

```


## Internal IBM users

IBM users can use pre-release versions of the IDT (bx and all plugins). The installer will check if you have the internal "stage1" plugin repo defined, and ask if you want to use it for updates.  Note: Since during initial install of the bx CLI does not have extra plugin repos defined, it only applies during subsequent updates.


