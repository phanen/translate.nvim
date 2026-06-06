---@alias translate.ParseResult [string, string]  -- [translation, source_lang]

local M = {}

---@param raw string
---@param use_batch boolean
---@return translate.ParseResult[]
M.parseAIRes = function(raw, use_batch)
  if not raw or raw == '' then return {} end
  if not use_batch then return { { raw, '' } } end

  local s = raw
  s = s:gsub('^%s*```json%s*', ''):gsub('^%s*```%s*', ''):gsub('```%s*$', '')

  local ok, parsed = pcall(vim.json.decode, s)
  if ok and type(parsed) == 'table' then
    local list
    if vim.islist and vim.islist(parsed) then
      list = parsed
    elseif parsed.translations then
      list = parsed.translations
    elseif parsed.segments then
      list = parsed.segments
    end
    if list then
      local r = {}
      for _, item in ipairs(list) do
        r[#r + 1] = {
          tostring(item.text or item.translation or ''),
          tostring(item.sourceLanguage or item.src or ''),
        }
      end
      if #r > 0 then return r end
    end
  end

  local r = {}
  for text in s:gmatch('<[tT][^>]*>(.-)</[tT]>') do
    r[#r + 1] = { text, '' }
  end
  if #r > 0 then return r end

  for line in (s .. '\n'):gmatch('(.-)\n') do
    local _, _, _, text = line:find('^%s*(%d+)%s*|%s*(.+)')
    if text then
      r[#r + 1] = { text, '' }
    elseif line:match('%S') then
      r[#r + 1] = { line, '' }
    end
  end
  return r
end

---@param res table
---@param api translate.Api
---@return translate.ParseResult[]
M.parseTransRes = function(res, api)
  if api.apiType == 'google' then
    local trans = {}
    for _, s in ipairs((res or {}).sentences or {}) do
      trans[#trans + 1] = s.trans
    end
    return { { table.concat(trans, ' '), (res or {}).src or '' } }
  elseif api.apiType == 'microsoft' then
    local r = {}
    for _, item in ipairs(res or {}) do
      local t = {}
      for _, tr in ipairs(item.translations or {}) do
        t[#t + 1] = tr.text
      end
      r[#r + 1] = { table.concat(t, ' '), (item.detectedLanguage or {}).language or '' }
    end
    return r
  elseif api.apiType == 'mymemory' then
    local data = (res or {}).responseData or {}
    local status = (res or {}).responseStatus or 0
    if status ~= 200 then
      error(
        ('mymemory error %s: %s'):format(
          tostring(status),
          tostring((res or {}).responseDetails or '')
        )
      )
    end
    return { { tostring(data.translatedText or ''), tostring(data.match or '') } }
  elseif api.apiType == 'baidu' then
    if res and res.errno and res.errno ~= 0 then
      error(('baidu error %s: %s'):format(tostring(res.errno), tostring(res.errmsg or '')))
    end
    if res and res.type == 1 then
      local ok, parsed = pcall(vim.json.decode, res.result or '[]')
      if
        ok
        and parsed
        and parsed[1]
        and parsed[1].mean
        and parsed[1].mean[1]
        and parsed[1].mean[1].cont
      then
        local key = next(parsed[1].mean[1].cont)
        return { { tostring(key or ''), tostring(res.from or '') } }
      end
    elseif res and res.type == 2 and res.data and #res.data > 0 then
      local parts = {}
      for _, item in ipairs(res.data) do
        parts[#parts + 1] = tostring(item.dst or '')
      end
      return { { table.concat(parts, ' '), tostring(res.from or '') } }
    end
    error(('baidu: empty or unknown response shape: %s'):format(vim.inspect(res or {})))
  elseif api.apiType == 'openai' then
    local content = type(res) == 'string' and res
      or (((res or {}).choices or {})[1] or {}).message and (((res or {}).choices[1].message or {}).content or '')
      or ''
    return M.parseAIRes(content, api.useBatchFetch)
  end
  error('parseTransRes: unknown api type: ' .. tostring(api.apiType))
end

return M
