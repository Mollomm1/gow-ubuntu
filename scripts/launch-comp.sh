#!/bin/bash
set -e

source /opt/gow/bash-lib/utils.sh

function launcher() {
  export XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/home/retro/.local/share/flatpak/exports/share:/usr/local/share/:/usr/share/
  
  # 
  # Launch DBUS
  sudo /opt/gow/startdbus
  
  export DESKTOP_SESSION=ubuntu
  export GNOME_SHELL_SESSION_MODE=ubuntu
  export XDG_CURRENT_DESKTOP=ubuntu:GNOME
  export XDG_SESSION_TYPE="wayland"
  export _JAVA_AWT_WM_NONREPARENTING=1
  export GDK_BACKEND=wayland
  export MOZ_ENABLE_WAYLAND=1
  export QT_QPA_PLATFORM="wayland;xcb"
  export QT_AUTO_SCREEN_SCALE_FACTOR=1
  export QT_ENABLE_HIGHDPI_SCALING=1
  export DISPLAY=:0
  
  # 
  # Sometime the display socket is not 0, don't ask me why.
  if [ ! -f "/tmp/sockets/wayland-0" ]; then
  	export WAYLAND_DISPLAY="wayland-0"
  else
  	export WAYLAND_DISPLAY="wayland-1"
  fi
  
  export $(dbus-launch)
  
  # 
  # First setup
  if [ ! -f "$HOME/.firstsetup" ]; then
    # add flathub repo
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    # load default dconf config
    dconf load / < /opt/gow/gnome.dconf.conf
    # create basic folders
    mkdir ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos
    chmod 755 ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos
    # prevent first setup process to run again
    touch ~/.firstsetup
  fi
  
  # 
  # Start Xwayland and gnome
  if [ $WAYLAND_DISPLAY == "wayland-0" ]; then
    dbus-run-session -- bash -E -c "WAYLAND_DISPLAY=\"wayland-1\" Xwayland & MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080 WAYLAND_DISPLAY=\"wayland-1\" gnome-shell --nested --sync --wayland"
  else
    dbus-run-session -- bash -E -c "WAYLAND_DISPLAY=\"wayland-0\" Xwayland & MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080 WAYLAND_DISPLAY=\"wayland-0\" gnome-shell --nested --sync --wayland"
  fi
}
