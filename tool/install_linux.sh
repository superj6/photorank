#!/usr/bin/env bash
# Build the Linux desktop app and install it for the current user
# (~/.local/opt/photorank + an application-menu entry).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/development/flutter/bin:$PATH"
flutter build linux --release
DEST="$HOME/.local/opt/photorank"
rm -rf "$DEST" && mkdir -p "$DEST" && cp -r build/linux/x64/release/bundle/. "$DEST/"
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps" "$HOME/.local/share/applications"
cp assets/icon/icon.png "$HOME/.local/share/icons/hicolor/512x512/apps/photorank.png"
cat > "$HOME/.local/share/applications/photorank.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=PhotoRank
Comment=A tiny game that sorts your photos
Exec=$DEST/photorank
Icon=photorank
Terminal=false
Categories=Graphics;Photography;
DESKTOP
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
echo "Installed to $DEST — find PhotoRank in your app menu, or run $DEST/photorank"
