# IBM Cloud Developer Tools

[![](https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg)](https://bluemix.net)

This repo provides support for the IBM Cloud Developer Tools (IDT) CLI environment. The IDT tools currently consists of the IBM Cloud CLI (bx) 'dev' and other plugins, as well as extensions to multiple IDEs.

These tools work for the following environments:
- [IBM **Cloud** Public](https://www.ibm.com/cloud-computing/)
- [IBM **Cloud** Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/)
- [IBM **Cloud** Dedicated](https://www.ibm.com/cloud-computing/bluemix/dedicated)
- [IBM MicroService Builder](https://developer.ibm.com/microservice-builder/)

If you run into any issues, please let us know on the [IBM Cloud Tech Slack :: #developer-tools](https://slack-invite-ibm-cloud-tech.mybluemix.net/) or file an issue on our [GitHub repo](https://github.com/IBM-Cloud/ibm-cloud-developer-tools).



## IDT MacOS &amp; Linux Installation

The following command will install the IBM Cloud Developer Tools in a single invocation. Open up a terminal and run the following command:

```
$ curl -sL https://ibm.biz/idt-installer | bash
```

Once complete, there will be three shortcuts defined to access the IBM Cloud Developer Tools:
- `idt` : Main command line tool. Shorthand for 'bx dev' command
- `idt update` : Update your IBM Cloud Developer Tools to the latest versions
- `idt uninstall` : Uninstall the IBM Cloud Developer Tools

Access the [platform-specific readme](./linux-installer/README.md) for additional details.



## IDT Windows Installation

To install the IBM Cloud Developer Tools CLI on Windows 10 or newer:

1. Open Windows PowerShell by right-clicking and select "Run as Administrator".
2. Run this command:
```
Set-ExecutionPolicy Unrestricted; iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')
```

Access the [Windows-specific readme](./windows-installer/README.md) for additional details.


## 3rd Party IDE Extensions

The following IDE extensions are available to enable access to IDT CLI directly from within the IDE.

- [Visual Studio Code](https://code.visualstudio.com/) editor - [IBM Developer Tools extension](https://marketplace.visualstudio.com/items?itemName=IBM.ibm-developer)
- [Jetbrains](https://www.jetbrains.com) based IDEs (IntelliJ, WebStorm, Android Studio, etc) - [External Tools Settings](./jetbrains)

Notice: These extensions are provided "as-is". IBM does not explicitly endorse, nor support these 3rd party products. Although we will attempt to answer questions through our Slack channel, because we want you to succeed and be happy.



## Feedback

We can be reached in the following ways.  We encourage and welcome all feedback and suggestions
- [IBM Cloud Tech Slack](https://slack-invite-ibm-cloud-tech.mybluemix.net/): Find us on the `#developer-tools` channel
- [IBM Cloud Developer Tools GitHub repo](https://github.com/IBM-Cloud/ibm-cloud-developer-tools): Use to file any issues specific to installation of the tools or the IDE extensions.

