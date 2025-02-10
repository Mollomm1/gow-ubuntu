FROM ghcr.io/games-on-whales/base-app:master

ARG CORE_PACKAGES=" \
    lsb-release \
    wget \
    gnupg2 \
    dbus-x11 \
    firefox \
    flatpak \
    sudo \
    "

ARG GNOME_PACKAGES=" \
    gnome-shell \
    gnome-shell-* \
    gnome-accessibility-themes \
    gnome-calculator \
    gnome-control-center* \
    gnome-desktop3-data \
    gnome-initial-setup \
    gnome-menus \
    gnome-themes-extra* \
    gnome-user-docs \
    gnome-video-effects \
    gnome-tweaks \
    gnome-software \
    language-pack-en-base \
    yaru-* \
    ubuntu-desktop \
    fonts-ubuntu \
    "
    
ARG ADDITIONAL_PACKAGES=" \
    vlc \
    gnome-software-plugin-flatpak \
    xfce4-terminal \
    "
# 
# Prevent firefox snap
COPY scripts/ff-unsnap /etc/apt/preferences.d/ff-unsnap

RUN \
    # \
    # Setup Firefox PPA \
    apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common gpg-agent && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    apt-get update && \
    # \
    # Install core packages \
    apt-get install -y --no-install-recommends $CORE_PACKAGES && \
    # \
    # Install full Gnome desktop \
    apt-get install -y $GNOME_PACKAGES && \
    # \
    # Install additional apps \
    apt-get install -y $ADDITIONAL_PACKAGES

RUN \
    # \
    # Fixes \
    for file in $(find /usr -type f -iname "*login1*"); do mv -v $file "$file.back"; done && \
    echo "\nexport $(dbus-launch)\nexport XDG_CURRENT_DESKTOP=ubuntu:GNOME\nexport XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/home/retro/.local/share/flatpak/exports/share:/usr/local/share/:/usr/share/\nexport XDG_SESSION_TYPE=wayland\nexport DESKTOP_SESSION=ubuntu\nexport GNOME_SHELL_SESSION_MODE=ubuntu" >> /etc/profile && \
    # \
    # Hide broken/Useless setting \
    mv -v /usr/share/applications/gnome-sound-panel.desktop /usr/share/applications/gnome-sound-panel.desktop.back && \
    mv -v /usr/share/applications/gnome-color-panel.desktop /usr/share/applications/gnome-color-panel.desktop.back && \
    mv -v /usr/share/applications/gnome-power-panel.desktop /usr/share/applications/gnome-power-panel.desktop.back && \
    mv -v /usr/share/applications/gnome-bluetooth-panel.desktop /usr/share/applications/gnome-bluetooth-panel.desktop.back && \
    mv -v /usr/share/applications/gnome-network-panel.desktop /usr/share/applications/gnome-network-panel.desktop.back && \
    mv -v /usr/share/applications/gnome-printers-panel.desktop /usr/share/applications/gnome-printers-panel.desktop.back

RUN \
    # \
    # Clean \
    apt update && \
    apt-get remove -y \
        gnome-power-manager gnome-bluetooth \
        gpaste-2 gpaste totem kitty gnome-terminal foot\
        gnome-software-plugin-snap snapd \
        gnome-shell-pomodoro gnome-shell-pomodoro-data && \
    apt autoremove -y &&\
    apt clean && \
    rm -rf \
        /config/.cache \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*
# 
# Replace launch scripts
COPY --chmod=777 scripts/launch-comp.sh scripts/startup.sh scripts/gnome.dconf.conf /opt/gow/
COPY --chmod=777 scripts/startdbus.sh /opt/gow/startdbus

# 
# Fix locals
COPY scripts/locale /etc/default/locale

# 
# Allow anyone to start dbus without password
RUN echo "\nALL ALL=NOPASSWD: /opt/gow/startdbus" >> /etc/sudoers

# 
# Fix bwarp perms for flatpaks
RUN chmod u+s /usr/bin/bwrap

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
