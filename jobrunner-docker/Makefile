# user to ensure that ssh access is set up to the host
export DOCKER_USER ?= $(USER)
export DOCKER_ADDR ?= $(shell docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')

SSH_KEY=ssh/id_ed25519
SSH_PUBKEY=$(SSH_KEY).pub
SSH_COMMENT=local jobrunner dev key

# create known_hosts file so ssh works without prompting
ssh/known_hosts:
	ssh-keyscan $(DOCKER_ADDR) > ssh/known_hosts


# create a local dev key with no password to use for ssh access
$(SSH_KEY):
	ssh-keygen -t ed25519 -N '' -C "$(SSH_COMMENT)" -f $@


# ensure the local dev key is allowed to ssh in as current user
$(SSH_KEY).authorized: $(SSH_KEY) ssh/known_hosts
	grep -q "$(shell cat $(SSH_PUBKEY))" ~/.ssh/authorized_keys || cat $(SSH_PUBKEY) >> ~/.ssh/authorized_keys
	# quick test to fail early if ssh doesn't work for some reason
	ssh -i $(SSH_KEY) -o UserKnownHostsFile=ssh/known_hosts $(DOCKER_USER)@$(DOCKER_ADDR) true || { echo "Failed to ssh into $(DOCKER_ADDR)"; tail /var/log/auth.log; exit 1; }
	touch $@
