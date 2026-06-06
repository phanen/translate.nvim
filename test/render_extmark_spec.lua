local h = require('test._helpers')

h.env()

describe('translate.render (extmark)', function()
  before_each(h.clear)

  describe('extmark_eol', function()
    it('attaches virt_text at eol for each item', function()
      local marks = h.exec_lua(function()
        require('translate').setup()
        local render = require('translate.render')
        local ns = require('translate.ns').eol
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello', 'world' })
        render.extmark_eol(0, { '你好', '世界' }, {
          { srow = 0, scol = 0, erow = 0, ecol = 5 },
          { srow = 1, scol = 0, erow = 1, ecol = 5 },
        })
        return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      end)
      h.eq(2, #marks)
      h.eq('eol', marks[1][4].virt_text_pos)
      h.eq({ { '你好', 'TranslateTrans' } }, marks[1][4].virt_text)
      h.eq({ { '世界', 'TranslateTrans' } }, marks[2][4].virt_text)
    end)
  end)

  describe('extmark_below', function()
    it('attaches virt_lines below for each item', function()
      local marks = h.exec_lua(function()
        require('translate').setup()
        local render = require('translate.render')
        local ns = require('translate.ns').below
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
        render.extmark_below(0, { '你好' }, { { srow = 0, scol = 0, erow = 0, ecol = 5 } })
        return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
      end)
      h.eq(1, #marks)
      h.eq({ { { '你好', 'TranslateTrans' } } }, marks[1][4].virt_lines)
    end)
  end)

  describe('extmark_clear', function()
    it('removes marks from the eol namespace', function()
      local count = h.exec_lua(function()
        require('translate').setup()
        local render = require('translate.render')
        local ns = require('translate.ns').eol
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
        render.extmark_eol(0, { '你好' }, { { srow = 0, scol = 0, erow = 0, ecol = 5 } })
        render.extmark_clear(0, 'eol')
        return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
      end)
      h.eq(0, count)
    end)
  end)
end)
