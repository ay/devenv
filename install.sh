#!/usr/bin/env bash

ruby_version="2.2.3"
node_version="4.2.1"
python_version="2.7.10"
go_version="1.5.1"

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

green () { printf "\033[32m$1\033[0m\n"; }
yellow () { printf "\033[33m$1\033[0m\n"; }
red () { printf "\033[31m$1\033[0m\n"; }

ask () {
    local question="$1" default_y="$2" yn
    if [ -z "$default_y" ]; then
        read -p "$question [y/N]? "
    else
        read -p "$question [Y/n]? "
    fi
    yn=$(echo "$REPLY" | tr "A-Z" "a-z")
    if [ -z "$default_y" ]; then
        test "$yn" == "y" -o "$yn" == 'yes'
    else
        test "$yn" != 'n' -a "$yn" != 'no'
    fi
}

# Install rbenv and Ruby
if [ ! -e "$HOME/.rbenv" ]; then
    if ask "Install rbenv and Ruby" "Y"; then
        yellow "==> Installing rbenv into ~/.rbenv"
        git clone https://github.com/sstephenson/rbenv.git "$HOME/.rbenv"
        git clone https://github.com/sstephenson/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        yellow "==> Compiling and installing Ruby v$ruby_version"
        rbenv install $ruby_version
        rbenv global $ruby_version
        rbenv_installed=true
    fi
else
    yellow "==> ~/.rbenv already exists"
fi

# Install nvm and Node
if [ ! -e "$HOME/.nvm" ]; then
    if ask "Install nvm and Node?" "Y"; then
        yellow "==> Installing nvm into ~/.nvm"
        git clone https://github.com/creationix/nvm.git "$HOME/.nvm"
        source "$HOME/.nvm/nvm.sh"
        yellow "==> Installing Node v$node_version"
        nvm install $node_version
        nvm alias default $node_version
        nvm_installed=true
    fi
else
    yellow "==> ~/.nvm already exists"
fi

# Install pyenv and Python
if [ ! -e "$HOME/.pyenv" ]; then
    if ask "Install pyenv and Python" "Y"; then
        yellow "==> Installing pyenv into ~/.pyenv"
        git clone git://github.com/yyuu/pyenv.git "$HOME/.pyenv"
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        yellow "==> Installing Python v$python_version"

        pyenv install $python_version

        pyenv global $python_version
        pyenv rehash
        yellow "==> Installing virtualenv"
        $HOME/.pyenv/shims/pip install virtualenv
        yellow "==> Installing virtualenvwrapper"
        $HOME/.pyenv/shims/pip install virtualenvwrapper
        pyenv_installed=true
    fi
else
    yellow "==> ~/.pyenv already exists"
fi

# Install Go
if [ ! -e "$HOME/.local/go" ]; then
    if ask "Install Go to ~/.local/go" "Y"; then
        yellow "==> Installing Go v$go_version to ~/.local/go"

        # Determine binary tarball filename
        if [ "$(uname -m)" = "x86_64" ]; then
            arch="amd64"
        else
            arch="386"
        fi
        tarball="go${go_version}.${platform}-${arch}.tar.gz"

        # Download URL
        download="https://storage.googleapis.com/golang/$tarball"

        # Attempt to download and untar
        yellow "==> Downloading Go binary tarball from $download"
        curl -L -f -C - --progress-bar "$download" -o "/tmp/$tarball"
        if [ $? -eq 0 ]; then
            yellow "==> Untarring $tarball to ~/.local/go"
            mkdir -p "$HOME/.local/go"
            tar zxf "/tmp/$tarball" --strip-components 1 -C "$HOME/.local/go"
            rm "/tmp/$tarball"
            yellow "==> Creating ~/.go to use as GOPATH"
            mkdir -p $HOME/.go
            go_installed=true
        else
            red "==> Go binary tarball download failed"
        fi
    fi
else
    yellow "==> ~/.local/go already exists"
fi

if [ "$rbenv_installed" = true ]; then
    green "
Ruby v$ruby_version is now installed with rbenv in ~/.rbenv. You should add
these to your shell environment:

    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    "
fi

if [ "$nvm_installed" = true ]; then
    green "
Node v$node_version is now installed with nvm in ~/.nvm. You should add these
to your shell environment:

    source ~/.nvm/nvm.sh
    "
fi

if [ "$pyenv_installed" = true ]; then
    green "
Python v$python_version is now installed with pyenv in ~/.pyenv. You should add
these to your shell environment:

    export PYENV_ROOT=\"\$HOME/.pyenv\"
    export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
    eval \"\$(pyenv init -)\"
    "
fi

if [ "$go_installed" = true ]; then
    green "
Go v$go_version is now installed in ~/.local/go. ~/.go was also created to use
as your GOPATH. You should add these to your shell environment:

    export GOROOT=\"\$HOME/.local/go\"
    export PATH=\"\$PATH:\$GOROOT/bin\"
    export GOPATH=\"\$HOME/.go\"
    export PATH=\"\$PATH:\$GOPATH/bin\"
    "
fi
