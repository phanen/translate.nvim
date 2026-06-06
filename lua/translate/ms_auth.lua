---@class translate.MsToken
---@field token string
---@field expires_at number  -- ms epoch

---@type translate.MsToken?
local cached

local M = {}

---@return string?
M.fetch = function()
  if cached and cached.expires_at > vim.uv.now() then return cached.token end
  local http = require('translate.http')
  local status, body = http.fetch({
    url = 'https://edge.microsoft.com/translate/auth',
    method = 'GET',
    headers = {},
    body = nil,
  })
  if status < 200 or status >= 300 or not body or body == '' then return nil end
  cached = { token = body, expires_at = vim.uv.now() + 8 * 60 * 1000 }
  return cached.token
end

---@param token string?
M.set = function(token)
  if not token or token == '' then
    cached = nil
  else
    cached = { token = token, expires_at = vim.uv.now() + 8 * 60 * 1000 }
  end
end

return M
