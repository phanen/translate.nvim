local h = require('test._helpers')

h.env()

describe('translate.source', function()
  before_each(h.clear)

  describe('cword', function()
    it('returns the word at cursor', function()
      h.set_lines({ 'hello world' })
      local word = h.exec_lua(function()
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        return require('translate.source').cword()
      end)
      h.eq('hello', word)
    end)

    it('returns the right word when cursor is on second token', function()
      h.set_lines({ 'hello world' })
      local word = h.exec_lua(function()
        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        return require('translate.source').cword()
      end)
      h.eq('world', word)
    end)
  end)

  describe('cWORD', function()
    it('returns the whole WORD at cursor', function()
      h.set_lines({ 'foo-bar baz' })
      local word = h.exec_lua(function()
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        return require('translate.source').cWORD()
      end)
      h.eq('foo-bar', word)
    end)
  end)

  describe('range', function()
    it('returns charwise substring', function()
      h.set_lines({ 'hello world' })
      local lines = h.exec_lua(
        function() return require('translate.source').range(1, 0, 1, 4, 'v') end
      )
      h.eq({ 'hello' }, lines)
    end)

    it('returns linewise full lines', function()
      h.set_lines({ 'hello world', 'foo bar', 'baz qux' })
      local lines = h.exec_lua(
        function() return require('translate.source').range(1, 0, 2, 6, 'V') end
      )
      h.eq({ 'hello world', 'foo bar' }, lines)
    end)

    it('returns single line when srow equals erow', function()
      h.set_lines({ 'hello world' })
      local lines = h.exec_lua(
        function() return require('translate.source').range(1, 0, 1, 10, 'v') end
      )
      h.eq({ 'hello world' }, lines)
    end)
  end)
end)
