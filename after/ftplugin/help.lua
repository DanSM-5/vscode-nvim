
local buf = vim.api.nvim_get_current_buf()

-- Keybindings for help

-- Jump to subject
vim.keymap.set('n', '<cr>', '<c-]>', { noremap = true, buffer = buf, desc = '[Help] Jump to subject' })
-- Go back from last jump
vim.keymap.set('n', '<bs>', '<c-t>', { noremap = true, buffer = buf, desc = '[Help] Go back from last subject' })
-- Next option
vim.keymap.set('n', 'o', "/'\\l\\{2,\\}'<cr>", { noremap = true, buffer = buf, desc = '[Help] Next option' })
-- Previous option
vim.keymap.set('n', 'O', "?'\\l\\{2,\\}'<cr>", { noremap = true, buffer = buf, desc = '[Help] Previous option' })
-- Next subject
vim.keymap.set('n', 's', "/|\\zs\\S\\+\\ze|<cr>", { noremap = true, buffer = buf, desc = '[Help] Next subject' })
-- Previous subject
vim.keymap.set('n', 'S', "?|\\zs\\S\\+\\ze|<cr>", { noremap = true, buffer = buf, desc = '[Help] Previous subject' })


-- Helper bindings for quickfix
-- nnoremap <S-F1>  :cc<CR>
-- nnoremap <F2>    :cnext<CR>
-- nnoremap <S-F2>  :cprev<CR>
-- nnoremap <F3>    :cnfile<CR>
-- nnoremap <S-F3>  :cpfile<CR>
-- nnoremap <F4>    :cfirst<CR>
-- nnoremap <S-F4>  :clast<CR>
