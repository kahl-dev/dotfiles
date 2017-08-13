# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ]; then

  plugins+=(linuxbrew)

  # use newer vim instead
  alias vim="${HOME}/.linuxbrew/bin/vim"
fi

