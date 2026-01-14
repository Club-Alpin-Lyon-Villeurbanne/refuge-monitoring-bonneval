# Makefile pour le monitoring du refuge Bonneval
# Charge .env si présent
-include .env

PI_USER ?= bonneval
HOST_WIFI = pi-bonneval-wifi.local
HOST_ELEC = pi-bonneval-elec.local

.PHONY: help deploy-wifi deploy-elec check-wifi check-elec ssh-wifi ssh-elec reboot-wifi reboot-elec update-wifi-wifi update-wifi-elec test

help:
	@echo "Monitoring Refuge Bonneval"
	@echo ""
	@echo "Déploiement :"
	@echo "  make deploy-wifi        Déployer sur Pi-WIFI"
	@echo "  make deploy-elec        Déployer sur Pi-ELEC"
	@echo ""
	@echo "État :"
	@echo "  make check-wifi         Vérifier Pi-WIFI"
	@echo "  make check-elec         Vérifier Pi-ELEC"
	@echo ""
	@echo "SSH :"
	@echo "  make ssh-wifi           Connexion SSH Pi-WIFI"
	@echo "  make ssh-elec           Connexion SSH Pi-ELEC"
	@echo ""
	@echo "Maintenance :"
	@echo "  make reboot-wifi        Redémarrer Pi-WIFI"
	@echo "  make reboot-elec        Redémarrer Pi-ELEC"
	@echo "  make update-wifi-wifi   Changer WiFi sur Pi-WIFI"
	@echo "  make update-wifi-elec   Changer WiFi sur Pi-ELEC"
	@echo ""
	@echo "Validation :"
	@echo "  make test               Valider scripts et config"

# --- Déploiement ---
deploy-wifi:
	@test -f .env || (echo "Erreur: .env introuvable. Copier .env.example vers .env" && exit 1)
	@test -n "$(HC_URL_WIFI)" || (echo "Erreur: HC_URL_WIFI non défini dans .env" && exit 1)
	scp scripts/setup-pi.sh $(PI_USER)@$(HOST_WIFI):/tmp/
	ssh $(PI_USER)@$(HOST_WIFI) "sudo bash /tmp/setup-pi.sh wifi '$(HC_URL_WIFI)'"

deploy-elec:
	@test -f .env || (echo "Erreur: .env introuvable. Copier .env.example vers .env" && exit 1)
	@test -n "$(HC_URL_ELEC)" || (echo "Erreur: HC_URL_ELEC non défini dans .env" && exit 1)
	scp scripts/setup-pi.sh $(PI_USER)@$(HOST_ELEC):/tmp/
	ssh $(PI_USER)@$(HOST_ELEC) "sudo bash /tmp/setup-pi.sh elec '$(HC_URL_ELEC)'"

# --- État ---
check-wifi:
	@echo "=== Pi-WIFI Status ==="
	ssh $(PI_USER)@$(HOST_WIFI) "\
		echo '-- Hostname --' && hostname && \
		echo '-- Uptime --' && uptime && \
		echo '-- Heartbeat Timer --' && systemctl status heartbeat.timer --no-pager && \
		echo '-- Last Heartbeat --' && journalctl -u heartbeat.service -n 3 --no-pager"

check-elec:
	@echo "=== Pi-ELEC Status ==="
	ssh $(PI_USER)@$(HOST_ELEC) "\
		echo '-- Hostname --' && hostname && \
		echo '-- Uptime --' && uptime && \
		echo '-- Heartbeat Timer --' && systemctl status heartbeat.timer --no-pager && \
		echo '-- Last Heartbeat --' && journalctl -u heartbeat.service -n 3 --no-pager"

# --- SSH ---
ssh-wifi:
	ssh $(PI_USER)@$(HOST_WIFI)

ssh-elec:
	ssh $(PI_USER)@$(HOST_ELEC)

# --- Maintenance ---
reboot-wifi:
	ssh $(PI_USER)@$(HOST_WIFI) "sudo reboot"

reboot-elec:
	ssh $(PI_USER)@$(HOST_ELEC) "sudo reboot"

# --- WiFi Update ---
update-wifi-wifi:
	scp scripts/update-wifi.sh $(PI_USER)@$(HOST_WIFI):/tmp/
	ssh -t $(PI_USER)@$(HOST_WIFI) "sudo bash /tmp/update-wifi.sh"

update-wifi-elec:
	scp scripts/update-wifi.sh $(PI_USER)@$(HOST_ELEC):/tmp/
	ssh -t $(PI_USER)@$(HOST_ELEC) "sudo bash /tmp/update-wifi.sh"

# --- Validation ---
test:
	@echo "=== Validation de la configuration ==="
	@echo "Vérification .env.example..."
	@test -f .env.example && echo "  .env.example: OK" || echo "  .env.example: MANQUANT"
	@echo "Vérification des scripts..."
	@bash -n scripts/setup-pi.sh && echo "  setup-pi.sh: syntaxe OK" || echo "  setup-pi.sh: ERREUR SYNTAXE"
	@bash -n scripts/update-wifi.sh && echo "  update-wifi.sh: syntaxe OK" || echo "  update-wifi.sh: ERREUR SYNTAXE"
	@echo "Vérification .env..."
	@if [ -f .env ]; then \
		. ./.env && \
		(test -n "$$HC_URL_WIFI" && echo "  HC_URL_WIFI: défini" || echo "  HC_URL_WIFI: NON DÉFINI") && \
		(test -n "$$HC_URL_ELEC" && echo "  HC_URL_ELEC: défini" || echo "  HC_URL_ELEC: NON DÉFINI"); \
	else \
		echo "  .env: INTROUVABLE (copier .env.example vers .env)"; \
	fi
	@echo "=== Terminé ==="
