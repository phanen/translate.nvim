local h = require('test._helpers')

h.env()

describe('translate.health', function()
  before_each(h.clear)

  it('runs check() without error when setup has not been called', function()
    local ok = h.exec_lua(function()
      return pcall(function() require('translate.health').check() end)
    end)
    h.eq(true, ok)
  end)

  it('runs check() without error after setup', function()
    local ok = h.exec_lua(function()
      require('translate').setup()
      return pcall(function() require('translate.health').check() end)
    end)
    h.eq(true, ok)
  end)
end)
