local h = require('test._helpers')
local Screen = require('nvim-test.screen')

h.env()

describe('translate.region (eol render)', function()
  before_each(h.clear)

  it('places eol virt_text when target = eol (default)', function()
    local screen = Screen.new(60, 5)
    screen:attach()
    h.set_lines({ 'hello world' })
    local count = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return #vim.api.nvim_buf_get_extmarks(0, require('translate.ns').eol, 0, -1, {})
    end)
    h.eq(1, count)
  end)

  it('shows the translation inline at eol via screen:expect', function()
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

  it('places below virt_lines when target = below', function()
    h.set_lines({ 'hello' })
    local count = h.exec_lua(function()
      require('translate').setup({ target = 'below' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return #vim.api.nvim_buf_get_extmarks(0, require('translate.ns').below, 0, -1, {})
    end)
    h.eq(1, count)
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

  it('places eol extmarks after resync on a lua buffer', function()
    local screen = Screen.new(60, 5)
    screen:attach()
    h.set_lines({ '-- a lua comment', 'local x = 1' })
    local count = h.exec_lua(function()
      vim.bo[0].filetype = 'lua'
      require('translate').setup()
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      return #vim.api.nvim_buf_get_extmarks(0, require('translate.ns').eol, 0, -1, {})
    end)
    h.eq(1, count)
  end)

  it('shows the comment translation on the first line of the buffer', function()
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

  it('immer resync places extmarks in below namespace when target = below', function()
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

  it('region with target = inline places inline virt_text', function()
    local marks = h.exec_lua(function()
      require('translate').setup({ target = 'inline' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello world' })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      local ns = require('translate.ns').inline
      return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    end)
    h.eq(1, #marks)
    h.eq('inline', marks[1][4].virt_text_pos)
    h.eq({ { '你好', 'TranslateTrans' } }, marks[1][4].virt_text)
  end)

  it('region with target = replace conceals original text', function()
    local marks = h.exec_lua(function()
      require('translate').setup({ target = 'replace' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello world' })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      local ns = require('translate.ns').replace
      return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    end)
    h.eq(1, #marks)
    h.eq('inline', marks[1][4].virt_text_pos)
    h.eq('', marks[1][4].conceal_lines)
    h.eq({ { '你好', 'TranslateTrans' } }, marks[1][4].virt_text)
  end)
end)
