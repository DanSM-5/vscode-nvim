-- lazy.nvim paths
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

-- Bootstrap lazy.nvim
if not uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Disable updates check if file exists
local check_for_updates = not (uv.fs_stat(vim.fn.stdpath('config') .. '/.no_updates_check'))

-- Setup lazy.nvim
require('lazy').setup({
  spec = {
    -- import your plugins
    { import = 'plugins_vscode' },
    { import = 'plugins_nvim', enabled = vim.g.vscode ~= 1  },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  -- install = { colorscheme = { 'habamax' } },
  install = { colorscheme = { 'onedark' } },
  -- automatically check for plugin updates
  checker = { enabled = check_for_updates, notify = false },
  -- change_detection = { enabled = false }
  ui = {
    icons = {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
    custom_keys = {
      -- An external dependency is the default for <leader>l... WTF!!!
      ['<localleader>l'] = {
        function (plugin)
          require('lazy.util').float_term({
            'git', 'log', '--oneline', '--decorate', '--graph', '--all',
          }, { cwd = plugin.dir })
        end,
        desc = '[Lazy.nvim] Open plugin log',
      },
    },
  },
})

