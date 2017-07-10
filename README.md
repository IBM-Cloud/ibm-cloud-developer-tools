# IBM Developer Windows Installer

Powershell script that downloads and installs the Developer Bluemix CLI Plugin and all of its dependencies.

# Running from Download

1. Download or clone this repository.
2. Open Windows Powershell by right-clicking and select "Run as Administrator".
3. Change directory to wherever the `idt-win-installer.ps1` script is.
4. Run the command:
```
Set-ExecutionPolicy Unrestricted
```
5. Run the command:
```
.\idt-win-installer.ps1
```

# Single-line Running

1. Open Windows Powershell by right-clicking and select "Run as Administrator".
2. Run this command:
```
Set-ExecutionPolicy Unrestricted; iex(New-Object Net.WebClient).DownloadString('https://raw.github.ibm.com/MIL/idt-windows-installer/master/idt-win-installer.ps1?token=AAACmnszZo3lFbNoxu-xATV5Yiy55Sb1ks5ZbQyrwA%3D%3D')
```