---@alias translate.SourceMode
---| 'v'
---| 'V'
---| '\22'

local fn = vim.fn
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

return M
