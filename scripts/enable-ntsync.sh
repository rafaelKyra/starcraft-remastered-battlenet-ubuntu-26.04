#!/bin/bash
# OPTIONAL, necesita sudo: sincronizare thread-uri in kernel (Linux >= 6.14) = mai putin lag.
modinfo ntsync >/dev/null 2>&1 || { echo "Kernelul tau nu are ntsync."; exit 1; }
sudo modprobe ntsync && echo ntsync | sudo tee /etc/modules-load.d/ntsync.conf && ls -l /dev/ntsync
