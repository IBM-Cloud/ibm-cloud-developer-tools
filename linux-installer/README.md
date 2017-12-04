# IBM Developer Tools CLI Installer (idt-installer)

[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)
![Platform](https://img.shields.io/badge/platform-BASH-lightgrey.svg?style=flat)

### Table of Contents
* [Summary](#summary)
* [Install](#installation)
* [Updating](#updating)
* [Uninstall](#uninstall)
* [Pre-Requisites](#pre-requisites)
* [Usage](#usage)
* [Platform specific concerns](#platforms)
    * [MacOS](#macos)
    * [Linux](#linux)
    * [Windows](#windows)
* [Internal IBM users](#internal-ibm-users)


## Summary

This script performs an installation of the IBM Developer Tools CLI environment. The IDT is a plugin to the IBM Bluemix CLI. Our general target environment is the IBM Cloud, including public, dedicated, and local hybrid.


## Installation
Before running the installation script, you should set this environment variable if you plan to deploy to Kubernetes so that the version of Helm that is installed is compatible with the Helm server version.

```
export DESIRED_VERSION=v2.4.2
```

To install the IBM Developer Tools CLI, run the following command:

```
$ curl -sL https://ibm.biz/idt-installer | bash
```

Once complete, there will be three aliases defined to access the IDT:
- `idt` : Main command line tool for IBM cloud native development (shortcut to 'bx dev')
- `idt-update` : Update your IDT environment to the latest versions
- `idt-uninstall` : Uninstall the IBM Developer Tools

Note: You will need to either restart your terminal session, or reload your bash environment (ie `. ~/.bashrc`) to access these commands.


### Debugging

If you have any issues with the instaler, try running with the `--trace` argument which will produce verbose output to assist us in diagnosing your problem:

```
curl -sL https://ibm.biz/idt-installer | bash -s -- --trace
```


## Updating

If you wish to update the IBM Developer Tools CLI, run `idt-update`. This command is simply an alias defined during initial install that runs the installer shown here:

```
$ curl -sL https://ibm.biz/idt-installer | bash
```

## Uninstall

If you wish to remove the IBM Developer Tools CLI, run `idt-uninstall`. This command is simply an alias defined during install that runs the following:

```
$ curl -sL https://ibm.biz/idt-installer | bash -s uninstall
```


## Pre-Requisites

The script will check for the following prereqs, and attempt to install them if not found.
- Git command line
- Docker command line
- Kubernetes CLI (kubectl)


## Usage
```
Usage: idt-installer [<args>]

Where <args> is:
    install             [Default] Perform full install (or update) of all needed CLIs and Plugins
    uninstall           Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    help | -h | -?      Show this help
    --nobrew            Force not using brew installer on MacOS
    --trace             Eanble verbose tracing of all activity


If "install" (or no action provided), a full CLI installation (or update) will occur:
  1. Pre-req check for 'git', 'docker', 'kubectl', and 'helm'
  2. Install latest IBM Cloud 'bx' CLI
  3. Install all required plugins
  4. Defines aliases to improve useability
      - idt : Shortcut for normal "bx dev" command
      - idt-update : Runs this installer checking for and installing any updates
      - idt-uninstall : Uninstalls 'bx cli' and all plugins

If "uninstall", the IBM Cloud CLI and plugins are removed from the system, including personal metadata.
    Note: Pre-req CLIs listed above are NOT uninstalled.

Chat with us on Slack: https://ibm.biz/IBMCloudNativeSlack
Submit any issues to : https://github.com/ibm-cloud-tools/idt-installer

```

## Platforms

The following are platform specific concerns and notes you should be aware of.

### MacOS

By default, this installer will use the 'brew' installer if it is available. You can use the `--nobrew` argument to disable use of 'brew'. Note that you must be consistent with the use of `--nobrew` when installing, updating, and uninstalling.

### Linux

This script has only been tested on Ubuntu Linux systems, although it should behave properly on other distros. If you run into any issues, please let us know on [Slack](https://ibm.biz/IBMCloudNativeSlack) or file an issue on our [GitHub repo](https://github.com/ibm-cloud-tools/idt-installer).


### Windows

**WARNING**: Windows is not supported by this installer.  See the [Windows installation](../windows-installer/README.md) for additional information.



## Internal IBM users

IBM users can utilize this installer pulling the Bluemix CLI and plugins from pre-release internal servers. In order to have the installer utilize internal servers, set the following environment variables (eg in `~/.bashrc`), substituting the proper internal URLs. Shown below are the default public URLs:

```
export IDT_INSTALL_USE_PROD=true
export IDT_INSTALL_BMX_URL="https://clis.ng.bluemix.net/install"
export IDT_INSTALL_BMX_REPO_NAME="internal"
export IDT_INSTALL_BMX_REPO_URL="https://plugins.ng.bluemix.net"
```

If you need assistance on the proper values, just ask in any of the IBM internal slack channels.
