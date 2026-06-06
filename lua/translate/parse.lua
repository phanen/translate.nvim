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
  elseif api.apiType == 'openai' then
    local content = type(res) == 'string' and res
      or (((res or {}).choices or {})[1] or {}).message and (((res or {}).choices[1].message or {}).content or '')
      or ''
    return M.parseAIRes(content, api.useBatchFetch)
  end
  error('parseTransRes: unknown api type: ' .. tostring(api.apiType))
end

return M
