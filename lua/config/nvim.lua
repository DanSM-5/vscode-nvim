-- Set colorscheme
vim.cmd.colorscheme('slate')

-- Disable vim-smoothie remaps
vim.g.smoothie_no_default_mappings = 1
vim.opt.scrolloff = 5
vim.g.markdown_folding = 1

local lsp_servers = {}
for _, file in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
  local name = vim.fn.fnamemodify(file, ':t:r')
  table.insert(lsp_servers, name)
end
-- Start lsps
vim.lsp.enable(lsp_servers)

local repeat_motion = require('utils.repeat_motion')
local create_repeatable_pair = repeat_motion.create_repeatable_pair
local repeat_pair = repeat_motion.repeat_pair
local create_dot_map = repeat_motion.repeat_dot_map

vim.keymap.set('t', '<leader><esc>', '<c-\\><c-n>', {
  noremap = true,
  desc = '[Terminal] Escape terminal mode',
})

vim.api.nvim_create_user_command('GitFZF', function(opts)
  local args = vim.fn.join(opts.fargs)
  local bang = opts.bang and 1 or 0
  local path = ''
  if vim.fn.empty(args) == 1 then
    path = require('utils.funcs').git_path()
  else
    path = args
  end

  vim.fn['fzf#vim#files'](path, vim.fn['fzf#vim#with_preview'](), bang)
end, {
  bang = true,
  bar = true,
  complete = 'dir',
  nargs = '?',
  force = true,
  desc = '[Git] Open fzf in top git repo or active buffer directory',
})

-- Mappings to help navigation
vim.keymap.set('n', '<c-p>', '<cmd>GFiles<cr>', {
  noremap = true,
  desc = '[Fzf] Git files',
})
-- command! -bang -nargs=? -complete=dir GitFZF
-- \ call fzfcmd#fzf_files(empty(<q-args>) ? utils#git_path() : <q-args>, g:fzf_bind_options, <bang>0)

-- call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(<q-args> == "?" ? { "placeholder": "" } : {})
-- call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
vim.keymap.set('n', '<A-p>', function()
  vim.cmd.GitFZF(vim.fn.getcwd())
end, {
  noremap = true,
  desc = '[Fzf] Git files',
})

-- VimSmoothie remap
vim.keymap.set('v', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('v', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('v', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})

-- Move between buffers with tab
vim.keymap.set('n', '<tab>', ':bn<cr>', { silent = true, noremap = true, desc = '[Buffer] Next buffer' })
vim.keymap.set('n', '<s-tab>', ':bN<cr>', { silent = true, noremap = true, desc = '[Buffer] Previous buffer' })

vim.keymap.set('n', ']<tab>', function ()
  vim.cmd(vim.v.count1..'tabnext')
end, { silent = true, noremap = true, desc = '[Tab] Move to next tab' })
vim.keymap.set('n', '[<tab>', function ()
  vim.cmd(vim.v.count1..'tabprevious')
end, { silent = true, noremap = true, desc = '[Tab] Move to Previous tab' })

-- Call vim fugitive
vim.keymap.set('n', '<leader>gg', '<cmd>Git<cr>', {
  noremap = true,
  desc = '[Fugitive] Open fugitive',
})


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
  end,
})


vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true, desc = '[Vim] Improve scroll down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true, desc = '[Vim] Improve scroll up' })

-- Window resize vsplit
-- vim.keymap.set('n', '<A-,>', '<C-w>5<', { noremap = true, desc = '[Window] Resize vertical split smaller' })
-- vim.keymap.set('n', '<A-.>', '<C-w>5>', { noremap = true, desc = '[Window] Resize vertical split wider' })
-- Window resize split taller/shorter
-- vim.keymap.set('n', '<A-->', '<C-w>5<', { noremap = true, desc = '[Window] Resize split shorter' })
-- vim.keymap.set('n', '<A-t>', '<C-w>+', { noremap = true, desc = '[Window] Resize split taller' })

local ctrl_w = vim.api.nvim_replace_termcodes('<C-w>', true, true, true)
local vsplit_bigger, vsplit_smaller = create_repeatable_pair(function()
  vim.fn.feedkeys(ctrl_w .. '5>', 'n')
end, function()
    vim.fn.feedkeys(ctrl_w .. '5<', 'n')
  end)

repeat_pair({
  keys = '>',
  prefix_forward = '<A-.',
  prefix_backward = '<A-,',
  on_forward = vsplit_bigger,
  on_backward = vsplit_smaller,
  desc_forward = '[VSplit] Make vsplit bigger',
  desc_backward = '[VSplit] Make vsplit smaller',
})

local split_bigger, split_smaller = create_repeatable_pair(function()
  vim.fn.feedkeys(ctrl_w .. '+', 'n')
end, function()
    vim.fn.feedkeys(ctrl_w .. '-', 'n')
  end)

repeat_pair({
  keys = '>',
  prefix_forward = '<A-t',
  prefix_backward = '<A-s',
  on_forward = split_bigger,
  on_backward = split_smaller,
  desc_forward = '[Split] Make split bigger',
  desc_backward = '[Split] Make split smaller',
})

-- Diagnostic mappings
local diagnostic_jump_next = nil
local diagnostic_jump_prev = nil

if vim.diagnostic.jump then
  diagnostic_jump_next = vim.diagnostic.jump
  diagnostic_jump_prev = vim.diagnostic.jump
else
  -- Deprecated in favor of `vim.diagnostic.jump` in Neovim 0.11.0
  diagnostic_jump_next = vim.diagnostic.goto_next
  diagnostic_jump_prev = vim.diagnostic.goto_prev
end

local diagnostic_next,
diagnostic_prev
= create_repeatable_pair(
  ---Move to next diagnostic
  ---@param options vim.diagnostic.JumpOpts | nil
  function(options)
    local opts = options or {}
    ---@diagnostic disable-next-line
    opts.count = 1 * vim.v.count1
    diagnostic_jump_next(opts)
  end,
  ---Move to provious diagnostic
  ---@param options vim.diagnostic.JumpOpts | nil
  function(options)
    local opts = options or {}
    ---@diagnostic disable-next-line
    opts.count = -1 * vim.v.count1
    diagnostic_jump_prev(opts)
  end
)

-- diagnostic
vim.keymap.set('n', ']d', function()
  diagnostic_next({ wrap = true })
end,
  { desc = '[Diagnostic] Go to next diagnostic message', silent = true, noremap = true }
)
vim.keymap.set('n', '[d', function()
  diagnostic_prev({ wrap = true })
end,
  { desc = '[Diagnostic] Go to previous diagnostic message', silent = true, noremap = true }
)

-- diagnostic ERROR
vim.keymap.set('n', ']e', function()
  diagnostic_next({ severity = vim.diagnostic.severity.ERROR, wrap = true })
end, { desc = '[Diagnostic] Go to next error', silent = true, noremap = true })
vim.keymap.set('n', '[e', function()
  diagnostic_prev({ severity = vim.diagnostic.severity.ERROR, wrap = true })
end, { desc = '[Diagnostic] Go to previous error', silent = true, noremap = true })

-- diagnostic WARN
vim.keymap.set('n', ']w', function()
  diagnostic_next({ severity = vim.diagnostic.severity.WARN, wrap = true })
end, { desc = '[Diagnostic] Go to next warning', silent = true, noremap = true })
vim.keymap.set('n', '[w', function()
  diagnostic_prev({ severity = vim.diagnostic.severity.WARN, wrap = true })
end, { desc = '[Diagnostic] Go to previous warning', silent = true, noremap = true })

-- diagnostic INFO, using H as it is often a variation of hint
vim.keymap.set('n', ']H', function()
  diagnostic_next({ severity = vim.diagnostic.severity.INFO })
end, { desc = '[Diagnostic] Go to next info', silent = true, noremap = true })
vim.keymap.set('n', '[H', function()
  diagnostic_prev({ severity = vim.diagnostic.severity.INFO })
end, { desc = '[Diagnostic] Go to previous info', silent = true, noremap = true })

-- diagnostic HINT
vim.keymap.set('n', ']h', function()
  diagnostic_next({ severity = vim.diagnostic.severity.HINT })
end, { desc = '[Diagnostic] Go to next hint', silent = true, noremap = true })
vim.keymap.set('n', '[h', function()
  diagnostic_prev({ severity = vim.diagnostic.severity.HINT })
end, { desc = '[Diagnostic] Go to previous hint', silent = true, noremap = true })

-- windows navigation
vim.keymap.set('n', '<A-k>', '<c-w><c-k>', { noremap = true, desc = '[Window] Move to up window' })
vim.keymap.set('n', '<A-j>', '<c-w><c-j>', { noremap = true, desc = '[Window] Move to down window' })
vim.keymap.set('n', '<A-h>', '<c-w><c-h>', { noremap = true, desc = '[Window] Move to right window' })
vim.keymap.set('n', '<A-l>', '<c-w><c-l>', { noremap = true, desc = '[Window] Move to left window' })

-- Duplicate line above and below without moving cursor
create_dot_map('inoremap <A-y> <esc>:<C-U>t-1<cr>a')
create_dot_map('inoremap <A-e> <esc>:<C-U>t-1<cr>a')

-- Comment and copy
create_dot_map('nmap yc <cmd>t.<cr>kgccj')
create_dot_map('nmap yC <cmd>t.<cr>gcck')

-- Cd to current project or active buffer directory
vim.keymap.set('n', '<leader>cd', function()
  require('utils.funcs').buffer_cd()
end, { noremap = true, desc = '[Vim] Change root directory' })

-- " Quick buffer overview an completion to change
vim.keymap.set('n', '<leader>gb', ':ls<cr>:b<space>', {
  desc = 'List open buffers and set command mode for quick navigation',
  noremap = true,
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
vim.cmd([[execute 'set fillchars=fold:\ ,foldopen:,foldsep:\ ,foldclose:,diff:╱']])
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
  } }
})

-- Start diagnostics (virtual text) enabled
vim.diagnostic.config({
  virtual_text = true,
  jump = {
    float = true,
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

-- Configure terminal buffers
vim.api.nvim_create_user_command('Term', function (opts)
  if opts.bang then
    vim.cmd.tabnew()
  end
  vim.cmd.terminal()
end, {
  bang = true,
  bar = true,
  desc = '[Terminal] Open terminal',
})
vim.api.nvim_create_user_command('Vterm', function (_)
  vim.cmd.vsplit()
  vim.cmd.terminal()
end, {
  bang = true,
  bar = true,
  desc = '[Terminal] Open terminal',
})
vim.api.nvim_create_user_command('Sterm', function (_)
  vim.cmd.split()
  vim.cmd.terminal()
end, {
  bang = true,
  bar = true,
  desc = '[Terminal] Open terminal',
})

local custom_term = vim.api.nvim_create_augroup('custom_term', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = custom_term,
  desc = '[Terminal] Setup terminal buffer',
  pattern = '*',
  callback = function ()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.bufhidden = 'hide'
    vim.cmd.startinsert()
  end,
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Recover previous cursor position in buffer',
  pattern = { '*' },
  callback = function()
    if (vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$")) then
      vim.fn.execute("normal! g`\"zz")
    end
  end
})
