#!/bin/bash
# GPU profiling-permission probe (pearl-probe-test only): can this Salad container read GPU performance counters?
echo "PROBE start $(uname -r)"
grep -qiE "microsoft|wsl" /proc/version && echo "PROBE host=WSL2" || echo "PROBE host=linux"
echo "PROBE driver params: $(grep -iE 'Profil' /proc/driver/nvidia/params 2>&1 | tr '\n' ' ')"
c=$(awk '/^CapEff/{print $2}' /proc/self/status); echo "PROBE CapEff=$c cap_sys_admin=$(( (0x$c >> 21) & 1 )) uid=$(id -u)"
nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader | sed 's/^/PROBE gpu: /'
echo "PROBE devs: $(ls /dev/nvidia* 2>&1 | tr '\n' ' ')"
echo "PROBE done"; sleep 3600
