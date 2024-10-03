ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local zones = {}

local allowedJobs = {
    "army",
    "police",
    "fib",
    "ambulance"
}

RegisterServerEvent('LS-Sperrzone:openMenu')
AddEventHandler('LS-Sperrzone:openMenu', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)  -- Holt die Job-Informationen des Spielers

    if xPlayer then
        local playerJob = xPlayer.getJob().name

        -- Überprüfen, ob der Job des Spielers in der Liste der erlaubten Jobs ist
        if hasValue(allowedJobs, playerJob) then
            TriggerClientEvent('LS-Sperrzone:openMenu', _source) -- Sendet ein Event zum Client, um das Menü zu öffnen
        else
            TriggerClientEvent('esx:showNotification', _source, "Du hast keine Berechtigung, dieses Menü zu öffnen.")
        end
    end
end)

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

RegisterNetEvent('LS-Sperrzone:createZone')
AddEventHandler('LS-Sperrzone:createZone', function(coords, radius, zoneId)
    zones[zoneId] = {coords = coords, radius = radius}

    -- Informiere alle Clients über die neue Sperrzone
    TriggerClientEvent('LS-Sperrzone:createZoneForAll', -1, coords, radius, zoneId)
end)

RegisterNetEvent('LS-Sperrzone:deleteZone')
AddEventHandler('LS-Sperrzone:deleteZone', function(zoneId)
    zoneId = tonumber(zoneId)
    if zones[zoneId] then
        zones[zoneId] = nil
        print("[DEBUG] Lösche Sperrzone mit ID: " .. tostring(zoneId))
        TriggerClientEvent('LS-Sperrzone:deleteZone', -1, zoneId)
    else
        print("[DEBUG] Sperrzone mit ID " .. tostring(zoneId) .. " nicht gefunden.")
    end
end)

-- Sende alle bestehenden Zonen an neue Spieler
RegisterNetEvent('LS-Sperrzone:sendZonesToNewPlayer')
AddEventHandler('LS-Sperrzone:sendZonesToNewPlayer', function()
    local _source = source
    for zoneId, zoneData in pairs(zones) do
        TriggerClientEvent('LS-Sperrzone:createZoneForAll', _source, zoneData.coords, zoneData.radius, zoneId)
    end
end)
