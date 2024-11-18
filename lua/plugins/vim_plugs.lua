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
  'psliwka/vim-smoothie',
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    -- Fix issue ENAMETOOLONG in linux
    name = 'tsto',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function ()
      require('keymaps').set_repeatable()
    end
  },
}

