return {
  setup = function()
    local textobjects = require('lib.treesitter.textobjects')
    local fold_ui = require('lib.treesitter.fold_ui')
    local fold_text = require('lib.treesitter.fold_text')
    local diagnostics = require('lib.treesitter.diagnostics')

    textobjects.setup({ enable = true, disable = false })
    fold_ui.setup({ enable = true, disable = false })
    fold_text.setup({ enable = true, disable = false })
    diagnostics.setup({ enable = true, disable = true })

    local manager = require('treesitter-modules.core.manager')
    table.insert(manager.modules, textobjects)
    table.insert(manager.modules, fold_ui)
    table.insert(manager.modules, fold_text)
    table.insert(manager.modules, diagnostics)

    require('treesitter-modules').setup({
      -- list of parser names, or 'all', that must be installed
      ensure_installed = {
        'bash',
        'css',
        'diff',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'json5',
        'lua',
        'markdown',
        'markdown_inline',
        'powershell',
        'query',
        'ssh_config',
        'ssh_config',
        'toml',
        'typescript',
        'typst',
        'vim',
        'vimdoc',
        'yaml',
      },
      -- list of parser names, or 'all', to ignore installing
      ignore_install = {},
      -- install parsers in ensure_installed synchronously
      sync_install = false,
      -- automatically install missing parsers when entering buffer
      auto_install = true,
      fold = {
        enable = false,
        disable = false,
      },
      highlight = {
        enable = true,
        disable = false,
        -- setting this to true will run `:h syntax` and tree-sitter at the same time
        -- set this to `true` if you depend on 'syntax' being enabled
        -- using this option may slow down your editor, and duplicate highlights
        -- instead of `true` it can also be a list of languages
        additional_vim_regex_highlighting = false,
      },
      incremental_selection = {
        enable = true,
        disable = false,
        -- set value to `false` to disable individual mapping
        keymaps = {
          init_selection = '<space>nn',
          node_incremental = '<space>nn',
          node_decremental = '<space>nN',
          scope_incremental = '<space>np',
        },
      },
      indent = {
        enable = true,
        disable = false,
      },
    })
  end,
}
