# IBM Developer Windows Installer

PowerShell script that downloads and installs the Developer Bluemix CLI Plugin and all of its dependencies.

## Single-line Running

1. Open Windows PowerShell by right-clicking and select "Run as Administrator".
2. Run this command:
```
Set-ExecutionPolicy Unrestricted; iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')
```

## Running from Download

1. Download or clone this repository.
2. Open Windows PowerShell by right-clicking and selecting "Run as administrator".
3. Change directory to wherever the `idt-win-installer.ps1` script is.
4. Run the command:
```
Set-ExecutionPolicy Unrestricted
```
5. Run the command:
```
.\idt-win-installer.ps1
```