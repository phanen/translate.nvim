---@diagnostic disable: undefined-field
local M = {}

M.check = function()
  vim.health.start('translate')
  local ok, t = pcall(require, 'translate')
  if not ok then
    vim.health.error('translate module failed to load: ' .. tostring(t))
    return
  end
  if t.config then
    vim.health.ok('setup() called')
    vim.health.info('target_lang: ' .. t.config.target_lang)
    vim.health.info('source_lang: ' .. t.config.source_lang)
    vim.health.info('target:      ' .. t.config.target)
    vim.health.info('http_timeout: ' .. tostring(t.config.http_timeout))
  else
    vim.health.warn('setup() not called yet')
  end
end

return M
