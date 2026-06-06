local h = require('test._helpers')

h.env()

describe('translate.chunker', function()
  before_each(h.clear)

  describe('to_eol', function()
    it('passes through single-line ranges with erow collapsed', function()
      local r = h.exec_lua(function()
        return require('translate.chunker').to_eol({ 'hi' }, { { srow = 0, scol = 0, erow = 0, ecol = 5 } })
      end)
      h.eq({ items = { 'hi' }, ranges = { { srow = 0, scol = 0, erow = 0, ecol = 0 } } }, r)
    end)

    it('collapses multi-line ranges to the first line', function()
      local r = h.exec_lua(
        function()
          return require('translate.chunker').to_eol(
            { '你好' },
            { { srow = 0, scol = 0, erow = 2, ecol = 0 } }
          )
        end
      )
      h.eq({ srow = 0, scol = 0, erow = 0, ecol = 0 }, r.ranges[1])
      h.eq({ '你好' }, r.items)
    end)

    it('handles multiple items', function()
      local r = h.exec_lua(
        function()
          return require('translate.chunker').to_eol({ 'A', 'B' }, {
            { srow = 0, scol = 0, erow = 1, ecol = 0 },
            { srow = 2, scol = 0, erow = 3, ecol = 0 },
          })
        end
      )
      h.eq({ srow = 0, scol = 0, erow = 0, ecol = 0 }, r.ranges[1])
      h.eq({ srow = 2, scol = 0, erow = 2, ecol = 0 }, r.ranges[2])
    end)
  end)

  describe('to_below', function()
    it('passes through ranges unchanged', function()
      local r = h.exec_lua(
        function()
          return require('translate.chunker').to_below(
            { 'X' },
            { { srow = 1, scol = 0, erow = 3, ecol = 0 } }
          )
        end
      )
      h.eq({ items = { 'X' }, ranges = { { srow = 1, scol = 0, erow = 3, ecol = 0 } } }, r)
    end)
  end)
end)
