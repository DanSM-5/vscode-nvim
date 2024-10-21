---@class RepeatOptions
---@field forward boolean Initial movement of motion
---@field on_forward function Callback when moving forward
---@field on_backward function Callback when moving backward

---@class MirrorMap
---@field keys string Key to be used when creating a map
---@field prefix_forward string|nil prefix key to be used on forward binding
---@field prefix_backward string|nil prefix key to be used on backward binding
---@field mode string|table|nil Mode to add keymaps to. Defaults to normal.
---@field on_forward function Callback when moving forward
---@field on_backward function Callback when moving backward
---@field desc_forward string Keymap description for forward binding
---@field desc_backward string Keymap description for backward binding

local repeat_motion = {}

---Creates repeatable motions for ',' and ';' using demicolon plugin.
---The on_forward and on_backward will be used for directionality of the movement
---The forward prop is important as it signals the initial direction of the motion
---and it is used by demicolon (it mutates the ref object) to keep track of the directionality
---@param options RepeatOptions
repeat_motion.repeat_pair = function(options)
  local repeatably_do = require('demicolon.jump').repeatably_do
  local repeat_func = function()
    ---Main repeatable logic
    ---@param opts RepeatOptions
    repeatably_do(function(opts)
      if opts.forward == nil or opts.forward then
        opts.on_forward()
      else
        opts.on_backward()
      end
    end, options)
  end

  return repeat_func
end

---Creates dot repeatable motions using vim-repeat and repeatable.vim
---@param map_string string string to be use for mapping e.g. "mode lhs rhs"
repeat_motion.repeat_dot = function(map_string)
  -- Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  -- vim.cmd.Repeatable('nnoremap <silent>[g :tabprevious')
  vim.cmd.Repeatable(map_string)
end

---Create a pair of maps. Square brackers are used by default '[' ']'
---@param options MirrorMap
repeat_motion.mirror_map = function(options)
  local prefix_forward = options.prefix_forward or ']'
  local prefix_backward = options.prefix_backward or '['
  local mode = options.mode or 'n'
  local keymap_forward = prefix_forward .. options.keys
  local keymap_backward = prefix_backward .. options.keys

  -- Forward map
  vim.keymap.set(mode, keymap_forward, repeat_motion.repeat_pair({
    forward = true,
    on_forward = options.on_forward,
    on_backward = options.on_backward
  }), { desc = options.desc_forward, noremap = true })

  -- Backward map
  vim.keymap.set(mode, keymap_backward, repeat_motion.repeat_pair({
    forward = false,
    on_forward = options.on_forward,
    on_backward = options.on_backward
  }), { desc = options.desc_backward, noremap = true })
end

return repeat_motion

