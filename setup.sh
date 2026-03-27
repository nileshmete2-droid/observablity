#!/bin/bash
# =============================================================================
#  ONE-COMMAND SETUP
#
#  Run this on your Linux server and everything will be ready:
#    - Installs Podman (if not installed)
#    - Clones the repo from GitHub
#    - Creates data folders
#    - Fixes SELinux permissions
#    - Sets up auto-start on reboot
#    - Starts the stack
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/nileshmete2-droid/observablity/main/setup.sh | sudo bash
#
#  Or if you already cloned the repo:
#    cd /opt/observability
#    sudo bash setup.sh
# =============================================================================

set -e

echo ""
echo "========================================="
echo "  Observability Stack — Setup"
echo "========================================="
echo ""

# ----- 1. Install Podman if not installed ------------------------------------
echo "[1/6] Checking Podman..."
if command -v podman &> /dev/null; then
    echo "       Podman already installed ✓  ($(podman --version))"
else
    echo "       Installing Podman..."
    if command -v dnf &> /dev/null; then
        # RHEL / CentOS / AlmaLinux / Rocky / Fedora
        dnf install -y podman podman-plugins
    elif command -v yum &> /dev/null; then
        # Older CentOS / RHEL
        yum install -y podman
    elif command -v apt-get &> /dev/null; then
        # Ubuntu / Debian
        apt-get update && apt-get install -y podman
    else
        echo "ERROR: Could not detect package manager. Install Podman manually."
        exit 1
    fi
    echo "       Podman installed ✓"
fi

# ----- 2. Install podman-compose if not installed ----------------------------
echo "[2/6] Checking podman-compose..."
if command -v podman-compose &> /dev/null; then
    echo "       podman-compose already installed ✓"
else
    echo "       Installing podman-compose..."
    pip3 install podman-compose 2>/dev/null || pip install podman-compose
    echo "       podman-compose installed ✓"
fi

# ----- 3. Clone repo or use current directory --------------------------------
INSTALL_DIR="/opt/observability"
echo "[3/6] Setting up files..."

if [ -f "./docker-compose.yml" ]; then
    # Already inside the repo
    INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "       Using current directory: $INSTALL_DIR"
elif [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    echo "       Already exists at $INSTALL_DIR ✓"
else
    echo "       Cloning from GitHub..."
    git clone https://github.com/nileshmete2-droid/observablity.git "$INSTALL_DIR"
    echo "       Cloned to $INSTALL_DIR ✓"
fi

# ----- 4. Create data folders ------------------------------------------------
echo "[4/6] Creating data folders..."
mkdir -p "$INSTALL_DIR/data/prometheus"
mkdir -p "$INSTALL_DIR/data/loki"
mkdir -p "$INSTALL_DIR/data/grafana"
mkdir -p "$INSTALL_DIR/data/promtail"
chmod -R 777 "$INSTALL_DIR/data"
echo "       Data folders created ✓"

# ----- 5. Fix SELinux (if active) --------------------------------------------
echo "[5/6] Checking SELinux..."
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    chcon -Rt svirt_sandbox_file_t "$INSTALL_DIR/" 2>/dev/null || true
    setsebool -P container_manage_cgroup on 2>/dev/null || true
    setsebool -P container_connect_any on 2>/dev/null || true
    echo "       SELinux configured ✓"
else
    echo "       SELinux not active, skipping ✓"
fi

# ----- 6. Set up auto-start on reboot ---------------------------------------
echo "[6/6] Setting up auto-start..."
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
echo "       Auto-start enabled ✓"

# ----- Start the stack -------------------------------------------------------
echo ""
echo "Starting the stack..."
cd "$INSTALL_DIR"
podman-compose up -d

echo ""
echo "========================================="
echo "  ✅ DONE! Everything is running."
echo "========================================="
echo ""
echo "  Grafana:    http://$(hostname -I | awk '{print $1}'):3000"
echo "  Login:      admin / admin"
echo ""
echo "  NEXT STEP:"
echo "  1. Edit promtail/promtail-config.yml"
echo "  2. Add your log path and label (examples are inside)"
echo "  3. Run: podman-compose restart promtail"
echo ""
echo "  Commands:"
echo "    sudo systemctl start observability"
echo "    sudo systemctl stop observability"
echo "    sudo systemctl restart observability"
echo "========================================="
