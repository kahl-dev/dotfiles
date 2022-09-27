# linux only
if ! _is_raspberry; then
  if _is_linux; then
    ## Setup linux brew
    export LINUXBREWHOME=$HOME/.linuxbrew
    export PATH=$LINUXBREWHOME/bin:$LINUXBREWHOME/sbin:$PATH
    export MANPATH=$LINUXBREWHOME/share/man:$MANPATH
    export PKG_CONFIG_PATH=$LINUXBREWHOME/lib64/pkgconfig:$LINUXBREWHOME/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=$LINUXBREWHOME/lib64:$LINUXBREWHOME/lib:$LD_LIBRARY_PATH
  fi


  # https://docs.brew.sh/Shell-Completion
  # Brew auto completion
  if _is_osx; then
    export PATH="$(brew --prefix)/opt/python3@/bin:$PATH"
    export LDFLAGS="-L$(brew --prefix)/opt/python3@/lib"
    export PKG_CONFIG_PATH="$(brew --prefix)/opt/python3@/lib/pkgconfig"

  fi

  if type brew &>/dev/null
  then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  fi

fi
