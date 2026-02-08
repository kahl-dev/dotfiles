# 🚀 Bootstrap-only Makefile
# Post-install management is handled by the `dot` CLI.
# This Makefile exists solely for initial setup and teardown.

.DEFAULT_GOAL := help

help: ## Show available targets
	@echo "-----------------------------------------------------------------"
	@echo "    __         __    __     __             ____        __  _____ __     "
	@echo "   / /______ _/ /_  / /____/ /__ _   __   / __ \____  / /_/ __(_) /__  _____"
	@echo "  / //_/ __ '/ __ \/ // __  / _ \ | / /  / / / / __ \/ __/ /_/ / / _ \/ ___/"
	@echo " / ,< / /_/ / / / / // /_/ /  __/ |/ /  / /_/ / /_/ / /_/ __/ / /  __(__  ) "
	@echo "/_/|_|\__,_/_/ /_/_(_)__,_/\___/|___/  /_____/\____/\__/_/ /_/_/\___/____/  "
	@echo "-----------------------------------------------------------------"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install all dotfiles via dotbot
	@./install-profile macos

uninstall: ## Remove all symlinks and configurations
	@./scripts/uninstall.sh
