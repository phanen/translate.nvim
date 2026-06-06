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
---@param text string
---@return string url
---@return table init
---@return any _user_msg
M.genMicrosoft = function(api, text)
  local url = api.url or 'https://api-edge.cognitive.microsofttranslator.com/translate'
  local params = { from = api.from, to = api.to, ['api-version'] = '3.0' }
  local q = {}
  for k, v in pairs(params) do
    q[#q + 1] = ('%s=%s'):format(k, vim.uri_encode(tostring(v)))
  end
  url = url .. '?' .. table.concat(q, '&')
  local headers = { ['Content-Type'] = 'application/json' }
  if api.key then headers['Ocp-Apim-Subscription-Key'] = api.key end
  if api.region then headers['Ocp-Apim-Subscription-Region'] = api.region end
  local body = vim.json.encode({ { Text = text } })
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

M.genReqFuncs = { google = M.genGoogle, microsoft = M.genMicrosoft, openai = M.genOpenAI }

return M
