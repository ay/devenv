# devenv

devenv is a tiny bash script that lets you quickly bootstrap a local development environment with the latest stable versions of Ruby with [rbenv](https://github.com/sstephenson/rbenv), Node and io.js with [nvm](https://github.com/creationix/nvm), Python with [pyenv](https://github.com/yyuu/pyenv), and Go. Everything is installed **locally** in your home directory.

## Requirements

I've only tested this on recent versions of Ubuntu and OS X Yosemite. You need:

  * Git
  * curl
  * Bash
  * **Ubuntu**:
    * `build-essential` package
    * `libssl-dev` package
  * **OS X**: Command Line Tools (`xcode-select --install`)

## Installation

Before installing, you should read through [install.sh](install.sh). You could either clone this repo and run install.sh from there or just:

```
$ curl https://raw.githubusercontent.com/alexyakoubian/devenv/master/install.sh | bash
```

### Ruby / rbenv

Ruby is installed with rbenv and [ruby-build](https://github.com/sstephenson/ruby-build). rbenv is installed in `~/.rbenv` and the latest stable Ruby under its version directory in `~/.rbenv/versions`. This Ruby install is also set as rbenv's global Ruby version with `rbenv global`. For rbenv to work properly, you need to add these to your shell environment:

```sh
export PATH="$HOME/.rbenv/bin:PATH"
eval "$(rbenv init -)"
```

### Node / io.js / nvm

Node is installed with nvm, which is installed in `~/.nvm`. The latest stable Node is installed under its version directory in `~/.nvm` and made the default Node version with `nvm alias default`. The latest unstable io.js release is also installed and available with `nvm use iojs`. For nvm to work properly you need to load `~/.nvm/nvm.sh` into your shell environment:

```sh
source ~/.nvm/nvm.sh
```

### Python / pyenv

Python is installed with pyenv, which is installed in `~/.pyenv`. The latest stable Python is installed under its version directory in `~/.pyenv/versions`. This Python install is also set as pyenv's global Python version with `pyenv global`. For pyenv to work properly, you need to add these to your shell environment:

```sh
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

### Go

Go is installed from an official [binary tarball](https://code.google.com/p/go/downloads/list?q=OpSys-FreeBSD+OR+OpSys-Linux+OR+OpSys-OSX+Type-Archive) for your system into `~/.local/go`. `~/.go` is also created to use as your GOPATH. For Go to work properly, you need to add these to your shell environment:

```sh
export GOROOT="$HOME/.local/go"
export PATH="$PATH:$GOROOT/bin"
export GOPATH="$HOME/.go"
export PATH="$PATH:$GOPATH/bin"
```
