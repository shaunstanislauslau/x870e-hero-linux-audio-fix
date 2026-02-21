# Fix: ASUS ROG Crosshair X870E Hero — Onboard Audio on Linux

The onboard Realtek ALC4082 audio on the ASUS ROG Crosshair X870E Hero does not work out of the box on Ubuntu (and likely other distros shipping `alsa-ucm-conf` < 1.2.14). Only digital S/PDIF output is available — all analog outputs (rear speakers, headphones, microphone) show as **"not available"**.

This repo provides a one-command fix.

## My System Specs

| Component | Detail |
|---|---|
| **Motherboard** | ASUS ROG Crosshair X870E Hero |
| **BIOS** | Version **2004** (updated from 1401) |
| **CPU** | AMD Ryzen 9 9950X3D (16-core / 32-thread) |
| **GPU** | NVIDIA GeForce RTX 5090 |
| **RAM** | 128GB DDR5 — 4x32GB G.Skill F5-6000J3040G32G (6000 MT/s kit, running at 3600 MT/s) |
| **Storage** | Samsung 990 PRO 2TB NVMe + Samsung 960 EVO 1TB NVMe + Seagate IronWolf 12TB HDD |
| **OS** | Ubuntu 24.04.4 LTS |
| **Kernel** | 6.8.0-100-generic |
| **PipeWire** | 1.0.5 |
| **alsa-ucm-conf** | 1.2.10-1ubuntu5.9 |
| **Audio (USB DAC)** | Schiit Modi 3+ — primary audio output, was using this before the fix since onboard audio never worked |
| **Onboard Audio** | Realtek ALC4082 (USB ID: `0b05:1b7c`) — **not working** until this fix |

## The Problem

The X870E Hero's Realtek ALC4082 audio chipset connects via **internal USB**, not PCI (unlike older boards). The Linux ALSA UCM (Use Case Manager) configuration needs to recognize the board's USB device ID (`0b05:1b7c`) to enable the analog audio paths.

Ubuntu's `alsa-ucm-conf` version **1.2.10** does not include this ID. The upstream [alsa-ucm-conf](https://github.com/alsa-project/alsa-ucm-conf) added support in **v1.2.14** ([PR #503](https://github.com/alsa-project/alsa-ucm-conf/pull/503)), but Ubuntu hasn't shipped that version yet.

**Symptoms:**
- `lspci | grep audio` shows only the GPU (NVIDIA) audio — no onboard audio device
- The onboard audio appears as a generic "USB Audio" device (`0b05:1b7c`) in `lsusb`
- In PipeWire/PulseAudio, all analog profiles show `available: no`
- Only `Digital Stereo (IEC958)` output works
- Speakers/headphones plugged into the rear or front panel jacks produce no sound

**What this is NOT:**
- This is **not** a BIOS issue — confirmed working on BIOS 2004
- This is **not** a hardware defect — the audio works fine in Windows
- This is **not** a PipeWire or PulseAudio bug — it's a missing device ID in the UCM config

## Quick Fix

```bash
git clone https://github.com/YOUR_USERNAME/x870e-audio-fix.git
cd x870e-audio-fix
sudo bash fix-x870e-audio.sh
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## What the Script Does

1. Checks `/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf` for the device ID `0b05:1b7c`
2. If missing, adds it to the Realtek ALC4080 regex block so the UCM profile loads correctly
3. Logs the action to syslog

The script is safe to run multiple times — it skips the patch if the ID is already present.

## Persist Across `apt upgrade`

If `alsa-ucm-conf` gets updated via `apt`, it will overwrite the patched file. To auto-reapply:

```bash
# Install the script system-wide
sudo cp fix-x870e-audio.sh /usr/local/bin/fix-x870e-audio.sh
sudo chmod +x /usr/local/bin/fix-x870e-audio.sh

# Add an apt hook to run it after every package upgrade
echo 'DPkg::Post-Invoke { "if [ -x /usr/local/bin/fix-x870e-audio.sh ]; then /usr/local/bin/fix-x870e-audio.sh; fi"; };' \
  | sudo tee /etc/apt/apt.conf.d/99-fix-x870e-audio
```

## Verify It's Working

```bash
# Should show HiFi verbs (not an error)
alsaucm -c hw:4 list _verbs

# Should show "available: yes" or "availability unknown" (not "not available")
pactl list cards | grep -A3 "analog-output-speaker"

# Should show analog profiles as available
pactl list cards | grep "output:analog-stereo"
```

> **Note:** The card number (`hw:4`) may differ on your system. Run `cat /proc/asound/cards` to find the correct one for "USB Audio".

## Cleanup

Once Ubuntu ships `alsa-ucm-conf` **1.2.14 or newer**, this fix becomes unnecessary. The script will detect the ID is already present and skip the patch. To fully clean up:

```bash
sudo rm /etc/apt/apt.conf.d/99-fix-x870e-audio
sudo rm /usr/local/bin/fix-x870e-audio.sh
```

## Affected Distros

Any Linux distro shipping `alsa-ucm-conf` older than **1.2.14** will have this issue, including but not limited to:
- Ubuntu 24.04 LTS (Noble Numbat)
- Linux Mint 22.x
- Debian Bookworm (if using backported kernels with newer hardware)

The fix approach is the same — patch `USB-Audio.conf` to include `0b05:1b7c`.

## Other X870E Boards

If you have a **different** X870E board with the same issue, your USB device ID will be different. Find it with:

```bash
lsusb | grep "ASUSTek.*Audio"
```

Then add your ID to the script's `sed` pattern and the UCM regex. Consider submitting a PR to the upstream [alsa-ucm-conf](https://github.com/alsa-project/alsa-ucm-conf) repo.

## Credits

- [alsa-project/alsa-ucm-conf](https://github.com/alsa-project/alsa-ucm-conf) — upstream UCM configuration
- [PR #503](https://github.com/alsa-project/alsa-ucm-conf/pull/503) by Fabcien — original upstream fix for the X870E Hero

## License

MIT
