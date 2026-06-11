if vim.g.loaded_translate == 1 then return end
vim.g.loaded_translate = 1

vim.api.nvim_create_user_command(
  'Translate',
  function() require('translate').region() end,
  { range = true, desc = 'translate.nvim: translate selection or word' }
)

vim.api.nvim_create_user_command(
  'TranslateImmer',
  function(info) require('translate').immer.enable(tonumber(info.args) or 0) end,
  { desc = 'translate.nvim: enable immersive translation' }
)
