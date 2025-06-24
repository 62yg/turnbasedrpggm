GM.Name 	= "TurnBasedRPG"
GM.Author 	= "62"


team.SetUp ( 11, "Black", Color ( 0, 0, 0 ) )

-------------------------------------------------------------------------------------------------------------------------


if SERVER then


function fightingtime(player1, player2)

local initiativeP1 = 0
local initiativeP2 = 0

    if not IsValid(player1) or not IsValid(player2) then
        print("[FightSystem] One or both players are invalid.")
        return
    end

    local player1SteamID = player1:SteamID()
    local player2SteamID = player2:SteamID()

    if not player1SteamID or not player2SteamID then
        print("[FightSystem] Failed to get SteamIDs!")
        return
    end

    -- No LIMIT here — let Lua loop handle the max 4 rule
local player1Chars = sql.Query("SELECT * FROM character_stats WHERE playerRoaster = " .. sql.SQLStr(player1:SteamID()))
local player2Chars = sql.Query("SELECT * FROM character_stats WHERE playerRoaster = " .. sql.SQLStr(player2:SteamID()))

   

    if not player1Chars and not player2Chars then
        print("[FightSystem] No characters found for either player.")
        return
    end

    -- Spawn helper
 local function spawnCharacterNPC(player, row, index, isPlayer1)
    local name = (row.name or ""):lower()
    local className = name
    if not scripted_ents.GetStored(className) then
        print("[FightSystem] Unknown NPC class:", className)
        return
    end

    local npc = ents.Create(className)
    if not IsValid(npc) then return end

    local spawnPositions = {
        [true] = {
            Vector(207.261, 74.487, -12287.969),
            Vector(198.373, 141.034, -12287.969),
            Vector(187.475, 222.620, -12287.969),
            Vector(177.867, 294.554, -12287.969)
        },
        [false] = {
            Vector(-221.764, 54.577, -12287.969),
            Vector(-210.668, 125.295, -12287.969),
            Vector(-188.682, 208.915, -12287.969),
            Vector(-206.834, 274.472, -12287.969)
        }
    }

    local pos = spawnPositions[isPlayer1][index]
    npc:SetPos(pos)
    npc:Spawn()
    npc:SetOwner(player)
    npc:SetNWString("CharacterName", row.name)

    RegisterActiveNPC(row.name, npc) -- IMPORTANT!

    return npc
end


    -- Spawn up to 4 characters for player 1
    if player1Chars then
        for i = 1, math.min(#player1Chars, 4) do
            spawnCharacterNPC(player1, player1Chars[i], i, true)
			local curP1init = tonumber(player1Chars[i].initiative) or 0     -- get current player 1 characters initiative value
			 initiativeP1 = initiativeP1 + curP1init   -- add the current characters initiative value to total for p1 (initiativeP1)
        end
    end

    -- Spawn up to 4 characters for player 2
    if player2Chars then
        for i = 1, math.min(#player2Chars, 4) do
            spawnCharacterNPC(player2, player2Chars[i], i, false)
		    local curP2init = tonumber(player2Chars[i].initiative) or 0       -- get current player 2 characters initiative value
			 initiativeP2 = initiativeP2 + curP2init   -- add the current characters initiative value to total for p2 (initiativeP2)
        end
    end
	
	
	if initiativeP1 > initiativeP2 then
	   startTurn(player1, player2)
	elseif initiativeP1 < initiativeP2 then
	   startTurn(player2, player1)
	else
	   local rand = math.random(1,2)
	   if rand == 1 then
	      startTurn(player1, player2)
	   else
	      startTurn(player2, player1)
	   end
	end
	

        util.AddNetworkString("StartBattle")
    net.Start("StartBattle")
    net.Send({player1, player2})
	
end -- end of function

-- Server-side
util.AddNetworkString("StartPturn")

function startTurn(curPlayer, opponent)
    if not IsValid(curPlayer) then return end

    net.Start("StartPturn")
    net.WriteEntity(curPlayer)
    net.Send(curPlayer)
end


end -- end of if SERVER statement







   






















------------------------------------------------------------------------------------------------------------------------