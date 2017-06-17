# IBM Cloud Developer Tools CLI Installer (idt-installer)

[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)
![Platform](https://img.shields.io/badge/platform-SWIFT-lightgrey.svg?style=flat)
![Platform](https://img.shields.io/badge/platform-BASH-lightgrey.svg?style=flat)


### Table of Contents
* [Summary](#summary)
* [Install](#installation)
* [Updating](#updating)
* [Uninstall](#uninstall)
* [Pre-Requisites](#pre-requisites)
* [Usage](#usage)


## Summary

This script performs an installation of the IBM Cloud developer CLI environment.


## Installation
To install the IBM Developer Tools CLI, run the following command:

```
$ curl https://idt-installer.mybluemix.net/ | bash
```

Once complete, there will be three aliass defined to access the IDT:
- `idt` : Main command line tool for IBM Cloud Native development
- `idt-update` : Update your IDT tools to the latest version
- `idt-uninstall` : Uninstall the IBM Developer Tools

Note: You will need to reload your bash environment (ie `. ~/.bashrc`) to access these commands.


## Updating

If you wish to update the IBM Cloud Developer Tools CLI, run `idt-update`. This command is simply an alias defined during install that runs the same install action shown above:

```
$ curl https://idt-installer.mybluemix.net/ | bash -c uninstall
```

## Uninstall

If you wish to remove the IBM Cloud Developer Tools CLI, run `idt-uninstall`. This command is simply an alias defined during install that runs the following:

```
$ curl https://idt-installer.mybluemix.net/ | bash -c uninstall
```


## Pre-Requisites

The script will check for the following prereqs, and attempt to install them if not found.
- Git command line
- Docker command line
- Kubernetes CLI (kubectl)


## Usage
```
Usage: idt-installer [<action>]

Where <action> is:
    install             [Default] Perform full install of all needed CLIs and Plugins
    uninstall           Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    -? | -h | --help    Show this help

If "install" (or no argument provided), a full CLI installation will occur:
    1. Pre-req check for 'git', 'docker', and 'kubectl'
    2. Install IBM Cloud 'bx' CLI
    3. Install required plugins

If "uninstall", the IBM Cloud CLI and plugins are removed from the system, including personal metadata.
    Note: Pre-req CLIs listed above are NOT uninstalled.

```

### Windows Warning

Windows has not been tested AT ALL.  If you can try it, and report all failures directly to the author, that will help us get this available for real Windows users.

Additionally, Windows users must have Bash installed at this time.  If you're willing to port this installer to PowerShell, please do!


