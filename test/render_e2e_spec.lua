local h = require('test._helpers')
local Screen = require('nvim-test.screen')

h.env()

describe('translate.region', function()
  local screen --- @type test.screen
  before_each(function()
    h.clear()
    screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
  end)

  it('target = eol', function()
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup({ api = 'google' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
    end)
    screen:expect([[
      ^hello world 你好                                            |
      ~                                                           |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
  end)

  it('target = inline', function()
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup({ api = 'google', target = 'inline' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
    end)
    screen:expect([[
      你好^hello world                                             |
      ~                                                           |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
  end)

  it('target = replace', function()
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup({ api = 'google', target = 'replace' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
    end)
    screen:expect([[
      ^你好  world                                                 |
      ~                                                           |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
  end)

  it('no-op on empty cword', function()
    h.set_lines({ '   ' })
    local ok = h.exec_lua(function()
      require('translate').setup()
      require('translate').region()
      return true
    end)
    h.eq(true, ok)
  end)
end)

describe('translate.immer', function()
  local screen --- @type test.screen
  before_each(function()
    h.clear()
    screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
  end)

  it('target = eol', function()
    h.set_lines({ '-- a lua comment', 'local x = 1' })
    h.exec_lua(function()
      vim.bo[0].filetype = 'lua'
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').setup({ api = 'google' }) -- immer.eol
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
    end)
    screen:expect([[
      ^-- a lua comment 注释                                       |
      local x = 1                                                 |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
  end)

  it('target = below', function()
    h.set_lines({ '-- a comment' })
    h.exec_lua(function()
      vim.bo[0].filetype = 'lua'
      require('translate').setup({ api = 'google', target = 'below' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
    end)
    screen:expect([[
      ^-- a comment                                                |
      注释                                                        |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
  end)
end)
