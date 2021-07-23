#!/bin/bash -
#title           :MacosInstall.sh
#description     :This script will set up a Mac to the Vonage standard.
#author		       :Toby Salt
#date            :21/7/2021
#version         :2.0.0
#usage		       :sudo sh MacosInstall.sh
#==============================================================================

clear && rm -rf ~/macapps && mkdir ~/macapps > /dev/null && cd ~/macapps

#############################
##        Variables        ##
#############################


versionChecker() {
	local v1=$1; local v2=$2;
	while [ `echo $v1 | egrep -c [^0123456789.]` -gt 0 ]; do
		char=`echo $v1 | sed 's/.*\([^0123456789.]\).*/\1/'`; char_dec=`echo -n "$char" | od -b | head -1 | awk {'print $2'}`; v1=`echo $v1 | sed "s/$char/.$char_dec/g"`; done
	while [ `echo $v2 | egrep -c [^0123456789.]` -gt 0 ]; do
		char=`echo $v2 | sed 's/.*\([^0123456789.]\).*/\1/'`; char_dec=`echo -n "$char" | od -b | head -1 | awk {'print $2'}`; v2=`echo $v2 | sed "s/$char/.$char_dec/g"`; done
	v1=`echo $v1 | sed 's/\.\./.0/g'`; v2=`echo $v2 | sed 's/\.\./.0/g'`;
	checkVersion "$v1" "$v2"
}

checkVersion() {
	[ "$1" == "$2" ] && return 1
	v1f=`echo $1 | cut -d "." -f -1`;v1b=`echo $1 | cut -d "." -f 2-`;v2f=`echo $2 | cut -d "." -f -1`;v2b=`echo $2 | cut -d "." -f 2-`;
	if [[ "$v1f" != "$1" ]] || [[ "$v2f" != "$2" ]]; then [[ "$v1f" -gt "$v2f" ]] && return 1; [[ "$v1f" -lt "$v2f" ]] && return 0;
		[[ "$v1f" == "$1" ]] || [[ -z "$v1b" ]] && v1b=0; [[ "$v2f" == "$2" ]] || [[ -z "$v2b" ]] && v2b=0; checkVersion "$v1b" "$v2b"; return $?
	else [ "$1" -gt "$2" ] && return 1 || return 0; fi
}

appStatus() {
  if [ ! -d "/Applications/$1" ]; then echo "uninstalled"; else
    if [[ $5 == "build" ]]; then BUNDLE="CFBundleVersion"; else BUNDLE="CFBundleShortVersionString"; fi
    INSTALLED=`/usr/libexec/plistbuddy -c Print:$BUNDLE: "/Applications/$1/Contents/Info.plist"`
      if [ $4 == "dmg" ]; then COMPARETO=`/usr/libexec/plistbuddy -c Print:$BUNDLE: "/Volumes/$2/$1/Contents/Info.plist"`;
      elif [[ $4 == "zip" || $4 == "tar" ]]; then COMPARETO=`/usr/libexec/plistbuddy -c Print:$BUNDLE: "$3$1/Contents/Info.plist"`; fi
    checkVersion "$INSTALLED" "$COMPARETO"; UPDATED=$?;x§
    if [[ $UPDATED == 1 ]]; then echo "updated"; else echo "outdated"; fi; fi
}
installApp() {
  echo $'\360\237\214\200  - ['$2'] Downloading app...'
  if [ $1 == "dmg" ]; then curl -s -L -o "$2.dmg" $4; yes | hdiutil mount -nobrowse "$2.dmg" -mountpoint "/Volumes/$2" > /dev/null;
    if [[ $(appStatus "$3" "$2" "" "dmg" "$7") == "updated" ]]; then echo $'\342\235\214  - ['$2'] Skipped because it was already up to date!\n';
    elif [[ $(appStatus "$3" "$2" "" "dmg" "$7") == "outdated" && $6 != "noupdate" ]]; then ditto "/Volumes/$2/$3" "/Applications/$3"; echo $'\360\237\214\216  - ['$2'] Successfully updated!\n'
    elif [[ $(appStatus "$3" "$2" "" "dmg" "$7") == "outdated" && $6 == "noupdate" ]]; then echo $'\342\235\214  - ['$2'] This app cant be updated!\n'
    elif [[ $(appStatus "$3" "$2" "" "dmg" "$7") == "uninstalled" ]]; then cp -R "/Volumes/$2/$3" /Applications; echo $'\360\237\221\215  - ['$2'] Succesfully installed!\n'; fi
   hdiutil unmount "/Volumes/$2" > /dev/null && rm "$2.dmg"
  elif [ $1 == "zip" ]; then curl -s -L -o "$2.zip" $4; unzip -qq "$2.zip";
    if [[ $(appStatus "$3" "" "$5" "zip" "$7") == "updated" ]]; then echo $'\342\235\214  - ['$2'] Skipped because it was already up to date!\n';
    elif [[ $(appStatus "$3" "" "$5" "zip" "$7") == "outdated" && $6 != "noupdate" ]]; then ditto "$5$3" "/Applications/$3"; echo $'\360\237\214\216  - ['$2'] Successfully updated!\n'
    elif [[ $(appStatus "$3" "" "$5" "zip" "$7") == "outdated" && $6 == "noupdate" ]]; then echo $'\342\235\214  - ['$2'] This app cant be updated!\n'
    elif [[ $(appStatus "$3" "" "$5" "zip" "$7") == "uninstalled" ]]; then mv "$5$3" /Applications; echo $'\360\237\221\215  - ['$2'] Succesfully installed!\n'; fi;
    rm -rf "$2.zip" && rm -rf "$5" && rm -rf "$3"
  elif [ $1 == "tar" ]; then curl -s -L -o "$2.tar.bz2" $4; tar -zxf "$2.tar.bz2" > /dev/null;
    if [[ $(appStatus "$3" "" "$5" "tar" "$7") == "updated" ]]; then echo $'\342\235\214  - ['$2'] Skipped because it was already up to date!\n';
    elif [[ $(appStatus "$3" "" "$5" "tar" "$7") == "outdated" && $6 != "noupdate" ]]; then ditto "$3" "/Applications/$3"; echo $'\360\237\214\216  - ['$2'] Successfully updated!\n';
    elif [[ $(appStatus "$3" "" "$5" "tar" "$7") == "outdated" && $6 == "noupdate" ]]; then echo $'\342\235\214  - ['$2'] This app cant be updated!\n'
    elif [[ $(appStatus "$3" "" "$5" "tar" "$7") == "uninstalled" ]]; then mv "$5$3" /Applications; echo $'\360\237\221\215  - ['$2'] Succesfully installed!\n'; fi
    rm -rf "$2.tar.bz2" && rm -rf "$3"; fi
}

#############################
##        functions        ##
#############################

function initalSetup {
  echo 'Initial Setup'
  #Install Rosetta 2
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license

  # Set Hostname
  if ! $($hostname) | grep -q -E '[A-Z][0-9]{20}' ; then

    # Set machine hostname
    serialNo=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk -F ':' '{print $2}'  | awk -F "[: ]+" '{print $2}' )
    # Make sure hostname conforms to our standard
      hostname="VON-${serialNo}"
      scutil --set HostName $hostname
      scutil --set LocalHostName $hostname
      scutil --set ComputerName $hostname

      echo 'Hostname set to -' $hostname
    else
      echo -e 'Please enter a valid hostname following VONMAC-SerialNumber.'
      exit

  fi

  # Run installs
  installNoMAD
  installAirwatch
  installTrend
  installChrome
  installSlack
  installVBC
  installPulse

}

function installNoMAD {

  echo 'Install NoMAD'
  # Check if NoMAD is installed, install if it is not
  if [ ! -d /Applications/NoMAD.app ]; then
    # Download current NoMAD Release
    curl --progress-bar -o /tmp/NoMAD.pkg https://files.nomad.menu/NoMAD.pkg
    # Install the pkg
    installer -pkg "/tmp/NoMAD.pkg" -target /
  else
    echo 'NoMAD is already installed'
  fi
  # NoMAD conf file location
  nomadConf='/Library/Preferences/com.trusourcelabs.NoMAD'
  echo "Recreating NoMAD config file at ${nomadConf}"
  # Remove NoMAD Conf file
  rm -f $nomadConf
  ## Set NoMAD Config options
  # Enable password sync
  defaults write $nomadConf LocalPasswordSync -bool true
  # Use the keychain
  defaults write $nomadConf UseKeychain -bool true
  # Set password policy
  defaults write $nomadConf PasswordPolicy -dict minLength 8 minLowerCase 1 minNumber 1 minUpperCase 1
  # Message for users when changing password
  defaults write $nomadConf MessagePasswordChangePolicy -string "Your password is required to have a minimum of 8 characters, atleast 1 uppercase letter, atleast 1 lowercase letter and atleast 1 number"
  # Message for when a user is asked for their local password to sync their network password to the local account
  defaults write $nomadConf MessageLocalSync -string "Please enter your current computer password"
  # Add NoMAD to login items
  defaults write $nomadConf LoginItem -bool true
  # Hide the option to quit NoMAD
  defaults write $nomadConf HideQuit -bool true
  # Hide the preferences option
  defaults write $nomadConf HidePrefs -bool true
  # Set the AD Domain
  defaults write $nomadConf ADDomain -string "vonage.net"
  # Set 'Get help' menu item to open an email to thesupportsquad@vonage.com
  defaults write $nomadConf GetHelpType -string 'URL'
  defaults write $nomadConf GetHelpOptions -string 'mailto:thesupportsquad@vonage.com'
  # Check for unnoticed password changes
  defaults write $nomadConf UPCAlert -bool true
  defaults write $nomadConf MessageUPCAlert -string "Your password has been changed from somewhere other than this machine."

}

function installTrend {
  echo 'Install Trend Apex One'
  if [ ! -d /Applications/TrendMicroSecurity.app ]; then
    curl --progress-bar -o ~/downloads/tmsminstall.zip https://macos-build-storage.s3-eu-west-1.amazonaws.com/tmsminstall.zip
    cd ~/downloads/
    ls
    unzip -d ~/downloads/tmsminstall/ tmsminstall.zip
    installer -pkg ~/downloads/tmsminstall/tmsminstall/tmsminstall.pkg -target /
  else
    echo 'TrendMicro Apex One is already installed'
  fi
}

function installAirwatch {
  echo 'Install Airwatch Workspace One'
  if [ ! -d /Applications/Workspace\ ONE\ Intelligent\ Hub.app ]; then
    curl --progress-bar -o /tmp/Airwatch.pkg https://packages.vmware.com/wsone/VMwareWorkspaceONEIntelligentHub.pkg
    installer -pkg /tmp/Airwatch.pkg -target /
  else
    echo 'Airwatch is already installed'
  fi
}

function installChrome {
  echo 'Install Google Chrome'
  if [ ! -d /Applications/Google\ Chrome.app ]; then
    installApp "dmg" "Chrome" "Google Chrome.app" "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg" "" "" ""
  else
    echo 'Google Chrome is already installed'
  fi
}

function installSlack {
  echo 'Install Slack'
  if [ ! -d /Applications/Slack.app ]; then
    installApp "dmg" "Slack" "Slack.app" "https://slack.com/ssb/download-osx" "" "" ""
  else
    echo 'Slack is already installed'
  fi
}

function installVBC {
  echo 'Install Vonage Business'
  if [ ! -d /Applications/Vonage\ Business.app ]; then
    installApp "dmg" "VonageBusinessSetup" "Vonage Business.app" "https://macos-build-storage.s3-eu-west-1.amazonaws.com/VonageBusinessSetup.dmg" "" "" ""
  else
    echo 'VBC is already installed'
  fi
}

function installPulse {
  echo 'Install Pulse Secure'
    if [ ! -d /Applications/Pulse\ Secure.app ]; then
      curl --progress-bar -o ~/downloads/pulsesecure.pkg https://macos-build-storage.s3.eu-west-1.amazonaws.com/PulseSecure.pkg
      installer -pkg ~/downloads/pulsesecure.pkg -target /
      rm ~/downloads/pulsesecure.pkg
  else
    echo 'Pulse is already installed'
  fi
}

function printHelp {
  echo 'Usage: ./MacOS-Setup.sh -i'
  echo '      -h to print this menu'
  echo '      -i to do an initial setup'
  echo '      -n to install NoMAD'
  echo '      -t to install Trend Micro'
  echo '      -a to install Airwatch'
  echo '      -s to install Slack'
  echo '      -c to install Chrome'
  echo '      -v to install Vonage Business'
  echo '      -p to install Pulse Secure'
}

function isRoot {
  if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit 1
  fi
}


#############################
##          Main           ##
#############################

# Print help if there are no parameters passed
if [ -z $1 ]; then
  printHelp
fi

while getopts nitaschvp option; do
  case "${option}" in

    n)  isRoot
        installNoMAD
        ;;

    i)  isRoot
        initalSetup
        ;;

    t)  isRoot
        installTrend
        ;;

    a)  isRoot
        installAirwatch
        ;;

    s)  isRoot
        installSlack
        ;;

    c)  isRoot
        installChrome
        ;;

    v)  isRoot
        installVBC
        ;;

    p) isRoot
        installPulse
        ;;

    h)  printHelp ;;
    *)  echo 'Not a valid option.'
        printHelp
        ;;

  esac
done

rm -rf ~/macapps
