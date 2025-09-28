#!/usr/bin/env pwsh

if (-not (git rev-parse HEAD 2> $null)) { exit }

if (Get-Command delta -ErrorAction SilentlyContinue) {
  $pager = '| delta --paging=always'
  $preview_pager = ' | delta'
} else {
  $pager = '| less -R'
  $preview_pager = ''
}

if (Get-Command -Name pwsh -All) {
  $shell_cmd = 'pwsh.exe'
  $is_pwsh = $true
} else {
  $shell_cmd = 'powershell.exe'
  $is_pwsh = $false
}



$preview = "
  `$var = @'
{}
'@
  `$var = `$var.Trim().Trim(`"'`").Trim('`"')
  `$hash = if (`$var -match `"[a-f0-9]{7,}`") {
    `$matches[0]
  } else { @() }
  git show --color=always `$hash $preview_pager |
    bat -p --color=always
"

# When calling this from pwsh (powershell 7),
# the script will inherit the PSModulePath environment variable
# which causes New-TemporaryFile to fail.
# This script is intended to run with Windows Powershell so
# the alternative is to call the windows API directly.
try {
  # Ensure that New-Temporaryfile is available
  Import-Module Microsoft.PowerShell.Utility
  $content_file = New-Temporaryfile
}
catch {
  $content_file = Get-Item ([System.IO.Path]::GetTempFilename())
}

# Clipboard command
$copy = 'Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[1] } | Set-Clipboard'

$out = ''
$shas = @()
$q = ''
$k = ''

# $dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
$fzf_history = if ($env:FZF_HIST_DIR) { $env:FZF_HIST_DIR } else { "$HOME/.cache/fzf_history".Replace('\', '/') }

function get_fzf_down_options() {
  $options = @(
    '--query=',
    '--height', '100%',
    '--min-height', '20',
    '--input-border',
    '--cycle',
    '--layout=reverse',
    '--multi',
    '--border',
    '--bind', 'alt-f:first',
    '--bind', 'alt-l:last',
    '--bind', 'alt-c:clear-query',
    '--bind', 'alt-a:select-all',
    '--bind', 'alt-d:deselect-all',
    '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
    '--bind', 'ctrl-^:toggle-preview',
    '--bind', "ctrl-y:execute-silent($copy)+bell",
    '--bind', 'alt-up:preview-page-up',
    '--bind', 'alt-down:preview-page-down',
    '--bind', 'ctrl-s:toggle-sort',
    "--history=$fzf_history/fzf-git_show",
    '--header', 'ctrl-d: Diff | ctrl-a: All | ctrl-f: HEAD | ctrl-y: Copy',
    '--prompt', 'Commits> ',
    '--preview', $preview,
    '--preview-window', 'right,50%,wrap',
    '--with-shell', "$shell_cmd -NoLogo -NonInteractive -NoProfile -Command",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--print-query',
    '--expect=ctrl-d'
  )

  return $options
}

$down_options = get_fzf_down_options
$git_base_cmd = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr'"
$git_current_cmd = "$git_base_cmd $args"
$git_all_cmd = "$git_base_cmd --all $args"

try {
  while ($true) {
    $out = git log --graph --color=always --all `
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
    fzf @down_options `
      --bind "ctrl-f:reload:$git_current_cmd" `
      --bind "ctrl-a:reload:$git_all_cmd"

    if (-not $out) { break; }

    $out > $content_file.FullName
    $q = Get-Content $content_file.FullName | Select-Object -Index 0
    $k = Get-Content $content_file.FullName | Select-Object -Index 1
    $shas = Get-Content $content_file.FullName | Select-Object -Skip 2 | ForEach-Object {
      if ($_ -match "[a-f0-9]{7,}") {
        return $matches[0]
      }
    }

    if (-not $shas) { continue; }
    if ($q) { $down_options[0] = "--query=$q" }
    # NOTE: Using windows powershell causes some issues. We will detect here if pwsh is present
    # and use it over windows powershell.
    if ($k -eq 'ctrl-d') {
      if ($is_pwsh) {
        pwsh -NoLogo -NonInteractive -NoProfile -Command "git diff --color=always $shas $pager"
      } else {
        powershell -NoLogo -NonInteractive -NoProfile -Command "git diff --color=always -- $shas $pager"
      }
    } else {
      foreach ($sha in $shas) {
        if ($is_pwsh) {
          pwsh -NoLogo -NonInteractive -NoProfile -Command "git show --color=always $sha $pager"
        } else {
          powershell -NoLogo -NonInteractive -NoProfile -Command "git show --color=always -- $sha $pager"
        }
      }
    }
  }
} finally {
  if (Test-Path -Path $content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
    Remove-Item -Force $content_file.FullName
  }
}

