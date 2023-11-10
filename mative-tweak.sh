#!/bin/bash
SCRIPT_VERSION="0.0.1"
UBUNTU_VERSION=$(lsb_release -sd)
KERNEL_RELEASE=$(uname -r)
KERNEL_VERSION=$(uname -v)
user=$(whoami)
hostname=$(hostname)
prompt="$user@$hostname:~#"

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

function disable_sudo_passwd {
    while true; do
        clear # Clear the screen

        echo "Disable sudo password entry in terminal"

        sudo bash -c 'echo "$(logname) ALL=(ALL:ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)'
        # Prompt the user to return to the menu
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

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
        read -p "Press 'q' to return to the menu: " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
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
        read -p "Press 'q' to return to the menu: " input

        if [ "$input" == "q" ]; then
            break # Exit the loop and return to the menu
        fi
    done
}

# Main menu
while true; do
    clear # Clear the screen
    echo ""
    echo "  ____    ____       _     _________  _____  ____   ____  ________  "
    echo " |_   \  /   _|     / \   |  _   _  ||_   _||_  _| |_  _||_   __  | "
    echo "   |   \/   |      / _ \  |_/ | | \_|  | |    \ \   / /    | |_ \_| "
    echo "   | |\  /| |     / ___ \     | |      | |     \ \ / /     |  _| _  "
    echo "  _| |_\/_| |_  _/ /   \ \_  _| |_    _| |_     \ ' /     _| |__/ | "
    echo " |_____||_____||____| |____||_____|  |_____|     \_/     |________| "
    echo ""
    echo " mative-tweak - An all-in-one, system maintenance application "
    echo " for Ubuntu/Debian operating systems and derivatives"
    echo ""
    echo " Your operating system: $UBUNTU_VERSION"
    echo " Your kernel release: $KERNEL_RELEASE"
    echo " Your kernel version: $KERNEL_VERSION"
    echo ""
    echo " mative-tweak v$SCRIPT_VERSION (c) Maksym Titenko"
    echo " GitHub: https://github.com/titenko/mative-tweak"
    echo " Discussions: https://github.com/titenko/mative-tweak/discussions"
    echo " Issues: https://github.com/titenko/mative-tweak/issues"
    echo ""
    # Display the menu
    echo " Menu:"
    echo ""
    echo " --- Tweaks & Settings"
    echo " 0.  Update & Upgrade System"
    echo " 1.  Uninstall Snap and block future installation"
    echo " 2.  Flatpak installation and configuration"
    echo " 3.  Install the multimedia codec pack"
    echo " 4.  Install additional support for archivers"
    echo " 5.  Automatically installing Nvidia drivers - Version 1"
    echo " 6.  Automatically installing Nvidia drivers - Version 2"
    echo " 7.  Disable sudo password entry in terminal"
    echo " 8.  Zram - Installing and configuring"
    echo " --- Browsers"
    echo " 9.  Firefox - Install the deb version of the web browser from PPA"
    echo " 10. Brave - Install the deb version of the web browser from official repository"
    echo " 11. Chromium - Install the deb version of the web browser from PPA"
    echo " 12. Google Chrome - Install the deb version of the web browser from official Google repository"
    echo " --- Messengers"
    echo " 13. Telegram Desktop - Install binary version from official web page"
    echo " 14. Ferdium - Install the deb version from GitHub"
    echo " 15. Discord - Install the deb version from official web page"
    echo " --- Kernels"
    echo " 16. Automatic installation of Xanmod kernel with CPU compatibility level detection"
    echo " 17. Install Liquorix kernel from PPA"
    echo " 18. Install Liquorix kernel using the developer script"
    echo " --- Apps"
    echo " 19. VLC player - Installing and configuring"
    echo " 20. Foliate - Installing and configuring"
    echo " --- Themes & Icons"
    echo " 21. Papirus Icons Pack - download and install"
    echo " --- "
    echo " a.  About"
    echo " u.  Check update"
    echo " r.  Reboot mative-tweak"
    echo " e.  Exit"

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
    5) nvidia_installer_v1 ;;
    6) nvidia_installer_v2 ;;
    7) disable_sudo_passwd ;;
    8) zram_installer ;;
    # Browsers
    9) firefox_unsnap ;;
    10) brave_installer ;;
    11) chromium_installer ;;
    12) google_chrome_installer ;;
    # Messengers
    13) telegram_installer ;;
    14) ferdium_installer ;;
    15) discord_installer ;;
    # Kernels
    16) xanmod_installer ;;
    17) liquorix_installer_ppa ;;
    18) liquorix_installer_scr ;;
    # Apps
    19) vlc_installer ;;
    20) foliate_installer ;;
    # Themes & Icons
    21) papirus_installer ;;
    22) option22 ;;
    # ---
    u) update_and_restart_script ;;
    a) about ;;
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
