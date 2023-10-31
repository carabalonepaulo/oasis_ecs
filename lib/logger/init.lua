--- @enum LogLevel
local LEVEL = {
  info = 1,
  debug = 2,
  warning = 3,
  error = 4
}

local outputs = {
  require 'lib.logger.output.console',
  require 'lib.logger.output.file'
}

--- @param level LogLevel
--- @param message string
--- @param ... any
local function write(level, message, ...)
  for i = 1, #outputs do
    outputs[i](level, string.format(message, ...))
  end
end

--- @param message string
--- @param ... any
local function info(message, ...)
  write(LEVEL.info, message, ...)
end

--- @param message string
--- @param ... any
local function debug(message, ...)
  write(LEVEL.debug, message, ...)
end

--- @param message string
--- @param ... any
local function warning(message, ...)
  write(LEVEL.warning, message, ...)
end

--- @param message string
--- @param ... any
local function error(message, ...)
  write(LEVEL.error, message, ...)
end

return {
  write = write,
  info = info,
  debug = debug,
  warning = warning,
  error = error
}
