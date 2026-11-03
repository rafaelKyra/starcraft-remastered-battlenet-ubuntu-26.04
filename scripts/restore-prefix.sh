#!/bin/bash
# Restaureaza un backup facut cu backup-prefix.sh (jocul instalat ramane neatins).
D="$(realpath "${1:?folder_instalare}")"; F="$(realpath "${2:?fisier_backup.tar.zst}")"
source "$D/env.sh"; wineserver -k 2>/dev/null; sleep 2
GAME="$D/prefix/drive_c/Program Files (x86)/StarCraft"; TMP="$D/.game-keep"
[ -d "$GAME" ] && mv "$GAME" "$TMP"
rm -rf "$D/prefix"; tar --zstd -xf "$F" -C "$D"
[ -d "$TMP" ] && mkdir -p "$D/prefix/drive_c/Program Files (x86)" && mv "$TMP" "$GAME"
echo "Restaurat din $F"
