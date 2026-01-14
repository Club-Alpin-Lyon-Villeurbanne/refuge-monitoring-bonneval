#!/bin/bash
# Mise à jour des credentials WiFi sur un Pi Bonneval
# Usage: sudo ./update-wifi.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Erreur: lancer en root (sudo $0)"
    exit 1
fi

echo "=== Mise à jour WiFi ==="
echo ""
read -p "Nouveau SSID: " SSID
read -s -p "Mot de passe: " PSK
echo ""
read -p "SSID caché ? [y/N]: " HIDDEN

if [ -z "$SSID" ]; then
    echo "Erreur: le SSID ne peut pas être vide"
    exit 1
fi

if [ -z "$PSK" ]; then
    echo "Attention: mot de passe vide (réseau ouvert)"
fi

# Déterminer si SSID caché
SCAN_SSID=""
if [ "$HIDDEN" = "y" ] || [ "$HIDDEN" = "Y" ]; then
    SCAN_SSID="
    scan_ssid=1"
fi

# Sauvegarde de l'ancienne config
cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.bak 2>/dev/null || true

# Nouvelle configuration
cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=FR

network={
    ssid="$SSID"
    psk="$PSK"
${SCAN_SSID}}
EOF

echo ""
echo "Configuration mise à jour."
echo "Reconnexion au WiFi '$SSID'..."
wpa_cli -i wlan0 reconfigure >/dev/null 2>&1 || true

echo ""
echo "=== Fait ==="
echo "Le Pi va se connecter à '$SSID'."
echo "Tu peux maintenant fermer ton hotspot."
echo ""
echo "Ancienne config sauvegardée: /etc/wpa_supplicant/wpa_supplicant.conf.bak"
