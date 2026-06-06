local h = require('test._helpers')

h.env()

describe('translate.config', function()
  before_each(h.clear)

  it('returns expected defaults', function()
    local d = h.exec_lua(function() return require('translate.config').defaults() end)
    h.eq('zh-Hans', d.target_lang)
    h.eq('auto', d.source_lang)
    h.eq('eol', d.target)
    h.eq(30000, d.http_timeout)
  end)

  describe('merge', function()
    it('merges user opts over base', function()
      local m = h.exec_lua(
        function() return require('translate.config').merge({ a = 1, b = 2 }, { b = 3, c = 4 }) end
      )
      h.eq({ a = 1, b = 3, c = 4 }, m)
    end)

    it('handles nil user opts', function()
      local d = { x = 1 }
      local m = h.exec_lua(function(a) return require('translate.config').merge(a, nil) end, d)
      h.eq(d, m)
    end)
  end)

  describe('validate', function()
    local run = function(overrides)
      return h.exec_lua(function(o)
        local cfg = require('translate.config').defaults()
        for k, v in pairs(o) do
          cfg[k] = v
        end
        local ok, e = pcall(require('translate.config').validate, cfg)
        return ok and '' or e
      end, overrides)
    end

    it('accepts defaults', function() h.eq('', run({})) end)

    it(
      'rejects unknown target',
      function() h.matches('invalid target', run({ target = 'unknown' })) end
    )

    it(
      'rejects empty target_lang',
      function() h.matches('target_lang', run({ target_lang = '' })) end
    )
  end)
end)
