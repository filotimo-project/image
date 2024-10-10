ARG IMAGE_NAME="${IMAGE_NAME:-filotimo}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
# Fetch this dynamically outside the containerfile - use the build script
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.9.12-8.fsync.fc40.x86_64}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

FROM ghcr.io/ublue-os/${KERNEL_FLAVOR}-kernel:${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS kernel
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods-extra

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as filotimo

ARG IMAGE_NAME="${IMAGE_NAME:-filotimo}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.9.12-8.fsync.fc40.x86_64}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

# fsync kernel - remove for f41 once upstream ublue ships it TODO
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=kernel,src=/tmp/rpms,dst=/tmp/fsync-rpms \
    rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override replace \
    --experimental \
        /tmp/fsync-rpms/kernel-[0-9]*.rpm \
        /tmp/fsync-rpms/kernel-core-*.rpm \
        /tmp/fsync-rpms/kernel-modules-*.rpm \
        /tmp/fsync-rpms/kernel-devel-*.rpm \
        /tmp/fsync-rpms/kernel-uki-virt-*.rpm && \
    ostree container commit

# Install akmod rpms for various firmware and features
# https://github.com/ublue-os/bazzite/blob/main/Containerfile#L309
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /usr/bin/copr https://raw.githubusercontent.com/ublue-os/COPR-command/main/copr && \
    chmod +x /usr/bin/copr && \
    curl -Lo /etc/yum.repos.d/_copr_rok-cdemu.repo https://copr.fedorainfracloud.org/coprs/rok/cdemu/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rok-cdemu-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*xone*.rpm \
        /tmp/akmods-rpms/kmods/*openrazer*.rpm \
        /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
        /tmp/akmods-rpms/kmods/*wl*.rpm \
        /tmp/akmods-extra-rpms/kmods/*gcadapter_oc*.rpm \
        /tmp/akmods-extra-rpms/kmods/*nct6687*.rpm \
        /tmp/akmods-extra-rpms/kmods/*zenergy*.rpm \
        /tmp/akmods-extra-rpms/kmods/*vhba*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ayaneo-platform*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ayn-platform*.rpm \
        /tmp/akmods-extra-rpms/kmods/*bmi260*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ryzen-smu*.rpm \
        /tmp/akmods-extra-rpms/kmods/*evdi*.rpm && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    rpm-ostree override remove \
        rpmfusion-free-release \
        rpmfusion-nonfree-release && \
    ostree container commit

# Some mediatek firmware that I don't really know about
# https://github.com/ublue-os/bluefin/blob/main/build_files/firmware.sh
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    mkdir -p /tmp/mediatek-firmware && \
    curl -Lo /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin?inline=false" && \
    curl -Lo /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_RAM_CODE_MT7922_1.bin?inline=false" && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin && \
    mv -vf /tmp/mediatek-firmware/* /usr/lib/firmware/mediatek/ && \
    rm -rf /tmp/mediatek-firmware && \
    ostree container commit

# Install important repos
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    echo "${FEDORA_MAJOR_VERSION}" && \
    curl -Lo /etc/yum.repos.d/filotimo.repo https://download.opensuse.org/repositories/home:/tduck:/filotimolinux/Fedora_"${FEDORA_MAJOR_VERSION}"/home:tduck:filotimolinux.repo && \
    curl -Lo /etc/yum.repos.d/klassy.repo https://download.opensuse.org/repositories/home:/paul4us/Fedora_"${FEDORA_MAJOR_VERSION}"/home:paul4us.repo && \
    curl -Lo /etc/yum.repos.d/_copr_rodoma92-kde-cdemu-manager.repo https://copr.fedorainfracloud.org/coprs/rodoma92/kde-cdemu-manager/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rodoma92-kde-cdemu-manager-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
    ostree container commit

# Install Filotimo packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rm -rf /var/cache/rpm-ostree/repomd && \
    rpm-ostree override remove zram-generator-defaults fedora-logos desktop-backgrounds-compat plasma-lookandfeel-fedora \
        --install filotimo-environment \
        --install filotimo-backgrounds \
        --install filotimo-branding \
        --install filotimo-kde-theme && \
    rpm-ostree install \
        filotimo-environment-firefox \
        filotimo-environment-fonts \
        filotimo-environment-ime \
        filotimo-kde-overrides \
        msttcore-fonts-installer \
        onedriver \
        appimagelauncher \
        bup kup python-libfuse \
        filotimo-atychia \
        filotimo-plymouth-theme && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/terra.repo && \
    ostree container commit

# Replace ppd with tuned - remove for f41 TODO
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        power-profiles-daemon \
        --install tuned \
        --install tuned-ppd && \
    ostree container commit

# Install misc. packages
# libdvdcss has dubious legality
# TODO remove pulseaudio-utils for f41 - upstreamed into kinfocenter package
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        ublue-os-update-services \
        toolbox && \
    rpm-ostree install \
        plasma-discover-rpm-ostree \
        distrobox \
        git gh \
        nodejs-bash-language-server \
        kdenetwork-filesharing \
        ark \
        kio-admin \
        kleopatra \
        firewall-config \
        setroubleshoot \
        openssl openssl-libs \
        python3-pip \
        i2c-tools \
        pulseaudio-utils \
        p7zip \
        unzip \
        unrar \
        gstreamer1-plugins-good gstreamer1-plugin-vaapi gstreamer1-plugin-libav \
        x265 \
        ffmpeg \
        kde-cdemu-manager-kf6 \
        v4l2loopback pipewire-v4l2 libcamera-v4l2 \
        samba samba-usershares samba-dcerpc samba-ldb-ldap-modules samba-winbind-clients samba-winbind-modules \
        rclone \
        mesa-libGLU \
        usbmuxd \
        stress-ng \
        epson-inkjet-printer-escpr \
        epson-inkjet-printer-escpr2 \
        foomatic \
        foomatic-db-ppds \
        gutenprint \
        hplip \
        libimobiledevice \
        android-tools \
        htop \
        virt-manager \
        podman docker \
        fish zsh \
        libreoffice && \
    ostree container commit

# Consolidate and install justfiles
COPY just /tmp/just

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Add modifications and finalize
COPY scripts /tmp/scripts

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    mkdir -p /var/lib/alternatives && \
    cd /tmp/scripts && \
    ./build-base.sh && \
    ./build-initramfs.sh && \
    IMAGE_FLAVOR="main" ./image-info.sh && \
    ostree container commit

# Generate NVIDIA image
FROM ghcr.io/ublue-os/akmods-nvidia:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS nvidia-akmods

FROM filotimo as filotimo-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-filotimo-nvidia}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.9.12-8.fsync.fc40.x86_64}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

# Install NVIDIA driver, use different copr repo for kf6 supergfxctl plasmoid
# TODO only install supergfxctl on hybrid systems or find some way to only show it on hybrid systems
# TODO remove libxcb installation at start once it builds again without it
# it's confusing visual noise outside of that context
# https://github.com/ublue-os/hwe/
# https://github.com/ublue-os/bazzite/blob/main/Containerfile#L950
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=nvidia-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    rpm-ostree override replace --experimental --from repo=fedora libxcb-1.16-4.fc40.i686 && \
    curl -Lo /etc/yum.repos.d/_copr_jhyub-supergfxctl-plasmoid.repo https://copr.fedorainfracloud.org/coprs/jhyub/supergfxctl-plasmoid/repo/fedora-"${FEDORA_MAJOR_VERSION}"/jhyub-supergfxctl-plasmoid-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="kinoite" /tmp/nvidia-install.sh && \
    rpm-ostree install nvidia-vaapi-driver && \
    systemctl enable supergfxd && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_jhyub-supergfxctl-plasmoid.repo && \
    ostree container commit

COPY scripts /tmp/scripts

# Finalize
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    cd /tmp/scripts && \
    ./build-initramfs.sh && \
    IMAGE_FLAVOR="nvidia" ./image-info.sh && \
    ./integrate-supergfxctl-plasmoid.sh && \
    ostree container commit
