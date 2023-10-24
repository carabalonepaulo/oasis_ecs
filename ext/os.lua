function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function os.get_dir_items(path, name_only)
  name_only = name_only or true

  local output = os.capture('dir "' .. (path or '.') .. '"')
  local list = {}

  for kind, name in output:gmatch('(%w+)>%s+([a-zA-Z0-9%._%-]+)') do
    if not (name == '.' or name == '..') then
      table.insert(list, name_only and name or { kind = kind:lower(), name = name })
    end
  end

  return list
end
