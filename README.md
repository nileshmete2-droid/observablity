# 🔭 Observability Stack

Monitors your apps and collects their logs. You open a dashboard, pick your app, and see all its logs.

**What's inside:**

| Tool         | What it does        | Open at       |
|-------------|---------------------|---------------|
| **Grafana**  | Shows logs visually  | `localhost:3000` → login: `admin / admin` |
| **Loki**     | Stores logs          | runs in background |
| **Promtail** | Reads your app logs  | runs in background |
| **Prometheus** | Stores metrics     | `localhost:9090` |

---

## 📋 First-Time Setup

### 1. Install Podman

**RHEL / CentOS / AlmaLinux / Rocky:**
```bash
sudo dnf install -y podman podman-plugins
sudo pip3 install podman-compose
```

**Ubuntu / Debian:**
```bash
sudo apt update && sudo apt install -y podman
sudo pip3 install podman-compose
```

### 2. Copy to server

```bash
scp -r observability/ user@your-server:/opt/observability
```

### 3. Run setup

```bash
ssh user@your-server
cd /opt/observability
sudo bash setup.sh
```

This creates data folders, fixes permissions, and sets up auto-start. **You only do this once.**

### 4. Start

```bash
sudo systemctl start observability
```

### 5. Open Grafana

Go to `http://your-server-ip:3000`  
Login: `admin` / `admin`  
Go to **Dashboards → Observability → Service Logs Dashboard**

---

## 🔧 How to Add Your App's Logs

Your apps write logs to files on the server. You tell Promtail where those files are.

### Step 1 — Tell Podman where your logs are

Open `docker-compose.yml`. Find the promtail section. Add your log folder:

```yaml
# Under promtail → volumes, add a line like this:
- /path/to/your/app/logs:/var/log/myapp:ro,z
```

**Real examples:**

```yaml
# If your Node.js app writes logs to /home/deploy/my-api/logs/
- /home/deploy/my-api/logs:/var/log/my-api:ro,z

# If your Java app writes logs to /opt/spring-app/logs/
- /opt/spring-app/logs:/var/log/spring-app:ro,z

# If you want Nginx logs
- /var/log/nginx:/var/log/nginx:ro,z
```

> **What does `:ro,z` mean?**  
> `ro` = Promtail can only read, not modify your logs  
> `z` = Makes it work on SELinux servers (just always add it)

### Step 2 — Give it a name

Open `promtail/promtail-config.yml`. Uncomment one of the examples, or add:

```yaml
  - job_name: my-app
    static_configs:
      - targets: [localhost]
        labels:
          service: "my-app"                     # ← this name shows in Grafana
          __path__: "/var/log/myapp/*.log"       # ← must match what you added above
```

### Step 3 — Restart

```bash
cd /opt/observability
podman-compose restart promtail
```

Now open Grafana → pick your app from the dropdown → see logs!

---

## 💾 Your Data is Safe

All data is saved on your server's disk in the `data/` folder:

```
/opt/observability/data/
├── prometheus/    ← metrics (kept for 15 days)
├── loki/          ← logs (kept for 15 days)
├── grafana/       ← your dashboard settings
└── promtail/      ← remembers where it stopped reading
```

- ✅ Server reboots? Data is still there.
- ✅ Podman restarts? Data is still there.
- ✅ After reboot, Promtail continues from where it left off. No duplicate logs.
- ✅ Logs older than 15 days are automatically cleaned up.

---

## 🔁 Auto-Start

The `setup.sh` script already sets this up. After a server reboot, the stack starts automatically.

**Useful commands:**

```bash
sudo systemctl start observability       # Start
sudo systemctl stop observability        # Stop
sudo systemctl restart observability     # Restart
sudo systemctl status observability      # Check if running
```

**Alternative — use crontab instead:**

```bash
sudo crontab -e
# Add this line:
@reboot sleep 30 && cd /opt/observability && podman-compose up -d
```

---

## 🛑 Stop Everything

```bash
cd /opt/observability
podman-compose down           # Stop (data stays)
podman-compose down -v        # Stop and delete data
```

---

## 🔐 Passwords

| What | Username | Password |
|------|----------|----------|
| Grafana login | admin | admin |
| Internal services | obsuser | obspass123 |

> **For production:** search for `obsuser` and `obspass123` across all files and change them.
