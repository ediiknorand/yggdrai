-- const
local CONST = dofile("./AI/USER_AI/lib/const.lua")
local ST = dofile("./AI/USER_AI/lib/state.lua")
-- var
local hunted = {}
-- util
local function getGoodMobs(me)
  local actors = getActors()
  local players = actors/{'player', 'summon'} - (me + me.owner)
  local mobs = actors^{me, me.owner, -1, 'monster'}/'monster'/hunted - players.target
  local good_mobs = newGroup()
  for _,mob in pairs(mobs) do
    local p,d = players.nearest(mob)
    local reachable = me.dist(mob) < 14 - mob.range
    if p and d > p.range + mob.range and d > me.dist(mob) - mob.range and reachable then
      good_mobs = good_mobs + mob
    elseif not p and reachable then
      good_mobs = good_mobs + mob
    end
  end
  return good_mobs
end
-- States
local stScan = ST.copy(ST.follow)
local stCMDAttack = ST.copy(ST.attack)
-- Transition Table
local ftran = {}

ftran[stScan] = function(me)
  local good_mobs = getGoodMobs(me)
  if good_mobs.n > 0 then
    return ST.chase, {me, good_mobs.nearest(me), {}}
  end
end

ftran[ST.chase] = function(me, target, protected_mobs)
  local players = getActors()/{'player', 'summon'} - (me + me.owner)
  local ksers = players^protected_mobs
  if ksers.n > 0 then
    -- KSER ALERT!!!
    -- Record something here. If possible, take screenshots.
  end
  local good_mobs = getGoodMobs(me)
  if not good_mobs[target.gid] and protected_mobs.n > 0 then
    return ST.chase, {me, protected_mobs.nearest(me), protected_mobs}
  elseif not good_mobs[target.gid] then
    return stScan, {me}
  end
  if me.dist(target) <= me.range then
    return ST.attack, {me, target, protected_mobs}
  end
end

ftran[ST.attack] = function(me, target, protected_mobs)
  local isAttackingUs = target^me or target^me.owner
  if isAttackingUs then
    protected_mobs = protected_mobs + target
  end
  local players = getActors()/{'player', 'summon'} - (me + me.owner)
  local ksers = players^protected_mobs
  if ksers.n > 0 then
    -- KSER ALERT!!!
    -- Record something here. If possible, take screenshots.
  end
  if ((players^target).n > 0 and not isAttackingUs) or target.dead then
    if protected_mobs.n > 0 then
      return ST.chase, {me, protected_mobs.nearest(me), protected_mobs}
    end
    return stScan, {me}
  end
  return ST.attack, {me, target, protected_mobs}
end

-- Command Handler
local fcmd = {
  [CONST.CMD_MOVE] = {stScan, ST.follow},
  [CONST.CMD_ATTACK] = stCMDAttack,
  [CONST.CMD_MOVE] = ST.move,
}

-- Initializer
local function farm_profile(me, ...)
  hunted = arg or hunted
  return ftran, fcmd, ST.follow, {me}
end

return farm_profile
