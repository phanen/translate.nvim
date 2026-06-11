local h = require('test._helpers')

h.env()

describe('translate.ms_auth', function()
  before_each(h.clear)

  it('fetches a token from edge.microsoft.com', function()
    local token = h.exec_lua(function()
      require('translate.http').set_transport(function(opts, cb)
        _G._t_url = opts.url
        cb(200, 'mock-microsoft-token')
      end)
      require('translate.ms_auth').set(nil)
      return require('translate.ms_auth').fetch()
    end)
    h.eq('mock-microsoft-token', token)
  end)

  it('caches the token between calls', function()
    local calls = h.exec_lua(function()
      _G._t_cnt = 0
      require('translate.http').set_transport(function(_, cb)
        _G._t_cnt = _G._t_cnt + 1
        cb(200, 'tok')
      end)
      require('translate.ms_auth').set(nil)
      local a = require('translate.ms_auth').fetch()
      local b = require('translate.ms_auth').fetch()
      return { a = a, b = b, count = _G._t_cnt }
    end)
    h.eq('tok', calls.a)
    h.eq('tok', calls.b)
    h.eq(1, calls.count)
  end)

  it('allows manual override via set()', function()
    local token = h.exec_lua(function()
      require('translate.ms_auth').set('manual-token')
      return require('translate.ms_auth').fetch()
    end)
    h.eq('manual-token', token)
  end)
end)
