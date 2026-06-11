local h = require('test._helpers')
local Screen = require('nvim-test.screen')

h.env()

describe('translate.region', function()
  before_each(h.clear)

  it('target = eol', function()
    local screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup()
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
    local screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup({ target = 'inline' })
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
    local screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
    h.set_lines({ 'hello world' })
    h.exec_lua(function()
      require('translate').setup({ target = 'replace' })
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
  before_each(h.clear)

  it('target = eol', function()
    local screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
    h.set_lines({ '-- a lua comment', 'local x = 1' })
    h.exec_lua(function()
      vim.bo[0].filetype = 'lua'
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').setup()
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
    local screen = Screen.new(60, 5)
    screen:attach({ ext_messages = true })
    h.set_lines({ '-- a comment' })
    screen:expect([[
      ^-- a comment                                                |
      ~                                                           |
      ~                                                           |
      ~                                                           |
      ~                                                           |
    ]])
    local marks = h.exec_lua(function()
      vim.bo[0].filetype = 'lua'
      require('translate').setup({ target = 'below' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').below
      return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    end)
    h.eq(1, #marks)
    h.eq({ { '注释', 'TranslateTrans' } }, marks[1][4].virt_lines[1])
  end)
end)
