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
-- state.lua implements the most useful function that you probally are going to use
-- States are indexed by functions.
-- If you need several states with similar behavior but with different transitions, use ST.copy() to copy these states.

-- Global
local ST = {}
-- States
ST.hold = function(me, ...)
  Move(me.gid, unpack(me.xy))
end

ST.move = function(me, x, y, ...)
  Move(me.gid, x, y)
end

ST.attack = function(me, target, ...)
  Move(me.gid, unpack(me.xy))
  Attack(me.gid, target.gid)
end

ST.follow = function(me, ...)
  MoveToOwner(me.gid)
end

ST.chase = function(me, target, ...)
  Move(me.gid, unpack(target.xy))
end

ST.skill = function(me, skill_level, skill, target, ...) -- You can use the return value of newActor() and set their custom position
  if target.gid < 0 and not target.dead then
    SkillGround(me.gid, skill_level, skill, unpack(target.xy))
  elseif not target.dead then
    SkillObject(me.gid, skill_level, skill, target.gid)
  end
end

ST.patrol = function(me, ...)
  local x,y = unpack(me.owner.xy)
  local t = me.t
  Move(me.gid, x+2*math.cos(t), y+2*math.sin(t))
end

-- State API
ST.copy = function(f)
  if type(f) ~= 'function' then
    return nil
  end
  return function(...)
    return f(unpack(arg))
  end
end

-- Return
return ST
