SUPERSODA = {}
SUPERSODA.sodas = {'soda_speedup', 'soda_ragedup', 'soda_shieldup'}

-- add functions to player object, SHARED
local plymeta = FindMetaTable('Player')
function plymeta:HasDrunkSoda(soda_name)
    if not self.drankSoda then return false end

    return self.drankSoda[soda_name] or false
end

function plymeta:SetSoda(soda_name, soda_state)
    if not self.drankSoda then
        self.drankSoda = {}
    end
    self.drankSoda[soda_name] = soda_state
end

function plymeta:DrinkSoda(soda_name)
    self:SetSoda(soda_name, true)
end

function plymeta:RemoveSoda(soda_name)
    self:SetSoda(soda_name, false)
end


if SERVER then
    util.AddNetworkString('ttt2_supersoda_reset')
    util.AddNetworkString('ttt2_supersoda_drink')

    -- RESET PLAYER SODA STATE
    function SUPERSODA:ResetPlayerState(ply)
        for _,soda in ipairs(self.sodas) do
            ply:RemoveSoda(soda)
        end

        net.Start('ttt2_supersoda_reset')
        net.Send(ply)
    end
    hook.Add('PlayerSpawn', 'ttt2_supersoda_reset_hook', function(ply)
        SUPERSODA:ResetPlayerState(ply)
    end)

    -- HANDLE SODA PICKUP
    function SUPERSODA:PickupSoda(ply, ent)
        local soda = ent:GetClass()

        if ply:GetPos():Distance(ent:GetPos()) >= 60 then return end -- too far away
        if not table.HasValue(SUPERSODA.sodas, soda) then return end -- no valid soda

        -- drink soda and notify
        sound.Play('sodacan/opencan.wav', ply:GetPos(), 60)
        ent:Remove()
        STATUS:AddStatus(ply, soda)

        -- set drank soda on client
        ply:DrinkSoda(soda)
        net.Start('ttt2_supersoda_drink')
        net.WriteString(soda)
        net.Send(ply)
    end
    hook.Add('KeyPress', 'ttt2_supersoda_pickup', function(ply, key)
        if key ~= IN_USE then return end

        SUPERSODA:PickupSoda(ply, ply:GetEyeTrace().Entity)
    end)

    local function SpawnRandomSoda()
        local spawns = ents.FindByClass('item_*')
        
        if (#spawns) > 0 then
            
            local spwn = spawns[ math.random( #spawns ) ]
            local soda = ents.Create( SUPERSODA.sodas[ math.random( #SUPERSODA.sodas ) ] )
            
            soda:SetPos( spwn:GetPos() )
            soda:Spawn()
            spwn:Remove()

        end
    end
    hook.Add('TTTBeginRound', 'SpawnSoda' , SpawnRandomSoda)
end

if CLIENT then
    net.Receive('ttt2_supersoda_reset', function()
        local client = LocalPlayer()

        if not client or not IsValid(client) then return end

        for _,soda in ipairs(SUPERSODA.sodas) do
            client:RemoveSoda(soda)
        end
    end)

    net.Receive('ttt2_supersoda_drink', function()
        local client = LocalPlayer()
        local soda = net.ReadString()

        client:DrinkSoda(soda)
        MSTACK:AddMessage(LANG.GetTranslation('ttt_drank_' .. soda))
    end)
end

concommand.Add('debug_sodaversion', function()
    print('TTT2 - V. 1.0.0')
end)