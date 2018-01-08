#------------------------------------------------------------------------------
# Script:  idt-win-installer
#------------------------------------------------------------------------------
# IBM Cloud Developer Tools - CLI installer script for Windows 10 systems
#------------------------------------------------------------------------------
# Copyright (c) 2018, International Business Machines. All Rights Reserved.
#------------------------------------------------------------------------------
$VERSION="1.2.0"
$PROG="IBM Cloud Developer Tools - Installer for Windows"

$INSTALLER_URL="https://ibm.biz/idt-win-installer"
$GIT_URL="https://github.com/IBM-Cloud/ibm-cloud-developer-tools"
$SLACK_URL="https://slack-invite-ibm-cloud-tech.mybluemix.net/"
$IDT_INSTALL_BMX_URL="https://clis.ng.bluemix.net/install"
$IDT_INSTALL_BMX_REPO_NAME="Bluemix"
$IDT_INSTALL_BMX_REPO_URL="https://plugins.ng.bluemix.net"

$FORCE = 0
$NEEDS_REBOOT = 0

#------------------------------------------------------------------------------
function help {
  Write-Output @"

  $PROG
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

  Chat with us on Slack: ${SLACK_URL}, channel #developer-tools
  Submit any issues to : ${GIT_URL}/issues

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

function quit() {
   # If running in the console, wait for input before closing.
   if ($Host.Name -eq "ConsoleHost") { 
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.FlushInputBuffer()   # Make sure buffered input doesn't "press a key" and skip the ReadKey().
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
  }
}

#------------------------------------------------------------------------------
function uninstall() {
  warn "Starting Uninstall..."
  Write-Output
  $reply = Read-Host -Prompt "Are you sure you want to remove IDT and IBM Cloud CLI (Y/n)?"
  Write-Output
  if($reply -match "[Yy]*") {
    log "Deleting: C:\Program Files\IBM\Bluemix"
    Remove-Item -Recurse -Force "C:\Program Files\IBM\Bluemix"
    log "Deleting: ~/.bluemix"
    Remove-Item -Recurse -Force ~/.bluemix
    log "Uninstall complete."
  } else {
    log "Uninstall cancelled at user request"
  }
}

#------------------------------------------------------------------------------
function install() {
  log "Starting Installation/Update..."

  #-- Check if internal IBM setup
  if( get-command bx -erroraction 'silentlycontinue' ) {
    $pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
    if($pluginlist -match "\bstage\b") {
      Write-Output
      $reply = Read-Host -Prompt "Use IBM internal repos for install/updates (Y/n)?"
      Write-Output
      if($reply -match "[Yy]*") {
        $IDT_INSTALL_BMX_URL="https://clis.stage1.ng.bluemix.net/install"
        $IDT_INSTALL_BMX_REPO_NAME="stage1"
        $IDT_INSTALL_BMX_REPO_URL="https://plugins.stage1.ng.bluemix.net"
      }
    }
  }

  install_deps
  install_bx
  install_plugins
  env_setup add

  log "Install finished."

  #-- Request Restart to save changes to PATH.
  if ($NEEDS_REBOOT -eq 1 ) {
    $restart = Read-Host "A system restart is required. Would you like to restart now (y/N)?"
    if($restart -match "[Yy]*" ) {
        Restart-Computer
    }
  }
}


#------------------------------------------------------------------------------
#-- Install dependencies - git, docker, kubectl, helm.
function install_deps() {

  #-- git
  log "Checking for external dependency: git"
  if( -not (get-command git -erroraction 'silentlycontinue') -or $FORCE -eq 1) {
    log "Installing/updating external dependency: git"
    $gitVersion = (Invoke-WebRequest "https://git-scm.com/downloads/latest" -UseBasicParsing).Content
    Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe" -UseBasicParsing -outfile "git-installer.exe"
    .\git-installer.exe /SILENT /PathOption="Cmd" | Out-Null
    Remove-Item "git-installer.exe"
    $NEEDS_REBOOT = 1
    log "Install/update completed for: git"
  }

  #-- docker
  log "Checking for external dependency: docker"
  if( -not(get-command docker -erroraction 'silentlycontinue') -or $FORCE -eq 1) {
    log "Installing/updating external dependency: docker"
    Invoke-WebRequest "https://download.docker.com/win/stable/InstallDocker.msi" -UseBasicParsing -outfile "InstallDocker.msi"
    msiexec /i InstallDocker.msi /passive | Out-Null
    $NEEDS_REBOOT = 1
    log "Install/update completed for: docker"
  }

  #-- kubectl
  log "Checking for external dependency: kubectl"
  if( -not( get-command kubectl -erroraction 'silentlycontinue') -or $FORCE -eq 1) {
    log "Installing/updating external dependency: kubectl"
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
    $NEEDS_REBOOT = 1
    log "Install/update completed for: kubectl"
  }

  #-- helm
  log "Checking for external dependency: helm"
  if( -not (get-command helm -erroraction 'silentlycontinue') -or $FORCE -eq 1) {
    log "Installing/updating external dependency: helm"
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
    $NEEDS_REBOOT = 1
    log "Install/update completed for: helm"
  }
}

#------------------------------------------------------------------------------
#-- Install Bluemix CLI.
function install_bx() {
  if( get-command bx -erroraction 'silentlycontinue') {
      Write-Output "bx already installed"
      bx update
  } else {
    log "Installing IBM Cloud 'bx' CLI for Windows..."
    $url = $IDT_INSTALL_BMX_URL + "/powershell"
    log "Downloading and installing IBM Cloud 'bx' CLI from: $url" 
    Invoke-Expression(New-Object Net.WebClient).DownloadString( $url )
    C:\"Program Files"\IBM\Bluemix\bin\bx.exe api api.ng.bluemix.net
    $NEEDS_REBOOT = 1
  }
  log "IBM Cloud CLI version:"
  C:\"Program Files"\IBM\Bluemix\bin\bx.exe --version
}

#------------------------------------------------------------------------------
#-- Install Bluemix CLI Plugins.
function install_plugins {
  log "Installing/updating IBM Cloud CLI plugins used by IDT..."
  $EXT_PLUGINS = "Cloud-Functions",
                "container-registry",
                "container-service",
                "dev",
                "schematics",
                "sdk-gen"
  $pluginlist = C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin list
  Foreach ($plugin in $EXT_PLUGINS) {
      log "Checking status of plugin: $plugin"
      if($pluginlist -match "\b$plugin\b") {
          log "Updating plugin '$plugin'"
          C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin update -r $IDT_INSTALL_BMX_REPO_NAME $plugin
      } else {
          log "Installing plugin '$plugin'"
          C:\"Program Files"\IBM\Bluemix\bin\bx.exe plugin install -r $IDT_INSTALL_BMX_REPO_NAME $plugin
      }
  }
}

#------------------------------------------------------------------------------
#-- Create "idt" script to act as shortcut to "bx dev"
function env_setup() {
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
  PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted ""iex(New-Object Net.WebClient).DownloadString(""""http://ibm.biz/idt-win-installer"""")"" ""%2"" ""%3"" ' -Verb RunAs}"
) ELSE IF "%1"=="uninstall" (
  echo Uninstalling IBM Cloud Developer Tools CLI...
  PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted ""iex(New-Object Net.WebClient).DownloadString(""""http://ibm.biz/idt-win-installer"""")"" ""uninstall"" ""%2"" ' -Verb RunAs}"
  echo IDT and IBM Cloud CLI have been removed.
) ELSE (
  bx dev %*
)
REM #-----------------------------------------------------------
"@
  Write-Output $idt_batch | Out-File -Encoding ascii "C:\Program Files\IBM\Bluemix\bin\idt.bat"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
function main {
  log "--==[ $PROG, v$VERSION ]==--"
  $secs = (Get-Date)

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
        $FORCE=1
        warn "Forcing updates for all dependencies and other settings"
      }
      "update"    { $ACTION = "install" }
      "install"   { $ACTION = "install" }
      "uninstall" { $ACTION = "uninstall" }
      default     { $ACTION = "help" }
    }
  }

  switch -exact ($ACTION) {
    "install"   { install }
    "uninstall" { uninstall }
    default     { help }
  }

  $secs = (Get-Date)-$secs
  log "--==[ Finished. Total time: $($secs.ToString("hh\:mm\:ss")) seconds ]==--"

  quit
}

#------------------------------------------------------------------------------
#-- Kick things off
#------------------------------------------------------------------------------
main $args

#------------------------------------------------------------------------------
# EOF
#------------------------------------------------------------------------------
