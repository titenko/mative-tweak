# mative-tweak

[![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Ftitenko%2Fmative-tweak&countColor=%23263759)](https://visitorbadge.io/status?path=https%3A%2F%2Fgithub.com%2Ftitenko%2Fmative-tweak)

mative-tweak script for configuring and optimizing Ubuntu/Debian and their derivatives, installing additional software from third-party repositories. The purpose of this script is to save the user from routine tasks after reinstalling the system.

## Install

    wget https://raw.githubusercontent.com/titenko/mative-tweak/master/mative-tweak.sh &&
    chmod +x mative-tweak.sh


![mative-tweak](https://raw.githubusercontent.com/titenko/mative-tweak/master/screenshot/mative-tweak.png)

## Features

**System Setup:**

 - Uninstalling and locking the Snap installation. The script removes
   all Snap packages from the system, cleans the system of remaining
   files, then removes the Snapd daemon and blocks installation of the
   package in the future.
 - Install and configure Flatpak atomically as a better alternative to
   Snap. The script installs all the necessary packages and dependencies
   for Flatpak to work correctly, then integrates them into the system:
   user and system themes, fonts, icons... so that the installed
   applications look harmonious in the system and blend in with the
   user's workspace.
 - Installation of multimedia codecs, for correct operation of media
   files.
 - Installation and customization of extensions for working with
   archives. The script extends the capabilities of the built-in
   archiver, resulting in support for all archive formats, including
   proprietary ones.
 - Automatic installation of Nvidia drivers. The script scans the
   system, detects the user's video card and then installs the optimal
   set of drivers.
 - Installation and automatic configuration of Zram. The script installs
   the zram-config package and then scans the system, determines the
   optimal configuration, then makes changes to the configuration files,
   starts the service and adds it to auto-boot at system startup.

**Unsnap Firefox:**

 - Since in new versions of Ubuntu by default Firefox comes in Snap
   format, there is an option to install Firefox in deb format. The
   script adds the official Mozilla PPA repository to the system and
   then prioritizes installing and updating Firefox only from this
   repository, blocks the stub package that installs Firefox in Snap
   format and installs the deb version of Firefox.

**Installing additional browsers:**

In addition to Unsnap Firefox, the script can also be used to install other browsers in deb format. At the moment the script is used to install the most popular browsers such as 

 - Brave Browser

 - Chromium Browser

 -  Google Chrome

Support for other browsers will be added in the future.

**Kernels:**

 - Xanmod Kernel. The Xanmod kernel supports many different
   architectures and the difficulty in installing this kernel is that
   the packages are divided into different versions for different
   architectures. The script will automatically add a repository,
   determine the required architecture, and then install and configure
   this kernel.
 - Liquorix Kernel. There are two installation options with the addition
   of the developer's PPA repository and installing the kernel from the
   repository, and the Liquorix kernel developers provide their own
   script for installation, which is executed in the second version of
   the installer.

**Themes and applications:**

 - Using the script you can also install additional applications, themes
   and icons. The list of applications will be expanded in future
   versions. First of all, applications that require the addition of
   additional PPA repositories or have a specific installation will be
   added. For example, to install Telegram, the script uses a binary
   file from the developer’s website, the script downloads the latest
   version of the messenger in the archive, unpacks the archive,
   transfers the executable files to the Opt folder, and then runs the
   installation script. When installing the VLC player, the script
   checks for the presence of codecs and extensions and, if necessary,
   installs them, after which it adds the player to the default startup
   for all supported video file formats. To install Ferdium, Discord,
   Foliate... the script downloads the latest version of the deb file
   from the developer's resource, performs the installation and adds
   monitoring to check for updates on the developer's resource if this
   functionality is not provided in the application itself.

**Check update:**

 - The script contains a function to check for updates. Since the script
   is under development, the menu has a function to check for updates,
   if any changes are made to the original version located on GitHub,
   the user can add updates using the script function without having to
   download a new version.

## Roadmap

 - [x]  Structure the script, organize functions and add sections.
        (Priority)
     - [ ] --> Add menus and sections       
 - [ ]  Make cosmetic changes to improve the appearance and simplify
        interactions with the script.
 - [ ]  Organize the code, add comments and change function names for
        better script readability and easier editing.
 - [ ]  Optimize the operation of the Xanmod kernel installer, identify
        and eliminate errors.
 - [ ]  Add a function to update the standard kernel from the Mainline
        branch

**Expand the functionality of the script:**

 - [ ]  Add additional settings and system tweaks

 - [ ]  Expand the list of browsers

 - [ ]  Expand the list of applications

 - [ ]  Expand the list of themes and icons
