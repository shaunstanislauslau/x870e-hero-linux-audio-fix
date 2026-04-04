#!/bin/bash
# Re-add ASUS ROG Crosshair X870E Hero (0b05:1b7c) to ALC4080 UCM config
UCM_FILE="/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf"
if [ -f "$UCM_FILE" ]; then
    # Fix corrupted comment if present
    sed -i 's/0b05:1a5c|1b7c/0b05:1a5c/' "$UCM_FILE"
    # Add 1b7c to the ASUS regex group if missing from the Regex line
    if ! grep "Regex.*1b7c" "$UCM_FILE" > /dev/null 2>&1; then
        sed -i 's/(0b05:(19(84|9\[69])|1a(16|2\[07]|5\[23c])))/(0b05:(19(84|9[69])|1a(16|2[07]|5[23c])|1b7c))/' "$UCM_FILE"
        logger "fix-x870e-audio: patched alsa-ucm-conf for X870E Hero"
    fi
fi
