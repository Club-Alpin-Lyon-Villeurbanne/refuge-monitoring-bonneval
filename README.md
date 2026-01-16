# Monitoring Refuge Bonneval

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Système de monitoring simple et fiable pour refuges de montagne isolés,
> développé par le [Club Alpin de Lyon](https://www.clubalpinlyon.fr/).

## Pourquoi ce projet ?

Les refuges de montagne sont souvent isolés, avec une électricité instable et un accès Internet limité (4G). Ce système permet de **détecter à distance** :

- Les coupures électriques
- Les pertes de connexion Internet

Avec seulement **2 Raspberry Pi Zero** et un compte gratuit [healthchecks.io](https://healthchecks.io).

## Comment ça marche ?

Deux Pi envoient un heartbeat toutes les minutes. Selon lequel répond, on sait ce qui se passe :

| Pi-WIFI | Pi-ELEC | Diagnostic |
|---------|---------|------------|
| UP | UP | Tout fonctionne |
| UP | DOWN | Coupure électrique |
| DOWN | DOWN | Perte réseau ou onduleur épuisé |
| DOWN | UP | Pi-WIFI HS (rare) |

## Architecture

```
                        ┌─────────────────────────────────────────────────────────┐
                        │                    REFUGE BONNEVAL                       │
                        │                                                          │
   ┌──────────┐         │  ┌─────────────┐         ┌─────────────┐                │
   │          │         │  │ ONDULEUR    │         │             │                │
   │ SECTEUR  │─────────┼──┤             │         │  ROUTEUR 4G │────────────────┼────► Internet
   │   EDF    │         │  │ ┌─────────┐ │         │  (onduleur) │                │
   │          │         │  │ │ Pi-WIFI │ │         │             │                │
   └──────────┘         │  │ └────┬────┘ │         └─────────────┘                │
        │               │  └──────┼──────┘               ▲                        │
        │               │         │ heartbeat            │                        │
        │               │         └──────────────────────┘                        │
        │               │                                                          │
        │               │  ┌─────────┐                   ▲                        │
        └───────────────┼──┤ Pi-ELEC ├───────────────────┘                        │
                        │  └─────────┘   heartbeat                                │
                        │  (secteur direct)                                        │
                        └─────────────────────────────────────────────────────────┘

                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │ healthchecks.io │
                                   │                 │
                                   │  - pi-wifi      │
                                   │  - pi-elec      │
                                   └────────┬────────┘
                                            │
                                            ▼
                                      Alertes Email/SMS
```

## Quickstart

```bash
# 1. Cloner le repo
git clone https://github.com/club-alpin-lyon/refuge-monitoring-bonneval.git
cd refuge-monitoring-bonneval

# 2. Configurer
cp .env.example .env
# Éditer .env avec les URLs healthchecks.io

# 3. Déployer
make deploy-wifi
make deploy-elec

# 4. Vérifier
make check-wifi
make check-elec
```

## Documentation

- [Guide de déploiement](docs/DEPLOYMENT.md) - Installation pas à pas
- [Dépannage](docs/TROUBLESHOOTING.md) - Diagnostic et résolution de problèmes

## Matériel nécessaire

- 2x Raspberry Pi Zero 2 W (~15€ chacun)
- 2x Carte microSD 4 Go minimum (~5€ chacune)
- 1x Onduleur (déjà présent au refuge)
- Compte [healthchecks.io](https://healthchecks.io) (gratuit)

**Coût total** : ~40€

## Contribuer

Ce projet est maintenu par des bénévoles du Club Alpin de Lyon.
Toute aide est la bienvenue ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) - Libre d'utilisation et de modification.
