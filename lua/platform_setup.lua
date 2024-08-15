if (vim.env.IS_WINSHELL == 'true') then
  -- Windows specific
  -- cmd, powershell, pwsh, git bash, git zsh
  vim.cmd([[
    set shell=cmd
    set shellcmdflag=/c

    " Set system_copy variables
    let g:system_copy#paste_command = 'pbpaste.exe'
    let g:system_copy#copy_command = 'pbcopy.exe'
  ]])
elseif (vim.env.IS_FROM_CONTAINER == 'true') then
  vim.cmd([[
    " Set system_copy variables
    let g:system_copy#paste_command = 'fs-paste'
    let g:system_copy#copy_command = 'fs-copy'
    call clipboard#set(g:system_copy#copy_command, g:system_copy#paste_command)
  ]])
elseif (vim.fn.has('wsl') == 1 and vim.env.IS_WSL1 == 'true') then
  -- Set system_copy variables
  vim.g['system_copy#paste_command'] = 'pbpaste.exe'
  vim.g['system_copy#copy_command'] = 'pbcopy.exe'
elseif ((not vim.fn.empty(vim.env.DISPLAY)) and vim.fn.executable('xsel') == 1) then
  vim.g['system_copy#copy_command'] = 'xsel -i -b'
  vim.g['system_copy#paste_command'] = 'xsel -o -b'
elseif ((not vim.fn.empty(vim.env.DISPLAY)) and vim.fn.executable('xclip') == 1) then
  vim.g['system_copy#copy_command'] = 'xclip -i -selection clipboard'
  vim.g['system_copy#paste_command'] = 'xclip -o -selection clipboard'
elseif (
  (not vim.fn.empty(vim.env.WAYLAND_DISPLAY)) and
  vim.fn.executable('wl-copy') == 1 and
  vim.fn.executable('wl-paste') == 1
) then
  vim.g['system_copy#copy_command'] = 'wl-copy --foreground --type text/plain'
  vim.g['system_copy#paste_command'] = 'wl-paste --no-newline'
elseif (vim.fn.has('mac') == 1) then
  -- Set system_copy variables
  vim.g['system_copy#paste_command'] = 'pbpaste'
  vim.g['system_copy#copy_command'] = 'pbcopy'
elseif (vim.fn.executable('pbcopy.exe') == 1) then
  vim.g['system_copy#paste_command'] = 'pbpaste.exe'
  vim.g['system_copy#copy_command'] = 'pbcopy.exe'
end
