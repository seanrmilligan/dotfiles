# Configuring your new computer

Assumption: /repo/ is the folder where you have cloned this repository.

## bash

Steps:
  1. mv /repo/bash/bashrc ~/.bashrc
  2. mv /repo/bash/bash_aliases ~/.bash_aliases

## gpg

Assumption: The public key is named public.key and the private key is named private.key

Steps:
  1. gpg --import public.key
  2. gpg --import private.key

## ssh

Steps:
  1. mkdir -p ~/.ssh
  2. mv /repo/ssh/config ~/.ssh/config

## git

Steps:
  1. sudo apt install git
  2. git config --global user.email "<email>"
  3. git config --global user.name "<name>"
  4. git config --global commit.gpgsign true
  5. git config --global user.signingkey <fingerprint>
  6 .git config --global gpg.program /usr/bin/gpg2

Note: Set up gpg before committing anything