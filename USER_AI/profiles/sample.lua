-- States
local function stTest(me)
  MoveToOwner(me.gid)
end

-- Transition Table
local ftran = {}

-- Command Handler
local fcmd = 'default'

-- Initializer
local function test_profile(me, ...)
  return ftran, fcmd, stTest, {me}
end

return test_profile
