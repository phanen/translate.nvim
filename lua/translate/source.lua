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

---@param use_range? boolean  -- true when invoked with a range (:'<,'>)
---@return string[]?, translate.Range[]?
M.collect = function(use_range)
  local mode = api.nvim_get_mode().mode
  local s, v, regtype
  if mode:match('[vV\22]') then
    s = fn.getpos('.')
    v = fn.getpos('v')
    regtype = mode == 'V' and 'V' or (mode == '\22' and '\22' or 'v')
  elseif use_range then
    local lt = fn.getpos("'<")
    local gt = fn.getpos("'>")
    if lt[2] ~= 0 and gt[2] ~= 0 then
      s = lt
      v = gt
      regtype = fn.visualmode()
      if regtype == '' then regtype = 'v' end
    end
  end
  if not s then
    local word = M.cword()
    if word == '' then return nil, nil end
    local cursor = api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    return { word }, { { srow = row, scol = col, erow = row, ecol = col + #word } }
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
