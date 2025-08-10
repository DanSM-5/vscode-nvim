-- Set colorscheme
vim.cmd.colorscheme('slate')

-- Color scheme overrides
-- MatchParen ctermfg=16 ctermbg=220 guifg=#000000 guibg=#ffd700
vim.api.nvim_set_hl(0, 'MatchParen', { force = true, ctermfg = 16, ctermbg = 220, fg = '#5f87d7', sp = '#5f87d7', underline = true })

-- Disable vim-smoothie remaps
vim.g.smoothie_no_default_mappings = 1
vim.opt.scrolloff = 5
vim.g.markdown_folding = 1


local lsp_servers = {}
local ignore_servers = { 'cmp2lsp' }
for _, file in ipairs(vim.api.nvim_get_runtime_file('after/lsp/*', true)) do
  local name = vim.fn.fnamemodify(file, ':t:r')
  if vim.tbl_contains(ignore_servers, name) then
    goto continue
  end
  table.insert(lsp_servers, name)

  ::continue::
end
-- Start lsps
vim.lsp.enable(lsp_servers)


-- Configure tab
local function SetTab(space)
  local space_val = tonumber((space == nil or space == '') and '2' or space, 10)
  vim.opt.tabstop = space_val
  vim.opt.softtabstop = space_val
  vim.opt.shiftwidth = space_val
  vim.opt.expandtab = true
  vim.opt.ruler = true
  vim.opt.autoindent = true
  vim.opt.smartindent = true
end

vim.g.SetTab = SetTab
vim.api.nvim_create_user_command('SetTab', function (opts)
  SetTab(opts.fargs[1])
  if opts.bang then
    vim.cmd.retab()
  end
end, { desc = '[Tab] Set indentation options on buffer', bang = true, nargs = '?', bar = true })

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Run after all plugins are loaded and nvim is ready',
  pattern = { '*' },
  callback = function()
    SetTab()
    require('config.netrw').setup()
  end,
})



---[[ Setup keymaps so we can accept completion using Enter and choose items using arrow keys or Tab.
local pumMaps = {
  ['<Tab>'] = '<C-n>',
  ['<S-Tab>'] = '<C-p>',
}
-- ['<CR>'] = '<C-y>',
-- ['<Down>'] = '<C-n>',
-- ['<Up>'] = '<C-p>',
for insertKmap, pumKmap in pairs(pumMaps) do
  vim.keymap.set('i', insertKmap, function()
    return vim.fn.pumvisible() == 1 and pumKmap or insertKmap
  end, { expr = true })
end
---]]

-- Enable fold method using indent
-- Ref: https://www.reddit.com/r/neovim/comments/10q2mjq/comment/j6nmuw8
-- also consider plugin: https://github.com/kevinhwang91/nvim-ufo
vim.opt.fillchars = {
  fold = ' ',
  foldopen = '',
  foldsep = ' ',
  foldclose = '',
  diff = '╱',
}
vim.opt.foldmethod = 'indent'
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- always open on the right
vim.opt.splitright = true
-- always split below
vim.opt.splitbelow = true

-- Enable terminal colors
vim.opt.termguicolors = true

-- enable filetype base indentation
vim.cmd('filetype plugin indent on')
-- Enable highlight on search
vim.opt.hlsearch = true

-- NOTE: Set by VimPlug
-- enable syntax highlight
-- > syntax enabled

-- Set backspace normal behavior
vim.opt.backspace = 'indent,eol,start'
vim.opt.breakindent = true
-- Set hidden on
vim.opt.hidden = true

-- Set workable mouse scroll
-- For selecting text hold shift while selecting text
-- or set mouse=r and then select text in command mode (:)
-- NOTE: This prevents right click paste.
-- use ctrl+shift+v, <leader>p or zp/zP
vim.opt.mouse = 'a'

vim.opt.completeopt = 'menuone,noinsert,popup,fuzzy'
-- vim.opt.diffopt = 'internal,filler,closeoff,indent-heuristic,linematch:120,algorithm:histogram'
vim.opt.diffopt = 'internal,filler,closeoff,indent-heuristic,algorithm:histogram'
vim.opt.signcolumn = 'auto:2'

-- Set wrap on lines
vim.opt.wrap = true


-- Briefly move cursor to matching pair: [], {}, ()
-- vim.opt.showmatch = true
-- Add angle brackets as matching pair.
vim.opt.matchpairs = vim.o.matchpairs .. ',<:>'

-- Reduce default update time to 1 second
vim.opt.updatetime = 1000

-- Explicit default of incsearch.
-- Visually show and highlight search matches.
vim.opt.incsearch = true

-- Recognize `@` symbol in filenames for things like `gf`
vim.opt.isfname = vim.o.isfname .. ',@-@'

-- Tab size
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.ruler = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Allow increments on alphabetical characters
vim.opt.nrformats = vim.o.nrformats .. ',alpha'

-- Buffer opts
vim.opt.fileformats = 'unix,dos,mac'
vim.opt.textwidth = 120
vim.opt.linebreak = true
vim.opt.autoread = true

-- "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor",
-- Cursor opts
vim.opt.guicursor = {
  'n-v-c:block',
  'i-ci-ve:ver25',
  'r-cr:hor20',
  'o:hor50',
  'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
  'sm:block-blinkwait175-blinkoff150-blinkon175',
  't:block-blinkon500-blinkoff500-TermCursor',
}

local undo_dir = vim.fn.expand('~/.cache/vscode-nvim/undodir')
if vim.fn.isdirectory(undo_dir) then
  pcall(vim.fn.mkdir, undo_dir, 'p')
end
vim.opt.undodir = undo_dir
vim.opt.undofile = true

if vim.fn.has('win32') == 1 then
  vim.g.python3_host_prog = '~/AppData/local/Programs/Python/Python3*/python.exe'
else
  vim.g.python3_host_prog = 'python3'
end

if vim.fn.executable('rg') then
  vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case --no-ignore --engine=pcre2 --hidden -g "!plugged" -g "!.git" -g "!node_modules"'
  vim.opt.grepformat = '%f:%l:%c:%m'
end

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = '*grep*',
  command = 'cwindow',
})

-- Global diagnostic mappings
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set(
  'n',
  '<space>e',
  vim.diagnostic.open_float,
  { desc = 'LSP: Open float window', silent = true, noremap = true }
)
vim.keymap.set(
  'n',
  '<space>E',
  function ()
    local curr_config = vim.diagnostic.config()
    vim.diagnostic.config({ virtual_lines = { current_line = true }, virtual_text = false })

    local unset = function ()
      vim.diagnostic.config(curr_config)
      pcall(vim.keymap.del, 'n', '<esc>', { buffer = true })
    end

    vim.keymap.set('n', '<esc>', function ()
      unset()
    end, { silent = true, buffer = true, desc = '[Diagnostic] Hide virtual lines' })

    vim.api.nvim_create_autocmd('CursorMoved', {
      once = true,
      desc = '[Diagnostic] Hide virtual lines',
      callback = unset
    })
  end,
  { desc = '[Lsp] Open virtual lines', silent = true, noremap = true }
)
vim.keymap.set('n', '<space>l', vim.diagnostic.setloclist, { desc = 'LSP: Open diagnostic list', silent = true })
vim.keymap.set('n', '<space>q', vim.diagnostic.setqflist , { desc = 'LSP: Open diagnostic list', silent = true })

-- Signs for diagnostics
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
vim.diagnostic.config({
  signs = { text = {
    [vim.diagnostic.severity.ERROR] = signs.Error,
    [vim.diagnostic.severity.WARN] = signs.Warn,
    [vim.diagnostic.severity.HINT] = signs.Hint,
    [vim.diagnostic.severity.INFO] = signs.Info,
  } },

  -- Start diagnostics (virtual text) enabled
  virtual_text = true,
  jump = {
    float = true,
  },

  float = {
    border = 'rounded',
    source = true,
    header = 'Diagnostics',
    -- prefix = '💥 ',
  },

  -- update_in_insert = true,
})

-- Start with inlay hints enabled
vim.lsp.inlay_hint.enable(true)

vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', {
  sp = 'Red', undercurl = true,
  force = true,
})
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', {
  sp = 'Orange', undercurl = true,
  force = true,
})
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineOk', {
  sp = 'LightGreen', undercurl = true,
  force = true,
})
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', {
  sp = 'LightBlue', undercurl = true,
  force = true,
})
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', {
  sp = 'LightGrey', undercurl = true,
  force = true,
})


require('terminal.autocmd').register()
require('terminal.cmd').register()
require('terminal.keymaps').register()
