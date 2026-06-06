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
