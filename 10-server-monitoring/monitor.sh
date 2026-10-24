
#!/bin/bash

LOG_DIR="$HOME/server-monitor/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/server-status.log"

{
    echo "================================="
    echo "Server Health Check"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "================================="

    echo "[CPU Load]"
    uptime

    echo ""
    echo "[Memory Usage]"
    free -h

    echo ""
    echo "[Disk Usage]"
    df -h /

    echo ""
    echo "[Top 5 CPU Processes]"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6

    echo ""
} | tee -a "$LOG_FILE"
