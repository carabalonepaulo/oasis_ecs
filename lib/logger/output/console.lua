local color_string = string.char(27) .. '[%dm'
local format_color = function(n) return color_string:format(n) end
local colors = {
  format_color(0),  -- info
  format_color(34), -- debug
  format_color(33), -- warning
  format_color(31)  -- error
}
local reset = format_color(0)
local dim = format_color(2)

return function(level, message)
  local now = os.date('%H:%M:%S')
  local color = colors[level]

  io.write(color, '[', reset, dim, now, reset, color, '] ', reset)
  io.write(message .. '\n')
end
