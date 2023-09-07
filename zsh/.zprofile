# if [-d "/opt/homebrew/bin/brew" ]; then
#   eval "$(/opt/homebrew/bin/brew shellenv)"
# elif [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
#   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# fi

  # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


# if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
#   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#   export PATH="$(brew --prefix)/opt/python/libexec/bin:${PATH}"
# fi

# if [ -d "/home/.linuxbrew/bin" ]; then
#   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# fi


# Check the operating system
case "$(uname -s)" in
    Darwin) # macOS
        if [ -d "/opt/homebrew/bin" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        ;;

    Linux)
        # Check for various potential Linux paths for Homebrew
        if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            export PATH="$(brew --prefix)/opt/python/libexec/bin:${PATH}"
        elif [ -d "/home/.linuxbrew/bin" ]; then
            eval "$(/home/.linuxbrew/bin/brew shellenv)"
        fi
        ;;

    *) # Default case
        echo "Unsupported OS"
        ;;
esac
