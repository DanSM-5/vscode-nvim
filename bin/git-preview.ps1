#!/usr/bin/env pwsh

if (-not (git rev-parse HEAD 2> $null)) { exit }

if (Get-Command delta -ErrorAction SilentlyContinue) {
  $pager = 'delta --paging=always'
  $preview_pager = '| delta'
} else {
  $pager = 'less -R'
  $preview_pager = ''
}

if (Get-Command -Name pwsh -All) {
  $shell_cmd = 'pwsh.exe'
} else {
  $shell_cmd = 'powershell.exe'
}

$preview = "
  `$sha = {2}
  if (`$sha) {
    git show --color=always `$sha $preview_pager |
      bat -p --color=always
  } else {
    `$root = git rev-parse --show-toplevel 2> `$null
    if (-not `$root) { `$root = git rev-parse --absolute-git-dir 2> `$null }
    `$branch = git symbolic-ref --quiet --short HEAD 2> `$null
    `$head = git rev-parse --short HEAD 2> `$null
    `$upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2> `$null

    Write-Output ('Repository: ' + `$root)
    if (`$branch) {
      Write-Output ('HEAD:       ' + `$branch + ' (' + `$head + ')')
    } else {
      Write-Output ('HEAD:       detached at ' + `$head)
    }
    if (`$upstream) { Write-Output ('Upstream:   ' + `$upstream) }

    [string[]]`$remotes = @(git remote -v)
    if (`$remotes.Count -gt 0) {
      Write-Output ''
      Write-Output 'Remotes:'
      `$remotes
    } else {
      Write-Output ''
      Write-Output 'Remotes:    (none)'
    }

    Write-Output ''
    Write-Output 'Last commit:'
    git log -1 --color=always --date=relative '--format=%C(auto)%h%d %s%nAuthor: %an <%ae>%nDate:   %ad'
  }
"
$show_action = "`$shas = @(Write-Output {+2} | Where-Object { `$_ }); if (`$shas) { git show --color=always `$shas | $pager }"
$diff_action = "`$shas = @(Write-Output {+2} | Where-Object { `$_ }); if (`$shas) { git diff --color=always `$shas | $pager }"

# Clipboard command
$copy = 'Get-Content {+f2} | Set-Clipboard'

# $dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
$fzf_history = if ($env:FZF_HIST_DIR) { $env:FZF_HIST_DIR } else { "$HOME/.cache/fzf-history".Replace('\', '/') }

function get_fzf_down_options() {
  $options = @(
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
    '--preview-window', 'right,50%,wrap-word',
    '--with-shell', "$shell_cmd -NoLogo -NonInteractive -NoProfile -Command",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--bind', "enter:execute:$show_action",
    '--bind', "ctrl-d:execute:$diff_action"
  )

  return $options
}

$down_options = get_fzf_down_options
$git_base_cmd = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h'"
$git_current_cmd = "$git_base_cmd $args"
$git_all_cmd = "$git_base_cmd --all $args"

git log --graph --color=always --all `
  --format="%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h" @args |
    fzf @down_options `
      --bind "ctrl-f:reload:$git_current_cmd" `
      --bind "ctrl-a:reload:$git_all_cmd"
