# Setting up

## The One-liner
```
git clone git@github.com:seanrmilligan/dotfiles $HOME/dotfiles && bash $HOME/dotfiles/install.sh
```

## GNU Stow
GNU Stow is a symlink manager used to centrally locate files in a filesystem
while making them appear to be spread throughout the filesystem.

While there are other uses, I use it here to keep dotfiles in a git repo for
version control while creating symlinks across the filesystem to where the
various apps I use expect to find their config files.

### Installing
```
sudo apt install stow
```

### Using Stow
Stow allows you to name the folders for each app whatever you like. The name
you give the folder is then used to link (stow) or unlink (unstow) everything
under that directory all at once.

Assume the following dotfiles managed by stow in our dotfiles git repo:
```
  ~/
  |
  + -- dotfiles/
       |
       + -- bash/
       |    |
       |    + -- .bashrc
       |    + -- .bash_aliases
       |
       + -- vim/
            |
            + -- .vim/
                 |
                 + -- .vimrc
```

Setting up the symlinks is as simple as telling stow the folder names:
```
stow bash vim
```

### Migrating existing dotfiles
Moving existing dotfiles to be managed by stow works as follows:

  1. Make a directory in stow for the app you want to manage.
     ```
     mkdir ~/vim
     ```
  2. Move the dotfile to the dotfiles repo:
     ```
     mv ~/.vim ~/dotfiles/vim/.vim
     ```
  3. Link the migrated dotfiles back to where the app expects to find them
     ```
     cd ~/dotfiles && stow vim
     ```
You should now have a symlink `~/.vim` -> `~/dotfiles/vim/.vim`
