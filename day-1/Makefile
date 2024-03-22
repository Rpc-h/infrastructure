.POSIX:

.PHONY: ensure-env-variable-is-set
ensure-env-variable-is-set:
ifeq ($(env),)
	echo "Parameter <env> is missing" >&2 && exit 1
endif

.PHONY: ansible-playbook-args
ansible-playbook-args=
ifeq ($(debug),true)
	debug_playbook=-vvvv
endif
ifneq ($(skip),)
	skipped_tags=--skip-tags=$(skip)
endif
ifneq ($(tags),)
	specific_tags=--tags $(tags)
endif
ifneq ($(limit),)
	specific_hosts=--limit $(limit)
endif
ifneq ($(private_key),)
	private_key_override=--private-key $(private_key)
endif
vault=--vault-password-file ./.vault_pass
tee_log=tee ansible-log-`date +%Y%m%d-%H%M%S`.log
ansible_inventory=-i "./inventories/$(env)/"
ansible_playbook=time ansible-playbook $(ansible_inventory) $(vault) $(debug_playbook) $(skipped_tags) $(specific_tags) $(specific_hosts) $(private_key_override)

all: help

.PHONY: galaxy
galaxy: ## Install ansible dependent roles
	ansible-galaxy install --force -r requirements.yaml

.PHONY: install-server
install-server: ensure-env-variable-is-set $(ansible-playbook-args)
install-server: ## Install servers components
	$(ansible_playbook) ./install-server.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log

.PHONY: install-hoprd
install-hoprd: ensure-env-variable-is-set $(ansible-playbook-args)
install-hoprd: ## Install Hoprd service
	$(ansible_playbook) ./install-hoprd.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log

.PHONY: install-phttp-exit-app
install-phttp-exit-app: ensure-env-variable-is-set $(ansible-playbook-args)
install-phttp-exit-app: ## Install pHTTP exit app service
	$(ansible_playbook) ./install-phttp-exit-app.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log

.PHONY: restart
restart: ensure-env-variable-is-set $(ansible-playbook-args)
restart: ## Restart Hoprd on servers
	$(ansible_playbook) --extra-vars "clean_db=$(clean)" ./restart.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log

.PHONY: show
show: ensure-env-variable-is-set $(ansible-playbook-args)
show: ## Install Hoprd on servers
	$(ansible_playbook) --ask-become-pass ./show.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log


# The ansible .vault_pass can be downloaded from Bitwarden by name `Ansible Vault Pass - Rpch`
.PHONY: decrypt
decrypt: ensure-env-variable-is-set
decrypt: ## Install Hoprd on servers
ifeq ($(env),staging)
	for i in {1..25}; do ansible-vault decrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-$(env)-alpha-$$i/.env-rpch; done
else
	for i in {0..24}; do ansible-vault decrypt --vault-password-file .vault_pass ./files/$(env)/production-$$i/.env-rpch; done
endif

.PHONY: encrypt
encrypt: ensure-env-variable-is-set
encrypt: ## Install Hoprd on servers
ifeq ($(env),staging)
	for i in {1..25}; do ansible-vault encrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-$(env)-alpha-$$i/.env-rpch; done
else
	for i in {0..24}; do ansible-vault encrypt --vault-password-file .vault_pass ./files/$(env)/production-$$i/.env-rpch; done
endif


.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
