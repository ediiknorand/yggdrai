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
require "./AI/USER_AI/actor.lua"
-- Constants
local GID_BASE = 110000000
local GID_SHIFT = 0
local RENEWAL = true
local CONST = dofile("./AI/USER_AI/lib/const.lua")
local V_MOTION   = 3
local V_TARGET   = 5
local V_CLASS    = 7
local V_MERCLASS = 12
-- Utility
local function copytable_shallow(t,mt)
  local result = {}
  for i,v in pairs(t) do
    result[i] = v
  end
  if mt then
    return setmetatable(result, mt)
  end
  return result
end
--  Player Class
local motion2class = {
  [CONST.MOTION_VULCAN] = CONST.CLOWN,
  [CONST.MOTION_SPIRAL] = CONST.LORD_KNIGHT,
  [CONST.MOTION_COUNTER] = CONST.KNIGHT,
  [CONST.MOTION_DANCE] = CONST.DANCER,
  [CONST.MOTION_PERFORM] = CONST.BARD,
  [CONST.MOTION_SHARPSHOOT] = CONST.SNIPER,
  [CONST.MOTION_JUMP_UP] = CONST.TAEKWON_KID,
  [CONST.MOTION_JUMP_FALL] = CONST.TAEKWON_KID,
  [CONST.MOTION_PWHIRL] = CONST.TAEKWON_KID,
  [CONST.MOTION_PAXE] = CONST.TAEKWON_KID,
  [CONST.MOTION_PCOUNTER] = CONST.TAEKWON_KID,
  [CONST.MOTION_TUMBLE] = CONST.TAEKWON_KID,
  [CONST.MOTION_COUNTERK] = CONST.TAEKWON_KID,
  [CONST.MOTION_FLYK] = CONST.TAEKWON_KID,
  [CONST.MOTION_BIGTOSS] = CONST.CREATOR,
  [CONST.MOTION_WHIRLK] = CONST.TAEKWON_KID,
  [CONST.MOTION_AXEK] = CONST.TAEKWON_KID,
  [CONST.MOTION_ROUNDK] = CONST.TAEKWON_KID,
  [CONST.MOTION_COMFORT] = CONST.TAEKWON_MASTER,
  [CONST.MOTION_HEAT] = CONST.TAEKWON_MASTER,
  [CONST.MOTION_NINJAGROUND] = CONST.NINJA,
  [CONST.MOTION_NINJAHAND] = CONST.NINJA,
  [CONST.MOTION_NINJACAST] = CONST.NINJA,
  [CONST.MOTION_GUNTWIN] = CONST.GUNSLINGER,
  [CONST.MOTION_GUNFLIP] = CONST.GUNSLINGER,
  [CONST.MOTION_GUNSHOW] = CONST.GUNSLINGER,
  [CONST.MOTION_GUNCAST] = CONST.GUNSLINGER,
  [CONST.MOTION_FULLBLAST] = CONST.GUNSLINGER,
}

local motion2classf = {
  [CONST.MOTION_SOULLINK] = function(gid)
    local target_gid = GetV(V_TARGET, gid)
    local tmotion = GetV(V_MOTION, target_gid)
    if tmotion == CONST.MOTION_DAMAGE then
      return CONST.TAEKWON_KID
    end
    return CONST.SOUL_LINKER
  end,
}

local motion_confirm = {
  [CONST.MOTION_SPIRAL] = not RENEWAL,
  [CONST.MOTION_SHARPSHOOT] = not RENEWAL,
  [CONST.MOTION_BIGTOSS] = not RENEWAL,
  [CONST.MOTION_COMFORT] = true,
  [CONST.MOTION_HEAT] = true,
  [CONST.MOTION_NINJAGROUND] = not RENEWAL,
  [CONST.MOTION_NINJAHAND] = not RENEWAL,
  [CONST.MOTION_NINJACAST] = not RENEWAL,
  [CONST.MOTION_GUNTWIN] = not RENEWAL,
  [CONST.MOTION_GUNFLIP] = not RENEWAL,
  [CONST.MOTION_GUNCAST] = not RENEWAL,
  [CONST.MOTION_FULLBLAST] = not RENEWAL,
}

local function getClassPlayer(gid)
  local motion = GetV(V_MOTION, gid)
  if motion2class[motion] then
    return motion2class[motion],motion_confirm[motion]
  end
  return nil
end

-- getClassMob
-- work-in-progress

-- General getClass

local function getClass(gid) -- Avoiding circular dependencies is a good practice
  local class = GetV(V_CLASS, gid)
  local confirm
  if class then
    return class
  end
  if gid < GID_BASE then
    class,confirm = getClassPlayer(gid)
    return class,confirm
  end
  return
end

-- Actor metatable
local actor_index_f = actor_metatable.__index
merclass_actor_metatable = copytable_shallow(actor_metatable)
merclass_actor_metatable.__index = function(actor,key)
  if not actor.gid then
    return nil
  end
  if key == 'class' then
    local class,confirm = getClass(actor.gid)
    if class and confirm then
      rawset(actor,'class',class)
      return class
    end
  end
  return actor_index_f(actor, key)
end

-- Merclass API
local MERCLASS = {}

MERCLASS.getActor = function(gid)
  local actor = getActor(gid)
  return setmetatable(actor, merclass_actor_metatable)
end

MERCLASS.getActors = function(foreach)
  local actors = getActors(foreach)
  for _,actor in pairs(actors) do
    setmetatable(actor, merclass_actor_metatable)
  end
  return actors
end

MERCLASS.shift = function(n)
  if type(n) == 'number' then
    GID_SHIFT = n
  end
end

MERCLASS.ROversion = function(version)
  if version == 'pre-renewal' then
    RENEWAL = false
  elseif version == 'renewal' then
    RENEWAL = true
  end
end

return MERCLASS
