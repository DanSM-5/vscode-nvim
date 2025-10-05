---@module 'types.vscode'

local vscode = require('vscode')
local nx = { 'n', 'x' }
local xo = { 'x', 'o' }
local nxo = { 'n', 'x', 'o' }

return {
  set_default = function()
    -- Vim commentary emulation
    -- vim.keymap.set('x', 'gc', '<Plug>VSCodeCommentary', {
    --   desc = '[VSCommentary]: Start comment action with word objects',
    -- })
    -- vim.keymap.set('n', 'gc', '<Plug>VSCodeCommentary', {
    --   desc = '[VSCommentary]: Start comment action with word objects',
    -- })
    vim.keymap.set('o', 'gc', '<Plug>VSCodeCommentary', {
      desc = '[VSCommentary]: Start comment action with word objects',
    })
    -- vim.keymap.set('n', 'gcc', '<Plug>VSCodeCommentaryLine', {
    --   desc = '[VSCommentary]: Toggle comment line under the cursor',
    -- })

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

    -- Fast saving
    -- vim.keymap.set('n', '<C-s>', ':<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })
    -- vim.keymap.set('v', '<C-s>', ':<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })
    -- vim.keymap.set('c', '<C-s>', '<C-u>w<CR>', { desc = 'Save buffer with ctrl-s', noremap = true })

    local upScrollCallback = function ()
      require('utils.scroll').scroll_up()
    end
    local downScrollCallback = function ()
      require('utils.scroll').scroll_down()
    end

    vim.keymap.set({'n', 'v'}, '<S-down>', downScrollCallback, {
      desc = '[VSCode] Scroll down (shift-d)',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'v' }, '<S-up>', upScrollCallback, {
      desc = '[VSCode] Scroll up (shift-d)',
      noremap = true,
    })


    -- Move to line displayed in context of sticky scroll
    vim.keymap.set({ 'n' }, '<leader>cu', function()
      vscode.call('editor.action.focusStickyScroll')
      vscode.action('editor.action.goToFocusedStickyScrollLine')
    end, { noremap = true, desc = '[VSCode] Go context up' })

    vim.keymap.set('n', '<leader>ct', function ()
      vscode.action('editor.action.toggleStickyScroll')
    end, { noremap = true, desc = '[VSCode] Toggle sticky scrol' })


    -- Vscode actions -- LSP like bindings

    -- Go to implementation mappings
    vim.keymap.set({ 'n', 'x' }, '<space>I', function()
      vscode.action('editor.action.peekImplementation')
    end, {
      desc = '[VSCode] Peak implementations',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'x' }, '<space>i', function()
      vscode.action('editor.action.goToImplementation')
    end, {
      desc = '[VSCode] Show implementations',
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

    -- Show definition
    vim.keymap.set({ 'n', 'x' }, 'gd', function()
      vscode.action('editor.action.revealDefinition')
    end, {
      desc = '[VSCode] Reveal definition',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'x' }, '<space>ds', function()
      vscode.call('workbench.action.splitEditorDown')
      vscode.action('editor.action.revealDefinition')
    end, {
      desc = '[VSCode] Reveal definition in split',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'x' }, '<space>dv', function()
      vscode.call('workbench.action.splitEditorRight')
      vscode.action('editor.action.revealDefinition')
    end, {
      desc = '[VSCode] Reveal definition in vertical split',
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
    end, { desc = '[VSCode] Toggle fold', noremap = true })
    vim.keymap.set('n', 'zM', function()
      vscode.action('editor.foldAll')
    end, { desc = '[VSCode] Fold all', noremap = true })
    vim.keymap.set('n', 'zR', function()
      vscode.action('editor.unfoldAll')
    end, { desc = '[VSCode] Unfold all', noremap = true })
    vim.keymap.set('n', 'zc', function()
      vscode.action('editor.fold')
    end, { desc = '[VSCode] Fold current', noremap = true })
    vim.keymap.set('n', 'zC', function()
      vscode.action('editor.foldRecursively')
    end, { desc = '[VSCode] Fold recursively', noremap = true })
    vim.keymap.set('n', 'zo', function()
      vscode.action('editor.unfold')
    end, { desc = '[VSCode] Unfold current', noremap = true })
    vim.keymap.set('n', 'zO', function()
      vscode.action('editor.unfoldRecursively')
    end, { desc = '[VSCode] Unfold recursively', noremap = true })

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


    -- Show Symbols
    local select_symbol = function()
      vscode.action('workbench.action.gotoSymbol')
    end
    vim.keymap.set('n', '<space>sd', select_symbol, { noremap = true, desc = '[VSCode] Select symbol' })
    vim.keymap.set('n', '<leader>fa', select_symbol, { noremap = true, desc = '[VSCode] Select symbol' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ss', function()
      vscode.action('breadcrumbs.focusAndSelect')
    end, {
      desc = '[VSCode] Show symbols',
      noremap = true,
    })
    vim.keymap.set({ 'n', 'x' }, '<leader>sc', function()
      vscode.action('editor.showCallHierarchy')
    end, {
      desc = '[VSCode] Show call hierarchy',
      noremap = true,
    })
    vim.keymap.set('n', '<space>sw', function ()
      vscode.action('workbench.action.showAllSymbols')
    end, {
      desc = '[VSCode] Show workspace symbols',
      noremap = true,
    })

    vim.keymap.set('n', '<space>df', function ()
      vscode.action('editor.action.peekDefinition')
    end, {
      noremap = true,
      desc = '[VSCode] Peek symbol definition'
    })
    vim.keymap.set('n', '<space>dF', function ()
      -- vscode.action('editor.action.peekDeclaration')
      vscode.action('editor.action.peekTypeDefinition')
    end, {
      noremap = true,
      desc = '[VSCode] Peek symbol declaration'
    })

    vim.keymap.set('n', '<space>D', function ()
      vscode.action('editor.action.goToTypeDefinition')
    end, {
      noremap = true,
      desc = '[VSCode] Go to type definition'
    })

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

    -- Errors in vscode show with hover rather than a
    -- separate action, so map this one as well
    vim.keymap.set({ 'n', 'x' }, '<space>e', function ()
      vscode.action('editor.action.showHover')
    end, { desc = '[VSCode] Show error window', noremap = true })
    vim.keymap.set({ 'n' }, '<space>q', function ()
      vscode.action('workbench.actions.view.problems')
    end, { desc = '[VSCode] Show problems and warnings', noremap = true })
    vim.keymap.set({ 'n' }, '<space>l', function ()
      vscode.action('workbench.actions.view.problems')
    end, { desc = '[VSCode] Show problems and warnings', noremap = true })


    vim.keymap.set('n', '<leader>ve', function ()
      vscode.action('workbench.view.explorer')
    end, {
      noremap = true,
      desc = '[VSCode] Open explorer',
    })

    -- Signature help
    vim.keymap.set('n', '<C-k>', function ()
      vscode.call('editor.action.triggerParameterHints')
    end, {
      noremap = true,
      desc = '[VSCode] Open signature helpt',
    })

  end,

  set_repeatable = function()
    local repeat_motion = require('utils.repeat_motion')
    local repeat_pair = repeat_motion.repeat_pair
    local repeat_action = repeat_motion.create_repeatable_func

    -- Hunk stage
    vim.keymap.set('n', '<leader>hs', repeat_action(function ()
      require('utils.gitvscode').stage_hunk_under_cursor()
    end), { desc = '[VSCode] Stage hunk', noremap = true })
    vim.keymap.set('v', '<leader>hs', repeat_action(function()
      -- NOTE: This has to be called with call to ensure
      -- selection is made with the selected text.
      vscode.call('git.stageSelectedRanges', {
        restore_selection = true,
      })
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
      vscode.call('git.unstageSelectedRanges')
    end), { desc = '[VSCode] Unstage hunk', noremap = true })
    vim.keymap.set('n', '<leader>hU', repeat_action(function()
      vscode.action('git.unstageAll') -- All changes in repo
      -- vscode.action('git.unstage') -- Only current file
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
    repeat_pair({
      keys = 'w',
      on_forward = nextDiagnostic,
      on_backward = prevDiagnostic,
      desc_forward = '[VSCode] Go to next diagnostic: error, warning, info',
      desc_backward = '[VSCode] Go to previous diagnostic: error, warning, info',
    })

    -- Next fold
    local nextFold = function()
      vscode.action('editor.gotoNextFold')
    end
    -- Previous fold
    local prevFold = function()
      vscode.action('editor.gotoPreviousFold')
    end

    repeat_pair({
      keys = 'z',
      on_forward = nextFold,
      on_backward = prevFold,
      desc_forward = '[VSCode] Go to next fold',
      desc_backward = '[VSCode] Go to prev fold',
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
      keys = 'S',
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

    -- Override next-prev matching bracket
    -- local next_close_bracket, prev_close_bracket = create_repeatable_pair(
    --   function ()
    --     vim.fn.search('}')
    --   end, function ()
    --     vim.fn.search('}', 'b')
    --   end
    -- )
    -- local next_open_bracket, prev_open_bracket = create_repeatable_pair(
    --   function ()
    --     vim.fn.search('{')
    --   end, function ()
    --     vim.fn.search('{', 'b')
    --   end
    -- )
    -- vim.keymap.set('n', ']}', next_close_bracket, { desc = '[Bracket]: Go to next close bracket', silent = true, noremap = true })
    -- vim.keymap.set('n', '[}', prev_close_bracket, { desc = '[Bracket]: Go to previous close bracket', silent = true, noremap = true })
    -- vim.keymap.set('n', ']{', next_open_bracket, { desc = '[Bracket]: Go to next open bracket', silent = true, noremap = true })
    -- vim.keymap.set('n', '[{', prev_open_bracket, { desc = '[Bracket]: Go to previous open bracket', silent = true, noremap = true })


    -- Move to next find match
    local next_search_result = function()
      for _ in pairs(vim.fn.range(1, vim.v.count1)) do
        vscode.action('search.action.focusNextSearchResult')
      end
    end
    local previous_search_result = function()
      for _ in pairs(vim.fn.range(1, vim.v.count1)) do
        vscode.action('search.action.focusPreviousSearchResult')
      end
    end

    repeat_pair({
      keys = 'q',
      on_forward = next_search_result,
      on_backward = previous_search_result,
      desc_forward = '[VSCode] Go to next search result',
      desc_backward = '[VSCode] Go to previous search result',
    })


    -- Move to next error in files
    local next_search_result = function()
      for _ in pairs(vim.fn.range(1, vim.v.count1)) do
        vscode.action('editor.action.marker.nextInFiles')
      end
    end
    local previous_search_result = function()
      for _ in pairs(vim.fn.range(1, vim.v.count1)) do
        vscode.action('editor.action.marker.prevInFiles')
      end
    end

    repeat_pair({
      keys = 'l',
      on_forward = next_search_result,
      on_backward = previous_search_result,
      desc_forward = '[VSCode] Go to next error in files',
      desc_backward = '[VSCode] Go to previous error in files',
    })


    -- Duplicate comment keymap
    local duplicate_and_comment = repeat_action(function ()
      vim.cmd([[:t.]])
      vim.cmd.normal('k')
      -- vscode.call('editor.action.commentLine')
      local line = vim.fn.line('.') - 1 -- 0-indexed
      vscode.action('editor.action.commentLine', {
        range = { line, line },
        callback = function ()
          vim.cmd.normal('j')
        end,
      })
    end)
    local duplicate_and_comment_up = repeat_action(function ()
      vim.cmd([[:t.]])
      local line = vim.fn.line('.') - 1 -- 0-indexed
      vscode.action('editor.action.commentLine', {
        range = { line, line },
        callback = function ()
          vim.cmd.normal('k')
        end
      })
    end)

    vim.keymap.set('n', 'yc', duplicate_and_comment, {
      desc = '[Comment] Duplicate line, comment original',
      noremap = true,
    })
    vim.keymap.set('n', 'yC', duplicate_and_comment_up, {
      desc = '[Comment] Duplicate line, comment new',
      noremap = true,
    })

  end,

  -- Currently not in use.
  -- Kept as fallback if modules fail in vscode mode
  treesiter = function()
    -- keymaps "Select"
    vim.keymap.set(xo, 'agb', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@block.outer', 'textobjects')
    end, { desc = '[TS] Select a block', noremap = true })
    vim.keymap.set(xo, 'igb', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@block.inner', 'textobjects')
    end, { desc = '[TS] Select inner function', noremap = true })
    vim.keymap.set(xo, 'af', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
    end, { desc = '[TS] Select a function', noremap = true })
    vim.keymap.set(xo, 'if', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
    end, { desc = '[TS] Select inner function', noremap = true })
    vim.keymap.set(xo, 'ac', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
    end, { desc = '[TS] Select a class', noremap = true })
    vim.keymap.set(xo, 'ic', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
    end, { desc = '[TS] Select inner part of a class region', noremap = true })
    vim.keymap.set(xo, 'as', function()
      -- You can also use captures from other query groups like `locals.scm`
      require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
    end, { desc = '[TS] Select language scope', noremap = true })


    -- keymaps "Move"
    -- goto next start
    vim.keymap.set(nxo, ']m', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
    end, { desc = '[TS] Next function start', noremap = true })
    vim.keymap.set(nxo, ']]', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
    end, { desc = '[TS] Next class start', noremap = true })
    vim.keymap.set(nxo, ']k', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@block.*', 'textobjects')
    end, { desc = '[TS] Next block start', noremap = true })
    vim.keymap.set(nxo, ']C', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@comment.outer', 'textobjects')
    end, { desc = '[TS] Next comment start', noremap = true })
    vim.keymap.set(nxo, ']f', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@local.scope', 'locals')
    end, { desc = '[TS] Next scope', noremap = true })

    -- goto next end
    vim.keymap.set(nxo, ']M', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
    end, { desc = '[TS] Next function end', noremap = true })
    vim.keymap.set(nxo, '][', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
    end, { desc = '[TS] Next class end', noremap = true })
    vim.keymap.set(nxo, ']K', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@block.outer', 'textobjects')
    end, { desc = '[TS] Next block end', noremap = true })

    -- goto previous start
    vim.keymap.set(nxo, '[m', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
    end, { desc = '[TS] Previous function start', noremap = true })
    vim.keymap.set(nxo, '[[', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
    end, { desc = '[TS] Previous class start', noremap = true })
    vim.keymap.set(nxo, '[k', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@block.*', 'textobjects')
    end, { desc = '[TS] Previous block start', noremap = true })
    vim.keymap.set(nxo, '[C', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@comment.outer', 'textobjects')
    end, { desc = '[TS] Previous comment start', noremap = true })
    vim.keymap.set(nxo, '[f', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@local.scope', 'locals')
    end, { desc = '[TS] Previous scope', noremap = true })

    -- goto previous end
    vim.keymap.set(nxo, '[M', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
    end, { desc = '[TS] Previous function end', noremap = true })
    vim.keymap.set(nxo, '[]', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
    end, { desc = '[TS] Previous class end', noremap = true })
    vim.keymap.set(nxo, '[K', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@block.outer', 'textobjects')
    end, { desc = '[TS] Previous block end', noremap = true })


    -- Go to either the start or the end, whichever is closer.
    -- Use if you want more granular movements
    vim.keymap.set(nxo, ']x', function()
      require('nvim-treesitter-textobjects.move').goto_next('@conditional.outer', 'textobjects')
    end, { desc = '[TS] Next start/end', noremap = true })
    vim.keymap.set(nxo, '[x', function()
      require('nvim-treesitter-textobjects.move').goto_previous('@conditional.outer', 'textobjects')
    end, { desc = '[TS] Previous start/end', noremap = true })
  end
}

