#------------------------------------------------------------------------------
# Script:  idt-win-installer
#------------------------------------------------------------------------------
# IBM Cloud Developer Tools - CLI installer script for Windows 10 systems
#------------------------------------------------------------------------------
# Copyright (c) 2018, International Business Machines. All Rights Reserved.
#------------------------------------------------------------------------------
$VERSION="1.2.0"
$PROG="IBM Cloud Developer Tools - Installer for Windows"

Write-Output "--==[ $PROG, v$VERSION ]==--"

# Check for Windows 10
if ([System.Environment]::OSVersion.Version.Major -lt 10)
{
    Write-Output "Error: This installer requires Windows 10 or higher."
    exit
}

# Check for 64-bit Platform - Dev and Helm do not have 32-bit versions.
if ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem)
{
    Write-Output "Error: This installer requires 64-bit Windows."
    exit
}

# Running as admin defaults to system32 change to home directory.
Set-Location ~


# Install dependencies - git, docker, kubectl, helm.
$reboot = 0
$EXT_PROGS = "git,https://git-scm.com",
             "docker,https://docs.docker.com/engine/installation",
             "kubectl,https://kubernetes.io/docs/tasks/tools/install-kubectl/",
             "helm,https://github.com/kubernetes/helm/blob/master/docs/install.md"
Foreach($i in $EXT_PROGS) {
    $prog_bin, $prog_url = $i.split(",")
    Write-Output "Checking for dependency $prog_bin"
    if( get-command $prog_bin -erroraction 'silentlycontinue' ) {
        Write-Output "$prog_bin already installed"
    } else {
        $reboot = 1
        Write-Output "$prog_bin attempting to install..."
        if ($prog_bin -eq "git") {
            $gitVersion = (Invoke-WebRequest "https://git-scm.com/downloads/latest" -UseBasicParsing).Content
            Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe" -UseBasicParsing -outfile "git-installer.exe"
            .\git-installer.exe /SILENT /PathOption="Cmd" | Out-Null
            Remove-Item "git-installer.exe"
        } elseif ($prog_bin -eq "docker") {
            Invoke-WebRequest "https://download.docker.com/win/stable/InstallDocker.msi" -UseBasicParsing -outfile "InstallDocker.msi"
            msiexec /i InstallDocker.msi /passive | Out-Null
        } elseif ($prog_bin -eq "kubectl") {
            $kube_version = (Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/stable.txt" -UseBasicParsing).Content
            $kube_version = $kube_version -replace "`n|`r"
            Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/$kube_version/bin/windows/amd64/kubectl.exe" -UseBasicParsing -outfile "kubectl.exe"
            mkdir "C:\Program Files\kubectl"
            Move-Item -Path "kubectl.exe" -Destination "C:\Program Files\kubectl"
            # Directly edit the registery to add kubectl to PATH. Will require a restart to stick.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\kubectl"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
        } elseif ($prog_bin -eq "helm") {
            $helm_url = ((Invoke-WebRequest https://github.com/kubernetes/helm -UseBasicParsing).Links.OuterHTML | Where-Object{$_ -match 'windows-amd64.tar.gz'} | Select-Object -first 1).Split('"')[1]
            Write-Output "Helm URL : $helm_url"
            $helm_file = $helm_url.Split("/")[$_.Length-1]
            Write-Output "Helm File: $helm_file"
            Invoke-WebRequest $helm_url -UseBasicParsing -outfile "$helm_file"
            mkdir "C:\Program Files\helm" -ErrorAction SilentlyContinue
            if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
                Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
            }
            Expand-7Zip $helm_file .
            $tar = $helm_file.Replace('.gz','')
            Expand-7Zip $tar "C:\Program Files\helm"
            Remove-Item $helm_file $tar
            # Directly edit the registery to add helm to PATH. Will require a restart to stick.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\helm\windows-amd64"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
        } else {
            Write-Output "Warning: $prog_bin install not implemented"
        }
    }
}

#-- Install Bluemix CLI.
Write-Output "Installing IBM Cloud CLI..."
if( get-command bx -erroraction 'silentlycontinue') {
    Write-Output "bx already installed"
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe update
} else {
    Invoke-Expression(New-Object Net.WebClient).DownloadString("https://clis.ng.bluemix.net/install/powershell")
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe api api.ng.bluemix.net
    reboot = 1
}
Write-Output "IBM Cloud CLI version:"
C:\"Program Files"\IBM\Bluemix\bin\bx.exe --version

#-- Install Bluemix CLI Plugins.
Write-Output "Installing/updating IBM Cloud CLI plugins used by IDT..."
$EXT_PLUGINS = "Cloud-Functions",
               "container-registry",
               "container-service",
               "dev",
               "schematics",
               "sdk-gen"
$pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
Foreach ($plugin in $EXT_PLUGINS) {
    if($pluginlist -match "\b$plugin\b") {
        Write-Output "Updating plugin: $plugin"
        C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin update $plugin -r Bluemix
    } else {
        Write-Output "Installing plugin: $plugin"
        C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install $plugin -r Bluemix
    }
}

#-- Create "idt" script to act as shortcut to "bx dev"
Write-Output "Creating 'idt' script to act as shortcut to 'bx dev' command..."
$idt_batch = @"
@ECHO OFF
REM #-----------------------------------------------------------
REM # IBM Cloud Developer Tools (IDT), version 1.2.0
REM # Wrapper for the 'bx dev' command, and external helpers.
REM #-----------------------------------------------------------
REM # Syntax:
REM #   idt                               - Run 'bx dev <args>'
REM #   idt update    [--trace] [--force] - Update IDT and deps
REM #   idt uninstall [--trace]           - Uninstall IDT
REM #-----------------------------------------------------------
IF "%1"=="update" (
    echo Updating IBM Cloud Developer Tools CLI...
REM     PowerShell.exe -ExecutionPolicy Unrestricted -Command "iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')"
    powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile "iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')" -verb RunAs}"
) ELSE IF "%1"=="uninstall" (
    echo Uninstalling IBM Cloud Developer Tools CLI...
REM     set /P AREYOUSURE=Are you sure you want to unbinstall IDT (Y/N)?
REM     if /I %AREYOUSURE% EQ Y (
REM         for /d %f in (C:\"Program Files"\IBM\Bluemix*) do rmdir /s/q "%f"
REM )
    echo IDT and IBM Cloud CLI have been removed.
) ELSE (
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe dev %*
)
REM #-----------------------------------------------------------
"@
#Write-Output $idt_batch > C:\"Program Files"\IBM\Bluemix\bin\idt.bat
#"bx dev %*" | Out-File -FilePath "C:\Program Files\IBM\Bluemix\bin\idt.bat" -Encoding ascii
Write-Output $idt_batch | Out-File -Encoding ascii "C:\Program Files\IBM\Bluemix\bin\idt.bat"

Write-Output "--==[ Finished ]==--"

#-- Request Restart to save changes to PATH.
if ($reboot -eq 1 ) {
    $restart = Read-Host "A system restart is required. Would you like to restart now (y/N)?"
    if($restart -eq "y" -Or $restart -eq "yes") {
        Restart-Computer
    }
}
