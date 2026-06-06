---@class translate.TransOpts
---@field batchSize integer?
---@field batchLength integer?

local M = {}

---@param api translate.Api
---@param segments string[]
---@param opts translate.BatchOpts?
---@return string[]
M.handle = function(api, segments, opts)
  local batch = require('translate.batch')
  local req = require('translate.req')
  local http = require('translate.http')
  local parse = require('translate.parse')

  local chunks = batch.chunk(segments, opts)
  local results = {}
  for _, chunk in ipairs(chunks) do
    local gen = req.genReqFuncs[api.apiType]
    assert(gen, ('unknown api type: %s'):format(api.apiType))
    local text = table.concat(chunk, '\n')
    local url, init = gen(api, text)
    local status, body = http.fetch({
      url = url,
      method = init.method,
      headers = init.headers,
      body = init.body,
      timeout = api.httpTimeout,
    })
    if status < 200 or status >= 300 then error(('http error %d: %s'):format(status, body)) end
    local res = vim.json.decode(body)
    local parsed = parse.parseTransRes(res, api)
    for _, p in ipairs(parsed) do
      results[#results + 1] = p[1]
    end
  end
  return results
end

return M
