-- Unified framework / inventory helpers (qb-core, qbox, es_extended + ox/qb/esx inventories)

Framework = Framework or {}
local QBCore, ESX

-- Core detection (lazy loop to allow late start)
CreateThread(function()
    local waited = 0
    while waited < 5000 do
        if not QBCore and (GetResourceState('qb-core') == 'started' or GetResourceState('qbox') == 'started') then
            QBCore = exports['qb-core']:GetCoreObject()
        end
        if not ESX and GetResourceState('es_extended') == 'started' then
            if exports['es_extended'] and exports['es_extended']:getSharedObject() then
                ESX = exports['es_extended']:getSharedObject()
            else
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            end
        end
        if QBCore or ESX then break end
        Wait(250)
        waited = waited + 250
    end
end)

local function fwDebug(...)
    if Shared and Shared.Debug and Shared.DebugFiles and Shared.DebugFiles['main'] then
        print('[tuff-nitro][framework]', ...)
    end
end

local function useFramework()
    -- Default to true if unset (backwards compatible)
    return not (Shared and Shared.UseFramework == false)
end

-- Player helpers ---------------------------------------------------------
function Framework.GetPlayer(source)
    if QBCore then return QBCore.Functions.GetPlayer(source) end
    if ESX then return ESX.GetPlayerFromId(source) end
    return nil
end

function Framework.GetPlayerIdentifier(source)
    if not useFramework() then
        -- Standalone mode: provide a stable placeholder identifier.
        return 'standalone'
    end
    if QBCore then
        local p = Framework.GetPlayer(source)
        return p and p.PlayerData and p.PlayerData.citizenid
    elseif ESX then
        local xp = Framework.GetPlayer(source)
        return xp and xp.getIdentifier() or nil
    end
    return GetPlayerIdentifierByType(source, 'license')
end

function Framework.GetPlayerJob(source)
    if not useFramework() then
        return 'unemployed', 0
    end
    local job, grade = 'unemployed', 0
    if QBCore then
        local p = Framework.GetPlayer(source)
        if p and p.PlayerData and p.PlayerData.job then
            job = p.PlayerData.job.name
            grade = p.PlayerData.job.grade.level or 0
        end
    elseif ESX then
        local xp = Framework.GetPlayer(source)
        if xp and xp.getJob() then
            local j = xp.getJob()
            job = j.name
            grade = j.grade
        end
    end
    return job, grade
end

function Framework.IsPlayerAdmin(source)
    if IsPlayerAceAllowed(source, 'tuffnitro.admin') or IsPlayerAceAllowed(source, 'command') then return true end
    if QBCore and QBCore.Functions.HasPermission and QBCore.Functions.HasPermission(source, 'admin') then return true end
    if ESX then
        local xp = Framework.GetPlayer(source)
        if xp and (xp.getGroup and xp.getGroup() == 'admin' or xp.group == 'admin') then return true end
    end
    return false
end

function Framework.DoJobCheck(source, jobs)
    if not useFramework() then
        return true
    end
    if type(jobs) ~= 'table' then
        return false
    end
    local job, grade = Framework.GetPlayerJob(source)
    local cfg = jobs[job]
    if not cfg then return false end
    if type(cfg) == 'table' then
        for _, g in pairs(cfg) do if g == grade then return true end end
        return false
    end
    return true
end

function Framework.GetPlayerInGameName(source)
    local firstname, lastname = 'TestName', 'TestLastName'
    if QBCore then
        if not QBCore then
            QBCore = exports['qb-core']:GetCoreObject()
        end
        local Player = QBCore.Functions.GetPlayer(source)

        firstname, lastname = Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname
    elseif ESX then
        if not ESX then
            ESX = exports['es_extended']:getSharedObject()
        end
        local xPlayer = ESX.GetPlayerFromId(source)

        firstname, lastname = xPlayer.getName(), '#'
    else
        firstname, lastname = GetPlayerName(source), '#'
    end
    return firstname, lastname
end

-- Vehicle helpers --------------------------------------------------------
function Framework.GetVehicleRealPlate(vehicle)
    if not vehicle or vehicle == 0 then return '' end
    return GetVehicleNumberPlateText(vehicle)
end

function Framework.IsVehicleOwned(plate, vehicle)
    if not useFramework() then
        return true
    end
    if not plate or plate == '' then return false end
    if GetResourceState('qb-core') == 'started' or GetResourceState('qbox') == 'started' then
        local exists = exports.oxmysql:scalar_async('SELECT 1 FROM `player_vehicles` WHERE `plate` = ? LIMIT 1',
            { plate })
        return exists ~= nil
    elseif GetResourceState('es_extended') == 'started' then
        local exists = exports.oxmysql:scalar_async('SELECT 1 FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1', { plate })
        return exists ~= nil
    end
    return false
end

function Framework.GetVehicleOwner(plate, vehicle)
    if not useFramework() then
        -- Standalone mode: return the same placeholder used by GetPlayerIdentifier,
        -- so owner comparisons in server logic always succeed.
        return 'standalone'
    end
    if not plate or plate == '' then return nil end
    if GetResourceState('qb-core') == 'started' or GetResourceState('qbox') == 'started' then
        local owner = exports.oxmysql:scalar_async('SELECT `citizenid` FROM `player_vehicles` WHERE `plate` = ? LIMIT 1',
            { plate })
        return owner
    elseif GetResourceState('es_extended') == 'started' then
        local owner = exports.oxmysql:scalar_async('SELECT `owner` FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1',
            { plate })
        return owner
    end
    return nil
end

-- Money (placeholder integration, returns true if removed) ---------------
function Framework.RemovePlayerMoney(source, amount, method, reason, billedBy)
    if not useFramework() then
        return true
    end
    if amount <= 0 then return true end
    if QBCore then
        local p = Framework.GetPlayer(source); if not p then return false end
        local acct = (method == 'bank') and 'bank' or 'cash'
        local bal = p.PlayerData.money[acct] or 0
        if bal < amount then return false end
        p.Functions.RemoveMoney(acct, amount, reason or 'tuff-nitro')
        return true
    elseif ESX then
        local xp = Framework.GetPlayer(source); if not xp then return false end
        local acct = (method == 'bank') and 'bank' or 'cash'
        local bal = (acct == 'bank') and xp.getAccount('bank').money or xp.getMoney()
        if bal < amount then return false end
        if acct == 'bank' then xp.removeAccountMoney('bank', amount) else xp.removeMoney(amount) end
        return true
    end
    return true -- standalone
end

RemovePlayerMoney = Framework.RemovePlayerMoney
GetVehicleRealPlate = Framework.GetVehicleRealPlate

-- Billing payouts (society/player) -------------------------------------
local _billingHandlers = {
    payout = nil,
    society = nil,
    player = nil,
}

function Framework.RegisterBillingPayoutHandler(fn)
    _billingHandlers.payout = fn
end

function Framework.RegisterSocietyPayoutHandler(fn)
    _billingHandlers.society = fn
end

function Framework.RegisterPlayerPayoutHandler(fn)
    _billingHandlers.player = fn
end

exports('RegisterBillingPayoutHandler', Framework.RegisterBillingPayoutHandler)
exports('RegisterSocietyPayoutHandler', Framework.RegisterSocietyPayoutHandler)
exports('RegisterPlayerPayoutHandler', Framework.RegisterPlayerPayoutHandler)

function Framework.AddPlayerMoney(targetSource, amount, method, reason, meta)
    if amount <= 0 then return true end
    if _billingHandlers.player then
        local ok, handled = pcall(_billingHandlers.player, targetSource, amount, method, reason, meta)
        if ok and handled then return true end
    end
    if not useFramework() then
        return true
    end
    if QBCore then
        local p = Framework.GetPlayer(targetSource); if not p then return false end
        local acct = (method == 'bank') and 'bank' or 'cash'
        p.Functions.AddMoney(acct, amount, reason or 'tuff-nitro')
        return true
    elseif ESX then
        local xp = Framework.GetPlayer(targetSource); if not xp then return false end
        local acct = (method == 'bank') and 'bank' or 'cash'
        if acct == 'bank' then xp.addAccountMoney('bank', amount) else xp.addMoney(amount) end
        return true
    end
    return true
end

function Framework.AddSocietyMoney(societyName, amount, meta)
    if amount <= 0 then return true end
    if not societyName or societyName == '' then return false end
    if _billingHandlers.society then
        local ok, handled = pcall(_billingHandlers.society, societyName, amount, meta)
        if ok and handled then return true end
    end

    if GetResourceState('qb-management') == 'started' then
        exports['qb-management']:AddMoney(societyName, amount)
        fwDebug(('[billing] Society payout via qb-management: society=%s amount=%s')
            :format(tostring(societyName), tostring(amount)))
        return true
    end

    if GetResourceState('esx_society') == 'started' then
        TriggerEvent('esx_society:getSociety', societyName, function(society)
            if society and society.account then
                TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                    if account then account.addMoney(amount) end
                end)
            end
        end)
        fwDebug(('[billing] Society payout via esx_society: society=%s amount=%s')
            :format(tostring(societyName), tostring(amount)))
        return true
    end

    fwDebug(('[billing] Society payout skipped (no handler): society=%s amount=%s')
        :format(tostring(societyName), tostring(amount)))
    return false
end

function Framework.HandleBillingPayout(data)
    if _billingHandlers.payout then
        local ok, handled = pcall(_billingHandlers.payout, data)
        if ok and handled then return true end
    end

    if not data or not data.location or not data.location.Billing then
        TriggerEvent('tuff-nitro:billing:payout', data)
        return true
    end

    local billing = data.location.Billing
    local giveToSociety = billing.GiveToSociety == true and billing.SocietyName and billing.SocietyName ~= ''

    if giveToSociety then
        local ok = Framework.AddSocietyMoney(billing.SocietyName, data.amount, data)
        fwDebug(('[billing] Society payout %s: society=%s amount=%s payer=%s')
            :format(ok and 'ok' or 'failed', tostring(billing.SocietyName), tostring(data.amount),
                tostring(data.payer)))
    else
        if data.billedBy and data.billedBy ~= 0 and data.billedBy ~= data.payer then
            Framework.AddPlayerMoney(data.billedBy, data.amount, data.paymentMethod, data.reason or 'tuff-nitro', data)
        end
    end

    TriggerEvent('tuff-nitro:billing:payout', data)
    return true
end

exports('AddPlayerMoney', Framework.AddPlayerMoney)
exports('AddSocietyMoney', Framework.AddSocietyMoney)
exports('HandleBillingPayout', Framework.HandleBillingPayout)

-- Inventory helpers ------------------------------------------------------
local function invType()
    if not Config or not Config.Inventory or not Config.Inventory.Enable_Inventory then
        return 'none'
    end

    local function detectInventory()
        if GetResourceState('ox_inventory') == 'started' then return 'ox_inventory' end
        if GetResourceState('qb-inventory') == 'started' then return 'qb-inventory' end
        if GetResourceState('ps-inventory') == 'started' then return 'ps-inventory' end
        if GetResourceState('es_extended') == 'started' then return 'esx' end
        return 'none'
    end

    local name = Config.Inventory.Inventory_Name or 'none'
    local validInventories = {
        ['ox_inventory'] = true,
        ['qb-inventory'] = true,
        ['ps-inventory'] = true,
        ['esx'] = true,
        ['none'] = true,
    }

    if not validInventories[name] then
        print(('[^1tuff-nitro^7] ^1WARNING:^7 Inventory_Name is Incorrect . ^3Detected:^7 %s. Inventory disabled. Go to server/config.lua and set the Inventory_Name correctly !')
            :format(detectInventory()))
        return 'none'
    end

    if name == 'ox_inventory' and GetResourceState('ox_inventory') ~= 'started' then
        print(('[^1tuff-nitro^7] ^1WARNING:^7 Inventory_Name is Incorrect . ^3Detected:^7 %s. Inventory disabled. Go to server/config.lua and set the Inventory_Name correctly !')
            :format(detectInventory()))
        return 'none'
    end

    if name == 'qb-inventory' and GetResourceState('qb-inventory') ~= 'started' then
        print(('[^1tuff-nitro^7] ^1WARNING:^7 Inventory_Name is Incorrect . ^3Detected:^7 %s. Inventory disabled. Go to server/config.lua and set the Inventory_Name correctly !')
            :format(detectInventory()))
        return 'none'
    end

    if name == 'ps-inventory' and GetResourceState('ps-inventory') ~= 'started' then
        print(('[^1tuff-nitro^7] ^1WARNING:^7 Inventory_Name is Incorrect . ^3Detected:^7 %s. Inventory disabled. Go to server/config.lua and set the Inventory_Name correctly !')
            :format(detectInventory()))
        return 'none'
    end

    if name == 'esx' and GetResourceState('es_extended') ~= 'started' then
        print(('[^1tuff-nitro^7] ^1WARNING:^7 Inventory_Name is Incorrect . ^3Detected:^7 %s. Inventory disabled. Go to server/config.lua and set the Inventory_Name correctly !')
            :format(detectInventory()))
        return 'none'
    end

    return name
end

function Framework.HasItem(source, item, _)
    if not useFramework() then
        return 1
    end
    -- Returns numeric count of item in player inventory (0 if absent / inventory disabled)
    if not item then return 0 end
    if not Config or not Config.Inventory or not Config.Inventory.Enable_Inventory then return 0 end
    local inv = invType()
    if inv == 'ox_inventory' then
        local data = exports.ox_inventory:GetItem(source, item, nil, true)
        return (data and data.count) or 0
    elseif inv == 'qb-inventory' or inv == 'ps-inventory' then
        local p = Framework.GetPlayer(source); if not p then return 0 end
        local found = p.Functions.GetItemByName(item)
        return (found and found.amount) or 0
    elseif inv == 'esx' then
        local xp = Framework.GetPlayer(source); if not xp then return 0 end
        local itm = xp.getInventoryItem(item)
        return (itm and itm.count) or 0
    end
    return 0
end

function Framework.AddItem(source, item, count, meta)
    if not useFramework() then
        return true
    end
    count = count or 1
    local inv = invType()
    if inv == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, item, count, meta)
    elseif inv == 'qb-inventory' or inv == 'ps-inventory' then
        local p = Framework.GetPlayer(source); if not p then return false end
        p.Functions.AddItem(item, count, false, meta); return true
    elseif inv == 'esx' then
        local xp = Framework.GetPlayer(source); if not xp then return false end
        xp.addInventoryItem(item, count); return true
    end
    return false
end

function Framework.RemoveItem(source, item, count)
    if not useFramework() then
        return true
    end
    count = count or 1
    local inv = invType()
    if inv == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, item, count)
    elseif inv == 'qb-inventory' or inv == 'ps-inventory' then
        local p = Framework.GetPlayer(source); if not p then return false end
        p.Functions.RemoveItem(item, count); return true
    elseif inv == 'esx' then
        local xp = Framework.GetPlayer(source); if not xp then return false end
        xp.removeInventoryItem(item, count); return true
    end
    return false
end

function Framework.DoItemCheck(source, items)
    if not useFramework() then
        return true
    end
    if not items then return true end
    for name, amt in pairs(items) do
        if not Framework.HasItem(source, name, amt) then return false end
    end
    return true
end

function Framework.RemoveItemCheck(source, items)
    if not useFramework() then
        return
    end
    if not items then return end
    for name, amt in pairs(items) do
        if Framework.HasItem(source, name, amt) then Framework.RemoveItem(source, name, amt) end
    end
end

-- Usable item registrations ----------------------------------------------
local function registerUsableItem(name, cb)
    local inv = invType()
    if inv == 'ox_inventory' then
        exports(name, function(event, item, inventory, slot, data)
            if event == 'usingItem' and inventory.type == 'player' and item.name == name then
                cb(inventory.player.source, item)
                return true
            end
        end)
    elseif inv == 'qb-inventory' or inv == 'ps-inventory' then
        if QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
            QBCore.Functions.CreateUseableItem(name, function(src, item) cb(src, item) end)
        end
    elseif inv == 'esx' and ESX and ESX.RegisterUsableItem then
        ESX.RegisterUsableItem(name, function(src) cb(src, { name = name }) end)
    end
end

function Framework.RegisterUsables()
    if not Config or not Config.Inventory or not Config.Inventory.Enable_Inventory then return end
    -- Settings menu item
    if Shared.SettingMenu and Shared.SettingMenu.Interaction and Shared.SettingMenu.Interaction.ItemUsage then
        local itemName = Shared.SettingMenu.Interaction.ItemName
        if itemName and itemName ~= '' then
            registerUsableItem(itemName, function(src)
                TriggerClientEvent('tuff-nitro:clOpenSettings', src)
            end)
        end
    end
    -- Color customization items (if provided)
    local nitroItem = Shared.ColorCustomization and Shared.ColorCustomization.Nitrous and
        Shared.ColorCustomization.Nitrous.ItemUsage and Shared.ColorCustomization.Nitrous.ItemUsage.ItemName
    if nitroItem and nitroItem ~= '' then
        registerUsableItem(nitroItem, function(src) CustomizeNitrousColor(src) end)
    end
    local exhaustItem = Shared.ColorCustomization and Shared.ColorCustomization.Exhaust and
        Shared.ColorCustomization.Exhaust.ItemUsage and Shared.ColorCustomization.Exhaust.ItemUsage.ItemName
    if exhaustItem and exhaustItem ~= '' then
        registerUsableItem(exhaustItem, function(src) CustomizeExhaustColor(src) end)
    end
    -- Admin nitrous menu item
    local adminItem = Shared and Shared.Administration and Shared.Administration.ItemUsage and
        Shared.Administration.ItemUsage.Enabled and Shared.Administration.ItemUsage.ItemName
    if adminItem and adminItem ~= '' then
        registerUsableItem(adminItem, function(src)
            if not Framework.IsPlayerAdmin(src) then return end
            TriggerClientEvent('tuff-nitro:admin:openMenu', src)
        end)
    end
end

-- Nitrous / Exhaust item builders ---------------------------------------
GetNitrousItemsForPlayer = function(source, locationIndex)
    local items = {}
    if (Shared and Shared.UseFramework == false) or not Shared.Nitrous.RequireItem or (not Config or not Config.Inventory or not Config.Inventory.Enable_Inventory) then
        for itemName, info in pairs(Shared.Nitrous.Colors) do
            items[#items + 1] = {
                id = itemName,
                label = info.label,
                amount = 1,
                image = info.imageURL,
                custom = info.color == 'custom',
                color = info.colorHex
            }
        end
    else
        for itemName, info in pairs(Shared.Nitrous.Colors) do
            local itemCount = Framework.HasItem(source, itemName)
            if itemCount > 0 then
                items[#items + 1] = {
                    id = itemName,
                    label = info.label,
                    amount = itemCount,
                    image = info.imageURL,
                    custom = info.color == 'custom',
                    color = info.colorHex
                }
            end
        end
    end
    return items
end

GetExhaustItemsForPlayer = function(source, locationIndex)
    local items = {}
    if (Shared and Shared.UseFramework == false) or not Shared.Exhaust.RequireItem or (not Config or not Config.Inventory or not Config.Inventory.Enable_Inventory) then
        for itemName, info in pairs(Shared.Exhaust.Colors) do
            items[#items + 1] = {
                id = itemName,
                label = info.label,
                amount = 1,
                image = info.imageURL,
                custom = info.color == 'custom',
                color = info.colorHex
            }
        end
    else
        for itemName, info in pairs(Shared.Exhaust.Colors) do
            local itemCount = Framework.HasItem(source, itemName)
            if itemCount > 0 then
                items[#items + 1] = {
                    id = itemName,
                    label = info.label,
                    amount = itemCount,
                    image = info.imageURL,
                    custom = info.color == 'custom',
                    color = info.colorHex
                }
            end
        end
    end
    return items
end

-- Customize Colors command registration ---------------------------------
Citizen.CreateThread(function()
    Wait(500)
    if Shared.ColorCustomization and Shared.ColorCustomization.Nitrous and Shared.ColorCustomization.Nitrous.Command.Enabled then
        RegisterCommand(Shared.ColorCustomization.Nitrous.Command.CommandName,
            function(src, args) CustomizeNitrousColor(src) end, false)
    end
    if Shared.ColorCustomization and Shared.ColorCustomization.Exhaust and Shared.ColorCustomization.Exhaust.Command.Enabled then
        RegisterCommand(Shared.ColorCustomization.Exhaust.Command.CommandName,
            function(src, args) CustomizeExhaustColor(src) end, false)
    end
    Framework.RegisterUsables()
end)
