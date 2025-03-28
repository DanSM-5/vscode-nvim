-- Set colorscheme
vim.cmd.colorscheme('slate')

-- Disable vim-smoothie remaps
vim.g.smoothie_no_default_mappings = 1
vim.opt.scrolloff = 5

vim.g.markdown_folding = 1

-- Mappings to help navigation
vim.keymap.set('n', '<c-p>', ':<C-u>GFiles<cr>', {
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
-- Select blocks after indenting
vim.keymap.set('x', '<', '<gv', {
  noremap = true,
  desc = '[Indent] Reselect indent on decrease',
})
vim.keymap.set('x', '>', '>gv|', {
  noremap = true,
  desc = '[Indent] Reselect indent on increase',
})

-- Use tab for indenting in visual mode
vim.keymap.set('x', '<Tab>', '>gv|', {
  noremap = true,
  desc = '[Indent] Increase indent',
})
vim.keymap.set('x', '<S-Tab>', '<gv', {
  noremap = true,
  desc = '[Indent] Decrease indent',
})
vim.keymap.set('n', '>', '>>_', {
  noremap = true,
  desc = '[Indent] Increase indent',
})
vim.keymap.set('n', '<', '<<_', {
  noremap = true,
  desc = '[Indent] Decrease indent',
})

-- smart up and down
vim.keymap.set('n', '<down>', 'gj', {
  remap = true,
  silent = true,
  desc = '[Nav] Smart down',
})
vim.keymap.set('n', '<up>', 'gk', {
  remap = true,
  silent = true,
  desc = '[Nav] Smart up',
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
vim.api.nvim_create_user_command('SetTab', SetTab, {})
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Run after all plugins are loaded and nvim is ready',
  pattern = { '*' },
  callback = function()
    SetTab()
  end,
})

-- SystemCopy keybindings
vim.keymap.set('n', 'zy', '<Plug>SystemCopy', {
  desc = '[SystemCopy] Copy motion',
})
vim.keymap.set('x', 'zy', '<Plug>SystemCopy', {
  desc = '[SystemCopy] Copy motion',
})
vim.keymap.set('n', 'zY', '<Plug>SystemCopyLine', {
  desc = '[SystemCopy] Copy line under cursor',
})
vim.keymap.set('n', 'zp', '<Plug>SystemPaste', {
  desc = '[SystemCopy] Paste motion',
})
vim.keymap.set('x', 'zp', '<Plug>SystemPaste', {
  desc = '[SystemCopy] Paste motion',
})
vim.keymap.set('n', 'zP', '<Plug>SystemPasteLine', {
  desc = '[SystemCopy] Paste line below',
})

-- Map clipboard functions
vim.keymap.set('x', '<Leader>y', ':<C-u>call clipboard#yank()<cr>', {
  desc = 'Yank selection to system clipboard',
  silent = true,
  noremap = true,
})
vim.keymap.set('n', '<Leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('n', '<Leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<Leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<Leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})

-- Indent text object
-- :h indent-object
vim.keymap.set('x', 'ii', '<Plug>(indent-object_linewise-none)', {
  remap = true,
  desc = '[Indent-Object] Select inner indent'
})
vim.keymap.set('o', 'ii', '<Plug>(indent-object_blockwise-none)', {
  remap = true,
  desc = '[Indent-Object] O-Pending inner indent'
})

-- Enable fold method using indent
-- Ref: https://www.reddit.com/r/neovim/comments/10q2mjq/comment/j6nmuw8
-- also consider plugin: https://github.com/kevinhwang91/nvim-ufo
vim.cmd([[execute 'set fillchars=fold:\ ,foldopen:,foldsep:\ ,foldclose:']])
vim.opt.foldmethod = 'indent'
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- ignore case in searches
vim.opt.ignorecase = true
-- Ignore casing unless using uppercase characters
vim.opt.smartcase = true

-- always open on the right
vim.opt.splitright = true
-- always split below
vim.opt.splitbelow = true

-- Set relative numbers
vim.opt.number = true
vim.opt.relativenumber = true
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
vim.opt.diffopt = 'internal,filler,closeoff,indent-heuristic,linematch:120,algorithm:histogram'
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

local exclude_filetypes = {
  'help',
}

---Setup keymaps for lsp
---@param client vim.lsp.Client
---@param bufnr number
local set_lsp_keys = function(client, bufnr)
  local buf = bufnr

  if
      vim.tbl_contains(exclude_filetypes, vim.bo[buf].buftype)
      or vim.tbl_contains(exclude_filetypes, vim.bo[buf].filetype)
  then
    vim.notify('[lsp][filetype] Not allowed: '..vim.bo[buf].filetype, vim.log.levels.DEBUG)
    vim.notify('[lsp][buftype] Not allowed: '..vim.bo[buf].buftype, vim.log.levels.DEBUG)
    return
  end

  vim.notify('[lsp][attached] Client: '..client.name..' id: '..client.id, vim.log.levels.DEBUG)

  -- Enable completion triggered by <C-x><C-o>
  -- Should now be set by default. Set anyways.
  vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

  -- Wrapper for setting maps with description
  ---Set keymap
  ---@param mode VimMode|VimMode[]
  ---@param key string
  ---@param func string|fun()
  ---@param desc string
  local set_map = function(mode, key, func, desc)
    local opts = { buffer = buf, silent = true, noremap = true }

    if desc then
      opts.desc = desc
    end

    vim.keymap.set(mode, key, func, opts)
  end

  set_map('n', '<space>td', function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, '[Lsp]: Toggle diagnostics')
  set_map('n', '<space>ti', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ nil }))
  end, '[Lsp]: Toggle inlay hints')
  set_map('n', '<space>tt', function()
    local config = type(vim.diagnostic.config().virtual_text) == 'boolean' and { current_line = true } or true
    vim.diagnostic.config({ virtual_text = config })
  end, '[Lsp]: Toggle inlay hints')
  set_map('n', '<space>tl', function()
    local config = type(vim.diagnostic.config().virtual_lines) == 'boolean' and { current_line = true } or false
    vim.diagnostic.config({ virtual_lines = config })
  end, '[Lsp]: Toggle inlay hints')
  -- Buffer local mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  set_map('n', 'gD', vim.lsp.buf.declaration, '[Lsp]: Go to declaration')
  set_map('n', 'gd', vim.lsp.buf.definition, '[Lsp]: Go to definition')
  set_map('n', '<space>vs', function()
    vim.cmd.split()
    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', '<space>vv', function()
    vim.cmd.vsplit()
    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', 'K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, '[Lsp]: Hover action')
  set_map('n', '<space>i', vim.lsp.buf.implementation, '[Lsp]: Go to implementation')
  set_map('n', '<C-k>', function()
    vim.lsp.buf.signature_help({ border = 'rounded' })
  end, '[Lsp]: Show signature help')
  set_map('n', '<space>wa', vim.lsp.buf.add_workspace_folder, '[Lsp]: Add workspace')
  set_map('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, '[Lsp]: Remove workspace')
  set_map('n', '<space>wl', function()
    vim.print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[Lsp]: List workspaces')
  set_map('n', '<space>D', vim.lsp.buf.type_definition, '[Lsp]: Go to type definition')
  set_map('n', '<space>rn', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<f2>', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<space>ca', vim.lsp.buf.code_action, '[Lsp]: Code Actions')
  set_map('n', 'gr', vim.lsp.buf.references, '[Lsp]: Go to references')
  set_map('n', '<space>f', function()
    vim.lsp.buf.format({ async = false })
    vim.cmd.retab()
    vim.cmd.write()
  end, '[Lsp]: Format buffer')
  set_map('n', '<space>ci', vim.lsp.buf.incoming_calls, '[Lsp]: Incoming Calls')
  set_map('n', '<space>co', vim.lsp.buf.outgoing_calls, '[Lsp]: Outgoing Calls')

  set_map('n', '<space>sw', function()
    vim.lsp.buf.workspace_symbol('')
  end, '[Lsp] Open workspace symbols')
  set_map('n', '<space>sd', function()
    vim.lsp.buf.document_symbol({})
  end, '[Lsp] Open document symbols')
  set_map('n', 'gO', function()
    vim.lsp.buf.document_symbol()
  end, '[Lsp] Open document symbols')
end

-- Add keymaps on lsp attach
vim.api.nvim_create_autocmd('LspAttatch', {
  ---Add keymaps for lsp attached
  ---@param opts vim.api.keyset.create_autocmd.callback_args
  callback = function(opts)
    local clientId = opts.data.clientId
    local client = vim.lsp.get_client_by_id(clientId)
    local buffer = opts.buf

    if not client then
      return
    end

    set_lsp_keys(client, buffer)
  end
})
