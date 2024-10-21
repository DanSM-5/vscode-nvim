-- vim plugins

return {
  'DanSM-5/vim-system-copy',
  'tpope/vim-repeat',
  -- 'christoomey/vim-sort-motion',
  'bkad/CamelCaseMotion',
  'tpope/vim-surround',
  'kreskij/Repeatable.vim',
  'haya14busa/vim-asterisk',
  'psliwka/vim-smoothie',
  {
    'mawkler/demicolon.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function ()
      require('demicolon').setup({
        integrations = {
          gitsigns = { enabled = false }
        },
        keymaps = {
          -- Create `t`/`T`/`f`/`F` key mappings
          horizontal_motions = true,
          -- Create ]d/[d, etc. key mappings to jump to diganostics. See demicolon.keymaps.create_default_diagnostic_keymaps
          diagnostic_motions = false,
          -- Create `;` and `,` key mappings
          repeat_motions = true,
          -- Create `]q`/`[q` and `]l`/`[l` quickfix and location list mappings
          list_motions = false,
          -- Create `]s`/`[s` key mappings for jumping to spelling mistakes
          spell_motions = false,
          -- Create `]z`/`[z` key mappings for jumping to folds
          fold_motions = false,
        },
      })
      require('keymaps').set_repeatable()
    end
  }
}

