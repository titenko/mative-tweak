#!/bin/bash

MATIVE_FETCH_VERSION="0.0.1"
user=$(whoami)
hostname=$(hostname)
prompt="$user@$hostname:~#"

# Очистка экрана
clear

# Логотип
cat << "EOF"
  ____    ____       _     _________  _____  ____   ____  ________
 |_   \  /   _|     / \   |  _   _  ||_   _||_  _| |_  _||_   __  |
   |   \/   |      / _ \  |_/ | | \_|  | |    \ \   / /    | |_ \_|
   | |\  /| |     / ___ \     | |      | |     \ \ / /     |  _| _
  _| |_\/_| |_  _/ /   \ \_  _| |_    _| |_     \ ' /     _| |__/ |
 |_____||_____||____| |____||_____|  |_____|     \_/     |________|
EOF

# Информация о приложении
echo ""
echo " mative-fetch is a command-line system information tool written in bash."
echo " mative-fetch displays information about your operating system,"
echo " software and hardware in an aesthetic and visually pleasing way."    
echo ""
echo " mative-fetch v$MATIVE_FETCH_VERSION (c) Maksym Titenko"
echo " GitHub: https://github.com/titenko/mative-tweak"
echo " Discussions: https://github.com/titenko/mative-tweak/discussions"
echo " Issues: https://github.com/titenko/mative-tweak/issues"
echo ""

# Определение функции для получения информации о системе
get_system_info() {
    GREEN='\e[32m'  # устанавливаем зеленый цвет
    NC='\e[0m'      # сбрасываем цвет

    echo -e "${GREEN} \e[1mSystem Information:${NC}"
    echo -e "${GREEN} \e[1m-------------------${NC}"
    echo -e "${GREEN} \e[1mOS:${NC} $(lsb_release -d | cut -f2-)"
    echo -e "${GREEN} \e[1mHost:${NC} $(hostname)"
    echo -e "${GREEN} \e[1mKernel:${NC} $(uname -r)"
    echo -e "${GREEN} \e[1mUptime:${NC} $(uptime -p)"
    
    # Подсчет количества установленных пакетов с использованием dpkg и flatpak
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
        desktop_environment="Cinnamon $desktop_environment_version"  # Заменить "X-Cinnamon" на "Cinnamon" и добавить версию
        ;;
    "XFCE")
        xfce_version=$(xfce4-session --version)
        desktop_environment_version=$(echo "$xfce_version" | awk '{print $2}')
        ;;
    *)
        desktop_environment_version="Not available"
        ;;
    esac

    echo -e "${GREEN} \e[1mDE:${NC} $desktop_environment"  # Добавить версию к выводу
    echo -e "${GREEN} \e[1mWM:${NC} $(wmctrl -m | grep "Name:" | cut -d ' ' -f2)"

    # Получение информации о теме оформления GTK
    if command -v gsettings &> /dev/null; then
        echo -e "${GREEN} \e[1mWM Theme:${NC} $(gsettings get org.gnome.desktop.wm.preferences theme)"
        echo -e "${GREEN} \e[1mTheme:${NC} $(gsettings get org.gnome.desktop.interface gtk-theme)"
    elif [ -n "$GTK2_RC_FILES" ]; then
        wm_theme=$(grep "gtk-theme-name" $GTK2_RC_FILES | cut -d '=' -f2)
        echo -e "${GREEN} \e[1mWM Theme:${NC} $wm_theme"
    else
        echo -e "${GREEN} \e[1mWM Theme:${NC} Not available"
    fi

    # Получение информации об иконках
    get_icons() {
        # Поиск в текущей теме иконок через gsettings
        icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$icons" ]; then
            echo -e "${GREEN} \e[1mIcons:${NC} $icons"
        else
            echo -e "${GREEN} \e[1mIcons:${NC} Not available"
        fi
    }

    # Вызов функции
    get_icons

    # Получение информации о терминале
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
        terminal_name="X Terminal Emulator"
    elif [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        terminal_name="Wayland Terminal"
    else
        # Если не удалось определить по переменным окружения, используем ps
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


# Вызов функции
get_system_info

