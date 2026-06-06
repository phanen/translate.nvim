local h = require('test._helpers')

h.env()

describe('translate.trans', function()
  before_each(h.clear)

  local mock = function(body)
    h.exec_lua(function(b)
      local http = require('translate.http')
      http.set_transport(function(_, cb) cb(200, b) end)
    end, body)
  end

  it('translates a single segment via google', function()
    local r = h.exec_lua(function()
      local trans = require('translate.trans')
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ sentences = { { trans = '你好' } }, src = 'en' }))
        end
      )
      return trans.handle(
        { apiType = 'google', from = 'en', to = 'zh', httpTimeout = 30000 },
        { 'hello' }
      )
    end)
    h.eq({ '你好' }, r)
  end)

  it('translates a single segment via microsoft', function()
    local r = h.exec_lua(function()
      local trans = require('translate.trans')
      require('translate.http').set_transport(
        function(_, cb)
          cb(
            200,
            vim.json.encode({
              { translations = { { text = '你好' } }, detectedLanguage = { language = 'en' } },
            })
          )
        end
      )
      return trans.handle(
        { apiType = 'microsoft', from = 'en', to = 'zh', httpTimeout = 30000 },
        { 'hello' }
      )
    end)
    h.eq({ '你好' }, r)
  end)

  it('translates a single segment via openai', function()
    local r = h.exec_lua(function()
      local trans = require('translate.trans')
      require('translate.http').set_transport(
        function(_, cb)
          cb(200, vim.json.encode({ choices = { { message = { content = '你好' } } } }))
        end
      )
      return trans.handle({
        apiType = 'openai',
        from = 'en',
        to = 'zh',
        key = 'k',
        httpTimeout = 30000,
        useBatchFetch = false,
      }, { 'hello' })
    end)
    h.eq({ '你好' }, r)
  end)

  it('chunks large input into multiple http calls', function()
    local r = h.exec_lua(function()
      local count = { 0 }
      require('translate.http').set_transport(function(_, cb)
        count[1] = count[1] + 1
        cb(200, vim.json.encode({ sentences = { { trans = 'tr' } }, src = 'en' }))
      end)
      local trans = require('translate.trans')
      local out = trans.handle(
        { apiType = 'google', from = 'en', to = 'zh', httpTimeout = 30000 },
        { 'a', 'b', 'c', 'd', 'e' },
        { batchSize = 2, batchLength = 1000 }
      )
      return { out = out, calls = count[1] }
    end)
    h.eq(3, r.calls)
    h.eq({ 'tr', 'tr', 'tr' }, r.out)
  end)

  it('throws on http error', function()
    local r = h.exec_lua(function()
      local trans = require('translate.trans')
      require('translate.http').set_transport(function(_, cb) cb(500, 'server error') end)
      local ok, err = pcall(
        trans.handle,
        { apiType = 'google', from = 'en', to = 'zh', httpTimeout = 30000 },
        { 'x' }
      )
      return { ok = ok, err = err or '' }
    end)
    h.eq(false, r.ok)
    h.matches('http error 500', r.err)
  end)

  it('throws on unknown api type', function()
    local r = h.exec_lua(function()
      local trans = require('translate.trans')
      local ok, err = pcall(trans.handle, { apiType = 'unknown', from = 'en', to = 'zh' }, { 'x' })
      return { ok = ok, err = err or '' }
    end)
    h.eq(false, r.ok)
    h.matches('unknown api type', r.err)
  end)
end)
