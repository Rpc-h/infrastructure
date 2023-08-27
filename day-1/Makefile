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
vault=--vault-password-file ./.vault_pass
tee_log=tee ansible-log-`date +%Y%m%d-%H%M%S`.log
ansible_inventory=-i "./inventories/$(env)/"
ansible_playbook=time ansible-playbook $(ansible_inventory) $(vault) $(debug_playbook) $(skipped_tags) $(specific_tags) $(specific_hosts)

all: help

.PHONY: install
install: ensure-env-variable-is-set $(ansible-playbook-args)
install: ## Install Hoprd on servers
	$(ansible_playbook) ./install.yaml | tee ansible-log-`date +%Y%m%d-%H%M%S`.log

# The ansible .vault_pass can be downloaded from Bitwarden by name `Ansible Vault Pass - Rpch`
.PHONY: decrypt
decrypt: ensure-env-variable-is-set
decrypt: ## Install Hoprd on servers
	for i in {1..9}; do ansible-vault decrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-staging-alpha-0$$i/.env ./files/$(env)/hetzner-staging-alpha-0$$i/.hoprd.id; done
	for i in {10..25}; do ansible-vault decrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-staging-alpha-$$i/.env ./files/$(env)/hetzner-staging-alpha-$$i/.hoprd.id; done

.PHONY: encrypt
encrypt: ensure-env-variable-is-set
encrypt: ## Install Hoprd on servers
	for i in {1..9}; do ansible-vault encrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-staging-alpha-0$$i/.env ./files/$(env)/hetzner-staging-alpha-0$$i/.hoprd.id; done
	for i in {10..25}; do ansible-vault encrypt --vault-password-file .vault_pass ./files/$(env)/hetzner-staging-alpha-$$i/.env ./files/$(env)/hetzner-staging-alpha-$$i/.hoprd.id; done


.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
