ESX = nil

Keys = {}
PlayerData = {}
SearchedVeh = {}
local disableF = false

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(1)
    end
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('hsn-hotwire:client:addKeys')
AddEventHandler('hsn-hotwire:client:addKeys', function(data)
    Keys[data] = true
end)

RegisterNetEvent('hsn-hotwire:client:removeKeys')
AddEventHandler('hsn-hotwire:client:removeKeys',function(plate)
    Keys[plate] = nil
end)

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
	DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
	ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        if IsPedInAnyVehicle(PlayerPedId(),false)  then
            local vehicle = GetVehiclePedIsIn(PlayerPedId())
            local Plate = GetVehicleNumberPlateText(vehicle)
            local vehicleCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.25, 0.35)
            if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId() then
                if Keys[Plate] ~= true then
                    wait = 2
                    if SearchedVeh[Plate] ~= true then
                        text = '~y~[H]~s~ Düzkontak | ~g~[Z]~s~ Ara'
                    else
                        text = '~y~[H]~s~ Düzkontak'
                    end
                    if IsControlJustPressed(1, 74) then--H
                        ESX.TriggerServerCallback('hsn-hotwire:maymuncuk', function(data)
                        TriggerServerEvent('hsn-hotwire:maymuncuksil')
                        exports['mythic_progbar']:Progress({
                            name = "hotwire",
                            duration = 20000,
                            label = 'Araç Maymuncuklanıyor...',
                            useWhileDead = false,
                            canCancel = false,
                            controlDisables = {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            },
                            animation = {
                                animDict = "mini@repair",
                                anim = "fixing_a_player",
                                flags = 49,
                            },
                        }, function(cancelled)
                            if not cancelled then
                                local luck = math.random(1, 3)
                                if luck == 1 then
                                    TriggerServerEvent('hsn-hotwire:addKeys',Plate)
                                    SetVehicleEngineOn(vehicle,true)
                                    exports['mythic_notify']:SendAlert('inform', 'Aracı başarıyla düzkontak yaptın!')
                                else
                                    exports['mythic_notify']:SendAlert('inform', 'Düzkontak yapmayı beceremedin!')
                                end
                            else
                                -- Do Something If Action Was Cancelled
                            end
                        end)
                        end, "lockpick")
                    end
                    if IsControlJustPressed(1, 20) then --Z
                        if SearchedVeh[Plate] ~= true then
                            SearchVehicle(Plate)
                        end
                    end
                    DrawText3Ds(vehicleCoords.x,vehicleCoords.y,vehicleCoords.z,text)
                end
            end
        end
        Citizen.Wait(wait)  
    end
end)

RegisterCommand('anahtarver', function()
    local vehicle = ESX.Game.GetVehicleInDirection()
    local Plate = GetVehicleNumberPlateText(vehicle)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if vehicle ~= nil then
        if Keys[Plate] == true then
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('hsn-hotwire:server:giveKeys',GetPlayerServerId(closestPlayer), Plate)
            else
                exports['mythic_notify']:SendAlert('inform', 'Yakında kimse yok!')
            end
        else
            exports['mythic_notify']:SendAlert('inform', 'Bu aracın anahtarlarına sahip değilsiniz!')
        end
    else
        exports['mythic_notify']:SendAlert('inform', 'Araca doğru bakmalısınız!')
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 750
        local veh = GetVehiclePedIsIn(PlayerPedId() , false)
        local Plate = GetVehicleNumberPlateText(veh)
        if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId() and Keys[Plate] ~= true then
            wait = 6
            SetVehicleEngineOn(veh, false)
        end
        Citizen.Wait(wait)
    end
end)

SearchVehicle = function(plate)
    SearchedVeh[plate] = true
    exports['mythic_progbar']:Progress({
        name = "search",
        duration = 12500,
        label = 'Araç Aranıyor...',
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "mini@repair",
            anim = "fixing_a_player",
            flags = 49,
        },
    }, function(cancelled)
        if not cancelled then
            TriggerServerEvent('hsn-hotwire:server:SearchVeh', plate)
        else
            -- Do Something If Action Was Cancelled
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)
        if IsControlJustPressed(1,182) then
            local coords = GetEntityCoords(PlayerPedId())
            vehicle = ESX.Game.GetClosestVehicle()
            local Plate = GetVehicleNumberPlateText(vehicle)
            if Keys[Plate] == true then
                local lock = GetVehicleDoorLockStatus(vehicle)
                if lock == 1 or lock == 0 then
                    TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
                    SetVehicleDoorShut(vehicle, 0, false)
                    SetVehicleDoorShut(vehicle, 1, false)
                    SetVehicleDoorShut(vehicle, 2, false)
                    SetVehicleDoorShut(vehicle, 3, false)
                    SetVehicleDoorsLocked(vehicle, 2)
                    PlayVehicleDoorCloseSound(vehicle, 1)
                    SetVehicleLights(vehicle, 2)
                    SetVehicleLights(vehicle, 0)
                    SetVehicleLights(vehicle, 2)
                    SetVehicleLights(vehicle, 0)
                    exports['mythic_notify']:SendAlert('inform', 'Araç kilitlendi.')
                elseif lock == 2 then
                    TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
                    SetVehicleDoorsLocked(vehicle, 1)
					PlayVehicleDoorOpenSound(vehicle, 0)
					SetVehicleLights(vehicle, 2)
					SetVehicleLights(vehicle, 0)
					SetVehicleLights(vehicle, 2)
                    SetVehicleLights(vehicle, 0)
                    exports['mythic_notify']:SendAlert('inform', 'Aracın kilidi açıldı.')
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1250
        if GetVehiclePedIsTryingToEnter(PlayerPedId()) ~= 0 then 
            local curveh = GetVehiclePedIsTryingToEnter(PlayerPedId())
            local pedDriver = GetPedInVehicleSeat(curveh, -1)
            local plate = GetVehicleNumberPlateText(curveh)
            if Keys[plate] ~= PlayerData.identifier and DoesEntityExist(pedDriver) and IsEntityDead(pedDriver) and not IsPedAPlayer(pedDriver)  then
                wait = 1
                exports['mythic_progbar']:Progress({
                    name = "takekeys",
                    duration = 2000,
                    label = 'Anahtar Alınıyor...',
                    useWhileDead = false,
                    canCancel = false,
                    controlDisables = {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    },
                }, function(cancelled)
                    if not cancelled then
                        TriggerServerEvent('hsn-hotwire:addKeys',plate)
                        exports['mythic_notify']:SendAlert('inform', 'Aracın anahtarlarını aldın!')
                    else
                        -- Do Something If Action Was Cancelled
                    end
                end)
            end
        end
        Citizen.Wait(wait)
    end
end)

AddKeys = function(plate)
    if plate ~= nil then
        TriggerServerEvent('hsn-hotwire:addKeys',plate)
    end
end