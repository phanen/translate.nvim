local h = require('test._helpers')

h.env()

describe('translate.cache', function()
  before_each(h.clear)

  it('returns nil for miss', function()
    local got = h.exec_lua(
      function() return require('translate.cache').get('google', 'hi', 'en', 'zh') end
    )
    h.eq(nil, got)
  end)

  it('returns the stored value on hit', function()
    h.exec_lua(function() require('translate.cache').set('google', 'hi', 'en', 'zh', '你好') end)
    local got = h.exec_lua(
      function() return require('translate.cache').get('google', 'hi', 'en', 'zh') end
    )
    h.eq('你好', got)
  end)

  it('keys are scoped by api_type / from / to', function()
    h.exec_lua(function()
      require('translate.cache').set('google', 'hi', 'en', 'zh', 'A')
      require('translate.cache').set('microsoft', 'hi', 'en', 'zh', 'B')
      require('translate.cache').set('google', 'hi', 'en', 'ja', 'C')
    end)
    h.eq(
      'A',
      h.exec_lua(function() return require('translate.cache').get('google', 'hi', 'en', 'zh') end)
    )
    h.eq(
      'B',
      h.exec_lua(
        function() return require('translate.cache').get('microsoft', 'hi', 'en', 'zh') end
      )
    )
    h.eq(
      'C',
      h.exec_lua(function() return require('translate.cache').get('google', 'hi', 'en', 'ja') end)
    )
  end)

  it('clear empties the cache', function()
    h.exec_lua(function()
      require('translate.cache').set('google', 'hi', 'en', 'zh', 'A')
      require('translate.cache').clear()
    end)
    local got = h.exec_lua(
      function() return require('translate.cache').get('google', 'hi', 'en', 'zh') end
    )
    h.eq(nil, got)
  end)
end)
