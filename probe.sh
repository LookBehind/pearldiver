#!/bin/bash
# Probe v2 (pearl-probe-test only): try Nsight Compute on the real miner for one kernel launch.
echo "PROBE start $(uname -r)"; grep -qiE "microsoft|wsl" /proc/version && echo "PROBE host=WSL2" || echo "PROBE host=linux"
nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader | sed 's/^/PROBE gpu: /'
export DEBIAN_FRONTEND=noninteractive
curl -fsSL -o /tmp/k.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && dpkg -i /tmp/k.deb >/dev/null && apt-get update -qq
P=$(apt-cache search --names-only '^nsight-compute-20' | sort | tail -1 | cut -d' ' -f1); echo "PROBE installing $P"
t0=$(date +%s); apt-get install -y -qq --no-install-recommends $P >/dev/null 2>&1; echo "PROBE install rc=$? in $(( $(date +%s)-t0 ))s"
NCU=$(ls /opt/nvidia/nsight-compute/*/ncu 2>/dev/null | head -1); echo "PROBE ncu=$NCU"
curl -fsSL https://raw.githubusercontent.com/LookBehind/pearldiver/refs/heads/main/pearldiver-salad.tar.gz | tar xz -C /opt
M=sm__cycles_elapsed.avg,sm__pipe_tensor_op_imma_cycles_active.avg.pct_of_peak_sustained_active,smsp__average_warp_latency_issue_stalled_math_pipe_throttle.ratio,smsp__average_warp_latency_issue_stalled_wait.ratio,smsp__average_warp_latency_issue_stalled_barrier.ratio,smsp__average_warp_latency_issue_stalled_short_scoreboard.ratio,smsp__average_warp_latency_issue_stalled_long_scoreboard.ratio,smsp__average_warp_latency_issue_stalled_selected.ratio,smsp__average_warp_latency_issue_stalled_not_selected.ratio
cd /opt/pearldiver-salad && timeout 600 env PEARL_PIPE=1 PG_IMMA_STALL=0 PG_GROUP_M=32 PG_ASYNC_REORDER=60000 PG_MODE=w128h $NCU -k regex:pearl_w128 -s 3 -c 1 --metrics $M \
  ./pearldiver --pool pool.swipe2win.co:3333 --wallet TO_USDT_TRC20:TBo2xx7mvtLLAQkDGVCjLy41nwbH28816p --worker probe --gpus 0 --idx-base 15 --m 8192 --api-port 21373 2>&1 \
  | grep -E "ERR_|==ERROR==|==PROF==|sm__|smsp__|permission|Permission" | head -20 | sed 's/^/PROBE ncu: /'
echo "PROBE done"; sleep 3600
