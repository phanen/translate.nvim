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

---@return string[]?, translate.Range[]?
M.collect = function()
  local mode = api.nvim_get_mode().mode
  if mode:match('[vV\22]') then
    local s = fn.getpos('.')
    local v = fn.getpos('v')
    local regtype = mode == 'V' and 'V' or (mode == '\22' and '\22' or 'v')
    local srow, scol, vrow, vcol = s[2], s[3] - 1, v[2], v[3] - 1
    local srow0 = math.min(srow, vrow)
    local scol0 = srow0 == srow and scol or (srow0 == vrow and vcol or 0)
    local erow = math.max(srow, vrow)
    local ecol = erow == srow and scol or (erow == vrow and vcol or 0)
    local raw = M.range(srow0, scol0, erow, ecol, regtype)
    local full = table.concat(raw, '\n')
    return { full }, { { srow = srow0, scol = scol0, erow = erow, ecol = ecol } }
  else
    local word = M.cword()
    if word == '' then return nil, nil end
    local cursor = api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    return { word }, { { srow = row, scol = col, erow = row, ecol = col + #word } }
  end
end

return M
