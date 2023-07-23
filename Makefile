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

createSymlinks: ## INSTALLATION: Create symlinks
	@$(SCRIPTS_DIR)/createSymlinks.sh

installBrew: ## INSTALLATION: Install brew
	@$(SCRIPTS_DIR)/installBrew.sh

installBrewOsxPackages: ## INSTALLATION: Install osx brew packages
	@/usr/local/bin/brew bundle -v --no-upgrade --file "$(DOTFILES)/brew/Osxbrew"

installBrewBasePackages: ## INSTALLATION: Install base brew packages
	@/usr/local/bin/brew bundle -v --no-upgrade --file "$(DOTFILES)/brew/Basebrew"

installStarship: ## INSTALLATION: Install starship
	@$(SCRIPTS_DIR)/installStarship.sh

setupOsx: ## INSTALLATION: Setup Mac OSX
	@$(SCRIPTS_DIR)/osx.sh

install: ## INSTALLATION: Install all Dotfiles
	@make createSymlinks
	@make installBrew
	@make createSymlinks
	@make installStarship
	@make startServices

installPi: ## INSTALLATION: Install all Dotfiles
	@make createSymlinks
	@make installStarship

# Maintenance commands

update: ## MAINTENANCE: Run updates
	@$(SCRIPTS_DIR)/updates.sh

updateAll: ## MAINTENANCE: Update all 
	@$(SCRIPTS_DIR)/updates.sh --yes

startServices: ## MAINTENANCE: Start services
	@$(SCRIPTS_DIR)/startServices.sh

stopServices: ## MAINTENANCE: Stop services
	@$(SCRIPTS_DIR)/startServices.sh

# Debug commands

colorTest: ## DEBUG: Show color test
	@$(SCRIPTS_DIR)/colorTest.sh

logNcListener: ## DEBUG: Log nc listener
	@tail -f ~/Library/Logs/com.kahl_dev.nc_listener

# Cleanup commands

nvimResetPackages: ## CLEANUP: Reset lazy.nvim packages
	@rm -Rf ~/.local/share/nvim/lazy
	@rm -Rf ~/.local/state/nvim/lazy

uninstall: ## CLEANUP: Remove all created folder and symlinks
	@make stopServices
	@$(SCRIPTS_DIR)/uninstall.sh
	

