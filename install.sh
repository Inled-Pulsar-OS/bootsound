#!/bin/bash

# Ensure script is run with sudo if needed, but Zenity should run as user for GUI access
# We'll use sudo for the copy/systemctl commands later.

# Get the script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check if zenity is installed
if ! command -v zenity &> /dev/null; then
    echo "Error: zenity is not installed. Please install it first."
    exit 1
fi

# Function to select a sound
select_sound() {
    local title=$1
    local selected=$(zenity --list --title="$title" \
        --text="Choose a sound or select 'Custom...' to browse." \
        --column="Name" --column="File" \
        "Windows XP Start" "$DIR/windows_xp_start.mp3" \
        "XP Shutdown" "$DIR/xp_shutdown.mp3" \
        "Nokia (Tarrega Vals)" "$DIR/nokia.wav" \
        "MacOS" "$DIR/MacStartupChime.ogg.wav" \
        "None" "none" \
        "Custom..." "custom" \
        --height=350 --width=500 --hide-column=2 --print-column=2)

    if [ $? -ne 0 ]; then
        echo "CANCELLED"
        return
    fi

    if [ "$selected" = "custom" ]; then
        selected=$(zenity --file-selection --title="Select Custom Sound File")
        if [ $? -ne 0 ]; then
            echo "CANCELLED"
            return
        fi
    elif [ "$selected" = "none" ]; then
        selected=""
    fi
    echo "$selected"
}

# Main installer
zenity --question --text="Do you want to install/configure Boot and Shutdown sounds?" --width=300
if [ $? -ne 0 ]; then exit 0; fi

BOOT_SOUND=$(select_sound "Select Boot Sound")
if [ "$BOOT_SOUND" = "CANCELLED" ]; then exit 0; fi

SHUTDOWN_SOUND=$(select_sound "Select Shutdown Sound")
if [ "$SHUTDOWN_SOUND" = "CANCELLED" ]; then exit 0; fi

echo "Installing files..."

# Function to run privileged commands via pkexec
run_privileged() {
    pkexec bash -c "$1"
}

# Cleanup existing installation to ensure a clean state
CLEANUP_CMD="systemctl disable --now bootsound.service shutdownsound.service 2>/dev/null; \
             rm -f /etc/systemd/system/bootsound.service /etc/systemd/system/shutdownsound.service; \
             mkdir -p /usr/share/bootsound"

run_privileged "$CLEANUP_CMD"

# Handle Boot Sound
if [ -n "$BOOT_SOUND" ]; then
    INSTALL_BOOT="cp '$BOOT_SOUND' /usr/share/bootsound/boot-sound && \
                  cp '$DIR/bootsound.service' /etc/systemd/system/ && \
                  systemctl enable bootsound.service"
    run_privileged "$INSTALL_BOOT"
else
    run_privileged "rm -f /usr/share/bootsound/boot-sound"
fi

# Handle Shutdown Sound
if [ -n "$SHUTDOWN_SOUND" ]; then
    INSTALL_SHUTDOWN="cp '$SHUTDOWN_SOUND' /usr/share/bootsound/shutdown-sound && \
                      cp '$DIR/shutdownsound.service' /etc/systemd/system/ && \
                      systemctl enable shutdownsound.service"
    run_privileged "$INSTALL_SHUTDOWN"
else
    run_privileged "rm -f /usr/share/bootsound/shutdown-sound"
fi

run_privileged "systemctl daemon-reload"

zenity --info --text="Installation complete! Your sounds are configured.\n\nBoot: ${BOOT_SOUND:-None}\nShutdown: ${SHUTDOWN_SOUND:-None}" --width=400
