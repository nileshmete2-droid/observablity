# 🔭 Observability Stack

Collects your app logs and shows them in a dashboard. You pick your app, you see the logs. That's it.

**GitHub:** https://github.com/nileshmete2-droid/observablity

---

## 🚀 Install (One Command)

SSH into your server and run:

```bash
curl -fsSL https://raw.githubusercontent.com/nileshmete2-droid/observablity/main/setup.sh | sudo bash
```

This will:
- Install Podman (if not already there)
- Download the stack to `/opt/observability`
- Create data folders
- Fix SELinux permissions
- Set up auto-start on reboot
- Start everything

When done, open: **http://your-server-ip:3000** → login `admin / admin`

---

## 🔧 Add Your Logs (2 Steps)

You have a log file like `/opt/sit/executables/java-services/flowable/flow.log` and you want to see it in Grafana.

### Step 1 — Mount the log folder

Open `docker-compose.yml`. Find the promtail section. Uncomment or add your log folder:

```yaml
# Uncomment this line to mount your app logs:
- /opt/apps:/opt/apps:ro,z
```

### Step 2 — Add label + path

Open `promtail/promtail-config.yml`. Uncomment the example or add your own:

```yaml
  - job_name: order-service
    static_configs:
      - targets: [localhost]
        labels:
          service: "order-service"                                # ← label in Grafana
          __path__: "/opt/apps/order-service/logs/app.log"       # ← your log file
```

Then restart:

```bash
cd /opt/observability
podman-compose restart promtail
```

**Done!** Open Grafana → pick "order-service" from dropdown → see logs.

---

## 📝 More Examples

Want to add more services? Just copy-paste and change the **label** and **path**:

| Service | Label | Log Path |
|---------|-------|----------|
| Order Service | `order-service` | `/opt/apps/order-service/logs/app.log` |
| Payment Service | `payment-service` | `/opt/apps/payment-service/logs/*.log` |
| User Service | `user-service` | `/opt/apps/user-service/logs/*.log` |
| Auth Service | `auth-service` | `/opt/apps/auth-service/logs/*.log` |
| Notification | `notification-service` | `/opt/apps/notification-service/logs/*.log` |
| Single log file | `my-app` | `/opt/apps/my-app/app.log` |
| Nginx | `nginx` | `/var/log/nginx/*.log` |

All these examples are already in `promtail/promtail-config.yml` — just uncomment the ones you need.

---

## 💾 Data

- Logs and metrics are kept for **15 days**, then auto-deleted
- All data is saved in `/opt/observability/data/` — survives reboots
- After a restart, Promtail continues from where it left off (no duplicates)

---

## 🔁 Server Reboots

The stack starts automatically after every reboot. You can also control it manually:

```bash
sudo systemctl start observability       # Start
sudo systemctl stop observability        # Stop
sudo systemctl restart observability     # Restart
sudo systemctl status observability      # Check
```

---

## 🔐 Passwords

| What | Username | Password |
|------|----------|----------|
| Grafana login | `admin` | `admin` |
| Internal services | `obsuser` | `obspass123` |

Change these in production.
