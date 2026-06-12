---@alias translate.SourceMode
---| 'v'
---| 'V'
---| '\22'

local fn = vim.fn
local api = vim.api

local M = {}

---@return string
M.cword = function() return fn.expand('<cword>') end

---@return string
M.cWORD = function() return fn.expand('<cWORD>') end

---@param srow integer  1-based
---@param scol integer  0-based
---@param erow integer  1-based
---@param ecol integer  0-based (exclusive)
---@param mode translate.SourceMode
---@return string[]
M.range = function(srow, scol, erow, ecol, mode)
  return fn.getregion({ 0, srow, scol + 1, 0 }, { 0, erow, ecol + 1, 0 }, {
    type = mode,
    eol = true,
    exclusive = vim.o.sel:sub(1, 1) == 'e',
  })
end

---@param pos1? [integer, integer, integer]
---@param pos2? [integer, integer, integer]
---@return string[]?, translate.Range[]?
M.collect = function(pos1, pos2)
  local s, v, regtype
  if pos1 and pos2 and pos1[2] ~= 0 and pos2[2] ~= 0 then
    s = pos1
    v = pos2
    regtype = fn.visualmode(1)
    if regtype == '' then regtype = 'v' end
  end
  if not s then
    local m = api.nvim_get_mode().mode
    if m:match('[vV\22]') then
      s = fn.getpos('.')
      v = fn.getpos('v')
      regtype = m == 'V' and 'V' or (m == '\22' and '\22' or 'v')
    else
      local word = M.cword()
      if word == '' then return nil, nil end
      local cursor = api.nvim_win_get_cursor(0)
      local row, col = cursor[1] - 1, cursor[2]
      return { word }, { { srow = row, scol = col, erow = row, ecol = col + #word } }
    end
  end
  local raw =
    fn.getregion(s, v, { type = regtype, eol = true, exclusive = vim.o.sel:sub(1, 1) == 'e' })
  local srow0 = math.min(s[2], v[2]) - 1
  local erow = math.max(s[2], v[2]) - 1
  if regtype == 'V' or regtype == '\22' then
    local ranges = {}
    for i, line in ipairs(raw) do
      ranges[i] = { srow = srow0 + i - 1, scol = 0, erow = srow0 + i - 1, ecol = 0 }
    end
    return raw, ranges
  else
    local full = table.concat(raw, '\n')
    return { full }, { { srow = srow0, scol = 0, erow = erow, ecol = 0 } }
  end
end

return M
