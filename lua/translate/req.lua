local M = {}

---@param api translate.Api
---@param text string
---@return string url
---@return table init
---@return any _user_msg
M.genGoogle = function(api, text)
  local url = api.url or 'https://translate.googleapis.com/translate_a/single'
  local params =
    { client = 'gtx', dt = 't', dj = '1', ie = 'UTF-8', sl = api.from, tl = api.to, q = text }
  local q = {}
  for k, v in pairs(params) do
    q[#q + 1] = ('%s=%s'):format(k, vim.uri_encode(tostring(v)))
  end
  url = url .. '?' .. table.concat(q, '&')
  local headers = { ['Content-Type'] = 'application/json' }
  if api.key then headers.Authorization = 'Bearer ' .. api.key end
  return url, { method = 'GET', headers = headers, body = nil }, nil
end

---@param api translate.Api
---@param text_or_texts string|string[]
---@return string url
---@return table init
---@return any _user_msg
M.genMicrosoft = function(api, text_or_texts)
  local texts = type(text_or_texts) == 'table' and text_or_texts or { text_or_texts }
  local url = api.url or 'https://api-edge.cognitive.microsofttranslator.com/translate'
  local params = { to = api.to, ['api-version'] = '3.0' }
  if api.from and api.from ~= 'auto' then params.from = api.from end
  local q = {}
  for k, v in pairs(params) do
    q[#q + 1] = ('%s=%s'):format(k, vim.uri_encode(tostring(v)))
  end
  url = url .. '?' .. table.concat(q, '&')
  local headers = { ['Content-Type'] = 'application/json' }
  if api.key then
    headers['Ocp-Apim-Subscription-Key'] = api.key
    if api.region then headers['Ocp-Apim-Subscription-Region'] = api.region end
  else
    local token = require('translate.ms_auth').fetch()
    if token then headers['Authorization'] = 'Bearer ' .. token end
  end
  local items = {}
  for _, t in ipairs(texts) do
    items[#items + 1] = { Text = t }
  end
  local body = vim.json.encode(items)
  return url, { method = 'POST', headers = headers, body = body }, nil
end

---@param api translate.Api
---@param text string
---@return string url
---@return table init
---@return table? user_msg
M.genOpenAI = function(api, text)
  local url = api.url or 'https://api.openai.com/v1/chat/completions'
  local headers =
    { ['Content-Type'] = 'application/json', Authorization = 'Bearer ' .. (api.key or '') }
  local model = api.model or 'gpt-4'
  local sys = api.systemPrompt
    or ('Translate the following to %s. Output only the translation.'):format(api.to)
  local body = vim.json.encode({
    model = model,
    messages = { { role = 'system', content = sys }, { role = 'user', content = text } },
    temperature = api.temperature or 0,
  })
  local user_msg = { role = 'user', content = text }
  return url, { method = 'POST', headers = headers, body = body }, user_msg
end

---@param api translate.Api
---@param text string
---@return string url
---@return table init
---@return any _user_msg
M.genMyMemory = function(api, text)
  local url = api.url or 'https://api.mymemory.translated.net/get'
  local from = (api.from and api.from ~= 'auto') and api.from or 'en'
  local langpair = ('%s|%s'):format(from, api.to or 'zh-Hans')
  local params = { q = text, langpair = langpair }
  if api.key then params.de = api.key end
  local q = {}
  for k, v in pairs(params) do
    q[#q + 1] = ('%s=%s'):format(k, vim.uri_encode(tostring(v)))
  end
  url = url .. '?' .. table.concat(q, '&')
  return url, { method = 'GET', headers = {}, body = nil }, nil
end

---@param api translate.Api
---@param text string
---@return string url
---@return table init
---@return any _user_msg
M.genBaidu = function(api, text)
  local url = api.url or 'https://fanyi.baidu.com/transapi'
  local from = (api.from and api.from ~= 'auto') and api.from or 'en'
  local to = api.to or 'zh'
  local body = 'from='
    .. vim.uri_encode(from)
    .. '&to='
    .. vim.uri_encode(to)
    .. '&query='
    .. vim.uri_encode(text)
    .. '&source=txt'
  local headers = { ['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8' }
  return url, { method = 'POST', headers = headers, body = body }, nil
end

M.genReqFuncs = {
  google = M.genGoogle,
  microsoft = M.genMicrosoft,
  openai = M.genOpenAI,
  mymemory = M.genMyMemory,
  baidu = M.genBaidu,
}

return M
