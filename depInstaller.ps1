#do this to mimic the curl | bash script
#this assumes a 64 bit machine, as helm and the dev plugin have no 32 bit versions
$EXT_PROGS = "git,https://git-scm.com","docker,https://docs.docker.com/engine/installation","kubectl,https://kubernetes.io/docs/tasks/tools/install-kubectl/","helm,https://github.com/kubernetes/helm/blob/master/docs/install.md"
#install dependencies
Foreach($i in $EXT_PROGS) {
    $prog_bin, $prog_url = $i.split(",")
    echo "Checking for dependency $prog_bin"
    if( get-command $prog_bin ) {
        echo "$prog_bin already installed"
    } else {
        echo "$prog_bin attempting to install..."
        if ($prog_bin -eq "git") {
            Invoke-WebRequest "https://git-scm.com/download/win" -outfile "git.exe"
            .\git.exe /SILENT /PathOption="Cmd" | Out-Null
            rm "git.exe"
        } elseif ($prog_bin -eq "docker") {
            Invoke-WebRequest "https://download.docker.com/win/stable/DockerToolbox.exe" -outfile "DockerToolbox.exe"
            .\DockerToolbox.exe /a /SILENT | Out-Null
            rm "DockerToolbox.exe"
        } elseif ($prog_bin -eq "kubectl") {
            $kube_version = (Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/stable.txt").Content
            $kube_version = $kube_version -replace "`n|`r"
            Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/$kube_version/bin/windows/amd64/kubectl.exe" -outfile "kubectl.exe"
            mkdir "C:\Program Files\kubectl"
            Move-Item -Path "kubectl.exe" -Destination "C:\Program Files\kubectl"
            #directly edit the registery to add kubectl to path
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            $value = (Get-ItemProperty $regPath -Name Path).Path
            $newValue = $value+";C:\Program Files\kubectl"
            Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
        } elseif ($prog_bin -eq "helm") {
            #only installs helm, not tiller
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
            #directly edit the registery to add helm to path
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
#after dependencies are installed intall bx
if( get-command bx ) {
    echo "bx already installed"
} else {
    iex(New-Object Net.WebClient).DownloadString("https://clis.ng.bluemix.net/install/powershell")
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe api api.ng.bluemix.net
}
#after bx is installed, install plugins
$EXT_PLUGINS = "container-registry","container-service","dev","IBM-Containers"
$EXT_PLUGINS = New-Object System.Collections.ArrayList(,$EXT_PLUGINS)
$pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
#parse list to determine what plugins we have installed already
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
    }
}
#install plugins
if( $EXT_PLUGINS.contains("dev")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install dev -r Bluemix
}
if( $EXT_PLUGINS.contains("container-registry")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install container-registry -r Bluemix
}
if( $EXT_PLUGINS.contains("container-service")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install container-service -r Bluemix
}
if( $EXT_PLUGINS.contains("IBM-Containers")) {
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install IBM-Containers -r Bluemix
}