-- vim plugins

return {
  'DanSM-5/vim-system-copy',
  'tpope/vim-repeat',
  -- 'christoomey/vim-sort-motion',
  'bkad/CamelCaseMotion',
  'tpope/vim-surround',
  {
    'kreskij/Repeatable.vim',
    cmd = { 'Repeatable' },
  },
  'haya14busa/vim-asterisk',
  -- 'psliwka/vim-smoothie',
  {
    'echasnovski/mini.ai',
    opts = {},
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = vim.g.vscode ~= 1,
    event = { 'VimEnter' },
    config = function()
      local gitsigns = require('gitsigns')

      -- Quickfix command
      vim.api.nvim_create_user_command('Gqf', function (opts)
        -- NOTE: to use quickfix on buffer only use
        -- :Gitsigns setqflist
        local target = opts.bang and 'attached' or 'all'
        gitsigns.setqflist(target)
      end, { bang = true, bar = true })

      -- Set mappings
      gitsigns.setup({
        on_attach = function(bufnr)
          -- Navigation
          vim.keymap.set('n', '<space>nh', gitsigns.next_hunk, { desc = 'Gitsigns: Go to next hunk', buffer = bufnr })
          vim.keymap.set('n', '<space>nH', gitsigns.prev_hunk, { desc = 'Gitsigns: Go to previous hunk', buffer = bufnr })
          local repeat_pair = require('utils.repeat_motion').create_repeatable_pair
          local next_hunk, prev_hunk = repeat_pair(gitsigns.next_hunk, gitsigns.prev_hunk)
          vim.keymap.set('n', ']g', next_hunk, { desc = 'Gitsigns: Go to next hunk', buffer = bufnr })
          vim.keymap.set('n', '[g', prev_hunk, { desc = 'Gitsigns: Go to previous hunk', buffer = bufnr })

          -- Actions
          vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Gitsigns: Stage hunk', buffer = bufnr })
          vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Gitsigns: Reset hunk', buffer = bufnr })
          vim.keymap.set('v', '<leader>hs',
            function() gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
            { desc = 'Gitsigns: Stage hunk', buffer = bufnr }
          )
          vim.keymap.set('v', '<leader>hr',
            function() gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
            { desc = 'Gitsigns: Reset hunk', buffer = bufnr }
          )
          vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Gitsigns: Stage buffer', buffer = bufnr })
          vim.keymap.set('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Gitsigns: Undo stage hunk', buffer = bufnr })
          vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Gitsigns: Reset buffer', buffer = bufnr })
          vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk,
            { desc = 'Gitsigns: Preview hunk, repeat to enter preview window', buffer = bufnr })
          vim.keymap.set('n', '<leader>hb', function() gitsigns.blame_line { full = true } end,
            { desc = 'Gitsigns: Blame line', buffer = bufnr })
          vim.keymap.set('n', '<leader>hB', gitsigns.toggle_current_line_blame,
            { desc = 'Gitsigns: Toggle line blame', buffer = bufnr })
          vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'Gitsigns: Diff hunk', buffer = bufnr })
          vim.keymap.set('n', '<leader>hD', function() gitsigns.diffthis('~') end,
            { desc = 'Gitsigns: Diff all', buffer = bufnr })
          vim.keymap.set('n', '<leader>td', gitsigns.toggle_deleted, { desc = 'Gitsigns: Toggle deleted hunk', buffer = bufnr })
          -- Text object
          vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>',
            { desc = 'Gitsigns: Text object inner hunk', buffer = bufnr })
        end
      })
    end,
  },
}

