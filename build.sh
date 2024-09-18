#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Enable samba for filesharing
systemctl enable smb

# Enable tuned
systemctl enable tuned
systemctl enable tuned-ppd

# Mask hibernate - usually just causes problems
systemctl mask hibernate.target

# Fix podman complaining about some database thing
mkdir -p /etc/skel/.local/share/containers/storage/volumes

# Hide nvtop and htop desktop entries
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop

# Set Konsole default profile
echo "[Desktop Entry]
DefaultProfile=Filotimo.profile" >> /etc/xdg/konsolerc

# Set rpm-ostree to check for updates automatically, not stage automatically
# Updates will be done automatically by Discover
sed -i "s/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=check/" /etc/rpm-ostreed.conf

# Remove fcitx default icons
rm -rf /usr/share/icons/breeze/status/22/fcitx.svg
rm -rf /usr/share/icons/breeze/status/24/fcitx.svg

# Remove fedora and fedora-testing flatpak remotes
sed -i '/\[remote "fedora"\]/,/^\[/d' /var/lib/flatpak/repo/config
sed -i '/\[remote "fedora-testing"\]/,/^\[/d' /var/lib/flatpak/repo/config

# Override Vesktop and Discord to use X11 since IME is broken under wayland and it's still buggy
echo "[Context]
sockets=!wayland;" > /var/lib/flatpak/overrides/dev.vencord.Vesktop
echo "[Context]
sockets=!wayland;" > /var/lib/flatpak/overrides/com.discordapp.Discord

# Install OpenH264 on first boot
SCRIPT_FILE="/usr/libexec/install-openh264"
cat <<EOF | tee "$SCRIPT_FILE" > /dev/null
#!/usr/bin/bash
if rpm-ostree status | grep -q 'openh264\|mozilla-openh264\|gstreamer1-plugin-openh264'; then
    echo "OpenH264 is already layered."
else
    echo "One or more OpenH264 packages were not layered, installing now..."
    rpm-ostree override remove noopenh264 --install openh264 --install mozilla-openh264 --install gstreamer1-plugin-openh264
    echo "Changes will take effect on next reboot."
fi
EOF
chmod +x "$SCRIPT_FILE"
SERVICE_FILE="/etc/systemd/system/install-openh264.service"
cat <<EOF | tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Re-layer OpenH264 Codec
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_FILE
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable install-openh264.service
