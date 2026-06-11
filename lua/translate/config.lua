---@alias translate.Target
---| 'echo'
---| 'buffer'
---| 'eol'
---| 'below'
---| 'inline'
---| 'replace'

---@class translate.Creds
---@field key string?
---@field region string?
---@field url string?
---@field model string?
---@field systemPrompt string?

---@class translate.Config
---@field target_lang string?
---@field source_lang string?
---@field target translate.Target?
---@field http_timeout integer?
---@field api translate.ApiType?
---@field creds translate.Creds?

local M = {}

---@return translate.Config
M.defaults = function()
  return {
    target_lang = 'zh-Hans',
    source_lang = 'auto',
    target = 'eol',
    http_timeout = 30000,
    api = 'google',
    creds = nil,
  }
end

---@param a translate.Config
---@param b translate.Config?
---@return translate.Config
M.merge = function(a, b)
  local r = {} ---@type translate.Config
  for k, v in pairs(a) do
    r[k] = v
  end
  for k, v in pairs(b or {}) do
    r[k] = v
  end
  return r
end

local valid_targets =
  { echo = true, buffer = true, eol = true, below = true, inline = true, replace = true }

---@param cfg translate.Config
M.validate = function(cfg)
  assert(valid_targets[cfg.target] == true, ('invalid target: %s'):format(tostring(cfg.target)))
  assert(
    type(cfg.target_lang) == 'string' and cfg.target_lang ~= '',
    'target_lang must be a non-empty string'
  )
  assert(
    type(cfg.source_lang) == 'string' and cfg.source_lang ~= '',
    'source_lang must be a non-empty string'
  )
  assert(
    type(cfg.http_timeout) == 'number' and cfg.http_timeout > 0,
    'http_timeout must be a positive number'
  )
  if cfg.api ~= nil then
    local valid_apis =
      { google = true, microsoft = true, openai = true, mymemory = true, baidu = true }
    assert(valid_apis[cfg.api] == true, ('invalid api: %s'):format(tostring(cfg.api)))
  end
end

return M
