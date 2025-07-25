# Variables
SCRIPTS_DIR=./scripts
DEFAULT_GOAL := help

help: ## Display this help message
	@echo "-----------------------------------------------------------------"
	@echo "    __         __    __     __             ____        __  _____ __     "
	@echo "   / /______ _/ /_  / /____/ /__ _   __   / __ \____  / /_/ __(_) /__  _____"
	@echo "  / //_/ __ '/ __ \/ // __  / _ \ | / /  / / / / __ \/ __/ /_/ / / _ \/ ___/"
	@echo " / ,< / /_/ / / / / // /_/ /  __/ |/ /  / /_/ / /_/ / /_/ __/ / /  __(__  ) "
	@echo "/_/|_|\__,_/_/ /_/_(_)__,_/\___/|___/  /_____/\____/\__/_/ /_/_/\___/____/  "
	@echo "-----------------------------------------------------------------"
	@printf "\n\033[1;36m%s\033[0m\n" "Installation commands"
	@grep -E '^[a-zA-Z_-]+:.*?## INSTALLATION: .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## INSTALLATION: "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf "\n\033[1;36m%s\033[0m\n" "Maintenance commands"
	@grep -E '^[a-zA-Z_-]+:.*?## MAINTENANCE: .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## MAINTENANCE: "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf "\n\033[1;36m%s\033[0m\n" "Debug commands"
	@grep -E '^[a-zA-Z_-]+:.*?## DEBUG: .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## DEBUG: "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf "\n\033[1;36m%s\033[0m\n" "Cleanup commands"
	@grep -E '^[a-zA-Z_-]+:.*?## CLEANUP: .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## CLEANUP: "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Installation commands

installBrew: ## INSTALLATION: Install brew
	@$(SCRIPTS_DIR)/installBrew.sh
	@make updateShell

installBrewOsxPackages: ## INSTALLATION: Install osx brew packages
	@/usr/local/bin/brew bundle -v --no-upgrade --file "$(DOTFILES)/brew/Osxbrew"

installBrewBasePackages: ## INSTALLATION: Install base brew packages
	@/usr/local/bin/brew bundle -v --no-upgrade --file "$(DOTFILES)/brew/Basebrew"

setupOsx: ## INSTALLATION: Setup Mac OSX
	@$(SCRIPTS_DIR)/osx.sh

install: ## INSTALLATION: Install all Dotfiles
	@make createSymlinks
	@make installBrew
	@make createSymlinks
	@make installStarship
	@make installAdditionalShellScripts
	@make startServices

installAdditionalShellScripts: ## INSTALLATION: Innstall additional shell scripts
	@$(SCRIPTS_DIR)/installAdditionalShellScripts.sh

updateShell: ## MAINTENANCE: Update shell
	source ~/.zshrc

# Remote Bridge commands

installRemoteBridge: ## INSTALLATION: Install Remote Bridge service
	@echo "Installing Remote Bridge..."
	@cd remote-bridge && pnpm install --silent
	@./remote-bridge/bin/remote-bridge install
	@echo "Remote Bridge installed. Run 'make startRemoteBridge' to activate."

startRemoteBridge: ## MAINTENANCE: Start Remote Bridge service
	@./remote-bridge/bin/remote-bridge start

stopRemoteBridge: ## MAINTENANCE: Stop Remote Bridge service
	@./remote-bridge/bin/remote-bridge stop

restartRemoteBridge: ## MAINTENANCE: Restart Remote Bridge service
	@./remote-bridge/bin/remote-bridge restart

statusRemoteBridge: ## MAINTENANCE: Check Remote Bridge status
	@./remote-bridge/bin/remote-bridge status

logsRemoteBridge: ## DEBUG: View Remote Bridge logs
	@./remote-bridge/bin/remote-bridge logs

# Cleanup commands

nvimResetPackages: ## CLEANUP: Reset lazy.nvim packages
	@rm -Rf ~/.local/share/nvim/lazy
	@rm -Rf ~/.local/state/nvim/lazy
	@rm -Rf ~/.cache/nvim

uninstall: ## CLEANUP: Remove all created folder and symlinks
	@make stopServices
	@$(SCRIPTS_DIR)/uninstall.sh
	

