local h = require('test._helpers')

h.env()

describe('translate.render (echo)', function()
  before_each(h.clear)

  it('builds chunks with TranslateTrans highlight', function()
    local chunks = h.exec_lua(function()
      local captured
      require('translate.render').echo({ '你好' }, function(c) captured = c end)
      return captured
    end)
    h.eq({ { '你好', 'TranslateTrans' } }, chunks)
  end)

  it('builds one chunk per item', function()
    local chunks = h.exec_lua(function()
      local captured
      require('translate.render').echo({ '你好', '世界' }, function(c) captured = c end)
      return captured
    end)
    h.eq({ { '你好', 'TranslateTrans' }, { '世界', 'TranslateTrans' } }, chunks)
  end)

  it('emits to nvim_echo when no sink is provided', function()
    local ok = h.exec_lua(function()
      return pcall(function() require('translate.render').echo({ 'hi' }) end)
    end)
    h.eq(true, ok)
  end)
end)
