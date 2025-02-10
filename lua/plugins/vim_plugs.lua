-- vim plugins

local is_vscode = vim.g.vscode == 1
local has_fzf = (vim.uv or vim.loop).fs_stat(
  vim.fn.expand('~/user-scripts/fzf')
)

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
  'urxvtcd/vim-indent-object',
  -- 'psliwka/vim-smoothie',
  {
    'echasnovski/mini.ai',
    opts = {
      search_method = 'cover',
      n_lines = 100,
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function ()
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup({
        sync_intall = true,
        auto_install = true,
        highlight = { enable = not is_vscode },
        indent = { enable = not is_vscode },
        sync_install = true,
        ensure_installed = {},
        ignore_install = {},
        textobjects = {
          lsp_interop = {
            enable = not is_vscode,
            border = 'rounded', -- 'none',
            floating_preview_opts = {},
            peek_definition_code = {
              ['<space>df'] = '@function.outer',
              ['<space>dF'] = '@class.outer',
            },
          },
          select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
              ['agb'] = { query = '@block.outer', desc = 'Select a block' },
              ['igb'] = { query = '@block.inner', desc = 'Select inner block' },
              -- You can use the capture groups defined in textobjects.scm
              ['af'] = { query = '@function.outer', desc = 'Select a function' },
              ['if'] = { query = '@function.inner', desc = 'Select inner function' },
              ['ac'] = { query = '@class.outer', desc = 'Select a class' },
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
              -- You can also use captures from other query groups like `locals.scm`
              ['as'] = { query = '@scope', query_group = 'locals', desc = 'Select language scope' },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'v', -- 'V' -- linewise
              ['@class.outer'] = 'v' -- '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            include_surrounding_whitespace = true,
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = { query = '@function.outer', desc = '[TS] Next function start' },
              [']]'] = { query = '@class.outer', desc = '[TS] Next class start' },
              [']b'] = { query = '@block.*', desc = '[TS] Next block start' },
              [']C'] = { query = '@comment.outer', desc = '[TS] Next comment start' }
              --
              -- You can use regex matching (i.e. lua pattern) and/or pass a list in a 'query' key to group multiple queries.
              -- [']o'] = '@loop.*',
              -- [']o'] = { query = { '@loop.inner', '@loop.outer' } }
              --
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              -- [']s'] = { query = '@local.scope', query_group = 'locals', desc = 'Next scope' },
              -- [']z'] = { query = '@fold', query_group = 'folds', desc = 'Next fold' },
            },
            goto_next_end = {
              [']M'] = { query = '@function.outer', desc = '[TS] Next function end' },
              [']['] = { query = '@class.outer', desc = '[TS] Next class end' },
              [']B'] = { query = '@block.outer', desc = '[TS] Next block end' },
            },
            goto_previous_start = {
              ['[m'] = { query = '@function.outer', desc = '[TS] Previous function start' },
              ['[['] = { query = '@class.outer', desc = '[TS] Previous class start' },
              ['[b'] = { query = '@block.*', desc = '[TS] Previous block start' },
              ['[C'] = { query = '@comment.outer', desc = '[TS] Previous comment start' }
            },
            goto_previous_end = {
              ['[M'] = { query = '@function.outer', desc = '[TS] Previous function end' },
              ['[]'] = { query = '@class.outer', desc = '[TS] Previous class end' },
              ['[B'] = { query = '@block.outer', desc = '[TS] Previous block end' },
            },
            -- Below will go to either the start or the end, whichever is closer.
            -- Use if you want more granular movements
            -- Make it even more gradual by adding multiple queries and regex.
            -- goto_next = {
            --   [']d'] = '@conditional.outer',
            -- },
            -- goto_previous = {
            --   ['[d'] = '@conditional.outer',
            -- }
          },
        }
        --- END
      })
    end,
  },
  {
    'psliwka/vim-smoothie',
    enabled = not is_vscode,
  },
  {
    'tpope/vim-fugitive',
    enabled = not is_vscode,
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = not is_vscode,
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
  {
    enabled = not is_vscode and has_fzf,
    dir = vim.fn.expand('~/user-scripts/fzf'),
    name = 'fzf',
  },
  {
    'junegunn/fzf.vim',
    enabled = not is_vscode and has_fzf,
  }
}

