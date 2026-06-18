for locationIndex, locationInfo in pairs(Shared.Locations) do
    if locationInfo.Interaction.Command.Enabled then
        RegisterCommand(locationInfo.Interaction.Command.CommandName, function()
            RequestOpenMenuLocation(locationIndex, 'command')
        end, false)
    end
end

if Shared.SettingMenu.Enabled and Shared.SettingMenu.Interaction.CommandUsage then
    RegisterCommand(Shared.SettingMenu.Interaction.CommandName, function()
        RequestOpenSettingsMenu()
    end, false)
end
if Shared.Debug then
    RegisterCommand('firstSpawnNitrous', function()
        SpawnFirstTime()
    end, false)
end
AddEventHandler('playerSpawned', function()
    SpawnFirstTime()
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SpawnFirstTime()
end)

-- 3D text hook
-- Server owners can override this global to implement their own 3D text.
-- Return true if you've drawn the text yourself so default drawing is skipped.
-- Signature: Draw3DText(vec3 position, string text) -> boolean
Draw3DText = Draw3DText or function(position, text)
    return false
end

-- global tooltip for opening the menu and hiding it
ShowTooltip = function(label)
    local text = string.format('Press [E] To Open %s', label)
    SendNUIMessage({
        action = 'setDatas',
        datas = {
            isOnlyHint = true,
            hints = {
                normal = {
                    active = true,
                    text = text
                }
            }
        }
    })
    SendNUIMessage({
        action = 'toggleMenu',
        status = true
    })
end
HideTooltip = function()
    -- Allow the UI transition to ease out before closing the menu
    _G.__tuffNitroHintHideToken = (_G.__tuffNitroHintHideToken or 0) + 1
    local token = _G.__tuffNitroHintHideToken
    SendNUIMessage({
        action = 'setDatas',
        datas = {
            isOnlyHint = true,
            hints = {
                normal = {
                    active = false,
                    text = 'nil'
                },
                error = {
                    active = false,
                    text = 'nil'
                }
            }
        }
    })
    CreateThread(function()
        Wait(250)
        if _G.__tuffNitroHintHideToken ~= token then return end
        SendNUIMessage({
            action = 'toggleMenu',
            status = false
        })
    end)
end


-- progress bar

IsDoingProgressBar = function()
    return lib.progressActive()
end
ProgressBar = function(duration, label, animInfo)
    print('Starting progress bar', duration, label)
    -- Choose a fitting animation based on context (install vs pickup)
    local animData
    if animInfo then
        animData = animInfo
    elseif type(label) == 'string' and label:lower():find('pick') then
        -- Pickup-like animation (works for grabbing items)
        animData = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
            flags = 49,
        }
    else
        -- Mechanic kneel/base animation (good for installs)
        animData = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flags = 49,
        }
    end
    if lib.progressCircle({
            duration = duration,
            label = label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            anim = animData,
            disable = {
                car = true,
                move = true,
                combat = true,
                sprint = true,
            },
        }) then
        return true
    else
        return false
    end
end

DoesThisCarHasTurbo = function(vehicle)
    local hasTurbo = IsToggleModOn(vehicle, 18)
    return (hasTurbo == 1 or hasTurbo == true) or false
end

RegisterNetEvent('tuff-nitro:client:Notify', function(message, type, cd)
    Notify(message, type, cd)
end)

Notify = function(message, type, cd)
    if not cd then cd = 5000 end
    local ntype = type or 'info'
    local cooldown = cd
    local title = "Tuff Nitrous v2"
    local translatedMessage = message
    if Shared.Notify == "codem" then
        TriggerEvent('codem-notification:Create', translatedMessage, "bminfo", title, cooldown)
    elseif Shared.Notify == "esx" then
        if not ESX then
            if exports['es_extended'] and exports['es_extended']:getSharedObject() then
                ESX = exports['es_extended']:getSharedObject()
            else
                TriggerEvent('esx:getSharedObject', function(obj)
                    ESX = obj
                end)
            end
        end
        ESX.ShowNotification(translatedMessage)
    elseif Shared.Notify == "qb" then
        if not QBCore then
            QBCore = exports['qb-core']:GetCoreObject()
        end
        QBCore.Functions.Notify({ text = translatedMessage, caption = title }, ntype, cooldown)
    elseif Shared.Notify == "okok" then
        exports['okokNotify']:Alert(title, translatedMessage, cooldown, ntype)
    elseif Shared.Notify == 'wasabi' then
        exports.wasabi_notify:notify(title, translatedMessage, cooldown, ntype)
    elseif Shared.Notify == 't-notify' then
        exports['t-notify']:Alert({ style = ntype, message = translatedMessage, duration = cooldown, })
    elseif Shared.Notify == 'r_notify' then
        exports.r_notify:notify({
            title = title,
            content = translatedMessage,
            type = ntype,
            icon = "fas fa-check",
            duration =
                cooldown,
            position = 'top-right',
            sound = false
        })
    elseif Shared.Notify == 'pNotify' then
        exports['pNotify']:SendNotification({
            text = translatedMessage,
            type = ntype,
            timeout = cooldown,
            layout =
            'centerRight'
        })
    elseif Shared.Notify == 'mythic' then
        exports['mythic_notify']:SendAlert('inform', translatedMessage, cooldown)
    elseif Shared.Notify == "ox_lib" or lib then
        lib.notify({
            title = title,
            description = translatedMessage,
            type = ntype
        })
    end
end




local function collectExhaustBoneNames(maxBones)
    local names = { 'exhaust' }
    for i = 0, (maxBones or 32) - 1 do
        names[#names + 1] = ('exhaust_%d'):format(i)
    end
    return names
end

local function logExhaustBonesForEntity(label, entity, boneNames)
    if not DoesEntityExist(entity) then
        print(('[tuff-nitro] %s entity missing; skipping bone log'):format(label))
        return
    end
    print(('--- Exhaust bones for %s (%d) ---'):format(label, entity))
    for _, boneName in ipairs(boneNames) do
        local boneIndex = GetEntityBoneIndexByName(entity, boneName)
        if boneIndex and boneIndex ~= -1 then
            local bonePos = GetWorldPositionOfEntityBone(entity, boneIndex)
            print(string.format(' %s idx=%d pos=(%.3f, %.3f, %.3f)', boneName, boneIndex, bonePos.x, bonePos.y,
                bonePos.z))
        end
    end
end
local nitroHudLastSignature = nil

local function _trimPlate(plate)
    if type(plate) ~= 'string' then return nil end
    return (plate:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function _buildNitroHudPayload(vehicle, nitroLevel, isActive)
    local level = math.max(0, math.min(100, math.floor((tonumber(nitroLevel) or 0) + 0.5)))
    local payload = {
        level = level,
        active = isActive == true,
        vehicle = 0,
        inVehicle = false,
        plate = nil,
        hasNitrous = false,
        nitroId = nil,
        nitroLabel = nil,
        selectedMode = 'nitrous',
        selectedNitroLevel = nil,
        selectedPurgeLevel = nil,
        raw = nil
    }

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        payload.vehicle = vehicle
        payload.inVehicle = true
        payload.plate = _trimPlate(GetVehicleNumberPlateText(vehicle))

        local ent = Entity(vehicle)
        if ent and ent.state and type(ent.state.nitrous) == 'table' then
            local raw = {}
            for k, v in pairs(ent.state.nitrous) do
                raw[k] = v
            end
            payload.raw = raw
            payload.hasNitrous = payload.raw.id ~= nil and payload.raw.id ~= false
            if payload.raw.id ~= nil then
                payload.nitroId = tostring(payload.raw.id)
            else
                local color = payload.raw.nitrousColor or payload.raw.color
                if type(color) == 'string' and color ~= '' then
                    payload.nitroId = ('nitrous_%s'):format(color)
                else
                    payload.nitroId = 'nitrous_default'
                end
            end

            local colors = Shared and Shared.Nitrous and Shared.Nitrous.Colors
            if colors and payload.nitroId and colors[payload.nitroId] and colors[payload.nitroId].label then
                payload.nitroLabel = colors[payload.nitroId].label
            else
                payload.nitroLabel = payload.raw.label or payload.raw.nitrousColor or payload.raw.color
            end
            if nitroLevel == nil then
                payload.level = math.max(0, math.min(100, math.floor((tonumber(payload.raw.fill) or 0) + 0.5)))
            end
        end
    end

    local runtimeProvider = rawget(_G, 'GetTuffNitroRuntimeState')
    if type(runtimeProvider) == 'function' then
        local ok, runtime = pcall(runtimeProvider)
        if ok and type(runtime) == 'table' then
            if type(runtime.mode) == 'string' and runtime.mode ~= '' then payload.selectedMode = runtime.mode end
            payload.selectedNitroLevel = tonumber(runtime.selectedNitroLevel) or nil
            payload.selectedPurgeLevel = tonumber(runtime.selectedPurgeLevel) or nil
        end
    end

    return payload
end

local function _triggerNitroHudEvent(eventName, args)
    if type(eventName) ~= 'string' or eventName == '' then return false end
    local ok = pcall(function()
        TriggerEvent(eventName, table.unpack(args))
    end)
    return ok
end

local function _triggerNitroHudExport(resourceName, exportName, args)
    if type(resourceName) ~= 'string' or resourceName == '' then return false end
    if type(exportName) ~= 'string' or exportName == '' then return false end
    if GetResourceState(resourceName) ~= 'started' then return false end
    local ok = pcall(function()
        exports[resourceName][exportName](table.unpack(args))
    end)
    return ok
end

-- Universal HUD bridge for nitrous.
-- Supports:
-- 1) Event adapters  (TriggerEvent)
-- 2) Export adapters (exports[resource][export](...))
-- 3) Custom Lua callback in config
UpdateExternalNitroHud = function(vehicle, nitroLevel, isActive, force)
    local hudCfg = Shared and Shared.Nitrous and Shared.Nitrous.HudBridge or nil
    if hudCfg and hudCfg.Enabled == false then return end

    local payload = _buildNitroHudPayload(vehicle, nitroLevel, isActive)
    local signature = string.format('%s|%s|%s|%s', payload.level, payload.active and 1 or 0, payload.plate or '',
        payload.hasNitrous and 1 or 0)
    if not force and nitroHudLastSignature == signature then
        return
    end
    nitroHudLastSignature = signature

    local adapters = hudCfg and hudCfg.Adapters or nil
    if type(adapters) == 'table' then
        for _, adapter in pairs(adapters) do
            if type(adapter) == 'table' and adapter.Enabled ~= false then
                local args = { payload.level, payload.active }
                if type(adapter.BuildArgs) == 'function' then
                    local okArgs, built = pcall(adapter.BuildArgs, payload)
                    if okArgs and type(built) == 'table' then
                        args = built
                    end
                end

                local adapterType = string.lower(tostring(adapter.Type or 'event'))
                if adapterType == 'export' then
                    _triggerNitroHudExport(adapter.Resource, adapter.Export or adapter.ExportName, args)
                else
                    _triggerNitroHudEvent(adapter.EventName, args)
                end
            end
        end
    end

    if hudCfg and type(hudCfg.CustomHandler) == 'function' then
        pcall(hudCfg.CustomHandler, payload)
    end
end

-- Backward-compatible alias for old integrations.
UpdateQbHudNitrous = function(nitroLevel, isActive, force)
    UpdateExternalNitroHud(0, nitroLevel, isActive, force)
end

local function _copyTableShallow(tbl)
    if type(tbl) ~= 'table' then return nil end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end

local function _resolveNitroIdFromState(nitrousState)
    if type(nitrousState) ~= 'table' then return nil end
    if nitrousState.id ~= nil then return tostring(nitrousState.id) end
    local color = nitrousState.nitrousColor or nitrousState.color
    if type(color) == 'string' and color ~= '' then
        return ('nitrous_%s'):format(color)
    end
    return 'nitrous_default'
end

local function _resolveNitroLabel(nitroId, nitrousState)
    local colors = Shared and Shared.Nitrous and Shared.Nitrous.Colors
    if colors and nitroId and colors[nitroId] and colors[nitroId].label then
        return colors[nitroId].label
    end
    if type(nitrousState) == 'table' then
        if type(nitrousState.label) == 'string' and nitrousState.label ~= '' then return nitrousState.label end
        if type(nitrousState.nitrousColor) == 'string' and nitrousState.nitrousColor ~= '' then return nitrousState.nitrousColor end
        if type(nitrousState.color) == 'string' and nitrousState.color ~= '' then return nitrousState.color end
    end
    return nil
end

-- Client HUD export: returns current nitrous data for custom HUD integrations.
GetNitroHudData = function()
    local data = {
        inVehicle = false,
        isDriver = false,
        vehicle = 0,
        hasNitrous = false,
        nitroId = nil,
        nitroLabel = nil,
        fill = 0,
        level = 0,
        isUsingNitrous = false,
        isPurging = false,
        selectedMode = 'nitrous',
        selectedNitroLevel = nil,
        selectedPurgeLevel = nil,
        nitroActiveLocal = false,
        purgeActiveLocal = false,
        nitrous = nil
    }

    local runtimeProvider = rawget(_G, 'GetTuffNitroRuntimeState')
    if type(runtimeProvider) == 'function' then
        local ok, runtime = pcall(runtimeProvider)
        if ok and type(runtime) == 'table' then
            if type(runtime.mode) == 'string' and runtime.mode ~= '' then data.selectedMode = runtime.mode end
            if type(runtime.selectedNitroLevel) == 'number' then data.selectedNitroLevel = runtime.selectedNitroLevel end
            if type(runtime.selectedPurgeLevel) == 'number' then data.selectedPurgeLevel = runtime.selectedPurgeLevel end
            data.nitroActiveLocal = runtime.nitroActiveLocal == true
            data.purgeActiveLocal = runtime.purgeActiveLocal == true
        end
    end

    local ped = PlayerPedId()
    if not ped or ped <= 0 then return data end

    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return data end

    data.inVehicle = true
    data.vehicle = veh
    data.isDriver = GetPedInVehicleSeat(veh, -1) == ped

    local ent = Entity(veh)
    local entState = ent and ent.state or nil
    if not entState then
        if data.selectedNitroLevel == nil then data.selectedNitroLevel = 1 end
        if data.selectedPurgeLevel == nil then data.selectedPurgeLevel = 1 end
        return data
    end

    data.isUsingNitrous = entState.isUsingNitrous == true
    data.isPurging = entState.isPurging == true

    local nitrousState = entState.nitrous
    if type(nitrousState) == 'table' then
        data.nitrous = _copyTableShallow(nitrousState)
        data.hasNitrous = nitrousState.id ~= nil and nitrousState.id ~= false
        data.nitroId = _resolveNitroIdFromState(nitrousState)
        data.nitroLabel = _resolveNitroLabel(data.nitroId, nitrousState)
        data.fill = math.max(0, math.min(100, tonumber(nitrousState.fill) or 0))
        data.level = tonumber(nitrousState.level) or 0
    end

    if data.selectedNitroLevel == nil then
        data.selectedNitroLevel = (data.level > 0) and data.level or 1
    end
    if data.selectedPurgeLevel == nil then
        data.selectedPurgeLevel = 1
    end

    return data
end

exports('GetNitroHudData', function()
    return GetNitroHudData()
end)

exports('GetNitroData', function()
    return GetNitroHudData()
end)
