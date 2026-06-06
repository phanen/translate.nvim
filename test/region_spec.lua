local h = require('test._helpers')

h.env()

describe('translate.region', function()
  before_each(h.clear)

  it('cword triggers google translate with the cword text', function()
    h.set_lines({ 'hello world' })
    local url = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(function(opts, cb)
        _G._test_url = opts.url
        cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_url
    end)
    h.matches('translate%.googleapis%.com', url)
    h.matches('q=hello', url)
  end)

  it('echoes the translation to the render sink', function()
    h.set_lines({ 'hello world' })
    local captured = h.exec_lua(function()
      require('translate').setup({ target = 'echo' })
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      local captured_chunks
      local render = require('translate.render')
      local orig_echo = render.echo
      render.echo = function(items, sink)
        sink = sink or function(c) captured_chunks = c end
        orig_echo(items, sink)
      end
      require('translate').region()
      return captured_chunks
    end)
    h.eq({ { '你好', 'TranslateTrans' } }, captured)
  end)

  it('uses cWORD for cword when called from normal mode', function()
    h.set_lines({ 'hello' })
    local url = h.exec_lua(function()
      require('translate').setup()
      require('translate.http').set_transport(function(opts, cb)
        _G._test_url = opts.url
        cb(200, vim.json.encode({ sentences = { { trans = 'hi' } }, src = 'en' }))
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_url
    end)
    h.matches('q=hello', url)
  end)

  it('is a no-op when setup has not been called', function()
    local ok = h.exec_lua(function()
      return pcall(function() require('translate').region() end)
    end)
    h.eq(true, ok)
  end)

  it('uses config.api = microsoft when set', function()
    h.set_lines({ 'hello' })
    local url = h.exec_lua(function()
      require('translate').setup({ api = 'microsoft' })
      require('translate.http').set_transport(function(opts, cb)
        _G._test_url = opts.url
        cb(
          200,
          vim.json.encode({
            { translations = { { text = '你好' } }, detectedLanguage = { language = 'en' } },
          })
        )
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_url
    end)
    h.matches('api%-edge%.cognitive%.microsofttranslator%.com', url)
  end)

  it('uses config.api = openai when set', function()
    h.set_lines({ 'hello' })
    local url = h.exec_lua(function()
      require('translate').setup({ api = 'openai' })
      require('translate.http').set_transport(function(opts, cb)
        _G._test_url = opts.url
        cb(200, vim.json.encode({ choices = { { message = { content = '你好' } } } }))
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_url
    end)
    h.matches('api%.openai%.com', url)
  end)

  it('forwards creds.key to microsoft api cfg', function()
    h.set_lines({ 'hello' })
    local headers = h.exec_lua(function()
      require('translate').setup({
        api = 'microsoft',
        creds = { key = 'my-azure-key', region = 'eastasia' },
      })
      require('translate.http').set_transport(function(opts, cb)
        _G._test_headers = opts.headers
        cb(
          200,
          vim.json.encode({
            { translations = { { text = 'x' } }, detectedLanguage = { language = 'en' } },
          })
        )
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_headers
    end)
    h.eq('my-azure-key', headers['Ocp-Apim-Subscription-Key'])
    h.eq('eastasia', headers['Ocp-Apim-Subscription-Region'])
  end)

  it('uses config.api = mymemory when set (no key required)', function()
    h.set_lines({ 'hello' })
    local url = h.exec_lua(function()
      require('translate').setup({ api = 'mymemory' })
      require('translate.http').set_transport(function(opts, cb)
        _G._test_url = opts.url
        cb(
          200,
          vim.json.encode({ responseData = { translatedText = '你好' }, responseStatus = 200 })
        )
      end)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      require('translate').region()
      return _G._test_url
    end)
    h.matches('api%.mymemory%.translated%.net', url)
    h.matches('langpair=en%%7czh%-Hans', url)
  end)
end)
