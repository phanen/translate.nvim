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
  local cache = require('translate.cache')

  local results, to_fetch, idx_map = {}, {}, {}
  for i, s in ipairs(segments) do
    local hit = cache.get(api.apiType, s, api.from or '', api.to or '')
    if hit then
      results[i] = hit
    else
      to_fetch[#to_fetch + 1] = s
      idx_map[#idx_map + 1] = i
    end
  end

  if #to_fetch == 0 then return results end

  local chunks = batch.chunk(to_fetch, opts)
  local pos = 0
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
    ---@cast body string
    local res = vim.json.decode(body)
    local parsed = parse.parseTransRes(res, api)
    local translation = parsed[1] and parsed[1][1] or ''
    for j, s in ipairs(chunk) do
      local orig = idx_map[pos + j]
      results[orig] = translation
      cache.set(api.apiType, s, api.from or '', api.to or '', translation)
    end
    pos = pos + #chunk
  end

  return results
end

return M
