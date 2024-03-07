yes=${args[--yes]}

cd $DOTFILES

if [[ $yes == 1 ]]; then
	all_yes=1
fi

if _exec_exists nvim; then
	if [[ $all_yes == 1 ]] || (read -p "Do you want to update LazyVim? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
		printf "${COLOR_CYAN}Update LazyVim${COLOR_OFF}\n"
		nvim --headless '+Lazy! sync' +qa
	fi

	printf "${COLOR_CYAN}Please also update Mason LSPs manualy${COLOR_OFF}\n"
fi

if _exec_exists brew; then
	if [[ $all_yes == 1 ]] || (read -p "Do you want to update Homebrew packages? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
		printf "${COLOR_CYAN}Update Homebrew packages${COLOR_OFF}\n"
		brew update
		brew upgrade
		brew cleanup -s
		#now diagnotic
		# brew doctor
		# brew missing
	fi
fi

if _is_osx; then
	if [[ $all_yes == 1 ]] || (read -p "Do you want to update App Store packages with mas? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
		printf "${COLOR_CYAN}Update App Store packages with mas${COLOR_OFF}\n"
		mas upgrade
	fi

	if [[ $all_yes == 1 ]] || (read -p "Do you want to update the System? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
		printf "${COLOR_CYAN}Update System${COLOR_OFF}\n"
		softwareupdate -i -a
	fi
fi

printf "${COLOR_CYAN}node and npm packages has to be updated manually${COLOR_OFF}\n"
