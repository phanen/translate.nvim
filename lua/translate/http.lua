---@class translate.HttpOpts
---@field url string
---@field method string?
---@field headers table<string, string>?
---@field body string?
---@field timeout integer?

---@alias translate.HttpTransport fun(opts: translate.HttpOpts, cb: fun(status: integer, body: string))

---@type translate.HttpTransport?
local transport

local M = {}

---@param fn translate.HttpTransport
M.set_transport = function(fn) transport = fn end

---@return translate.HttpTransport?
M.transport = function() return transport end

local default_transport = function(opts, cb)
  local args = { 'curl', '-sS', '-L', '-X', opts.method or 'GET', '-w', '\n%{http_code}' }
  for k, v in pairs(opts.headers or {}) do
    args[#args + 1] = '-H'
    args[#args + 1] = ('%s: %s'):format(k, v)
  end
  if opts.body then
    args[#args + 1] = '--data-binary'
    args[#args + 1] = opts.body
  end
  if opts.timeout then
    args[#args + 1] = '--max-time'
    args[#args + 1] = tostring(opts.timeout / 1000)
  end
  args[#args + 1] = opts.url
  local out = vim.system(args, { text = true }):wait()
  local raw = out.stdout or ''
  local body, status = raw, 0
  local last_nl = raw:find('\n[^\n]*$')
  if last_nl then
    body = raw:sub(1, last_nl - 1)
    local code = tonumber(raw:sub(last_nl + 1))
    if code then status = math.floor(code) end
    if status == 0 then status = (out.code or 0) end
  end
  cb(status, body)
end

---@param opts translate.HttpOpts
---@return integer status
---@return string body
M.fetch = function(opts)
  local t = transport or default_transport
  local status, body ---@type integer?, string?
  t(opts, function(s, b)
    status = s
    body = b
  end)
  assert(status ~= nil and body ~= nil, 'http transport must be synchronous')
  return status, body
end

return M
