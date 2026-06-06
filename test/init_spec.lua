local h = require('test._helpers')

h.env()

describe('translate (init)', function()
  before_each(h.clear)

  it(
    'loads as a table',
    function() h.eq('table', h.exec_lua('return type(require("translate"))')) end
  )

  describe('setup', function()
    it('populates M.config with defaults', function()
      h.exec_lua(function() require('translate').setup() end)
      local cfg = h.exec_lua(function() return require('translate').config end)
      h.eq('zh-Hans', cfg.target_lang)
      h.eq('eol', cfg.target)
    end)

    it('accepts user overrides', function()
      h.exec_lua(function() require('translate').setup({ target_lang = 'en' }) end)
      local cfg = h.exec_lua(function() return require('translate').config end)
      h.eq('en', cfg.target_lang)
    end)

    it('rejects invalid config', function()
      local err = h.exec_lua(function()
        local ok, e = pcall(require('translate').setup, { target = 'bogus' })
        return ok and '' or e
      end)
      h.matches('invalid target', err)
    end)
  end)
end)
