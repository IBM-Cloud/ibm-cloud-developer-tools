# IBM Developer Tools CLI Installer (idt-installer)

[![](https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg)](https://bluemix.net)
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

This script performs an installation of the IBM Developer Tools CLI environment. The IDT consists of the 'dev' (and several other) plugins to the IBM Cloud CLI. Our general target environment is the IBM Cloud, including public, dedicated, and local hybrid.


## Installation
Before running the installation script, you should set this environment variable if you plan to deploy to Kubernetes so that the version of Helm that is installed is compatible with the Helm server version.

```
export DESIRED_VERSION=v2.4.2
```

To install the IBM Cloud Developer Tools CLI, run the following command:

```
$ curl -sL https://ibm.biz/idt-installer | bash
```

Once complete, there will be three added shortcuts defined to access the IDT:
- `idt` : Main command line tool for IBM cloud native development (shortcut to 'bx dev' command)
- `idt update` : Update your IDT environment to the latest versions
- `idt uninstall` : Uninstall the IBM Developer Tools


### Debugging

If you have any issues with the instaler, try running with the `--trace` argument which will produce verbose output to assist us in diagnosing your problem:

```
curl -sL https://ibm.biz/idt-installer | bash -s -- --trace
```

If updating an existing IDT installation, you can run the following:
```
idt update --trace
```


## Updating

If you wish to update the IBM Developer Tools CLI, run `idt update`. There is also a `--force` (or `-f`) argument that will force update to all dependencies too.

This command is simply an alias defined during initial install that runs the installer shown here:

```
$ curl -sL https://ibm.biz/idt-installer | bash -c -- [--force]
```

## Uninstall

If you wish to remove the IBM Developer Tools CLI, run `idt uninstall`. This command is simply an alias defined during install that runs the following:

```
$ curl -sL https://ibm.biz/idt-installer | bash -s uninstall
```


## Pre-Requisites

The script will check for the following prereqs, and attempt to install them if not found.
- Git command line
- Docker command line
- Kubernetes CLI (kubectl)
- Kubernetes helm


## Usage
```
Usage: idt-installer [<args>]

Where <args> is:
    install             [Default] Perform full install (or update) of all needed CLIs and Plugins
    uninstall           Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    help | -h | -?      Show this help
    --force | -f        Force updates of dependencies and other settings during update
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

## Platforms

The following are platform specific concerns and notes you should be aware of.

Note: Previous versions of this installer set up aliases within you shell env (ie ~/.bashrc). Current version have switched over to use a wrapper shell scripty (/usr/local/bin/idt) to achieve better results. The old env entries are automatically removed.


### MacOS

The installer uses the "homebrew" utility, and it will be installed as needed.

### Linux

This script has only been tested on Ubuntu Linux systems, although it should behave properly on other distros that use 'apt-get'. 

If you run into any issues, please let us know on [IBM Cloud Tech Slack](https://slack-invite-ibm-cloud-tech.mybluemix.net/) - #developer-tools channel, or file an issue on our [GitHub repo](https://github.com/IBM-Cloud/ibm-cloud-developer-tools/issues).


### Windows

**WARNING**: Windows is not supported by this installer.  See the [Windows installation](../windows-installer/README.md) for additional information.



## Internal IBM users

IBM users can use pre-release versions of the IDT (bx and all plugins). The installer will check if you have the internal "stage1" plugin repo defined, and ask if you want to use it for updates.  Note: Since during initial install of the bx CLI does not have extra plugin repos defined, it only applies during subsequent updates.

