cat > collect_system_data.sh << 'EOF'
#!/bin/bash
# collect_system_data.sh – Simple pipe-separated metrics collector

DATA_DIR="./data"
mkdir -p "$DATA_DIR"
LOG_FILE="$DATA_DIR/metrics.log"

# Timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Load average (1 min) – extract as float
LOAD_1=$(uptime | awk -F 'load average:' '{print $2}' | awk -F ',' '{print $1}' | sed 's/ //g')

# Memory usage percentage (integer)
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

# Disk usage for root (integer)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Top 5 CPU processes: format "name:cpu,name:cpu,..."
TOP_CPU=$(ps -eo comm,%cpu --sort=-%cpu | head -6 | tail -5 | awk '{printf "%s:%s,", $1, $2}' | sed 's/,$//')

# Network interface (first non-loopback)
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
if [ -n "$INTERFACE" ]; then
    RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
else
    RX=0
    TX=0
fi

# Failed SSH logins in last 5 minutes
FAILED_LOGINS=0
if command -v journalctl >/dev/null 2>&1; then
    FAILED_LOGINS=$(journalctl _COMM=sshd --since "5 minutes ago" 2>/dev/null | grep -c "Failed password" || echo 0)
fi

# Write as pipe-separated line (no spaces around pipes)
echo "$TIMESTAMP|$LOAD_1|$MEM_PERCENT|$DISK_USAGE|$TOP_CPU|$RX|$TX|$FAILED_LOGINS" >> "$LOG_FILE"
EOF

chmod +x collect_system_data.sh
