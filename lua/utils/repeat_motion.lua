---@class RepeatOptions
---@field fn function Function to make repeatable with motions

---@class RepeatPair
---@field keys string Key to be used when creating a map
---@field prefix_forward string|nil prefix key to be used on forward binding
---@field prefix_backward string|nil prefix key to be used on backward binding
---@field mode string|table|nil Mode to add keymaps to. Defaults to normal.
---@field on_forward function Callback when moving forward
---@field on_backward function Callback when moving backward
---@field desc_forward string Keymap description for forward binding
---@field desc_backward string Keymap description for backward binding

---@class MotionKeys
---@field move_forward string Key to be used when repeating a direction motion
---@field move_backward string Key to be used when repeating a direction motion

local repeat_motion = {}

---Creates repeatable function using nvim-treesitter-textobjects
---It accepts an object that uses a `forward` for directionality
---@param options RepeatOptions
---@return fun(opts: { forward: boolean }|table): nil
repeat_motion.repeat_direction = function(options)
  local func = require('utils.repeatable_move')
    .make_repeatable_move(options.fn)
  return func
end

---Creates dot repeatable motions using vim-repeat and repeatable.vim
---@param map_string string string to be use for mapping e.g. "mode lhs rhs"
repeat_motion.repeat_dot = function(map_string)
  -- Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  -- vim.cmd.Repeatable('nnoremap <silent>[g :tabprevious')
  vim.cmd.Repeatable(map_string)
end

---Create a pair of maps. Square brackers are used by default '[' ']'
---Maps are repeatable through the motion keys set by `set_motion_keys`
---Depends of nvim-treesitter-textobjects
---@param options RepeatPair
repeat_motion.repeat_pair = function(options)
  local prefix_forward = options.prefix_forward or ']'
  local prefix_backward = options.prefix_backward or '['
  local mode = options.mode or 'n'
  local keymap_forward = prefix_forward .. options.keys
  local keymap_backward = prefix_backward .. options.keys
  local forward, backward  = require('utils.repeatable_move')
    .make_repeatable_move_pair(options.on_forward, options.on_backward)

  -- Forward map
  vim.keymap.set(mode, keymap_forward, forward, { desc = options.desc_forward, noremap = true })

  -- Backward map
  vim.keymap.set(mode, keymap_backward, backward, { desc = options.desc_backward, noremap = true })
end

---Sets the keymaps to use as motions. By default uses ',' and ';' for similar behavior of t, T, f and F.
---Other maps can be used such as '<' and '>'
---Depends of nvim-treesitter-textobjects
---@param opts MotionKeys|nil
repeat_motion.set_motion_keys = function (opts)
  local options = vim.tbl_deep_extend('force', { move_forward = ';', move_backward = ',' }, opts or {})
  local repeatable_move = require('utils.repeatable_move')
  local nxo = { 'n', 'x', 'o' }

  -- Set repeatable motions with ; and ,
  -- ensure ; goes forward and , goes backward regardless of the last direction
  vim.keymap.set(nxo, options.move_forward, repeatable_move.repeat_last_move_next)
  vim.keymap.set(nxo, options.move_backward, repeatable_move.repeat_last_move_previous)

  -- vim way: ; goes to the direction you were moving.
  -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
  -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

  -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
  vim.keymap.set({ "n", "x", "o" }, "f", repeatable_move.builtin_f_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "F", repeatable_move.builtin_F_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "t", repeatable_move.builtin_t_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "T", repeatable_move.builtin_T_expr, { expr = true })
end

return repeat_motion

