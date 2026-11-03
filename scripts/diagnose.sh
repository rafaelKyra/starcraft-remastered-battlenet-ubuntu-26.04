#!/bin/bash
# Verificari rapide cand ceva nu merge. Utilizare: ./scripts/diagnose.sh [folder_instalare]
D="${1:-$PWD/starcraft-linux}"; source "$D/env.sh" 2>/dev/null || { echo "env.sh lipsa in $D"; exit 1; }
echo "OS: $(lsb_release -ds)  Kernel: $(uname -r)"; wine --version
ls -l /dev/ntsync 2>&1; systemctl is-active avahi-daemon
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>&1
DXVK_LOG_LEVEL=info DXVK_LOG_PATH=/tmp timeout 20 wine cmd /c ver >/dev/null 2>&1; grep -h 'Found device' /tmp/*_d3d*.log 2>/dev/null | sort -u
for p in $(pgrep -f 'Battle.net.exe|StarCraft.exe'|head -2); do echo "pid $p:"; tr '\0' '\n' </proc/$p/environ | grep -E 'WINEFSYNC|LD_PRELOAD'; done
