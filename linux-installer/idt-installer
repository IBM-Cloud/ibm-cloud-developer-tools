#!/bin/bash
#------------------------------------------------------------------------------
# Script:  idt-installer
#------------------------------------------------------------------------------
# IBM Cloud Developer Tools - CLI installer script for MacOS and Linux systems
#------------------------------------------------------------------------------
# Copyright (c) 2018, International Business Machines. All Rights Reserved.
#------------------------------------------------------------------------------

VERSION="1.2.3"
PROG="IBM Cloud Developer Tools for Linux/MacOS - Installer"
INSTALLER_URL="https://ibm.biz/idt-installer"
GIT_URL="https://github.com/IBM-Cloud/ibm-cloud-developer-tools"
SLACK_URL="https://slack-invite-ibm-cloud-tech.mybluemix.net/"
IDT_INSTALL_BMX_URL="https://clis.ng.bluemix.net/install"
IDT_INSTALL_BMX_REPO_NAME="Bluemix"
IDT_INSTALL_BMX_REPO_URL="https://plugins.ng.bluemix.net"

#------------------------------------------------------------------------------
function help {
  cat <<-!!EOF

  ${PROG}
  Usage: idt-installer [<args>]

  Where <args> is:
    install          [Default] Perform full install (or update) of all needed CLIs and Plugins
    uninstall        Uninstall full IBM Cloud CLI env, including 'bx', and plugins
    help | -h | -?   Show this help
    --force          Force updates of dependencies and other settings during update
    --trace          Eanble verbose tracing of all activity

  If "install" (or no action provided), a full CLI installation (or update) will occur:
  1. Pre-req check for 'git', 'docker', 'kubectl', and 'helm'
  2. Install latest IBM Cloud 'bx' CLI
  3. Install all required plugins
  4. Defines 'idt' shortcut to improve useability.
      - idt           : Shortcut for normal "bx dev" command
      - idt update    : Runs this installer checking for and installing any updates
      - idt uninstall : Uninstalls IDT, 'bx' cli, and all plugins  

  Chat with us on Slack: ${SLACK_URL}, channel #developer-tools
  Submit any issues to : ${GIT_URL}/issues

	!!EOF
}


#------------------------------------------------------------------------------
#-- ${FUNCNAME[1]} == Calling function's name
#-- Colors escape seqs
YEL='\033[1;33m'
CYN='\033[0;36m'
GRN='\033[1;32m'
RED='\033[1;31m'
NRM='\033[0m'

function log {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} $*"
}

function warn {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} ${YEL}WARN${NRM}: $*"
}

function error {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} ${RED}ERROR${NRM}: $*"
  exit -1
}


function prompt {
  label=${1}
  default=${2}
  if [[ -z $default ]]; then
    echo -en "${label}: ${CYN}" > /dev/tty
  else
    echo -en "${label} [$default]: ${CYN}"  > /dev/tty
  fi
  read -r
  echo -e "${NRM}"  > /dev/tty
  #-- Use $REPLY to get user's input
}

#------------------------------------------------------------------------------
function uninstall {
  if [[ -t 0 ]]; then   #-- are we in a terminal?
    echo
    prompt "Please confirm you want to uninstall IBM Cloud Developer Tools (y/N)?"
    if [[ "$REPLY" != [Yy]* ]]; then
      log "Uninstall aborted at user request"
      return
    fi
  fi
  warn "Starting Uninstall..."
  [ "$SUDO" ] && log "You may be prompted for 'sudo' password."

  #-- Run the following regardless
  $SUDO rm -f  /usr/local/bin/bluemix
  $SUDO rm -f  /usr/local/bin/bx
  $SUDO rm -f  /usr/local/bin/bluemix-analytics
  $SUDO rm -rf /usr/local/Bluemix
  #-- Taken from bluemix CLI brew uninstaller
  if [[ -f /etc/profile ]]; then
    $SUDO sed -E -i ".bluemix_uninstall_bak" \
                      -e '/^### Added by the Bluemix CLI$/d' \
                      -e '/^source \/usr\/local\/Bluemix\/bx\/bash_autocomplete$/d' \
                      /etc/profile
  fi
  if [[ -f ~/.bashrc ]]; then
    sed -E -i ".bluemix_uninstall_bak" \
                  -e '/^### Added by the Bluemix CLI$/d' \
                  -e '/^source \/usr\/local\/Bluemix\/bx\/bash_autocomplete$/d' \
                  ~/.bashrc
  fi
  if [[ -f ~/.zshrc ]]; then
    sed -E -i ".bluemix_uninstall_bak" \
                  -e '/^### Added by the Bluemix CLI$/d' \
                  -e '/^source \/usr\/local\/Bluemix\/bx\/zsh_autocomplete$/d' \
                  ~/.zshrc
  fi
  env_setup remove

  rm -rf ~/.bluemix

  log "Uninstall finished."
}

#------------------------------------------------------------------------------
function install {
  if [[ -n "$(which idt)" ]]; then
    log "Starting Installation..."
  else
    log "Starting Update..."
  fi
  
  #-- Check if internal IBM setup
  if [[ -n "$(which bx)" ]]; then
    read -r repo url <<< $(bx plugin repos | grep stage1)
    if [[ -n "$repo" ]]; then
      echo
      prompt "Use IBM internal '$repo' repos for install/updates (Y/n)?"
      echo
      if [[ "$REPLY" != [Nn]* ]]; then
        IDT_INSTALL_BMX_URL="https://clis.stage1.ng.bluemix.net/install"
        IDT_INSTALL_BMX_REPO_NAME="${repo}"
        IDT_INSTALL_BMX_REPO_URL="${url}"
      fi
    fi
  fi
  [ "$SUDO" ] && log "Note: You may be prompted for your 'sudo' password during install."

  install_deps
  install_bx
  install_plugins
  env_setup add

  log "Install finished."
}

#------------------------------------------------------------------------------
function install_deps {
  #-- check for/install brew for macos
  case "$PLATFORM" in
  "Darwin")
    log "Checking for external dependency: brew"
    if [[ -z "$(which brew)" && -n "$(which ruby)" ]]; then
      log "'brew' installer not found, attempting to install..."
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      log "'brew' installation completed."
    fi
    if [[ "$FORCE" == true ]]; then
      log "Updating 'brew'..."
      brew update
    fi

    #-- GIT:
    log "Installing/updating external dependency: git"
    if [[ -z "$(which git)" ]]; then
      brew install git
      log "Please review any setup requirements for 'git' from: https://git-scm.com/downloads"
    elif [[ "$FORCE" == true ]]; then
      brew upgrade git
    fi

    #-- Docker:
    log "Installing/updating external dependency: docker"
    if [[ -z "$(which docker)" ]]; then
      brew cask install docker
      log  "Please review any setup requirements for 'docker' from: https://docs.docker.com/engine/installation/"
    elif [[ "$FORCE" == true ]]; then
      brew cask reinstall docker
    fi

     #-- kubectl:
    log "Installing/updating external dependency: kubectl"
    if [[ -z "$(which kubectl)" || "$FORCE" == true ]]; then
      curl --progress-bar -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
      $SUDO mv ./kubectl /usr/local/bin/kubectl
      $SUDO chmod +x /usr/local/bin/kubectl
      log  "Please review any setup requirements for 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    fi

    #-- helm:
    log "Installing/updating external dependency: helm"
    if [[ -z "$(which helm)" ]]; then
      brew install kubernetes-helm
      log  "Please review any setup requirements for 'helm' from: https://github.com/kubernetes/helm/blob/master/docs/install.md"
    elif [[ "$FORCE" == true ]]; then
      brew upgrade kubernetes-helm
    fi
    ;;


  "Linux")
    log "Checking for and updating 'apt-get' support on Linux"
    if [[ -z "$(which apt-get)" ]]; then
      error "'apt-get' is not found.  Thats the only linux installer I know, sorry."
    fi
    if [[ -z "$(which add-apt-repository)" ]]; then
      $SUDO apt-get install -y software-properties-common python-software-properties
    fi
    $SUDO add-apt-repository -y ppa:git-core/ppa
    $SUDO apt-get -y update

    #-- CURL:
    log "Installing/updating external dependency: curl"
    if [[ -z "$(which curl)" || "$FORCE" == true ]]; then
      $SUDO apt-get -y install curl
    fi
    #-- GIT:
    log "Installing/updating external dependency: git"
    if [[ -z "$(which git)" || "$FORCE" == true ]]; then
      $SUDO apt-get -y install git
      log  "Please review any setup requirements for 'git' from: https://git-scm.com/downloads"
    fi

    #-- Docker:
    log "Installing/updating external dependency: docker"
    if [[ -z "$(which docker)" || "$FORCE" == true ]]; then
      curl -fsSL get.docker.com | $SUDO sh -
      if [ "$SUDO" ]; then
        # Allow docker to run as a non-root user (if not running as root).
        sudo groupadd docker 2>/dev/null
        sudo usermod -aG docker $USER  2>/dev/null
      else
        log 'If you want to run docker without sudo run: "sudo groupadd docker && sudo usermod -aG docker $USER"'
      fi
      log  "Please review any setup requirements for 'docker' from: https://docs.docker.com/engine/installation/"
    fi

    #-- kubectl:
    log "Installing/updating external dependency: kubectl"
    if [[ -z "$(which kubectl)" || "$FORCE" == true ]]; then
      curl --progress-bar -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
      $SUDO mv ./kubectl /usr/local/bin/kubectl
      $SUDO chmod +x /usr/local/bin/kubectl
      log  "Please review any setup requirements for 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    fi

    #-- helm:
    log "Installing/updating external dependency: helm"
    if [[ -z "$(which helm)" || "$FORCE" == true ]]; then
      curl -fsSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
      log  "Please review any setup requirements for 'helm' from: https://github.com/kubernetes/helm/blob/master/docs/install.md"
    fi

    ;;
  esac

}

#------------------------------------------------------------------------------
function install_bx {
  if [[ -z "$(which bx)" ]]; then
    log "Installing IBM Cloud 'bx' CLI for platform '${PLATFORM}'..."
    case "$PLATFORM" in
    "Darwin")
      log "Downloading and installing IBM Cloud 'bx' CLI from: ${IDT_INSTALL_BMX_URL}/osx"
      sh <(curl -fsSL ${IDT_INSTALL_BMX_URL}/osx)
      ;;
    "Linux")
      log "Downloading and installing IBM Cloud 'bx' CLI from: ${IDT_INSTALL_BMX_URL}/linux"
      sh <(curl -fsSL ${IDT_INSTALL_BMX_URL}/linux)
      ;;
    esac
    log "IBM Cloud 'bx' CLI install finished."
  else #-- Upgrade
    log "Updating existing IBM Cloud 'bx' CLI..."
    bx update
  fi
  log "Running 'bx --version'..."
  bx --version
}

#------------------------------------------------------------------------------
function install_plugins {
  #-- BX plugins to process
  PLUGINS=(
    "cloud-functions"
    "container-registry"
    "container-service"
    "dev"
    "sdk-gen"
  )

  log "Installing/updating IBM Cloud CLI plugins used by IDT..."
  for plugin in "${PLUGINS[@]}"; do
    log "Checking status of plugin: ${plugin}"
    read -r p ver <<< "$(bx plugin list | grep "^${plugin} ")"
    if [[ -z "$p" ]]; then
      log "Installing plugin '$plugin'"
      bx plugin install -r "${IDT_INSTALL_BMX_REPO_NAME}" "$plugin"
    else
      log "Updating plugin '$plugin' from version '$ver'"
      bx plugin update -r "${IDT_INSTALL_BMX_REPO_NAME}" "$plugin"
    fi
  done
  log "Running 'bx plugin list'..."
  bx plugin list
  log "Finished installing/updating plugins"
}

#------------------------------------------------------------------------------
function env_setup {
  idt_prog="/usr/local/bin/idt"
  env_file=""

  if   [[ -f ~/.bashrc ]]      ; then env_file=~/.bashrc
  elif [[ -f ~/.bash_profile ]]; then env_file=~/.bash_profile
  elif [[ -f ~/.profile ]]     ; then env_file=~/.profile
  fi

  #-- Clear up any old aliases
  if [[ -n "$(grep 'alias idt="bx dev"' "$env_file")" ]]; then
    log "Removing old 'idt' aliases from: ${env_file}"
    sed -E -i ".idt_uninstall_bak" \
          -e '/^#-- Added by the IDT Installer$/d' \
          -e '/^alias idt=\"bx dev\"$/d' \
          -e '/^alias idt-update=/d' \
          -e '/^alias idt-uninstall=/d' \
          ${env_file}
    warn "Please restart your shell so old 'idt' alias does not get picked up!"
    warn "Symptom is: running 'idt update' results in 'update is not a defined command'."
  fi

  if [[ "$1" == "add" ]]; then
    idt_launch_ver=$(grep "# Version:" /usr/local/bin/idt 2>/dev/null | cut -d':' -f2)
    if [[ ! -f "$idt_prog" || "$FORCE" == true || "${idt_launch_ver}" != "$VERSION" ]]; then
      cat <<-!!EOF > ~/idt
				#!/bin/bash
				#-----------------------------------------------------------
				# IBM Cloud Developer Tools (IDT)
				# Version:${VERSION}
				# Wrapper for the 'bx dev' command, and external helpers.
				#-----------------------------------------------------------
				# Syntax:
				#   idt                               - Run 'bx dev <args>'
				#   idt update    [--trace] [--force] - Update IDT and deps
				#   idt uninstall [--trace]           - Uninstall IDT
				#-----------------------------------------------------------
				if [[ "\$1" == "update" || "\$1" == "uninstall" ]]; then
				  echo "IDT launcher action: \$1"
				  tmp=\$(mktemp -d 2>/dev/null || mktemp -d -t 'idttmpdir')
				  echo "Fetching latest installer to: \$tmp/idt-installer"
				  curl -sL https://ibm.biz/idt-installer -o \$tmp/idt-installer
				  bash -- \$tmp/idt-installer \$*
				  rm -r \$tmp
				else
				  bx dev \$*
				fi
				#-----------------------------------------------------------
			!!EOF
      $SUDO mv ~/idt $idt_prog
      $SUDO chmod 755 $idt_prog
      log "The following shortcuts defined to access the IBM Cloud Developer Tools CLI:"
      log "  ${GRN}idt${NRM}           : Main command, shorthand for '${CYN}bx dev${NRM}'"
      log "  ${GRN}idt update${NRM}    : Update your IBM Cloud Developer Tools to the latest version"
      log "  ${GRN}idt uninstall${NRM} : Uninstall the IBM Cloud Developer Tools"
    fi
  elif [[ "$1" == "remove" ]]; then
    $SUDO rm -f $idt_prog
  else
    error "Internal error - called with invalid parameter: ${1}"
  fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
function main {
  log "--==[ ${GRN}${PROG}, v${VERSION}${NRM} ]==--"
  (( SECS = SECONDS ))

  TMPDIR=${TMPDIR:-"/tmp"}
  PLATFORM=$(uname)
  ACTION=""

  # Only use sudo if not running as root:
  [ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""

  #-- Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
    "--trace")
      warn "Enabling verbose tracing of all activity"
      set -x
      ;;
    "--force")
      FORCE=true
      warn "Forcing updates for all dependencies and other settings"
      ;;
    "update")     ACTION="install";;
    "install")    ACTION="install";;
    "uninstall")  ACTION="uninstall";;
    "help")       ACTION="help";;
    esac
    shift
  done

  case "$PLATFORM" in
  "Darwin")
    ;;
  "Linux")
    # Linux distro, e.g "Ubuntu", "RedHatEnterpriseWorkstation", "RedHatEnterpriseServer", "CentOS", "Debian"
    DISTRO=$(lsb_release -is 2>/dev/null || echo "")
    if [ "$DISTRO" != Ubuntu ]; then
      warn "Linux has only been tested on Ubuntu, please let us know if you use this utility on other Distros"
    fi
    ;;
  *)
    warn "Only MacOS and Linux systems are supported by this installer."
    warn "For Windows, please follow manual installation instructions at:"
    warn "${GIT_URL}"
    error "Unsupported platform: ${PLATFORM}"
    ;;
  esac

  case "$ACTION" in
  "")           install;;
  "install")    install;;
  "uninstall")  uninstall;;
  *)            help;;
  esac

  (( SECS = SECONDS - SECS ))
  log "--==[ ${GRN}Total time: ${SECS} seconds${NRM} ]==--"
}

#------------------------------------------------------------------------------
#-- Kick things off
#------------------------------------------------------------------------------
main "$@"