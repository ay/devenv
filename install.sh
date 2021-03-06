#!/usr/bin/env bash

: ${INSTALL_DIR:="${HOME}/.local"}

: ${RUBY_VERSION:="2.6.3"}

: ${NODE_VERSION:="12.7.0"}

: ${PYTHON_VERSION:="3.7.4"}

: ${GO_VERSION:="1.12.7"}

: ${JDK_VERSION:="12.0.2"}
: ${JDK_BUILD:="10"}
: ${JDK_BUILDHASH:="e482c34c86bd4bf8b56c0b35558996b9"}
: ${JDK_DIGEST:="82fdf9f2cd4e5b1ed538dfb1c0169e4e1018494105d950cb8330417076922496"}

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

green () { printf "\033[32m$1\033[0m\n"; }
yellow () { printf "\033[33m$1\033[0m\n"; }
red () { printf "\033[31m$1\033[0m\n"; }

ask () {
    local question="$1" default_y="$2" yn
    if [ -z "$default_y" ]; then
        read -p "${question} [y/N]? "
    else
        read -p "${question} [Y/n]? "
    fi
    yn=$(echo "$REPLY" | tr "A-Z" "a-z")
    if [ -z "$default_y" ]; then
        test "$yn" == "y" -o "$yn" == 'yes'
    else
        test "$yn" != 'n' -a "$yn" != 'no'
    fi
}

verify_digest () {
    local filename="$1" digest="$2"
    local expected="$(openssl dgst -sha256 "$1" | cut -d " " -f 2)"
    [ "$expected" = "$digest" ]
}

# Install rbenv and Ruby
if [ ! -e "${HOME}/.rbenv" ]; then
    if ask "Install rbenv and Ruby to ~/.rbenv" "Y"; then
        yellow "==> Installing rbenv into ~/.rbenv"
        git clone https://github.com/rbenv/rbenv.git "${HOME}/.rbenv"
        git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"
        export PATH="${HOME}/.rbenv/bin:${PATH}"
        eval "$(rbenv init -)"
        yellow "==> Compiling and installing Ruby ${RUBY_VERSION}"
        rbenv install "$RUBY_VERSION"
        rbenv global "$RUBY_VERSION"
        rbenv_installed=true
    fi
else
    yellow "==> ~/.rbenv already exists"
fi

# Install nvm and Node
if [ ! -e "${HOME}/.nvm" ]; then
    if ask "Install nvm and Node to ~/.nvm" "Y"; then
        yellow "==> Installing nvm into ~/.nvm"
        git clone https://github.com/creationix/nvm.git "${HOME}/.nvm"
        source "${HOME}/.nvm/nvm.sh"
        yellow "==> Installing Node ${NODE_VERSION}"
        nvm install "$NODE_VERSION"
        nvm alias default "$NODE_VERSION"
        nvm_installed=true
    fi
else
    yellow "==> ~/.nvm already exists"
fi

# Install pyenv and Python
if [ ! -e "${HOME}/.pyenv" ]; then
    if ask "Install pyenv and Python to ~/.pyenv" "Y"; then
        yellow "==> Installing pyenv into ~/.pyenv"
        git clone https://github.com/pyenv/pyenv.git "${HOME}/.pyenv"
        export PYENV_ROOT="${HOME}/.pyenv"
        export PATH="${PYENV_ROOT}/bin:${PATH}"
        eval "$(pyenv init -)"
        yellow "==> Installing Python ${PYTHON_VERSION}"

        if [ "$platform" = "darwin" ]; then
            CFLAGS="-I$(xcrun --show-sdk-path)/usr/include" pyenv install "$PYTHON_VERSION"
        else
            pyenv install "$PYTHON_VERSION"
        fi

        pyenv global "$PYTHON_VERSION"
        pyenv rehash
        yellow "==> Upgrading pip"
        "${HOME}/.pyenv/shims/pip" install --upgrade pip
        yellow "==> Installing virtualenv"
        "${HOME}/.pyenv/shims/pip" install virtualenv
        yellow "==> Installing virtualenvwrapper"
        "${HOME}/.pyenv/shims/pip" install virtualenvwrapper
        pyenv_installed=true
    fi
else
    yellow "==> ~/.pyenv already exists"
fi

# Install Go
if [ ! -e "${INSTALL_DIR}/go" ]; then
    if ask "Install Go to ${INSTALL_DIR}/go" "Y"; then
        yellow "==> Installing Go ${GO_VERSION} to ${INSTALL_DIR}/go"

        # Determine binary tarball filename
        if [ "$(uname -m)" = "x86_64" ]; then
            arch="amd64"
        else
            arch="386"
        fi
        tarball="go${GO_VERSION}.${platform}-${arch}.tar.gz"

        # Download URL
        download="https://dl.google.com/go/${tarball}"

        # Attempt to download and untar
        yellow "==> Downloading Go binary tarball from ${download}"
        curl -L -f -C - --progress-bar "$download" -o "/tmp/${tarball}"
        if [ $? -eq 0 ]; then
            yellow "==> Untarring ${tarball} to ${INSTALL_DIR}/go"
            mkdir -p "${INSTALL_DIR}/go"
            tar zxf "/tmp/${tarball}" --strip-components 1 -C "${INSTALL_DIR}/go"
            rm "/tmp/${tarball}"
            yellow "==> Creating ~/.go to use as GOPATH"
            mkdir -p "${HOME}/.go"
            go_installed=true
        else
            red "==> Go binary tarball download failed"
        fi
    fi
else
    yellow "==> ${INSTALL_DIR}/go already exists"
fi

# Install Java (JDK)
if [ ! -e "${INSTALL_DIR}/java" ]; then
    if ask "Install JDK to ${INSTALL_DIR}/java" "Y"; then
        if [ "$platform" = "darwin" ]; then
            jdk_tarball="jdk-${JDK_VERSION}_osx-x64_bin.tar.gz"
            jdk_url="http://download.oracle.com/otn-pub/java/jdk/${JDK_VERSION}+${JDK_BUILD}/${JDK_BUILDHASH}/${jdk_tarball}"
            yellow "==> Installing JDK ${JDK_VERSION} build ${JDK_BUILD} to ${INSTALL_DIR}/java"

            # Work from a temporary directory
            jdk_tmp="$(mktemp -d -t jdk)" && pushd "$jdk_tmp" > /dev/null

            # Download JDK
            curl -#fL \
                 --cookie "oraclelicense=accept-securebackup-cookie" \
                 -o "$jdk_tarball" "$jdk_url"

            if verify_digest "$jdk_tarball" "$JDK_DIGEST"; then

                # Extract Java home
                mkdir -p "${INSTALL_DIR}/java"
                tar xf \
                    "$jdk_tarball" \
                    -C "${INSTALL_DIR}/java" \
                    --strip-components 4 \
                    "jdk-${JDK_VERSION}.jdk/Contents/Home"

                jdk_installed=true

            else
                red "==> SHA256 digest for ${jdk_dmg} did not match, aborting"
            fi

            # Clean up
            popd > /dev/null
            rm -r "$jdk_tmp"

            # Set Java's home and add its binaries to PATH
            export JAVA_HOME="${INSTALL_DIR}/java"
            export PATH="${JAVA_HOME}/bin:${PATH}"
        fi
    fi
else
    yellow "==> ${INSTALL_DIR}/java already exists"
fi

# Install Leiningen (for Clojure)
if command -v java > /dev/null; then
    if [ ! -e "${HOME}/.lein" ]; then
        if ask "Install Leiningen to ~/.lein (with binary in ${INSTALL_DIR}/bin)" "Y"; then
            yellow "==> Installing Leiningen to ~/.lein"
            mkdir -p "${INSTALL_DIR}/bin"
            curl -#fL \
                -o "${INSTALL_DIR}/bin/lein" \
                "https://github.com/technomancy/leiningen/raw/stable/bin/lein"
            chmod +x "${INSTALL_DIR}/bin/lein"
            "${INSTALL_DIR}/bin/lein" > /dev/null
            lein_installed=true
        fi
    else
        yellow "==> ~/.lein already exists"
    fi
else
    yellow "==> Java not found, skipping Leiningen installation"
fi

if [ "$rbenv_installed" = true ]; then
    green "
Ruby ${RUBY_VERSION} is now installed with rbenv in ~/.rbenv. You should add
these to your shell environment:

    export PATH=\"\${HOME}/.rbenv/bin:\${PATH}\"
    eval \"\$(rbenv init -)\"
    "
fi

if [ "$nvm_installed" = true ]; then
    green "
Node ${NODE_VERSION} is now installed with nvm in ~/.nvm. You should add these
to your shell environment:

    source \"\${HOME}/.nvm/nvm.sh\"
    "
fi

if [ "$pyenv_installed" = true ]; then
    green "
Python ${PYTHON_VERSION} is now installed with pyenv in ~/.pyenv. You should add
these to your shell environment:

    export PYENV_ROOT=\"\${HOME}/.pyenv\"
    export PATH=\"\${PYENV_ROOT}/bin:\${PATH}\"
    eval \"\$(pyenv init -)\"
    "
fi

if [ "$go_installed" = true ]; then
    green "
Go ${GO_VERSION} is now installed in ${INSTALL_DIR}/go. ~/.go was also created to use
as your GOPATH. You should add these to your shell environment:

    export GOROOT=\"${INSTALL_DIR}/go\"
    export PATH=\"\${PATH}:\${GOROOT}/bin\"
    export GOPATH=\"\${HOME}/.go\"
    export PATH=\"\${PATH}:\${GOPATH}/bin\"
    "
fi

if [ "$jdk_installed" = true ]; then
    green "
JDK ${JDK_VERSION}u${JDK_UPDATE}-b${JDK_BUILD} is now installed in ${INSTALL_DIR}/java.
You should add these to your shell environment:

    export JAVA_HOME=\"${INSTALL_DIR}/java\"
    export PATH=\"\${JAVA_HOME}/bin:\${PATH}\"
    "
fi

if [ "$lein_installed" = true ]; then
    green "
Leiningen is now installed in ~/.lein with the lein binary at ${INSTALL_DIR}/bin/lein.
Make sure you have ${INSTALL_DIR}/bin in your PATH:

    export PATH=\"\${PATH}:${INSTALL_DIR}/bin\"
    "
fi
