#!/usr/bin/env bash

# fshow - git commit browser (enter for show, ctrl-d for diff, ctrl-s toggles sort)
# git rev-parse HEAD > /dev/null 2>&1 || exit

def_pager="less -R"
pager=""

if command -v delta &>/dev/null; then
  # if set pager is delta
  pager="delta --paging=always"
  preview_pager='| delta'
else
  pager="$def_pager"
  preview_pager=''
fi

preview="
  sha={2}
  if [ -n \"\$sha\" ]; then
    git show --color=always \"\$sha\" $preview_pager |
      bat -p --color=always
  else
    root=\$(git rev-parse --show-toplevel 2>/dev/null || git rev-parse --absolute-git-dir 2>/dev/null)
    branch=\$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
    head=\$(git rev-parse --short HEAD 2>/dev/null)
    upstream=\$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)

    printf 'Repository: %s\\n' \"\$root\"
    if [ -n \"\$branch\" ]; then
      printf 'HEAD:       %s (%s)\\n' \"\$branch\" \"\$head\"
    else
      printf 'HEAD:       detached at %s\\n' \"\$head\"
    fi
    [ -z \"\$upstream\" ] || printf 'Upstream:   %s\\n' \"\$upstream\"

    remotes=\$(git remote -v)
    if [ -n \"\$remotes\" ]; then
      printf '\\nRemotes:\\n%s\\n' \"\$remotes\"
    else
      printf '\\nRemotes:    (none)\\n'
    fi

    printf '\\nLast commit:\\n'
    git log -1 --color=always --date=relative \\
      --format='%C(auto)%h%d %s%nAuthor: %an <%ae>%nDate:   %ad'
  fi
"
action_shas="shas=; for sha in {+2}; do [ -z \"\$sha\" ] || shas=\"\$shas \$sha\"; done; [ -z \"\$shas\" ] ||"
show_action="$action_shas git show --color=always \$shas | $pager"
diff_action="$action_shas git diff --color=always \$shas | $pager"

# Find clipboard utility
copy='true'
# NOTE: Will probably will never run on windows but
# better safe than sorry
if [ "$OS" = 'Windows_NT' ]; then
  # Gitbash
  copy="cat {+f2} | pbcopy.exe"
elif [ "$OSTYPE" = 'darwin' ] || command -v 'pbcopy' &>/dev/null; then
  copy="cat {+f2} | pbcopy"
# Assume linux if above didn't match
elif [ -n "$WAYLAND_DISPLAY" ] && command -v 'wl-copy' &>/dev/null; then
  copy="cat {+f2} | wl-copy --foreground --type text/plain"
elif [ -n "$DISPLAY" ] && command -v 'xsel' &>/dev/null; then
  copy="cat {+f2} | xsel -i -b"
elif [ -n "$DISPLAY" ] && command -v 'xclip' &>/dev/null; then
  copy="cat {+f2} | xclip -i -selection clipboard"
fi

# Setup history
fzf_history="${FZF_HIST_DIR:-$HOME/.cache/fzf-history}"
mkdir -p "$fzf_history"

# Default fzf flags
fzf-down () {
  fzf \
    --height '100%' \
    --min-height 20 \
    --input-border \
    --cycle \
    --layout=reverse \
    --multi \
    --bind 'alt-f:first' \
    --bind 'alt-l:last' \
    --bind 'alt-c:clear-query' \
    --bind 'alt-a:select-all' \
    --bind 'alt-d:deselect-all' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind 'ctrl-^:toggle-preview' \
    --bind "ctrl-y:execute-silent($copy)+bell" \
    --bind 'alt-up:preview-page-up' \
    --bind 'alt-down:preview-page-down' \
    --bind 'ctrl-s:toggle-sort' \
    --header 'ctrl-d: Diff | ctrl-a: All | ctrl-f: HEAD | ctrl-y: Copy' \
    --prompt 'Commits> ' \
    --preview "$preview" \
    --preview-window 'right,50%,wrap-word' \
    --ansi --no-sort --reverse \
    "--history=$fzf_history/fzf-git_show" \
    --border "$@"
}

git_base_cmd="git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h'"
git_current_cmd="$git_base_cmd $*"
git_all_cmd="$git_base_cmd --all $*"

fzf-down \
  --delimiter=$'\t' \
  --with-nth 1 \
  --bind "start:reload:$git_all_cmd" \
  --bind "ctrl-f:reload:$git_current_cmd" \
  --bind "ctrl-a:reload:$git_all_cmd" \
  --bind "enter:execute:$show_action" \
  --bind "ctrl-d:execute:$diff_action"
