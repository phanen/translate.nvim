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

M.genReqFuncs = { google = M.genGoogle, microsoft = M.genMicrosoft }

return M
