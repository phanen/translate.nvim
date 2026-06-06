local h = require('test._helpers')

h.env()

describe('translate.batch', function()
  before_each(h.clear)

  describe('chunk', function()
    it('returns empty list for empty input', function()
      local r = h.exec_lua(function() return require('translate.batch').chunk({}) end)
      h.eq({}, r)
    end)

    it('keeps short input in one batch', function()
      local r = h.exec_lua(
        function()
          return require('translate.batch').chunk(
            { 'a', 'b', 'c' },
            { batchSize = 10, batchLength = 100 }
          )
        end
      )
      h.eq({ { 'a', 'b', 'c' } }, r)
    end)

    it('splits when batchSize is reached', function()
      local r = h.exec_lua(
        function()
          return require('translate.batch').chunk(
            { 'a', 'b', 'c', 'd', 'e' },
            { batchSize = 2, batchLength = 1000 }
          )
        end
      )
      h.eq({ { 'a', 'b' }, { 'c', 'd' }, { 'e' } }, r)
    end)

    it('splits when batchLength is reached', function()
      local r = h.exec_lua(
        function()
          return require('translate.batch').chunk(
            { 'aaaa', 'bbbb', 'cccc' },
            { batchSize = 100, batchLength = 5 }
          )
        end
      )
      h.eq({ { 'aaaa' }, { 'bbbb' }, { 'cccc' } }, r)
    end)

    it('uses default opts when none given', function()
      local r = h.exec_lua(function() return require('translate.batch').chunk({ 'x' }) end)
      h.eq({ { 'x' } }, r)
    end)

    it('respects both limits together', function()
      local r = h.exec_lua(
        function()
          return require('translate.batch').chunk(
            { 'aa', 'bb', 'cc', 'dd' },
            { batchSize = 2, batchLength = 3 }
          )
        end
      )
      h.eq({ { 'aa' }, { 'bb' }, { 'cc' }, { 'dd' } }, r)
    end)
  end)
end)
