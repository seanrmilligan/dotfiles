# Configuring your new computer

Assumption: /repo/ is the folder where you have cloned this repository.

## bash

Steps:
  1. cp /repo/bash/bashrc ~/.bashrc
  2. cp /repo/bash/bash_aliases ~/.bash_aliases

## gpg

Assumption: The public key is named public.key and the private key is named private.key

Steps:
  1. gpg --import public.key
  2. gpg --import private.key
  3. gpg --list-keys --fingerprint

## ssh

Steps:
  1. mkdir -p ~/.ssh
  2. cp /repo/ssh/config ~/.ssh/config

## git

Steps:
  1. sudo apt install git
  2. git config --global user.email "user@email.com"
  3. git config --global user.name "John Doe"
  4. git config --global commit.gpgsign true
  5. git config --global user.signingkey [fingerprint]
  6. git config --global gpg.program /usr/bin/gpg2
  7. git config --global push.default simple

Note: Set up gpg before committing anything

## misc

```
wget -q -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

sudo add-apt-repository ppa:snaipewastaken/ppa
sudo add-apt-repository ppa:gnome-terminator

sudo apt update
sudo apt upgrade
sudo apt install criterion-dev terminator gcc clang make gdb cgdb valgrind git sublime-text google-chrome-stable curl vim

```