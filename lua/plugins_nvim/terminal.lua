---@module 'lazy'

local fzf_path = vim.fn.expand('~/user-scripts/fzf')
local has_fzf = (vim.uv or vim.loop).fs_stat(fzf_path)
---@type LazyPluginSpec
local fzf_spec = has_fzf and {
  event = 'VeryLazy',
  dir = fzf_path,
  name = 'fzf',
} or {
  'junegunn/fzf',
  event = 'VeryLazy',
  name = 'fzf',
}

---@type LazyPluginSpec[]
return {
  -- {
  --   'nvim-treesitter/nvim-treesitter-context',
  --   event = 'VeryLazy',
  --   dependencies = {
  --     'nvim-treesitter/nvim-treesitter',
  --   },
  --   ---@type TSContext.UserConfig
  --   opts = {
  --     enable = true,
  --   },
  -- },
  { 'rafamadriz/friendly-snippets', lazy = true },
  { 'nvim-tree/nvim-web-devicons', lazy = true, },
  -- { 'lukas-reineke/cmp-rg' },
  {
    'psliwka/vim-smoothie',
    event = 'VeryLazy',
  },
  {
    'DanSM-5/fzf-lsp.nvim',
    lazy = true,
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
        '--bind', 'ctrl-l:change-preview-window(down|hidden|)',
        '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
        '--bind', 'ctrl-^:toggle-preview',
      }
      require('fzf_lsp').setup({
        override_ui_select = true
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'VeryLazy' },
    commit = 'fcfa7a989',
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
          local next_hunk, prev_hunk = repeat_pair(function ()
            gitsigns.nav_hunk('next')
          end, function ()
              gitsigns.nav_hunk('prev')
          end)
          vim.keymap.set('n', ']g', next_hunk, { desc = 'Gitsigns: Go to next hunk', buffer = bufnr })
          vim.keymap.set('n', '[g', prev_hunk, { desc = 'Gitsigns: Go to previous hunk', buffer = bufnr })

          -- Actions
          vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Gitsigns: Stage hunk', buffer = bufnr })
          vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Gitsigns: Reset hunk', buffer = bufnr })
          vim.keymap.set('v', '<leader>hs',
            function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end,
            { desc = 'Gitsigns: Stage hunk', buffer = bufnr }
          )
          vim.keymap.set('v', '<leader>hr',
            function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end,
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
          vim.keymap.set('n', '<leader>td', gitsigns.preview_hunk_inline, { desc = 'Gitsigns: Toggle deleted hunk', buffer = bufnr })
          vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>',
            { desc = 'Gitsigns: Text object inner hunk', buffer = bufnr })
        end
      })
    end,
  },
  fzf_spec,
  {
    'junegunn/fzf.vim',
    event = 'VeryLazy',
  },
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
  -- Blink.cmp minimal config
  -- Currently preferring builtin completion
  {
    'saghen/blink.cmp',
    enabled = false,
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
      },
      cmdline = {
        enabled = false,
        keymap = nil,
        sources = {},
      },
      completion = {
        -- NOTE: Currently causes issues
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          treesitter_highlighting = true,
          window = { border = 'rounded' },
        },
        menu = {
          border = 'rounded',
          draw = {
            padding = { 1, 1 },
            columns = {
              { 'label', 'label_description', gap = 1 },
              { 'kind_icon', 'kind', gap = 1 },
              { 'source_name' },
            },
            components = {
              kind_icon = { width = { fill = true }, },
            },
          },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  },
}
