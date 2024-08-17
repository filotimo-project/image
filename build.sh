#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Install Filotimo packages
rpm-ostree override replace --experimental \
filotimo-environment \
filotimo-kde-overrides \
msttcore-fonts-installer \
onedriver \
appimagelauncher \
filotimo-backgrounds \
filotimo-grub-theme \
filotimo-plymouth-theme \
filotimo-branding \
filotimo-atychia

# Remove misc. packages
rpm-ostree override remove \
power-profiles-daemon \
firefox \
mediawriter \
krusader \
konversation \
k3b \
kontact \
kmail \
korganizer \
kaddressbook \
*akonadi* \
mariadb* \
kmines \
kmahjongg \
kpat

# Install misc. packages
rpm-ostree override replace --experimental \
tuned tuned-ppd \
distrobox \
git \
vlc \
kdenetwork-filesharing \
ark \
kio-admin \
kleopatra \
firewall-config \
setroubleshoot \
firewall-config \
openssl openssl-libs \
python3-pip \
nmap \
p7zip \
p7zip-plugins \
unzip \
unrar \
libheif libheif-tools \
gstreamer1-plugin-openh264 \
mesa-vdpau-drivers-freeworld mesa-va-drivers-freeworld \
intel-media-driver libva-media-driver libva-utils vdpauinfo \
nvidia-vaapi-driver \
libdvdcss \
ffmpeg \
epson-inkjet-printer-escpr2 \
foomatic-db \
gutenprint \
hplip

FLATPAK_FLATHUB=( org.mozilla.Firefox
org.mozilla.Thunderbird
org.kde.isoimagewriter
org.kde.kclock
org.kde.kweather
org.kde.francis
com.github.wwmm.easyeffects
org.kde.skanpage
org.kde.kamoso
org.kde.elisa
org.kde.kolourpaint
org.kde.digikam
org.kde.kget
org.kde.ktorrent
org.kde.krecorder )

# Add flathub
flatpak remote-add --if-not-exists -y flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify --enable -y flathub

for app in ${FLATPAK_FLATHUB[@]}; do
	flatpak install -y flathub "$app"
done

flatpak override --socket=wayland org.mozilla.Thunderbird
flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Enable samba for filesharing
systemctl enable smbd

# Mask hibernate - usually just causes problems
systemctl mask hibernate.target
