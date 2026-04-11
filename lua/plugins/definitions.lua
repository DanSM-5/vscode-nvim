---@module 'treesitter-context'
---@module 'mini.indentscope'

local is_vscode = vim.g.vscode == 1
vim.g.miniindentscope_disable = is_vscode

-- Complete url helpers
-- local gh = function(x) return 'https://github.com/' .. x end
-- local cb = function(x) return 'https://codeberg.org/' .. x end
-- local gl = function(x) return 'https://gitlab.net/' .. x end

---@type pack.plugin.loadSpec[]
local plugins = {
  {
    -- Improve '*' and '#'
    src = 'haya14busa/vim-asterisk',
  },
  {
    -- Copy to register motions
    src = 'DanSM-5/vim-system-copy',
  },
  {
    -- Allow dot repeat function and keymaps
    src = 'tpope/vim-repeat',
  },
  {
    -- Allow moving in pascal/camel case, snake case and kebab case
    src = 'bkad/CamelCaseMotion',
    data = {
      event = 'LazyStart',
    },
  },
  {
    -- Allow replacing text using motions without storing deleted text
    src = 'inkarkat/vim-ReplaceWithRegister',
    data = {
      event = 'LazyStart',
    },
  },
  {
    -- Git integration
    src = 'tpope/vim-fugitive',
    data = {
      event = 'LazyStart',
    },
  },
  {
    -- Change surroungins
    src = 'kylechui/nvim-surround',
    data = {
      event = 'LazyStart',
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
  },
  {
    -- Add `Repeatable` command to improve ergonomics of vim-repeat
    src = 'kreskij/Repeatable.vim',
    data = {
      cmd = 'Repeatable',
    },
  },
  {
    -- Improve `a` and `i` text objects
    src = 'nvim-mini/mini.ai',
    data = {
      event = 'LazyStart',
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
  },

  -- Treesitter support
  {
    -- Add treesitter queries
    src = 'nvim-treesitter/nvim-treesitter',
    version = 'main',
    data = {
      build = ':TSUpdate',
      config = function()
        require('nvim-treesitter').setup({})
      end,
    },
  },
  {
    -- Add textobjects using treesitter
    src = 'nvim-treesitter/nvim-treesitter-textobjects',
    version = 'main',
    data = {
      event = 'LazyStart',
      deps = {
        'nvim-treesitter',
      },
      config = function()
        require('config.treesitter_textobjects').setup()
      end,
    },
  },
  {
    -- Manage treesitter functionality through modules
    src = 'MeanderingProgrammer/treesitter-modules.nvim',
    data = {
      deps = {
        'nvim-treesitter',
      },
      config = function ()
        require('config.treesitter_modules').setup()
      end
    },
  },

  {
    -- indentation lines
    src = 'saghen/blink.indent',
    data = {
      event = 'LazyStart',
      config = function()
        ---@type boolean Contron blink.indent
        vim.g.indent_guide = true

        require('blink.indent').setup({
          blocked = {
            -- default: 'terminal', 'quickfix', 'nofile', 'prompt'
            buftypes = { include_defaults = true },
            -- default: 'lspinfo', 'packer', 'checkhealth', 'help', 'man', 'gitcommit', 'dashboard', ''
            filetypes = { include_defaults = true, 'fzf', 'fugitive' },
          },
          mappings = {
            -- which lines around the scope are included for 'ai': 'top', 'bottom', 'both', or 'none'
            border = 'both',
            -- set to '' to disable
            -- textobjects (e.g. `y2ii` to yank current and outer scope)
            object_scope = 'ii',
            object_scope_with_border = 'ai',
            -- motions
            goto_top = '', -- '[i',
            goto_bottom = '', -- ']i',
          },
          static = {
            enabled = not is_vscode,
            char = '▏',
            priority = 1,
            -- specify multiple highlights here for rainbow-style indent guides
            -- highlights = { 'BlinkIndentRed', 'BlinkIndentOrange', 'BlinkIndentYellow', 'BlinkIndentGreen', 'BlinkIndentViolet', 'BlinkIndentCyan' },
            highlights = { 'BlinkIndent' },
          },
          scope = {
            enabled = not is_vscode,
            char = '▏',
            priority = 1000,
            -- set this to a single highlight, such as 'BlinkIndent' to disable rainbow-style indent guides
            -- highlights = { 'BlinkIndentScope' },
            -- optionally add: 'BlinkIndentRed', 'BlinkIndentCyan', 'BlinkIndentYellow', 'BlinkIndentGreen'
            highlights = {
              -- 'BlinkIndentOrange',
              -- 'BlinkIndentViolet',
              -- 'BlinkIndentBlue',
              'Delimiter',
            },
            -- enable to show underlines on the line above the current scope
            underline = {
              enabled = false,
              -- optionally add: 'BlinkIndentRedUnderline', 'BlinkIndentCyanUnderline', 'BlinkIndentYellowUnderline', 'BlinkIndentGreenUnderline'
              highlights = {
                'Delimiter',
              },
            },
          },
        })

        if not is_vscode then
          vim.api.nvim_create_user_command('IndentGuides', function(opts)
            ---@type string|boolean|nil
            local option = opts.fargs[1]

            if option ~= nil then
              option = option == 'on'
            end

            -- blink.indent control
            local blink_indent = option ~= nil and option or not vim.g.indent_guide
            vim.g.indent_guide = blink_indent
          end, {
            desc = '[Indent] Change indent guides visibility',
            nargs = '?',
            bang = true,
            bar = true,
            complete = function()
              return { 'on', 'off' }
            end,
          })
        end
      end,
    },
  },
}



-- if running in vscode, stop loading plugins here
if not is_vscode then
  vim.list_extend(plugins, {
    { src = 'rafamadriz/friendly-snippets', data = { lazy = true } },
    { src = 'nvim-tree/nvim-web-devicons', data = { lazy = true } },
    {
      src = 'psliwka/vim-smoothie',
      data = {
        event = 'LazyStart',
      },
    },
    {
      src = 'DanSM-5/fzf-lsp.nvim',
      data = {
        lazy = true,
        event = 'LspAttach',
        cmd = {
          'Definitions',
          'Declarations',
          'TypeDefinitions',
          'Implementations',
          'References',
          'DocumentSymbols',
          'WorkspaceSymbols',
          'IncomingCalls',
          'OutgoingCalls',
          'CodeActions',
          'RangeCodeActions',
          'Diagnostics',
          'DiagnosticsAll',
        },
        config = function()
          vim.g.fzf_lsp_pretty = 1
          vim.g.fzf_lsp_override_opts = {
            '--bind',
            'ctrl-l:change-preview-window(down|hidden|)',
            '--bind',
            'ctrl-/:change-preview-window(down|hidden|)',
            '--bind',
            'ctrl-^:toggle-preview',
            '--preview-window',
            'right,wrap-word',
          }
          require('fzf_lsp').setup({
            override_ui_select = true,
          })
        end,
      },
    },
    {
      src = 'lewis6991/gitsigns.nvim',
      version = 'fcfa7a989',
      data = {
        event = 'LazyStart',
        config = function()
          local gitsigns = require('gitsigns')

          -- Quickfix command
          vim.api.nvim_create_user_command('Gqf', function(opts)
            -- NOTE: to use quickfix on buffer only use
            -- :Gitsigns setqflist
            local target = opts.bang and 'attached' or 'all'
            gitsigns.setqflist(target)
          end, { bang = true, bar = true })

          -- Set mappings
          gitsigns.setup({
            -- Show before diagnostics
            sign_priority = 11, -- defaults to 6
            on_attach = function(bufnr)
              -- Navigation
              -- vim.keymap.set('n', '<space>nh', function ()
              --   gitsigns.nav_hunk('next')
              -- end, { desc = 'Gitsigns: Go to next hunk', buffer = bufnr })
              -- vim.keymap.set('n', '<space>nH', function ()
              --   gitsigns.nav_hunk('prev')
              -- end, { desc = 'Gitsigns: Go to previous hunk', buffer = bufnr })
              local repeat_pair = require('utils.repeat_motion').create_repeatable_pair
              local next_hunk, prev_hunk = repeat_pair(function()
                gitsigns.nav_hunk('next')
              end, function()
                  gitsigns.nav_hunk('prev')
                end)
              vim.keymap.set('n', ']g', next_hunk, { desc = 'Gitsigns: Go to next hunk', buffer = bufnr })
              vim.keymap.set('n', '[g', prev_hunk, { desc = 'Gitsigns: Go to previous hunk', buffer = bufnr })

              -- Actions
              vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Gitsigns: Stage hunk', buffer = bufnr })
              vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Gitsigns: Reset hunk', buffer = bufnr })
              vim.keymap.set('v', '<leader>hs', function()
                gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
              end, { desc = 'Gitsigns: Stage hunk', buffer = bufnr })
              vim.keymap.set('v', '<leader>hr', function()
                gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
              end, { desc = 'Gitsigns: Reset hunk', buffer = bufnr })
              vim.keymap.set(
                'n',
                '<leader>hS',
                gitsigns.stage_buffer,
                { desc = 'Gitsigns: Stage buffer', buffer = bufnr }
              )
              vim.keymap.set(
                'n',
                '<leader>hu',
                gitsigns.stage_hunk,
                { desc = 'Gitsigns: Undo stage hunk', buffer = bufnr }
              )
              vim.keymap.set(
                'n',
                '<leader>hR',
                gitsigns.reset_buffer,
                { desc = 'Gitsigns: Reset buffer', buffer = bufnr }
              )
              vim.keymap.set(
                'n',
                '<leader>hp',
                gitsigns.preview_hunk,
                { desc = 'Gitsigns: Preview hunk, repeat to enter preview window', buffer = bufnr }
              )
              vim.keymap.set('n', '<leader>hb', function()
                gitsigns.blame_line({ full = true })
              end, { desc = 'Gitsigns: Blame line', buffer = bufnr })
              vim.keymap.set(
                'n',
                '<leader>hB',
                gitsigns.toggle_current_line_blame,
                { desc = 'Gitsigns: Toggle line blame', buffer = bufnr }
              )
              vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'Gitsigns: Diff hunk', buffer = bufnr })
              vim.keymap.set('n', '<leader>hD', function()
                gitsigns.diffthis('~')
              end, { desc = 'Gitsigns: Diff all', buffer = bufnr })
              vim.keymap.set(
                'n',
                '<leader>td',
                gitsigns.preview_hunk_inline,
                { desc = 'Gitsigns: Toggle deleted hunk', buffer = bufnr }
              )
              vim.keymap.set(
                { 'o', 'x' },
                'ih',
                ':<C-U>Gitsigns select_hunk<CR>',
                { desc = 'Gitsigns: Text object inner hunk', buffer = bufnr }
              )
            end,
          })
        end,
      },
    },
    {
      src = 'junegunn/fzf',
      data = {
        event = 'LazyStart',
        name = 'fzf',
      },
    },
    {
      src = 'junegunn/fzf.vim',
      data = {
        event = 'LazyStart',
      },
    },
    {
      src = 'folke/ts-comments.nvim',
      data = {
        event = 'LazyStart',
        -- enabled = vim.fn.has('nvim-0.10.0') == 1,
        config = function()
          require('ts-comments').setup()
        end,
      },
    },

    -- Blink.cmp minimal config
    -- Currently preferring builtin completion
    -- {
    --   src = 'saghen/blink.cmp',
    --   version = vim.version.range( '1.*'),
    --   data = {
    --     -- enabled = false,
    --     deps = { 'rafamadriz/friendly-snippets' },
    --     config = function()
    --       local opts = {
    --         keymap = {
    --           preset = 'default',
    --           ['<CR>'] = { 'accept', 'fallback' },
    --         },
    --         cmdline = {
    --           enabled = false,
    --           keymap = nil,
    --           sources = {},
    --         },
    --         completion = {
    --           -- NOTE: Currently causes issues
    --           documentation = {
    --             auto_show = true,
    --             auto_show_delay_ms = 250,
    --             treesitter_highlighting = true,
    --             window = { border = 'rounded' },
    --           },
    --           menu = {
    --             border = 'rounded',
    --             draw = {
    --               padding = { 1, 1 },
    --               columns = {
    --                 { 'label', 'label_description', gap = 1 },
    --                 { 'kind_icon', 'kind', gap = 1 },
    --                 { 'source_name' },
    --               },
    --               components = {
    --                 kind_icon = { width = { fill = true }, },
    --               },
    --             },
    --           },
    --         },
    --         sources = {
    --           default = { 'lsp', 'path', 'snippets', 'buffer' },
    --         },
    --         fuzzy = { implementation = "prefer_rust_with_warning" }
    --       }
    --       require('blink.cmp').setup(opts)
    --       -- opts_extend = { "sources.default" }
    --     end,
    --   },
    -- },
  } --[[@as pack.plugin.loadSpec[] ]] )
end

-- return collection of loaded plugins
return {
  load = function ()
    local pack = require('lib.pack')
    pack.load(plugins)
  end,
  plugins = plugins,
}
