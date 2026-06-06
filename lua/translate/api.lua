---@class translate.Api
---@field apiType string
---@field apiSlug string
---@field from string
---@field to string
---@field url string?
---@field key string?
---@field region string?
---@field useBatchFetch boolean
---@field httpTimeout integer
---@field sortOrder integer
---@field isDisabled boolean

---@alias translate.ApiType
---| 'google'
---| 'microsoft'
---| 'openai'

local M = {}

M.TYPES = { 'google', 'microsoft', 'openai' }

---@param api_type translate.ApiType
---@return translate.Api
M.default_api = function(api_type)
  return {
    apiType = api_type,
    apiSlug = api_type,
    from = 'auto',
    to = 'zh-Hans',
    useBatchFetch = false,
    httpTimeout = 30000,
    sortOrder = 0,
    isDisabled = false,
  }
end

return M
