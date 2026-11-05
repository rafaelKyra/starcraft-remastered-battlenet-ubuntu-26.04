#!/bin/bash
# Repara "Battle.net porneste si se inchide la loc" (crash in libcef.dll, "free(): invalid size")
# pentru o instalare facuta cu versiunea veche a ghidului.  Utilizare: ./scripts/fix-startup-crash.sh [folder_instalare]
# Ce face: salveaza env.sh ca env.sh.bak-DATA, il inlocuieste cu varianta minima, scoate gamemoderun din launcher
# si muta DXVK de la global la "doar StarCraft.exe" (AppDefaults). Nu atinge jocul sau contul.
set -euo pipefail
D="$(realpath "${1:-$HOME/starcraft-linux}")"
[ -f "$D/env.sh" ] || { echo "Nu gasesc $D/env.sh"; exit 1; }
WDIR=$(sed -n 's#.*runtime/\(wine-[^/]*\)/bin.*#\1#p' "$D/env.sh" | head -1)
[ -n "$WDIR" ] || WDIR=$(basename "$(ls -d "$D"/runtime/wine-*staging-tkg-amd64 | head -1)")
cp "$D/env.sh" "$D/env.sh.bak-$(date +%Y%m%d%H%M)"
cat > "$D/env.sh" <<ENV
#!/bin/bash
R="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export WINEPREFIX="\$R/prefix" WINEARCH=win64
export PATH="\$R/runtime/$WDIR/bin:\$R/runtime:\$PATH"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export WINEDEBUG=-all
unset WAYLAND_DISPLAY
export WINE_GRAPHICS_DRIVER=x11
ENV
cat > "$D/start-battlenet.sh" <<'LAUNCH'
#!/bin/bash
D="$(dirname "$(readlink -f "$0")")"
source "$D/env.sh"
B="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
[ -f "$B" ] || B="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"
exec wine "$B" "$@"
LAUNCH
chmod +x "$D/env.sh" "$D/start-battlenet.sh"
# shellcheck disable=SC1091
source "$D/env.sh"
wineserver -k 2>/dev/null || true; sleep 3
for d in d3d9 d3d11 dxgi; do wine reg add 'HKCU\Software\Wine\AppDefaults\StarCraft.exe\DllOverrides' /v $d /d native /f >/dev/null; done
echo "Gata. Pornesti cu: $D/start-battlenet.sh   (env.sh vechi: $D/env.sh.bak-*)"
