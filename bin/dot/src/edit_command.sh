# Check if the DOTFILES variable is set
if [ -z "$DOTFILES" ]; then
	echo "The DOTFILES variable is not set."
	exit 1
fi

# Check if the EDITOR variable is set
if [ -z "$EDITOR" ]; then
	echo "The EDITOR variable is not set. Defaulting to vim."
	EDITOR="vim" # Default to vim if EDITOR is not set
fi

# Use the editor specified in the EDITOR variable to open the path in DOTFILES
$EDITOR "$DOTFILES"
