local AI_PATH = "./AI/USER_AI/"
local yggdrai = dofile(AI_PATH.."yggdrai.lua")

function AI(my_gid)
  yggdrai(AI_PATH.."profiles/test.lua", my_gid)
end
