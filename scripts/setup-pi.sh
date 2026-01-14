#!/bin/bash
# Script d'installation pour le monitoring du refuge Bonneval
# Usage: ./setup-pi.sh <wifi|elec> <healthcheck-url>

set -e

# --- Arguments ---
ROLE="${1:-}"
HC_URL="${2:-}"

if [ -z "$ROLE" ] || [ -z "$HC_URL" ]; then
    echo "Usage: $0 <wifi|elec> <healthcheck-url>"
    echo "  wifi  - Pi sur onduleur (test connectivité)"
    echo "  elec  - Pi sur secteur (test électricité)"
    exit 1
fi

if [ "$ROLE" != "wifi" ] && [ "$ROLE" != "elec" ]; then
    echo "Erreur: le rôle doit être 'wifi' ou 'elec'"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Erreur: lancer en root (sudo $0 $*)"
    exit 1
fi

HOSTNAME="pi-bonneval-${ROLE}"

echo "=== Setup Pi Bonneval - ${ROLE} ==="
echo "Hostname: ${HOSTNAME}"
echo "Healthcheck URL: ${HC_URL}"
echo ""

# --- Installation des paquets ---
echo "[1/7] Installation des paquets..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y curl watchdog

# --- Hostname ---
echo "[2/7] Configuration du hostname..."
hostnamectl set-hostname "$HOSTNAME"
if grep -q "127.0.1.1" /etc/hosts; then
    sed -i "s/127.0.1.1.*/127.0.1.1\t${HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1	${HOSTNAME}" >> /etc/hosts
fi

# --- Optimisation carte SD (tmpfs) ---
echo "[3/7] Optimisation carte SD (montages tmpfs)..."
FSTAB_ENTRIES="
# Tmpfs for SD card longevity
tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,size=64M 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,nodev,size=32M 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,nodev,size=32M 0 0
"

# Add tmpfs entries if not present
if ! grep -q "tmpfs /tmp" /etc/fstab; then
    echo "$FSTAB_ENTRIES" >> /etc/fstab
fi

# --- Désactivation du swap ---
echo "[4/7] Désactivation du swap..."
dphys-swapfile swapoff 2>/dev/null || true
dphys-swapfile uninstall 2>/dev/null || true
systemctl disable dphys-swapfile 2>/dev/null || true
swapoff -a

# --- Création du script heartbeat ---
echo "[5/7] Création du script heartbeat..."
cat > /usr/local/bin/heartbeat.sh << 'SCRIPT'
#!/bin/bash
# Heartbeat script for healthchecks.io
HC_URL="__HC_URL__"
curl -fsS -m 10 --retry 3 "${HC_URL}" >/dev/null 2>&1
SCRIPT

sed -i "s|__HC_URL__|${HC_URL}|" /usr/local/bin/heartbeat.sh
chmod +x /usr/local/bin/heartbeat.sh

# --- Création du service systemd ---
echo "[6/7] Création du service et timer systemd..."
cat > /etc/systemd/system/heartbeat.service << 'SERVICE'
[Unit]
Description=Heartbeat to healthchecks.io
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/heartbeat.sh
SERVICE

cat > /etc/systemd/system/heartbeat.timer << 'TIMER'
[Unit]
Description=Run heartbeat every 5 minutes

[Timer]
OnBootSec=30
OnUnitActiveSec=5min
AccuracySec=10s

[Install]
WantedBy=timers.target
TIMER

systemctl daemon-reload
systemctl enable heartbeat.timer
systemctl start heartbeat.timer

# --- Configuration du watchdog ---
echo "[7/7] Configuration du watchdog matériel..."
cat > /etc/watchdog.conf << 'WATCHDOG'
# Hardware watchdog configuration
watchdog-device = /dev/watchdog
watchdog-timeout = 15
max-load-1 = 24
interval = 10
WATCHDOG

# Enable watchdog in boot config if not present
if ! grep -q "dtparam=watchdog=on" /boot/firmware/config.txt 2>/dev/null; then
    echo "dtparam=watchdog=on" >> /boot/firmware/config.txt 2>/dev/null || \
    echo "dtparam=watchdog=on" >> /boot/config.txt 2>/dev/null || true
fi

systemctl enable watchdog
systemctl start watchdog 2>/dev/null || true

# --- Résumé ---
echo ""
echo "=== Installation terminée ==="
echo ""
echo "Hostname:   ${HOSTNAME}"
echo "Heartbeat:  toutes les 5 minutes"
echo "URL:        ${HC_URL}"
echo ""
echo "État des services :"
systemctl is-enabled heartbeat.timer && echo "  heartbeat.timer: activé"
systemctl is-enabled watchdog && echo "  watchdog: activé"
echo ""
echo "Prochaines étapes :"
echo "  1. Redémarrer : sudo reboot"
echo "  2. Vérifier healthchecks.io pour les pings entrants"
echo "  3. Vérifier : systemctl status heartbeat.timer"
echo ""
