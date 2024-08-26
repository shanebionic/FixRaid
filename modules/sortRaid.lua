--- Low-level implementation of player sorting.
local A, L = unpack(select(2, ...))
local M = A:NewModule("sortRaid", "AceTimer-3.0")
A.sortRaid = M
M.private = {
  deltaPlayers = {},
  deltaNewGroups = {},
  action = {},
  splitGroups = {{}, {}},
  keys = {},
  players = {},
}
local R = M.private

-- Utility function to cancel the current action
function M:CancelAction()
  if R.action.timer then
    M:CancelTimer(R.action.timer)
  end
  wipe(R.action)
end

local DELAY_ACTION = 0.01
local CLASS_SORT_CHAR = {}
do
  for i, class in ipairs(CLASS_SORT_ORDER) do
    CLASS_SORT_CHAR[class] = string.char(64 + i)
  end
end

local format, floor, ipairs, pairs, sort, tinsert, tostring, wipe = format, floor, ipairs, pairs, sort, tinsert, tostring, wipe
local tconcat = table.concat
local SetRaidSubgroup, SwapRaidSubgroup = SetRaidSubgroup, SwapRaidSubgroup

local function resetPrivateTables()
  wipe(R.deltaPlayers)
  wipe(R.deltaNewGroups)
  wipe(R.keys)
  wipe(R.players)
end

local function sortPlayers(sortMode, keys, players)
  local d = A.sortModes:GetDefault()
  if d.onBeforeSort and d.onBeforeSort(sortMode, keys, players) then
    return true
  end
  if sortMode.onBeforeSort and sortMode.onBeforeSort(sortMode, keys, players) then
    return true
  end
  if sortMode.onSort then
    sortMode.onSort(sortMode, keys, players)
  elseif d.onSort then
    d.onSort(sortMode, keys, players)
  end
end

local function handlePlayerAction(player, newGroup)
  if A.group:GetGroupSize(newGroup) < 5 then
    startAction(player.name, newGroup, function() SetRaidSubgroup(player.rindex, newGroup) end, "set "..player.rindex.." "..newGroup)
  else
    -- Handle swaps
    local partner = findSwapPartner(newGroup, player.group)
    if partner then
      startAction(player.name, newGroup, function() SwapRaidSubgroup(player.rindex, partner.rindex) end, "swap "..player.rindex.." "..partner.rindex)
    else
      -- Error handling or alternate logic
      A.console:Errorf(M, "unable to find slot for %s!", player.name)
    end
  end
end

function M:BuildDelta(sortMode)
  resetPrivateTables()
  
  -- Build temporary tables tracking players.
  local keys, players = R.keys, R.players
  local skipFirstGroups = sortMode.skipFirstGroups or 0
  for name, p in pairs(A.group:GetRoster()) do
    if (not p.isSitting and p.group > skipFirstGroups) or sortMode.isIncludingSitting then
      local k = (p.class and CLASS_SORT_CHAR[p.class] or "Z")..(p.isUnknown and ("_"..name) or name)
      tinsert(keys, k)
      players[k] = p
    end
  end

  sortPlayers(sortMode, keys, players)
  
  local numGroups = M:GetNumGroups(sortMode)
  local newGroup, iMod4
  for i, k in ipairs(keys) do
    if sortMode.isSplit then
      iMod4 = i % 4
      if A.options.splitOddEven then
        newGroup = floor((i - 1) / 10) * 2 + 1
        if iMod4 == 2 or iMod4 == 3 then
          newGroup = newGroup + 1
        end
      else
        newGroup = floor((i - 1) / 10) + 1
        if iMod4 == 2 or iMod4 == 3 then
          newGroup = newGroup + floor(numGroups / 2)
        end
      end
    else
      newGroup = floor((i - 1) / 5) + 1
    end
    newGroup = newGroup + (sortMode.groupOffset or 0)
    if newGroup ~= players[k].group and not players[k].isDummy then
      tinsert(R.deltaPlayers, players[k])
      tinsert(R.deltaNewGroups, newGroup)
    end
  end

  if A.DEBUG >= 2 then M:DebugPrintDelta() end
end

-- Other functions remain mostly unchanged, with minor adjustments to use the new helper functions and variables.