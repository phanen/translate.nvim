---@class translate.BatchOpts
---@field batchSize integer
---@field batchLength integer

---@type translate.BatchOpts
local defaults = { batchSize = 30, batchLength = 4000 }

local M = {}

---@param segments string[]
---@param opts translate.BatchOpts?
---@return string[][]
M.chunk = function(segments, opts)
  local batch_size, batch_length = defaults.batchSize, defaults.batchLength
  if opts then
    batch_size = opts.batchSize or batch_size
    batch_length = opts.batchLength or batch_length
  end
  local batches = {}
  local current = {}
  local current_len = 0
  for _, s in ipairs(segments) do
    local s_len = #s
    local over_size = #current >= batch_size
    local over_len = current_len + s_len > batch_length and #current > 0
    if over_size or over_len then
      batches[#batches + 1] = current
      current = {}
      current_len = 0
    end
    current[#current + 1] = s
    current_len = current_len + s_len
  end
  if #current > 0 then batches[#batches + 1] = current end
  return batches
end

return M
