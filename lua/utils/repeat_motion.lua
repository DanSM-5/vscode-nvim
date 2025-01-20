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
---@field bufnr? integer Buffer to attach keymap

---@class MotionKeys
---@field move_forward string Key to be used when repeating a direction motion
---@field move_backward string Key to be used when repeating a direction motion

local get_repeat_module = function ()
  if vim.env.NVIM_APPNAME == 'vscode-nvim' then
    return require('utils.repeatable_move')
  end

  return require('nvim-treesitter.textobjects.repeatable_move')
end

---@class RepeatMotion
---@field repeat_direction fun(options: RepeatOptions): fun(opts: { forward: boolean }|table): nil
---@field repeat_action function|nil DO NOT USE DIRECTLY
---@field repeat_dot_map fun(map_string: string): nil
---@field repeat_pair fun(options: RepeatPair): nil
---@field set_motion_keys fun(opts: MotionKeys|nil): nil
local repeat_motion = {}
-- Not listed to preserve generics
-- -@field create_repeatable_pair fun(forward: TForward, backward: TBackward): TForward, TBackward
-- -@field create_repeatable_func fun(fn: function): function

---Creates repeatable function using nvim-treesitter-textobjects
---It accepts an object that uses a `forward` for directionality
---@param options RepeatOptions
---@return fun(opts: { forward: boolean }|table): nil
repeat_motion.repeat_direction = function(options)
  local func = get_repeat_module()
    .make_repeatable_move(options.fn)
  return func
end

---Creates dot repeatable motions using vim-repeat and repeatable.vim
---@param map_string string string to be use for mapping e.g. "mode lhs rhs"
repeat_motion.repeat_dot_map = function(map_string)
  -- Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  -- vim.cmd.Repeatable('nnoremap <silent>[g :tabprevious')
  vim.cmd.Repeatable(map_string)
end

---Create dot repeatable function. Requires vim-repeat
---@generic TFunc
---@param fn TFunc Function to repeat
---@return TFunc Function that can be repeated with dot
repeat_motion.create_repeatable_func = function (fn)
  return function(...)
    local args = { ... }
    local nargs = select('#', ...)
    vim.go.operatorfunc = "v:lua.require'utils.repeat_motion'.repeat_action"

    repeat_motion.repeat_action = function()
      fn(unpack(args, 1, nargs))
      if vim.fn.exists('*repeat#set') == 1 then
        local action = vim.api.nvim_replace_termcodes(
          string.format('<cmd>call %s()<cr>', vim.go.operatorfunc),
          true,
          true,
          true
        )
        pcall(vim.fn['repeat#set'], action, -1)
      end
    end

    vim.cmd('normal! g@l')
  end
end

---Create a pair of functions that repeat motion forward and backward
---@generic TForward
---@generic TBackward
---@param forward TForward
---@param backward TBackward
---@return TForward
---@return TBackward
repeat_motion.create_repeatable_pair = function (forward, backward)
  local rep_forward, rep_backward = get_repeat_module()
    .make_repeatable_move_pair(forward, backward)

  return rep_forward, rep_backward
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
  local forward, backward  = get_repeat_module()
    .make_repeatable_move_pair(options.on_forward, options.on_backward)

  local forward_opts = { desc = options.desc_forward, noremap = true }
  local backward_opts = { desc = options.desc_forward, noremap = true }

  if options.bufnr ~= nil then
    forward_opts.bufnr = options.bufnr
    backward_opts.bufnr = options.bufnr
  end

  -- Forward map
  vim.keymap.set(mode, keymap_forward, forward, forward_opts)

  -- Backward map
  vim.keymap.set(mode, keymap_backward, backward, backward_opts)
end

---Sets the keymaps to use as motions. By default uses ',' and ';' for similar behavior of t, T, f and F.
---Other maps can be used such as '<' and '>'
---Depends of nvim-treesitter-textobjects
---@param opts MotionKeys|nil
repeat_motion.set_motion_keys = function (opts)
  local options = vim.tbl_deep_extend('force', { move_forward = ';', move_backward = ',' }, opts or {})
  local repeatable_move = get_repeat_module()
  local nxo = { 'n', 'x', 'o' }

  -- Set repeatable motions with ; and ,
  -- ensure ; goes forward and , goes backward regardless of the last direction
  vim.keymap.set(nxo, options.move_forward, repeatable_move.repeat_last_move_next)
  vim.keymap.set(nxo, options.move_backward, repeatable_move.repeat_last_move_previous)

  -- vim way: ; goes to the direction you were moving.
  -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
  -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

  -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
  vim.keymap.set({ 'n', 'x', 'o' }, 'f', repeatable_move.builtin_f_expr, { expr = true })
  vim.keymap.set({ 'n', 'x', 'o' }, 'F', repeatable_move.builtin_F_expr, { expr = true })
  vim.keymap.set({ 'n', 'x', 'o' }, 't', repeatable_move.builtin_t_expr, { expr = true })
  vim.keymap.set({ 'n', 'x', 'o' }, 'T', repeatable_move.builtin_T_expr, { expr = true })
end

return repeat_motion

