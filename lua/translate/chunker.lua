---@class translate.AlignResult
---@field items string[]
---@field ranges translate.Range[]

local M = {}

---@param items string[]
---@param ranges translate.Range[]
---@return translate.AlignResult
M.to_eol = function(items, ranges)
  local out = { items = {}, ranges = {} }
  for i, item in ipairs(items) do
    out.items[i] = item
    local r = ranges[i]
    if r then out.ranges[i] = { srow = r.srow, scol = r.scol, erow = r.srow, ecol = 0 } end
  end
  return out
end

---@param items string[]
---@param ranges translate.Range[]
---@return translate.AlignResult
M.to_below = function(items, ranges) return { items = items, ranges = ranges } end

return M
