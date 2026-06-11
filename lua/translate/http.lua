---@class translate.HttpOpts
---@field url string
---@field method string?
---@field headers table<string, string>?
---@field body string?
---@field timeout integer?

---@alias translate.HttpTransport fun(opts: translate.HttpOpts, cb: fun(status: integer, body: string))
---@alias translate.HttpAsync fun(opts: translate.HttpOpts, cb: fun(status: integer, body: string))

---@type translate.HttpTransport?
local transport

local M = {}

---@param fn translate.HttpTransport
M.set_transport = function(fn) transport = fn end

---@return translate.HttpTransport?
M.transport = function() return transport end

---@param raw string?
---@param code integer?
---@return integer status
---@return string body
local parse_response = function(raw, code)
  local out_raw = raw or ''
  local body, status = out_raw, code or 0
  local last_nl = out_raw:find('\n[^\n]*$')
  if last_nl then
    body = out_raw:sub(1, last_nl - 1)
    local http_code = tonumber(out_raw:sub(last_nl + 1))
    if http_code then status = math.floor(http_code) end
    if status == 0 then status = code or 0 end
  end
  return status, body
end

---@param args string[]
---@param opts translate.HttpOpts
---@return string[]
local build_curl_args = function(args, opts)
  args[#args + 1] = '-sS'
  args[#args + 1] = '-L'
  args[#args + 1] = '-X'
  args[#args + 1] = opts.method or 'GET'
  args[#args + 1] = '-w'
  args[#args + 1] = '\n%{http_code}'
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
  return args
end

---@param opts translate.HttpOpts
---@param cb fun(status: integer, body: string)
M.default_async = function(opts, cb)
  local args = build_curl_args({ 'curl' }, opts)
  vim.system(
    args,
    { text = true },
    vim.schedule_wrap(function(obj) cb(parse_response(obj.stdout, obj.code)) end)
  )
end

local default_transport = function(opts, cb)
  local args = build_curl_args({ 'curl' }, opts)
  local out = vim.system(args, { text = true }):wait()
  cb(parse_response(out.stdout, out.code))
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

---@param opts translate.HttpOpts
---@param cb fun(status: integer, body: string)
M.fetch_async = function(opts, cb)
  local t = transport
  if t then
    t(opts, cb)
  else
    M.default_async(opts, cb)
  end
end

return M
