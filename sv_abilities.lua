Abilities = {
    ["Slash"] = { damage = 15, effect = "Bleed" },
    ["Fireball"] = { damage = 25, effect = "Burn" },
    ["Heal"] = { damage = -20, effect = "Restore HP" }
}

util.AddNetworkString("SendAbilitiesToClient")
util.AddNetworkString("RequestAttack")
util.AddNetworkString("SendEnemyCharacters")
util.AddNetworkString("PerformAttack")

local ActiveNPCs = ActiveNPCs or {} -- track active NPCs by character name

-- Call this from spawnCharacterNPC to track active NPCs
function RegisterActiveNPC(name, npc)
    ActiveNPCs[name] = npc
end

-- Send available abilities to client
function SendAbilities(ply)
    net.Start("SendAbilitiesToClient")
        net.WriteUInt(table.Count(Abilities), 8)
        for name, details in pairs(Abilities) do
            net.WriteString(name)
            net.WriteInt(details.damage, 16)
            net.WriteString(details.effect or "")
        end
    net.Send(ply)
end

-- Handle client's request for enemy characters in battle
net.Receive("RequestAttack", function(len, ply)
    local abilityName = net.ReadString()
    local enemies = {}

    -- Query enemy characters currently in battle (by their NPC existence)
    for charName, npc in pairs(ActiveNPCs) do
        if IsValid(npc) and npc:GetOwner():SteamID() ~= ply:SteamID() then
            table.insert(enemies, charName)
        end
    end

    net.Start("SendEnemyCharacters")
        net.WriteString(abilityName)
        net.WriteUInt(#enemies, 8)
        for _, enemy in ipairs(enemies) do
            net.WriteString(enemy)
        end
    net.Send(ply)
end)

-- Apply attack to enemy NPC
net.Receive("PerformAttack", function(len, ply)
    local enemyName = net.ReadString()
    local abilityName = net.ReadString()

    local npc = ActiveNPCs[enemyName]
    if npc and IsValid(npc) then
        local ability = Abilities[abilityName]

        -- Apply damage or healing
        local damageAmount = ability.damage
        local dmgInfo = DamageInfo()
        dmgInfo:SetAttacker(ply)
        dmgInfo:SetDamage(math.abs(damageAmount))
        dmgInfo:SetDamageType(damageAmount >= 0 and DMG_GENERIC or DMG_GENERIC) -- customize damage type later
        npc:TakeDamageInfo(dmgInfo)

        -- Apply effects
        if ability.effect then
            npc:SetNWString("CurrentEffect", ability.effect)
        end
    else
        print("Could not find valid NPC for enemy name:", enemyName)
    end
end)
