#!/bin/bash

# Function to ask yes or no questions
ask_yes_no() {
    while true; do
        read -p "$1 (Yy/Nn) [Y]: " response
        case "$response" in
            [Yy]* | "" ) return 0 ;;   # empty input defaults to yes
            [Nn]* ) return 1 ;;
            * ) echo "Please answer with y or n." ;;
        esac
    done
}

# Function to check and enable multilib repository
enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "Enabling multilib repository..."
        sudo tee -a /etc/pacman.conf > /dev/null <<EOT

[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
        echo "Multilib repository has been enabled."
    else
        echo "Multilib repository is already enabled."
    fi
}

# Function to install yay
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd .. && rm -rf yay
        export PATH="$PATH:$HOME/.local/bin"
    else
        echo "yay is already installed."
    fi
}

# Function to enable chaotic aur
enable_chaotic_aur() {
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo "Chaotic AUR is already enabled."
    else
        echo "Enabling Chaotic AUR..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
    fi
}

# Function to install AMD GPU drivers and tools
install_amd() {
    echo "Installing AMD GPU drivers and tools..."
    sudo pacman -S --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
    yay -S lact
}

# Function to install Nvidia GPU drivers and tools
install_nvidia() {
    echo "Installing Nvidia GPU drivers and tools..."

    if ask_yes_no "Do you have an RTX gpu?"; then
        sudo pacman -S --needed nvidia-open-dkms
    else
        sudo pacman -S --needed nvidia-dkms
    fi

    sudo pacman -S --needed nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia egl-wayland libva-nvidia-driver
    
    echo "Editing /etc/mkinitcpio.conf to add Nvidia modules..."
    sudo sed -i 's/^MODULES=(/&nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf

    echo "Creating and editing /etc/modprobe.d/nvidia.conf..."
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf

    echo "Rebuilding the initramfs..."
    sudo mkinitcpio -P

    echo "Adding environment variables to ~/.config/hypr/env_variables.conf..."
    mkdir -p ~/.config/hypr
    cat <<EOL >> ~/.config/hypr/env_variables.conf
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia_drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct

cursor {
    no_hardware_cursors = true
}
EOL

    echo "Enabling required services..."
    sudo systemctl enable nvidia-suspend.service
    sudo systemctl enable nvidia-hibernate.service
    sudo systemctl enable nvidia-resume.service

    echo "Adding kernel parameter to refind..."
    sudo sed -i '/"Boot using default options"/s/\(.*\)"/\1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"/' /boot/refind_linux.conf
}

# Packages to install
# System Utilities
SYSTEM_UTILS=(
    micro os-prober btop pacman-contrib reflector zenity wget zoxide man gdb
)

AUR_SYSTEM_UTILS=(
    auto-cpufreq aurutils arch-update
)

# Display, Desktop & Compositors
DESKTOP_ENVIRONMENT=(
    hyprland hyprlock hypridle hyprwayland-scanner kitty swww plymouth 
    wl-clipboard wl-clip-persist grim slurp wlr-randr
)

AUR_DESKTOP_ENVIRONMENT=(
    hyprpicker grimblast-git xwaylandvideobridge
)

# Qt & KDE Support
QT_KDE_SUPPORT=(
    qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt5-wayland 
    qt6-wayland qt6-5compat qt6-declarative qt6-svg qt6-virtualkeyboard 
    qt6-multimedia-ffmpeg qt5ct qt6ct kvantum kvantum-qt5
)

# Themes, Fonts & Appearance
THEMES_FONTS=(
    noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme 
    ttf-firacode-nerd ttf-meslo-nerd ttf-ubuntu-font-family 
    gnome-font-viewer adw-gtk-theme libadwaita
)

AUR_THEMES_FONTS=(
    bibata-cursor-theme ttf-meslo-nerd-font-powerlevel10k
)

# Audio & Multimedia
AUDIO_MULTIMEDIA=(
    pipewire wireplumber pipewire-alsa pipewire-audio pipewire-jack 
    pipewire-pulse gst-plugin-pipewire gst-plugins-base gst-plugins-good 
    gst-plugins-bad gst-plugins-ugly pavucontrol pamixer playerctl 
    ffmpegthumbnailer vlc gstreamer kooha
)

# Networking
NETWORKING=(
    networkmanager network-manager-applet socat firewalld bluez 
    bluez-utils blueman
)

# File & Disk Utilities
FILE_DISK_UTILS=(
    pcmanfm ark cpio file-roller unzip zip 7zip unrar gnome-disk-utility baobab
)

# Auth & Portal
AUTH_PORTAL=(
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome gnome-keyring
)

# Image & Graphics
IMAGE_GRAPHICS=(
    imagemagick tumbler gwenview
)

AUR_IMAGE_GRAPHICS=(
    pinta dopamine-appimage-preview
)

# Development Tools
DEV_TOOLS=(
    meson cmake pkgconf python-pipx python-pillow python-numpy python-scikit-learn
)

AUR_DEV_TOOLS=(
    visual-studio-code-bin github-desktop
)

# Office & Docs
OFFICE_DOCS=(
    libreoffice-fresh evince
)

# Misc GUI Apps
GUI_APPS=(
    nwg-look nwg-displays gnome-clocks yad
)

AUR_GUI_APPS=(
    floorp-bin gapless waypaper
)

# Misc Tools
MISC_TOOLS=(
    brightnessctl xdg-user-dirs fastfetch jq curl bc
)

AUR_MISC_TOOLS=(
    hardcode-fixer-git
)

# Gaming packages to install
GAMING_PACKAGES=(
    steam wine-staging winetricks gamemode lib32-gamemode
    giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap
    gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal
    v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error
    alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib
    libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite
    libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader
    libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3
    gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
    mangohud lib32-mangohud goverlay gamescope
)

# AUR gaming packages to install
GAMING_PACKAGES_YAY=(
    vkbasalt lib32-vkbasalt dxvk-bin protontricks
)

echo "Installing poketop dotfiles..."

# Enhance git
echo "Enhancing git..."
git config --global http.postBuffer 157286400

# Enhance pacman
echo "Configuring pacman..."
sudo sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/; s/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf && \
sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
enable_multilib

# Install yay
install_yay
enable_chaotic_aur

# Make package compression faster
echo "Reducing package compression time..."
sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/COMPRESSZST=(zstd -c -T0 --fast -)/' /etc/makepkg.conf

# Enable TRIM for SSDs
sudo systemctl enable fstrim.timer

# install packages
echo "Installing required packages..."

# All pacman package groups
ALL_PACMAN_GROUPS=(
    SYSTEM_UTILS
    DESKTOP_ENVIRONMENT
    QT_KDE_SUPPORT
    THEMES_FONTS
    AUDIO_MULTIMEDIA
    NETWORKING
    FILE_DISK_UTILS
    AUTH_PORTAL
    IMAGE_GRAPHICS
    DEV_TOOLS
    OFFICE_DOCS
    GUI_APPS
    MISC_TOOLS
)

# All AUR package groups
ALL_AUR_GROUPS=(
    AUR_SYSTEM_UTILS
    AUR_DESKTOP_ENVIRONMENT
    AUR_THEMES_FONTS
    AUR_IMAGE_GRAPHICS
    AUR_DEV_TOOLS
    AUR_GUI_APPS
    AUR_MISC_TOOLS
)

# Install pacman packages
for group in "${ALL_PACMAN_GROUPS[@]}"; do
    sudo pacman -S --needed "${!group[@]}"
done

# Install AUR packages
for group in "${ALL_AUR_GROUPS[@]}"; do
    yay -S --needed "${!group[@]}"
done

# Configure SDDM
echo "Configuring SDDM..."
sudo mkdir -p /usr/share/sddm/themes/
sudo cp -r ./config/sddm/sddm-astronaut-theme /usr/share/sddm/themes/
sudo cp ./config/sddm/sddm.conf /etc/sddm.conf

# If GDM is enabled, remove the symlink and enable sddm
if [ -L /etc/systemd/system/display-manager.service ] && \
   [ "$(readlink /etc/systemd/system/display-manager.service)" = "/usr/lib/systemd/system/gdm.service" ]; then
    echo "Current display manager is GDM, disabling..."
    sudo rm /etc/systemd/system/display-manager.service
fi

systemctl enable sddm.service
echo "SDDM service enabled."

# Configure Kitty
echo "Configuring Kitty..."
mkdir -p ~/.config/kitty
cp -r ./kitty/* ~/.config/kitty
mkdir -p ~/.local/bin
cp ./xdg-terminal-exec ~/.local/bin/xdg-terminal-exec
chmod +x ~/.local/bin/xdg-terminal-exec

# Configure Zsh
echo "Configuring Zsh..."
chsh -s "$(which zsh)"
sudo chsh -s "$(which zsh)"
cp ./.zshrc ~/.zshrc
cp ./.zprofile ~/.zprofile

# Configure Micro theme
echo "Configuring Micro theme..."
mkdir -p ~/.config/micro/
cp -r ./micro/* ~/.config/micro/

# Configure Plymouth
echo "Configuring Plymouth..."
sudo sed -i '/^\[Daemon\]/a ShowDelay=0' /etc/plymouth/plymouthd.conf
sudo sed -i '/^HOOKS=/ s/)$/ plymouth)/' /etc/mkinitcpio.conf
sudo cp -r ./config/plymouth/black_hud /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R black_hud

# Configure Hyprland
echo "Configuring Hyprland..."
mkdir -p ~/.config/hypr
cp -r ./hypr/* ~/.config/hypr/
chmod +x ~/.config/hypr/scripts/*.sh

# Send notification post install when restarting
echo "exec-once = ~/.config/hypr/scripts/post_install_listener.sh" >> ~/.config/hypr/startup.conf

# User icon
ln -s -f ~/.config/hypr/profile-picture.png ~/.face.icon
ln -s -f ~/.config/hypr/profile-picture.png ~/.face

# Configure poketop
echo "Configuring Poketop..."
mkdir -p ~/.poketop
cp -r ./.poketop/* ~/.poketop
chmod +x ~/.poketop/__main__.py

# Set application associations
xdg-settings set default-web-browser floorp.desktop
xdg-mime default pcmanfm.desktop inode/directory

# Apply Papirus icon theme
echo "Applying icon theme..."
sudo hardcode-fixer
papirus-folders -C cat-mocha-lavender

# Apply GTK theme
echo "Applying GTK theme..."
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp -r ./config/gtk-* ~/.config/
cp -r ./config/nwg-look ~/.config/
cp -r ./config/xsettingsd ~/.config/
cp ./config/.gtkrc-2.0 ~/

# Enable auto-cpufreq
echo "Enabling auto-cpufreq..."
systemctl enable --now auto-cpufreq 

# Enable firewalld
echo "Enabling firewalld..."
sudo systemctl enable firewalld.service

# Add user to input group
echo "Adding user to input group..."
sudo usermod -a -G input "$USER"

# Add user to video group
echo "Adding user to video group..."
sudo usermod -a -G video "$USER"

# Enable Bluetooth
echo "Enabling Bluetooth..."
sudo systemctl enable bluetooth.service

# Configure Fastfetch
echo "Configuring Fastfetch..."
cp -r ./fastfetch ~/.config/

# Ensure Pipx path
echo "Ensuring Pipx path..."
pipx ensurepath

# Ask about using a laptop
if ask_yes_no "Are you using a laptop?"; then
    yay -S --needed batsignal
    systemctl --user enable batsignal.service
    systemctl --user start batsignal.service
    mkdir -p ~/.config/systemd/user/batsignal.service.d
    printf '[Service]\nExecStart=\nExecStart=batsignal -d 5 -c 15 -w 30 -p' > ~/.config/systemd/user/batsignal.service.d/options.conf
else
    echo "Laptop installation skipped."
fi

# Ask about AMD installation
if ask_yes_no "Do you want to install AMD GPU drivers?"; then
    install_amd
else
    echo "AMD GPU installation skipped."
fi

# Ask about Nvidia installation
if ask_yes_no "Do you want to install Nvidia GPU drivers?"; then
    install_nvidia
else
    echo "Nvidia GPU installation skipped."
fi

# Install gaming packages if user agrees
if ask_yes_no "Would you like to download additional gaming packages?"; then
    echo "Downloading gaming packages..."
    sudo pacman -S --needed "${GAMING_PACKAGES[@]}"
    yay -S --needed "${GAMING_PACKAGES_YAY[@]}"

    # install and configure millenium
    if ask_yes_no "Would you like to patch Steam with Millenium?"; then
        echo "Patching Steam with Millenium..."
        sudo millenium patch
        sudo chown "$USER:$USER" ~/.local/share/millennium
        chmod -R u+rwX ~/.local/share/millennium
        echo "Installing SpaceTheme for Steam..."
        mkdir -p ~/.steam/steam/steamui/skins/Steam
        cp -r ./millenium-space-theme/* ~/.steam/steam/steamui/skins/Steam
    else
        echo "Skipping Millenium."
    fi
else
    echo "Skipping gaming packages."
fi

if ask_yes_no "Would you like to download plover?"; then
    echo "Downloading Plover AppImage..."
    mkdir -p ~/Applications
    wget -O ~/Applications/plover.AppImage https://github.com/openstenoproject/plover/releases/latest/download/Plover-x86_64.AppImage
    chmod +x ~/Applications/plover.AppImage

    echo "Creating desktop entry for Plover..."
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/plover.desktop <<EOL
[Desktop Entry]
Name=Plover
Exec=$HOME/Applications/plover.AppImage
Icon=plover
Type=Application
Categories=Utility;
Comment=Open Steno Project Plover
Terminal=false
EOL

    echo "Attempting to extract icon from AppImage..."
    # Extract icon if possible
    tmpdir=$(mktemp -d)
    ~/Applications/plover.AppImage --appimage-extract > /dev/null 2>&1
    if [ -f squashfs-root/usr/share/icons/hicolor/256x256/apps/plover.png ]; then
        cp squashfs-root/usr/share/icons/hicolor/256x256/apps/plover.png ~/.local/share/icons/plover.png
        sed -i "s|Icon=plover|Icon=$HOME/.local/share/icons/plover.png|" ~/.local/share/applications/plover.desktop
    fi
    rm -rf squashfs-root "$tmpdir"

    update-desktop-database ~/.local/share/applications
    echo "Plover AppImage installed and integrated."
else
    echo "Not installing plover."
fi

# Ask about restart
if ask_yes_no "Dotfiles successfully installed. Do you want to restart now? (recommended)"; then
    sudo reboot now
else
    echo "Not restarting. Please restart in order to use the dotfiles."
fi