-- Dependencies
require "./AI/USER_AI/actor.lua"
-- Global
-- Const

-- States
local function stInit(me)
  MoveToOwner(me.gid)
end

local function stFollow(me, target)
  Move(me.gid, unpack(target.xy))
end

-- Transition Table
local ftran = {}
ftran[stInit] = function(me)
  local disguised
  getActors(function(actor)
    if actor == 'player' and actor.canAttack then
      disguised = actor
    end
  end)
  if disguised then
    return stFollow, {me, disguised}
  end
end
-- Command Handler
local fcmd = 'default'

-- Initializer
local function test_profile(me, ...)
  return ftran, fcmd, stInit, {me}
end

return test_profile
