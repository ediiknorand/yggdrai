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


-- dependencies
-- local CONST = dofile("./AI/USER_AI/const.lua")

-- const
local GID_PLAYER_LIMIT = 110000000
-- local GID_WARP_LIMIT   = 110003100  -- Broken Hammer !!
-- local GID_NPC_LIMIT    = 110013000
local V_OWNER               = 0     -- You don't need these values. Really...
local V_POSITION            = 1
local V_GID                 = 2
local V_MOTION              = 3
local V_RANGE               = 4
local V_TARGET              = 5
local V_SKILLRANGE          = 6
local V_CLASS               = 7
local V_HP                  = 8
local V_SP                  = 9
local V_MAXHP               = 10
local V_MAXSP               = 11
local V_MERCLASS            = 12
local V_SKILLRANGE_POSITION = 13
local V_SKILLRANGE_LEVEL    = 14
local CONST = {}
CONST.MARCHER01        = 17
CONST.MUNKNOWN         = 100
CONST.MWILDROSE        = 101
CONST.MDOPPELGANGER    = 102
CONST.MALICE           = 103
CONST.MMIMIC           = 104
CONST.MDISGUISE        = 105
CONST.MGM              = 106
CONST.MPENGINEER       = 107
CONST.MISIS            = 108
local actor_time = {}
local rider_class = {
  [13] = 7,
  [21] = 14,
  [4014] = 4008,
  [4022] = 4015,
  [4036] = 4030,
  [4044] = 4037,
  [4048] = 4047, -- star gladiator rides the AIR!
  [4080] = 4054,
  [4081] = 4060,
  [4082] = 4066,
  [4083] = 4073,
  [4084] = 4056,
  [4085] = 4062,
  [4086] = 4058,
  [4087] = 4064,
  [4109] = 4096,
  [4110] = 4102,
  [4111] = 4098,
  [4112] = 4100,
}

-- util
local function copytable_shallow(t, mt)
  local result = {}
  for i,e in pairs(t) do
    result[i] = e
  end
  if mt then
    setmetatable(t, mt)
  end
  return t
end

local function number_in(number, low, high)
  return number >= low and number <= high
end

local function distAA(a0, a1)
  local xp = a0.x - a1.x
  local yp = a0.y - a1.y
  return math.sqrt(xp*xp + yp*yp)
end

local function timer()
  local spawn_time = GetTick()/1000
  return function()
    return GetTick()/1000 - spawn_time
  end
end

local function add_actors(left, right)
  if type(left) ~= 'table' or type(right) ~= 'table' then
    return nil
  end
  if left.gid and right.gid then
    local result = newGroup()
    result = result + left
    result = result + right
    return result
  end
  if not left.gid and not right.gid then
    local result = copytable_shallow(left, actors_metatable)
    for gid,actor in pairs(right) do
      result = result + actor
    end
    return result
  end
  local actors, actor
  if left.gid then
    actor = left
    actors = right
  else
    actor = right
    actors = left
  end
  local result = copytable_shallow(actors, actors_metatable)
  result[actor.gid] = actor
  return result
end

-- Actor Metatable
local actor_getv = {
  pos = function(gid)
    return {GetV(V_POSITION, gid)}
  end,
  x = function(gid)
    local lx,ly = GetV(V_POSITION, gid)
    return lx
  end,
  y = function(gid)
    local lx,ly = GetV(V_POSITION, gid)
    return ly
  end,
  target = function(gid)
    return getActor(GetV(V_TARGET, gid))
  end,
  motion = function(gid)
    return GetV(V_MOTION, gid)
  end,
  dead = function(gid)
    return GetV(V_MOTION, gid) == 3 or GetV(V_MOTION, gid) < 0
  end,
  owner = function(gid)
    return getActor(GetV(V_OWNER, gid))
  end,
  class = function(gid)
    local lclass = GetV(V_CLASS, gid)
    if not lclass then
      return actor_getv.merclass(gid)
    end
    if gid < GID_PLAYER_LIMIT then
      return rider_class[lclass] or lclass
    end
    return lclass
  end,
  rider = function(gid)
    local lclass = GetV(V_CLASS, gid)
    return lclass and (gid < GID_PLAYER_LIMIT) and rider_class[lclass]
  end,
  range = function(gid)
    return GetV(V_RANGE, gid)
  end,
  hp = function(gid)
    return GetV(V_HP, gid)
  end,
  sp = function(gid)
    return GetV(V_SP, gid)
  end,
  maxhp = function(gid)
    return GetV(V_MAXHP, gid)
  end,
  maxsp = function(gid)
    return GetV(V_MAXSP, gid)
  end,
  merclass = function(gid)
    local lclass = GetV(V_MERCLASS, gid)
    if lclass > 1 then
      return lclass + 16
    end
    local lhp,lsp = actor_getv.maxhp(gid), actor_getv.maxsp(gid)
    if number_in(lhp, 251, 332) and number_in(lsp, 200, 250) then
      return CONST.MARCHER01
    elseif lhp == 7513 and lsp == 201 then
      return CONST.MPENGINEER
    elseif number_in(lhp, 4000, 5000) and number_in(lsp, 50, 64) then
      return CONST.MWILDROSE
    elseif number_in(lhp, 7513, 8500) and number_in(lsp, 201, 249) then
      return CONST.MPENGINEER
    elseif number_in(lhp, 7200, 7512) and number_in(lsp, 200, 249) then
      return CONST.MDOPPELGANGER
    elseif number_in(lhp, 10000, 13000) and number_in(lsp, 220, 299) then
      return CONST.MALICE
    elseif number_in(lhp, 6100, 7200) and number_in(lsp, 180, 249) then
      return CONST.MMIMIC
    elseif number_in(lhp, 7500, 9500) and number_in(lsp, 180, 249) then
      return CONST.MDISGUISE
    elseif number_in(lhp, 7000, 8500) and number_in(lsp, 250, 319) then
      return CONST.MGM
    elseif number_in(lhp, 12299, 14500) and number_in(lsp, 450, 599) then
      return CONST.MISIS
    end
    return CONST.MUNKNOWN
  end,
  skillrange = function(gid)
    return function(skill, skill_level)
      if skill_level then
        return GetV(V_SKILLRANGE_LEVEL, gid, skill, skill_level)
      end
      return GetV(V_SKILLRANGE, gid, skill)
    end
  end,
  skillrangepos = function(gid)
    return function(skill, skill_level)
      return {GetV(V_SKILLRANGE_POSITION, gid, skill, skill_level)}
    end
  end,
  srx = function(gid)
    return function(skill, skill_level)
      local lx,ly = GetV(V_SKILLRANGE_POSITION, gid, skill, skill_level)
      return lx
    end
  end,
  sry = function(gid)
    return function(skill, skill_level)
      local lx,ly = GetV(V_SKILLRANGE_POSITION, gid, skill, skill_level)
      return ly
    end
  end,
  canAttack = function(gid)
    return IsMonster(gid) ~= 0
  end,
  t = function(gid)
    return actor_time[gid]()
  end,
  dist = function(gid)
    return function(act)
      local lx,ly = unpack(actor_getv.pos(gid))
      local lxp = act.x - lx
      local lyp = act.y - ly
      return math.sqrt(lxp*lxp + lyp*lyp)
    end
  end
}
actor_getv.xy = actor_getv.pos
actor_getv.mobid = actor_getv.class
actor_getv.sr = actor_getv.skillrange
actor_getv.srxy = actor_getv.skillrangepos

actor_metatable = {
  __index = function(actor, key)
    if not actor.gid then
      return
    end
    if type(key) == 'string' then
      return actor_getv[key](actor.gid)
    end
  end,
  __add = add_actors,
  __tostring = function(actor)
    if not actor.gid or actor.gid < 0 or not actor.class or actor.class < 0 then
      return "unknown"
    end
    if actor.gid < GID_PLAYER_LIMIT then
      return "player"
    --  elseif actor.gid < GID_WARP_LIMIT then
    --    return "warp"
    --  elseif actor.gid < GID_NPC_LIMIT then
    --    return "npc"
    --  elseif actor.class > 1000 and IsMonster(actor.gid) then
    --    return "monster"
    --  elseif actor.class > 0 and actor.class <= 1000 then
    --    return "summon"
    --  elseif actor.class > 1000 then
    --    return "pet"
    --  else
    --    return "unknown"
    elseif actor.class > 1000 and actor.canAttack then
      return "monster"
    elseif actor.class > 0 and actor.class < 45 then
      return "summon"
    elseif actor.class > 1000 then
      return "pet"
    elseif actor.class == 45 then
      return "warp"
    else
      return "npc"
    end
  end,
  __concat = function(left, right)
    return tostring(left)..tostring(right)
  end,
  __eq = function(l_actor, r_actor)
    if type(l_actor) == 'number' then
      return l_actor == r_actor.gid
    elseif type(r_actor) == 'number' then
      return l_actor.gid == r_actor
    end
    if type(l_actor) == 'string' then
      return l_actor == tostring(r_actor)
    elseif type(r_actor) == 'string' then
      return tostring(l_actor) == r_actor
    end
    return l_actor.gid == r_actor.gid
  end,
  __lt = function(l_actor, r_actor)
    if type(l_actor) == 'number' then
      return l_actor < r_actor.gid
    elseif type(r_actor) == 'number' then
      return l_actor.gid < r_actor
    end
    return l_actor.gid < r_actor.gid
  end,
  __le = function(l_actor, r_actor)
    if type(l_actor) == 'number' then
      return l_actor <= r_actor.gid
    elseif type(r_actor) == 'number' then
      return l_actor.gid <= r_actor
    end
    return l_actor.gid <= r_actor.gid
  end,
  __pow = function(left, right)
    if type(left) ~= 'table' or not left.gid then
      return nil
    end
    if type(right) == 'table' and not right.gid then
      local result = false
      for _,item in pairs(right) do
        result = (result or left^item)
      end
      return result
    elseif type(right) == 'table' then
      return (left.target == right)
    elseif type(right) == 'number' then
      return (left.target.class == right)
    elseif type(right) == 'string' then
      return (tostring(left.target) == right)
    end
    return false
  end
}

-- Actors Metatable
actors_metatable = {
  __index = function(actors, key)
    if key == 'nearest' then
      return function(a)
        local n
	local d
	local dactor
	if type(a) == 'number' then
	  dactor = getActor(a)
	elseif type(a) == 'table' and type(a.gid) == 'number' and a.gid > 0 then
	  dactor = a
	else
	  return nil
	end
        for _,actor in pairs(actors) do
          if type(actor) == 'table' and actor.gid and actor ~= dactor then
	    local d_tmp = distAA(dactor, actor)
	    if not d or d_tmp < d then
	      d = d_tmp
	      n = actor
	    end
	  end
	end
	return n,d
      end
    end
  end,
  __div = function(left, right) -- filter by type/class
    if type(left) == 'table' and (type(right) == 'string' or type(right) == 'number') then
      local result = {}
      setmetatable(result, actors_metatable)
      for gid,actor in pairs(left) do
        if type(right) == 'number' then
          if type(gid) == 'number' and actor.class == right then
            result[gid] = actor
          end
	else
	  if type(gid) == 'number' and tostring(actor) == right then
            result[gid] = actor
	  end
	end
      end
      return result
    elseif type(left) == 'table' and type(right)  == 'table' then
      local result = {}
      setmetatable(result, actors_metatable)
      for _,v in pairs(right) do
        if type(v) == 'number' or type(v) == 'string' then
	  result = result + left/v
	end
      end
      return result
    end
  end,
  __add = add_actors, -- insert actors
  __sub = function(left, right) -- remove actor
    if type(left) ~= 'table' then
      return nil
    end
    local result = copytable_shallow(left, actors_metatable)
    if type(right) == 'number' then
      for gid,actor in pairs(left) do
        if actor.class == right then
	  result[gid] = nil
	end
      end
    elseif type(right) == 'string' then
      for gid,actor in pairs(left) do
        if tostring(actor) == right then
	  result[gid] = nil
	end
      end
    elseif type(right) == 'table' and right.gid then
      result[right.gid] = nil
    elseif type(right) == 'table' then
      for _,item in pairs(right) do
        result = result - item
      end
    end
    return result
  end,
  __unm = function(actors)
    return getActors() - actors
  end,
  __pow = function(left, right)
    if type(left) ~= 'table' then
      return nil
    end
    local actors = left
    local result = copytable_shallow(actors, actors_metatable)
    for gid,actor in pairs(actors) do
      if type(gid) == 'number' and not(actor^right) then
        result[gid] = nil
      end
    end
    return result
  end,
  __tostring = function(actors)
    local s = ""
    for _,actor in pairs(actors) do
      s = s..tostring(actor).." "..actor.gid.." "..actor.class.."\n"
    end
    return s
  end,
  __concat = function(left, right)
    return tostring(left)..tostring(right)
  end
}

-- Actor Time

function actor_update_time()
  local actors = getActors()
  for gid,_ in pairs(actor_time) do
    if not actors[gid] then
      actor_time[gid] = nil
    end
  end
end

-- Actor API

function getActor(gid)
  if type(gid) ~= 'number' then
    return nil
  end
  local actor = {}
  actor.gid = gid
  if not actor_time[gid] then
    actor_time[gid] = timer()
  end
  return setmetatable(actor, actor_metatable)
end

function getActors(foreach)
  local gids = GetActors()
  local actors = {}
  local forfunction
  if foreach and type(foreach) == 'function' then
    forfunction = foreach
  end
  for _,gid in pairs(gids) do
    actors[gid] = getActor(gid)
    if forfunction then
      forfunction(actors[gid])
    end
  end
  return setmetatable(actors, actors_metatable)
end

function newActor() -- useful to set "imaginary" actors (like cell positions)
  local actor = {}
  actor.gid = -1
  actor.t = -1
  return setmetatable(actor, actor_metatable)
end

function newGroup() -- empty group of actors
  local group = {}
  return setmetatable(group, actors_metatable)
end
