Config = Config or {}

Config.EnableWebhook = true

Config.DisableSave = false -- Disable saving for nos datas for vehicles , recommended if you are in a standalone/vMenu server or if your server does not identify cars with their plate numbers.

Config.Database = {
    SaveType = 'json',          -- 'json' or 'mysql' , choose json to save datas in a local json file, mysql to save datas in a database
    JSON = {
        FileName = 'datas.json' -- only used if SaveType is 'json'
    },
    MySQL = {
        SaveOnVehicleEdits = true, -- set to true to save nitrous datas when a vehicle is edited
        FullSaveOnStop = false,    -- set to true to save all nitrous datas when the server stops (recommended false to avoid issues on large servers)
    },
    AutoSave = {
        Enabled = true,
        Interval = 60,            -- in minutes
        OptimizeFullSaves = true, -- set to true to optimize full saves with batching, (only for mysql)
    }
}
Config.BillingTimeout = 180 -- in Seconds, after how many seconds of no response from target player, we timeout the bill

-- Inventory settings ,Add your inventory support in framework/server.lua (HasItem/AddItem/RemoveItem/RegisterUsableItem)
Config.Inventory = {
    Enable_Inventory = true,          -- Master toggle for using an external inventory system
    Inventory_Name   = 'ox_inventory' -- 'ox_inventory' | 'qb-inventory' | 'ps-inventory' | 'esx' | 'none'
}
