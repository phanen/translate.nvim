if vim.g.loaded_translate == 1 then return end
vim.g.loaded_translate = 1

vim.api.nvim_create_user_command('Translate', function()
  require('translate').region()
end, { desc = 'translate.nvim: translate selection or word' })
