local h = require('test._helpers')
local Screen = require('nvim-test.screen')

h.env()

describe('translate.region (eol render)', function()
  before_each(h.clear)

  it('shows the translation at eol via screen:expect', function()
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

  it('shows the inline translation pushing source text right', function()
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

  it('no-op when cword is empty (whitespace, punctuation)', function()
    h.set_lines({ '   ' })
    local ok = h.exec_lua(function()
      require('translate').setup()
      require('translate').region()
      return true
    end)
    h.eq(true, ok)
  end)
end)

describe('translate.immer (visible behavior)', function()
  before_each(h.clear)

  it('shows the comment translation at eol', function()
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

  it('immer resync places virt_lines when target = below', function()
    local marks = h.exec_lua(function()
      require('translate').setup({ target = 'below' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a comment' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').below
      return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    end)
    h.eq(1, #marks)
    h.eq({ { '注释', 'TranslateTrans' } }, marks[1][4].virt_lines[1])
  end)

  describe('target = replace', function()
    it('shows inline translation (conceal needs conceallevel >= 2)', function()
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
  end)
end)
