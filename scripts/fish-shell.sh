#!/usr/bin/bash
set -ouex pipefail

# Alias dnf for dnf5 TODO remove for f41
echo -e 'alias dnf="dnf5"\nalias sudo="sudo "' | tee -a /etc/bashrc /etc/zshrc /usr/share/fish/config.fish > /dev/null

# ...and also add bash preexec
curl -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

# Setup fish to inherit profile correctly
echo '#!/bin/bash -l
exec -l fish "$@"' > /usr/bin/fishlogin
chmod +x /usr/bin/fishlogin

# Set fish as default shell
echo "/usr/bin/fishlogin" >> /etc/shells
sudo sed -i 's@^SHELL=.*@SHELL=/usr/bin/fishlogin@' /etc/default/useradd
