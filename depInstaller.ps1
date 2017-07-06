$EXT_PROGS = "docker,docker,https://docs.docker.com/engine/installation","kubectl,kubectl,https://kubernetes.io/docs/tasks/tools/install-kubectl/","helm,kubernetes-helm,https://github.com/kubernetes/helm/blob/master/docs/install.md"
Foreach($i in $EXT_PROGS) {
    $prog_bin, $prog_url = $i.split(",")
    echo "Checking for dependency $prog_bin"
    if( get-command $prog_bin ) {
        echo "$prog_bin already installed"
    } else {
        echo "$prog_bin attempting to install..."
        if ($prog_bin -eq "docker") {
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
            $helm_url = "https://github.com/kubernetes/helm/releases/latest"
            $TAG = (((Invoke-WebRequest 'https://github.com/kubernetes/helm/releases/latest').Links.outerHTML | Where{$_ -match '/tag/'} | select -first 1).Split('"')[3]).Split("/")[$_.Length-1]
            if("x$TAG" -eq "x") {
                echo "Cannot determine tag"
                return
            }
            #need to check for proper architecture
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
