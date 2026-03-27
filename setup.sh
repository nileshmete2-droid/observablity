#!/bin/bash
# =============================================================================
#  ONE-TIME SETUP SCRIPT
#  Run this once on your Linux server. It does everything for you:
#    - Creates folders for storing data
#    - Fixes permissions so everything works on SELinux
#    - Sets up auto-start on server reboot
#
#  Usage:  sudo bash setup.sh
# =============================================================================

set -e

echo "========================================="
echo "  Setting up Observability Stack"
echo "========================================="

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Create data folders (these store your logs, metrics, dashboards)
echo "[1/4] Creating data folders..."
mkdir -p "$INSTALL_DIR/data/prometheus"
mkdir -p "$INSTALL_DIR/data/loki"
mkdir -p "$INSTALL_DIR/data/grafana"
mkdir -p "$INSTALL_DIR/data/promtail"

# 2. Fix permissions so Podman containers can read/write
echo "[2/4] Setting permissions..."
chmod -R 777 "$INSTALL_DIR/data"

# 3. Handle SELinux (if it's running on this server)
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo "[3/4] Configuring SELinux..."
    chcon -Rt svirt_sandbox_file_t "$INSTALL_DIR/" 2>/dev/null || true
    setsebool -P container_manage_cgroup on 2>/dev/null || true
    setsebool -P container_connect_any on 2>/dev/null || true
    echo "       SELinux configured ✓"
else
    echo "[3/4] SELinux not active, skipping..."
fi

# 4. Install systemd service for auto-start on reboot
echo "[4/4] Setting up auto-start..."
cat > /etc/systemd/system/observability.service << EOF
[Unit]
Description=Observability Stack
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/podman-compose up -d
ExecStop=/usr/bin/podman-compose down
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable observability

echo ""
echo "========================================="
echo "  ✅ Setup Complete!"
echo "========================================="
echo ""
echo "  Start now:   sudo systemctl start observability"
echo "  Open:        http://your-server-ip:3000"
echo "  Login:       admin / admin"
echo ""
echo "  The stack will auto-start on every reboot."
echo "========================================="
