local M = {}

---@alias translate.RenderSink fun(chunks: {[integer]: string|string[]})

---@param items string[]
---@param sink translate.RenderSink?
M.echo = function(items, sink)
  local chunks = {}
  for _, text in ipairs(items) do
    chunks[#chunks + 1] = { text, 'TranslateTrans' }
  end
  if sink then
    sink(chunks)
  else
    vim.api.nvim_echo(chunks, false, {})
  end
end

---@param buf integer
---@param items string[]
---@param ranges translate.Range[]
---@param clear? boolean  -- default true, false to append without clearing
M.extmark_eol = function(buf, items, ranges, clear)
  local ns = require('translate.ns').eol
  if clear ~= false then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
  for i, item in ipairs(items) do
    local r = ranges[i]
    local clean = item:gsub('%z', ''):gsub('[\r\n]+', ' ')
    if r then
      vim.api.nvim_buf_set_extmark(buf, ns, r.srow, r.scol, {
        end_row = r.erow,
        end_col = r.ecol,
        virt_text = { { clean, 'TranslateTrans' } },
        virt_text_pos = 'eol',
      })
    end
  end
end

---@param buf integer
---@param items string[]
---@param ranges translate.Range[]
---@param clear? boolean  -- default true, false to append
M.extmark_below = function(buf, items, ranges, clear)
  local ns = require('translate.ns').below
  if clear ~= false then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
  for i, item in ipairs(items) do
    local r = ranges[i]
    local clean = item:gsub('%z', ''):gsub('[\r\n]+', ' ')
    if r then
      vim.api.nvim_buf_set_extmark(buf, ns, r.srow, r.scol, {
        virt_lines = { { { clean, 'TranslateTrans' } } },
      })
    end
  end
end

---@param buf integer
---@param items string[]
---@param ranges translate.Range[]
---@param clear? boolean  -- default true, false to append
M.extmark_inline = function(buf, items, ranges, clear)
  local ns = require('translate.ns').inline
  if clear ~= false then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
  for i, item in ipairs(items) do
    local r = ranges[i]
    local clean = item:gsub('%z', ''):gsub('[\r\n]+', ' ')
    if r then
      vim.api.nvim_buf_set_extmark(buf, ns, r.srow, r.scol, {
        end_row = r.erow,
        end_col = r.ecol,
        virt_text = { { clean, 'TranslateTrans' } },
        virt_text_pos = 'inline',
        virt_text_hide = true,
      })
    end
  end
end

---@param buf integer
---@param which string?
M.extmark_clear = function(buf, which)
  local ns_mod = require('translate.ns')
  local ns = ns_mod[which or 'eol'] or ns_mod.eol
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
