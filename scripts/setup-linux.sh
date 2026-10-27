#!/bin/bash
# Sets up a Linux (Debian/Ubuntu) machine to build, test and run the engine:
# the Swift toolchain via swiftly, its system dependencies, X11 headers for
# LinuxPlatform, and Xvfb/screenshot tools for headless runs of the Game.
# Safe to run repeatedly.
set -euo pipefail

SWIFT_VERSION="6.2"
export SWIFTLY_HOME_DIR="${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

APT_PACKAGES=(
  # Swift toolchain runtime dependencies
  libcurl4-openssl-dev libxml2-dev libz3-dev
  # LinuxPlatform links against Xlib
  libx11-dev
  # Headless runs: virtual display, screenshots, window/input automation
  xvfb x11-apps imagemagick xdotool
)
missing=()
for pkg in "${APT_PACKAGES[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if [ ${#missing[@]} -gt 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get install -y -qq "${missing[@]}" || {
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq "${missing[@]}"
  }
fi

# swiftly (Swift toolchain manager); init adds it to the shell profile
if [ ! -x "$SWIFTLY_HOME_DIR/bin/swiftly" ]; then
  tmp="$(mktemp -d)"
  curl -sSfL "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" -o "$tmp/swiftly.tar.gz"
  tar -xzf "$tmp/swiftly.tar.gz" -C "$tmp"
  "$tmp/swiftly" init --assume-yes --skip-install --quiet-shell-followup
  rm -rf "$tmp"
fi

# shellcheck source=/dev/null
. "$SWIFTLY_HOME_DIR/env.sh"

if ! swiftly list 2>/dev/null | grep -q "Swift $SWIFT_VERSION"; then
  swiftly install "$SWIFT_VERSION" --assume-yes
fi
swiftly use --global-default "$SWIFT_VERSION" --assume-yes >/dev/null
hash -r

swift --version
