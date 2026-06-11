local M = {}

M.eol = vim.api.nvim_create_namespace('translate.eol')
M.below = vim.api.nvim_create_namespace('translate.below')
M.inline = vim.api.nvim_create_namespace('translate.inline')
M.replace = vim.api.nvim_create_namespace('translate.replace')

return M
