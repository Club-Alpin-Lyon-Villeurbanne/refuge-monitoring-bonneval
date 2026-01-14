# Troubleshooting - Monitoring Refuge Bonneval

## Diagnostic par scénario d'alerte

### Pi-WIFI UP, Pi-ELEC DOWN

**Diagnostic** : Coupure électrique secteur

Le Pi-ELEC (sur secteur direct) ne répond plus, mais le Pi-WIFI (sur onduleur) fonctionne encore.

**Actions** :
1. Attendre - la coupure peut être temporaire
2. Si prolongé : contacter quelqu'un sur place pour vérifier
3. Quand Pi-ELEC revient UP : la coupure est terminée

### Pi-WIFI DOWN, Pi-ELEC DOWN

**Diagnostic** : Perte réseau OU onduleur épuisé

Deux possibilités :
- Routeur 4G HS ou perte de réseau mobile
- Coupure longue : onduleur épuisé, tout est éteint

**Actions** :
1. Vérifier si le réseau mobile fonctionne dans la zone (consulter les cartes de couverture)
2. Contacter quelqu'un sur place si possible
3. Planifier une intervention si ça persiste

### Pi-WIFI DOWN, Pi-ELEC UP

**Diagnostic** : Pi-WIFI HS (rare)

Le Pi sur onduleur a un problème (carte SD morte, crash système).

**Actions** :
1. Tenter un reboot à distance (si accessible) :
   ```bash
   make reboot-wifi
   ```
2. Si inaccessible : intervention sur place nécessaire
3. Remplacer la carte SD si défaillante

### Les deux checks n'ont jamais fonctionné

**Diagnostic** : Problème de configuration

**Vérifier** :
1. URLs healthchecks.io correctes dans `.env`
2. Pi connectés au bon réseau WiFi
3. Résolution DNS :
   ```bash
   ping pi-bonneval-wifi.local
   ```

## Commandes de diagnostic SSH

### Connexion rapide

```bash
make ssh-wifi
make ssh-elec
```

### État général

```bash
# Hostname et uptime
hostname && uptime

# Mémoire et swap (swap doit être à 0)
free -h

# Espace disque
df -h

# Température CPU
vcgencmd measure_temp
```

### Services heartbeat

```bash
# État du timer
systemctl status heartbeat.timer

# Dernières exécutions
journalctl -u heartbeat.service -n 10

# Test manuel du heartbeat
/usr/local/bin/heartbeat.sh && echo "OK" || echo "FAILED"
```

### Réseau

```bash
# Connectivité WiFi
iwconfig wlan0

# IP
ip addr show wlan0

# Test DNS
ping -c 2 google.com

# Test healthchecks.io
curl -v https://hc-ping.com/
```

### Watchdog

```bash
# État du watchdog
systemctl status watchdog

# Logs watchdog
journalctl -u watchdog -n 10
```

## Procédure carte SD morte

### Symptômes
- Pi inaccessible en SSH
- Pas de réponse au ping
- LED verte du Pi éteinte ou fixe (pas de clignotement)

### Sur place

1. Débrancher le Pi
2. Retirer la carte SD
3. Tester la carte sur un PC (souvent illisible si morte)
4. Insérer une nouvelle carte SD flashée
5. Rebrancher le Pi
6. Attendre 3-5 minutes

### À distance (après remplacement carte)

```bash
# Vérifier la connexion
ping pi-bonneval-wifi.local

# Redéployer
make deploy-wifi  # ou deploy-elec

# Vérifier
make check-wifi
```

## Changement de WiFi

Si le WiFi du refuge change (nouveau SSID ou mot de passe), voici la procédure pour mettre à jour les Pi.

### Workflow avec hotspot téléphone

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. Le WiFi du refuge a changé                                  │
│     Ancien: "RefugeWiFi" / "ancienpass"                         │
│     Nouveau: "NouveauWiFi" / "nouveaupass"                      │
│                                                                 │
│  2. Sur ton téléphone, crée un hotspot avec L'ANCIEN WiFi:      │
│     📱 Nom: "RefugeWiFi"  Mot de passe: "ancienpass"            │
│                                                                 │
│  3. Les Pi se connectent automatiquement au hotspot             │
│     (ils croient que c'est l'ancien WiFi)                       │
│                                                                 │
│  4. Connecte ton laptop au même hotspot                         │
│     💻 ───WiFi───► 📱 ◄───WiFi─── 🥧 Pi                         │
│                                                                 │
│  5. Lance la mise à jour:                                       │
│     $ make update-wifi-wifi                                     │
│     $ make update-wifi-elec                                     │
│                                                                 │
│  6. Entre les NOUVEAUX credentials quand demandé                │
│                                                                 │
│  7. Désactive le hotspot                                        │
│     Les Pi se connectent au nouveau WiFi du refuge              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Commandes

```bash
# Mise à jour Pi-WIFI
make update-wifi-wifi

# Mise à jour Pi-ELEC
make update-wifi-elec
```

Le script demande interactivement le nouveau SSID et mot de passe (pas d'historique bash).

### Si le hotspot ne fonctionne pas

Alternative : modifier la carte SD directement.

1. Retirer la carte SD du Pi
2. La monter sur un PC :
   - **Linux** : montage auto, partition `rootfs`
   - **macOS** : utiliser ext4fuse ou Paragon extFS (la partition ext4 n'est pas lisible nativement)
   - **Windows** : utiliser Ext2Fsd ou WSL
3. Éditer `/etc/wpa_supplicant/wpa_supplicant.conf` sur la partition rootfs :
   ```
   network={
       ssid="NouveauSSID"
       psk="NouveauMotDePasse"
       scan_ssid=1  # si SSID caché
   }
   ```
4. Remettre la carte dans le Pi

## Prévention

### Bonnes pratiques
- Garder une carte SD de rechange flashée
- Vérifier les checks healthchecks.io régulièrement
- Mettre à jour l'OS occasionnellement (tous les 6 mois)

### Signes avant-coureurs
- Heartbeats irréguliers (visibles dans l'historique healthchecks.io)
- Temps de réponse SSH anormalement longs
- Erreurs dans les logs système
