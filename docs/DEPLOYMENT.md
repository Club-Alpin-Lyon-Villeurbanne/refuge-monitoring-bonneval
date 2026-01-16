# Déploiement - Monitoring Refuge Bonneval

## Prérequis

- 2x Raspberry Pi Zero 2 W
- 2x Cartes microSD (4 Go minimum, classe A1 recommandée)
- Onduleur avec le Pi-WIFI et le routeur 4G
- Compte healthchecks.io (gratuit jusqu'à 20 checks)
- Accès SSH aux Pi (être sur le même réseau WiFi)

## 1. Créer les checks sur healthchecks.io

1. Aller sur https://healthchecks.io
2. Créer un nouveau projet "Refuge Bonneval"
3. Créer 2 checks :

| Check | Period | Grace | Description |
|-------|--------|-------|-------------|
| pi-bonneval-wifi | 1 minute | 2 minutes | Pi sur onduleur (test WiFi) |
| pi-bonneval-elec | 1 minute | 2 minutes | Pi sur secteur (test électricité) |

4. Copier les URLs de ping pour chaque check

## 2. Configurer les notifications

Dans healthchecks.io, configurer les intégrations :

- **Email** : notifications de base
- **SMS** (optionnel) : pour alertes critiques
- **Signal/Telegram** (optionnel) : notifications instantanées

Recommandation : configurer au minimum l'email.

## 3. Préparer les cartes SD

### Télécharger Raspberry Pi Imager

1. Aller sur https://www.raspberrypi.com/software/
2. Télécharger et installer Raspberry Pi Imager pour ton OS

### Workflow de création d'une carte SD

```
┌─────────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI IMAGER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ CHOOSE DEVICE   │ ──► Raspberry Pi Zero 2 W                  │
│  └─────────────────┘                                            │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ CHOOSE OS       │ ──► Raspberry Pi OS (other)                │
│  └─────────────────┘         └──► Raspberry Pi OS Lite (64-bit) │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ CHOOSE STORAGE  │ ──► Ta carte microSD                       │
│  └─────────────────┘                                            │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ NEXT            │ ──► "Edit Settings" (pas "No")             │
│  └─────────────────┘                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Configuration dans "Edit Settings"

#### Onglet "GENERAL"

| Paramètre | Valeur Pi-WIFI | Valeur Pi-ELEC |
|-----------|----------------|----------------|
| Set hostname | `pi-bonneval-wifi` | `pi-bonneval-elec` |
| Set username and password | ✓ | ✓ |
| Username | `bonneval` | `bonneval` |
| Password | (mot de passe fort) | (même mot de passe) |
| Configure wireless LAN | ✓ | ✓ |
| SSID | (SSID du refuge) | (SSID du refuge) |
| Password | (mot de passe WiFi) | (mot de passe WiFi) |
| Hidden SSID | ✓ (si SSID caché) | ✓ (si SSID caché) |
| Wireless LAN country | FR | FR |
| Set locale settings | ✓ | ✓ |
| Time zone | Europe/Paris | Europe/Paris |
| Keyboard layout | fr | fr |

#### Onglet "SERVICES"

| Paramètre | Valeur |
|-----------|--------|
| Enable SSH | ✓ |
| Use password authentication | ● (sélectionné) |

#### Onglet "OPTIONS"

| Paramètre | Valeur |
|-----------|--------|
| Eject media when finished | ✓ |

### Flasher la carte

1. Cliquer "Save" pour sauvegarder les settings
2. Cliquer "Yes" pour appliquer les settings
3. Cliquer "Yes" pour confirmer l'effacement de la carte
4. Attendre la fin du flash (~5-10 min)
5. Retirer la carte quand "Write Successful" apparaît

### Répéter pour la deuxième carte

Refaire le processus avec hostname `pi-bonneval-elec`.

**Astuce** : Les settings sont sauvegardés, il suffit de changer le hostname.

## 4. Premier démarrage

1. Insérer la carte SD dans le Pi
2. Brancher l'alimentation
3. Attendre 2-3 minutes (premier boot)
4. Vérifier la connexion :

```bash
ping pi-bonneval-wifi.local
```

Si le ping ne fonctionne pas, vérifier :
- Le Pi est bien connecté au même réseau
- Le hostname mDNS fonctionne (sinon utiliser l'IP)

## 5. Déployer le monitoring

```bash
# Configurer
cp .env.example .env
# Éditer .env avec les URLs healthchecks.io

# Valider la config
make test

# Déployer Pi-WIFI
make deploy-wifi

# Déployer Pi-ELEC
make deploy-elec
```

## 6. Vérifier le déploiement

```bash
# Vérifier les services
make check-wifi
make check-elec
```

Sur healthchecks.io, les checks doivent passer au vert dans les 2-3 minutes.

## Procédure de remplacement d'urgence

Si une carte SD meurt et qu'il faut la remplacer rapidement :

### Prérequis
- Carte SD de rechange pré-flashée (recommandé)
- Ou : laptop avec Raspberry Pi Imager + carte SD vierge

### Procédure

1. **Identifier le Pi défaillant** via healthchecks.io
2. **Flasher une nouvelle carte** (voir section 3)
3. **Sur place** :
   - Éteindre le Pi (débrancher)
   - Remplacer la carte SD
   - Rebrancher
4. **À distance** (après 3-5 min) :
   ```bash
   make deploy-wifi  # ou deploy-elec
   ```
5. **Vérifier** sur healthchecks.io

### Carte SD pré-configurée

Pour un remplacement encore plus rapide, garder une carte SD déjà flashée avec :
- OS installé
- WiFi configuré
- User `bonneval` créé

Il suffira alors de lancer `make deploy-xxx` après insertion.

## Checklist finale

- [ ] Pi-WIFI connecté et sur onduleur
- [ ] Pi-ELEC connecté et sur secteur direct
- [ ] Routeur 4G sur onduleur
- [ ] Check pi-bonneval-wifi vert sur healthchecks.io
- [ ] Check pi-bonneval-elec vert sur healthchecks.io
- [ ] Notifications email configurées et testées
- [ ] Carte SD de rechange disponible (optionnel mais recommandé)

## Maintenance

### Mise à jour système (occasionnelle)

```bash
ssh bonneval@pi-bonneval-wifi.local
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### Vérifier les logs

```bash
make check-wifi
# ou en détail :
ssh bonneval@pi-bonneval-wifi.local "journalctl -u heartbeat.service -n 20"
```
