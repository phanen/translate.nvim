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

return M
