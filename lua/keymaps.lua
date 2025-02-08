local vscode = require('vscode')
local nx = { 'n', 'x' }

return {
  set_default = function()
    -- Vim commentary emulation
    vim.keymap.set('x', 'gc', '<Plug>VSCodeCommentary', {
      desc = '[VSCommentary]: Start comment action with word objects',
    })
    vim.keymap.set('n', 'gc', '<Plug>VSCodeCommentary', {
      desc = '[VSCommentary]: Start comment action with word objects',
    })
    vim.keymap.set('o', 'gc', '<Plug>VSCodeCommentary', {
      desc = '[VSCommentary]: Start comment action with word objects',
    })
    vim.keymap.set('n', 'gcc', '<Plug>VSCodeCommentaryLine', {
      desc = '[VSCommentary]: Toggle comment line under the cursor',
    })

    -- Ctrl+Shift+Up/Down to move up and down
    -- vim.keymap.set('n', '<C-S-Down>', ':m .+1<cr>==',
    --   { desc = 'Move line under the cursor down', silent = true })
    -- vim.keymap.set('n', '<C-S-Up>', ':m .-2<cr>==',
    --   { desc = 'Move line under the cursor up', silent = true })
    -- vim.keymap.set('i', '<C-S-Down>', '<Esc>:m .+1<cr>==gi',
    --   { desc = 'Move line under the cursor down', silent = true })
    -- vim.keymap.set('i', '<C-S-Up>', '<Esc>:m .-2<cr>==gi',
    --   { desc = 'Move line under the cursor up', silent = true })
    -- vim.keymap.set('v', '<C-S-Down>', ":m '>+1<cr>gv=gv",
    --   { desc = 'Move line under the cursor down', silent = true })
    -- vim.keymap.set('v', '<C-S-Up>', ":m '<-2<cr>gv=gv",
    --   { desc = 'Move line under the cursor up', silent = true })

    -- ]<End> or ]<Home> move current line to the end or the begin of current buffer
    vim.keymap.set('n', ']<End>', 'ddGp``', { desc = 'Move line to end of the buffer', noremap = true, silent = true })
    vim.keymap.set(
      'n',
      ']<Home>',
      'ddggP``',
      { desc = 'Move line to start of the buffer', noremap = true, silent = true }
    )
    vim.keymap.set('v', ']<End>', 'dGp``', { desc = 'Move line to end of the buffer', noremap = true, silent = true })
    vim.keymap.set(
      'v',
      ']<Home>',
      'dggP``',
      { desc = 'Move line to start of the buffer', noremap = true, silent = true }
    )

    -- Select blocks after indenting
    vim.keymap.set('x', '<', '<gv', { desc = 'Reselect visual block after reducing indenting', noremap = true })
    vim.keymap.set('x', '>', '>gv|', { desc = 'Reselect visual block after increasing indenting', noremap = true })

    -- Use tab for indenting in visual mode
    vim.keymap.set('x', '<S-Tab>', '<gv', { desc = 'Decrease indentation of selected block', noremap = true })
    vim.keymap.set('x', '<Tab>', '>gv|', { desc = 'Increase indentation of selected block', noremap = true })
    vim.keymap.set('n', '>', '>>_', { desc = 'Increase indentation of line', noremap = true })
    vim.keymap.set('n', '<', '<<_', { desc = 'Decrease indentation of line', noremap = true })

    -- smart up and down
    vim.keymap.set('n', '<down>', 'gj', { desc = 'Move down in wrapped lines', silent = true, remap = true })
    vim.keymap.set('n', '<up>', 'gk', { desc = 'Move up in wrapped lines', silent = true, remap = true })
    -- nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
    -- nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

    -- Fast saving
    vim.keymap.set('n', '<C-s>', ':<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })
    vim.keymap.set('v', '<C-s>', ':<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })
    vim.keymap.set('c', '<C-s>', '<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })

    -- SystemCopy keybindings
    vim.keymap.set('n', 'zy', '<Plug>SystemCopy', {
      desc = '[SystemCopy] Copy motion',
    })
    vim.keymap.set('x', 'zy', '<Plug>SystemCopy', {
      desc = '[SystemCopy] Copy motion',
    })
    vim.keymap.set('n', 'zY', '<Plug>SystemCopyLine', {
      desc = '[SystemCopy] Copy line under cursor',
    })
    vim.keymap.set('n', 'zp', '<Plug>SystemPaste', {
      desc = '[SystemCopy] Paste motion',
    })
    vim.keymap.set('x', 'zp', '<Plug>SystemPaste', {
      desc = '[SystemCopy] Paste motion',
    })
    vim.keymap.set('n', 'zP', '<Plug>SystemPasteLine', {
      desc = '[SystemCopy] Paste line below',
    })

    -- @deprecated in favor of native vscode editorScroll command
    -- VimSmoothie maps
    -- vim.keymap.set('v', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
    --   desc = '[VimSmoothie] Move down (ctrl-d)',
    --   noremap = true,
    -- })
    -- vim.keymap.set('n', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
    --   desc = '[VimSmoothie] Move down (ctrl-d)',
    --   noremap = true,
    -- })
    -- vim.keymap.set('v', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
    --   desc = '[VimSmoothie] Move up (ctrl-d)',
    --   noremap = true,
    -- })
    -- vim.keymap.set('n', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
    --   desc = '[VimSmoothie] Move up (ctrl-d)',
    --   noremap = true,
    -- })

    -- Smooth scroll up/down
    -- Combine with: "editor.cursorSmoothCaretAnimation": "on"
    -- Set an appropriate jumpStep value. 8 seems to be on the sweet spot.
    -- You can try: "editor.smoothScrolling": true
    -- but animation felt yanky at the end of the buffer
    -- https://stackoverflow.com/questions/47040925/microsoft-vs-code-jump-10-lines-vertically-at-once/48568520#48568520

    local jumpStep = 8
    local upScrollCallback =  function ()
      local current = vim.fn.line('.')
      if current <= jumpStep then
        vscode.call('editorScroll', { args = { by = 'line', to = 'up', value = math.floor(jumpStep / 2), revealCursor = true }})
      else
        vscode.call('editorScroll', { args = { by = 'line', to = 'up', value = jumpStep, revealCursor = true }})
      end

      if current <= (jumpStep * 3) then
        vscode.call('cursorMove', { args = { to = 'up', value = jumpStep }})
      else
        vscode.call('cursorMove', { args = { to = 'viewPortCenter', value = jumpStep }})
      end

    end

    local downScrollCallback = function ()
      vscode.call('editorScroll', { args = { by = 'line', to = 'down', value = jumpStep, revealCursor = true }})
      -- Works better if "editor.smoothScrolling": false
      -- vscode.call('cursorMove', { args = { to = 'viewPortCenter' }})

      -- Improves when "editor.smoothScrolling": true
      local line = vim.fn.line('.')
      local eof = vim.fn.line('$')
      if line <= (eof - (3 * jumpStep)) then
        vscode.call('cursorMove', { args = { to = 'down', value = math.floor(jumpStep / 2) }})
      else
        vscode.call('cursorMove', { args = { to = 'viewPortCenter', value = jumpStep }})
      end
    end

    vim.keymap.set('v', '<S-down>', downScrollCallback, {
      desc = '[VimSmoothie] Move down (shift-d)',
      noremap = true,
    })
    vim.keymap.set('n', '<S-down>', downScrollCallback, {
      desc = '[VimSmoothie] Move down (shift-d)',
      noremap = true,
    })
    vim.keymap.set('v', '<S-up>', upScrollCallback, {
      desc = '[VimSmoothie] Move up (shift-d)',
      noremap = true,
    })
    vim.keymap.set('n', '<S-up>', upScrollCallback, {
      desc = '[VimSmoothie] Move up (shift-d)',
      noremap = true,
    })

    -- Map clipboard functions
    vim.keymap.set('x', '<Leader>y', ':<C-u>call clipboard#yank()<cr>', {
      desc = 'Yank selection to system clipboard',
      silent = true,
      noremap = true,
    })
    vim.keymap.set('n', '<Leader>p', 'clipboard#paste("p")', {
      desc = 'Paste content of system clipboard after the cursor',
      expr = true,
      noremap = true,
    })
    vim.keymap.set('n', '<Leader>P', 'clipboard#paste("P")', {
      desc = 'Paste content of system clipboard after the cursor',
      expr = true,
      noremap = true,
    })
    vim.keymap.set('x', '<Leader>p', 'clipboard#paste("p")', {
      desc = 'Paste content of system clipboard after the cursor',
      expr = true,
      noremap = true,
    })
    vim.keymap.set('x', '<Leader>P', 'clipboard#paste("P")', {
      desc = 'Paste content of system clipboard after the cursor',
      expr = true,
      noremap = true,
    })

    -- Clean trailing whitespace in file
    vim.keymap.set('n', '<Leader>cc', ':%s/\\s\\+$//e<cr>', {
      desc = 'Clear trailing whitespace in file',
      noremap = true,
      silent = true,
    })
    -- Clean carriage returns '^M'
    vim.keymap.set('n', '<Leader>cr', ':%s/\\r$//g<cr>', {
      desc = 'Clear carriage return characters (^M)',
      noremap = true,
      silent = true,
    })
    -- " Quick buffer overview an completion to change
    vim.keymap.set('n', 'gb', ':ls<cr>:b<space>', {
      desc = 'List open buffers and set command mode for quick navigation',
      noremap = true,
    })

    -- vim-asterisk
    vim.keymap.set({ 'n', 'v', 'o' }, '*', '<Plug>(asterisk-*)', {
      desc = '[Asterisk] Select word under the cursor *',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, '#', '<Plug>(asterisk-#)', {
      desc = '[Asterisk] Select word under the cursor #',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'g*', '<Plug>(asterisk-g*)', {
      desc = '[Asterisk] Select word under the cursor g*',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'g#', '<Plug>(asterisk-g#)', {
      desc = '[Asterisk] Select word under the cursor g#',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'z*', '<Plug>(asterisk-z*)', {
      desc = '[Asterisk] Select word under the cursor * (preserve position)',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'gz*', '<Plug>(asterisk-gz*)', {
      desc = '[Asterisk] Select word under the cursor # (preserve position)',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'z#', '<Plug>(asterisk-z#)', {
      desc = '[Asterisk] Select word under the cursor g* (preserve position)',
    })
    vim.keymap.set({ 'n', 'v', 'o' }, 'gz#', '<Plug>(asterisk-gz#)', {
      desc = '[Asterisk] Select word under the cursor g# (preserve position)',
    })

    -- Set 'stay' behavior by default
    -- map *  <Plug>(asterisk-z*)
    -- map #  <Plug>(asterisk-z#)
    -- map g* <Plug>(asterisk-gz*)
    -- map g# <Plug>(asterisk-gz#)

    -- -- Down
    -- nnoremap <C-d> <C-d>zz
    -- -- Up
    -- nnoremap <C-u> <C-u>zz
    -- -- Forwards
    -- nnoremap <C-f> <C-f>zz
    -- -- Backwards
    -- nnoremap <C-b> <C-b>zz
    -- nnoremap <PageUp> <PageUp>zz
    -- nnoremap <PageDown> <PageDown>zz
    -- nnoremap <S-Up> <S-Up>zz
    -- nnoremap <S-Down> <S-Down>zz

    -- Vscode actions -- LSP like bindings

    -- Go to implementation mappings
    vim.keymap.set({ 'n', 'x' }, 'gI', function()
      vscode.action('editor.action.goToImplementation')
    end, {
      desc = '[VSCode] Show implementations',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'x' }, 'gi', function()
      vscode.action('editor.action.peekImplementation')
    end, {
      desc = '[VSCode] Peak implementations',
      noremap = true,
    })
    vim.keymap.set('n', '<space>rn', function()
      vscode.action('editor.action.rename')
    end, {
      desc = '[VSCode] Rename symbol',
      noremap = true,
    })

    -- Show references
    vim.keymap.set({ 'n', 'x' }, 'gr', function()
      vscode.action('editor.action.referenceSearch.trigger')
    end, {
      desc = '[VSCode] Show references',
      noremap = true,
    })

    -- Format document
    vim.keymap.set('n', '<space>f', function()
      vscode.action('editor.action.formatDocument')
    end, {
      desc = '[VSCode] Format Document',
      noremap = true,
    })

    -- Open reference in vertical split
    vim.keymap.set('n', 'gv', function()
      vscode.action('editor.action.revealDefinitionAside')
    end, {
      desc = '[VSCode] Show definition in vertical split',
      noremap = true,
    })

    -- -- Diagnostic next
    -- vim.keymap.set('n', ']d', function()
    --   vscode.action('editor.action.marker.next')
    -- end, {
    --   desc = '[VSCode] Go to next diagnostic: error, warning, info',
    --   noremap = true,
    -- })
    -- -- Diagnostic prev
    -- vim.keymap.set('n', '[d', function()
    --   vscode.action('editor.action.marker.prev')
    -- end, {
    --   desc = '[VSCode] Go to previous diagnostic: error, warning, info',
    --   noremap = true,
    -- })

    -- -- Go to next merge conflict
    -- vim.keymap.set('n', ']n', function ()
    --   vscode.action('merge-conflict.next')
    -- end, { desc = '[VSCode] Go to next merge conflict', noremap = true })
    --
    -- -- Go to prev merge conflict
    -- vim.keymap.set('n', '[n', function ()
    --   vscode.action('merge-conflict.previous')
    -- end, { desc = '[VSCode] Go to prev merge conflict', noremap = true })

    -- -- Action marker next/prev doesn't support moving per specific levels
    -- -- error/warning/info/hint etc. So we duplicate the common case for complitness.
    -- -- Diagnostic next
    -- vim.keymap.set('n', '<space>ne', function()
    --   vscode.action('editor.action.marker.next')
    -- end, {
    --   desc = '[VSCode] Go to next diagnostic: error, warning, info',
    --   noremap = true,
    -- })
    -- -- Diagnostic prev
    -- vim.keymap.set('n', '<space>nE', function()
    --   vscode.action('editor.action.marker.prev')
    -- end, {
    --   desc = '[VSCode] Go to previous diagnostic: error, warning, info',
    --   noremap = true,
    -- })

    -- -- Next ocurrence of symbol
    -- vim.keymap.set('n', ']r', function ()
    --   vscode.action('editor.action.wordHighlight.next')
    -- end, {
    --   desc = '[VSCode] Go to next matching symbol',
    --   noremap = true,
    -- })
    --
    -- -- Previous ocurrence of symbol
    -- vim.keymap.set('n', '[r', function ()
    --   vscode.action('editor.action.wordHighlight.prev')
    -- end, {
    --   desc = '[VSCode] Go to prev matching symbol',
    --   noremap = true,
    -- })

    -- also exists go to next and prev in same file:
    -- editor.action.marker.nextInFiles and
    -- editor.action.marker.prevInFiles

    -- Code Actions (Quickfix)
    vim.keymap.set({ 'n', 'x' }, '<space>ca', function()
      vscode.action('editor.action.quickFix')
    end, {
      desc = '[VSCode] Open editor actions',
      noremap = true,
    })

    -- Fold Toggle
    vim.keymap.set('n', 'za', function()
      vscode.action('editor.toggleFold')
    end, {
      desc = '[VSCode] Toggle fold',
      noremap = true,
    })

    -- Below is the function in vimscript
    -- function! s:manageEditorSize(...)
    --     let count = a:1
    --     let to = a:2
    --     for i in range(1, count ? count : 1)
    --         call VSCodeNotify(to ==# 'increase' ? 'workbench.action.increaseViewSize' : 'workbench.action.decreaseViewSize')
    --     endfor
    -- endfunction

    vim.keymap.set(nx, '<A-j>', function()
      vscode.action('workbench.action.navigateDown')
    end, {
      desc = '[VSCode] Navigate to down window',
    })
    vim.keymap.set(nx, '<A-k>', function()
      vscode.action('workbench.action.navigateUp')
    end, {
      desc = '[VSCode] Navigate to up window',
    })
    vim.keymap.set(nx, '<A-h>', function()
      vscode.action('workbench.action.navigateLeft')
    end, {
      desc = '[VSCode] Navigate to left window',
    })
    vim.keymap.set(nx, '<A-l>', function()
      vscode.action('workbench.action.navigateRight')
    end, {
      desc = '[VSCode] Navigate to right window',
    })

    -- Move next buffer
    vim.keymap.set('n', '<Tab>', function()
      -- vscode.action('workbench.action.nextEditor')
      vscode.action('workbench.action.nextEditorInGroup')
    end, { desc = '[VSCode] Move to next buffer', noremap = true })
    -- Move to previous buffer
    vim.keymap.set('n', '<s-tab>', function()
      -- vscode.action('workbench.action.previousEditor')
      vscode.action('workbench.action.previousEditorInGroup')
    end, { desc = '[VSCode] Move to previous buffer', noremap = true })

    -- Clean carriage returns '^M'
    vim.keymap.set('n', '<leader>cr', ':%s/\r$//g<cr>', {
      desc = 'Clean carriage returns',
      noremap = true,
      silent = true,
    })

    local select_symbol = function()
      vscode.action('workbench.action.gotoSymbol')
    end
    vim.keymap.set('n', '<leader>ss', select_symbol, { noremap = true, desc = '[VSCode] Select symbol' })
    vim.keymap.set('n', '<leader>fa', select_symbol, { noremap = true, desc = '[VSCode] Select symbol' })

    -- WARN: Do not remap <c-o> in vscode
    -- it cannot handle it properly and cursor position is lost
    --
    -- vim.keymap.set('n', '<c-o><c-o>', '<c-o>', { desc = 'Regular <c-o> or jumplist backwards', noremap = true })
    -- vim.keymap.set('n', '<c-o><esc>', '<esc>', { desc = 'Placeholder to cancel O-pending mode', noremap = true })

    vim.keymap.set('n', '<leader>fr', function ()
      vscode.action('workbench.action.findInFiles', {
        args = {
          query = vim.fn.expand('<cword>') or ''
        }
      })
    end, { desc = '[VSCode] Search word under the cursor', noremap = true })
    vim.keymap.set('v', '<leader>fr', function ()
      vscode.action('workbench.action.findInFiles')
    end, { desc = '[VSCode] Search word under the cursor', noremap = true })

    -- Move cursor to position on screen
    vim.keymap.set('n', 'zz', function ()
      vscode.action('revealLine', { args = { at = 'center', lineNumber = vim.api.nvim_win_get_cursor(0)[1] } })
    end, { desc = '[VSCode] Move cursor to the center of the screen', noremap = true })
    vim.keymap.set('n', 'zt', function ()
      vscode.action('revealLine', { args = { at = 'top', lineNumber = vim.api.nvim_win_get_cursor(0)[1] } })
    end, { desc = '[VSCode] Move cursor to the top of the screen', noremap = true })
    vim.keymap.set('n', 'zb', function ()
      vscode.action('revealLine', { args = { at = 'bottom', lineNumber = vim.api.nvim_win_get_cursor(0)[1] } })
    end, { desc = '[VSCode] Move cursor to the bottom of the screen', noremap = true })

    -- Hunk diff
    vim.keymap.set('n', '<leader>hd', function ()
      vscode.action('git.openChange')
    end, { desc = '[VSCode] Diff hunk', noremap = true })
  end,

  set_repeatable = function()
    local repeat_motion = require('utils.repeat_motion')
    repeat_motion.set_motion_keys()
    local repeat_pair = repeat_motion.repeat_pair
    local repeat_action = repeat_motion.create_repeatable_func

    -- Hunk stage
    vim.keymap.set('n', '<leader>hs', repeat_action(function ()
      require('utils.gitvscode').stage_hunk_under_cursor()
    end), { desc = '[VSCode] Stage hunk', noremap = true })
    vim.keymap.set('v', '<leader>hs', repeat_action(function()
      vscode.action('git.stageSelectedRanges')
    end), { desc = '[VSCode] Stage hunk', noremap = true })
    vim.keymap.set('n', '<leader>hS', repeat_action(function ()
      vscode.action('git.stage')
    end), { desc = '[VSCode] Stage buffer', noremap = true })

    --NOTE: Currently not working... 😓
    -- Hunk undo stage
    vim.keymap.set('n', '<leader>hu', repeat_action(function()
      require('utils.gitvscode').unstage_hunk_under_cursor()
    end), { desc = '[VSCode] Unstage hunk', noremap = true })
    vim.keymap.set('v', '<leader>hu', repeat_action(function()
      vscode.action('git.unstageSelectedRanges')
    end), { desc = '[VSCode] Unstage hunk', noremap = true })
    vim.keymap.set('n', '<leader>hU', repeat_action(function()
      vscode.action('git.unstageAll')
    end), { desc = '[VSCode] Unstage all changes', noremap = true })

    -- Hunk reset
    vim.keymap.set('n', '<leader>hr', repeat_action(function()
      require('utils.gitvscode').revert_hunk_under_cursor()
    end), { desc = '[VSCode] Revert hunk', noremap = true })
    vim.keymap.set('v', '<leader>hr', repeat_action(function()
      vscode.action('git.revertSelectedRanges')
    end), { desc = '[VSCode] Revert hunk', noremap = true })
    vim.keymap.set('n', '<leader>hR', repeat_action(function()
      require('utils.gitvscode').revert_all_changes()
    end), { desc = '[VSCode] Revert buffer', noremap = true })

    -- Hunk preview next
    local hunkPreviewNext = function ()
      vscode.action('editor.action.dirtydiff.next')
    end
    -- Hunk preview prev
    local hunkPreviewPrev = function ()
      vscode.action('editor.action.dirtydiff.previous')
    end

    repeat_pair({
      keys = {'p', 'P'},
      desc_forward = '[VSCode] Preview next hunk',
      desc_backward = '[VSCode] Preview previous hunk',
      on_forward = hunkPreviewNext,
      on_backward = hunkPreviewPrev,
      prefix_backward = '<leader>h',
      prefix_forward = '<leader>h',
    })

    -- Hunk next
    local nextChange = function()
      vscode.action('workbench.action.editor.nextChange')
    end
    -- Hunk prev
    local prevChange = function()
      vscode.action('workbench.action.editor.previousChange')
    end

    repeat_pair({
      keys = 'c',
      desc_forward = '[VSCode] Go to next change',
      desc_backward = '[VSCode] Go to previous change',
      on_forward = nextChange,
      on_backward = prevChange,
    })

    -- Go to next merge conflict
    local nextConflict = function()
      vscode.action('merge-conflict.next')
    end
    -- Go to prev merge conflict
    local prevConflict = function()
      vscode.action('merge-conflict.previous')
    end

    repeat_pair({
      keys = 'n',
      desc_forward = '[VSCode] Go to next merge conflict',
      desc_backward = '[VSCode] Go to prev merge conflict',
      on_forward = nextConflict,
      on_backward = prevConflict,
    })

    -- Diagnostic next
    local nextDiagnostic = function()
      vscode.action('editor.action.marker.next')
    end
    -- Diagnostic prev
    local prevDiagnostic = function()
      vscode.action('editor.action.marker.prev')
    end

    repeat_pair({
      keys = 'e',
      on_forward = nextDiagnostic,
      on_backward = prevDiagnostic,
      desc_forward = '[VSCode] Go to next diagnostic: error, warning, info',
      desc_backward = '[VSCode] Go to previous diagnostic: error, warning, info',
    })
    repeat_pair({
      keys = 'd',
      on_forward = nextDiagnostic,
      on_backward = prevDiagnostic,
      desc_forward = '[VSCode] Go to next diagnostic: error, warning, info',
      desc_backward = '[VSCode] Go to previous diagnostic: error, warning, info',
    })

    -- Next ocurrence of symbol
    local nextSymbol = function()
      vscode.action('editor.action.wordHighlight.next')
    end
    -- Previous ocurrence of symbol
    local prevSymbol = function()
      vscode.action('editor.action.wordHighlight.prev')
    end

    repeat_pair({
      keys = 'r',
      on_forward = nextSymbol,
      on_backward = prevSymbol,
      desc_forward = '[VSCode] Go to next matching symbol',
      desc_backward = '[VSCode] Go to prev matching symbol',
    })

    -- NOTE: Requires extension "Go to Next/Previous Member"
    -- Next member
    local nextMember = function()
      vscode.action('gotoNextPreviousMember.nextMember')
    end
    local prevMember = function()
      vscode.action('gotoNextPreviousMember.previousMember')
    end

    repeat_pair({
      keys = 'a',
      on_forward = nextMember,
      on_backward = prevMember,
      desc_forward = '[VSCode] Go to next file member',
      desc_backward = '[VSCode] Go to prev file member',
    })

    ---@param count number
    ---@param action string
    local manageEditorSize = function(count, action)
      for _ in pairs(vim.fn.range(1, count ~= 0 and count or 1)) do
        vscode.action(action)
      end
    end

    local create_repeatable_pair = repeat_motion.create_repeatable_pair

    local vsplit_bigger, vsplit_smaller = create_repeatable_pair(function()
      manageEditorSize(vim.v.count, 'workbench.action.increaseViewWidth')
    end, function()
      manageEditorSize(vim.v.count, 'workbench.action.decreaseViewWidth')
    end)

    -- Window resize vsplit
    vim.keymap.set(nx, '<A-.>', vsplit_bigger, {
      desc = '[VSCode] Increase editor window width',
      noremap = true,
    })
    vim.keymap.set(nx, '<A-,>', vsplit_smaller, {
      desc = '[VSCode] Decrease editor window width',
      noremap = true,
    })

    local split_bigger, split_smaller = create_repeatable_pair(function()
      manageEditorSize(vim.v.count, 'workbench.action.increaseViewHeight')
    end, function()
      manageEditorSize(vim.v.count, 'workbench.action.decreaseViewHeight')
    end)

    -- Window resize split
    vim.keymap.set(nx, '<A-t>', split_bigger, {
      desc = '[VSCode] Increase editor window height',
      noremap = true,
    })
    vim.keymap.set(nx, '<A-s>', split_smaller, {
      desc = '[VSCode] Decrease editor window height',
      noremap = true,
    })
  end,
}

