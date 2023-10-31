local crc32 = require 'vendor.crc32'
local Array = require 'lib.collections.array'

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

--- @param self string
--- @param pos integer
--- @param value string
--- @return string
function string.insert(self, pos, value)
  if not value then
    return self .. pos
  end

  return self:sub(1, pos) .. value .. self:sub(pos + 1, self:len())
end

--- @param self string
--- @param begin_pos integer
--- @param end_pos integer
--- @return string
function string.slice(self, begin_pos, end_pos)
  return self:sub(1, begin_pos - 1) .. self:sub(end_pos, self:len())
end

--- @param self string
--- @return string
function string.capitalize(self)
  return (self:gsub("^%l", string.upper))
end

--- @param self string
--- @return string
function string.beautify(self)
  return (#self <= 2 and self:upper() or self:capitalize())
end

--- @param self string
--- @return string
function string.sneak_case_to_pascal_case(self)
  return self:split('_')
      :map(string.beautify)
      :concat()
end

--- @param self string
--- @param str string
--- @return boolean
function string.starts_with(self, str)
  return self:sub(1, #str) == str
end

--- @param self string
--- @param str string
--- @return boolean
function string.ends_with(self, str)
  local i = #self - #str
  return self:sub(i + 1, i + #str) == str
end

--- @param self string
--- @return integer
function string.hash(self)
  return crc32(self)
end

--- @param self string
--- @param prefix string
--- @return string
function string.trim_prefix(self, prefix)
  return (self:gsub('^' .. prefix, ''))
end

--- @param self string
--- @param sufix string
--- @return string
function string.trim_sufix(self, sufix)
  return (self:gsub(sufix .. '$', ''))
end

--- @param self string
--- @return string
function string.get_file_name(self)
  return self:sub(1, self:find('%.') - 1)
end

--- @param self string
--- @return string
function string.get_file_extension(self)
  return self:sub(self:find('%.') + 1, #self)
end
