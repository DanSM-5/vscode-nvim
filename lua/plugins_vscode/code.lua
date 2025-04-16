-- vim plugins

local is_vscode = vim.g.vscode == 1

---@type (LazyPluginSpec|string)[]|
return {
  'haya14busa/vim-asterisk',
  'urxvtcd/vim-indent-object',
  'DanSM-5/vim-system-copy',
  'tpope/vim-repeat',
  -- 'christoomey/vim-sort-motion',
  'bkad/CamelCaseMotion',
  -- 'tpope/vim-surround',
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    config = function()
      if is_vscode then
        -- Configure highlight group in vscode mode
        vim.api.nvim_set_hl(0, 'NvimSurroundHighlight', {
          bg = '#394963',
          ctermbg = 17,
          force = true,
        })
      end

      require('nvim-surround').setup({})
    end,
  },
  {
    'kreskij/Repeatable.vim',
    cmd = { 'Repeatable' },
  },
  {
    'echasnovski/mini.ai',
    event = 'VeryLazy',
    config = function()
      local ai = require('mini.ai')
      ai.setup({
        search_method = 'cover',
        n_lines = 999999,
        custom_textobjects = {
          ["'"] = false,
          ['"'] = false,
          ['`'] = false,
          -- Set function call to F
          ['f'] = false,
          ['F'] = ai.gen_spec.function_call(),
        },
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('nvim-treesitter').define_modules({
        diagnostics = {
          attach = function(buf, _)
            require('utils.diagnostics_vscode').start_ts_diagnostics(buf)
          end,
          detach = function(buf)
            require('utils.diagnostics_vscode').stop_ts_diagnostics(buf)
          end,
          is_supported = function(lang)
            -- Known bad filetypes
            if vim.tbl_contains({ 'log' }, lang) then
              return false
            end

            local bufnr = vim.api.nvim_get_current_buf()
            local remote = require('utils.diagnostics_vscode').is_remote(bufnr)
            if (not remote) and (vim.fn.filereadable(vim.fn.bufname(bufnr)) == 0) then
              return false
            end

            return true
          end,
        },
      })

      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup({
        diagnostics = { enable = false },
        sync_intall = true,
        auto_install = true,
        highlight = { enable = not is_vscode },
        indent = { enable = not is_vscode },
        sync_install = true,
        ensure_installed = {},
        ignore_install = {},
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<space>nn',
            node_incremental = '<space>nn',
            scope_incremental = '<space>nN',
            node_decremental = '<space>np',
          },
        },
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
              ['as'] = { query = '@local.scope', query_group = 'locals', desc = 'Select language scope' },
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
              ['@class.outer'] = 'v', -- '<c-v>', -- blockwise
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
              [']k'] = { query = '@block.*', desc = '[TS] Next block start' },
              [']C'] = { query = '@comment.outer', desc = '[TS] Next comment start' },
              [']f'] = { query = '@local.scope', query_group = 'locals', desc = '[TS] Next scope' },
            },
            goto_next_end = {
              [']M'] = { query = '@function.outer', desc = '[TS] Next function end' },
              [']['] = { query = '@class.outer', desc = '[TS] Next class end' },
              [']K'] = { query = '@block.outer', desc = '[TS] Next block end' },
            },
            goto_previous_start = {
              ['[m'] = { query = '@function.outer', desc = '[TS] Previous function start' },
              ['[['] = { query = '@class.outer', desc = '[TS] Previous class start' },
              ['[k'] = { query = '@block.*', desc = '[TS] Previous block start' },
              ['[C'] = { query = '@comment.outer', desc = '[TS] Previous comment start' },
              ['[f'] = { query = '@local.scope', query_group = 'locals', desc = '[TS] Next scope' },
            },
            goto_previous_end = {
              ['[M'] = { query = '@function.outer', desc = '[TS] Previous function end' },
              ['[]'] = { query = '@class.outer', desc = '[TS] Previous class end' },
              ['[K'] = { query = '@block.outer', desc = '[TS] Previous block end' },
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
        },
        --- END
      })
    end,
  },
}
