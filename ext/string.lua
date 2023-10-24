---@diagnostic disable: param-type-mismatch
local crc32 = require 'vendor.crc32'
local Array = require 'lib.array'

--- @param text string
--- @param sep string
--- @param allow_empty boolean?
function string.split(text, sep, allow_empty)
  local parts = Array()
  local index = 0
  local last_index = 1

  local capture = function(final_index)
    local final_index = final_index or index - 1
    local value = text:sub(last_index, final_index)
    if value ~= '' then
      parts:insert(value)
    elseif allow_empty then
      parts:insert(value)
    end
  end

  local next = function()
    ---@diagnostic disable-next-line: cast-local-type
    index = text:find(sep, last_index)
  end

  next()
  while index do
    capture()
    last_index = index + 1
    next()
  end

  capture(text:len())

  return parts
end

function string.insert(self, pos, value)
  if not value then
    return self .. pos
  end

  return self:sub(1, pos) .. value .. self:sub(pos + 1, self:len())
end

function string.remove_slice(self, begin_pos, end_pos)
  return self:sub(1, begin_pos - 1) .. self:sub(end_pos, self:len())
end

function string.capitalize(self)
  return (self:gsub("^%l", string.upper))
end

function string.beautify(self)
  return (#self <= 2 and self:upper() or self:capitalize())
end

function string.sneak_case_to_pascal_case(self)
  return self:split('_')
      :map(string.beautify)
      :concat()
end

function string.starts_with(self, str)
  return self:sub(1, #str) == str
end

function string.ends_with(self, str)
  local i = #self - #str
  return self:sub(i + 1, i + #str) == str
end

function string.hash(self)
  return crc32(self)
end

function string.trim_prefix(self, prefix)
  return (self:gsub('^' .. prefix, ''))
end

function string.trim_sufix(self, sufix)
  return (self:gsub(sufix .. '$', ''))
end

function string.get_file_name(self)
  return self:sub(1, self:find('%.') - 1)
end

function string.get_file_extension(self)
  return self:sub(self:find('%.') + 1, #self)
end
