#!/bin/bash
# StarCraft: Remastered + Battle.net pe Ubuntu, Wine PORTABIL (fara sudo, fara Lutris).
# Tot ce se instaleaza sta in folderul ales (implicit ./starcraft-linux).
# Utilizare:  ./scripts/install.sh [folder_destinatie]
set -euo pipefail
DEST="$(realpath -m "${1:-$PWD/starcraft-linux}")"
say(){ printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die(){ printf '\033[1;31mEROARE: %s\033[0m\n' "$*" >&2; exit 1; }

say "1/7 Verificari"
[ "$(uname -m)" = x86_64 ] || die "Necesita x86_64."
for c in curl tar xz grep awk; do command -v "$c" >/dev/null || die "Lipseste '$c' (sudo apt install curl tar xz-utils)"; done
[ -n "${DISPLAY:-}" ] || die "Ruleaza din sesiunea grafica (DISPLAY gol)."
dpkg --print-foreign-architectures 2>/dev/null | grep -q i386 || \
  echo "ATENTIE: arhitectura i386 nu e activa. Ruleaza: sudo dpkg --add-architecture i386 && sudo apt update"
FREE_GB=$(df -BG --output=avail "$(dirname "$DEST")" | tail -1 | tr -dc 0-9)
[ "$FREE_GB" -ge 15 ] || die "Spatiu liber insuficient (${FREE_GB} GB, minim 15 GB)."
command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,driver_version --format=csv,noheader || echo "GPU non-NVIDIA: se foloseste Mesa Vulkan."
ls /usr/share/vulkan/icd.d/*.json >/dev/null 2>&1 || die "Nu am gasit drivere Vulkan (sudo apt install mesa-vulkan-drivers libvulkan1)."

mkdir -p "$DEST/runtime" "$DEST/prefix" "$DEST/dl"; cd "$DEST"

# --- VERSIUNI INGHETATE (testate impreuna, 2026-11-03). Nu se schimba singure. ---
WINE_VER=11.21;  WINE_SHA=0822a686125791dc64b013a9edf38f06fd3c8ba5e490acb01f24dc851eeb6ee3
DXVK_VER=3.1.1;  DXVK_SHA=40565b4a724aadc4433fa4e010b4b23916d9b1f1baeee64e17186db94f54e608
# Pentru ultimele versiuni (pe riscul tau, poate strica instalarea):  USE_LATEST=1 ./scripts/install.sh
if [ "${USE_LATEST:-0}" = 1 ]; then
  WURL=$(curl -fsSL https://api.github.com/repos/Kron4ek/Wine-Builds/releases/latest | grep -o 'https://[^"]*staging-tkg-amd64\.tar\.xz' | head -1)
  DURL=$(curl -fsSL https://api.github.com/repos/doitsujin/dxvk/releases/latest | grep -o 'https://[^"]*dxvk-[0-9.]*\.tar\.gz' | head -1)
  WSHA=""; DSHA=""
else
  WURL="https://github.com/Kron4ek/Wine-Builds/releases/download/$WINE_VER/wine-$WINE_VER-staging-tkg-amd64.tar.xz"; WSHA=$WINE_SHA
  DURL="https://github.com/doitsujin/dxvk/releases/download/v$DXVK_VER/dxvk-$DXVK_VER.tar.gz"; DSHA=$DXVK_SHA
fi
fetch(){ # url sha  -> descarca in dl/ si verifica hash-ul daca e cunoscut
  local f="dl/$(basename "$1")"; [ -f "$f" ] || curl -fL -o "$f" "$1"
  [ -z "$2" ] || echo "$2  $f" | sha256sum -c - >/dev/null || die "Hash invalid pentru $f (fisier corupt sau modificat)."
  echo "$f"; }

say "2/7 Wine TkG staging ${WINE_VER} (inghetat, hash verificat)"
WTAR=$(fetch "$WURL" "$WSHA" | tail -1); tar -xf "$WTAR" -C runtime
WDIR=$(basename "$(ls -d runtime/wine-*staging-tkg-amd64 | head -1)")

say "3/7 DXVK ${DXVK_VER} (inghetat, hash verificat)"
DTAR=$(fetch "$DURL" "$DSHA" | tail -1); tar -xzf "$DTAR" -C runtime
DDIR=$(basename "$(ls -d runtime/dxvk-[0-9]* | grep -v native | head -1)")

say "4/7 Winetricks + installer Battle.net (oficial)"
curl -fsSL -o runtime/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks; chmod +x runtime/winetricks
[ -f Battle.net-Setup.exe ] || curl -fL -o Battle.net-Setup.exe "https://www.battle.net/download/getInstallerForGame?os=win&version=LIVE&gameProgram=BATTLENET_APP"

say "5/7 Scriptul de mediu (env.sh) si launcher"
cat > env.sh <<ENV
#!/bin/bash
R="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export WINEPREFIX="\$R/prefix" WINEARCH=win64
export PATH="\$R/runtime/$WDIR/bin:\$R/runtime:\$PATH"
export WINEDLLOVERRIDES="winemenubuilder.exe=d;d3d9,d3d10core,d3d11,dxgi=n,b"
export WINEDEBUG=-all
unset WAYLAND_DISPLAY            # Wine ruleaza pe X11/XWayland (driverul Wayland pica pe Ubuntu 26.04)
export WINE_GRAPHICS_DRIVER=x11
export DXVK_STATE_CACHE_PATH="\$R/cache" DXVK_LOG_LEVEL=none __GL_SHADER_DISK_CACHE_PATH="\$R/cache"
export WINEFSYNC=1 WINEESYNC=1 STAGING_SHARED_MEMORY=1
export __GL_THREADED_OPTIMIZATIONS=1 __GL_MaxFramesAllowed=1 __GL_YIELD=USLEEP
mkdir -p "\$R/cache"
ENV
cat > start-battlenet.sh <<'LAUNCH'
#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/env.sh"
B="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
[ -f "$B" ] || B="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"
command -v gamemoderun >/dev/null && G=gamemoderun
exec ${G:-} wine "$B" "$@"
LAUNCH
chmod +x env.sh start-battlenet.sh
# shellcheck disable=SC1091
source ./env.sh

say "6/7 Creez prefixul Wine si instalez DXVK"
wineboot -u >/dev/null 2>&1 || true
cp "runtime/$DDIR"/x64/*.dll prefix/drive_c/windows/system32/
cp "runtime/$DDIR"/x32/*.dll prefix/drive_c/windows/syswow64/
wine reg add 'HKCU\Software\Wine' /v Version /d win10 /f >/dev/null
wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /d x11 /f >/dev/null
wine reg add 'HKCU\Software\Wine\X11 Driver' /v UseTakeFocus /d N /f >/dev/null
wine reg add 'HKCU\Software\Wine\DirectInput' /v MouseWarpOverride /d force /f >/dev/null

say "7/7 Shortcut in meniul de aplicatii"
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/battlenet-starcraft.desktop <<DESK
[Desktop Entry]
Type=Application
Name=Battle.net (StarCraft)
Exec=$DEST/start-battlenet.sh
Path=$DEST
Icon=applications-games
Terminal=false
Categories=Game;
DESK

say "Pornesc installer-ul Battle.net. In fereastra: Install -> (refuza Mono daca intreaba) -> login -> StarCraft -> Install."
nohup wine Battle.net-Setup.exe >/dev/null 2>&1 &
echo "Gata. Dupa instalare porneste din meniu: 'Battle.net (StarCraft)' sau  $DEST/start-battlenet.sh"
