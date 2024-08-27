local A, L = unpack(select(2, ...))
local P = A.sortModes
local M = P:NewModule("tmrhms", "AceEvent-3.0")
P.tmrhms = M

-- Updated role priority: Tanks > Melee > Melee Healers > Support > Ranged > Healers > Unknown
local ROLE_KEY = {1, 3, 7, 4, 2, 6, 5}  -- Adjusted order for round-robin support sorting

local PADDING_PLAYER = {role=5, isDummy=true}

local format, sort, tinsert = format, sort, tinsert

local function getDefaultCompareFunc(sortMode, keys, players)
    local ra, rb
    return function(a, b)
        ra, rb = ROLE_KEY[players[a].role or 5] or 4, ROLE_KEY[players[b].role or 5] or 4
        if ra == rb then
            return a < b
        end
        return ra < rb
    end
end

-- Round-robin distribution of support roles
local function distributeSupport(players, groups)
    local groupIndex = 1
    for _, playerKey in ipairs(players) do
        local player = players[playerKey]
        if player.role == M.ROLE.SUPPORT then
            -- Assign to the next group in round-robin
            groups[groupIndex] = groups[groupIndex] or {}
            tinsert(groups[groupIndex], playerKey)
            groupIndex = groupIndex % 8 + 1  -- Move to the next group, assuming 8 groups max
        end
    end
end

function M:OnEnable()
    A.sortModes:Register({
        key = "tmrhms",
        name = L["sorter.mode.tmrhms"],
        desc = format("%s:|n%s.", L["tooltip.right.fixRaid"], L["sorter.mode.tmrhms"]),
        getDefaultCompareFunc = getDefaultCompareFunc,
        onBeforeSort = function(sortMode, keys, players)
            if sortMode.isIncludingSitting then
                return
            end
            
            -- Insert dummy players for padding
            local fixedSize = A.util:GetFixedInstanceSize()
            if fixedSize then
                local k
                while #keys < fixedSize do
                    k = format("_pad%02d", #keys)
                    tinsert(keys, k)
                    players[k] = PADDING_PLAYER
                end
            end

            -- Distribute support roles in a round-robin fashion
            distributeSupport(players, sortMode.groups)
        end,
        onSort = function(sortMode, keys, players)
            sort(keys, getDefaultCompareFunc(sortMode, keys, players))
        end,
    })
end