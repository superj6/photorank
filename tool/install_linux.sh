#!/usr/bin/env bash
# Build the Linux desktop app and install it for the current user
# (~/.local/opt/photorank + an application-menu entry).
#   tool/install_linux.sh --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/development/flutter/bin:$PATH"
# Extra args are passed to flutter build (e.g. --dart-define=SUPABASE_URL=...).
flutter build linux --release "$@"
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
StartupWMClass=dev.photorank.photorank
DESKTOP
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# GNOME: pin to the dock (idempotent).
if command -v gsettings >/dev/null && gsettings writable org.gnome.shell favorite-apps >/dev/null 2>&1; then
  python3 - <<'PY' || true
import ast, subprocess
cur = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'favorite-apps'], capture_output=True, text=True).stdout.strip()
favs = ast.literal_eval(cur)
if 'photorank.desktop' not in favs:
    favs.append('photorank.desktop')
    subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'favorite-apps', str(favs)], check=True)
PY
fi

echo "Installed to $DEST — find PhotoRank in your app menu, or run $DEST/photorank"
