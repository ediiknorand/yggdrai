-- dependencies
require "./AI/USER_AI/actor.lua" -- global dependency

-- const
local CONST = {}
CONST.CMD_NONE           =  0
CONST.CMD_MOVE           =  1
CONST.CMD_STOP           =  2
CONST.CMD_ATTACK         =  3
CONST.CMD_ATTACK_AREA    =  4
CONST.CMD_PATROL         =  5
CONST.CMD_HOLD           =  6
CONST.CMD_SKILL          =  7
CONST.CMD_SKILL_AREA     =  8
CONST.CMD_FOLLOW         =  9

-- Useful variables
local yggdrai_profile
local yggdrai_state
local yggdrai_arg
local yggdrai_cmd
local yggdrai_tran
local yggdrai_actor

-- Command Handler
local cmd_state = {}

cmd_state[CONST.CMD_NONE] = function(...)
end

cmd_state[CONST.CMD_MOVE] = function(actor, x, y, ...)
  Move(actor.gid, x, y)
end

cmd_state[CONST.CMD_STOP] = function(actor, ...)
  Move(actor.gid, actor.xy)
end

cmd_state[CONST.CMD_ATTACK] = function(actor, target, ...)
  Move(actor.gid, actor.xy)
  Attack(actor.gid, target.gid)
end

cmd_state[CONST.CMD_ATTACK_AREA] = function(actor, x, y, ...)
  Move(actor.gid, x, y)
end

cmd_state[CONST.CMD_PATROL] = function (actor, ...)
  local t = GetTick()/1000
  local owner = actor.owner
  Move(actor.gid, owner.x+2*math.cos(t), owner.y+2*math.sin(t))
end

cmd_state[CONST.CMD_HOLD] = function(actor, ...)
end

cmd_state[CONST.CMD_SKILL] = function(actor, skill_level, skill, target, ...)
  SkillObject(actor.gid, skill_level, skill, target.gid)
end

cmd_state[CONST.CMD_SKILL_AREA] = function(actor, skill_level, skill, x, y, ...)
  SkillGround(actor.gid, skill_level, skill, x, y)
end

cmd_state[CONST.CMD_FOLLOW] = function(actor, ...)
  MoveToOwner(actor.gid)
end

local cmd_handler_table_i = {}
local cmd_handler_table_init
local function cmd_process(actor, cmd_handler)
  local msg = GetMsg(actor.gid)
  local result
  if msg[1] and msg[1] > 0 then
    if cmd_handler == 'default' then
      result = {cmd_state[msg[1]](actor, msg[2], msg[3], msg[4], msg[5])}
    elseif type(cmd_handler) == 'function' then -- transition function
      result = {cmd_handler(actor, unpack(msg))}
    elseif type(cmd_handler) == 'table' then
      local cmd_handler_item = cmd_handler[msg[1]]
      if type(cmd_handler_item) == 'function' then -- state function
        -- cmd_handler_item(actor, msg[2], msg[3], msg[4], msg[5])
        result = {cmd_handler_item, {actor, msg[2], msg[3], msg[4], msg[5]}}
      elseif type(cmd_handler_item) == 'table' then -- array of state functions
        local cmd_handler_table_v
        cmd_handler_table_i[msg[1]],cmd_handler_table_v = next(cmd_handler_item, cmd_handler_table_i[msg[1]])
	if type(cmd_handler_table_v) == 'function' then -- state function
	  -- cmd_handler_table_v(actor, msg[2], msg[3], msg[4], msg[5])
	  result = {cmd_handler_table_v, {actor, msg[2], msg[3], msg[4], msg[5]}}
	  cmd_handler_table_init = true
	elseif not cmd_handler_table_v and cmd_handler_table_init then
	  cmd_handler_table_i[msg[1]],cmd_handler_table_v = next(cmd_handler_item, nil)
	  if type(cmd_handler_table_v) == 'function' then -- repeat from the begining
	    -- cmd_handler_table_v(actor, msg[2], msg[3], msg[4], msg[5])
	    result = {cmd_handler_table_v, {actor, msg[2], msg[3], msg[4], msg[5]}}
	  end
	end
      end
    end
  end
  if not result then
    return nil
  end
  return unpack(result)
end

-- YggdrAI Core
local function yggdrai_run(actor, ftran, fcmd, fstate, farg)
  if type(actor) ~= 'table' or type(fstate) ~= 'function' or type(farg) ~= 'table' then
    return false
  end
  if not actor.gid then
    return false
  end
  fstate(unpack(farg))
  local st,ar = cmd_process(actor, fcmd)
  if st and ar then
    yggdrai_state = st
    yggdrai_arg = ar
    return true
  end
  if type(ftran[fstate]) == 'function' then
    st,ar = ftran[fstate](unpack(farg))
    if st and ar then
      yggdrai_state = st
      yggdrai_arg = ar
      return true
    end
  elseif type(ftran[fstate]) == 'table' then
    local status,st,ar = pcall(ftran[fstate], unpack(farg))
    if status and st and ar then
      yggdrai_state = st
      yggdrai_arg = ar
      return true
    elseif not status then
      return false
    end
  end
  return true
end

-- YggdrAI loader
local function yggdrai_loader(profile_path, gid, ...)
  yggdrai_profile = dofile(profile_path)
  if type(yggdrai_profile) ~= 'function' then
    yggdrai_profile = nil
    return false
  end
  yggdrai_actor = getActor(gid)
  if not yggdrai_actor then
    return false
  end
  local ftran, fcmd, fstate, farg = yggdrai_profile(yggdrai_actor, unpack(arg))
  if not(ftran and fcmd and fstate and farg) then
    yggdrai_profile = nil
    return false
  end
  yggdrai_tran, yggdrai_cmd, yggdrai_state, yggdrai_arg = ftran, fcmd, fstate, farg
  return true
end

-- YggdrAI API
local function yggdrai(profile_path, gid, ...)
  if not yggdrai_profile then
    yggdrai_loader(profile_path, gid, unpack(arg))
    return
  end
  yggdrai_run(yggdrai_actor, yggdrai_tran, yggdrai_cmd, yggdrai_state, yggdrai_arg)
  actor_update_time()
end

return yggdrai
