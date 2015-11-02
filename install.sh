#!/usr/bin/env bash

: ${RUBY_VERSION:="2.2.3"}

: ${NODE_VERSION:="4.2.1"}

: ${PYTHON_VERSION:="2.7.10"}

: ${GO_VERSION:="1.5.1"}

: ${JDK_VERSION:="8"}
: ${JDK_UPDATE:="66"}
: ${JDK_BUILD:="17"}

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
        yellow "==> Compiling and installing Ruby $RUBY_VERSION"
        rbenv install "$RUBY_VERSION"
        rbenv global "$RUBY_VERSION"
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
        yellow "==> Installing Node $NODE_VERSION"
        nvm install $NODE_VERSION
        nvm alias default $NODE_VERSION
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
        yellow "==> Installing Python $PYTHON_VERSION"

        pyenv install $PYTHON_VERSION

        pyenv global $PYTHON_VERSION
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
        yellow "==> Installing Go $GO_VERSION to ~/.local/go"

        # Determine binary tarball filename
        if [ "$(uname -m)" = "x86_64" ]; then
            arch="amd64"
        else
            arch="386"
        fi
        tarball="go${GO_VERSION}.${platform}-${arch}.tar.gz"

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

if [ ! -e "$HOME/.local/java" ]; then
    if ask "Install JDK to ~/.local/java" "Y"; then
        if [ "$platform" = "darwin" ]; then
            jdk_dmg="jdk-${JDK_VERSION}u${JDK_UPDATE}-macosx-x64.dmg"
            jdk_ver="${JDK_VERSION}u${JDK_UPDATE}-b${JDK_BUILD}"
            jdk_url="http://download.oracle.com/otn-pub/java/jdk/${jdk_ver}/${jdk_dmg}"
            yellow "==> Installing JDK ${jdk_ver} to ~/.local/java"

            # Work from a temporary directory
            jdk_tmp="$(mktemp -d -t jdk)" && pushd "$jdk_tmp" > /dev/null

            # Download JDK
            curl -#fL \
                 --cookie "oraclelicense=accept-securebackup-cookie" \
                 -o "$jdk_dmg" "$jdk_url"

            # Mount DMG
            hdiutil attach "$jdk_dmg" -mountpoint "mounted_dmg" > /dev/null

            # Expand package
            pkgutil --expand \
                "mounted_dmg/JDK ${JDK_VERSION} Update ${JDK_UPDATE}.pkg" \
                "expanded_pkg"

            # Extract Java home to ~/.local/java
            mkdir -p "$HOME/.local/java"
            tar xf \
                "expanded_pkg/jdk1${JDK_VERSION}0${JDK_UPDATE}.pkg/Payload" \
                -C "$HOME/.local/java" \
                --strip-components 3 \
                "Contents/Home"

            # Unmount DMG
            hdiutil detach "mounted_dmg" > /dev/null

            # Clean up
            popd > /dev/null
            rm -r "$jdk_tmp"

            jdk_installed=true
        fi
    fi
else
    yellow "==> ~/.local/java already exists"
fi

if [ ! -e "$HOME/.lein" ]; then
    if ask "Install Leiningen to ~/.lein (with binary in ~/.local/bin)" "Y"; then
        if [ -d "$HOME/.local/java" ]; then
            export JAVA_HOME="$HOME/.local/java"
            export PATH="$JAVA_HOME:$PATH"
        fi
        mkdir -p "$HOME/.local/bin"
        curl -#fL \
             -o "$HOME/.local/bin/lein" \
             "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
        chmod +x "$HOME/.local/bin/lein"
        "$HOME/.local/bin/lein" > /dev/null
        lein_installed=true
    fi
else
    yellow "==> ~/.lein already exists"
fi

if [ "$rbenv_installed" = true ]; then
    green "
Ruby $RUBY_VERSION is now installed with rbenv in ~/.rbenv. You should add
these to your shell environment:

    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    "
fi

if [ "$nvm_installed" = true ]; then
    green "
Node $NODE_VERSION is now installed with nvm in ~/.nvm. You should add these
to your shell environment:

    source ~/.nvm/nvm.sh
    "
fi

if [ "$pyenv_installed" = true ]; then
    green "
Python $PYTHON_VERSION is now installed with pyenv in ~/.pyenv. You should add
these to your shell environment:

    export PYENV_ROOT=\"\$HOME/.pyenv\"
    export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
    eval \"\$(pyenv init -)\"
    "
fi

if [ "$go_installed" = true ]; then
    green "
Go $GO_VERSION is now installed in ~/.local/go. ~/.go was also created to use
as your GOPATH. You should add these to your shell environment:

    export GOROOT=\"\$HOME/.local/go\"
    export PATH=\"\$PATH:\$GOROOT/bin\"
    export GOPATH=\"\$HOME/.go\"
    export PATH=\"\$PATH:\$GOPATH/bin\"
    "
fi

if [ "$jdk_installed" = true ]; then
    green "
JDK ${JDK_VERSION}u${JDK_UPDATE}-b${JDK_BUILD} is now installed in ~/.local/java.
You should add these to your shell environment:

    export JAVA_HOME=\"\$HOME/.local/java\"
    export PATH=\"\$JAVA_HOME:\$PATH\"
    "
fi

if [ "$lein_installed" = true ]; then
    green "
Leiningen is now installed to ~/.lein with the lein binary at ~/.local/bin/lein.
Make sure you have ~/.local/bin in your PATH:

    export PATH=\"\$PATH:\$HOME/.local/bin\"
    "
fi
