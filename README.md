VSCode-Neovim config
==========

This repository contains a configuration for neovim intended for usage in the [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) extension for VSCode.

## Configuration

To use this configuration properly, please add the following configurations on vscode:

- [settings](https://github.com/DanSM-5/user-scripts/blob/master/vscode/settings.json)
- [keybindings](https://github.com/DanSM-5/user-scripts/blob/master/vscode/keybindings.json)

It will add support for some keymaps to match (n)vim as well as providing the appropriate configuration for vscode.

### Entry point config

The configuration should always be loaded from `init.lua` file in the root of the repository.

This can be set in the configuration using `vscode-neovim.neovimInitVimPaths.[platform]`:

```json
{
  "vscode-neovim.neovimInitVimPaths.linux": "path/to/vscode-nvim/init.lua",
  "vscode-neovim.neovimInitVimPaths.win32": "path/to/vscode-nvim/init.lua",
  "vscode-neovim.neovimInitVimPaths.darwin": "path/to/vscode-nvim/init.lua",
}
```

### Entry point executable

The configuration expects the environment to provide some specific environment variables to detect the platform and
behave appropriately.

You can start neovim by using the provided wrapper scripts:

- `nvimw`: Wrapper for posix shells like bash or zsh.
- `nvimw.ps1`: Wrapper for powershell or pwsh.

This can be configured in the vscode settings using `vscode-neovim.neovimExecutablePaths.[platform]`:

```json
{
  "vscode-neovim.neovimExecutablePaths.linux": "path/to/vscode-nvim/nvimw",
  // vscode will inherit env variables from starting shell in windows. 
  // look at `nvimw.ps1` and set variables as needed
  "vscode-neovim.neovimExecutablePaths.win32": "nvim",
}
```

## Terminal mode

The configuration can also be used as a standalone neovim configuration. By default this configuration expects the use
of the environment variable `NVIM_APPNAME` set to `vscode-nvim`. It also requires some environment variables to be set.

The easiest mode to start neovim with this configuration is to use the provided scripts `nvimw` and `nvimw.ps1` as a
drop-in replacement for neovim command `nvim`.
