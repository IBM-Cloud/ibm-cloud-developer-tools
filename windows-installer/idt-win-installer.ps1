# idt-win-installer
# Installs IBM Developer Bluemix CLI plugin and all dependencies.
# VERSION="0.8"

# Check for 64-bit Platform - Dev and Helm do not have 32-bit versions.
if ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem)
{
    echo "This installer requires 64-bit Windows."
    exit
}

# Check for Windows 10
if ([System.Environment]::OSVersion.Version.Major -ne 10)
{
    echo "This installer requires Windows 10."
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
            $helm_download_url = "https://storage.googleapis.com/kubernetes-helm/helm-$TAG-windows-amd64.zip"
            Invoke-WebRequest $helm_download_url -outfile "helm-$TAG-windows-amd64.zip"
            mkdir "C:\Program Files\helm"
            Expand-Archive helm-$TAG-windows-amd64.zip -DestinationPath "C:\Program Files\helm"
            # Directly edit the registery to add helm to PATH. Will require a restart to stick.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\helm\windows-amd64"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
            rm "helm-$TAG-windows-amd64.zip"
        } else {
            echo "$prog_bin install not implemented"
        }
    }
}

# Install Bluemix CLI.
if( get-command bx -erroraction 'silentlycontinue') {
    echo "bx already installed"
} else {
    iex(New-Object Net.WebClient).DownloadString("https://clis.ng.bluemix.net/install/powershell")
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe api api.ng.bluemix.net
}

# Install Bluemix CLI Plugins.
$EXT_PLUGINS = "container-registry","container-service","dev","IBM-Containers","schematics"
$EXT_PLUGINS = New-Object System.Collections.ArrayList(,$EXT_PLUGINS)
$pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
# Parse bx plugin list to determine what plugins are installed already.
for ($i=2; $i -lt $pluginlist.length; $i++) {
    $item = $pluginlist[$i].split(" ",2)
    if($item[0] -match "\bdev\b") {
        echo "dev is installed"
        $EXT_PLUGINS.remove("dev")
    } elseif ($item[0] -match "\bcontainer-registry\b") {
        echo "constainer-registry is installed"
        $EXT_PLUGINS.remove("container-registry")
    } elseif ($item[0] -match "\bcontainer-service\b") {
        echo "container-service is installed"
        $EXT_PLUGINS.remove("container-service")
    } elseif ($item[0] -match "\bIBM-Containers\b") {
        echo "IBM-Containers is installed"
        $EXT_PLUGINS.remove("IBM-Containers")
    } elseif ($item[0] -match "\bschematics\b") {
        echo "schematics is installed"
        $EXT_PLUGINS.remove("schematics")
    }
}
# Install plugins.
if( $EXT_PLUGINS.contains("Cloud-Functions")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install Cloud-Functions -r Bluemix
}
if( $EXT_PLUGINS.contains("container-registry")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install container-registry -r Bluemix
}
if( $EXT_PLUGINS.contains("container-service")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install container-service -r Bluemix
}
if( $EXT_PLUGINS.contains("schematics")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install schematics -r Bluemix
}
if( $EXT_PLUGINS.contains("dev")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install dev -r Bluemix
}
if( $EXT_PLUGINS.contains("sdk-gen")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install sdk-gen -r Bluemix
}

# Request Restart to save changes to PATH.
$restart = Read-Host "A system restart is required. Would you like to restart now (y/n)? (default is n)"
if($restart -eq "y" -Or $restart -eq "yes") {
    Restart-Computer
}
