---@module 'lazy.nvim'
---@module 'treesitter-context'

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
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('config.treesitter_textobjects').setup()
    end,
  },
  {
    'MeanderingProgrammer/treesitter-modules.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function ()
      require('config.treesitter_modules').setup()
    end
  },
}
