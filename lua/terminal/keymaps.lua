local register = function()
  local nxo = { 'n', 'x', 'o' }
  local repeat_motion = require('utils.repeat_motion')
  local create_repeatable_pair = repeat_motion.create_repeatable_pair
  local repeat_pair = repeat_motion.repeat_pair
  local create_dot_map = repeat_motion.repeat_dot_map


  vim.keymap.set('x', '<A-up>', function ()
    return ":m '<-" .. (vim.v.count1 + 1) .. '<CR>gv=gv'
  end, { silent = true, noremap = true, desc = '[Vim] Move selected lines up', expr = true })
  vim.keymap.set('x', '<A-down>', function ()
    return ":m '>+" .. vim.v.count1 .. '<CR>gv=gv'
  end, { silent = true, noremap = true, desc = '[Vim] Move selected lines down', expr = true })

  vim.keymap.set('n', '<A-up>', function ()
    return ':<C-u>m .-' .. (vim.v.count1 + 1) .. '<CR>=='
  end, { silent = true, noremap = true, desc = '[Vim] Move line up', expr = true })
  vim.keymap.set('n', '<A-down>', function ()
    return ':<C-u>m .+' .. vim.v.count1 .. '<CR>=='
  end, { silent = true, noremap = true, desc = '[Vim] Move line down', expr = true })

  vim.keymap.set('i', '<A-up>', function ()
    return '<Esc>:m .-' .. (vim.v.count1 + 1) .. '<CR>==gi'
  end, { silent = true, noremap = true, desc = '[Vim] Move line up', expr = true })
  vim.keymap.set('i', '<A-down>', function ()
    return '<Esc>:m .+' .. vim.v.count1 .. '<CR>==gi'
  end, { silent = true, noremap = true, desc = '[Vim] Move line down', expr = true })


  vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true, desc = '[Vim] Improve scroll down' })
  vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true, desc = '[Vim] Improve scroll up' })

  vim.keymap.set('t', '<leader><esc>', '<c-\\><c-n>', {
    noremap = true,
    desc = '[Terminal] Escape terminal mode',
  })

  -- Mappings to help navigation
  vim.keymap.set('n', '<c-p>', function ()
    vim.cmd.GitFZF()
  end, {
    noremap = true,
    desc = '[Fzf] Git files',
  })
  -- command! -bang -nargs=? -complete=dir GitFZF
  -- \ call fzfcmd#fzf_files(empty(<q-args>) ? utils#git_path() : <q-args>, g:fzf_bind_options, <bang>0)

  -- call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(<q-args> == "?" ? { "placeholder": "" } : {})
  -- call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
  vim.keymap.set('n', '<A-p>', function()
    vim.cmd.GitFZF(vim.fn.getcwd())
  end, {
    noremap = true,
    desc = '[Fzf] Git files',
  })

  -- VimSmoothie remap
  vim.keymap.set('v', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })
  vim.keymap.set('n', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })
  vim.keymap.set('v', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })
  vim.keymap.set('n', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })
  vim.keymap.set('v', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })
  vim.keymap.set('n', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
    noremap = true,
    desc = '[Smoothie] Scroll down',
  })

  -- Move between buffers with tab
  vim.keymap.set('n', '<tab>', ':bn<cr>', { silent = true, noremap = true, desc = '[Buffer] Next buffer' })
  vim.keymap.set('n', '<s-tab>', ':bN<cr>', { silent = true, noremap = true, desc = '[Buffer] Previous buffer' })

  -- Call vim fugitive
  vim.keymap.set('n', '<leader>gg', function()
    local fugitive_window = nil

    for _, winnr in ipairs(vim.fn.range(1, vim.fn.winnr('$'))) do
      local bufnr = vim.fn.winbufnr(winnr)
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
      if filetype == 'fugitive' then
        fugitive_window = winnr
      end
    end

    if fugitive_window == nil then
      vim.cmd.Git()
    else
      vim.cmd(fugitive_window .. 'wincmd w')
      vim.cmd.quit()
    end
  end, {
    noremap = true,
    desc = '[Fugitive] Open fugitive',
  })

  -- Cd to current project or active buffer directory
  vim.keymap.set('n', '<leader>cd', function()
    require('utils.funcs').buffer_cd()
  end, { noremap = true, desc = '[Vim] Change root directory' })

  -- Quick buffer overview to change buffer
  vim.keymap.set('n', '<leader>gb', ':ls<cr>:b<space>', {
    desc = 'List open buffers and set command mode for quick navigation',
    noremap = true,
  })

  --- Repeatable keymaps

  -- Fold jump next/prev
  repeat_pair({
    keys = 'z',
    mode = nxo,
    desc_forward = '[Fold] Move to next fold',
    desc_backward = '[Fold] Move to previous fold',
    on_forward = function()
      vim.api.nvim_feedkeys(vim.v.count1 .. 'zj', 'xn', true)
    end,
    on_backward = function()
      vim.api.nvim_feedkeys(vim.v.count1 .. 'zk', 'xn', true)
    end,
  })

  -- Spelling next/prev
  ---@param forward boolean Direction of the keymap
  local spell_direction = function(forward)
    -- `]s`/`[s` only work if `spell` is enabled
    local spell = vim.wo.spell
    vim.wo.spell = true
    local direction = (forward and ']' or '[') .. 's'
    vim.api.nvim_feedkeys(vim.v.count1 .. direction, 'xn', true)
    vim.wo.spell = spell
  end
  repeat_pair({
    keys = 's',
    mode = nxo,
    desc_forward = '[Spell] Move to next spelling mistake',
    desc_backward = '[Spell] Move to previous spelling mistake',
    on_forward = function()
      spell_direction(true)
    end,
    on_backward = function()
      spell_direction(false)
    end,
  })

  -- Move to next/previous hunk
  local move_hunk = function(forward)
    if vim.wo.diff then -- If we're in a diff
      local direction_key = forward and ']' or '['
      vim.cmd.normal({ vim.v.count1 .. direction_key .. 'c', bang = true })
    else
      local exists, gitsigns = pcall(require, 'gitsigns')
      if not exists then
        vim.notify('GitSings not found', vim.log.levels.WARN)
        return
      end

      local direction = forward and 'next' or 'prev'
      gitsigns.nav_hunk(direction)
    end
  end

  repeat_pair({
    keys = 'c',
    mode = nxo,
    desc_forward = '[GitSings] Move to next hunk',
    desc_backward = '[GitSings] Move to previous hunk',
    on_forward = function()
      move_hunk(true)
    end,
    on_backward = function()
      move_hunk(false)
    end,
  })

  -- Resize windows
  local ctrl_w = vim.api.nvim_replace_termcodes('<C-w>', true, true, true)
  local vsplit_bigger, vsplit_smaller = create_repeatable_pair(function()
    vim.fn.feedkeys(ctrl_w .. '5>', 'n')
  end, function()
    vim.fn.feedkeys(ctrl_w .. '5<', 'n')
  end)

  repeat_pair({
    keys = '>',
    prefix_forward = '<A-.',
    prefix_backward = '<A-,',
    on_forward = vsplit_bigger,
    on_backward = vsplit_smaller,
    desc_forward = '[VSplit] Make vsplit bigger',
    desc_backward = '[VSplit] Make vsplit smaller',
  })

  local split_bigger, split_smaller = create_repeatable_pair(function()
    vim.fn.feedkeys(ctrl_w .. '+', 'n')
  end, function()
    vim.fn.feedkeys(ctrl_w .. '-', 'n')
  end)

  repeat_pair({
    keys = '>',
    prefix_forward = '<A-t',
    prefix_backward = '<A-s',
    on_forward = split_bigger,
    on_backward = split_smaller,
    desc_forward = '[Split] Make split bigger',
    desc_backward = '[Split] Make split smaller',
  })

  -- Diagnostic mappings
  local diagnostic_jump_next = nil
  local diagnostic_jump_prev = nil

  if vim.diagnostic.jump then
    diagnostic_jump_next = vim.diagnostic.jump
    diagnostic_jump_prev = vim.diagnostic.jump
  else
    -- Deprecated in favor of `vim.diagnostic.jump` in Neovim 0.11.0
    ---@diagnostic disable-next-line deprecated
    diagnostic_jump_next = vim.diagnostic.goto_next
    ---@diagnostic disable-next-line deprecated
    diagnostic_jump_prev = vim.diagnostic.goto_prev
  end

  local diagnostic_next, diagnostic_prev = create_repeatable_pair(
  ---Move to next diagnostic
  ---@param options vim.diagnostic.JumpOpts | nil
    function(options)
      local opts = options or {}
      ---@diagnostic disable-next-line
      opts.count = 1 * vim.v.count1
      diagnostic_jump_next(opts)
    end,
    ---Move to provious diagnostic
    ---@param options vim.diagnostic.JumpOpts | nil
    function(options)
      local opts = options or {}
      ---@diagnostic disable-next-line
      opts.count = -1 * vim.v.count1
      diagnostic_jump_prev(opts)
    end
  )

  -- diagnostic
  vim.keymap.set('n', ']d', function()
    diagnostic_next({ wrap = true })
  end, { desc = '[Diagnostic] Go to next diagnostic message', silent = true, noremap = true })
  vim.keymap.set('n', '[d', function()
    diagnostic_prev({ wrap = true })
  end, { desc = '[Diagnostic] Go to previous diagnostic message', silent = true, noremap = true })

  -- diagnostic ERROR
  vim.keymap.set('n', ']e', function()
    diagnostic_next({ severity = vim.diagnostic.severity.ERROR, wrap = true })
  end, { desc = '[Diagnostic] Go to next error', silent = true, noremap = true })
  vim.keymap.set('n', '[e', function()
    diagnostic_prev({ severity = vim.diagnostic.severity.ERROR, wrap = true })
  end, { desc = '[Diagnostic] Go to previous error', silent = true, noremap = true })

  -- diagnostic WARN
  vim.keymap.set('n', ']w', function()
    diagnostic_next({ severity = vim.diagnostic.severity.WARN, wrap = true })
  end, { desc = '[Diagnostic] Go to next warning', silent = true, noremap = true })
  vim.keymap.set('n', '[w', function()
    diagnostic_prev({ severity = vim.diagnostic.severity.WARN, wrap = true })
  end, { desc = '[Diagnostic] Go to previous warning', silent = true, noremap = true })

  -- diagnostic INFO, using H as it is often a variation of hint
  vim.keymap.set('n', ']H', function()
    diagnostic_next({ severity = vim.diagnostic.severity.INFO })
  end, { desc = '[Diagnostic] Go to next info', silent = true, noremap = true })
  vim.keymap.set('n', '[H', function()
    diagnostic_prev({ severity = vim.diagnostic.severity.INFO })
  end, { desc = '[Diagnostic] Go to previous info', silent = true, noremap = true })

  -- diagnostic HINT
  vim.keymap.set('n', ']h', function()
    diagnostic_next({ severity = vim.diagnostic.severity.HINT })
  end, { desc = '[Diagnostic] Go to next hint', silent = true, noremap = true })
  vim.keymap.set('n', '[h', function()
    diagnostic_prev({ severity = vim.diagnostic.severity.HINT })
  end, { desc = '[Diagnostic] Go to previous hint', silent = true, noremap = true })

  -- windows navigation
  vim.keymap.set('n', '<A-k>', '<c-w><c-k>', { noremap = true, desc = '[Window] Move to up window' })
  vim.keymap.set('n', '<A-j>', '<c-w><c-j>', { noremap = true, desc = '[Window] Move to down window' })
  vim.keymap.set('n', '<A-h>', '<c-w><c-h>', { noremap = true, desc = '[Window] Move to right window' })
  vim.keymap.set('n', '<A-l>', '<c-w><c-l>', { noremap = true, desc = '[Window] Move to left window' })

  -- Duplicate line above and below without moving cursor
  create_dot_map('inoremap <A-y> <esc>:<C-U>t-1<cr>a')
  create_dot_map('inoremap <A-e> <esc>:<C-U>t-1<cr>a')

  -- Comment and copy
  create_dot_map('nmap yc <cmd>t.<cr>kgccj')
  create_dot_map('nmap yC <cmd>t.<cr>gcck')

  -- Move to next/prev Tab
  repeat_pair({
    prefix_backward = 'g',
    prefix_forward = 'g',
    keys = { 't', 'T' },
    desc_forward = '[Tab] Move to next tab',
    desc_backward = '[Tab] Move to previous tab',
    on_forward = function ()
      vim.cmd(vim.v.count1..'tabnext')
    end,
    on_backward = function ()
      vim.cmd(vim.v.count1..'tabprevious')
    end,
  })

  --- Improved builtin neovim keymaps (based on fugitive)

  --- Execute a command and print errors without a stacktrace.
  --- @param opts table Arguments to |nvim_cmd()|
  local function cmd(opts)
    local ok, err = pcall(vim.api.nvim_cmd, opts, {})
    if not ok then
      vim.api.nvim_echo({ { err:sub(#'Vim:' + 1) } }, true, { err = true })
    end
  end

  -- Quickfix mappings

  -- Move items in quickfix next/prev
  local quickfix_next = function()
    cmd({ cmd = 'cnext', count = vim.v.count1 })
  end
  local quickfix_prev =  function()
    cmd({ cmd = 'cprevious', count = vim.v.count1 })
  end
  repeat_pair({
    keys = 'q',
    desc_forward = '[Quickfix] Move to next item',
    desc_backward = '[Quickfix] Move to previous item',
    on_forward = quickfix_next,
    on_backward = quickfix_prev,
  })

  -- Do not repeat?
  vim.keymap.set('n', ']Q', function()
    cmd({ cmd = 'clast', count = vim.v.count ~= 0 and vim.v.count or nil })
  end, { desc = '[Quickfix] Move to last item', noremap = true })
  vim.keymap.set('n', '[Q', function()
    cmd({ cmd = 'cfirst', count = vim.v.count ~= 0 and vim.v.count or nil })
  end, { desc = '[Quickfix] Move to first item', noremap = true })

  -- Move to next/prev item in file
  local quickfix_next_file =  function()
    cmd({ cmd = 'cnfile', count = vim.v.count1 })
  end
  local quickfix_prev_file = function()
    cmd({ cmd = 'cpfile', count = vim.v.count1 })
  end
  repeat_pair({
    keys = '<C-q>',
    desc_forward = '[Quickfix] Move to next file item',
    desc_backward = '[Quickfix] Move to previous file item',
    on_forward = quickfix_next_file,
    on_backward = quickfix_prev_file,
  })


  -- Location list mappings

  -- Move items in loclist next/prev
  local locationlist_next = function()
    cmd({ cmd = 'lnext', count = vim.v.count1 })
  end
  local locationlist_prev = function()
    cmd({ cmd = 'lprevious', count = vim.v.count1 })
  end
  repeat_pair({
    keys = 'l',
    desc_forward = '[Locationlist] Move to next item',
    desc_backward = '[Locationlist] Move to previous item',
    on_forward = locationlist_next,
    on_backward = locationlist_prev,
  })

  -- Do not repeat?
  vim.keymap.set('n', ']L', function()
    cmd({ cmd = 'llast', count = vim.v.count ~= 0 and vim.v.count or nil })
  end, { desc = '[Locationlist] Move to last item', noremap = true })
  vim.keymap.set('n', '[L', function()
    cmd({ cmd = 'lfirst', count = vim.v.count ~= 0 and vim.v.count or nil })
  end, { desc = '[Locationlist] Move to first item', noremap = true })

  -- Move to next/prev item in file
  local locationlist_next_file = function()
    cmd({ cmd = 'lnfile', count = vim.v.count1 })
  end
  local locationlist_prev_file = function()
    cmd({ cmd = 'lpfile', count = vim.v.count1 })
  end
  repeat_pair({
    keys = '<C-l>',
    desc_forward = '[Locationlist] Move to next file item',
    desc_backward = '[Locationlist] Move to previous file item',
    on_forward = locationlist_next_file,
    on_backward = locationlist_prev_file,
  })


  -- Argument list

  -- Move to next/prev entry in argument list
  local arglist_next = function()
    -- count doesn't work with :next, must use range. See #30641.
    cmd({ cmd = 'next', range = { vim.v.count1 } })
  end
  local arglist_prev = function()
    cmd({ cmd = 'previous', count = vim.v.count1 })
  end
  repeat_pair({
    keys = 'a',
    desc_forward = '[Argumentlist] Move to next entry',
    desc_backward = '[Argumentlist] Move to previous entry',
    on_forward = arglist_next,
    on_backward = arglist_prev,
  })

  -- Do not repeat?
  vim.keymap.set('n', ']A', function()
    if vim.v.count ~= 0 then
      cmd({ cmd = 'argument', count = vim.v.count })
    else
      cmd({ cmd = 'last' })
    end
  end, { desc = '[Argumentlist] Move to last entry', noremap = true })
  vim.keymap.set('n', '[A', function()
    if vim.v.count ~= 0 then
      cmd({ cmd = 'argument', count = vim.v.count })
    else
      cmd({ cmd = 'first' })
    end
  end, { desc = '[Argumentlist] Move to first entry', noremap = true })


  -- Tags

  -- Move to next/prev tag
  local tag_next = function()
    -- count doesn't work with :tnext, must use range. See #30641.
    cmd({ cmd = 'tnext', range = { vim.v.count1 } })
  end
  local tag_prev = function()
    -- count doesn't work with :tprevious, must use range. See #30641.
    cmd({ cmd = 'tprevious', range = { vim.v.count1 } })
  end
  repeat_pair({
    keys = 't',
    desc_forward = '[Tags] Move to next tag',
    desc_backward = '[Tags] Move to previous tag',
    on_forward = tag_next,
    on_backward = tag_prev,
  })

  -- Do not repeat?
  vim.keymap.set('n', ']T', function()
    -- :tlast does not accept a count, so use :trewind if count given
    if vim.v.count ~= 0 then
      cmd({ cmd = 'tfirst', range = { vim.v.count } })
    else
      cmd({ cmd = 'tlast' })
    end
  end, { desc = '[Tags] Move to last tag', noremap = true })
  vim.keymap.set('n', '[T', function()
    -- count doesn't work with :trewind, must use range. See #30641.
    cmd({ cmd = 'tfirst', range = vim.v.count ~= 0 and { vim.v.count } or nil })
  end, { desc = '[Tags] Move to first tag', noremap = true })

  -- Move to next/prev tag in preview window
  local tag_next_preview = function()
    -- count doesn't work with :ptnext, must use range. See #30641.
    cmd({ cmd = 'ptnext', range = { vim.v.count1 } })
  end
  local tag_prev_preview = function()
    -- count doesn't work with :ptprevious, must use range. See #30641.
    cmd({ cmd = 'ptprevious', range = { vim.v.count1 } })
  end
  repeat_pair({
    keys = '<C-t>',
    desc_forward = '[Tags] Move to next tag in preview window',
    desc_backward = '[Tags] Move to previous tag in preview window',
    on_forward = tag_next_preview,
    on_backward = tag_prev_preview,
  })


  -- Buffers

  -- Move to next/prev buffer
  local buffer_next = function()
    cmd({ cmd = 'bnext', count = vim.v.count1 })
  end
  local buffer_prev = function()
    cmd({ cmd = 'bprevious', count = vim.v.count1 })
  end
  repeat_pair({
    keys = 'b',
    desc_forward = '[Buffers] Move to next buffer',
    desc_backward = '[Buffers] Move to previous buffer',
    on_forward = buffer_next,
    on_backward = buffer_prev,
  })

  -- Do not repeat?
  vim.keymap.set('n', ']B', function()
    if vim.v.count ~= 0 then
      cmd({ cmd = 'buffer', count = vim.v.count })
    else
      cmd({ cmd = 'blast' })
    end
  end, { desc = '[Buffers] Move to last buffer', noremap = true })
  vim.keymap.set('n', '[B', function()
    if vim.v.count ~= 0 then
      cmd({ cmd = 'buffer', count = vim.v.count })
    else
      cmd({ cmd = 'bfirst' })
    end
  end, { desc = '[Buffers] Move to first buffer', noremap = true })


  -- Add empty lines after/before cursor
  local empty_line_next = function()
    -- TODO: update once it is possible to assign a Lua function to options #25672
    vim.go.operatorfunc = "v:lua.require'vim._buf'.space_below"
    vim.cmd[[normal g@l]]
  end
  local empty_line_prev = function()
    -- TODO: update once it is possible to assign a Lua function to options #25672
    vim.go.operatorfunc = "v:lua.require'vim._buf'.space_above"
    vim.cmd[[normal g@l]]
  end
  repeat_pair({
    keys = '<space>',
    desc_forward = '[EmptyLine] Add empty line after cursor',
    desc_backward = '[EmptyLine] Add empty line before cursor',
    on_forward = empty_line_next,
    on_backward = empty_line_prev,
  })


  -- Jump to next conflict
  local jumpconflict_next = function()
    vim.cmd.normal(vim.keycode('<Plug>JumpconflictContextNext'))
  end
  local jumpconflict_prev = function()
    vim.cmd.normal(vim.keycode('<Plug>JumpconflictContextPrevious'))
  end
  repeat_pair({
    keys = 'n',
    desc_forward = '[JumpConflict] Move to next conflict marker',
    desc_backward = '[JumpConflict] Move to previous conflict marker',
    on_forward = jumpconflict_next,
    on_backward = jumpconflict_prev,
  })
end

return {
  register = register,
}
