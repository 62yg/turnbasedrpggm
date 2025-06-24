include( 'shared.lua' )
-------------------------------------------------------------------------------------------------------------------------
-- function for when the server sends a specific character data to the client:
net.Receive("SendCharacterStats", function()
    local charID = net.ReadUInt(32) 
    local name = net.ReadString()
	local playerOwned = net.ReadString()
    local playerRoaster = net.ReadString()


    -- Same order as server
    local statKeys = {
        "baseDmg", "fireDmg", "iceDmg", "electricDmg", "psychicDmg",
        "kineticDmg", "physicalDmg", "plasmaDmg", "radiationDmg",
        "acidDmg", "poisonDmg", "windDmg", "infectionDmg", "magicDmg",
        "sonicDmg", "timeDmg", "health", "energy", "xp", "level", "initiative"
    }

    local stats = {}
    for _, key in ipairs(statKeys) do
        stats[key] = net.ReadInt(32)
    end

    -- Example debug output
    print("Received character stats for:", name)                  -- gets the character name string and displays it
    print("Owned by:", playerOwned, "| Roaster:", playerRoaster)  -- gets these two strings and displays them
    PrintTable(stats)                                             -- prints the whole stats table
	print("Radiation damage is:", stats.radiationDmg)            -- prints just individual stat in this case radiation damage

    -- You could update a UI or store the data here
end)


net.Receive("StartBattle", function()

hook.Add("CalcView", "battle_CalcView", function()

    return {
        origin     = Vector(-13.127172, 190.537521, -11905.814453),
        angles     = Angle(90.000, -88.836, 0.000),
        fov        = 75,
        drawviewer = true
    }


end)

end)



net.Receive("StartPturn", function()
    local curPlayer = net.ReadEntity()
    local localPly = LocalPlayer()

    if curPlayer ~= localPly then return end

    -- Clear old panels if they exist
    if IsValid(GLOBAL_ActionPanels) then
        for _, pnl in ipairs(GLOBAL_ActionPanels) do
            if IsValid(pnl) then pnl:Remove() end
        end
    end

    GLOBAL_ActionPanels = {}

    -- Create up to 4 action panels
    for i = 1, 4 do
        local panel = vgui.Create("DFrame")
        panel:SetSize(140, 100)
        panel:SetTitle("Character " .. i)
        panel:SetDraggable(false)
        panel:ShowCloseButton(false)
        panel:SetPos(550, 100 + (i - 1) * 210)

        -- Attack button
        local btnAttack = vgui.Create("DButton", panel)
        btnAttack:SetSize(120, 20)
        btnAttack:SetPos(10, 25)
        btnAttack:SetText("Attack")
        
        -- define DoClick within the loop
        btnAttack.DoClick = function()
            net.Start("RequestAbilities")
            net.SendToServer()

            net.Receive("SendAbilitiesToClient", function()
                local count = net.ReadUInt(8)
                local abilities = {}
                for j = 1, count do
                    local name = net.ReadString()
                    local damage = net.ReadInt(16)
                    local effect = net.ReadString()
                    abilities[j] = { name = name, damage = damage, effect = effect }
                end
                ShowAttackPanel(abilities, panel) -- pass this character's panel here
            end)

            net.Receive("SendEnemyCharacters", function()
                local abilityName = net.ReadString()
                local count = net.ReadUInt(8)
                local enemies = {}
                for j = 1, count do
                    enemies[j] = net.ReadString()
                end
                ShowEnemySelectionPanel(abilityName, enemies, panel) -- pass this panel here too
            end)
        end

        -- Defend button
        local btnDefend = vgui.Create("DButton", panel)
        btnDefend:SetSize(120, 20)
        btnDefend:SetPos(10, 50)
        btnDefend:SetText("Defend")
        btnDefend.DoClick = function()
            print("Defend clicked for character " .. i)
        end

        -- Use Item button
        local btnItem = vgui.Create("DButton", panel)
        btnItem:SetSize(120, 20)
        btnItem:SetPos(10, 75)
        btnItem:SetText("Use Item")
        btnItem.DoClick = function()
            print("Use Item clicked for character " .. i)
        end

        table.insert(GLOBAL_ActionPanels, panel)
    end
end)


net.Receive("SendAbilitiesToClient", function()
    local count = net.ReadUInt(8)
    local abilities = {}

    for i = 1, count do
        local name = net.ReadString()
        local damage = net.ReadInt(16)
        local effect = net.ReadString()
        abilities[i] = { name = name, damage = damage, effect = effect }
    end

    ShowAttackPanel(abilities)
end)
function ShowEnemySelectionPanel(abilityName, enemies, originatingPanel)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("Select Enemy to Attack")
    frame:Center()
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Enemy Name")

    for _, enemyName in pairs(enemies) do
        list:AddLine(enemyName)
    end

    function list:OnRowSelected(rowIndex, row)
        local enemyName = row:GetValue(1)
        net.Start("PerformAttack")
            net.WriteString(enemyName)
            net.WriteString(abilityName)
        net.SendToServer()



    end
end

function ShowEnemySelectionPanel(abilityName, enemies, originatingPanel)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("Select Enemy to Attack")
    frame:Center()
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Enemy Name")

    for _, enemyName in pairs(enemies) do
        list:AddLine(enemyName)
    end

    function list:OnRowSelected(rowIndex, row)
        local enemyName = row:GetValue(1)
        net.Start("PerformAttack")
            net.WriteString(enemyName)
            net.WriteString(abilityName)
        net.SendToServer()

        -- Ensure we actually call the function to close panels here
        CloseCharacterAttackPanels(originatingPanel)
        frame:Close()
    end
end




function CloseCharacterAttackPanels(originatingPanel)
    if IsValid(originatingPanel) then
        originatingPanel:Close()
    end

    for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
        if panel:GetClassName() == "DFrame" and panel.GetTitle then
            local ok, title = pcall(panel.GetTitle, panel)
            if ok and (title == "Select Attack" or title == "Select Enemy to Attack") then
                panel:Close()
            end
        end
    end
end

  


------------------------------------------------------------------------------------------------------------------------

include( "Scoreboard/admin_buttons.lua" )
include( "Scoreboard/cl_tooltips.lua" )
include( "Scoreboard/player_frame.lua" )
include( "Scoreboard/player_infocard.lua" )
include( "Scoreboard/player_row.lua" )
include( "Scoreboard/scoreboard.lua" )
include( "Scoreboard/vote_button.lua" )
include( "Scoreboard/the_scoreboard.lua" )


local PLAYER = FindMetaTable("Player")

function PLAYER:WaterLevel()
	return self:GetDTInt( 2 )
end


 function ShowTeamMenu()
  local DermaPanel = vgui.Create( "DFrame" )
  DermaPanel:SetPos( 300,300 )
  DermaPanel:SetSize( 750, 600 )
  DermaPanel:SetTitle( "Choose Your Model. The menu will close when you have selected one." ) // Name of Fram
  DermaPanel:SetVisible( true )
  DermaPanel:SetDraggable( true ) //Can the player drag the frame /True/False
  DermaPanel:ShowCloseButton( true ) //Show the X (Close button) /True/False
  DermaPanel:MakePopup()
 





 end
 
  function ShowTeamSelect()
  local DermaPanel = vgui.Create( "DFrame" )
  DermaPanel:SetPos( 400,300 )
  DermaPanel:SetSize( 750, 600 )
  DermaPanel:SetTitle( "Choose Your Team. The menu will close when you have selected one." ) // Name of Fram
  DermaPanel:SetVisible( true )
  DermaPanel:SetDraggable( true ) //Can the player drag the frame /True/False
  DermaPanel:ShowCloseButton( true ) //Show the X (Close button) /True/False
  DermaPanel:MakePopup()
  

  local DermaButton = vgui.Create( "DButton" )
  DermaButton:SetParent( DermaPanel ) // Set parent to our "DermaPanel"
  DermaButton:SetText( "ADMIN" )
  DermaButton:SetPos( 375, 190 )
  DermaButton:SetSize( 150, 50 )
  DermaButton.DoClick = function ()
   RunConsoleCommand( "team_11" ) // What happens when you press the button
   DermaPanel:SetVisible( false )
  end 
end
 usermessage.Hook( "call_vgui", ShowTeamMenu )
 usermessage.Hook( "call_vgui2", ShowTeamSelect )