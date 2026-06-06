---@class translate.Spec
---@field text string[]

---@type table<string, translate.Spec>
local specs = {
  markdown = { text = { 'inline' } },
  lua = { text = { 'comment' } },
  c = { text = { 'comment' } },
  python = { text = { 'comment' } },
  vim = { text = { 'comment' } },
  vimdoc = { text = { 'comment' } },
  text = { text = {} },
  generic = { text = { 'comment' } },
}

local M = {}

---@param ft string?
---@return translate.Spec
M.get = function(ft) return (ft and specs[ft]) or specs.generic end

---@param ft string?
---@return string
M.query = function(ft)
  local lines = {}
  for _, t in ipairs(M.get(ft).text) do
    lines[#lines + 1] = ('(%s) @text.%s'):format(t, t)
  end
  return table.concat(lines, '\n')
end

---@param ft string?
---@return boolean
M.has_captures = function(ft) return #M.get(ft).text > 0 end

return M
