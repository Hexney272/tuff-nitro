Shared = Shared or {}

-- ================================================================
-- GLOBAL SETTINGS (read first)
-- ================================================================

-- Framework checks master toggle.
-- When false: job/ownership/item/admin/money checks are bypassed server-side
-- and only CustomRestriction callbacks are enforced.

-- Inventory settings are located in server/config.lua.

Shared.UseFramework = true

-- Only owned vehicles can use/install/remove nitrous.
Shared.OnlyOwnedVehicles = false

-- Notification system (see framework/client.lua for supported values)
Shared.Notify = "ox_lib" -- "qb", "esx", "okok" etc

-- Debug logging (enable only when troubleshooting)
Shared.Debug = false

-- Rejoin/server-restart troubleshooting:
--   main + serverMain = vehicle state restore/ensure logs
--   statehandler     = default exhaust-pop reconcile logs
--   backfire         = custom backfire sound bank + pop evaluator logs
--   gauge            = Nitro/Settings UI close-vs-gauge timing logs
Shared.DebugFiles = {
    ['backfire'] = false,       -- client/backfire.lua
    ['gauge'] = false,          -- client/gauge.lua
    ['particlefx'] = false,     -- client/particlefx.lua
    ['preview'] = false,        -- client/preview.lua
    ['statehandler'] = true,    -- client/statehandler.lua
    ['installation'] = false,   -- client/installation.lua
    ['custom_exhaust'] = false, -- client/custom_exhaust.lua
    ['main'] = false,           -- client/main.lua
    ['serverMain'] = false,     -- server/main.lua
    ['database'] = false        -- server/database.lua
}

-- ================================================================
-- ADMIN SETTINGS
-- ================================================================
Shared.Administration = {
    NitrousCommand = "adminnitro", -- Command to force-open nitrous UI as admin
    ItemUsage = {
        Enabled = false,
        ItemName = "adminnitro_kit"
    },
    LocationSettings = {
        -- Admin menu settings (mirror location options)
        AllowNitrousInstall = true,
        AllowExhaustInstall = true,
        AllowAntilag2StepInstall = true,
        Costs = {
            InstallNitrousCost = 0,
            RemovalNitrousCost = 0,
            RefillNitrousCost = 0,
            InstallExhaustCost = 0,
            RemovalExhaustCost = 0,
            InstallAntilag2StepCost = 0,
            EditAntilag2StepCost = 0,
        },
        AllowAntiLag2StepSelfEdit = true,
        AllowSelfRefillRecolor = true,
        AllowSelfRemoval = true,
    }
}

-- Backfire settings
Shared.Backfire = {
    -- Upshift/Downshift pop behavior: 'upshift' | 'downshift' | 'both'
    ShiftPopMode = 'downshift',
    -- Throttle-release pop thresholds (used for realistic decel pops)
    ThrottleRelease = {
        Default = {
            high = 0.35,  -- previous throttle must be at/above this
            low = 0.05,   -- current throttle must drop to/under this
            rpmMin = 0.50 -- minimum RPM to allow throttle-release pop
        },
        Classes = {
            [6] = { high = 0.30, low = 0.05, rpmMin = 0.45 }, -- Sports
            [7] = { high = 0.28, low = 0.05, rpmMin = 0.45 }, -- Super
            [4] = { high = 0.38, low = 0.06, rpmMin = 0.55 }, -- Muscle
            [2] = { high = 0.40, low = 0.06, rpmMin = 0.55 }, -- SUVs
        }
    }
}

-- Carrying props: control blocking
Shared.CarryControls = {
    Enabled = true,
    -- List of control IDs to disable while carrying props
    DisableControls = {
        21,  -- Sprint
        22,  -- Jump
        36,  -- Duck / Crouch
        24,  -- Attack
        25,  -- Aim
        140, -- Melee attack (light)
        141, -- Melee attack (heavy)
        142, -- Melee attack (alternate)
        237, -- Mouse Left Click
        44,  -- Cover (Q)
    },
    -- Optional custom function for extra control blocking
    CustomDisable = function()
        -- Example:
        -- DisableControlAction(0, 38, true) -- E key
    end
}

Shared.RemovalCommand = {
    Enabled = true,     -- Enable /dv_nitro command
    CommandName = 'dv_nitro',
    RemovalCost = 2000, -- Price charged when removing nitrous

    Permissions = {
        OnlyAllowAdmins = false,             -- Only admins can use this command
        JobRequired = true,
        CustomRestriction = function(source) -- Server-side custom permission check
            return true
        end,
        Jobs = {
            ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
            ["police"] = true           -- All grades allowed
        },
    },
}

-- Configuration for drawing a marker on the ground at stance locations.
Shared.DrawMarker = {
    enabled         = true, -- Enable/disable the ground marker at locations
    Scale           = 1.0,
    MarkerType      = 20,   -- Marker type (see https://docs.fivem.net/docs/game-references/markers/)

    -- RGBA color values (0–255)
    red             = 255,
    green           = 255,
    blue            = 252,
    alpha           = 100,

    MarkerUpAndDown = true, -- Vertical pulsing animation
    MarkerRotate    = true, -- Rotates in place
}

Shared.CameraEffect = {
    Enabled = true,
    ShakeEffect = 'RPG_RECOIL_SHAKE', -- Full list: https://docs.fivem.net/natives/?_0xFD55E49555E017CF
    Intensity = {
        minimum = 0.05,
        maximum = 0.3,
        RampTime = 4.0,  -- Seconds to reach maximum intensity
    },
    ShakeInterval = 100, -- Milliseconds between each shake
    FadeOut = {
        Steps = 15,      -- Number of fade-out steps (more = smoother)
        Interval = 30,   -- Milliseconds between each fade step (total fade time = Steps * Interval)
    },
}

Shared.SettingMenu = {
    Enabled = true,
    OnlyAllowOpenWhileInCar = false, -- If true, settings open only inside a car with nitrous installed
    Interaction = {
        CommandUsage = true,
        CommandName = 'nitrosettings',   -- Command to open settings menu
        ItemUsage = false,
        ItemName = 'nitro_settings_item' -- Item name to open settings menu
    },
    QuickViewTime = 3,                   -- Seconds that quick-view gauge stays visible
    DefaultUISoundVolume = 0.2,          -- 0.0 - 1.0 default UI sound volume (hover/click)
    KeybindBlacklist = {
        ['LEFTCTRL'] = true,
        ['LEFTSHIFT'] = true,
        ['TAB'] = true,
        ['CAPS'] = true,
        ['LEFTALT'] = true,
        ['RIGHTCTRL'] = true,
        ['RIGHTSHIFT'] = true,
        ['SPACE'] = true,
        ['ENTER'] = true,
        ['BACKSPACE'] = true,
        ['DELETE'] = true,
        ['INSERT'] = true,
        ['HOME'] = true,
        ['END'] = true,
        ['PAGEUP'] = true,
        ['PAGEDOWN'] = true,
        ['NUMLOCK'] = true,
        ['SCROLLLOCK'] = true,
    },
}

-- ================================================================
-- LOCATIONS / SHOPS
-- ================================================================
Shared.Locations = {
    ['mechanicshop'] = {
        Label = 'Mechanic Nitrous',
        Interaction = {
            Location = {
                Enabled = true,
                Coordinates = vector3(-212.95, -1328.34, 30.89),
                InteractDistance = 5.0,
                Blip = {
                    Enabled = true,
                    Sprite = 446,
                    Color = 5,
                    DisplayType = 4,
                    Scale = 0.7,
                    Name = 'Mechanic Nitrous Shop',
                },
            },
            ItemUsage = {
                Enabled = false,
                ItemName = ''
            },
            Command = {
                Enabled = true,
                CommandName = 'open_nitro'
            }
        },
        Installation = {                                         -- Installation/Refill/Removal process
            Enabled = true,                                      -- Enable installation workflow
            InstallationLoc = vector3(-227.89, -1329.34, 30.89), -- Prop pickup/delivery location
            EnabledForRefill = true,                             -- Enable nitrous refills
            EnabledForRemoval = true,                            -- Enable removal process
            EnabledForEdit = true,                               -- Enable antilag edit process
        },
        Permissions = {
            JobRequired = true,
            CustomRestriction = function(source) -- Custom function to restrict who can install things, -- Server side
                return true
            end,
            Jobs = {
                ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
                ["police"] = false          -- All grades allowed
            },
            ItemRequired = false,
            Items = { "screwdriver" }, -- Items required to install
        },
        Billing = {
            Enabled = true,        -- Allow billing other players at this location
            GiveToSociety = false, -- If true, money goes to SocietyName instead of player
            SocietyName = ''
        },
        AllowNitrousInstall = true,
        AllowExhaustInstall = true,
        AllowAntilag2StepInstall = false,
        Costs = {
            InstallNitrousCost = 5000,      -- Install nitrous
            RemovalNitrousCost = 2000,      -- Remove nitrous
            RefillNitrousCost = 1000,       -- Refill nitrous
            InstallExhaustCost = 3000,      -- Install exhaust
            RemovalExhaustCost = 1500,      -- Remove exhaust
            InstallAntilag2StepCost = 7000, -- Install antilag/2-step
            EditAntilag2StepCost = 3500,    -- Edit antilag/2-step
        },

        AllowAntiLag2StepSelfEdit = true, -- Allow players to edit their own anti-lag/2-step
        AllowSelfRefillRecolor = true,    -- Allow self-service refill/recolor
        AllowSelfRemoval = true,          -- Allow self-service removal
    }
}

-- Blacklist system for vehicles
-- ================================================================
-- VEHICLE BLACKLISTS
-- ================================================================
Shared.Blacklist = {
    Class = { -- by vehicle class
        --[1] = true, -- Sedans
        --[0] = true, -- Compacts
        --[2] = true, -- SUVs
        --[3] = true, -- Coupes
        --[5] = true, -- Sports Classics
        --[4] = true, -- Muscle
        --[6] = true, -- Sports
        --[7] = true, -- Super
        [8] = true,  -- Motorcycles
        --[9] = true, -- Off-road
        [10] = true, -- Industrial
        [11] = true, -- Utility
        --[12] = true, -- Vans
        [13] = true, -- Cycles
        [14] = true, -- Boats
        [15] = true, -- Helicopters
        [16] = true, -- Planes
        --[17] = true, -- Service
        --[18] = true, -- Emergency
        --[19] = true, -- Military
        --[20] = true, -- Commercial
        [21] = true, -- Trains
        [22] = true, -- Open Wheel
    },
    Model = {        -- by vehicle model
        [`adder`] = true,
    }
}
-- ================================================================
-- PURGE SYSTEM
-- ================================================================
Shared.Purge = {    -- Purge Options
    Enabled = true, -- Enable/Disable purge system
    cycleKey = {
        Key = 'Z',
        Label = 'Purge Cycle Keybind'
    },                                       -- Keybind to cycle purge locations

    AllowCustomColor = {                     -- Allow the player to customize the purge Color in real time
        Enabled = true,
        CustomRestriction = function(source) -- Custom function to restrict who can use the custom color picker
            return true
        end,
        JobRestriction = {
            Enabled = false,
            Jobs = {
                ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
                ["police"] = true           -- All grades allowed
            },
        },
        Command = {
            Enabled = true,
            Name = "purgecolor",       -- /purgecolor
        },
        Item = {                       -- tie to item usage
            Enabled = true,
            Name = "purge_color_item", -- item name for purge color
        }
    },
    -- Locations to show purge upon cycle (add more below)
    PurgeLocations = {
        ["Front Wheels"] = { -- [bone name] = { pos = 'left'/'right', offset = vector3(x,y,z) }
            ['wheel_lf'] = { pos = 'left', offset = vector3(-0.1, 0.5, 0.05) },
            ['wheel_rf'] = { pos = 'right', offset = vector3(0.1, 0.5, 0.05) },
        },
        ["Back Wheels"] = {
            ['wheel_lr'] = { pos = 'left', offset = vector3(-0.1, 0.5, 0.05) },
            ['wheel_rr'] = { pos = 'right', offset = vector3(0.1, 0.5, 0.05) },
        },
        ["Headlights"] = {
            ['headlight_l'] = { pos = 'left', offset = vector3(0, 0, 0) },
            ['headlight_r'] = { pos = 'right', offset = vector3(0, 0, 0) },
        },
        ["Dorrhandles"] = {
            ['handle_dside_f'] = { pos = 'left', offset = vector3(0, 0, 0) },
            ['handle_pside_f'] = { pos = 'right', offset = vector3(0, 0, 0) },
        },
        ["Taillights"] = {
            ['taillight_l'] = { pos = 'left', offset = vector3(0, 0, 0) },
            ['taillight_r'] = { pos = 'right', offset = vector3(0, 0, 0) },
        },
        ["All"] = {
            ['handle_dside_f'] = { pos = 'left', offset = vector3(0, 0, 0) },
            ['handle_pside_f'] = { pos = 'right', offset = vector3(0, 0, 0) },
            ['wheel_lf']       = { pos = 'left', offset = vector3(-0.1, 0.5, 0.05) },
            ['wheel_rf']       = { pos = 'right', offset = vector3(0.1, 0.5, 0.05) },
            ['wheel_lr']       = { pos = 'left', offset = vector3(-0.1, 0.5, 0.05) },
            ['wheel_rr']       = { pos = 'right', offset = vector3(0.1, 0.5, 0.05) },
            ['headlight_l']    = { pos = 'left', offset = vector3(0, 0, 0) },
            ['headlight_r']    = { pos = 'right', offset = vector3(0, 0, 0) },
            ['taillight_l']    = { pos = 'left', offset = vector3(0, 0, 0) },
            ['taillight_r']    = { pos = 'right', offset = vector3(0, 0, 0) },
        },
    },
    Levels = {
        [1] = { drainRate = 1.0, },
        [2] = { drainRate = 2.0, },
        [3] = { drainRate = 3.0, },
        [4] = { drainRate = 4.0, },
    }
}
-- ================================================================
-- TRAILS SYSTEM
-- ================================================================
Shared.Trails = {
    Enabled = true,                          -- Enable/Disable trails system
    AllowCustomColor = {                     -- Allow the player to customize the trail Color in real time
        Enabled = true,
        CustomRestriction = function(source) -- Custom function to restrict who can use the custom color picker
            return true
        end,
        JobRestriction = {
            Enabled = false,
            Jobs = {
                ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
                ["police"] = true           -- All grades allowed
            },
        },
        Command = {
            Enabled = true,
            Name = "trailcolor",       -- /trailcolor
        },
        Item = {                       -- tie to item usage
            Enabled = true,
            Name = "trail_color_item", -- item name for trail color
        }
    },
}
-- ================================================================
-- NITROUS SYSTEM
-- ================================================================
Shared.Nitrous = {
    -- When true: use hex color values instead of streamed particle files for nitrous flames.
    UseHexColors = false,
    RequireItem = false,          -- If true, nitrous colors require items; if false, mechanic can install any color
    RequireTurboOnCar = false,    -- Require turbo mod on the car to install nitrous
    ReturnItemOnRemoval = true,   -- Return installed item on removal (if RequireItem = true)
    ShowGaugeToPassengers = true, -- Show nitrous gauge to passengers
    GaugeAutoCloseMs = 3000,      -- Auto-close gauge after this many ms

    -- Universal external HUD bridge (events + exports + custom callback)
    -- Payload passed to adapters/custom handler:
    -- data.level (0-100), data.active (true/false), data.hasNitrous (true/false),
    -- data.plate, data.nitroId, data.nitroLabel, data.selectedMode, data.vehicle, data.raw
    HudBridge = {
        Enabled = false,            -- master toggle for push updates to external HUDs
        DisableBuiltInGauge = true, -- when HudBridge is enabled, hide built-in gauge UI

        -- Optional custom callback (runs after adapters). Use this for fully custom logic.
        CustomHandler = function(data)
            -- Example:
            -- TriggerEvent('your-hud:nitro:update', data.level, data.active, data.hasNitrous)
        end,

        -- Add as many adapters as you want.
        Adapters = {
            {
                Name = 'qb-hud',
                Enabled = true,
                Type = 'event', -- 'event' or 'export'
                EventName = 'hud:client:UpdateNitrous',
                BuildArgs = function(data)
                    -- qb-hud format:
                    -- RegisterNetEvent('hud:client:UpdateNitrous', function(nitroLevel, bool) ... end)
                    return { data.level, data.active }
                end
            },

            -- Example export adapter:
            --{
            --    Name = 'custom-hud',
            --    Enabled = false,
            --    Type = 'export',
            --    Resource = 'custom-hud',
            --    Export = 'UpdateNitrous',
            --    BuildArgs = function(data)
            --        -- Example export args: level, hasNitrous, active, plate
            --        return { data.level, data.hasNitrous, data.active, data.plate }
            --    end
            --},
        }
    },

    Colors = {
        ['nitrous_blue'] = {               -- Item Name
            color = 'blue',                -- color
            label = 'Nitrous Blue',
            colorHex = '#0084ff',          -- used for UI
            imageURL = 'nitrous_blue.png', -- image for UI
            prop = 'tuff_nos_blue'         -- prop name
        },
        ['nitrous_cyan'] = {
            color = 'cyan',
            label = 'Nitrous Cyan',
            colorHex = '#00fbff',
            imageURL = 'nitrous_cyan.png',
            prop = 'tuff_nos_cyan'
        },
        ['nitrous_default'] = {
            color = 'default',
            label = 'Nitrous Default',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_default.png',
            prop = 'tuff_nos_white'
        },
        ['nitrous_green'] = {
            color = 'green',
            label = 'Nitrous Green',
            colorHex = '#00FF00',
            imageURL = 'nitrous_green.png',
            prop = 'tuff_nos_green'
        },
        ['nitrous_mix1'] = {
            color = 'mix1',
            label = 'Nitrous Mix 1',
            colorHex = '#FF7A00',
            imageURL = 'nitrous_mix1.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_mix2'] = {
            color = 'mix2',
            label = 'Nitrous Mix 2',
            colorHex = '#8A00FF',
            imageURL = 'nitrous_mix2.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_pink'] = {
            color = 'pink',
            label = 'Nitrous Pink',
            colorHex = '#FF00FF',
            imageURL = 'nitrous_pink.png',
            prop = 'tuff_nos_pink'
        },
        ['nitrous_purple'] = {
            color = 'purple',
            label = 'Nitrous Purple',
            colorHex = '#8000FF',
            imageURL = 'nitrous_purple.png',
            prop = 'tuff_nos_purple'
        },
        ['nitrous_red'] = {
            color = 'red',
            label = 'Nitrous Red',
            colorHex = '#ff0a0a',
            imageURL = 'nitrous_red.png',
            prop = 'tuff_nos_red'
        },
        ['nitrous_teal'] = {
            color = 'teal',
            label = 'Nitrous Teal',
            colorHex = '#00FFCC',
            imageURL = 'nitrous_teal.png',
            prop = 'tuff_nos_teal'
        },
        ['nitrous_white'] = {
            color = 'white',
            label = 'Nitrous White',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_white.png',
            prop = 'tuff_nos_white'
        },
        ['nitrous_yellow'] = {
            color = 'yellow',
            label = 'Nitrous Yellow',
            colorHex = '#FFFF00',
            imageURL = 'nitrous_yellow.png',
            prop = 'tuff_nos_yellow'
        },
        ['nitrous_orange'] = {
            color = 'orange',
            label = 'Nitrous Orange',
            colorHex = '#FF6600',
            imageURL = 'nitrous_orange.png',
            prop = 'tuff_nos_orange'
        },
        ['nitrous_custom'] = {
            color = 'custom', -- Allow Custom Color picker.
            label = 'Nitrous Custom',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_custom.png',
            prop = 'tuff_nos_custom'
        },
        -- Nitrous Gradient Colors
        ['nitrous_blue_cyan_purple'] = {
            color = 'blue_cyan_purple',
            label = 'Nitrous Blue Cyan Purple',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_blue_cyan_purple.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_rainbow'] = {
            color = 'rainbow',
            label = 'Nitrous Rainbow',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_rainbow.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_orange_yellow_green'] = {
            color = 'orange_yellow_green',
            label = 'Nitrous Orange Yellow Green',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_orange_yellow_green.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_purple_pink_blue'] = {
            color = 'purple_pink_blue',
            label = 'Nitrous Purple Pink Blue',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_purple_pink_blue.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_red_green_blue'] = {
            color = 'red_green_blue',
            label = 'Nitrous Red Green Blue',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_red_green_blue.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_red_orange_yellow'] = {
            color = 'red_orange_yellow',
            label = 'Nitrous Red Orange Yellow',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_red_orange_yellow.png',
            prop = 'tuff_nos_custom'
        },
        ['nitrous_yellow_green_cyan'] = {
            color = 'yellow_green_cyan',
            label = 'Nitrous Yellow Green Cyan',
            colorHex = '#FFFFFF',
            imageURL = 'nitrous_yellow_green_cyan.png',
            prop = 'tuff_nos_custom'
        },
    },
    Levels = {
        [1] = { powermultiplier = 1.5, drainRate = 0.5, flameSize = 0.5, trailSize = 0.2, maxSpeed = 300 },
        [2] = { powermultiplier = 2.5, drainRate = 0.8, flameSize = 0.8, trailSize = 0.2, maxSpeed = 400 },
        [3] = { powermultiplier = 4.5, drainRate = 1.0, flameSize = 1.0, trailSize = 0.3, maxSpeed = 450 },
        [4] = { powermultiplier = 6.0, drainRate = 1.2, flameSize = 1.2, trailSize = 0.3, maxSpeed = 500 },
    },

    NitrousUsageCooldown = 5, -- Seconds before nitrous can be used again (set false to disable)

    BoostEffect = {
        type = 'handling',         -- handling / native
        fallbackType = 'handling', -- Used if an unknown boost type is set

        -- Keep boost settings grouped by type so customers only edit one small section.
        Types = {
            handling = {
                topSpeedRefresh = 1.0,

                -- Add more handling float values by copying one of the blocks below.
                -- class: GTA handling class, usually CHandlingData
                -- field: handling float field name used by GetVehicleHandlingFloat / SetVehicleHandlingFloat
                -- mode: multiply / add / set
                -- value: number applied using the selected mode
                -- scaleWithLevel: true = also scales with Shared.Nitrous.Levels[x].powermultiplier
                modifiers = {
                    {
                        class = 'CHandlingData',
                        field = 'fInitialDriveForce',
                        mode = 'multiply',
                        value = 1.0,
                        scaleWithLevel = true,
                    },
                    -- Example:
                    -- {
                    --     class = 'CHandlingData',
                    --     field = 'fDriveInertia',
                    --     mode = 'multiply',
                    --     value = 1.05,
                    --     scaleWithLevel = false,
                    -- },
                }
            },

            native = {
                accelerationBoost = 3.0,
                nitroBoost = 5.0,
                scaleWithLevel = true,
            },
        },

        -- Legacy fallback values for older configs. Safe to leave as-is.
        NitroBoost = 5.0,
        AccelerationBoost = 3.0,
    },
    DamageOnUsage = {                      -- Server owners can edit CustomHandler below for external damage scripts
        Enabled = true,
        Threshold = 8,                     -- Seconds of continuous use before damage starts (keep <= trigger duration when using press mode)
        StopUsageWhenDamageApplied = true, -- Stop nitrous when damage is applied
        Cooldown = 5,                      -- Seconds before nitrous can be used again (set false to disable)
        Damage = 20.0,                     -- Engine health damage per second
        UseCustomHandler = true,           -- true = use CustomHandler below, false = use built-in/backend damage
        CustomHandler = function(veh, damageAmount, context)
            -- Replace this with your own export/event if another vehicle damage script should handle nitrous damage.
            -- Return the new engine health if your handler changes GTA engine health directly.
            if not veh or not DoesEntityExist(veh) then return nil end

            local currentHealth = GetVehicleEngineHealth(veh)
            local newHealth = currentHealth - (tonumber(damageAmount) or 0.0)
            SetVehicleEngineHealth(veh, newHealth)

            return newHealth
        end,
    }
}
-- ================================================================
-- EXHAUST SYSTEM
-- ================================================================
Shared.Exhaust = {
    -- When true: use hex color values instead of streamed particle files for exhaust flames/backfire.
    UseHexColors = false,
    RequireItem = false,        -- If true, exhaust colors require items; if false, mechanic can install any color
    ReturnItemOnRemoval = true, -- Return installed item on removal (if RequireItem = true)
    ExhaustSizeFromEngineLevel = {
        [1] = 0.5,
        [2] = 0.8,
        [3] = 1.0,
        [4] = 1.2,
    },
    Colors = {
        ['exhaust_blue'] = {               -- itemname
            color = 'blue',                -- color
            label = 'Exhaust Blue',
            colorHex = '#0084ff',          -- hex color for UI
            imageURL = 'exhaust_blue.png', -- image for UI
            size = 1.0,                    -- ptfx size
            prop = 'tuff_exhaust_blue'
        },
        ['exhaust_cyan'] = {
            color = 'cyan',
            label = 'Exhaust Cyan',
            colorHex = '#00fbff',
            imageURL = 'exhaust_cyan.png',
            size = 1.0,
            prop = 'tuff_exhaust_cyan'
        },
        ['exhaust_default'] = {
            color = 'default',
            label = 'Exhaust Default',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_default.png',
            size = 1.0,
            prop = 'tuff_exhaust_default'
        },
        ['exhaust_green'] = {
            color = 'green',
            label = 'Exhaust Green',
            colorHex = '#00FF00',
            imageURL = 'exhaust_green.png',
            size = 1.0,
            prop = 'tuff_exhaust_green'
        },
        ['exhaust_mix1'] = {
            color = 'mix1',
            label = 'Exhaust Mix 1',
            colorHex = '#FF7A00',
            imageURL = 'exhaust_mix1.png',
            size = 1.0,
            prop = 'tuff_exhaust_default'
        },
        ['exhaust_mix2'] = {
            color = 'mix2',
            label = 'Exhaust Mix 2',
            colorHex = '#8A00FF',
            imageURL = 'exhaust_mix2.png',
            size = 1.0,
            prop = 'tuff_exhaust_default'
        },
        ['exhaust_pink'] = {
            color = 'pink',
            label = 'Exhaust Pink',
            colorHex = '#FF00FF',
            imageURL = 'exhaust_pink.png',
            size = 1.0,
            prop = 'tuff_exhaust_pink'
        },
        ['exhaust_purple'] = {
            color = 'purple',
            label = 'Exhaust Purple',
            colorHex = '#8000FF',
            imageURL = 'exhaust_purple.png',
            size = 1.0,
            prop = 'tuff_exhaust_purple'
        },
        ['exhaust_red'] = {
            color = 'red',
            label = 'Exhaust Red',
            colorHex = '#ff0a0a',
            imageURL = 'exhaust_red.png',
            size = 1.0,
            prop = 'tuff_exhaust_red'
        },
        ['exhaust_teal'] = {
            color = 'teal',
            label = 'Exhaust Teal',
            colorHex = '#00FFCC',
            imageURL = 'exhaust_teal.png',
            size = 1.0,
            prop = 'tuff_exhaust_teal'
        },
        ['exhaust_white'] = {
            color = 'white',
            label = 'Exhaust White',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_white.png',
            size = 1.0,
            prop = 'tuff_exhaust_white'
        },
        ['exhaust_yellow'] = {
            color = 'yellow',
            label = 'Exhaust Yellow',
            colorHex = '#FFFF00',
            imageURL = 'exhaust_yellow.png',
            size = 1.0,
            prop = 'tuff_exhaust_yellow'
        },
        ['exhaust_custom'] = {
            color = 'custom', -- Allow Custom Color picker.
            label = 'Exhaust Custom',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_custom.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_orange'] = {
            color = 'orange',
            label = 'Exhaust Orange',
            colorHex = '#FF6600',
            imageURL = 'exhaust_orange.png',
            size = 1.0,
            prop = 'tuff_exhaust_orange'
        },
        -- Exhaust Gradient Colors
        ['exhaust_blue_cyan_purple'] = {
            color = 'blue_cyan_purple',
            label = 'Exhaust Blue Cyan Purple',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_blue_cyan_purple.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_rainbow'] = {
            color = 'rainbow',
            label = 'Exhaust Rainbow',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_rainbow.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_orange_yellow_green'] = {
            color = 'orange_yellow_green',
            label = 'Exhaust Orange Yellow Green',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_orange_yellow_green.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_purple_pink_blue'] = {
            color = 'purple_pink_blue',
            label = 'Exhaust Purple Pink Blue',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_purple_pink_blue.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_red_green_blue'] = {
            color = 'red_green_blue',
            label = 'Exhaust Red Green Blue',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_red_green_blue.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_red_orange_yellow'] = {
            color = 'red_orange_yellow',
            label = 'Exhaust Red Orange Yellow',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_red_orange_yellow.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
        ['exhaust_yellow_green_cyan'] = {
            color = 'yellow_green_cyan',
            label = 'Exhaust Yellow Green Cyan',
            colorHex = '#FFFFFF',
            imageURL = 'exhaust_yellow_green_cyan.png',
            size = 1.0,
            prop = 'tuff_exhaust_custom'
        },
    },
    DisableDefaultExhaustPop = true, -- Disable default exhaust pop when backfire system is installed
    SoundEffects = {
        EnableCustomSound = true,    -- Enable custom sound effects
        Models = {                   -- specific vehicle sounds by model
            [`adder`] = 'antilag01',
            [`t20`] = 'antilag02',
            [`sandking`] = 'antilag03',
            [`zentorno`] = 'antilag03',
            -- Add other specific vehicle sounds here
        },
        Classes = {             -- specific vehicle sounds by class
            [1] = "antilag01",  -- Sedans
            [0] = "antilag01",  -- Compacts
            [2] = "antilag01",  -- SUVs
            [3] = "antilag01",  -- Coupes
            [5] = "antilag01",  -- Sports Classics
            [4] = "antilag01",  -- Muscle
            [6] = "antilag01",  -- Sports
            [7] = "antilag01",  -- Super
            [9] = "antilag01",  -- Off-road
            [12] = "antilag01", -- Vans
            [17] = "antilag01", -- Service
            [18] = "antilag01", -- Emergency
            [19] = "antilag01", -- Military
            [20] = "antilag01", -- Commercial
        }
        --[[ Sound sets:
        antilag01
        antilag02
        antilag03
        antilag04
        ]]
    }
}

-- ================================================================
-- ANTILAG / 2-STEP
-- ================================================================
Shared.Antilag2Step = {
    -- General feature gate (allows install/use in UI & client logic)
    Enabled = true,
    RequireTurboOnCar = false, -- require turbo mod on the car to install antilag/2-step
    -- Default exhaust pop color when no custom exhaust is installed
    -- Must match a valid exhaust color key (see Shared.Exhaust.Colors[*].color)
    DefaultExhaustPop = 'default',
    -- Reasonable defaults for UI-less operation; UI can override these per-vehicle
    FlamesWithDecelPops = true, -- whether to show flames when decel popping
    Defaults = {
        antiLagMs = 250,        -- cadence for anti-lag pulses (keep >= server replicate cap)
        stepIntervalMs = 260,   -- cadence for 2-step pops (keep >= server replicate cap)
        stepPercent = 55,       -- target RPM % during 2-step
        stepCutPercent = 50,    -- percent of period spent cutting power
        decelMinSpeed = 5.0,    -- minimum vehicle speed (m/s) required to trigger decel pops
    }
}

-- ================================================================
-- COLOR CUSTOMIZATION (COMMAND/ITEM ONLY)
-- ================================================================
Shared.ColorCustomization = { -- Recolor exhaust/nitrous without opening the main UI
    Nitrous = {
        Restrictions = {
            OnlyOwner = false,                   -- if true, it skips all the other restrictions
            CustomRestriction = function(source) -- Custom function to restrict who can install things, -- Server side
                return true
            end,
            JobRequired = false,
            Jobs = {
                ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
                ["police"] = true           -- All grades allowed
            },
            ItemRequired = false,
            Items = { "screwdriver" }, -- Items required to install
        },
        Command = {
            Enabled = true,
            CommandName = 'changeNitrousColor'
        },
        ItemUsage = {
            Enabled = false,
            ItemName = 'custom_nitrous_color_item'
        }
    },
    Exhaust = {
        Restrictions = {
            OnlyOwner = false,                   -- if true, it skips all the other restrictions
            CustomRestriction = function(source) -- Custom function to restrict who can install things, -- Server side
                return true
            end,
            JobRequired = false,
            Jobs = {
                ["mechanic"] = { 1, 2, 3 }, -- Specific grades allowed
                ["police"] = true           -- All grades allowed
            },
            ItemRequired = false,
            Items = { "screwdriver" }, -- Items required to install
        },
        Command = {
            Enabled = true,
            CommandName = 'changeExhaustColor'
        },
        ItemUsage = {
            Enabled = false,
            ItemName = 'custom_exhaust_color_item'
        }
    }
}

-- ================================================================
-- CUSTOM EXHAUST LOCATION SYSTEM
-- ================================================================

Shared.CustomExhaustLocation = {
    Enabled = true,                      -- Enable/Disable Custom Exhaust Location system
    CommandName = 'set_exhaust',         -- Command to set custom exhaust location
    ImportExport = {
        Enabled = true,                  -- Enable/Disable Import/Export system for custom exhaust locations
        ExportCommand = 'exportexhaust', -- Command to export current custom exhaust location
        ImportCommand = 'importexhaust', -- Command to import a custom exhaust location
    },
    Permissions = {
        OnlyAdmins = true, -- Only allow admins to use this command
        JobRequired = false,
        Jobs = {
            ["mechanic"] = { 1, 2, 3 },      -- Specific grades allowed
            ["police"] = true                -- All grades allowed
        },
        CustomRestriction = function(source) -- Custom function to restrict who can set custom exhaust location
            return true
        end,
    }
}

-- Flame Locations for nitrous and exhaust
-- ================================================================
-- DEFAULT FX LOCATIONS
-- ================================================================
Shared.FlameLocations = {
    "exhaust",
    "exhaust_2",
    "exhaust_3",
    "exhaust_4",
    "exhaust_5",
    "exhaust_6",
    "exhaust_7",
    "exhaust_8",
    "exhaust_9",
    "exhaust_10",
    "exhaust_11",
    "exhaust_12",
    "exhaust_13",
    "exhaust_14",
    "exhaust_15",
    "exhaust_16",
}

Shared.TrailLocations = {
    'taillight_l',
    'taillight_r'
}
