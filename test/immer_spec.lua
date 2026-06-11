local h = require('test._helpers')

h.env()

describe('translate.immer', function()
  before_each(h.clear)

  it('places extmarks after resync on a lua buffer', function()
    local count = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a comment', 'local x = 1' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').eol
      return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    end)
    h.eq(1, count)
  end)

  it('skips unchanged nodes on second resync', function()
    local call_count = h.exec_lua(function()
      _G._t_calls = 0
      require('translate').setup()
      require('translate.http').set_transport(function(_, cb)
        _G._t_calls = _G._t_calls + 1
        cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
      end)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a comment', 'local x = 1' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      require('translate').immer.resync(0)
      return _G._t_calls
    end)
    h.eq(1, call_count)
  end)

  it('retranslates when text changes', function()
    local call_count = h.exec_lua(function()
      _G._t_calls = 0
      require('translate').setup()
      require('translate.http').set_transport(function(_, cb)
        _G._t_calls = _G._t_calls + 1
        cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
      end)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- first', 'local x = 1' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- second', 'local x = 1' })
      require('translate').immer.resync(0)
      return _G._t_calls
    end)
    h.eq(2, call_count)
  end)

  it('disable clears extmarks and state', function()
    local marks = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- comment' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      require('translate').immer.disable(0)
      local ns = require('translate.ns').eol
      return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    end)
    h.eq(0, marks)
  end)

  it('places exactly one extmark per comment line (no duplicates)', function()
    local marks = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '注释' } }, src = 'en' }))
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a', '-- b', '-- c' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').eol
      return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    end)
    h.eq(3, #marks)
    for _, m in ipairs(marks) do
      h.eq(1, #m[4].virt_text)
      h.eq({ '注释', 'TranslateTrans' }, m[4].virt_text[1])
    end
  end)
end)
