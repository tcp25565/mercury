# Mercury

A private, single-file Roblox GUI library with a Minecraft-client look (Lambda / Vape / Linoria inspired). It includes one draggable window per category, a top-center autocomplete search, per-module settings popouts, and built-in theme and config managers.

```
Mercury.luau     the whole library (drop this into your executor)
Example.luau     a complete example menu
```

## Loading

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tcp25565/mercury/main/Mercury.luau"))()
```

To test locally, load `Mercury.luau` however your executor loads local files, then keep the returned value:

```lua
local Library = loadstring(readfile("Mercury.luau"))()
```

Mercury automatically unloads a previous instance registered in `getgenv().Mercury` before building.

## Controls

| Input | Action |
| --- | --- |
| `RightShift` | Show / hide the menu |
| Left click a module | Toggle the module on / off |
| Right click a module | Open that module's settings |
| Type in search | Dim non-matching modules and show matches |
| `Tab` in search | Open the first match's settings |
| Arrow keys in search | Move the result selection |
| `Enter` in search | Open the selected result |
| Click outside settings | Close the popout and return to the menu |
| Right click a key button | Cycle its mode (`Toggle` → `Hold` → `Press`) |

The search bar and settings popout are not draggable. Windows are dragged by their title.

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tcp25565/mercury/main/Mercury.luau"))()

local Combat = Library:AddWindow("Combat")

local AimBot = Combat:AddModule("AimBot", {
    Tooltip = "Aims at the closest target",
    Callback = function(enabled)
        print("AimBot", enabled)
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
})

AimBot:AddKeyPicker("AimKey", {
    Text = "Aim key",
    Default = "E",
    Mode = "Hold",
})

-- Namespaced access. Every control is a live Option object.
print(Library.Toggles.AimBot.Value)          -- module enabled?
print(Library.Options.AimBot.FOV.Value)      -- current FOV

-- Call this after every window / module / option has been created.
Library.SaveManager:LoadAutoloadConfig()
```

## Windows

```lua
local Window = Library:AddWindow(name, {
    Width = 190, -- optional
})
```

Windows are placed left-to-right across the top and can be dragged by their title. `Window:SetPosition(x, y)` moves one programmatically.

A `Client` window is created automatically after your synchronous setup finishes (via `task.defer`), so it always appears last. It contains two built-in modules: `Theme` and `Configs`. Reserve the name `Client` for it.

```lua
Library:SetClientWindowVisible(false) -- hide just the Client window
Library.ClientWindow                   -- the window object (after it is built)
```

## Modules

```lua
local AimBot = Combat:AddModule(name, {
    Tooltip = "shown when hovering the row",
    Callback = function(enabled) end, -- module row toggled
    Default = false,                  -- start enabled
})
```

The module row itself is the toggle. There is no separate "Enabled" option.

- Module names are globally unique; adding a duplicate raises an error.
- Option ids only need to be unique inside their module.
- `Library.Toggles.<ModuleName>` is the toggle Option.
- `Default = true` sets the starting state without firing `Callback`; callbacks run on changes, including config loads. Apply any startup side effect yourself if you rely on a default-enabled module.
- Modules can be hidden from saving with `module.NoSave = true` (the built-in `Theme` and `Configs` modules use this).

## Controls

All controls return an `Option`. IDs must be unique per module.

### Toggle

```lua
local toggle = module:AddToggle("TeamCheck", {
    Text = "Team check",
    Default = false,
    Callback = function(value) end,
})
```

### Slider

```lua
module:AddSlider("FOV", {
    Text = "FOV",
    Min = 0,
    Max = 360,
    Default = 90,
    Rounding = 0,   -- decimal places
    Prefix = "",    -- optional
    Suffix = "°",   -- optional
    Callback = function(value) end,
})
```

### Dropdown

```lua
module:AddDropdown("HitPart", {
    Text = "Hit part",
    Values = { "Head", "Torso" },
    Default = "Head",
    Callback = function(value) end,
})

module:AddDropdown("Priority", {
    Text = "Priority",
    Values = { "Distance", "Health", "FOV" },
    Multi = true,
    Default = { Distance = true },
    Callback = function(value) --[[ value is a set: { Distance = true } ]] end,
})
```

`Option:SetValues(newValues)` replaces the item list and keeps the current value when it still exists.

### Input

```lua
module:AddInput("TargetName", {
    Text = "Target name",
    Placeholder = "username",
    Default = "",
    Callback = function(value) end,
})
```

The value updates when the text box loses focus.

### KeyPicker

```lua
local key = module:AddKeyPicker("AimKey", {
    Text = "Aim key",
    Default = "MB2",       -- any Enum.KeyCode name, or "MB2" / "MB3" / "None"
    Mode = "Hold",         -- Toggle / Hold / Press
    Callback = function(state) end,
    ModeChangedCallback = function(mode) end,
})
```

Click the key button and press a key (or mouse button) to bind it. Right click the button to cycle modes. `None` is the default so new keypickers never conflict with the menu key.

- `Toggle`: state flips on press.
- `Hold`: state is true while held.
- `Press`: click-style callback on press.
- `key.Value` is a string; `key:GetState()` returns whether it is currently active.
- `key:SetMode("Hold")` changes the mode programmatically.

### ColorPicker

```lua
module:AddColorPicker("BoxColor", {
    Text = "Box color",
    Default = Color3.fromRGB(255, 77, 109),
    Callback = function(color) end,
})
```

`option:SetValueRGB(r, g, b)` is a shortcut. Values are `Color3` objects; configs store them as hex strings.

### Button, Label, Divider

```lua
local button = module:AddButton("Rejoin", function() end)
button:SetText("Rejoining...")

local label = module:AddLabel("Some text", { Size = 11 })
label:SetText("Updated text")

module:AddDivider()
```

`AddButton` also accepts a config table: `AddButton({ Text = "Rejoin", Func = function() end })`.

## Options and the registry

Every control is a live `Option`:

```lua
local option = Library.Options.AimBot.FOV

option.Value = 120          -- same as option:SetValue(120)
print(option.Value)         -- or option:Get()
print(option.Type)          -- "Slider"
print(option.ID)            -- "FOV"
print(option.Module.Name)   -- "AimBot"

option:OnChanged(function(value) end)
option:OnClick(function(state) end) -- keypickers / toggles

Library.Toggles.AimBot.Value = true
```

Lookups:

```lua
local module = Library:GetModule("AimBot")
local option = Library:FindOption("AimBot", "FOV")
```

`Option:SetValue(value, silent)` skips change callbacks when `silent` is true. Config loading uses that internally.

## Search

The search bar is fixed at the top center. It matches module names and option labels/ids, dims everything that does not match, and lists:

- module results (`Module`)
- setting results (`Module · Setting`)

Opening a result whose type is a setting scrolls that module's popout to the setting. When a popout is open, the search bar and all windows are hidden; click outside to return.

## Notifications and visibility

```lua
Library:Notify("Loaded", 3) -- text, seconds (default 4)

Library:Show()
Library:Hide()
Library:Toggle()
Library:SetVisible(false)
```

Notifications stack at the bottom right and fade out.

## Keybinds

```lua
Library:SetToggleKey(Enum.KeyCode.RightShift)
-- or assign directly; the input handler reads it every press:
Library.ToggleKeybind = Enum.KeyCode.Insert
```

The toggle is handled through `UserInputService`, not `ContextActionService`, so reassigning `Library.ToggleKeybind` takes effect immediately.

While a keypicker is listening, the menu key is suppressed so you can bind it. The GUI toggle is also ignored while a text box has focus.

## ThemeManager

Built in, available as `Library.ThemeManager`. The UI lives in `Client → Theme`.

Built-in themes: **Mercury**, **Lambda**, **Vape**, **Fatality**, **Jester**, **Mint**, **Tokyo Night**, **Quartz**, **BBot**, **Ubuntu**.

```lua
Library.ThemeManager:ApplyTheme("Vape")
Library.ThemeManager:SaveCustomTheme("MyTheme")
Library.ThemeManager:ApplyTheme("MyTheme")
Library.ThemeManager:Delete("MyTheme")       -- built-ins cannot be deleted

Library.ThemeManager:SaveDefault("MyTheme")  -- remembered across executions
Library.ThemeManager:GetDefault()
Library.ThemeManager:LoadDefault()

Library.ThemeManager:GetAllThemeNames()
Library.ThemeManager:ReloadCustomThemes()
Library.ThemeManager:SetFolder("Mercury")    -- root folder; themes go in <root>/themes
```

Theme fields: `BackgroundColor`, `MainColor`, `AccentColor`, `OutlineColor`, `FontColor`. The client UI also exposes a rainbow accent toggle; theme settings are not written to configs.

Custom themes are JSON files under `Mercury/themes`. Without an executor file API, applying built-in themes still works; custom theme saving/deleting reports that file access is unavailable.

## SaveManager

Built in, available as `Library.SaveManager`. The UI lives in `Client → Configs`.

Saved values: module enabled states plus `Toggle`, `Slider`, `Dropdown` (single and multi), `Input`, `KeyPicker` (value and mode), and `ColorPicker` (hex). `Theme` and `Configs` are excluded via `NoSave`.

```lua
Library.SaveManager:Save("PvP")
Library.SaveManager:Load("PvP")
Library.SaveManager:Delete("PvP")
Library.SaveManager:RefreshConfigList()

local ok, json = Library.SaveManager:Export()
Library.SaveManager:Import(json)

Library.SaveManager:SaveAutoloadConfig("PvP")
Library.SaveManager:GetAutoloadConfig()      -- "PvP" or "none"
Library.SaveManager:LoadAutoloadConfig()     -- call after building the UI
Library.SaveManager:DeleteAutoLoadConfig()
```

Folders and exclusions:

```lua
Library.SaveManager:SetFolder("Mercury")     -- root
Library.SaveManager:SetSubFolder("PvP")      -- optional, inside settings
Library.SaveManager:GetSettingsPath()        -- Mercury/settings[...]

Library.SaveManager:SetIgnoreIndexes({ "AimBot.TeamCheck", "ESP" })
Library.SaveManager:ClearIgnoreIndexes()
Library.SaveManager:IgnoreThemeSettings()
Library.SaveManager:SetLoadingOrder(true)    -- apply modules first, then options
```

Configs are JSON files under `Mercury/settings`. The default autoload call looks like this:

```lua
-- build every window / module / option first
Library.SaveManager:LoadAutoloadConfig()
```

Without `writefile` / `readfile` / `isfolder` / `makefolder` / `listfiles`, the rest of the library works normally, but config and custom-theme file operations return `false, "executor has no file access"` and the UI shows a notification.

## Other API

```lua
Library.Version

Library:OnUnload(function() end)

Library:SetClientWindowVisible(false)
Library.ClientWindow

Library:Unload()                 -- restore PlayerList, disconnect signals, destroy GUIs
getgenv().Mercury                -- current instance
```

`Library:Unload()` is called automatically on re-execution. All connections are tracked, so unloading does not leave input handlers behind.

## Notes

- Window names and module names must be unique. `Client` is reserved for the built-in window; `Theme` and `Configs` are reserved module names.
- The built-in window is created with `task.defer`; anything created synchronously by your script (including a synchronous autoload) happens before it is built. Call `LoadAutoloadConfig` at the end of your setup.
- `SaveManager` restores module toggles before options when `SetLoadingOrder(true)` is used. The default is file order (modules are written first).
- The library uses `gethui()` when available, then `PlayerGui`, then `CoreGui`.
- Right-click on a module, not a setting, opens settings. To jump directly to a setting, search for it and press `Tab`.
