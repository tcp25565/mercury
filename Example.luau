--[[
    Mercury example
    ---------------
    Replace the URL below with wherever you host Mercury.luau, or simply
    load Mercury in your executor first and delete the loadstring line.

    Controls:
      RightShift ............ show / hide the menu
      Left click a module ... toggle it on or off
      Right click a module .. open its settings
      Search + Tab .......... open the first match's settings
      Click outside ......... close settings / return to the menu
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tcp25565/mercury/main/Mercury.luau"))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- Small helper used by a few example callbacks.
local function getHumanoid()
    local character = Players.LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

--==========================================================================
-- Combat
--==========================================================================

local Combat = Library:AddWindow("Combat")

local AimBot = Combat:AddModule("AimBot", {
    Tooltip = "Smoothly aims at a target while the aim key is held",
    Callback = function(enabled)
        Library:Notify("AimBot " .. (enabled and "enabled" or "disabled"), 2.5)
    end,
})

AimBot:AddToggle("TeamCheck", {
    Text = "Team check",
    Default = true,
})

AimBot:AddSlider("FOV", {
    Text = "FOV",
    Min = 0,
    Max = 360,
    Default = 90,
    Rounding = 0,
    Suffix = "°",
    Callback = function(value)
        -- Frame your aimbot's search cone around the camera using this value.
    end,
})

AimBot:AddSlider("Smoothness", {
    Text = "Smoothness",
    Min = 1,
    Max = 20,
    Default = 5,
    Rounding = 1,
    Suffix = "x",
})

AimBot:AddDropdown("HitPart", {
    Text = "Hit part",
    Values = { "Head", "Torso", "Nearest" },
    Default = "Head",
})

AimBot:AddDropdown("Priority", {
    Text = "Target priority",
    Values = { "Distance", "Health", "FOV" },
    Multi = true,
    Default = { Distance = true },
})

AimBot:AddKeyPicker("AimKey", {
    Text = "Aim key",
    Default = "E",
    Mode = "Hold",          -- Toggle / Hold / Press (right-click the key to change)
})

AimBot:AddColorPicker("FOVColor", {
    Text = "FOV color",
    Default = Color3.fromRGB(255, 77, 109),
})

local SilentAim = Combat:AddModule("SilentAim", {
    Tooltip = "Redirects your shots toward the selected target",
})

SilentAim:AddToggle("WallCheck", { Text = "Wall check", Default = true })
SilentAim:AddSlider("HitChance", {
    Text = "Hit chance",
    Min = 0,
    Max = 100,
    Default = 100,
    Rounding = 0,
    Suffix = "%",
})
SilentAim:AddDropdown("Resolver", {
    Text = "Resolver",
    Values = { "None", "Basic", "Advanced" },
    Default = "Basic",
})

--==========================================================================
-- Visuals
--==========================================================================

local Visuals = Library:AddWindow("Visuals")

local ESP = Visuals:AddModule("ESP", {
    Tooltip = "Draws boxes, names and health bars around players",
})

ESP:AddToggle("Boxes", { Text = "Boxes", Default = true })
ESP:AddToggle("Names", { Text = "Names", Default = true })
ESP:AddToggle("Health", { Text = "Health bars", Default = false })
ESP:AddDropdown("Filter", {
    Text = "Filter",
    Values = { "All", "Enemies", "Team" },
    Default = "All",
})
ESP:AddSlider("MaxDistance", {
    Text = "Max distance",
    Min = 50,
    Max = 2000,
    Default = 500,
    Rounding = 0,
    Suffix = " studs",
})
ESP:AddColorPicker("BoxColor", {
    Text = "Box color",
    Default = Color3.fromRGB(255, 77, 109),
})
ESP:AddColorPicker("NameColor", {
    Text = "Name color",
    Default = Color3.fromRGB(255, 255, 255),
})

local Fullbright = Visuals:AddModule("Fullbright", {
    Tooltip = "Raises the world's brightness",
    Callback = function(enabled)
        if enabled then
            Lighting.Brightness = Library.Options.Fullbright.Brightness.Value
        else
            Lighting.Brightness = 2
        end
    end,
})

Fullbright:AddSlider("Brightness", {
    Text = "Brightness",
    Min = 1,
    Max = 5,
    Default = 2,
    Rounding = 1,
    Callback = function(value)
        if Library.Toggles.Fullbright.Value then
            Lighting.Brightness = value
        end
    end,
})

--==========================================================================
-- Player
--==========================================================================

local PlayerWindow = Library:AddWindow("Player")

local Movement = PlayerWindow:AddModule("Movement", {
    Tooltip = "Local movement tweaks",
})

Movement:AddSlider("WalkSpeed", {
    Text = "Walk speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 0,
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

Movement:AddSlider("JumpPower", {
    Text = "Jump power",
    Min = 50,
    Max = 250,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.JumpPower = value
            humanoid.UseJumpPower = true
        end
    end,
})

Movement:AddButton("Reset speeds", function()
    Library.Options.Movement.WalkSpeed:SetValue(16)
    Library.Options.Movement.JumpPower:SetValue(50)
    Library:Notify("Movement reset", 2)
end)

local Fly = PlayerWindow:AddModule("Fly", {
    Tooltip = "Example of a module with a key bind and sub-settings",
    Callback = function(enabled)
        Library:Notify("Fly " .. (enabled and "enabled" or "disabled"), 2)
    end,
})

Fly:AddKeyPicker("FlyKey", {
    Text = "Fly key",
    Default = "None",
    Mode = "Toggle",
})
Fly:AddSlider("FlySpeed", {
    Text = "Fly speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Rounding = 0,
})
Fly:AddToggle("FlyVertical", { Text = "Vertical flight", Default = true })

--==========================================================================
-- Misc
--==========================================================================

local Misc = Library:AddWindow("Misc")

local Utilities = Misc:AddModule("Utilities", {
    Tooltip = "Small quality-of-life actions",
})

Utilities:AddButton("Rejoin server", function()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
end)

Utilities:AddButton("Copy config path", function()
    local path = Library.SaveManager:GetSettingsPath()
    if setclipboard then
        setclipboard(path)
        Library:Notify("Copied: " .. path, 3)
    else
        Library:Notify(path, 4)
    end
end)

Utilities:AddLabel("Mercury v" .. tostring(Library.Version), {
    Size = 11,
})

Utilities:AddDivider()

Utilities:AddToggle("Debug", {
    Text = "Debug prints",
    Default = false,
    Callback = function(enabled)
        print("[example] debug:", enabled)
    end,
})

--==========================================================================
-- Programmatic access
--==========================================================================

-- Options are namespaced by module name. Reading and writing works at any time.
AimBot:AddButton("Log current settings", function()
    print("AimBot enabled:", Library.Toggles.AimBot.Value)
    print("FOV:", Library.Options.AimBot.FOV.Value)
    print("Hit part:", Library.Options.AimBot.HitPart.Value)
    print("Priority distance:", Library.Options.AimBot.Priority.Value.Distance == true)
end)

Library.Options.AimBot.FOV:OnChanged(function(value)
    -- Fires whenever the value changes, including loads from a config.
end)

-- Toggle the whole menu with a different key if you like (default is RightShift).
Library:SetToggleKey(Enum.KeyCode.RightShift)

-- Apply a built-in theme: Mercury, Lambda, Vape, Fatality, Jester, Mint,
-- Tokyo Night, Quartz, BBot or Ubuntu.
Library.ThemeManager:ApplyTheme("Mercury")

-- Load the config marked as autoload, if there is one. Call this after every
-- window and module has been created.
Library.SaveManager:LoadAutoloadConfig()

Library:Notify("Mercury loaded  •  RightShift to open  •  right-click a module for settings", 5)
