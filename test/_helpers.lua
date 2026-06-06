---@diagnostic disable: redundant-parameter
local helpers = require('nvim-test.helpers')

local M = {}

M.eq = helpers.eq
M.neq = helpers.neq
M.matches = helpers.matches
M.pcall = helpers.pcall
M.pcall_err = helpers.pcall_err
M.dedent = helpers.dedent

M.exec_lua = helpers.exec_lua
M.feed = helpers.feed
M.sleep = helpers.sleep
M.expectf = helpers.expectf
M.api = helpers.api
M.fn = helpers.fn
M.insert = helpers.insert
M.exc_exec = helpers.exc_exec
M.env = helpers.env

M.setup_path = function()
  M.exec_lua(function(path) package.path = path end, package.path)
end

M.clear = function(init_lua_path)
  helpers.clear(init_lua_path)
  M.setup_path()
end

---@param name string
---@return unknown
M.req = function(name)
  return M.exec_lua(function(n)
    for k in pairs(package.loaded) do
      if k == n or k:sub(1, #n + 1) == n .. '.' then package.loaded[k] = nil end
    end
    return require(n)
  end, name)
end

---@param lines string[]
M.set_lines = function(lines)
  M.exec_lua(function(ls) vim.api.nvim_buf_set_lines(0, 0, -1, false, ls) end, lines)
end

---@return string[]
M.get_lines = function() return M.exec_lua('return vim.api.nvim_buf_get_lines(0, 0, -1, false)') end

---@param ns integer
---@return [integer, integer, integer, table?][]
M.get_extmarks = function(ns)
  return M.exec_lua(
    function(n) return vim.api.nvim_buf_get_extmarks(0, n, 0, -1, { details = true }) end,
    ns
  )
end

return M
