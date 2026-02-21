#!/bin/bash
# Re-add ASUS ROG Crosshair X870E Hero (0b05:1b7c) to ALC4080 UCM config
# if it's missing after an alsa-ucm-conf package update.
UCM_FILE="/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf"
if [ -f "$UCM_FILE" ] && ! grep -q "1b7c" "$UCM_FILE"; then
    sed -i '/If.realtek-alc4080\|Macro.alc4080/,/True.Define.ProfileName.*Realtek\/ALC4080/ {
        /0b05:1a5c/a\\t\t# 0b05:1b7c ASUS ROG Crosshair X870E Hero
        s/\(0b05:[^)]*1a5c\)/\1|1b7c/
    }' "$UCM_FILE"
    logger "fix-x870e-audio: patched alsa-ucm-conf for X870E Hero"
fi
