-- Cursor based scroll
-- Combine with: "editor.cursorSmoothCaretAnimation": "on"
-- Set an appropriate jumpStep value. 8 seems to be on the sweet spot.
-- Do not mix 'viewPortCenter' with "editor.smoothScrolling": true
-- Also notice, "editor.smoothScrolling" makes <c-f>, <c-b>, <c-u> and <c-d>
-- very yanky. Even with regular up/down, scroll sometimes is not very precise
-- Ref: https://stackoverflow.com/questions/47040925/microsoft-vs-code-jump-10-lines-vertically-at-once/48568520#48568520


local throttle = require('utils.throttle').throttle
-- How many lines to move each key press
local jumpStep = 8
-- throttle delay
local delay = 50 -- or 40
-- helpers
-- local halfJump = math.floor(jumpStep / 2)
-- local doubleJump = jumpStep * 2

-- --- Get current line from vscode as it updates faster than nvim `line('.')`
-- --- @return integer Line number where cursor is located
-- local getCurrentLine = function ()
--   ---@type integer | vim.NIL
--   local line = vscode.eval([[
--     return vscode.window.activeTextEditor?.selection?.active?.line ||
--       vscode.window.activeTextEditor?.selection?.start?.line
--   ]])

--   -- Fallback
--   if line == vim.NIL then
--     return vim.fn.line('.')
--   end

--   -- vscode use 0 based index (as god intended)
--   return line + 1
-- end

-- local upScrollCallback =  throttle(delay, function ()
--   -- Current cursor line
--   local current = getCurrentLine()

--   -- Already reached top
--   if current == 1 then
--     return
--   end

--   -- Total lines (end of file)
--   local eof = vim.fn.line('$')

--   -- Scroll half jumpStep when close to the top or close to the bottom
--   if current <= doubleJump or current >= (eof - doubleJump) then
--     vscode.call('editorScroll', { args = { by = 'line', to = 'up', value = halfJump, revealCursor = true }})
--     vscode.call('cursorMove', { args = { to = 'up', value = halfJump }})
--   else
--     vscode.call('editorScroll', { args = { by = 'line', to = 'up', value = jumpStep, revealCursor = true }})
--     vscode.call('cursorMove', { args = { to = 'up', value = jumpStep }})
--   end

--   -- Below is an alternative move for 'cursorMove'
--   -- It does not play nice with `editor.smoothScrolling` when reaching the top.
--   -- Jump is less precise.

--   -- Get visible number of lines. This varies due to zoom, windows, etc.
--   -- -@type [VsCodeRange, VsCodeRange]
--   -- local visibleRanges = vscode.eval('return vscode.window.activeTextEditor.visibleRanges')[1]
--   -- local visibleLines = (visibleRanges[2].line - visibleRanges[1].line) + 1 -- 0 based index

--   -- Use 'up' movement when the current line is equal or less than the remaining visible lines to the top.
--   -- Using 'viewPortCenter' prevents the cursor from reaching the top.
--   -- if current <= visibleLines then
--   --   vscode.call('cursorMove', { args = { to = 'up', value = jumpStep }})
--   -- else
--   --   vscode.call('cursorMove', { args = { to = 'viewPortCenter', value = jumpStep }})
--   -- end
-- end)

-- local downScrollCallback = throttle(delay, function ()
--   -- Current cursor line
--   local current = getCurrentLine()
--   -- Total lines (end of file)
--   local eof = vim.fn.line('$')

--   -- Already reached bottom
--   if current == eof then
--     -- Should I?
--     -- vim.cmd.normal('zz')
--     return
--   end

--   -- If at the top and lest than twice jumpStep,
--   -- only move cursor but do not scroll buffer
--   if current <= doubleJump then
--     vscode.call('cursorMove', { args = { to = 'down', value = halfJump }})
--     -- if current is almost at the bottom,
--     -- move half the jumpStep to ease the scroll
--   elseif current >= (eof - doubleJump) then
--     vscode.call('editorScroll', { args = { by = 'line', to = 'down', value = halfJump, revealCursor = true }})
--     vscode.call('cursorMove', { args = { to = 'down', value = halfJump }})
--   else
--     -- Scroll by jumpStep
--     vscode.call('editorScroll', { args = { by = 'line', to = 'down', value = jumpStep, revealCursor = true }})
--     vscode.call('cursorMove', { args = { to = 'down', value = jumpStep }})
--   end

--   -- Below is an alternative move for 'cursorMove'
--   -- It does not play nice with `editor.smoothScrolling` when reaching the bottom.
--   -- Jump is less precise.

--   -- Get visible number of lines. This varies due to zoom, windows, etc.
--   -- -@type [VsCodeRange, VsCodeRange]
--   -- local visibleRanges = vscode.eval('return vscode.window.activeTextEditor.visibleRanges')[1]
--   -- local visibleLines = (visibleRanges[2].line - visibleRanges[1].line) + 1 -- 0 based index

--   -- Use 'down' movement when the current line is equal or more than the remaining visible lines to the bottom.
--   -- Using 'viewPortCenter' prevents the cursor from reaching the bottom.
--   -- if line >= (eof - visibleLines) then
--   --   -- Ease when reaching the bottom
--   --   vscode.call('cursorMove', { args = { to = 'down', value = jumpStep }})
--   -- else
--   --   vscode.call('cursorMove', { args = { to = 'viewPortCenter', value = jumpStep }})
--   -- end
-- end)

---Initialize the scroll object
---@param opts? { jumpStep: integer; delay: integer }
local registerScroll = function (opts)
  opts = opts or {}

  require('vscode').eval([[
    if (globalThis._vscode_scroll) return;

    const jumpStep = args?.jumpStep ?? 8;

    // Uncomment below and wrap scroll_up/scroll_down functions
    // to decrease the speed of the scroll.

    // const delay = args?.delay ?? 30; // 40;

    // const throttleFn = (fn, time) => {
    //   let timerFlag = null; // Variable to keep track of the timer

    //   // Returning a throttled version
    //   return (...args) => {
    //     if (timerFlag !== null) { // If there is a timer currently running
    //       return
    //     }

    //     fn(...args); // Execute the main function
    //     timerFlag = setTimeout(() => { // Set a timer to clear the timerFlag after the specified delay
    //       timerFlag = null; // Clear the timerFlag to allow the main function to be executed again
    //     }, time);
    //   };
    // };

    const get_scroll_info = () => {
      const scroll = globalThis._vscode_scroll;
      if (!scroll) return

      const current = scroll.get_curr_line();
      const eof = scroll.get_total_lines();
      const range = vscode.window.activeTextEditor.visibleRanges[0];
      return { current, eof, range };
    };

    const scroll_down = () => {
      const scroll = globalThis._vscode_scroll;
      if (!scroll) return

      const current = scroll.get_curr_line();
      const eof = scroll.get_total_lines();

      if (current === eof) {
        return;
      }

      const { doubleJump, halfJump } = scroll;

      if (current <= doubleJump) {
        vscode.commands.executeCommand('cursorMove', {
          to: 'down', value: scroll.halfJump,
        });
      } else if (current >= (eof - doubleJump)) {
        vscode.commands.executeCommand('editorScroll', {
          to: 'down', by: 'line', value: scroll.halfJump, revealCursor: true,
        });
        vscode.commands.executeCommand('cursorMove', {
          to: 'down', value: scroll.halfJump,
        });
      } else {
        vscode.commands.executeCommand('editorScroll', {
          to: 'down', by: 'line', value: scroll.jumpStep, revealCursor: true,
        });
        vscode.commands.executeCommand('cursorMove', {
          to: 'down', value: scroll.jumpStep,
        });
      }
    };

    const scroll_up = () => {
      const scroll = globalThis._vscode_scroll;
      if (!scroll) return

      const current = scroll.get_curr_line();

      if (current === 1) {
        return;
      }

      const eof = scroll.get_total_lines();
      const { doubleJump, halfJump } = scroll;

      if ((current <= doubleJump) || (current >= (eof - doubleJump))) {
        vscode.commands.executeCommand('editorScroll', {
          to: 'up', by: 'line', value: scroll.halfJump, revealCursor: true,
        });
        vscode.commands.executeCommand('cursorMove', {
          to: 'up', value: scroll.halfJump,
        });
      } else {
        vscode.commands.executeCommand('editorScroll', {
          to: 'up', by: 'line', value: scroll.jumpStep, revealCursor: true,
        });
        vscode.commands.executeCommand('cursorMove', {
          to: 'up', value: scroll.jumpStep,
        });
      }
    };

    globalThis._vscode_scroll = {
      jumpStep,
      halfJump: Math.floor(jumpStep / 2),
      doubleJump: jumpStep * 2,
      scroll_down,
      scroll_up,
      // scroll_down: throttleFn(scroll_down, delay),
      // scroll_up: throttleFn(scroll_up, delay),
      get_curr_line: () => {
        const line = vscode.window.activeTextEditor?.selection?.active?.line ||
          vscode.window.activeTextEditor?.selection?.start?.line;

        if (line != null) return line + 1
      },
      get_total_lines: () => {
        return vscode.window.activeTextEditor?.document?.lineCount;
      },
      get_scroll_info,
    }
  ]], {
    args = {
      jumpStep = opts.jumpStep,
      -- delay = opts.delay,
    }
  })
end

-- registerScroll({ jumpStep = jumpStep })

local scroll_down = throttle(delay, function ()
  local ctrl_d = vim.api.nvim_replace_termcodes('<C-d>', true, true, true)
  vim.fn.feedkeys(ctrl_d, 'normal')
  require('vscode').eval([[
    vscode.commands.executeCommand('editorScroll', {
      to: 'down', by: 'halfPage',
    });
  ]])
end)

local scroll_up = throttle(delay, function ()
  local ctrl_u = vim.api.nvim_replace_termcodes('<C-u>', true, true, true)
  vim.fn.feedkeys(ctrl_u, 'normal')
  require('vscode').eval([[
    vscode.commands.executeCommand('editorScroll', {
      to: 'up', by: 'halfPage',
    });
  ]])
end)

return {
  registerScroll = registerScroll,
  scroll_up = scroll_up,
  scroll_down = scroll_down,
}
