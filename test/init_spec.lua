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

  describe('clear', function()
    it('clears extmarks across all render namespaces', function()
      h.exec_lua(function()
        require('translate').setup()
        local render = require('translate.render')
        render.extmark_eol(0, { 'a' }, { { srow = 0, scol = 0, erow = 0, ecol = 0 } })
        render.extmark_below(0, { 'b' }, { { srow = 0, scol = 0, erow = 0, ecol = 0 } })
        render.extmark_replace(0, { 'c' }, { { srow = 0, scol = 0, erow = 0, ecol = 0 } })
        render.extmark_inline(0, { 'd' }, { { srow = 0, scol = 0, erow = 0, ecol = 0 } })
        require('translate').clear(0)
      end)
      local total = h.exec_lua(function()
        local ns = require('translate.ns')
        local n = 0
        for _, t in ipairs({ ns.eol, ns.below, ns.replace, ns.inline }) do
          n = n + #vim.api.nvim_buf_get_extmarks(0, t, 0, -1, {})
        end
        return n
      end)
      h.eq(0, total)
    end)
  end)
end)
