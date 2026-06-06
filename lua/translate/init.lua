---@class translate
---@field config translate.Config?
local M = {}

M.config = nil

---@param opts translate.Config?
M.setup = function(opts)
  local config = require('translate.config')
  local cfg = config.merge(config.defaults(), opts)
  config.validate(cfg)
  M.config = cfg
  require('translate.highlight').setup()
end

M.region = function()
  if not M.config then return end
  local source = require('translate.source')
  local trans = require('translate.trans')
  local render = require('translate.render')
  local api = require('translate.api')

  local lines
  local mode = vim.api.nvim_get_mode().mode
  if mode:match('[vV\22]') then
    local s = vim.fn.getpos("'[")
    local e = vim.fn.getpos("']")
    local regtype = mode == 'V' and 'V' or (mode == '\22' and '\22' or 'v')
    lines = source.range(s[2], s[3] - 1, e[2], e[3] - 1, regtype)
  else
    lines = { source.cword() }
  end

  local api_cfg = api.default_api('google')
  api_cfg.from = M.config.source_lang
  api_cfg.to = M.config.target_lang
  api_cfg.httpTimeout = M.config.http_timeout

  local results = trans.handle(api_cfg, lines)

  if M.config.target == 'echo' then render.echo(results) end
end

return M
