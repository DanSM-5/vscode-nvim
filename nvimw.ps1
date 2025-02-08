#!/usr/bin/env bash

try {
  # Load config to setup required env variables
  $env:VSCODE_NVIM = 'true'
  $env:NVIM_APPNAME = 'vscode-nvim'

  # Detection
  $env:IS_WSL = 'false'
  $env:IS_WSL1 = 'false'
  $env:IS_WSL2 = 'false'
  $env:IS_TERMUX = 'false'
  $env:IS_LINUX = 'false'
  $env:IS_MAC = 'false'
  $env:IS_WINDOWS = 'false' # Like IS_WINSHELL but includes WSL
  $env:IS_GITBASH = 'false'
  $env:IS_WINSHELL = 'false' # PWSH, GITBASH or CMD
  $env:IS_CMD = 'false' # Should never be true
  $env:IS_ZSH = 'false'
  $env:IS_BASH = 'false'
  $env:IS_POWERSHELL = 'false' # Should never be true
  $env:IS_NIXONDROID = if ($env:IS_NIXONDROID) { $env:IS_NIXONDROID } else { 'false' } # Can only be true if set from home-manager
  $env:IS_FROM_CONTAINER = if ($env:IS_FROM_CONTAINER) { $env:IS_NIXONDROID } else { 'false' } # Can only be true if running inside a container

  if ($IsWindows) {
    $env:IS_WINSHELL = 'true'
    $env:IS_POWERSHELL = 'true'
    $env:IS_WINDOWS = 'true'
  } elseif ($IsLinux) {
    $env:IS_LINUX = 'true'
    $env:IS_POWERSHELL = 'true' # 🤨
    $uname_ret = uname -a
    if ($uname_ret -match '.*WLS2.*') {
      $env:IS_WSL = 'true'
      $env:IS_WSL2 = 'true'
    } elseif ($uname_ret -match '.*[mM]icrosoft.*') {
      $env:IS_WSL = 'true'
      $env:IS_WSL1 = 'true'
    }
  } elseif ($IsMacOS) {
    $env:IS_MAC = 'true'
    $env:IS_POWERSHELL = 'true' # 🤨
  }

  # Launch nvim
  nvim @args
} finally {
  $env:VSCODE_NVIM = $null
  $env:NVIM_APPNAME = $null
}

