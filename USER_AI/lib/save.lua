-- Dependencies
-- Global
SAVE = {}
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
