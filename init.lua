AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sv_abilities.lua" )
 

include( 'sv_abilities.lua' )
include( 'shared.lua' )

math.randomseed(os.time())  -- sets up randomness based on the server's operating system time for math.random, used later
-------------------------------------------------------------------------------------------------------------------------


-- First of all this creates and saves a table in SQL with the following TEXT data or INTEGER data, basically it's just a new character,
-- their name, their assigned id and all their stats
function createCharacterStats()
    sql.Query("CREATE TABLE IF NOT EXISTS character_stats (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, baseDmg INTEGER, fireDmg INTEGER, iceDmg INTEGER, electricDmg INTEGER, psychicDmg INTEGER, kineticDmg INTEGER, physicalDmg INTEGER, plasmaDmg INTEGER, radiationDmg INTEGER, acidDmg INTEGER, poisonDmg INTEGER, windDmg INTEGER, infectionDmg INTEGER, magicDmg INTEGER, sonicDmg INTEGER, timeDmg INTEGER, health INTEGER, energy INTEGER, xp INTEGER, level INTEGER, initiative INTEGER, playerOwned TEXT, playerRoaster TEXT)")
end
createCharacterStats()

------------------------------------------------------------------------------------------------------------------------------------------

-- This is a function that can be used to get the value of a stat by unique id of the character
function getCharacterStat(id, statName)

    local result = sql.QueryRow("SELECT " .. sql.SQLStr(statName, true) .. " FROM character_stats WHERE id = " .. tonumber(id))
    if result then
        return tonumber(result[statName]) or result[statName]
    else
        return nil
    end
end

-- This is a function that can be used to SET the value of a stat by giving it the unique id of the character, the name of the stat and
-- the new desired value
function setCharacterStat(id, statName, value)
    local safeStat = sql.SQLStr(statName, true)
    local safeValue = (type(value) == "number") and value or sql.SQLStr(value)
    local query = "UPDATE character_stats SET " .. safeStat .. " = " .. safeValue .. " WHERE id = " .. tonumber(id)
    return sql.Query(query) ~= false
end


-- Here is an example of how to use the above two functions for getting and setting stats
-- First of all getting stats:
local charID = 1
local fire = getCharacterStat(charID, "fireDmg")
print("Fire Damage:", fire)  -- Prints the fire damage of the character whose ID is 1

-- Secondly, setting stats, this would add 10 xp to the xp stat for the character whose ID is 2
local charID = 1
local experiencePoints = getCharacterStat(charID, "xp")
setCharacterStat(charID, "xp", experiencePoints + 10)
 
    
------------------------------------------------------------------------------------------------------------------------------------------

--This next function can be used to insert a new character by just specifying a character name, all the data is filled in with 0'saves
-- Creates a new character with the given name and stat values
function createNewCharacter(name, stats, extraText)
    -- Validate name
    if not name or name == "" then
        error("Character name is required.")
    end

    -- Define TEXT fields
    local textKeys = { "playerOwned", "playerRoaster" }

    -- Define all stat keys in the order your table expects
    local statKeys = {
        "baseDmg", "fireDmg", "iceDmg", "electricDmg", "psychicDmg",
        "kineticDmg", "physicalDmg", "plasmaDmg", "radiationDmg",
        "acidDmg", "poisonDmg", "windDmg", "infectionDmg", "magicDmg",
        "sonicDmg", "timeDmg", "health", "energy", "xp", "level", "initiative"
    }

    -- Build final field and value lists
    local fields = { "name" }
    local values = { sql.SQLStr(name) }

    -- Append TEXT fields
    for _, key in ipairs(textKeys) do
        table.insert(fields, key)
        table.insert(values, sql.SQLStr(extraText[key] or ""))
    end

    -- Append INTEGER stat fields
    for _, key in ipairs(statKeys) do
        table.insert(fields, key)
        table.insert(values, tonumber(stats[key]) or 0)
    end

    -- Final INSERT query
    local query = string.format(
        "INSERT INTO character_stats (%s) VALUES (%s)",
        table.concat(fields, ", "),
        table.concat(values, ", ")
    )
	
	sql.Query(query)


    -- Return the ID of the last inserted character
    local result = sql.QueryRow("SELECT last_insert_rowid() AS id")
    return result and tonumber(result.id) or nil
end

--Here is an example of using the above function:
local newStats = {
    baseDmg = 5, fireDmg = 10, iceDmg = 0, electricDmg = 0, psychicDmg = 0,
    kineticDmg = 50, physicalDmg = 5, plasmaDmg = 0, radiationDmg = 0,
    acidDmg = 0, poisonDmg = 0, windDmg = 0, infectionDmg = 0, magicDmg = 0,
    sonicDmg = 0, timeDmg = 0, health = 100, energy = 120, xp = 0, level = 1, initiative = 1
}

local extraText = {
    playerOwned = "steamID",
    playerRoaster = "steamID"
}
 
local charID = createNewCharacter("Cyclops", newStats, extraText) -- Then call the function with your desired character name and the above table
print("Created new character with ID:", charID)        -- displays automatically created char id (auto incremented)

------------------------------------------------------------------------------------------------------------------------------------------



-- Now to create a net message to send all data for specific characters to specific clients to they can use it in their UI etc
util.AddNetworkString("SendCharacterStats")

-- Sends all stats of a character to a specific client
function sendCharacterStatsToClient(ply, charID)
    local row = sql.QueryRow("SELECT * FROM character_stats WHERE id = " .. tonumber(charID))
    if not row then
        print("Character ID not found:", charID)
        return
    end

    net.Start("SendCharacterStats")
        net.WriteUInt(tonumber(row.id), 32)
        net.WriteString(row.name)
        net.WriteString(row.playerOwned or "")
        net.WriteString(row.playerRoaster or "")
 
        -- Write all stats as integers
        local statKeys = {
            "baseDmg", "fireDmg", "iceDmg", "electricDmg", "psychicDmg",
            "kineticDmg", "physicalDmg", "plasmaDmg", "radiationDmg",
            "acidDmg", "poisonDmg", "windDmg", "infectionDmg", "magicDmg",
            "sonicDmg", "timeDmg", "health", "energy", "xp", "level", "initiative"
        }

        for _, key in ipairs(statKeys) do
            net.WriteInt(tonumber(row[key]) or 0, 32)
        end
    net.Send(ply)
end
-- See receive function on the client in cl_init.lua!
--example usage:
local charID = 1
sendCharacterStatsToClient(Entity(1), charID) -- Sends all data for character with ID of 1 to the first player on the server (host player)
 


 util.AddNetworkString("RequestAbilities")
util.AddNetworkString("OpenRoasterMenu")
util.AddNetworkString("SaveRoaster")

net.Receive("RequestAbilities", function(len, ply)
    SendAbilities(ply)
end)

net.Receive("SaveRoaster", function(len, ply)
    local count = math.min(net.ReadUInt(8), 4)
    local ids = {}
    for i = 1, count do
        table.insert(ids, net.ReadUInt(32))
    end

    local steamID = ply:SteamID()

    sql.Query("UPDATE character_stats SET playerRoaster = '' WHERE playerOwned = " .. sql.SQLStr(steamID))
    for _, id in ipairs(ids) do
        sql.Query("UPDATE character_stats SET playerRoaster = " .. sql.SQLStr(steamID) .. " WHERE id = " .. tonumber(id))
    end
end)














------------------------------------------------------------------------------------------------------------------------



function GM:PlayerInitialSpawn( ply )   -- when the player spawns on the map for the first time


 ply:SetTeam( 1 )                                      -- set the players team to team 1
 ply:SetWalkSpeed ( 260 )                              -- set the players walk speed
 ply:SetRunSpeed ( 320 )                               -- set the players run speed
 ply:SetHealth ( 100 )                                 -- set the players starting health
 ply:SetJumpPower(200)
 ply:SetSlowWalkSpeed( 100 )
 ply:Give( "weapon_none" )                             -- give the player this weapon
 ply:PrintMessage( HUD_PRINTTALK, "Welcome to Daniel's Gamemode. Press F1 or F2 for options (while you are dead)" )

end

----------------------------------------------------------------------------------------------------------------------------------------

function GM:PlayerSpawn( ply )


ply:SetupHands() -- Create the hands and call GM:PlayerSetHandsModel. THIS MUST COME BEFORE ALL OTHER CODE IN THIS FUNCTION SO DO NOT PUT ANYTHING BEFORE THIS
                 -- You must not change any player models information before ply:SetUpHands is called!!!
				 -- ply:Kill() must be used in initialspawn (the function above this one) and you must not setup any model information in that function either
				 -- The player must also be given and switch to a regular weapon before they switch to an arccw weapon, you can strip the regular weapon from them if you want afterwards
				 -- in this case the player is given weapon_none which they will automatically switch to before any other weapon. This is important.
				


 if ply:GetModel() == "models/player.mdl" then  -- if the player's current playermodel is set to this model which is the default untextured humanoid model with no animations then
     ply:SetModel( "models/player/group01/male_02.mdl" )   -- change the players model to male02 since they have no model set up yet
 end            -- end the if statement

 ply:SetWalkSpeed ( 260 )
 ply:SetRunSpeed ( 320 )
 ply:SetHealth ( 100 )
 ply:SetJumpPower(200)
 ply:SetSlowWalkSpeed( 100 )
 ply:Give( "weapon_none" )

fightingtime(Entity(1), Entity(2))
	
end


-- Choose the model for hands according to their player model.
function GM:PlayerSetHandsModel( ply, ent )

	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end

end

----------------------------------------------------------------------------------------------------------------------------------------




function GM:ShowHelp( ply )
    local steamID = ply:SteamID()
    local rows = sql.Query("SELECT id, name, playerRoaster FROM character_stats WHERE playerOwned = " .. sql.SQLStr(steamID))

    net.Start("OpenRoasterMenu")
        if rows then
            net.WriteUInt(#rows, 8)
            for _, row in ipairs(rows) do
                net.WriteUInt(tonumber(row.id) or 0, 32)
                net.WriteString(row.name or "")
                net.WriteBool(row.playerRoaster == steamID)
            end
        else
            net.WriteUInt(0, 8)
        end
    net.Send(ply)
end

function GM:ShowTeam( ply )
	umsg.Start("call_vgui2", ply)
	umsg.End()
end


function team_11( ply )
if ply:IsAdmin() then                   -- if the player is a server admin
     ply:SetTeam( 11 )
     ply:GodEnable()                    -- enable god mode
     ply:Give( "m9k_davy_crockett" )
     ply:Give( "lightninggun" )
     ply:Give( "weapon_physgun" )
     ply:Give( "weapon_possessor" )
	 ply:Give( "force_storm" )
else                                   -- if the player is not an admin
MsgN("tried to become team admin.")
end
end	

 
function GM:PlayerNoClip(ply)    -- This functions decides if players can use the noclip command
	return ply:IsAdmin()     -- this makes it so that only server admins can use noclip
end                              -- ends the function


hook.Add( "PhysgunPickup", "AllowPlayerPickup", function( ply, ent )    -- when the physgun tries to pick up something
	if ( ply:IsAdmin() and ent:IsPlayer() ) then                    -- if the person using the physgun is a player and is an admin and the thing it's trying to pick up is another player then
		return true                                             -- allow them to be picked up
	end                                                           -- end the if statement
end )                                                                  -- end the hooked function



concommand.Add( "team_11", team_11 )


