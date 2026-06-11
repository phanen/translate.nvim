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

  it('placeks exactly one extmark per comment line (no duplicates)', function()
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
      local d = m[4] ---@type table?
      if d and d.virt_text then
        h.eq(1, #d.virt_text)
        if d.virt_text[1] then h.eq({ '注释', 'TranslateTrans' }, d.virt_text[1]) end
      end
    end
  end)

  it('microsoft batch: one http request for N segments, correct per-line results', function()
    local result = h.exec_lua(function()
      _G._t_body = nil
      _G._t_count = 0
      require('translate').setup({ api = 'microsoft' })
      require('translate.http').set_transport(function(opts, cb)
        _G._t_body = opts.body
        _G._t_count = _G._t_count + 1
        cb(
          200,
          vim.json.encode({
            { translations = { { text = '一' } }, detectedLanguage = { language = 'en' } },
            { translations = { { text = '二' } }, detectedLanguage = { language = 'en' } },
            { translations = { { text = '三' } }, detectedLanguage = { language = 'en' } },
          })
        )
      end)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a', '-- b', '-- c' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').eol
      local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      return {
        count = #marks,
        calls = _G._t_count,
        body = _G._t_body,
      }
    end)
    h.eq(3, result.count)
    h.eq(true, result.calls >= 1, 'should make at least one call')
    h.matches('"Text"', result.body)
  end)

  it('microsoft batch: each line gets its own translation', function()
    local texts = h.exec_lua(function()
      require('translate').setup({ api = 'microsoft' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(
            200,
            vim.json.encode({
              { translations = { { text = 'one' } }, detectedLanguage = { language = 'en' } },
              { translations = { { text = 'two' } }, detectedLanguage = { language = 'en' } },
            })
          )
        end
      )
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- hello', '-- world' })
      vim.bo.filetype = 'lua'
      require('translate').immer.enable(0)
      require('translate').immer.resync(0)
      local ns = require('translate.ns').eol
      local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      return {
        marks[1]
          and marks[1][4]
          and marks[1][4].virt_text
          and marks[1][4].virt_text[1]
          and marks[1][4].virt_text[1][1],
        marks[2]
          and marks[2][4]
          and marks[2][4].virt_text
          and marks[2][4].virt_text[1]
          and marks[2][4].virt_text[1][1],
      }
    end)
    h.eq({ 'one', 'two' }, texts)
  end)
end)
