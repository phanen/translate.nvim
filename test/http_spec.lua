local h = require('test._helpers')

h.env()

describe('translate.http', function()
  before_each(h.clear)

  describe('set_transport / fetch', function()
    it('uses the injected transport', function()
      local status, body = h.exec_lua(function()
        local http = require('translate.http')
        http.set_transport(function(_, cb) cb(200, '{"ok":true}') end)
        return http.fetch({ url = 'http://x' })
      end)
      h.eq(200, status)
      h.eq('{"ok":true}', body)
    end)

    it('replaces previous transport on subsequent set', function()
      local status, body = h.exec_lua(function()
        local http = require('translate.http')
        http.set_transport(function(_, cb) cb(500, 'old') end)
        http.set_transport(function(_, cb) cb(201, 'new') end)
        return http.fetch({ url = 'http://x' })
      end)
      h.eq(201, status)
      h.eq('new', body)
    end)

    it('passes opts through to the transport', function()
      local got = h.exec_lua(function()
        local http = require('translate.http')
        local seen
        http.set_transport(function(o, cb)
          seen = o
          cb(200, '')
        end)
        http.fetch({
          url = 'http://x',
          method = 'POST',
          headers = { ['X-Test'] = 'yes' },
          body = 'payload',
        })
        return seen
      end)
      h.eq('http://x', got.url)
      h.eq('POST', got.method)
      h.eq('yes', got.headers['X-Test'])
      h.eq('payload', got.body)
    end)
  end)
end)
