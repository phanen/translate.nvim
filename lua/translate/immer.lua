---@class translate.ImmerState
---@field nodes table<string, string>  -- range key -> text
---@field timer uv.uv_timer_t?
---@field debounce_ms integer

local M = {}

---@type table<integer, translate.ImmerState?>
M.state = {}

---@param buf integer
---@param opts? { debounce_ms?: integer }
M.enable = function(buf, opts)
  buf = buf or 0
  M.disable(buf)
  local debounce_ms = (opts and opts.debounce_ms) or 400
  M.state[buf] = { nodes = {}, timer = nil, debounce_ms = debounce_ms }

  local function on_change()
    local s = M.state[buf]
    if not s then return end
    if s.timer then s.timer:stop() end
    local timer = vim.uv.new_timer()
    if not timer then return end
    s.timer = timer
    timer:start(s.debounce_ms, 0, function()
      vim.schedule(function() M.resync(buf) end)
    end)
  end

  vim.api.nvim_buf_attach(buf, false, {
    on_bytes = function() on_change() end,
    on_detach = function() M.disable(buf) end,
  })
  vim.schedule(function() M.resync(buf) end)
end

---@param buf integer
M.resync = function(buf)
  buf = buf or 0
  local s = M.state[buf]
  if not s then return end
  local ft = vim.bo[buf].filetype
  local extract = require('translate.extract')
  local nodes = extract.extract(buf, ft)
  if not nodes then return end

  local new_ranges, new_texts = {}, {}
  for _, n in ipairs(nodes) do
    local key = ('%d:%d-%d:%d'):format(n.range.srow, n.range.scol, n.range.erow, n.range.ecol)
    if s.nodes[key] ~= n.text then
      new_ranges[#new_ranges + 1] = n.range
      new_texts[#new_texts + 1] = n.text
    end
  end

  if #new_texts > 0 then
    local t = require('translate')
    if t.config then
      local api = require('translate.api').default_api(t.config.api or 'google')
      api.from = t.config.source_lang
      api.to = t.config.target_lang
      api.httpTimeout = t.config.http_timeout
      if t.config.creds then
        for k, v in pairs(t.config.creds) do
          api[k] = v
        end
      end
      local http = require('translate.http')
      local trans = require('translate.trans')
      local chunker = require('translate.chunker')
      local render = require('translate.render')
      render.extmark_clear(buf, 'eol')
      trans.handle_async(
        api,
        new_texts,
        { batchSize = 1 },
        function(results)
          ---@cast results string[]
          local aligned = chunker.to_eol(results, new_ranges)
          render.extmark_eol(buf, aligned.items, aligned.ranges)
        end,
        http.fetch_async,
        function(orig, translation, _)
          local r = new_ranges[orig]
          if r then
            local clean = translation:gsub('%z', ''):gsub('[\r\n]+', ' ')
            render.extmark_eol(buf, { clean }, { r }, false)
          end
        end
      )
    end
  end

  s.nodes = {}
  for _, n in ipairs(nodes) do
    local key = ('%d:%d-%d:%d'):format(n.range.srow, n.range.scol, n.range.erow, n.range.ecol)
    s.nodes[key] = n.text
  end
end

---@param buf integer
M.disable = function(buf)
  buf = buf or 0
  local s = M.state[buf]
  if not s then return end
  if s.timer then
    s.timer:stop()
    s.timer:close()
  end
  require('translate.render').extmark_clear(buf, 'eol')
  M.state[buf] = nil
end

return M
