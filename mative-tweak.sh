#!/bin/bash
SCRIPT_VERSION="0.0.1"
UBUNTU_VERSION=$(lsb_release -sd)
KERNEL_RELEASE=$(uname -r)
KERNEL_VERSION=$(uname -v)
user=$(whoami)
hostname=$(hostname)
prompt="$user@$hostname:~#"
GREEN='\e[32m' # set the color to green
NC='\e[0m'     # discolor
print_logo() {
    cat << "EOF"
  ____    ____       _     _________  _____  ____   ____  ________
 |_   \  /   _|     / \   |  _   _  ||_   _||_  _| |_  _||_   __  |
   |   \/   |      / _ \  |_/ | | \_|  | |    \ \   / /    | |_ \_|
   | |\  /| |     / ___ \     | |      | |     \ \ / /     |  _| _
  _| |_\/_| |_  _/ /   \ \_  _| |_    _| |_     \ ' /     _| |__/ |
 |_____||_____||____| |____||_____|  |_____|     \_/     |________|
EOF
}

# URL to the new version on GitHub
GITHUB_URL="https://raw.githubusercontent.com/titenko/mative-tweak/master/mative-tweak.sh"

# Function for updating and restarting the script
update_and_restart_script() {
    echo "Updating the script..."
    if curl -s "$GITHUB_URL" -o "$0.tmp"; then
        mv "$0.tmp" "$0"
        chmod +x "$0"
        echo "Script updated successfully. Restarting..."
        sleep 2
        exec "$0" "$@" # Restart the script
    else
        echo "Failed to update the script."
    fi
}

# Check version and update
if [ "$1" = "--update" ]; then
    update_and_restart_script "$@"
    exit 0
fi

function update_and_upgrade {
    while true; do
        clear # Clear the screen
        echo "Update system $UBUNTU_VERSION"
        echo ""
        sudo apt update
        sudo apt upgrade -y
        sudo apt full-upgrade -y
        sudo apt autoremove -y
        echo ""
        echo "System upgrade - completed"
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

# Define functions for executing scripts
function unsnap {
    while true; do
        clear # Clear the screen

        echo "Started the process of cleaning the system from Snap and blocking the installation of Snap "

        read -p "Do you want to remove Snap packages? (1 - Yes, 2 - No): " clean_snap_choice
        if [ "$clean_snap_choice" == "1" ]; then
            # Remove snapd packages
            sudo apt purge snapd -y

            # Remove leftover snap files
            sudo rm -rf /var/snap
            sudo rm -rf /snap

            # Clean the cache
            sudo apt autoremove -y
            sudo apt clean -y

            # Block snapd installation with dpkg
            echo "package snapd hold" | sudo dpkg --set-selections
            echo "package snapd from snapd:amd64 hold" | sudo dpkg --set-selections
            echo "package snapd from snapd:arm64 hold" | sudo dpkg --set-selections

            # Block snapd installation with APT
            echo -e "Package: snapd\nPin: origin ''\nPin-Priority: -1" | sudo tee /etc/apt/preferences.d/nosnap.pref

            # Optionally, you can also remove snapd packages that might be left in the list
            # sudo apt-mark hold snapd

            echo "The system has been successfully cleaned from Snap."
        fi
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function flatpak_installer {
    while true; do
        clear # Clear the screen

        echo "Flatpak installation and configuration"

        # Check if the user is a superuser
        if [ "$EUID" -ne 0 ]; then
            echo "This script requires superuser privileges. Please enter your sudo password to continue."
            sudo "$0" "$@"
            exit $?
        fi

        # Update and install necessary dependencies
        apt update
        apt install -y flatpak

        # Add the Flathub repository
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        # Update the information about available Flatpak packages
        flatpak update

        # Enable system theme integration
        flatpak config --set org.freedesktop.Platform.GL.default-opengl=x11
        flatpak config --set org.freedesktop.Platform.GL.implementation=x11

        # Enable system font integration
        flatpak config --set org.freedesktop.Platform.GL.force-system-fontconfig=true

        # Enable D-Bus integration for access to system services
        flatpak config --set org.freedesktop.DBus.SessionBusUsage=common
        flatpak config --set org.freedesktop.DBus.ApplicationBusUsage=common

        echo "Flatpak is installed and configured with maximum system integration."

        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function firefox_unsnap {
    while true; do
        clear # Clear the screen

        echo "The installation process of the Unsnap version of Firefox has started"
        read -p "Do you want to add a PPA repository and install Firefox from the PPA? (1. Yes, 2. No): " install_firefox_choice
        if [ "$install_firefox_choice" == "1" ]; then
            # Ask the user to choose between stable and beta versions of Firefox
            while true; do
                read -p "Select the Firefox version (1. Stable, 2. Beta): " choice
                case $choice in
                1)
                    repo="ppa:mozillateam/ppa"
                    break
                    ;;
                2)
                    repo="ppa:mozillateam/firefox-next"
                    break
                    ;;
                *)
                    echo "Please enter 1 or 2."
                    ;;
                esac
            done

            # Add the selected Mozilla Firefox repository
            sudo add-apt-repository $repo -y

            echo "The Mozilla Team PPA repository has been successfully added."

            # Create a file to set package priority
            echo '
            Package: *
            Pin: release o=LP-PPA-mozillateam
            Pin-Priority: 1001
            ' | sudo tee /etc/apt/preferences.d/mozilla-firefox

            # Update package information
            sudo apt update

            # Install Firefox
            sudo apt install firefox -y

            echo "Firefox has been successfully installed."
        fi
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function brave_installer {
    while true; do
        clear # Clear the screen

        echo "Install Brave Browser"

        sudo apt install curl -y
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt update -y
        sudo apt install brave-browser -y
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function chromium_installer {
    while true; do
        clear # Clear the screen

        echo "Install the deb version of the Chromium web browser"

        sudo add-apt-repository ppa:saiarcot895/chromium-beta -y
        cat <<__EOF__ | sudo tee /etc/apt/preferences.d/chromium
        Package: *
        Pin: release o=LP-PPA-saiarcot895-chromium-beta
        Pin-Priority: 700
__EOF__
        sudo apt install chromium-browser -y
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function google_chrome_installer {
    while true; do
        clear # Clear the screen

        echo "Install Google Chrome"

        echo ""
        # Ask for user confirmation
        read -p "Do you want to install Google Chrome? (Yes/No) " choice
        case "$choice" in
        y | Y | yes | Yes)
            echo "Installing Google Chrome..."
            ;;
        n | N | no | No)
            echo "Google Chrome installation canceled."
            break
            ;;
        *)
            echo "Invalid choice, exiting."
            exit 1
            ;;
        esac

        # Install dependencies
        sudo apt update
        sudo apt install -y wget

        # Download the latest version of Google Chrome
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

        # Install Google Chrome
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        sudo apt install -f -y

        # Remove the downloaded DEB file
        rm google-chrome-stable_current_amd64.deb
        echo ""
        echo "Google Chrome is installed and ready to use."
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function multimedia_codec {
    while true; do
        clear # Clear the screen

        echo "Install the multimedia codec pack"

        sudo apt install ubuntu-restricted-extras libavcodec-extra libdvd-pkg -y
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function additional_archivers {
    while true; do
        clear # Clear the screen

        echo "Install additional support for archivers"

        sudo apt install p7zip-rar rar unrar unace arj cabextract -y
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function nvidia_installer_v1 {
    while true; do
        clear # Clear the screen

        echo "Automatically installing Nvidia drivers"

        # Add the Nvidia driver repository
        sudo add-apt-repository ppa:graphics-drivers/ppa -y
        # Add the i386 architecture
        sudo dpkg --add-architecture i386
        # Update package information
        sudo apt update
        # Get information about the video adapter
        sudo ubuntu-drivers devices
        # Automatic video driver installation
        sudo ubuntu-drivers autoinstall -y
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function nvidia_installer_v2 {
    while true; do
        clear # Clear the screen

        echo "Automatically installing Nvidia drivers"

        # Add the Nvidia driver repository
        sudo add-apt-repository ppa:graphics-drivers/ppa -y
        # Add the i386 architecture
        sudo dpkg --add-architecture i386
        # Update package information
        sudo apt update
        # Determine the GPU model
        gpu_model=$(lspci -nn | grep -E 'VGA|3D' | grep -i NVIDIA | cut -d ' ' -f 5)
        if [ -z "$gpu_model" ]; then
            echo "Failed to detect Nvidia GPU model."
            exit 1
        fi

        # Install the driver based on the GPU model
        if [ $gpu_model -ge 200 ]; then
            echo "Installing Nvidia driver version 470 or newer for model $gpu_model"
            sudo apt install nvidia-driver-470 -y
        else
            echo "Installing Nvidia driver version 390 for model $gpu_model"
            sudo apt install nvidia-driver-390 -y
        fi
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function nouveau_installer {
    while true; do
        clear # Clear the screen

        echo "Automatically installing Nouveau Nvidia drivers"

        # Checks if the script is run with superuser privileges
        check_root() {
            if [ "$EUID" -ne 0 ]; then
                echo "This script must be run with superuser privileges. Please enter the password to continue."
                sudo "$0" "$@" # Re-run the script with superuser privileges
                exit $?
            fi
        }

        # Removes proprietary drivers and their dependencies
        remove_proprietary_drivers() {
            ubuntu-drivers autoinstall --remove
        }

        # Installs the Nouveau driver
        install_nouveau() {
            # Update the package list
            apt update

            # Install the Nouveau driver package
            apt install xserver-xorg-video-nouveau

            # Reboot the system to apply the changes
            echo "Nouveau installation completed. Please reboot the system to apply the changes."
        }

        # Checks for the presence of installed proprietary NVIDIA drivers
        check_root
        if ubuntu-drivers list | grep -q "nvidia"; then
            remove_proprietary_drivers
        fi

        echo "Installing Nouveau."
        install_nouveau
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function telegram_installer {
    while true; do
        clear # Clear the screen
        echo "Install Telegram Desktopp"
        wget -O telegram.tar.xz https://telegram.org/dl/desktop/linux
        sudo tar xvf telegram.tar.xz -C /opt/
        sudo ln -s /opt/Telegram/Telegram /usr/local/bin/telegram-desktop
        /opt/Telegram/Telegram -- %u
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function ferdium_installer {
    while true; do
        clear # Clear the screen

        echo "Install Ferdium from GitHub - https://github.com/ferdium"

        # URL for Ferdium releases on GitHub
        github_url="https://api.github.com/repos/ferdium/ferdium-app/releases/latest"

        # Use `curl` to fetch data about the latest release
        release_info=$(curl -s "$github_url")

        # Check for errors during data retrieval
        if [ -z "$release_info" ]; then
            echo "Error fetching data from GitHub."
            exit 1
        fi

        # Extract the latest version number
        latest_version=$(echo "$release_info" | grep -oP '"tag_name": "\K[^"]+')

        if [ -z "$latest_version" ]; then
            echo "Failed to retrieve the latest version number."
            exit 1
        fi

        latest_version_v="$latest_version"
        # Remove the letter 'v' from the version number
        latest_version="${latest_version#v}"

        # Form the URL to download the latest version
        download_url="https://github.com/ferdium/ferdium-app/releases/download/$latest_version_v/Ferdium-linux-$latest_version-amd64.deb"

        # Download the deb file
        temp_file="/tmp/ferdium_latest.deb"
        wget "$download_url" -O "$temp_file"

        if [ ! -f "$temp_file" ]; then
            echo "Error downloading the file."
            exit 1
        fi

        # Install the downloaded deb file using apt
        # sudo dpkg -i "$temp_file"
        sudo apt install "$temp_file" -y

        # Remove the downloaded deb file after installation
        rm -f "$temp_file"

        echo "Installation of the latest Ferdium version ($latest_version) is complete."
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function discord_installer {
    while true; do

        echo "Discord Installer"

        # URL for downloading Discord
        DISCORD_DOWNLOAD_URL="https://discord.com/api/download?platform=linux&format=deb"

        # Extract the URL of the latest version of Discord
        LATEST_DISCORD_URL=$(curl -sI $DISCORD_DOWNLOAD_URL | grep -i "location" | awk -F' ' '{print $2}' | tr -d '\r')

        # Check if the URL is available
        if [ -z "$LATEST_DISCORD_URL" ]; then
            echo "Failed to find the URL for downloading Discord."
            exit 1
        fi

        # File name for downloading
        FILE_NAME=$(basename $LATEST_DISCORD_URL)

        # Download Discord
        echo "Downloading Discord..."
        wget -q $LATEST_DISCORD_URL -O $FILE_NAME

        # Install Discord from the downloaded deb file
        echo "Installing Discord..."
        sudo dpkg -i $FILE_NAME

        # Resolve dependencies
        sudo apt install -f

        # Remove the downloaded file
        rm -f $FILE_NAME

        echo "Discord installation completed."
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function xanmod_installer {
    while true; do
        clear # Clear the screen

        echo "Automatic installation of Xanmod kernel with CPU compatibility level detection"

        # Register the PGP key
        wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
        # Add the repository
        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
        # Menu
        echo "Select a branch:"
        echo "1. main"
        echo "2. lts"
        echo "3. edge"
        echo "4. rt"

        branch=""
        while [ "$branch" != "main" ] && [ "$branch" != "lts" ] && [ "$branch" != "edge" ] && [ "$branch" != "rt" ]; do
            read -p "Enter your choice (main/lts/edge/rt): " branch
        done

        while ! grep -q "flags" /proc/cpuinfo; do
            if [ $(wc -l </proc/cpuinfo) -ne 1 ]; then
                exit 1
            fi
        done

        level=0
        if grep -q "lm" /proc/cpuinfo && grep -q "cmov" /proc/cpuinfo && grep -q "cx8" /proc/cpuinfo && grep -q "fpu" /proc/cpuinfo && grep -q "fxsr" /proc/cpuinfo && grep -q "mmx" /proc/cpuinfo && grep -q "syscall" /proc/cpuinfo && grep -q "sse2" /proc/cpuinfo; then
            level=1
        fi

        if [ $level -eq 1 ] && grep -q "cx16" /proc/cpuinfo && grep -q "lahf" /proc/cpuinfo && grep -q "popcnt" /proc/cpuinfo && grep -q "sse4_1" /proc/cpuinfo && grep -q "sse4_2" /proc/cpuinfo && grep -q "ssse3" /proc/cpuinfo; then
            level=2
        fi

        if [ $level -eq 2 ] && grep -q "avx" /proc/cpuinfo && grep -q "avx2" /proc/cpuinfo && grep -q "bmi1" /proc/cpuinfo && grep -q "bmi2" /proc/cpuinfo && grep -q "f16c" /proc/cpuinfo && grep -q "fma" /proc/cpuinfo && grep -q "abm" /proc/cpuinfo && grep -q "movbe" /proc/cpuinfo && grep -q "xsave" /proc/cpuinfo; then
            level=3
        fi

        if [ $level -eq 3 ] && grep -q "avx512f" /proc/cpuinfo && grep -q "avx512bw" /proc/cpuinfo && grep -q "avx512cd" /proc/cpuinfo && grep -q "avx512dq" /proc/cpuinfo && grep -q "avx512vl" /proc/cpuinfo; then
            level=4
        fi

        if [ $level -gt 0 ]; then
            result="x64v$level"
            echo "Branch: $branch"
            echo $result

            # Generate and execute a setup command
            cmd="sudo apt install linux-xanmod-$branch-$result"
            eval $cmd
        fi

        # Prompt the user to return to the menu
        echo ""
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function liquorix_installer_ppa {
    while true; do
        clear # Clear the screen

        echo "Install Liquorix kernel"

        # Add Liquorix repository and keys
        sudo add-apt-repository ppa:damentz/liquorix
        sudo apt-get update

        # Install Liquorix kernel
        sudo apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64

        # Update GRUB
        sudo update-grub
        echo ""
        echo "Liquorix kernel installation is complete. Please reboot your system to use the new kernel."
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function liquorix_installer_scr {
    while true; do
        clear # Clear the screen

        echo "Install Liquorix kernel"

        curl -s 'https://liquorix.net/install-liquorix.sh' | sudo bash
        echo ""
        echo "Liquorix kernel installation is complete. Please reboot your system to use the new kernel."
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function ubuntu_mainline_kernel_ppa {
    while true; do
        clear
        echo ""
        echo " Ubuntu Mainline Kernel Installer from PPA"
        echo ""
        while true; do
            echo " Are you sure you want to continue?"
            echo " 1. Yes"
            echo " 2. No"
            echo ""
            echo "Select an option: Enter 1 for Yes or 2 for No: "
            read -p "$prompt " input
            case "$input" in
            1) #Yes
                echo "Start."
                sleep 2
                # Add the PPA
                sudo add-apt-repository -y ppa:cappelikan/ppa
                sudo apt-get update

                # Install the latest kernel version from the PPA
                sudo apt-get install -y mainline

                # Select the latest kernel version
                latest_kernel=$(ls /lib/modules | grep -oP '\d+\.\d+\.\d+' | sort -V | tail -n1)

                echo "Installed kernel version $latest_kernel."

                # Reboot the system
                echo "Reboot your system to activate the new kernel."

                ;;
            2) #No
                echo "Stop."
                sleep 2
                outer_break=true
                break # Exit the inner loop
                ;;
            *)
                echo "Incorrect option. Please select again."
                sleep 2
                break
                ;;
            esac
            echo ""
            echo "Press 'q' to return to the menu:"
            read -p "$prompt " input
            if [ "$input" == "q" ]; then
                outer_break=true
                break
            fi
        done

        if [ "$outer_break" == true ]; then
            break # Exit the outer loop
        fi
    done

}

function ubuntu_mainline_kernel_src {
    while true; do
        clear
        echo ""
        echo " Ubuntu Mainline Kernel Installer from SRC (Testing)"
        echo ""
        while true; do
            echo " Are you sure you want to continue?"
            echo " 1. Yes"
            echo " 2. No"
            echo ""
            echo "Select an option: Enter 1 for Yes or 2 for No: "
            read -p "$prompt " input
            case "$input" in
            1) #Yes
                echo "Start installing Ubuntu Mainline Kernel."
                sleep 2
                # URL for the directory with deb files
                base_url="https://kernel.ubuntu.com/mainline/"
                latest_version=$(curl -s https://kernel.ubuntu.com/mainline/ | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | sort -V | tail -n 1)
                version=$(curl -s $base_url | grep -oP 'v\d+\.\d+\.\d+' | head -1)
                url="${base_url}${latest_version}/amd64/"

                # Create a folder in the home directory
                target_folder=~/mainline/${latest_version}/amd64
                mkdir -p $target_folder

                # Get a list of deb files in the directory
                files=$(curl -s $url | grep -Eo 'href="[^"]*\.deb"' | sed 's/href="//;s/"//')

                # Download each deb file to the folder
                for file in $files; do
                    wget -P $target_folder "${url}${file}"
                done

                # Print information about the version and request installation confirmation
                echo "You are about to install the kernel version ${latest_version}."

                while true; do
                    read -p "Do you want to continue? (y/n): " answer
                    case $answer in
                    [Yy]*)
                        # Notification of the start of installation
                        echo "Starting the installation of files..."

                        # Install all deb files
                        cd $target_folder
                        sudo dpkg -i *.deb

                        # Check dependencies and installation success
                        if [ $? -eq 0 ]; then
                            echo "Files installed successfully."
                            echo "Removing the mainline folder and its contents."

                            # Attempt to install dependencies
                            sudo apt install -f

                            # Remove the mainline folder and all its contents
                            rm -rf ~/mainline
                        else
                            echo "Installation error. Check dependencies."
                        fi
                        break
                        ;;
                    [Nn]*)
                        echo "Installation canceled. Removing the mainline folder and its contents."
                        rm -rf ~/mainline
                        break
                        ;;
                    *)
                        echo "Please enter 'yes' or 'no'."
                        ;;
                    esac
                done
                ;;
            2) #No
                echo "Stop."
                sleep 2
                outer_break=true
                break # Exit the inner loop
                ;;
            *)
                echo "Incorrect option. Please select again."
                sleep 2
                break
                ;;
            esac
            echo ""
            echo "Press 'q' to return to the menu:"
            read -p "$prompt " input
            if [ "$input" == "q" ]; then
                outer_break=true
                break
            fi
        done

        if [ "$outer_break" == true ]; then
            break # Exit the outer loop
        fi
    done

}

function disable_sudo_passwd {
    while true; do
        clear # Clear the screen

        echo "Disable sudo password entry in terminal"

        sudo bash -c 'echo "$(logname) ALL=(ALL:ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)'
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function vlc_installer {
    while true; do
        clear # Clear the screen

        echo "Installing and configuring VLC player"

        # Update the package list
        sudo apt update # For Debian/Ubuntu

        # Install VLC media player and necessary codecs
        sudo apt install vlc vlc-data vlc-plugin-base vlc-plugin-video-output vlc-l10n -y # For Debian/Ubuntu

        # Check if the system is Ubuntu
        if [ -f /etc/lsb-release ]; then
            sudo apt install ubuntu-restricted-extras -y
        else
            # Install necessary media codecs for Debian
            sudo apt install libavcodec-extra -y
        fi

        # Set VLC as the default application for video files
        xdg-mime default vlc.desktop video/*

        echo "VLC and the necessary codecs have been installed, and VLC is set as the default application for video files."

        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function foliate_installer {
    while true; do
        clear # Clear the screen

        echo "Installing and configuring Foliate"

        # Check for the presence of wget
        if ! command -v wget &>/dev/null; then
            echo "This script requires wget to be installed. Please install it and try again."
            exit 1
        fi

        # Determine the URL of the latest Foliate release
        latest_release_url=$(wget -qO- "https://github.com/johnfactotum/foliate/releases/latest" | grep -o 'https://github.com/johnfactotum/foliate/releases/download/.*.deb')

        # Name of the DEB package file
        deb_package_name="foliate-latest.deb"

        # Download the latest version of Foliate
        wget -O "$deb_package_name" "$latest_release_url"

        # Install Foliate
        sudo dpkg -i "$deb_package_name"
        sudo apt install -f # Install dependencies if needed

        # Remove the downloaded DEB package
        rm "$deb_package_name"

        # Configure file type associations to open with Foliate
        mime_types=("application/epub+zip" "application/pdf" "application/x-mobipocket-ebook" "text/plain")

        for mime_type in "${mime_types[@]}"; do
            xdg-mime default org.gnome.Foliate.desktop "$mime_type"
        done

        echo "Foliate has been successfully installed and configured to open supported file formats!"
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function zram_installer {
    while true; do
        clear # Clear the screen

        echo "zram-config"

        # Check if the current user is an administrator (root)
        if [ "$EUID" -ne 0 ]; then
            echo "This script requires administrator privileges. Please enter your password to run with administrator rights."
            sudo "$0" "$@"
            exit $?
        fi

        # Install zram-config (if not already installed)
        if ! dpkg -l | grep -q "zram-config"; then
            apt update
            apt install zram-config -y
        fi

        # Enable and configure zram
        sed -i 's/COMP_ALGO=lzo/COMP_ALGO=lz4/' /etc/init.d/zram-config
        sed -i 's/MEM_LIMIT=768M/MEM_LIMIT=50%/' /etc/init.d/zram-config

        # Restart the zram-config service
        service zram-config restart

        # Check if zram-config is installed
        if dpkg -l | grep -q "zram-config"; then
            echo "Zram has been successfully installed and configured."
        else
            echo "Installation of zram-config has encountered an error."
        fi
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function papirus_installer {
    while true; do
        clear # Clear the screen

        echo "Papirus Icon Pack"

        wget -qO- https://git.io/papirus-icon-theme-install | sh
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function option22 {
    while true; do
        clear # Clear the screen

        echo "You chose option 22"

        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function about {
    while true; do
        clear # Clear the screen

        echo "About"

        echo ""
        echo "mative-tweak script for system customization and optimization,"
        echo "installation of additional software from third-party repositories."
        echo "The purpose of this script is to save the user from routine tasks after reinstalling the system."
        echo ""
        echo "Issue: https://github.com/titenko/mative-tweak/issues"
        # Prompt the user to return to the menu
        echo ""
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function changelog {
    while true; do
        clear # Clear the screen

        echo "Changelog:"
        echo ""
        # Download the file from the URL and use 'cat' to display its contents
        curl -sS https://raw.githubusercontent.com/titenko/mative-tweak/master/CHANGELOG.md | cat
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            rm -f CHANGELOG.md # Remove the file CHANGELOG.md
            break              # Exit the loop and return to the menu
        fi
    done
}

function reboot {
    while true; do
        clear # Clear the screen

        echo "Rebooting mative-tweak"
        sleep 2

        exec bash "$0"
        #./mative-tweak.sh
        # Prompt the user to return to the menu
        echo ""
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function mative-fetch {
    while true; do
        clear # Clear the screen

        MATIVE_FETCH_VERSION="0.0.1"
        user=$(whoami)
        hostname=$(hostname)
        prompt="$user@$hostname:~#"

        # Clear the screen
        clear

        # Logo
        print_logo

        # Application information
        echo ""
        echo -e "${GREEN} \e[1mmative-fetch${NC} is a command-line system information tool written in bash."
        echo " mative-fetch displays information about your operating system,"
        echo " software and hardware in an aesthetic and visually pleasing way."
        echo ""
        echo " mative-fetch v$MATIVE_FETCH_VERSION (c) Maksym Titenko"
        echo " GitHub: https://github.com/titenko/mative-tweak"
        echo " Discussions: https://github.com/titenko/mative-tweak/discussions"
        echo " Issues: https://github.com/titenko/mative-tweak/issues"
        echo ""

        # Defining a function to obtain information about the system
        get_system_info() {
            GREEN='\e[32m' # set the color to green
            NC='\e[0m'     # discolor

            echo -e "${GREEN} \e[1mSystem Information:${NC}"
            echo ""
            echo -e "${GREEN} \e[1m-------------------${NC}"
            echo -e "${GREEN} \e[1mOS:${NC} $(lsb_release -d | cut -f2-)"
            echo -e "${GREEN} \e[1mHost:${NC} $(hostname)"
            echo -e "${GREEN} \e[1mKernel:${NC} $(uname -r)"
            echo -e "${GREEN} \e[1mUptime:${NC} $(uptime -p)"

            # Counting the number of installed packages using dpkg and flatpak
            dpkg_packages=$(dpkg -l | grep -c '^ii')
            flatpak_packages=$(flatpak list --columns=application | tail -n +2 | wc -l)
            echo -e "${GREEN} \e[1mPackages:${NC} $dpkg_packages (dpkg), $flatpak_packages (flatpak)"

            echo -e "${GREEN} \e[1mShell:${NC} $(echo $SHELL)"
            echo -e "${GREEN} \e[1mResolution:${NC} $(xrandr --current | grep '*' | uniq | awk '{print $1}')"

            echo -e "${GREEN} \e[1m-------------------${NC}"
            echo -e "${GREEN} \e[1mDesktop Environment Information:${NC}"
            desktop_environment=$(echo $XDG_CURRENT_DESKTOP)

            case "$desktop_environment" in
            "GNOME")
                gnome_version=$(gnome-session --version)
                desktop_environment_version=$(echo "$gnome_version" | awk '{print $2}')
                ;;
            "KDE" | "KDE Plasma")
                kde_version=$(kdeinit5 --version)
                desktop_environment_version=$(echo "$kde_version" | awk '{print $3}')
                ;;
            "X-Cinnamon")
                cinnamon_version=$(cinnamon --version)
                desktop_environment_version=$(echo "$cinnamon_version" | awk '{print $2}')
                desktop_environment="Cinnamon $desktop_environment_version" # Replace "X-Cinnamon" with "Cinnamon" and add the version
                ;;
            "XFCE")
                xfce_version=$(xfce4-session --version)
                desktop_environment_version=$(echo "$xfce_version" | awk '{print $2}')
                ;;
            *)
                desktop_environment_version="Not available"
                ;;
            esac

            echo -e "${GREEN} \e[1mDE:${NC} $desktop_environment" # Add a version to the output
            echo -e "${GREEN} \e[1mWM:${NC} $(wmctrl -m | grep "Name:" | cut -d ' ' -f2)"

            # Getting information about the GTK design theme
            if command -v gsettings &>/dev/null; then
                echo -e "${GREEN} \e[1mWM Theme:${NC} $(gsettings get org.gnome.desktop.wm.preferences theme)"
                echo -e "${GREEN} \e[1mTheme:${NC} $(gsettings get org.gnome.desktop.interface gtk-theme)"
            elif [ -n "$GTK2_RC_FILES" ]; then
                wm_theme=$(grep "gtk-theme-name" $GTK2_RC_FILES | cut -d '=' -f2)
                echo -e "${GREEN} \e[1mWM Theme:${NC} $wm_theme"
            else
                echo -e "${GREEN} \e[1mWM Theme:${NC} Not available"
            fi

            # Getting information about icons
            get_icons() {
                # Search in the current theme for icons via gsettings
                icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null)

                if [ $? -eq 0 ] && [ -n "$icons" ]; then
                    echo -e "${GREEN} \e[1mIcons:${NC} $icons"
                else
                    echo -e "${GREEN} \e[1mIcons:${NC} Not available"
                fi
            }

            # Function call
            get_icons

            # Getting information about the terminal
            if [ "$XDG_SESSION_TYPE" == "x11" ]; then
                terminal_name="X Terminal Emulator"
            elif [ "$XDG_SESSION_TYPE" == "wayland" ]; then
                terminal_name="Wayland Terminal"
            else
                # If it was not possible to determine by environment variables, use ps
                terminal_name=$(ps -p $$ -o comm= | sed 's/^-//')
            fi

            echo -e "${GREEN} \e[1mTerminal:${NC} $terminal_name"

            echo -e "${GREEN} \e[1mCPU:${NC} $(grep 'model name' /proc/cpuinfo | uniq | cut -d ':' -f 2 | xargs)"
            echo -e "${GREEN} \e[1mGPU:${NC} $(lspci | grep -i 'VGA\|3D' | sed 's/^.*: //')"

            echo -e "${GREEN} \e[1m-------------------${NC}"
            echo -e "${GREEN} \e[1mPerformance Information:${NC}"
            echo -e "${GREEN} \e[1mCPU Load:${NC}"
            echo ""
            echo -e "${GREEN} \e[1mTotal CPU Load:${NC}"
            echo -e " All cores: $(mpstat | awk '$12 ~ /[0-9.]+/ {printf "%.2f%%\n", 100-$12}' | tail -n 1)"
            echo ""
            echo -e "${GREEN} \e[1mCPU Load per Core:${NC}"
            i=0
            grep -E 'cpu[0-9]+' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} {printf " Core %d: %.2f%%\n", i, usage; i++}'

            echo ""
            echo -e "${GREEN} \e[1mRAM:${NC}"
            total_mem=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
            free_mem=$(awk '/MemAvailable/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
            used_mem=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {available=$2} END {printf "%.2f GB", (total - available) / 1024 / 1024}' /proc/meminfo)
            echo -e " Total: $total_mem"
            echo -e " Used: $used_mem "
            echo -e " Free: $free_mem"

            echo ""
            echo -e "${GREEN} \e[1mDisk Usage:${NC}"
            df -h / | awk 'NR==2 {printf " Total: %s\n Used: %s\n Free: %s\n", $2, $3, $4}' | sed 's/G/ GB/g'
            echo -e "${GREEN} \e[1m-------------------${NC}"
        }

        # Function call
        get_system_info

        # Prompt the user to return to the menu
        echo ""
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function mative_ucaresystem {
    MATIVE_UCS_VERSION="0.0.1"
    while true; do
        clear  # Clear the screen
        # Logo
        print_logo

        # Application information
        echo ""
        echo -e "${GREEN} \e[1mmative-ucaresystem${NC} all-in-one System Update and maintenance assistant app."
        echo " An all-in-one, system maintenance application "
        echo " for Ubuntu/Debian operating systems and derivatives" 
        echo " "
        echo ""
        echo " mative-ucaresystem v$MATIVE_UCS_VERSION (c) Maksym Titenko"
        echo " GitHub: https://github.com/titenko/mative-tweak"
        echo " Discussions: https://github.com/titenko/mative-tweak/discussions"
        echo " Issues: https://github.com/titenko/mative-tweak/issues"
        echo ""
        echo -e "${GREEN} \e[1mMative-uCareSystem:${NC}"
        echo ""
        echo " -------------------------------------------------------------------- "
        echo " Welcome to all-in-one System Update and maintenance assistant app."
        echo ""
        echo " This simple script will automatically refresh your packagelist,"
        echo " download and install updates (if there are any),"
        echo " remove any old kernels,"
        echo " obsolete packages and configuration files to free up disk space,"
        echo " without any need of user interference"
        echo " -------------------------------------------------------------------- "
        echo ""
        echo "You want to run Mative-uCareSystem? (Yes/No) " 
        read -p "$prompt " input
        case "$choice" in
        y|Y|yes|Yes)
        echo ""        
        echo "Start..."
        echo ""
        sleep 2    
        ;;
        n|N|no|No)
        echo ""
        echo "Stop..."
        sleep 2
        break
        ;;
        *)
        echo "Invalid choice, exiting."
        break
        ;;
        esac
    
        echo "Updating package lists"
        sleep 2
        sudo apt update
        echo ""
        echo "Upgrading packages and system libraries"
        echo ""
        sleep 2
        sudo apt upgrade -y
        sudo apt full-upgrade -y
        echo ""
        echo "Removing unneeded packages"
        echo ""
        sleep 2
        sudo apt autoremove --purge -y
        # Remove old kernels
        echo ""
        echo "Removing old kernels"
        echo ""
        sleep 2
        KEEP=2
        APT_OPTS=
        while [ ! -z "$1" ]; do
        case "$1" in
        --keep)
        KEEP="$2"
        shift 2
        ;;
        *)
        APT_OPTS="$APT_OPTS $1"
        shift 1
        ;;
        esac
        done
        # Build list of kernel packages to purge
        CANDIDATES=$(ls -tr /boot/vmlinuz-* | head -n -${KEEP} | grep -v "$(uname -r)$" | cut -d- -f2- | awk '{print "linux-image-" $0 " linux-headers-" $0}' )
        PURGE=""
        for c in $CANDIDATES; do
        dpkg-query -s "$c" >/dev/null 2>&1 && PURGE="$PURGE $c"
        done

        if [ -z "$PURGE" ]; then
        echo ""
        echo "No kernels are eligible for removal"
        echo ""
        else
        sudo apt $APT_OPTS remove -y --purge $PURGE
        fi


        # Remove unused config files
        echo ""
        echo "Removing unused config files"
        echo ""
        sleep 2
        sudo apt autoclean -y
        sudo apt clean -y
        echo ""
        echo "Updating flatpak apps"
        echo ""
        sleep 2
        flatpak update

        echo ""        
        echo "System upgrade - completed"        
        echo ""
        # Prompt the user to return to the menu
        echo "Press 'q' to return to the menu:"
        read -p "$prompt " input
        if [ "$input" == "q" ]; then
            break
        fi
    done
}

# Main menu
while true; do
    clear # Clear the screen
    # Logo
    cat <<"EOF"
  ____    ____       _     _________  _____  ____   ____  ________
 |_   \  /   _|     / \   |  _   _  ||_   _||_  _| |_  _||_   __  |
   |   \/   |      / _ \  |_/ | | \_|  | |    \ \   / /    | |_ \_|
   | |\  /| |     / ___ \     | |      | |     \ \ / /     |  _| _
  _| |_\/_| |_  _/ /   \ \_  _| |_    _| |_     \ ' /     _| |__/ |
 |_____||_____||____| |____||_____|  |_____|     \_/     |________|
EOF
    echo ""
    echo -e "${GREEN} \e[1mmative-tweak${NC} An all-in-one, system maintenance application "
    echo " for Ubuntu/Debian operating systems and derivatives"
    echo ""
    echo ""
    echo " mative-tweak v$SCRIPT_VERSION (c) Maksym Titenko"
    echo " GitHub: https://github.com/titenko/mative-tweak"
    echo " Discussions: https://github.com/titenko/mative-tweak/discussions"
    echo " Issues: https://github.com/titenko/mative-tweak/issues"
    echo ""
    # Display the menu
    echo -e "${GREEN} \e[1mMenu:${NC}"
    echo ""
    echo -e "${GREEN} \e[1m---  Tweaks & Settings${NC}"
    echo " 0.   Update & Upgrade System"
    echo " 1.   Uninstall Snap and block future installation"
    echo " 2.   Flatpak installation and configuration"
    echo " 3.   Install the multimedia codec pack"
    echo " 4.   Install additional support for archivers"
    echo " 5.   Disable sudo password entry in terminal"
    echo " 6.   Zram - Installing and configuring"
    echo -e "${GREEN} \e[1m---  Nvidia${NC}"
    echo " 7.   Automatically installing Nvidia drivers - Version 1"
    echo " 8.   Automatically installing Nvidia drivers - Version 2"
    echo " 9.   Automatically installing Nouveau Nvidia drivers"
    echo -e "${GREEN} \e[1m---  Browsers${NC}"
    echo " 10.  Firefox - Install the deb version of the web browser from PPA"
    echo " 11.  Brave - Install the deb version of the web browser from official repository"
    echo " 12.  Chromium - Install the deb version of the web browser from PPA"
    echo " 13.  Google Chrome - Install the deb version of the web browser from official Google repository"
    echo -e "${GREEN} \e[1m---  Messengers${NC}"
    echo " 14.  Telegram Desktop - Install binary version from official web page"
    echo " 15.  Ferdium - Install the deb version from GitHub"
    echo " 16.  Discord - Install the deb version from official web page"
    echo -e "${GREEN} \e[1m---  Kernels${NC}"
    echo " 17.  Automatic installation of Xanmod kernel with CPU compatibility level detection"
    echo " 18.  Install Liquorix kernel from PPA"
    echo " 19.  Install Liquorix kernel using the developer script"
    echo " 20.  Install Ubuntu Mainline Kernel from PPA"
    echo " 21.  Install Ubuntu Mainline Kernel from SRC (Testing)"
    echo -e "${GREEN} \e[1m---  Apps${NC}"
    echo " 22.  VLC player - Installing and configuring"
    echo " 23.  Foliate - Installing and configuring"
    echo -e "${GREEN} \e[1m---  Themes & Icons${NC}"
    echo " 24.  Papirus Icons Pack - download and install"
    echo -e "${GREEN} \e[1m---  Mative Apps${NC}"
    echo " f.   Mative-Fetch"
    echo " ucs. Mative-uCareSystem"
    echo -e "${GREEN} \e[1m---${NC}"
    echo " a.   About"
    echo " c.   Changelog"
    echo " u.   Check update"
    echo " r.   Reboot mative-tweak"
    echo " e.   Exit"

    # Prompt the user to make a choice
    echo ""
    echo "Select an option (0,1,2,3...) "
    read -p "$prompt " choice

    # Execute the corresponding script based on the user's choice
    case $choice in
    # Tweaks & Settings
    0) update_and_upgrade ;;
    1) unsnap ;;
    2) flatpak_installer ;;
    3) multimedia_codec ;;
    4) additional_archivers ;;
    5) disable_sudo_passwd ;;
    6) zram_installer ;;
    # Nvidia
    7) nvidia_installer_v1 ;;
    8) nvidia_installer_v2 ;;
    9) nouveau_installer ;;
    # Browsers
    10) firefox_unsnap ;;
    11) brave_installer ;;
    12) chromium_installer ;;
    13) google_chrome_installer ;;
    # Messengers
    14) telegram_installer ;;
    15) ferdium_installer ;;
    16) discord_installer ;;
    # Kernels
    17) xanmod_installer ;;
    18) liquorix_installer_ppa ;;
    19) liquorix_installer_scr ;;
    20) ubuntu_mainline_kernel_ppa ;;
    21) ubuntu_mainline_kernel_src ;;
    # Apps
    22) vlc_installer ;;
    23) foliate_installer ;;
    # Themes & Icons
    24) papirus_installer ;;
    25) option22 ;;
    # ---
    f) mative-fetch ;;
    ucs) mative_ucaresystem ;;
    u) update_and_restart_script ;;
    a) about ;;
    c) changelog ;;
    r) reboot ;;
    e)
        echo "Exiting the program."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please try again."
        ;;
    esac
done
