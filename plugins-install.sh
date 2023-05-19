#!/usr/bin/env bash

if ! [ -d ~/.config/vscode-nvim/plugins ]; then
  mkdir -p ~/.config/vscode-nvim/plugins
fi

# Vim repeat
if ! [ -d ~/.config/vscode-nvim/plugins/vim-repeat ]; then
  git clone https://github.com/tpope/vim-repeat ~/.config/vscode-nvim/plugins/vim-repeat
fi

