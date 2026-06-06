local M = {}

M.setup = function()
  vim.api.nvim_set_hl(0, 'TranslateTrans', { link = 'DiagnosticInfo', default = true })
  vim.api.nvim_set_hl(0, 'TranslateSrc', { link = 'Comment', default = true })
end

return M
