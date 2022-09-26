.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:\s?##1\s.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "JS Devs:"
	@grep -E '^[a-zA-Z0-9_-]+:\s?##2\s.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##2 "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Defaults:"
	@grep -E '^[a-zA-Z0-9_-]+:\s?##3\s.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##3 "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


createSymlinks: ##1 create symlinks
	./scripts/createSymlinks.sh

installBrew: ##1 install brew
	./scripts/installBrew.sh

install:
	@make createSymlinks
	@make installBrew

# FOO ------------------------------------------------------------
