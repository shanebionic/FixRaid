--- Tanks > Melee > Melee Healers > Ranged > Healers > Unknown > Support (round robin).
local A, L = unpack(select(2, ...))
local P = A.sortModes
local M = P:NewModule("tmrhms", "AceEvent-3.0")
P.tmrhms = M

-- Indexes correspond to A.group.ROLE constants (THMRMSU - Tanks, Healers, Melee, Ranged, Melee Healers, Support, Unknown).
local ROLE_KEY = {1, 4, 2, 3, 3, 2, 5}  -- Priorities: lower number = higher priority
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
            -- Insert dummy players for padding to keep the healers in the last group.
            local fixedSize = A.util:GetFixedInstanceSize()
            if fixedSize then
                local k
                while #keys < fixedSize do
                    k = format("_pad%02d", #keys)
                    tinsert(keys, k)
                    players[k] = PADDING_PLAYER
                end
            end
        end,
        onSort = function(sortMode, keys, players)
            -- Step 1: Sort players by role priority
            sort(keys, getDefaultCompareFunc(sortMode, keys, players))
            
            -- Step 2: Assign players to groups
            local groupSize = 5
            local supportRoles = {}
            local groupAssignments = {}
            local groupCount = 1

            for _, key in ipairs(keys) do
                local player = players[key]
                if player.role == A.group.ROLE.SUPPORT then
                    tinsert(supportRoles, player)  -- Store support roles for round-robin
                else
                    groupAssignments[groupCount] = groupAssignments[groupCount] or {}
                    tinsert(groupAssignments[groupCount], player)
                    
                    if #groupAssignments[groupCount] >= groupSize then
                        groupCount = groupCount + 1
                    end
                end
            end

            -- Step 3: Distribute support roles in round-robin fashion
            local supportIndex = 1
            for _, group in ipairs(groupAssignments) do
                if supportRoles[supportIndex] then
                    tinsert(group, supportRoles[supportIndex])
                    supportIndex = supportIndex + 1
                end
            end

            -- Step 4: Flatten the groupAssignments back into the keys array
            keys = {}
            for _, group in ipairs(groupAssignments) do
                for _, player in ipairs(group) do
                    tinsert(keys, player.name)
                end
            end
        end,
    })
end