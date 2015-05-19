-- Dependencies
require "AI\\USER_AI\\actor"
-- Global
local ST = dofile("./AI/USER_AI/lib/state.lua")
-- Const
-- Custom States
-- Transition Table
local ftran = {}
ftran[ST.follow] = function(me)
  local disguised
  getActors(function(actor)
    if actor == 'player' and actor.canAttack then
      disguised = actor
    end
  end)
  if disguised then
    return ST.chase, {me, disguised}
  end
end
-- Command Handler
local fcmd = 'default'

-- Initializer
local function test_profile(me, ...)
  return ftran, fcmd, ST.follow, {me}
end

return test_profile
