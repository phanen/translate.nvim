---@class translate.Range
---@field srow integer
---@field scol integer
---@field erow integer
---@field ecol integer

---@class translate.Node
---@field id integer
---@field text string
---@field range translate.Range

local M = {}

---@param buf integer
---@param ft string?
---@return translate.Node[]?
M.extract = function(buf, ft)
  local spec = require('translate.spec')
  buf = buf or 0
  local lang = ft and ft ~= '' and vim.treesitter.language.get_lang(ft) or nil
  if not spec.has_captures(ft) or not lang then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    return {
      {
        id = 0,
        text = table.concat(lines, '\n'),
        range = { srow = 0, scol = 0, erow = #lines, ecol = 0 },
      },
    }
  end
  if not pcall(vim.treesitter.language.add, lang) then return nil end
  local parser = vim.treesitter.get_parser(buf, lang, { error = false })
  if not parser then return nil end
  local trees = parser:parse()
  if not trees then return nil end
  local tree = trees[1]
  if not tree then return nil end
  local query = vim.treesitter.query.parse(lang, spec.query(ft))
  local nodes = {}
  local seen = {}
  local id = 0
  for _, match in query:iter_matches(tree:root(), buf, 0, -1) do
    for _, nodes_list in pairs(match) do
      for _, node in ipairs(nodes_list) do
        local sr, sc, er, ec = node:range()
        local key = ('%d:%d-%d:%d'):format(sr, sc, er, ec)
        if not seen[key] then
          seen[key] = true
          nodes[#nodes + 1] = {
            id = id,
            text = vim.treesitter.get_node_text(node, buf),
            range = { srow = sr, scol = sc, erow = er, ecol = ec },
          }
          id = id + 1
        end
      end
    end
  end
  table.sort(nodes, function(a, b)
    if a.range.srow ~= b.range.srow then return a.range.srow < b.range.srow end
    return a.range.scol < b.range.scol
  end)
  for i, n in ipairs(nodes) do
    n.id = i - 1
  end
  return nodes
end

---@param nodes translate.Node[]
---@return string
M.batch = function(nodes)
  local parts = {}
  for _, n in ipairs(nodes) do
    parts[#parts + 1] = ('<a i=%d>%s</a>'):format(n.id, n.text)
  end
  return table.concat(parts)
end

---@param response string
---@return table<integer, string>
M.restore = function(response)
  local result = {}
  for id, text in response:gmatch('<a i=(%d+)>(.-)</a>') do
    result[tonumber(id)] = text
  end
  return result
end

---@param texts string[]
---@return string[]
M.strip_prefix = function(texts)
  if #texts < 2 then return texts end
  local prefix = texts[1]
  for i = 2, #texts do
    local t = texts[i]
    local n = 0
    while n < #prefix and n < #t and prefix:byte(n + 1) == t:byte(n + 1) do
      n = n + 1
    end
    prefix = prefix:sub(1, n)
    if prefix == '' then break end
  end
  if prefix == '' then return texts end
  local trimmed = prefix:gsub('%s+$', '')
  if trimmed == '' then return texts end
  local result = {}
  for _, t in ipairs(texts) do
    result[#result + 1] = t:sub(#trimmed + 1):gsub('^%s+', '')
  end
  return result
end

return M
