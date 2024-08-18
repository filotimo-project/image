#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

#FLATPAK_FLATHUB=( org.mozilla.Thunderbird
#org.kde.isoimagewriter
#org.kde.kclock
#org.kde.kweather
#org.kde.francis
#com.github.wwmm.easyeffects
#org.kde.skanpage
#org.kde.kamoso
#org.kde.elisa
#org.kde.kolourpaint
#org.kde.digikam
#org.kde.kget
#org.kde.ktorrent
#org.kde.krecorder )

# Add flathub
#flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
#flatpak remote-modify --enable flathub

#for app in ${FLATPAK_FLATHUB[@]}; do
#	flatpak install -y flathub "$app"
#done

#flatpak override --socket=wayland org.mozilla.Thunderbird
#flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Enable samba for filesharing
systemctl enable smb

# Enable tuned
systemctl enable tuned
systemctl enable tuned-ppd

# Mask hibernate - usually just causes problems
systemctl mask hibernate.target
