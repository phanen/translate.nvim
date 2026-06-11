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

---@return string[]?, translate.Range[]?
local collect = function()
  local source = require('translate.source')
  local mode = vim.api.nvim_get_mode().mode
  if mode:match('[vV\22]') then
    local s = vim.fn.getpos('.')
    local v = vim.fn.getpos('v')
    local regtype = mode == 'V' and 'V' or (mode == '\22' and '\22' or 'v')
    local srow, scol, vrow, vcol = s[2], s[3] - 1, v[2], v[3] - 1
    local srow0 = math.min(srow, vrow)
    local scol0 = srow0 == srow and scol or (srow0 == vrow and vcol or 0)
    local erow = math.max(srow, vrow)
    local ecol = erow == srow and scol or (erow == vrow and vcol or 0)
    local raw = source.range(srow0, scol0, erow, ecol, regtype)
    local full = table.concat(raw, '\n')
    return { full }, { { srow = srow0, scol = scol0, erow = erow, ecol = ecol } }
  else
    local word = source.cword()
    if word == '' then return nil, nil end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    return { word }, { { srow = row, scol = col, erow = row, ecol = col + #word } }
  end
end

M.region = function()
  if not M.config then return end
  local trans = require('translate.trans')
  local render = require('translate.render')
  local api = require('translate.api')
  local chunker = require('translate.chunker')
  local http = require('translate.http')

  local lines, ranges = collect()
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
    elseif target == 'eol' or target == 'below' then
      local aligned = target == 'eol' and chunker.to_eol(r, ranges) or chunker.to_below(r, ranges)
      if target == 'eol' then
        render.extmark_eol(0, aligned.items, aligned.ranges)
      else
        render.extmark_below(0, aligned.items, aligned.ranges)
      end
    end
  end, http.fetch_async)
end

return M
