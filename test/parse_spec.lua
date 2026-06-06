local h = require('test._helpers')

h.env()

describe('translate.parse', function()
  before_each(h.clear)

  describe('parseTransRes', function()
    it('parses google response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { sentences = { { trans = '你好' } }, src = 'en' },
            { apiType = 'google' }
          )
        end
      )
      h.eq({ { '你好', 'en' } }, r)
    end)

    it('parses baidu type=1 (dict) response', function()
      local r = h.exec_lua(function()
        local content = '[{"mean":[{"cont":{"你好":"hello"}}]}]'
        return require('translate.parse').parseTransRes(
          { type = 1, from = 'en', result = content },
          { apiType = 'baidu' }
        )
      end)
      h.eq({ { '你好', 'en' } }, r)
    end)

    it('throws on baidu errno response', function()
      local r = h.exec_lua(function()
        local ok, err = pcall(
          require('translate.parse').parseTransRes,
          { errno = 997, errmsg = 'INVALID SOURCE LANG' },
          { apiType = 'baidu' }
        )
        return { ok = ok, err = err or '' }
      end)
      h.eq(false, r.ok)
      h.matches('baidu error 997', r.err)
      h.matches('INVALID SOURCE LANG', r.err)
    end)

    it('throws on baidu empty data', function()
      local r = h.exec_lua(function()
        local ok, err = pcall(
          require('translate.parse').parseTransRes,
          { type = 2, data = {} },
          { apiType = 'baidu' }
        )
        return { ok = ok, err = err or '' }
      end)
      h.eq(false, r.ok)
      h.matches('baidu', r.err)
    end)
  end)
end)
