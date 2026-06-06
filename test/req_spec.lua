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

  describe('genMicrosoft', function()
    it('builds a POST request with the official url', function()
      local url, init = h.exec_lua(
        function()
          return require('translate.req').genMicrosoft(
            { apiType = 'microsoft', from = 'en', to = 'zh' },
            'hello'
          )
        end
      )
      h.matches('api%-edge%.cognitive%.microsofttranslator%.com', url)
      h.matches('from=en', url)
      h.matches('to=zh', url)
      h.matches('api%-version=3%.0', url)
      h.eq('POST', init.method)
      h.matches('"Text":"hello"', init.body)
    end)

    it('adds Ocp-Apim-Subscription-Key when key is set', function()
      local _, init = h.exec_lua(
        function()
          return require('translate.req').genMicrosoft(
            { apiType = 'microsoft', from = 'en', to = 'zh', key = 'secret' },
            'hi'
          )
        end
      )
      h.eq('secret', init.headers['Ocp-Apim-Subscription-Key'])
    end)

    it('adds region header when region is set', function()
      local _, init = h.exec_lua(
        function()
          return require('translate.req').genMicrosoft(
            { apiType = 'microsoft', from = 'en', to = 'zh', region = 'eastasia' },
            'hi'
          )
        end
      )
      h.eq('eastasia', init.headers['Ocp-Apim-Subscription-Region'])
    end)

    it('uses custom url when provided', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genMicrosoft(
            { apiType = 'microsoft', from = 'en', to = 'zh', url = 'http://localhost/t' },
            'hi'
          )
        end
      )
      h.matches('localhost', url)
    end)
  end)

  describe('genMyMemory', function()
    it('builds a GET request with default url and langpair', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genMyMemory(
            { apiType = 'mymemory', from = 'en', to = 'zh' },
            'hello'
          )
        end
      )
      h.matches('api%.mymemory%.translated%.net', url)
      h.matches('langpair=en%%7czh', url)
      h.matches('q=hello', url)
    end)

    it('falls back to en when from is auto', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genMyMemory(
            { apiType = 'mymemory', from = 'auto', to = 'zh' },
            'hi'
          )
        end
      )
      h.matches('langpair=en%%7czh', url)
    end)

    it('adds de (email) param when key is set', function()
      local url = h.exec_lua(
        function()
          return require('translate.req').genMyMemory(
            { apiType = 'mymemory', from = 'en', to = 'zh', key = 'me@x.com' },
            'hi'
          )
        end
      )
      h.matches('de=me@x%.com', url)
    end)
  end)

  describe('genOpenAI', function()
    it('builds a POST request with default url and model', function()
      local url, init = h.exec_lua(
        function()
          return require('translate.req').genOpenAI(
            { apiType = 'openai', from = 'en', to = 'zh', key = 'k' },
            'hello'
          )
        end
      )
      h.matches('api%.openai%.com', url)
      h.eq('POST', init.method)
      h.matches('"model":"gpt%-4"', init.body)
      h.matches('"role":"system"', init.body)
      h.matches('"role":"user"', init.body)
      h.matches('"content":"hello"', init.body)
    end)

    it('adds Authorization Bearer header', function()
      local _, init = h.exec_lua(
        function()
          return require('translate.req').genOpenAI(
            { apiType = 'openai', to = 'zh', key = 'secret' },
            'hi'
          )
        end
      )
      h.eq('Bearer secret', init.headers['Authorization'])
    end)

    it('uses custom url and model', function()
      local url, init = h.exec_lua(
        function()
          return require('translate.req').genOpenAI({
            apiType = 'openai',
            to = 'zh',
            key = 'k',
            url = 'http://localhost/v1',
            model = 'glm-4',
          }, 'hi')
        end
      )
      h.matches('localhost', url)
      h.matches('"model":"glm%-4"', init.body)
    end)

    it('returns user_msg as third value', function()
      local user_msg = h.exec_lua(function()
        local _, _, m =
          require('translate.req').genOpenAI({ apiType = 'openai', to = 'zh', key = 'k' }, 'hello')
        return m
      end)
      h.eq('user', user_msg.role)
      h.eq('hello', user_msg.content)
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
