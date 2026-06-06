local h = require('test._helpers')

h.env()

describe('translate.req', function()
  before_each(h.clear)

  describe('genGoogle', function()
    it('builds a GET request with the official url', function()
      local url, init = h.exec_lua(
        function()
          return require('translate.req').genGoogle(
            { apiType = 'google', from = 'en', to = 'zh' },
            'hello'
          )
        end
      )
      h.matches('translate%.googleapis%.com', url)
      h.matches('tl=zh', url)
      h.matches('sl=en', url)
      h.matches('q=hello', url)
      h.eq('GET', init.method)
      h.eq(nil, init.body)
    end)

    it('uses custom url when provided', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genGoogle(
            { apiType = 'google', from = 'en', to = 'zh', url = 'http://localhost:8080/t' },
            'hi'
          )
        end
      )
      h.matches('localhost:8080', url)
    end)

    it('adds Authorization header when key is set', function()
      local _, init = h.exec_lua(
        function()
          return require('translate.req').genGoogle(
            { apiType = 'google', from = 'en', to = 'zh', key = 'secret' },
            'hi'
          )
        end
      )
      h.eq('Bearer secret', init.headers['Authorization'])
    end)

    it('url-encodes special characters in text', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genGoogle(
            { apiType = 'google', from = 'en', to = 'zh' },
            'a b'
          )
        end
      )
      h.matches('q=a%%20b', url)
    end)
  end)
end)

describe('translate.api', function()
  before_each(h.clear)

  describe('default_api', function()
    it('returns a sensible default for google', function()
      local a = h.exec_lua(function() return require('translate.api').default_api('google') end)
      h.eq('google', a.apiType)
      h.eq('auto', a.from)
      h.eq('zh-Hans', a.to)
      h.eq(false, a.useBatchFetch)
    end)
  end)
end)
