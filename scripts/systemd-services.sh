#!/usr/bin/bash
set -ouex pipefail

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

# Install OpenH264 on first boot
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
SCRIPT_FILE="/usr/libexec/postinstall-install-openh264"
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
SERVICE_FILE="/etc/systemd/system/postinstall-install-openh264.service"
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
systemctl enable postinstall-install-openh264.service

