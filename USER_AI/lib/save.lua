--[[

The MIT License (MIT)

Copyright (c) 2015 ediiknorand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]

-- Dependencies
-- Global
local SAVE = {}
-- Const
local AI_PATH = "AI\\USER_AI\\"
-- Util
local function create_save_dir(me)
  local save_dir = AI_PATH.."save\\"..me.owner.gid.."-"..me.class.."\\"
  os.execute("mkdir "..save_dir)
  return save_dir
end

local function write_item(item)
  if type(item) == 'number' or type(item) == 'boolean' then
    return tostring(item)
  elseif type(item) == 'string' then
    return "\'"..item.."\'"
  elseif type(item) == 'table' then
    local s = '{'
    for k,v in pairs(item) do
      s = s..'['..write_item(k)..'] = '..write_item(v)..','
    end
    s = s..'}'
    return s
  end
  return 'nil'
end

local function file_exists(name)
  if type(name) ~= 'string' then
    return false
  end
  -- return os.rename(name, name)
  local fd = io.open(name,'r')
  if not fd then
    return false
  end
  fd:close()
  return true
end

-- Save API
SAVE.put = function(actor, key, data)
  local save_dir = create_save_dir(actor)
  local fd = io.open(save_dir..tostring(key)..".lua", 'w')
  if not fd then
    return false
  end
  fd:write("return "..write_item(data).."\n")
  fd:close()
  return true
end

SAVE.get = function(actor, key)
  local save_file = AI_PATH.."save\\"..actor.owner.gid.."-"..actor.class.."\\"..tostring(key)..".lua"
  -- local save_file = "./AI/USER_AI/save/"..actor.owner.gid.."-"..actor.class.."/"..tostring(key)..".lua"
  if not file_exists(save_file) then
    return nil
  end
  local status,data = pcall(dofile, save_file)
  if status then
    return data
  end
  return nil
end

return SAVE
