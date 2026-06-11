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

M.immer = {
  enable = function(buf, opts) return require('translate.immer').enable(buf, opts) end,
  disable = function(buf) return require('translate.immer').disable(buf) end,
  resync = function(buf) return require('translate.immer').resync(buf) end,
}

M.region = function()
  if not M.config then return end
  local source = require('translate.source')
  local trans = require('translate.trans')
  local render = require('translate.render')
  local api = require('translate.api')
  local chunker = require('translate.chunker')
  local http = require('translate.http')

  local lines, ranges = source.collect()
  if not lines or #lines == 0 then return end

  local api_cfg = api.default_api(M.config.api or 'google')
  api_cfg.from = M.config.source_lang
  api_cfg.to = M.config.target_lang
  api_cfg.httpTimeout = M.config.http_timeout
  if M.config.creds then
    for k, v in pairs(M.config.creds) do
      api_cfg[k] = v
    end
  end

  local target = M.config.target
  trans.handle_async(api_cfg, lines, nil, function(r)
    ---@cast r string[]
    ---@cast ranges translate.Range[]
    if target == 'echo' then
      render.echo(r)
    elseif target == 'eol' or target == 'below' or target == 'inline' then
      local aligned = target == 'eol' and chunker.to_eol(r, ranges) or chunker.to_below(r, ranges)
      if target == 'eol' then
        render.extmark_eol(0, aligned.items, aligned.ranges)
      elseif target == 'below' then
        render.extmark_below(0, aligned.items, aligned.ranges)
      else
        render.extmark_inline(0, aligned.items, aligned.ranges)
      end
    end
  end, http.fetch_async)
end

return M
