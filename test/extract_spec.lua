local h = require('test._helpers')

h.env()

describe('translate.extract', function()
  before_each(h.clear)

  describe('batch', function()
    it('joins nodes with placeholders', function()
      local out = h.exec_lua(
        function()
          return require('translate.extract').batch({
            { id = 0, text = 'foo', range = { srow = 0, scol = 0, erow = 0, ecol = 0 } },
            { id = 1, text = 'bar', range = { srow = 0, scol = 0, erow = 0, ecol = 0 } },
          })
        end
      )
      h.eq('<a i=0>foo</a><a i=1>bar</a>', out)
    end)

    it('handles empty input', function()
      local out = h.exec_lua(function() return require('translate.extract').batch({}) end)
      h.eq('', out)
    end)
  end)

  describe('restore', function()
    it('parses placeholder response into id->text', function()
      local foo, bar = h.exec_lua(function()
        local r = require('translate.extract').restore('<a i=0>FOO</a><a i=1>BAR</a>')
        return r[0], r[1]
      end)
      h.eq('FOO', foo)
      h.eq('BAR', bar)
    end)

    it('returns empty table for empty response', function()
      local out = h.exec_lua(function() return require('translate.extract').restore('') end)
      h.eq({}, out)
    end)
  end)

  describe('extract', function()
    it('returns whole buffer for text ft', function()
      h.set_lines({ 'line 1', 'line 2' })
      local nodes = h.exec_lua(
        function() return require('translate.extract').extract(0, 'text') end
      )
      h.eq(1, #nodes)
      h.eq(0, nodes[1].id)
      h.eq('line 1\nline 2', nodes[1].text)
    end)

    it('returns comment nodes for lua ft, sorted by position', function()
      h.set_lines({ 'local x = 1 -- a number', '-- top comment', 'local y = 2' })
      local nodes = h.exec_lua(function() return require('translate.extract').extract(0, 'lua') end)
      h.eq(2, #nodes)
      h.matches('a number', nodes[1].text)
      h.matches('top comment', nodes[2].text)
      h.eq(0, nodes[1].id)
      h.eq(1, nodes[2].id)
    end)

    it('returns nil for unknown ft with no parser', function()
      h.set_lines({ 'something' })
      local out = h.exec_lua(
        function() return require('translate.extract').extract(0, 'brainfuck') end
      )
      h.eq(nil, out)
    end)

    it('falls back to whole-buffer when ft has no treesitter parser', function()
      h.set_lines({ 'plain text line' })
      local nodes = h.exec_lua(function() return require('translate.extract').extract(0, '') end)
      h.eq(1, #nodes)
      h.eq('plain text line', nodes[1].text)
    end)
  end)

  describe('strip_prefix', function()
    it('returns same texts when there is only one', function()
      local r = h.exec_lua(
        function() return require('translate.extract').strip_prefix({ 'hello' }) end
      )
      h.eq({ 'hello' }, r)
    end)

    it('strips common prefix like comment markers', function()
      local r = h.exec_lua(
        function() return require('translate.extract').strip_prefix({ '//! a', '//! b', '//! c' }) end
      )
      h.eq({ 'a', 'b', 'c' }, r)
    end)

    it('keeps texts unchanged when there is no common prefix', function()
      local r = h.exec_lua(
        function() return require('translate.extract').strip_prefix({ 'hello', 'world' }) end
      )
      h.eq({ 'hello', 'world' }, r)
    end)

    it('handles prefix with trailing whitespace', function()
      local r = h.exec_lua(
        function()
          return require('translate.extract').strip_prefix({ '-- comment a', '-- comment b' })
        end
      )
      h.eq({ 'a', 'b' }, r)
    end)
  end)
end)
