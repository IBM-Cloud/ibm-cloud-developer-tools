#------------------------------------------------------------------------------
# Script:  idt-win-installer
#------------------------------------------------------------------------------
# IBM Cloud Developer Tools - CLI installer script for Windows 10 systems
#------------------------------------------------------------------------------
# Copyright (c) 2018, International Business Machines. All Rights Reserved.
#------------------------------------------------------------------------------
$VERSION="1.2.0"
$PROG="IBM Cloud Developer Tools - Installer for Windows"

echo "--==[ $PROG, v$VERSION ]==--"

# Check for Windows 10
if ([System.Environment]::OSVersion.Version.Major -ne 10)
{
    echo "This installer requires Windows 10."
    exit
}

# Check for 64-bit Platform - Dev and Helm do not have 32-bit versions.
if ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem)
{
    echo "This installer requires 64-bit Windows."
    exit
}

# Running as admin defaults to system32 change to home directory.
cd ~

# Install dependencies - git, docker, kubectl, helm.
$EXT_PROGS = "git,https://git-scm.com","docker,https://docs.docker.com/engine/installation","kubectl,https://kubernetes.io/docs/tasks/tools/install-kubectl/","helm,https://github.com/kubernetes/helm/blob/master/docs/install.md"
Foreach($i in $EXT_PROGS) {
    $prog_bin, $prog_url = $i.split(",")
    echo "Checking for dependency $prog_bin"
    if( get-command $prog_bin -erroraction 'silentlycontinue' ) {
        echo "$prog_bin already installed"
    } else {
        echo "$prog_bin attempting to install..."
        if ($prog_bin -eq "git") {
            $gitVersion = (Invoke-WebRequest "https://git-scm.com/downloads/latest").Content
            Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe" -outfile "git-installer.exe"
            .\git-installer.exe /SILENT /PathOption="Cmd" | Out-Null
            rm "git-installer.exe"
        } elseif ($prog_bin -eq "docker") {
            Invoke-WebRequest "https://download.docker.com/win/stable/InstallDocker.msi" -outfile "InstallDocker.msi"
            msiexec /i InstallDocker.msi /passive | Out-Null
        } elseif ($prog_bin -eq "kubectl") {
            $kube_version = (Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/stable.txt").Content
            $kube_version = $kube_version -replace "`n|`r"
            Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/$kube_version/bin/windows/amd64/kubectl.exe" -outfile "kubectl.exe"
            mkdir "C:\Program Files\kubectl"
            Move-Item -Path "kubectl.exe" -Destination "C:\Program Files\kubectl"
            # Directly edit the registery to add kubectl to PATH. Will require a restart to stick.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\kubectl"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
        } elseif ($prog_bin -eq "helm") {
            $helm_url = "https://github.com/kubernetes/helm/releases/latest"
            $TAG = (((Invoke-WebRequest 'https://github.com/kubernetes/helm/releases/latest').Links.outerHTML | Where{$_ -match '/tag/'} | select -first 1).Split('"')[3]).Split("/")[$_.Length-1]
            if("x$TAG" -eq "x") {
                echo "Cannot determine tag"
                return
            }
            $helm_file = "helm-$TAG-windows-amd64.tar.gz"
            $helm_download_url = "https://storage.googleapis.com/kubernetes-helm/$helm_file"
            Invoke-WebRequest $helm_download_url -outfile "$helm_file"
            mkdir "C:\Program Files\helm"
            Expand-Archive $helm_file -DestinationPath "C:\Program Files\helm"
            rm $helm_file
            # Directly edit the registery to add helm to PATH. Will require a restart to stick.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\helm\windows-amd64"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
        } else {
            echo "$prog_bin install not implemented"
        }
    }
}

#-- Install Bluemix CLI.
if( get-command bx -erroraction 'silentlycontinue') {
    echo "bx already installed"
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe --version
} else {
    iex(New-Object Net.WebClient).DownloadString("https://clis.ng.bluemix.net/install/powershell")
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe api api.ng.bluemix.net
}

#-- Install Bluemix CLI Plugins.
$EXT_PLUGINS = "Cloud-Functions","container-registry","container-service","dev","schematics","sdk-gen"
$pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
Foreach ($plugin in $EXT_PLUGIN) {
    if($pluginlist -contains \b$plugin\b) {
        echo "Updating plugin: $plugin"
        C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install $plugin -r Bluemix
    } else {
        echo "Installing plugin: $plugin"
        C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install $plugin -r Bluemix
    }
}

#-- Create "idt" script to act as shortcut to "bx dev"
$idt_batch = @"
	#-----------------------------------------------------------
    # IBM Cloud Developer Tools (IDT), version $VERSION
    # Wrapper for the 'bx dev' command, and external helpers.
    #-----------------------------------------------------------
    # Syntax:
    #   idt                               - Run 'bx dev <args>'
    #   idt update    [--trace] [--force] - Update IDT and deps
    #   idt uninstall [--trace]           - Uninstall IDT
    #-----------------------------------------------------------
    @ECHO OFF
    IF "%1"=="update" (
        echo "Updating IBM Cloud Developer Tools (IDT) CLI..."
        PowerShell.exe -ExecutionPolicy Unrestricted -Command "iex(New-Object Net.WebClient).DownloadString('http://ibm.biz/idt-win-installer')"
    ) ELSE IF "%1"=="uninstall" (
        echo "Uninstalling IBM Cloud Developer Tools (IDT) CLI..."
        set /P AREYOUSURE=Are you sure you want to unbinstall IDT (Y/N)?
        if /I %AREYOUSURE% EQ Y (
            for /d %f in (C:\"Program Files"\IBM\Bluemix*) do rmdir /s/q "%f"
        )
        echo "IDT and IBM Cloud CLI have been removed."
    ) ELSE (
        bx dev %*
    )
    #-----------------------------------------------------------
"@
echo "$idt_batch" > C:\"Program Files"\IBM\Bluemix\bin\idt.bat

echo "--==[ Finished ]==--"

#-- Request Restart to save changes to PATH.
$restart = Read-Host "A system restart is required. Would you like to restart now (y/n)? (default is n)"
if($restart -eq "y" -Or $restart -eq "yes") {
    Restart-Computer
}
