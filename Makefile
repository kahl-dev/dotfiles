.DEFAULT_GOAL := help

help: ## Show this help
	@echo
	@grep -E '^[a-zA-Z0-9_-]+:\s?##1\s.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

createSymlinks: ##1 Create symlinks
	./scripts/createSymlinks.sh

installBrew: ##1 Install brew
	./scripts/installBrew.sh

installStarship: ##1 Install starship
	./scripts/installStarship.sh

configurateSsh: ##1 Configurate SSH
	./scripts/configurateSsh.sh

startServices: ##1 Start services
	./scripts/startServices.sh

setupOsx: ##1 Setup Mac OSX
	./scripts/osx.sh

colorTest: ##1 Show color test
	./scripts/colorTest.sh

checkForUpdates: ##1 Check for available updates
	./scripts/checkForUpdates.sh

update: ##1 Update all
	./scripts/updates.sh

uninstall: ##1 Remove all created folder and symlinks
	./scripts/uninstall.sh

install: ##1 Install all Dotfiles
	@make createSymlinks
	@make configurateSsh
	@make installBrew
	@make installStarship
	@make startServices

installPi: ##1 Install all Dotfiles
	@make createSymlinks
	@make configurateSsh
	@make installStarship

nvimResetPackages: ##1 reset lazy.nvim packages
	rm -Rf ~/.local/share/nvim/lazy
	rm -Rf ~/.local/state/nvim/lazy

