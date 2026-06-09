#!/bin/bash
# collect_system_data.sh – Collects Linux system metrics

DATA_DIR="./data"
mkdir -p "$DATA_DIR"
LOG_FILE="$DATA_DIR/metrics.log"

# Timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# CPU load (1,5,15 min)
LOAD=$(uptime | awk -F 'load average:' '{print $2}' | sed 's/ //g')

# Memory usage (used/total %)
MEM_TOTAL=$(free -b | awk '/^Mem:/ {print $2}')
MEM_AVAIL=$(free -b | awk '/^Mem:/ {print $7}')
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

# Disk usage for root (/)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Top 5 CPU consuming processes (comm, cpu%)
TOP_CPU=$(ps -eo comm,%cpu --sort=-%cpu | head -6 | tail -5 | awk '{printf "{\"proc\":\"%s\",\"cpu\":%s},", $1, $2}' | sed 's/,$//')

# Network RX/TX 
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
if [ -n "$INTERFACE" ]; then
    RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
else
    RX=0
    TX=0
fi

# failed logins
FAILED_LOGINS=$(journalctl _COMM=sshd --since "5 minutes ago" 2>/dev/null | grep -c "Failed password" || echo 0)

# JSON object
jq -n \
    --arg ts "$TIMESTAMP" \
    --arg load "$LOAD" \
    --arg mem_percent "$MEM_PERCENT" \
    --arg disk_usage "$DISK_USAGE" \
    --arg top_cpu "$TOP_CPU" \
    --arg rx "$RX" \
    --arg tx "$TX" \
    --arg failed "$FAILED_LOGINS" \
    '{timestamp: $ts, load_avg: $load, mem_usage_percent: ($mem_percent|tonumber), disk_usage_percent: ($disk_usage|tonumber), top_cpu_procs: $top_cpu, net_rx_bytes: ($rx|tonumber), net_tx_bytes: ($tx|tonumber), failed_logins_5min: ($failed|tonumber)}'

# Append file (using >>)
} >> "$LOG_FILE"
