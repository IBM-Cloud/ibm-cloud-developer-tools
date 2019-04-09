#------------------------------------------------------------------------------
# Script:  idt-win-installer
#------------------------------------------------------------------------------
# IBM Cloud Developer Tools - CLI installer script for Windows 10 systems
#------------------------------------------------------------------------------
# Copyright (c) 2019, International Business Machines. All Rights Reserved.
#------------------------------------------------------------------------------
$Global:VERSION="1.2.2"
$Global:PROG="IBM Cloud Developer Tools - Installer for Windows"

$Global:INSTALLER_URL="https://ibm.biz/idt-win-installer"
$Global:GIT_URL="https://github.com/IBM-Cloud/ibm-cloud-developer-tools"
$Global:SLACK_URL="https://slack-invite-ibm-cloud-tech.mybluemix.net/"
$Global:IDT_INSTALL_BMX_URL="https://clis.ng.bluemix.net/install"
$Global:IDT_INSTALL_BMX_REPO_NAME="Bluemix"
$Global:IDT_INSTALL_BMX_REPO_URL="https://plugins.ng.bluemix.net"

$Global:FORCE = $false
$Global:NEEDS_REBOOT = $false
$Global:SECS = 0

#------------------------------------------------------------------------------
function help {
  Write-Output @"

  $Global:PROG
  Usage: idt-win-installer [<args>]

  Where <args> is:
    install | update   [Default] Perform install (or update) of all needed CLIs and Plugins
    uninstall          Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    help               Show this help
    --force | -f       Force updates of dependencies and other settings during update
    --trace            Eanble verbose tracing of all activity

  If "install", "update", or no action, a full CLI installation (or update) will occur:
  1. Pre-req check for 'git', 'docker', 'kubectl', and 'helm'
  2. Install latest IBM Cloud 'bx' CLI
  3. Install all required plugins
  4. Defines 'idt' shortcut to improve useability.
      - idt           : Shortcut for normal "bx dev" command
      - idt update    : Runs this installer checking for and installing any updates
      - idt uninstall : Uninstalls IDT, 'bx' cli, and all plugins  

  Chat with us on Slack: $Global:SLACK_URL, channel #developer-tools
  Submit any issues to : $Global:GIT_URL/issues

"@
}


#------------------------------------------------------------------------------
function log() {
  Write-Host "[$((Get-PSCallStack)[1].Command)] " -foreground cyan  -nonewline
  Write-Host $args
}

function warn() {
  Write-Host "[$((Get-PSCallStack)[1].Command)] " -foreground cyan  -nonewline
  Write-Host "WARN" -foreground yellow  -nonewline
  Write-Host ": $args"
}

function error() {
  Write-Host "[$((Get-PSCallStack)[1].Command)] " -foreground cyan  -nonewline
  Write-Host "ERROR" -foreground red  -nonewline
  Write-Host ": $args"
  quit
}

#------------------------------------------------------------------------------
function quit() {
  $Global:SECS = (Get-Date)-$Global:SECS
  log "--==[ Finished. Total time: $($Global:SECS.ToString("hh\:mm\:ss")) seconds ]==--"
  Write-Host ""

  #-- Request Restart to save changes to PATH.
  if ( $Global:NEEDS_REBOOT ) {
    $restart = Read-Host -Prompt "A system restart is required. Would you like to restart now (y/N)?"
    if($restart -match "[Yy]" ) {
      Restart-Computer
    } else {
      Write-Host "Note: Reboot still needed to load env variables."
    }
  } else {
    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost") { 
      Write-Host "Press any key to continue..."
      $Host.UI.RawUI.FlushInputBuffer()   # Make sure buffered input doesn't "press a key" and skip the ReadKey().
      $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
      
      #-- turn opff trace
      Set-PSDebug -Trace 0
    }
  }
}

#------------------------------------------------------------------------------
function uninstall() {
  warn "Starting Uninstall..."
  Write-Output ""
  $reply = Read-Host -Prompt "Are you sure you want to remove IDT and IBM Cloud CLI (y/N)?"
  Write-Output ""
  if($reply -match "[Yy]") {
    log "Uninstalling IDT..."
    log "Deleting: C:\Program Files\IBM\Cloud"
    Remove-Item -Recurse -Force "C:\Program Files\IBM\Cloud" -erroraction 'silentlycontinue' 
    log "Deleting: ~/.bluemix"
    Remove-Item -Recurse -Force ~/.bluemix -erroraction 'silentlycontinue' 
    log "Uninstall complete."
  } else {
    log "Uninstall cancelled at user request"
  }
}

#------------------------------------------------------------------------------
function install() {
  log "Starting Installation/Update..."

  #-- Check if internal IBM setup
  $bx_command = get-command bx -erroraction 'silentlycontinue'
  if( $bx_command )  {
     # The command is set, use it
  } else {
    $bx_command = 'C:\"Program Files"\IBM\Cloud\bin\bx.exe'
  }
  $pluginlist = iex "$bx_command plugin list"
  if($pluginlist -match "\bstage\b") {
    Write-Output
    $reply = Read-Host -Prompt "Use IBM internal repos for install/updates (Y/n)?"
    Write-Output
    if($reply -match "[Yy]*") {
      $Global:IDT_INSTALL_BMX_URL="https://clis.stage1.ng.bluemix.net/install"
      $Global:IDT_INSTALL_BMX_REPO_NAME="stage1"
      $Global:IDT_INSTALL_BMX_REPO_URL="https://plugins.stage1.ng.bluemix.net"
    }
  }

  install_deps
  install_bx
  install_plugins
  env_setup add

  log "Install finished."

}


#------------------------------------------------------------------------------
#-- Install dependencies - git, docker, kubectl, helm.
function install_deps() {

  [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"

  #-- git
  log "Checking for external dependency: git"
  if( -not (get-command git -erroraction 'silentlycontinue') -or $Global:FORCE) {
    
    log "Installing/updating external dependency: git"
    $gitVersion = (Invoke-WebRequest "https://git-scm.com/downloads/latest" -UseBasicParsing).Content
    Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe" -UseBasicParsing -outfile "git-installer.exe"
    .\git-installer.exe /SILENT /PathOption="Cmd" | Out-Null
    Remove-Item "git-installer.exe"
    $Global:NEEDS_REBOOT = $true
    log "Install/update completed for: git"
  }

  #-- docker
  log "Checking for external dependency: docker"
  if( -not(get-command docker -erroraction 'silentlycontinue') -or $Global:FORCE) {
    log "Installing/updating external dependency: docker"
    Invoke-WebRequest "https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe" -UseBasicParsing -outfile "InstallDocker.exe"
    .\InstallDocker.exe | Out-Null
    $Global:NEEDS_REBOOT = $false
    log "Install/update completed for: docker"
  }

  #-- kubectl
  log "Checking for external dependency: kubectl"
  if( -not( get-command kubectl -erroraction 'silentlycontinue') -or $Global:FORCE) {
    log "Installing/updating external dependency: kubectl"

    $response = Invoke-RestMethod "https://containers.cloud.ibm.com/v1/kube-versions" 
    for ($i = 0; $i -lt $response.Length; $i++){
        if ($response[$i].default){
            $kube_version = "v" + $response[$i].major + "." + $response[$i].minor + "."  +$response[$i].patch
            break
        }
    }
    Invoke-WebRequest "https://storage.googleapis.com/kubernetes-release/release/$kube_version/bin/windows/amd64/kubectl.exe" -UseBasicParsing -outfile "kubectl.exe"
    mkdir "C:\Program Files\kubectl" -erroraction 'silentlycontinue'
    Move-Item -Path "kubectl.exe" -Destination "C:\Program Files\kubectl" -force
    add_to_path("C:\Program Files\kubectl")
    $Global:NEEDS_REBOOT = $true
    log "Install/update completed for: kubectl"
  }

  #-- helm
  log "Checking for external dependency: helm"
  if( -not (get-command helm -erroraction 'silentlycontinue') -or $Global:FORCE) {
    log "Installing/updating external dependency: helm"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $helm_url = ((Invoke-WebRequest https://github.com/helm/helm/releases -UseBasicParsing).Links.OuterHTML | Where-Object{$_ -match '.+?windows-amd64.zip'} | Select-Object -first 1).Split('"')[1]
    log "Helm URL : $helm_url"
    $helm_file = $helm_url.Split("/")[-1]
    log "Helm File: $helm_file"
    Invoke-WebRequest $helm_url -UseBasicParsing -outfile "$helm_file"
    mkdir "C:\Program Files\helm" -ErrorAction SilentlyContinue
    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
    }
    Expand-7Zip $helm_file .
    $tar_file = $helm_file.Replace('.gz','')
    Expand-7Zip $tar_file "C:\Program Files\helm"
    Remove-Item $helm_file -erroraction 'silentlycontinue'
    Remove-Item $tar_file  -erroraction 'silentlycontinue'
    add_to_path("C:\Program Files\helm\windows-amd64")
    $Global:NEEDS_REBOOT = $true
    log "Install/update completed for: helm"
  }
}

#------------------------------------------------------------------------------
#-- Add a dir to the system path
function add_to_path {
  Param($path)
  # Directly edit the registery to add kubectl to PATH. Will require a restart to stick.
  $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
  $value = (Get-ItemProperty $regPath -Name Path).Path
  if ( -not ($value -match [Regex]::Escape("$path") )) {
    log "Adding $path to PATH"
    $newValue = "$value;$path"
    Set-ItemProperty -Path $regPath -Name Path -Value $newValue | Out-Null
  }  
}

#------------------------------------------------------------------------------
#-- Install IBM Cloud CLI.
function install_bx() {
  if( get-command bx -erroraction 'silentlycontinue') {
      Write-Output "ibmcloud already installed"
      bx update
  } else {
    log "Installing 'ibmcloud' CLI for Windows..."
    $url = $Global:IDT_INSTALL_BMX_URL + "/powershell"
    log "Downloading and installing 'ibmcloud' CLI from: $url" 
    Invoke-Expression(New-Object Net.WebClient).DownloadString( $url )
    $Global:NEEDS_REBOOT = $true
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
  }
  log "IBM Cloud CLI version:"
  $bx_command = get-command bx -erroraction 'silentlycontinue'
  if( $bx_command )  {
     # The command is set, use it
  } else {
    $bx_command = 'C:\"Program Files"\IBM\Cloud\bin\bx.exe'
  }
  iex "$bx_command --version"
}

#------------------------------------------------------------------------------
#-- Install IBM Cloud CLI Plugins.
function install_plugins {
  log "Installing/updating IBM Cloud CLI plugins used by IDT..."
  $plugins = "Cloud-Functions",
             "container-registry",
             "container-service",
             "dev",
             "sdk-gen"
  
  $bx_command = get-command bx -erroraction 'silentlycontinue'
  if( $bx_command )  {
     # The command is set, use it
  } else {
    $bx_command = 'C:\"Program Files"\IBM\Cloud\bin\bx.exe'
  }
  $pluginlist = iex "$bx_command plugin list"

  Foreach ($plugin in $plugins) {
    log "Checking status of plugin: $plugin"
    if($pluginlist -match "\b$plugin\b") {
        log "Updating plugin '$plugin'"
        iex "$bx_command plugin update -r $Global:IDT_INSTALL_BMX_REPO_NAME $plugin"
    } else {
        log "Installing plugin '$plugin'"
        iex "$bx_command plugin install -r $Global:IDT_INSTALL_BMX_REPO_NAME $plugin"
    }
  }
  log "Running 'ibmcloud plugin list'..."
  iex "$bx_command plugin list"
  log "Finished installing/updating plugins"
}

#------------------------------------------------------------------------------
#-- Create "idt" script to act as shortcut to "bx dev"
function env_setup() {
  Write-Output "Creating 'idt' script to act as shortcut to 'ibmcloud dev' command..."
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
set "action="
if "%1"=="update"    set action="update"
if "%1"=="uninstall" set action="uninstall"
if defined action (
  echo IDT launcher action: %action%
  set ifile="%temp%\idt-win-installer.ps1"
  echo Fetching latest installer to: %ifile%
  Powershell -NoProfile -ExecutionPolicy Unrestricted -Command "Invoke-WebRequest 'http://ibm.biz/idt-win-installer' -UseBasicParsing -outfile '%ifile%'"
  echo Calling: %ifile% %*
  PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted -File %ifile% %*' -Verb RunAs}"
) else (
  bx dev %*
)
REM #-----------------------------------------------------------
"@
  $idt_command = get-command idt -erroraction 'silentlycontinue'
  if( $idt_command )  {
    # The command is set, use it's existing location
  } else {
    # Set to IBM Cloud install location
    $idt_command = 'C:\Program Files\IBM\Cloud\bin\idt.bat'
  }
  Write-Output $idt_batch | Out-File -Encoding ascii $idt_command
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
function main {
  log "--==[ $Global:PROG, v$Global:VERSION ]==--"
  $Global:SECS = (Get-Date)

  #-- Check for Windows 10
  if ([System.Environment]::OSVersion.Version.Major -lt 10) {
    error "This installer requires Windows 10 or higher."
  }

  #-- Check for 64-bit Platform - Dev and Helm do not have 32-bit versions.
  if ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem) {
    error "This installer requires 64-bit Windows."
  }

  If(-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
      error "This script must be run as Administrator. Re-run this script as an Administrator!"
  }

  #-- Running as admin defaults to system32 change to home directory.
  Set-Location ~

  $ACTION="install"

  #-- Parse args
  foreach ($arg in $args) {
    switch -exact ($arg) {
      "--trace" {
        warn "Enabling verbose tracing of all activity"
        Set-PSDebug -Trace 1
      }
      "--force" {
        $Global:FORCE=$true
        warn "Forcing updates for all dependencies and other settings"
      }
      "update"    { $ACTION = "install" }
      "install"   { $ACTION = "install" }
      "uninstall" { $ACTION = "uninstall" }
      "help"      { $ACTION = "help" }
      default     { warn "Undefined Arg: $arg" }
    }
  }
  switch -exact ($ACTION) {
    "install"   { install }
    "uninstall" { uninstall }
    default     { help }
  }

  quit
}

#------------------------------------------------------------------------------
#-- Kick things off
#------------------------------------------------------------------------------
main $args

#------------------------------------------------------------------------------
# EOF
#------------------------------------------------------------------------------
