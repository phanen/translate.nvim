---@class translate.TransOpts
---@field batchSize integer?
---@field batchLength integer?

local M = {}

---@param api translate.Api
---@param segments string[]
---@param opts translate.BatchOpts?
---@param cb fun(results: string[]?)
---@param http_fetch fun(opts: translate.HttpOpts, cb: fun(status: integer, body: string))
---@param on_segment? fun(orig: integer, translation: string, source: string)
M.handle_async = function(api, segments, opts, cb, http_fetch, on_segment)
  local batch = require('translate.batch')
  local req = require('translate.req')
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

  if #to_fetch == 0 then
    cb(results)
    return
  end

  local chunks = batch.chunk(to_fetch, opts)
  local pos = 0
  local function run_chunk(idx)
    local chunk = chunks[idx]
    if not chunk then
      cb(results)
      return
    end
    local gen = req.genReqFuncs[api.apiType]
    assert(gen, ('unknown api type: %s'):format(api.apiType))
    local text = table.concat(chunk, '\n')
    local url, init = gen(api, text)
    http_fetch({
      url = url,
      method = init.method,
      headers = init.headers,
      body = init.body,
      timeout = api.httpTimeout,
    }, function(status, body)
      if status < 200 or status >= 300 then
        error(('http error %d: %s'):format(status, body))
        return
      end
      ---@cast body string
      local ok, res = pcall(vim.json.decode, body)
      if not ok then
        local preview = body:sub(1, 200)
        error(('non-json response from %s: %s'):format(api.apiType, preview))
        return
      end
      ---@cast res table
      local parsed = parse.parseTransRes(res, api)
      local translation = parsed[1] and parsed[1][1] or ''
      for j, s in ipairs(chunk) do
        local orig = idx_map[pos + j]
        results[orig] = translation
        if translation ~= '' then
          cache.set(api.apiType, s, api.from or '', api.to or '', translation)
        end
        if on_segment then on_segment(orig, translation, s) end
      end
      pos = pos + #chunk
      run_chunk(idx + 1)
    end)
  end
  run_chunk(1)
end

---@param api translate.Api
---@param segments string[]
---@param opts translate.BatchOpts?
---@return string[]
M.handle = function(api, segments, opts)
  local http = require('translate.http')
  local done = false
  local results ---@type string[]?
  M.handle_async(api, segments, opts, function(r)
    results = r
    done = true
  end, function(o, cb2)
    local s, b = http.fetch(o)
    cb2(s, b)
  end)
  vim.wait(5000, function() return done end, 10)
  return results or {}
end

return M
