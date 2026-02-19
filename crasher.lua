local notifications = {}
local notifWidth, notifHeight = 0.15, 0.08
local startX, baseY = 0.89, 0.90

local menuOpen = false
local menuAlpha = 0
local selectedIndex = 1
local duiObj, duiTxd = nil, nil

local maxVisible = 5
local scrollOffset = 0

function showNotification(title, desc, color, duration)
    table.insert(notifications, {
        title = title,
        desc = desc,
        color = color or {255, 0, 0},
        duration = duration or 5000,
        startTime = GetGameTimer(),
        alpha = 0,
        currentY = baseY,
        currentX = startX
    })
end

function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

function GetNearbyPlayers()
    local players = {}
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= ped then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(coords - targetCoords)
            if distance < 700.0 then 
                -- i tak max bodajze 450
                table.insert(players, {
                    id = GetPlayerServerId(player),
                    name = GetPlayerName(player),
                    distance = distance,
                    ped = targetPed
                })
            end
        end
    end

    table.sort(players, function(a, b) return a.distance < b.distance end)
    return players
end

Citizen.CreateThread(function()
    local url = "https://media.discordapp.net/attachments/1442164978768548004/1450943932526628874/dropper.png?ex=694af7d6&is=6949a656&hm=dab6c70829022585c0cc3c0b8f12749b6f7b4e572482aeb92b75e51966c2d30b"
    
    duiObj = CreateDui(url, 680, 240)
    duiTxd = CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd("banner_dui"), "banner", GetDuiHandle(duiObj))
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsControlJustPressed(0, 166) or IsDisabledControlJustPressed(0, 166) then
            menuOpen = not menuOpen
            selectedIndex = 1
            scrollOffset = 0
        end

        if menuOpen then
            menuAlpha = math.min(255, menuAlpha + 15)
            local players = GetNearbyPlayers()
            local totalPlayers = #players

            if IsControlJustPressed(0, 172) or IsDisabledControlJustPressed(0, 172) then
                selectedIndex = math.max(1, selectedIndex - 1)
            elseif IsControlJustPressed(0, 173) or IsDisabledControlJustPressed(0, 173) then
                selectedIndex = math.min(totalPlayers, selectedIndex + 1)
            elseif IsControlJustPressed(0, 176) or IsDisabledControlJustPressed(0, 176) then
                if totalPlayers > 0 and players[selectedIndex] then
                    local selectedPlayer = players[selectedIndex]
                    
                    showNotification("Dropper 3.0", "Crashing ID: " .. selectedPlayer.id, {255, 0, 0}, 3000)
                    
                    local myPed = PlayerPedId()
                    local targetPed = selectedPlayer.ped
                    local targetCoords = GetEntityCoords(targetPed)
                    local originalCoords = GetEntityCoords(myPed)
                    
                    local teleportCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z + 300.0)
                    SetEntityCoords(myPed, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, true)
                    
                    FreezeEntityPosition(myPed, true)
                    SetEntityInvincible(myPed, true)
                    
                    RequestAnimDict("anim@mp_snowball")
                    while not HasAnimDictLoaded("anim@mp_snowball") do Wait(10) end
                    
                    TaskPlayAnim(myPed, "anim@mp_snowball", "snowball_throw", 8.0, 8.0, -1, 1, 0, false, false, false)
                    
                    local m = GetHashKey("player_zero")
                    RequestModel(m)
                    while not HasModelLoaded(m) do Wait(10) end
                    
                    CreateThread(function()
                        local duration = 5000
                        local startTime = GetGameTimer()
                        local targetCrashed = false
                        
                        local function Attack()
                            local t = {}
                            for i = 1, 50 do
                                if not DoesEntityExist(targetPed) then
                                    targetCrashed = true
                                    break
                                end
                                
                                local coords = GetEntityCoords(targetPed)
                                local e = CreatePed(4, m, coords.x + (math.random() - 0.5) * 1.5, coords.y + (math.random() - 0.5) * 1.5, coords.z + 2 + math.random() * 3, 0.0, true, true)
                                if e ~= 0 then
                                    SetEntityLocallyInvisible(e)
                                    SetEntityCollision(e, false, false)
                                    SetEntityAlpha(e, 0, false)
                                    table.insert(t, e)
                                    SetEntityAsMissionEntity(e, true, true)
                                    TaskStartScenarioInPlace(e, "WORLD_HUMAN_CHEERING", 0, true)
                                end
                                Wait(13)
                            end
                            
                            Wait(500)
                            
                            for _, e in ipairs(t) do 
                                if DoesEntityExist(e) then 
                                    SetEntityAsNoLongerNeeded(e)
                                    DeleteEntity(e) 
                                end 
                            end
                        end
                        
                        Attack()
                        Wait(800)
                        
                        if not targetCrashed and DoesEntityExist(targetPed) then 
                            Attack()
                        end
                        
                        local spinThread = CreateThread(function()
                            while GetGameTimer() - startTime < duration do
                                Wait(0)
                                
                                if not DoesEntityExist(targetPed) then
                                    targetCrashed = true
                                    break
                                end
                                
                                local currentTargetCoords = GetEntityCoords(targetPed)
                                
                                DrawLine(
                                    teleportCoords.x, teleportCoords.y, teleportCoords.z,
                                    currentTargetCoords.x, currentTargetCoords.y, currentTargetCoords.z,
                                    255, 255, 255, 255
                                )
                                
                                local currentHeading = GetEntityHeading(myPed)
                                SetEntityHeading(myPed, (currentHeading + 0.8) % 360.0)
                                
                                SetEntityCoords(myPed, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, true)
                            end
                        end)
                        
                        Wait(duration - (GetGameTimer() - startTime))
                        
                        ClearPedTasksImmediately(myPed)
                        FreezeEntityPosition(myPed, false)
                        SetEntityInvincible(myPed, false)
                        SetModelAsNoLongerNeeded(m)
                        
                        local groundZ = 0.0
                        local found = false
                        
                        for i = 1, 50 do
                            found, groundZ = GetGroundZFor_3dCoord(originalCoords.x, originalCoords.y, originalCoords.z + 1000.0, false)
                            if found then
                                break
                            end
                            Wait(50)
                        end
                        
                        if found then
                            SetEntityCoords(myPed, originalCoords.x, originalCoords.y, groundZ + 1.0, false, false, false, true)
                        else
                            SetEntityCoords(myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
                        end
                        
                        showNotification("Dropper 3.0", "Waiting for result..", {255, 255, 255}, 4000)
                        Wait(1500)
                        if targetCrashed or not DoesEntityExist(targetPed) then
                            showNotification("Dropper 3.0", "Successfully crashed!", {0, 255, 0}, 3000)
                        else
                            showNotification("Dropper 3.0", "Failed to crash!", {255, 255, 0}, 3000)
                        end
                    end)
                end


            elseif IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
                menuOpen = false
            end

            if selectedIndex < scrollOffset + 1 then
                scrollOffset = selectedIndex - 1
            elseif selectedIndex > scrollOffset + maxVisible then
                scrollOffset = selectedIndex - maxVisible
            end
            if scrollOffset < 0 then scrollOffset = 0 end

            local menuX = 0.22
            local menuWidth = 0.22
            local bannerHeight = 0.10
            local itemHeight = 0.045
            local footerHeight = 0.04

            local listHeight = itemHeight * maxVisible + 0.01
            local menuTopY = 0.20

            local bannerY = menuTopY + bannerHeight / 2.0
            if duiTxd then
                DrawSprite("banner_dui", "banner", menuX, bannerY, menuWidth, bannerHeight, 0.0, 255, 255, 255, 255)
            else
                DrawRect(menuX, bannerY, menuWidth, bannerHeight, 20, 20, 20, 255)
            end

            local listStartY = menuTopY + bannerHeight
            local listBgY = listStartY + listHeight / 2.0
            DrawRect(menuX, listBgY, menuWidth, listHeight, 8, 8, 8, menuAlpha * 0.50)

            local visibleCount = math.min(maxVisible, totalPlayers)
            for idx = 1, visibleCount do
                local i = idx + scrollOffset
                local player = players[i]
                if player then
                    local itemY = listStartY + (idx - 1) * itemHeight + itemHeight / 2.0
                    local isSelected = (i == selectedIndex)

                    if isSelected then
                        DrawRect(menuX, itemY, menuWidth, itemHeight, 50, 50, 50, menuAlpha * 0.75)
                        DrawRect(menuX - menuWidth/2 + 0.0015, itemY, 0.003, itemHeight, 255, 255, 255, menuAlpha)
                    else
                        DrawRect(menuX, itemY, menuWidth, itemHeight, 20, 20, 20, menuAlpha * 0.25)
                    end

                    SetTextFont(0)
                    SetTextScale(0.27, 0.27)
                    SetTextColour(isSelected and 255 or 180, isSelected and 255 or 180, isSelected and 255 or 180, menuAlpha)
                    SetTextEntry("STRING")
                    AddTextComponentString(player.name .. " [" .. player.id .. "]")
                    DrawText(menuX - menuWidth/2 + 0.010, itemY - 0.009)

                    SetTextFont(0)
                    SetTextScale(0.23, 0.23)
                    SetTextColour(isSelected and 200 or 140, isSelected and 200 or 140, isSelected and 200 or 140, menuAlpha * 0.8)
                    SetTextEntry("STRING")
                    AddTextComponentString(string.format("%.1fm", player.distance))
                    DrawText(menuX - menuWidth/2 + 0.010, itemY + 0.006)
                end
            end

            if totalPlayers == 0 then
                SetTextFont(0)
                SetTextScale(0.28, 0.28)
                SetTextColour(150, 150, 150, menuAlpha)
                SetTextEntry("STRING")
                AddTextComponentString("No players nearby")
                SetTextCentre(1)
                DrawText(menuX, listStartY + 0.05)
            end

            local footerStartY = listStartY + listHeight
            local footerY = footerStartY + footerHeight/2.0
            DrawRect(menuX, footerY, menuWidth, footerHeight, 12, 12, 12, menuAlpha * 0.85)

            local hue = (GetGameTimer() / 2000) % 1
            local r, g, b = HSVtoRGB(hue, 1, 1)

            SetTextFont(0)
            SetTextScale(0.24, 0.24)
            SetTextColour(r, g, b, menuAlpha)
            SetTextEntry("STRING")
            AddTextComponentString("Susano on TOP")
            SetTextCentre(1)
            DrawText(menuX, footerStartY + 0.010)

            SetTextFont(0)
            SetTextScale(0.24, 0.24)
            SetTextColour(180, 180, 180, menuAlpha)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("(%d/%d)", selectedIndex, math.max(1, totalPlayers)))
            DrawText(menuX - menuWidth/2 + 0.008, footerStartY + 0.010)

            SetTextFont(0)
            SetTextScale(0.24, 0.24)
            SetTextColour(180, 180, 180, menuAlpha)
            SetTextEntry("STRING")
            AddTextComponentString("v1.0.0")
            DrawText(menuX + menuWidth/2 - 0.024, footerStartY + 0.010)
        else
            menuAlpha = math.max(0, menuAlpha - 20)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        SetScriptGfxDrawOrder(7)
        SetScriptGfxDrawBehindPausemenu(false)

        local currentTime = GetGameTimer()

        for i = #notifications, 1, -1 do
            local notif = notifications[i]
            local elapsed = currentTime - notif.startTime
            local targetY = baseY - ((#notifications - i) * (notifHeight + 0.012))
            local targetX = startX

            if elapsed < 300 then
                notif.alpha = math.floor(255 * (elapsed / 300))
            elseif elapsed > notif.duration - 500 then
                notif.alpha = 255
                targetX = 1.2
            else
                notif.alpha = 255
            end

            if elapsed >= notif.duration then
                table.remove(notifications, i)
            else
                notif.currentY = notif.currentY + (targetY - notif.currentY) * 0.15
                notif.currentX = notif.currentX + (targetX - notif.currentX) * 0.06

                local pulse = (math.sin(currentTime / 350) * 0.4) + 1.0
                local r, g, b = math.min(255, notif.color[1] * pulse), math.min(255, notif.color[2] * pulse), math.min(255, notif.color[3] * pulse)

                DrawRect(notif.currentX, notif.currentY, notifWidth, notifHeight, 8, 8, 8, notif.alpha * 0.92)
                DrawRect(notif.currentX, notif.currentY, notifWidth * 0.98, notifHeight * 0.94, 22, 22, 22, notif.alpha * 0.6)
                DrawRect(notif.currentX - notifWidth/2 + 0.00125, notif.currentY, 0.0025, notifHeight, r, g, b, notif.alpha)

                SetTextFont(0)
                SetTextProportional(0)
                SetTextScale(0.32, 0.32)
                SetTextColour(255, 255, 255, notif.alpha)
                SetTextEntry("STRING")
                AddTextComponentString(notif.title)
                DrawText(notif.currentX - notifWidth/2 + 0.010, notif.currentY - 0.026)

                SetTextFont(0)
                SetTextScale(0.26, 0.26)
                SetTextColour(185, 185, 185, notif.alpha)
                SetTextEntry("STRING")
                AddTextComponentString(notif.desc)
                DrawText(notif.currentX - notifWidth/2 + 0.010, notif.currentY + 0.000)
            end
        end
    end
end)

showNotification("Welcome", "Successfully loaded menu. [F5]", {255, 255, 255}, 5000)