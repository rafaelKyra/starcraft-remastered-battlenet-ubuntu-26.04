#!/bin/bash
# Salveaza "starea buna" (Wine + setari + Battle.net, FARA jocul) ca sa poti reveni daca un update strica ceva.
# Utilizare: ./scripts/backup-prefix.sh [folder_instalare]      Restaurare: ./scripts/restore-prefix.sh [folder_instalare] fisier.tar.zst
D="$(realpath "${1:-$HOME/starcraft-linux}")"; OUT="$D/backups"; mkdir -p "$OUT"
source "$D/env.sh"; wineserver -k 2>/dev/null; sleep 2
F="$OUT/prefix-$(date +%Y-%m-%d_%H%M).tar.zst"
tar --zstd -cf "$F" -C "$D" --exclude='prefix/drive_c/Program Files (x86)/StarCraft' --exclude='prefix/drive_c/Program Files (x86)/StarCraft II' prefix env.sh start-battlenet.sh
ls -lh "$F"; echo "Backup gata. Jocul (StarCraft/) nu e inclus - ramane pe disc."
