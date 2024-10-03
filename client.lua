local zones = {}
local zoneCounter = 0

-- Befehl registrieren, um das Menü zu öffnen
RegisterCommand("sperrzone", function()
    SendNUIMessage({
        action = "openMenu",
        zones = getZonesForUI() -- Alle existierenden Zonen an die UI senden
    })
    SetNuiFocus(true, true)
    print("[DEBUG] Sperrzone-Menü geöffnet.")
end, false)

-- NUI-Callback zum Schließen des Menüs
RegisterNUICallback("closeMenu", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeMenu"
    })
    print("[DEBUG] Menü geschlossen durch NUI-Callback.")
    cb('ok')
end)

-- ESC-Schließen-Logik separat implementieren
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 322) then -- ESC Key
            SendNUIMessage({
                action = "closeMenu"
            })
            SetNuiFocus(false, false)
            print("[DEBUG] Menü geschlossen durch ESC-Taste.")
        end
    end
end)

-- NUI-Callback zum Erstellen einer Sperrzone
RegisterNUICallback("createZone", function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local radius = tonumber(data.radius)

    zoneCounter = zoneCounter + 1
    local zoneId = zoneCounter

    -- Benachrichtige den Server, um die Zone für alle Spieler zu erstellen
    TriggerServerEvent('LS-Sperrzone:createZone', playerCoords, radius, zoneId)

    zones[zoneId] = {
        id = zoneId,
        coords = playerCoords,
        radius = radius
    }

    -- Aktualisiere die UI direkt
    -- Korrigiert: Die Zone wird nur der UI hinzugefügt, wenn sie erfolgreich erstellt wurde
    Citizen.Wait(500) -- Füge einen kleinen Delay hinzu, um sicherzustellen, dass der Server die Erstellung registriert
    SendNUIMessage({
        action = "addZone",
        zone = {
            id = zoneId,
            radius = radius
        }
    })

    cb('ok')
end)

-- NUI-Callback zum Löschen einer Sperrzone
RegisterNUICallback("deleteZone", function(data, cb)
    local zoneId = tonumber(data.id)
    
    -- Benachrichtige den Server, um die Zone für alle Spieler zu löschen
    TriggerServerEvent('LS-Sperrzone:deleteZone', zoneId)

    -- Aktualisiere die UI direkt, um die gelöschte Zone zu entfernen
    SendNUIMessage({
        action = "removeZone",
        zoneId = zoneId
    })
    
    cb('ok')
end)

-- Zonen von Server synchronisieren
RegisterNetEvent('LS-Sperrzone:createZoneForAll')
AddEventHandler('LS-Sperrzone:createZoneForAll', function(coords, radius, zoneId)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 526)
    SetBlipScale(blip, 1.3)
    SetBlipColour(blip, 83)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Sperrzone")
    EndTextCommandSetBlipName(blip)
    
    -- Blip für den Radius hinzufügen
    local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radius + 0.0)
    SetBlipHighDetail(radiusBlip, true)
    SetBlipColour(radiusBlip, 27) -- Lila als Farbe
    SetBlipAlpha(radiusBlip, 128) -- Halbtransparenz
    
    zones[zoneId] = {
        id = zoneId,
        coords = coords,
        radius = radius,
        blip = blip,
        radiusBlip = radiusBlip
    }

    -- Aktualisiere die UI, um die neue Sperrzone hinzuzufügen
    SendNUIMessage({
        action = "addZone",
        zone = {
            id = zoneId,
            radius = radius
        }
    })

    print("[DEBUG] Sperrzone erstellt mit ID: " .. zoneId)
end)

-- Entfernen einer Sperrzone für alle Spieler
RegisterNetEvent('LS-Sperrzone:deleteZone')
AddEventHandler('LS-Sperrzone:deleteZone', function(zoneId)
    if zones[zoneId] then
        -- Entfernen des zentralen Blips
        RemoveBlip(zones[zoneId].blip)

        -- Entfernen des Radius-Blips
        if zones[zoneId].radiusBlip then
            RemoveBlip(zones[zoneId].radiusBlip)
        end

        zones[zoneId] = nil

        -- Aktualisiere die UI, um die gelöschte Zone zu entfernen
        SendNUIMessage({
            action = "removeZone",
            zoneId = zoneId
        })

        print("[DEBUG] Sperrzone mit ID " .. zoneId .. " gelöscht.")
    else
        print("[DEBUG] Sperrzone mit ID " .. zoneId .. " nicht gefunden.")
    end
end)

-- Bestehende Zonen an neue Spieler senden
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('LS-Sperrzone:sendZonesToNewPlayer')
end)

-- Funktion zur UI-Synchronisation
function getZonesForUI()
    local zonesForUI = {}
    for id, zone in pairs(zones) do
        table.insert(zonesForUI, { id = zone.id, radius = zone.radius })
    end
    return zonesForUI
end
