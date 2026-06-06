local h = require('test._helpers')

h.env()

describe('translate.spec', function()
  before_each(h.clear)

  describe('get', function()
    it('returns the spec for known fts', function()
      local s = h.exec_lua(function() return require('translate.spec').get('markdown') end)
      h.eq({ 'inline' }, s.text)
    end)

    it('falls back to generic for unknown ft', function()
      local s = h.exec_lua(function() return require('translate.spec').get('rust') end)
      h.eq({ 'comment' }, s.text)
    end)

    it('handles nil ft', function()
      local s = h.exec_lua(function() return require('translate.spec').get(nil) end)
      h.eq({ 'comment' }, s.text)
    end)
  end)

  describe('query', function()
    it('builds @text captures from the spec', function()
      local q = h.exec_lua(function() return require('translate.spec').query('markdown') end)
      h.matches('%(inline%) @text.inline', q)
    end)

    it('builds @text for code files', function()
      local q = h.exec_lua(function() return require('translate.spec').query('lua') end)
      h.matches('%(comment%) @text.comment', q)
    end)

    it('returns empty query for text ft', function()
      local q = h.exec_lua(function() return require('translate.spec').query('text') end)
      h.eq('', q)
    end)
  end)

  describe('has_captures', function()
    it('returns true when spec has text nodes', function()
      h.eq(
        true,
        h.exec_lua(function() return require('translate.spec').has_captures('markdown') end)
      )
    end)

    it('returns false for text ft', function()
      h.eq(false, h.exec_lua(function() return require('translate.spec').has_captures('text') end))
    end)

    it('returns true for generic fallback', function()
      h.eq(true, h.exec_lua(function() return require('translate.spec').has_captures('rust') end))
    end)
  end)
end)
