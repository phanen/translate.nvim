local h = require('test._helpers')

h.env()

describe('translate (bootstrap)', function()
  before_each(h.clear)

  it(
    'loads as a table',
    function() h.eq('table', h.exec_lua('return type(require("translate"))')) end
  )
end)
