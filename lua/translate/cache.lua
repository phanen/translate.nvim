---@type table<string, string>
local cache = {}

local M = {}

---@param api_type string
---@param text string
---@param from string
---@param to string
---@return string?
M.get = function(api_type, text, from, to)
  local key = api_type .. '|' .. from .. '|' .. to .. '|' .. text
  return cache[key]
end

---@param api_type string
---@param text string
---@param from string
---@param to string
---@param translation string
M.set = function(api_type, text, from, to, translation)
  local key = api_type .. '|' .. from .. '|' .. to .. '|' .. text
  cache[key] = translation
end

M.clear = function() cache = {} end

---@return integer
M.size = function()
  local n = 0
  for _ in pairs(cache) do
    n = n + 1
  end
  return n
end

return M
