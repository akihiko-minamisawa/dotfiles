#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
SOURCE_DIR="$DOTFILES_DIR/home"

# Create a symlink
create_symlink() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "Backing up: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    echo "Creating symlink: $src -> $dest"
    ln -s "$src" "$dest"
}

# Link files/directories under home/
for item in "$SOURCE_DIR"/.* "$SOURCE_DIR"/*; do
    name="$(basename "$item")"

    # Skip . and ..
    [ "$name" = "." ] || [ "$name" = ".." ] && continue
    # Skip non-existent pattern matches
    [ ! -e "$item" ] && continue

    if [ "$name" = ".config" ]; then
        # Link .config contents individually
        mkdir -p "$HOME_DIR/.config"
        for config_item in "$item"/*; do
            [ ! -e "$config_item" ] && continue
            config_name="$(basename "$config_item")"
            create_symlink "$config_item" "$HOME_DIR/.config/$config_name"
        done
    else
        create_symlink "$item" "$HOME_DIR/$name"
    fi
done

echo "Done"
