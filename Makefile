.PHONY: help setup up services-up down clean clobber status logs shell test lint console

help: ## Show this help (the default target)
	@grep -hE '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

# For running the specs and scripts on the host. mise is preferred, rbenv works too; both read .ruby-version (mise via
# mise.toml). bin/setup can't install Ruby itself, as it needs Ruby to run.
setup: services-up ## Install Ruby (with mise or rbenv), gems, config and ../rblib, and start MySQL, to work on the host
	@if command -v mise >/dev/null; then mise trust && mise install && mise exec -- bin/setup; \
	elif command -v rbenv >/dev/null; then rbenv install --skip-existing && rbenv exec ruby bin/setup; \
	else echo "Install mise (https://mise.jdx.dev) or rbenv first" >&2; exit 1; fi

# The stack is defined in .devcontainer/compose.yaml (see "Docker development environment" in AGENTS.md).
# --wait returns once every service passes its healthcheck, so the next command can use them straight away.
# Runs a command in the app container, or in a fresh one if it has stopped
in_app = if [ -n "$$(docker compose ps -q --status running app)" ]; then docker compose exec app $(1); else docker compose run --rm app $(1); fi

up: ## Start MySQL and a Ruby container with the gems installed, once ready (then make shell)
	docker compose up --build --wait -d
services-up: ## Start the test MySQL only, for running specs on the host
	docker compose up --build --wait -d mysql
down: ## Stop and remove the containers, keeping the data
	docker compose down --remove-orphans
# Everything this checkout built, so the next `make up` rebuilds from scratch. The data is kept.
# VS Code's dev container builds its own images on top of compose's. Only this project's containers say which
# they are, so they're noted before `down` removes them.
clean: ## Remove containers, built images (VS Code's too), gems, the rblib clone, tmp and logs, keeping the data
	p=$$(docker compose config | sed -n 's/^name: //p'); \
	vsc=$$(docker ps -a --filter "label=com.docker.compose.project=$$p" --format '{{.Image}}' | grep '^vsc-' | sort -u); \
	docker compose down --remove-orphans --rmi local && \
	docker volume rm --force "$${p}_bundle" "$${p}_rblib" && \
	{ [ -z "$$vsc" ] || docker rmi --force $$vsc; }
	git clean -fdX -- tmp log coverage # gitignored files only, so tracked placeholders stay
# Reaches past this checkout, for after switching branches or changing dependencies. Other projects lose only
# download and build time, as volumes (where their databases live) are never pruned.
clobber: clean ## Also remove the data, then all stopped containers, unused images and build cache machine-wide
	docker compose down --volumes
	@echo "Pruning stopped containers, unused images and build cache from ALL projects (volumes are kept)"
	docker system prune --all --force
status: ## Show each container's health and the host ports it's published on
	@docker compose ps -a --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
logs: ## Follow the logs of every container (or SERVICE=app for one)
	docker compose logs -f $(SERVICE)
shell: ## Open a shell in the app container, or in a fresh one if it has stopped (e.g. after a failed start)
	@$(call in_app,bash)
# The specs recreate their tables before each run, so there's no database to reset first
test: ## Run the specs as CI does, in the app container (ARGS=spec/lib/name_spec.rb:42 to narrow)
	@$(call in_app,bundle exec rspec $(ARGS))
lint: ## Run RuboCop in the app container (ARGS=<paths> to narrow); CI doesn't run it yet
	@$(call in_app,bundle exec rubocop $(ARGS))
console: ## Open IRB with the parser's lib loaded, in the app container
	@$(call in_app,script/console)
