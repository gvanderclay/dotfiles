#!/usr/bin/env bash
git clone --bare git@github.com:gvanderclay/dotfiles.git "$HOME"/.dotfiles
# define config alias locally since the dotfiles
# aren't installed on the system yet
function config {
    git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME" "$@"
}

backup_dir="$HOME/.dotfiles-backup"
# create a directory to backup existing dotfiles to
mkdir -p "$backup_dir"
config checkout
if config checkout; then
    echo "Checked out dotfiles from git@github.com:gvanderclay/dotfiles.git"
else
    echo "Moving existing dotfiles to $backup_dir"
    config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} "$backup_dir"/{}
fi
# checkout dotfiles from repo
config checkout
config config status.showUntrackedFiles no
