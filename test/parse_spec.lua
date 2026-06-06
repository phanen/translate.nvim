local h = require('test._helpers')

h.env()

describe('translate.parse', function()
  before_each(h.clear)

  describe('parseTransRes', function()
    it('parses google response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { sentences = { { trans = '你好' }, { trans = '世界' } }, src = 'en' },
            { apiType = 'google' }
          )
        end
      )
      h.eq({ { '你好 世界', 'en' } }, r)
    end)

    it('parses microsoft response with multiple translations', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { { translations = { { text = '你好' } }, detectedLanguage = { language = 'en' } } },
            { apiType = 'microsoft' }
          )
        end
      )
      h.eq({ { '你好', 'en' } }, r)
    end)

    it('parses openai response with json content', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { choices = { { message = { content = '[{"text":"你好"},{"text":"世界"}]' } } } },
            { apiType = 'openai', useBatchFetch = true }
          )
        end
      )
      h.eq({ { '你好', '' }, { '世界', '' } }, r)
    end)

    it('parses openai non-batch response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { choices = { { message = { content = 'plain translation' } } } },
            { apiType = 'openai', useBatchFetch = false }
          )
        end
      )
      h.eq({ { 'plain translation', '' } }, r)
    end)

    it('parses mymemory response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { responseData = { translatedText = '你好', match = '0.95' }, responseStatus = 200 },
            { apiType = 'mymemory' }
          )
        end
      )
      h.eq({ { '你好', '0.95' } }, r)
    end)

    it('throws on mymemory non-200 response', function()
      local r = h.exec_lua(function()
        local ok, err = pcall(
          require('translate.parse').parseTransRes,
          { responseStatus = 403, responseDetails = 'INVALID LANGUAGE PAIR' },
          { apiType = 'mymemory' }
        )
        return { ok = ok, err = err or '' }
      end)
      h.eq(false, r.ok)
      h.matches('mymemory error 403', r.err)
      h.matches('INVALID LANGUAGE PAIR', r.err)
    end)

    it('parses baidu type=2 (single sentence) response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes(
            { type = 2, from = 'en', data = { { dst = '你好' }, { dst = '世界' } } },
            { apiType = 'baidu' }
          )
        end
      )
      h.eq({ { '你好 世界', 'en' } }, r)
    end)

    it('parses baidu type=1 (dict) response', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseTransRes({
            type = 1,
            from = 'en',
            result = vim.json.encode({
              content = { { mean = { { cont = { ['你好'] = 'hello' } } } } },
            }),
          }, { apiType = 'baidu' })
        end
      )
      h.eq({ { '你好', 'en' } }, r)
    end)
  end)

  describe('parseAIRes', function()
    it('returns [] for empty input', function()
      local r = h.exec_lua(function() return require('translate.parse').parseAIRes('', true) end)
      h.eq({}, r)
    end)

    it('returns raw for non-batch mode', function()
      local r = h.exec_lua(
        function() return require('translate.parse').parseAIRes('hello', false) end
      )
      h.eq({ { 'hello', '' } }, r)
    end)

    it('parses json array with id/text', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseAIRes(
            '[{"id":0,"text":"你好"},{"id":1,"text":"世界"}]',
            true
          )
        end
      )
      h.eq({ { '你好', '' }, { '世界', '' } }, r)
    end)

    it('parses json with translations key', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseAIRes(
            '{"translations":[{"text":"A"},{"text":"B"}]}',
            true
          )
        end
      )
      h.eq({ { 'A', '' }, { 'B', '' } }, r)
    end)

    it('strips ```json``` wrapper', function()
      local r = h.exec_lua(
        function()
          return require('translate.parse').parseAIRes('```json\n[{"text":"X"}]\n```', true)
        end
      )
      h.eq({ { 'X', '' } }, r)
    end)

    it('falls back to pipe-delimited lines', function()
      local r = h.exec_lua(
        function() return require('translate.parse').parseAIRes('1 | 你好\n2 | 世界', true) end
      )
      h.eq({ { '你好', '' }, { '世界', '' } }, r)
    end)

    it('falls back to plain text lines', function()
      local r = h.exec_lua(
        function() return require('translate.parse').parseAIRes('hello\nworld', true) end
      )
      h.eq({ { 'hello', '' }, { 'world', '' } }, r)
    end)
  end)
end)
