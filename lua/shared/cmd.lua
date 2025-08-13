-- Clean search highlight (ctrl-l)
vim.api.nvim_create_user_command('CleanSearch', function ()
  vim.cmd(':nohlsearch')
end, { desc = 'Clean search highlight', bar = true })

-- Clean all carriage return symbols
vim.api.nvim_create_user_command('CleanCR', function ()
  vim.cmd([[
    try
      silent exec '%s/\r$//g'
    catch
    endtry
  ]])
end, { desc = 'Clean carriage return characters', bar = true })

-- Clean all trailing spaces
vim.api.nvim_create_user_command('CleanTrailingSpaces', function ()
  vim.cmd([[silent exec '%s/\s\+$//e']])
end, { desc = 'Clean empty characters at the end of the line', bar = true })

-- Repeatable move commands
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMove', function ()
  require('utils.repeatable_move').repeat_last_move()
end, { desc = '[Repeatable] Repeat last move', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveOpposite', function ()
  require('utils.repeatable_move').repeat_last_move_opposite()
end, { desc = '[Repeatable] Repeat last move opposite', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveNext', function ()
  require('utils.repeatable_move').repeat_last_move_next()
end, { desc = '[Repeatable] Repeat last move in forward direction', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMovePrevious', function ()
  require('utils.repeatable_move').repeat_last_move_previous()
end, { desc = '[Repeatable] Repeat last move in backward direction', bar = true, bang = true })

-- Maps normal, visual and o-pending at the same time
vim.api.nvim_create_user_command('NXOnoremap', 'nnoremap <args><Bar>xnoremap <args><Bar>onoremap <args>', { nargs = 1, desc = '[Nvim] Map normal, visual and operation pending' })
-- Make search consistent
vim.cmd.NXOnoremap([[<expr>n (v:searchforward ? 'n' : 'N').'zv']])
vim.cmd.NXOnoremap([[<expr>N (v:searchforward ? 'N' : 'n').'zv']])

-- Search in browser
vim.api.nvim_create_user_command('BSearch', function (args)
  local first = args.fargs[1]
  local engine = string.gsub(first, '@', '')
  local search = require('utils.browser_search')
  if string.sub(first, 1, 1) == '@' and search.is_valid_engine(engine) then
    search.search_browser(
      table.concat({ unpack(args.fargs, 2) }, ' '),
      engine
    )

    return
  end

  search.search_browser(
    table.concat(args.fargs, ' ')
  )
end, {
  desc = 'Search in browser',
  bang = true,
  -- bar = true,
  nargs = '+',
  complete = function (args)
    local engines = { '@google', '@bing', '@duckduckgo', '@wikipedia', '@brave', '@yandex', '@github' }
    if type(args) == 'string' and #args > 0 then
      local matched = vim.tbl_filter(function (engine)
        local _, matches = string.gsub(engine, args, '')
        return matches > 0
      end, engines)

      return #matched > 0 and matched or engines
    end

    return engines
  end
})
