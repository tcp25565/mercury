local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer


if getgenv then
    local ok, env = pcall(getgenv)
    if ok and env and env.Mercury then
        pcall(function()
            env.Mercury:Unload()
        end)
    end
end



local function Create(className, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    return instance
end

local function LowerString(value)
    return string.lower(tostring(value or ""))
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 72),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Tween(instance, properties, time)
    TweenService:Create(
        instance,
        TweenInfo.new(time or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    ):Play()
end

local function SafeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[Mercury] " .. tostring(err))
    end
end

if ColorSequence == nil then
    ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
    ColorSequence = {}
    function ColorSequence.new(...)
        local args = {...}
        if type(args[1]) == "table" then
            return { Keypoints = args[1] }
        end
        return { Keypoints = { ColorSequenceKeypoint.new(0, args[1]), ColorSequenceKeypoint.new(1, args[2] or args[1]) } }
    end
end
if NumberSequence == nil then
    NumberSequence = { new = function(a, b) return { a, b } end }
end

local function ColorToHex(color)
    return string.format("%02x%02x%02x",
        math.floor((color.R or 0) * 255 + 0.5),
        math.floor((color.G or 0) * 255 + 0.5),
        math.floor((color.B or 0) * 255 + 0.5))
end

local function GetViewport()
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local Connections = {}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function NewScreenGui(name, order)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = order
    gui.Enabled = true

    local parent
    if gethui then
        local ok, result = pcall(gethui)
        if ok then
            parent = result
        end
    end
    if not parent and LocalPlayer then
        parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    if not parent then
        parent = game:GetService("CoreGui")
    end

    local ok = pcall(function()
        gui.Parent = parent
    end)
    if not ok or not gui.Parent then
        pcall(function()
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    return gui
end


local FileAPI = type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function"
    and type(isfolder) == "function"
    and type(makefolder) == "function"
    and type(listfiles) == "function"

local function EnsureFolder(path)
    if not FileAPI or type(path) ~= "string" or path == "" then
        return false
    end

    local prefix = path:match("^%a:[/\\]") or path:match("^[/\\]") or ""
    local rest = path:sub(#prefix + 1)
    local current = prefix
    for segment in string.gmatch(rest, "[^/\\]+") do
        if current == "" or current:match("[/\\]$") then
            current = current .. segment
        else
            current = current .. "/" .. segment
        end
        local ok = pcall(function()
            if not isfolder(current) then
                makefolder(current)
            end
        end)
        if not ok then
            return false
        end
    end
    return true
end

local function FileExists(path)
    if not FileAPI then
        return false
    end
    local ok, result = pcall(isfile, path)
    return ok and result == true
end

local function ReadFile(path)
    if not FileAPI then
        return nil
    end
    local ok, result = pcall(readfile, path)
    if ok and type(result) == "string" then
        return result
    end
    return nil
end

local function WriteFile(path, contents)
    if not FileAPI then
        return false
    end
    local ok = pcall(writefile, path, contents)
    return ok
end

local function DeleteFile(path)
    if not FileAPI or type(delfile) ~= "function" then
        return false
    end
    local ok = pcall(delfile, path)
    return ok
end

local function FileBaseName(path)
    return tostring(path):match("([^/\\]+)$") or tostring(path)
end

local ASSET_BASE = "https://raw.githubusercontent.com/tcp25565/mercury/main/assets/"

local function LoadAsset(file)
    if not FileAPI then
        return nil
    end

    local path = "Mercury/assets/" .. file
    if not FileExists(path) then
        local downloaded = false
        pcall(function()
            local body = game:HttpGet(ASSET_BASE .. file)
            if type(body) == "string" and body ~= "" then
                EnsureFolder("Mercury/assets")
                downloaded = WriteFile(path, body)
            end
        end)
        if not downloaded then
            return nil
        end
    end

    local getter = getcustomasset or getsynasset
    if type(getter) ~= "function" then
        return nil
    end

    local ok, asset = pcall(getter, path)
    if not ok or type(asset) ~= "string" or asset == "" then
        return nil
    end

    return asset
end

local function LoadUISound(name, volume)
    local asset = LoadAsset(name .. ".mp3")
    if not asset then
        return nil
    end

    local sound = Instance.new("Sound")
    sound.Name = "Mercury" .. name
    sound.SoundId = asset
    sound.Volume = volume
    sound.Parent = SoundService
    return sound
end

local Library = {}
Library.Version = "0.2.0"
Library.Options = {}
Library.Toggles = {}
Library.Windows = {}
Library.ModuleMap = {}
Library.Labels = {}
Library.Registry = {}
Library._connections = Connections
Library._modules = {}
Library._windows = {}
Library._allOptions = {}
Library._unloadCallbacks = {}
Library._visible = true
Library._query = ""
Library._searchResults = {}
Library._searchIndex = 0
Library._popoutModule = nil
Library._keyPicking = false
Library._activeKeyPicker = nil
Library._applyingTheme = false
Library._frontZ = 10
Library.ToggleKeybind = Enum.KeyCode.RightShift
Library._lastToggleInput = 0
Library._toggleActionBound = false


Library.BackgroundColor = Color3.fromRGB(10, 10, 13)
Library.MainColor = Color3.fromRGB(22, 22, 28)
Library.AccentColor = Color3.fromRGB(255, 45, 135)
Library.OutlineColor = Color3.fromRGB(58, 58, 70)
Library.FontColor = Color3.fromRGB(232, 232, 238)

Library._hoverSound = LoadUISound("hover", 0.35)
Library._clickSound = LoadUISound("click", 0.5)
Library._chevronImage = LoadAsset("chevron.png")

function Library:PlayHover()
    local sound = self._hoverSound
    if not sound then
        return
    end
    pcall(function()
        sound:Stop()
        sound:Play()
    end)
end

function Library:PlayClick()
    local sound = self._clickSound
    if not sound then
        return
    end
    pcall(function()
        sound:Stop()
        sound:Play()
    end)
end

function Library:GetDarkerColor(color)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, v / 1.5)
end

function Library:GetRowColor()
    return self.MainColor:Lerp(Color3.new(1, 1, 1), 0.035)
end

function Library:GetRowHoverColor()
    return self.MainColor:Lerp(Color3.new(1, 1, 1), 0.10)
end

function Library:GetSubTextColor()
    return self.FontColor:Lerp(self.BackgroundColor, 0.42)
end

function Library:GetDimColor()
    return self.FontColor:Lerp(self.BackgroundColor, 0.62)
end

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:Bind(instance, properties)
    table.insert(self.Registry, {
        Instance = instance,
        Properties = properties,
    })
end

function Library:ApplyRegistry()
    for index = #self.Registry, 1, -1 do
        local entry = self.Registry[index]
        local instance = entry.Instance
        if not instance or instance.Parent == nil then
            table.remove(self.Registry, index)
        else
            for property, source in pairs(entry.Properties) do
                local ok, value = pcall(function()
                    if type(source) == "function" then
                        return source()
                    end
                    return self[source]
                end)
                if ok and value ~= nil then
                    pcall(function()
                        instance[property] = value
                    end)
                end
            end
        end
    end
end

function Library:OnUnload(callback)
    table.insert(self._unloadCallbacks, callback)
end

function Library:FindOption(moduleName, id)
    local namespace = self.Options[LowerString(moduleName)]
    return namespace and namespace[LowerString(id)] or nil
end

function Library:GetModule(name)
    return self.ModuleMap[LowerString(name)]
end

function Library:AddToRegistry(instance, properties)
    return self:Bind(instance, properties)
end



local Option = {}

Option.__index = function(self, key)
    if key == "Value" then
        return rawget(self, "_value")
    end
    return Option[key]
end

Option.__newindex = function(self, key, value)
    if key == "Value" then
        Option.SetValue(self, value)
    else
        rawset(self, key, value)
    end
end

function Option.new(kind, module, id, config)
    local self = setmetatable({}, Option)
    self.Type = kind
    self.Module = module
    self.ID = id
    self.Config = config or {}
    self._value = self.Config.Default
    self._listeners = {}
    self._hooks = {}
    self._clickListeners = {}
    self.State = false
    return self
end

function Option:_AddRender(render)
    table.insert(self._hooks, render)
    local ok, err = pcall(render)
    if not ok then
        warn("[Mercury] render error: " .. tostring(err))
    end
end

function Option:_Refresh()
    for _, render in ipairs(self._hooks) do
        local ok, err = pcall(render)
        if not ok then
            warn("[Mercury] render error: " .. tostring(err))
        end
    end
end

function Option:Get()
    return rawget(self, "_value")
end

function Option:SetValue(value, silent)
    if self.Type == "Slider" then
        local config = self.Config
        local min = config.Min or 0
        local max = config.Max or 100
        value = math.clamp(tonumber(value) or min, min, max)
        local decimals = math.max(0, math.floor(config.Rounding or 0))
        local multiplier = 10 ^ decimals
        value = math.floor(value * multiplier + 0.5) / multiplier
    elseif self.Type == "Input" then
        value = value == nil and "" or tostring(value)
    elseif self.Type == "Toggle" then
        value = value == true
    elseif self.Type == "KeyPicker" then
        if typeof(value) == "EnumItem" then
            value = value.Name
        end
    elseif self.Type == "ColorPicker" then
        if type(value) == "string" then
            local ok, parsed = pcall(Color3.fromHex, value)
            if ok then
                value = parsed
            end
        end
        if typeof(value) ~= "Color3" then
            return self
        end
    elseif self.Type == "Dropdown" and not self.Multi then
        if type(value) == "number" and self.Config.Values then
            value = self.Config.Values[value] or value
        end
    end

    local old = rawget(self, "_value")
    if old == value then
        return self
    end
    rawset(self, "_value", value)

    for _, render in ipairs(self._hooks) do
        local ok, err = pcall(render)
        if not ok then
            warn("[Mercury] render error: " .. tostring(err))
        end
    end

    if not silent then
        for _, listener in ipairs(self._listeners) do
            task.spawn(listener, value)
        end

        if self.Type == "KeyPicker" then
            if type(self.Config.ChangedCallback) == "function" then
                task.spawn(SafeCallback, self.Config.ChangedCallback, value)
            end
        elseif type(self.Config.Callback) == "function" then
            task.spawn(SafeCallback, self.Config.Callback, value)
        end
    end

    return self
end

function Option:SetValueRGB(color)
    return self:SetValue(color)
end

function Option:SetValues(values)
    if self._setValues then
        self._setValues(values)
    end
    return self
end

function Option:SetMode(mode)
    if self.Mode == mode then
        return self
    end
    self.Mode = mode
    for _, render in ipairs(self._hooks) do
        pcall(render)
    end
    if type(self.Config.ModeChangedCallback) == "function" then
        task.spawn(SafeCallback, self.Config.ModeChangedCallback, mode)
    end
    return self
end

function Option:OnChanged(callback)
    if type(callback) == "function" then
        table.insert(self._listeners, callback)
    end
    return self
end

function Option:OnClick(callback)
    if type(callback) == "function" then
        table.insert(self._clickListeners, callback)
    end
    return self
end

function Option:GetState()
    return self.State == true
end

function Option:_FireClick(state)
    for _, listener in ipairs(self._clickListeners) do
        task.spawn(SafeCallback, listener, state)
    end
    if type(self.Config.Callback) == "function" then
        task.spawn(SafeCallback, self.Config.Callback, state)
    end
end

function Option:_SetState(state)
    self.State = state == true
    self:_FireClick(self.State)
end



local windowsGui = NewScreenGui("MercuryWindows", 100000)
local searchGui = NewScreenGui("MercurySearch", 100010)
local tooltipGui = NewScreenGui("MercuryTooltip", 100020)
local popoutGui = NewScreenGui("MercuryPopout", 100030)
local notifyGui = NewScreenGui("MercuryNotify", 100040)

popoutGui.Enabled = false

local windowsHolder = Create("Frame", {
    Name = "Windows",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = windowsGui,
})


local hiddenHolder = Create("Frame", {
    Name = "Hidden",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = popoutGui,
})



local searchBar = Create("Frame", {
    Name = "SearchBar",
    Size = UDim2.fromOffset(340, 36),
    Position = UDim2.new(0.5, 0, 0, 12),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = Library.BackgroundColor,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Parent = searchGui,
})
local searchStroke = Stroke(searchBar, Library.OutlineColor, 1, 0.35)
Library:Bind(searchBar, { BackgroundColor3 = "BackgroundColor" })
Library:Bind(searchStroke, { Color = "OutlineColor" })

local searchPrompt = Create("TextLabel", {
    Size = UDim2.fromOffset(22, 20),
    Position = UDim2.new(0, 11, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = ">_",
    TextSize = 14,
    TextColor3 = Library.AccentColor,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = searchBar,
})
Library:Bind(searchPrompt, { TextColor3 = "AccentColor" })

local searchBox = Create("TextBox", {
    Name = "Input",
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.fromOffset(32, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "",
    TextSize = 14,
    TextColor3 = Library.FontColor,
    PlaceholderText = "search modules...",
    PlaceholderColor3 = Library:GetDimColor(),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ClearTextOnFocus = false,
    Parent = searchBar,
})
Library:Bind(searchBox, {
    TextColor3 = "FontColor",
    PlaceholderColor3 = function()
        return Library:GetDimColor()
    end,
})

local searchIcon = Create("Frame", {
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.new(1, -26, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    Parent = searchBar,
})
local searchRing = Create("Frame", {
    Size = UDim2.fromOffset(9, 9),
    BackgroundTransparency = 1,
    Parent = searchIcon,
})
local searchRingStroke = Stroke(searchRing, Library:GetSubTextColor(), 1.5, 0.1)
local searchHandle = Create("Frame", {
    Size = UDim2.fromOffset(2, 6),
    Position = UDim2.fromOffset(8, 8),
    Rotation = 45,
    BackgroundColor3 = Library:GetSubTextColor(),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Parent = searchIcon,
})
Library:Bind(searchRingStroke, {
    Color = function()
        return Library:GetSubTextColor()
    end,
})
Library:Bind(searchHandle, {
    BackgroundColor3 = function()
        return Library:GetSubTextColor()
    end,
})

local resultsFrame = Create("Frame", {
    Name = "Results",
    Size = UDim2.fromOffset(340, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.new(0.5, 0, 0, 54),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = Library.BackgroundColor,
    BackgroundTransparency = 0.02,
    BorderSizePixel = 0,
    Visible = false,
    Parent = searchGui,
})
local resultsStroke = Stroke(resultsFrame, Library.OutlineColor, 1, 0.35)
Library:Bind(resultsFrame, { BackgroundColor3 = "BackgroundColor" })
Library:Bind(resultsStroke, { Color = "OutlineColor" })

local resultsList = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Parent = resultsFrame,
})
Create("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    Parent = resultsList,
})
Create("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = resultsList,
})



local tooltipFrame = Create("Frame", {
    Name = "Tooltip",
    Size = UDim2.fromOffset(0, 0),
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundColor3 = Library.BackgroundColor,
    BackgroundTransparency = 0.02,
    BorderSizePixel = 0,
    Visible = false,
    Parent = tooltipGui,
})
local tooltipStroke = Stroke(tooltipFrame, Library.OutlineColor, 1, 0.25)
Library:Bind(tooltipFrame, { BackgroundColor3 = "BackgroundColor" })
Library:Bind(tooltipStroke, { Color = "OutlineColor" })
Create("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = tooltipFrame,
})
local tooltipLabel = Create("TextLabel", {
    Size = UDim2.fromOffset(220, 0),
    Position = UDim2.fromOffset(8, 6),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "",
    TextSize = 13,
    TextColor3 = Library.FontColor,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = tooltipFrame,
})
Library:Bind(tooltipLabel, { TextColor3 = "FontColor" })



local popoutGuiFrame = Create("Frame", {
    Name = "Popout",
    Size = UDim2.fromOffset(280, 420),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Library.BackgroundColor,
    BackgroundTransparency = 0.02,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = popoutGui,
})
local popoutStroke = Stroke(popoutGuiFrame, Library.AccentColor, 1, 0.55)
Library:Bind(popoutGuiFrame, { BackgroundColor3 = "BackgroundColor" })
Library:Bind(popoutStroke, { Color = "AccentColor" })

local popoutCurtain = Create("TextButton", {
    Name = "Curtain",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 1,
    Parent = popoutGui,
})

local popoutTitle = Create("TextLabel", {
    Size = UDim2.new(1, -130, 0, 22),
    Position = UDim2.fromOffset(10, 10),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "module",
    TextSize = 16,
    TextColor3 = Library.FontColor,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = popoutGuiFrame,
})
Library:Bind(popoutTitle, { TextColor3 = "FontColor" })

local popoutSub = Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 15),
    Position = UDim2.fromOffset(10, 33),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "",
    TextSize = 11,
    TextColor3 = Library:GetSubTextColor(),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = popoutGuiFrame,
})
Library:Bind(popoutSub, {
    TextColor3 = function()
        return Library:GetSubTextColor()
    end,
})

local popoutHint = Create("TextLabel", {
    Size = UDim2.fromOffset(110, 14),
    Position = UDim2.new(1, -10, 0, 13),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "click outside to close",
    TextSize = 10,
    TextColor3 = Library:GetDimColor(),
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = popoutGuiFrame,
})
Library:Bind(popoutHint, {
    TextColor3 = function()
        return Library:GetDimColor()
    end,
})

local popoutScroll = Create("ScrollingFrame", {
    Name = "Scroll",
    Size = UDim2.new(1, -20, 0, 350),
    Position = UDim2.fromOffset(10, 54),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Library.AccentColor,
    ScrollBarImageTransparency = 0.45,
    ClipsDescendants = true,
    Parent = popoutGuiFrame,
})
Library:Bind(popoutScroll, { ScrollBarImageColor3 = "AccentColor" })
Create("UIPadding", {
    PaddingRight = UDim.new(0, 4),
    Parent = popoutScroll,
})

local popoutEmpty = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "this module has no settings.",
    TextSize = 13,
    TextColor3 = Library:GetDimColor(),
    Visible = false,
    Parent = popoutScroll,
})
Library:Bind(popoutEmpty, {
    TextColor3 = function()
        return Library:GetDimColor()
    end,
})

Connect(popoutCurtain.MouseButton1Click, function()
    Library:PlayClick()
    Library:ClosePopout()
end)



local colorPickerGui = NewScreenGui("MercuryColorPicker", 100040)
local colorPickerFrame = Create("Frame", {
    Name = "ColorPicker",
    Size = UDim2.fromOffset(180, 208),
    BackgroundColor3 = Library.BackgroundColor,
    BorderSizePixel = 0,
    Visible = false,
    Parent = colorPickerGui,
})
local colorPickerStroke = Stroke(colorPickerFrame, Library.OutlineColor, 1, 0.35)
Library:Bind(colorPickerFrame, { BackgroundColor3 = "BackgroundColor" })
Library:Bind(colorPickerStroke, { Color = "OutlineColor" })
Create("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    Parent = colorPickerFrame,
})

local colorPickerTitle = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Library.AccentColor,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    Text = "color",
    TextSize = 13,
    TextColor3 = Color3.new(1, 1, 1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = colorPickerFrame,
})
Library:Bind(colorPickerTitle, { BackgroundColor3 = "AccentColor" })
Create("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    Parent = colorPickerTitle,
})
local cpSvSize = 124
local cpSvFrame = Create("Frame", {
    Size = UDim2.fromOffset(cpSvSize, cpSvSize),
    Position = UDim2.fromOffset(6, 24),
    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
    BorderSizePixel = 0,
    Active = true,
    Parent = colorPickerFrame,
})
local cpSvSat = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    Active = false,
    Parent = cpSvFrame,
})
Create("UIGradient", {
    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
    Transparency = NumberSequence.new(0, 1),
    Parent = cpSvSat,
})
local cpSvVal = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BorderSizePixel = 0,
    Active = false,
    Parent = cpSvFrame,
})
Create("UIGradient", {
    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
    Transparency = NumberSequence.new(1, 0),
    Rotation = 90,
    Parent = cpSvVal,
})
local cpSvIndicator = Create("Frame", {
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 1,
    BorderColor3 = Color3.new(0, 0, 0),
    Active = false,
    Parent = cpSvFrame,
})

local cpHueFrame = Create("Frame", {
    Size = UDim2.fromOffset(16, cpSvSize),
    Position = UDim2.fromOffset(cpSvSize + 12, 24),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    Active = true,
    Parent = colorPickerFrame,
})
Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
        ColorSequenceKeypoint.new(0.1667, Color3.fromHSV(0.1667, 1, 1)),
        ColorSequenceKeypoint.new(0.3333, Color3.fromHSV(0.3333, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
        ColorSequenceKeypoint.new(0.6667, Color3.fromHSV(0.6667, 1, 1)),
        ColorSequenceKeypoint.new(0.8333, Color3.fromHSV(0.8333, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
    }),
    Rotation = 90,
    Parent = cpHueFrame,
})
local cpHueIndicator = Create("Frame", {
    Size = UDim2.fromOffset(16, 4),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 1,
    BorderColor3 = Color3.new(0, 0, 0),
    Active = false,
    Parent = cpHueFrame,
})

local cpHexBox = Create("TextBox", {
    Size = UDim2.new(1, -12, 0, 24),
    Position = UDim2.fromOffset(6, cpSvSize + 36),
    BackgroundColor3 = Library.MainColor,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    Text = "#ffffff",
    TextSize = 13,
    TextColor3 = Library.FontColor,
    PlaceholderText = "hex color",
    PlaceholderColor3 = Library:GetDimColor(),
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = colorPickerFrame,
})
local cpHexStroke = Stroke(cpHexBox, Library.OutlineColor, 1, 0.45)
Create("UIPadding", {
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
    Parent = cpHexBox,
})
Library:Bind(cpHexBox, {
    BackgroundColor3 = "MainColor",
    TextColor3 = "FontColor",
    PlaceholderColor3 = function()
        return Library:GetDimColor()
    end,
})
Library:Bind(cpHexStroke, { Color = "OutlineColor" })

Library._colorPicker = {
    Frame = colorPickerFrame,
    SvFrame = cpSvFrame,
    SvIndicator = cpSvIndicator,
    HueFrame = cpHueFrame,
    HueIndicator = cpHueIndicator,
    HexBox = cpHexBox,
    Size = cpSvSize,
    Option = nil,
    Swatch = nil,
    DraggingSV = false,
    DraggingHue = false,
    H = 0,
    S = 1,
    V = 1,
}

local function toHSV(color)
    if type(color) == "userdata" and color.ToHSV then
        local h, s, v = color:ToHSV()
        return h, s, v
    end
    return Color3.toHSV(color)
end

local function renderColorPicker()
    local picker = Library._colorPicker
    local option = picker.Option
    if not option then
        return
    end
    local color = option.Value
    local h, s, v = toHSV(color)
    picker.H, picker.S, picker.V = h, s, v
    picker.SvFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    picker.SvIndicator.Position = UDim2.fromOffset(math.floor(s * picker.Size) - 3, math.floor((1 - v) * picker.Size) - 3)
    picker.HueIndicator.Position = UDim2.fromOffset(0, math.floor(h * picker.Size) - 2)
    if not picker.HexBox:IsFocused() then
        picker.HexBox.Text = "#" .. ColorToHex(color)
    end
    if picker.Swatch then
        picker.Swatch.BackgroundColor3 = color
    end
end

local function updateFromSV(input)
    local picker = Library._colorPicker
    local relX = (input.Position.X - picker.SvFrame.AbsolutePosition.X) / picker.SvFrame.AbsoluteSize.X
    local relY = (input.Position.Y - picker.SvFrame.AbsolutePosition.Y) / picker.SvFrame.AbsoluteSize.Y
    picker.S = math.clamp(relX, 0, 1)
    picker.V = math.clamp(1 - relY, 0, 1)
    if picker.Option then
        picker.Option:SetValue(Color3.fromHSV(picker.H, picker.S, picker.V))
    end
    renderColorPicker()
end

local function updateFromHue(input)
    local picker = Library._colorPicker
    local relY = (input.Position.Y - picker.HueFrame.AbsolutePosition.Y) / picker.HueFrame.AbsoluteSize.Y
    picker.H = math.clamp(relY, 0, 1)
    if picker.Option then
        picker.Option:SetValue(Color3.fromHSV(picker.H, picker.S, picker.V))
    end
    renderColorPicker()
end

Connect(cpSvFrame.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Library._colorPicker.DraggingSV = true
        Library:PlayClick()
        updateFromSV(input)
    end
end)
Connect(cpHueFrame.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Library._colorPicker.DraggingHue = true
        Library:PlayClick()
        updateFromHue(input)
    end
end)
Connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if Library._colorPicker.DraggingSV then
            updateFromSV(input)
        end
        if Library._colorPicker.DraggingHue then
            updateFromHue(input)
        end
    end
end)
Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Library._colorPicker.DraggingSV = false
        Library._colorPicker.DraggingHue = false
    end
end)

Connect(cpHexBox.FocusLost, function(enterPressed)
    if enterPressed then
        local text = string.gsub(cpHexBox.Text or "", "#", "")
        local ok, color = pcall(Color3.fromHex, text)
        if ok then
            if Library._colorPicker.Option then
                Library._colorPicker.Option:SetValue(color)
            end
        else
            cpHexBox.Text = "#" .. ColorToHex(Library._colorPicker.Option and Library._colorPicker.Option.Value or Color3.new(1, 1, 1))
        end
    else
        if Library._colorPicker.Option then
            cpHexBox.Text = "#" .. ColorToHex(Library._colorPicker.Option.Value)
        end
    end
end)

function Library:OpenColorPicker(option, swatch)
    if self._colorPicker.Option == option and colorPickerFrame.Visible then
        colorPickerFrame.Visible = false
        self._colorPicker.Option = nil
        self._colorPicker.Swatch = nil
        return
    end
    self._colorPicker.Option = option
    self._colorPicker.Swatch = swatch
    colorPickerTitle.Text = option._colorPickerTitle or "color"
    renderColorPicker()

    local swatchPos = swatch.AbsolutePosition
    local swatchSize = swatch.AbsoluteSize
    local pickerSize = colorPickerFrame.AbsoluteSize
    local viewport = GetViewport()
    local gap = 8

    local window = option.Module and option.Module.Window
    local winPos = window and window._frame and window._frame.AbsolutePosition or swatchPos
    local winSize = window and window._frame and window._frame.AbsoluteSize or swatchSize

    local swatchCenterX = swatchPos.X + swatchSize.X / 2
    local swatchCenterY = swatchPos.Y + swatchSize.Y / 2

    -- Prefer placing the picker to the right of the module window.
    local candidates = {
        { name = "right", x = winPos.X + winSize.X + gap, y = swatchCenterY - pickerSize.Y / 2 },
        { name = "left", x = winPos.X - pickerSize.X - gap, y = swatchCenterY - pickerSize.Y / 2 },
        { name = "bottom", x = swatchPos.X, y = swatchPos.Y + swatchSize.Y + gap },
        { name = "top", x = swatchPos.X, y = swatchPos.Y - pickerSize.Y - gap },
    }

    local function clamp(v, minV, maxV)
        if v < minV then return minV end
        if v > maxV then return maxV end
        return v
    end

    local function overlapsWindow(x, y)
        local px1, py1 = x, y
        local px2, py2 = x + pickerSize.X, y + pickerSize.Y
        local wx1, wy1 = winPos.X, winPos.Y
        local wx2, wy2 = winPos.X + winSize.X, winPos.Y + winSize.Y
        return not (px2 < wx1 or px1 > wx2 or py2 < wy1 or py1 > wy2)
    end

    local chosen = nil
    for _, candidate in ipairs(candidates) do
        local cx = clamp(candidate.x, 4, viewport.X - pickerSize.X - 4)
        local cy = clamp(candidate.y, 4, viewport.Y - pickerSize.Y - 4)
        if not overlapsWindow(cx, cy) then
            chosen = { name = candidate.name, x = cx, y = cy }
            break
        end
    end

    if not chosen then
        local best, bestArea = nil, math.huge
        for _, candidate in ipairs(candidates) do
            local cx = clamp(candidate.x, 4, viewport.X - pickerSize.X - 4)
            local cy = clamp(candidate.y, 4, viewport.Y - pickerSize.Y - 4)
            local ox = math.max(0, math.min(cx + pickerSize.X, winPos.X + winSize.X) - math.max(cx, winPos.X))
            local oy = math.max(0, math.min(cy + pickerSize.Y, winPos.Y + winSize.Y) - math.max(cy, winPos.Y))
            local area = ox * oy
            if area < bestArea then
                bestArea = area
                best = { name = candidate.name, x = cx, y = cy }
            end
        end
        chosen = best
    end
    colorPickerFrame.Position = UDim2.fromOffset(chosen.x, chosen.y)
    colorPickerFrame.Visible = true
end
function Library:CloseColorPicker()
    colorPickerFrame.Visible = false
    self._colorPicker.Option = nil
    self._colorPicker.Swatch = nil
end

Connect(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and colorPickerFrame.Visible then
        local pos = input.Position
        local framePos = colorPickerFrame.AbsolutePosition
        local frameSize = colorPickerFrame.AbsoluteSize
        local inside = pos.X >= framePos.X and pos.X <= framePos.X + frameSize.X and pos.Y >= framePos.Y and pos.Y <= framePos.Y + frameSize.Y
        local swatch = Library._colorPicker.Swatch
        local swatchInside = false
        if swatch then
            local sp = swatch.AbsolutePosition
            local ss = swatch.AbsoluteSize
            swatchInside = pos.X >= sp.X and pos.X <= sp.X + ss.X and pos.Y >= sp.Y and pos.Y <= sp.Y + ss.Y
        end
        if not inside and not swatchInside then
            Library:CloseColorPicker()
        end
    end
end)
local notifyHolder = Create("Frame", {
    Name = "Notifications",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = notifyGui,
})
Create("UIPadding", {
    PaddingTop = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    Parent = notifyHolder,
})
Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = notifyHolder,
})



function Library:RenderSearchResults()
    for _, child in ipairs(resultsList:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    if self._query == "" then
        resultsFrame.Visible = false
        return
    end

    local results = self._searchResults
    if #results == 0 then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = "no matches",
            TextSize = 13,
            TextColor3 = self:GetDimColor(),
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = resultsList,
        })
    else
        for index, entry in ipairs(results) do
            local isSelected = index == self._searchIndex
            local resultModule = entry.Module
            local resultOption = entry.Option

            local row = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = isSelected and self.AccentColor or self:GetRowColor(),
                BackgroundTransparency = isSelected and 0.82 or 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                Parent = resultsList,
            })

            local bar = Create("Frame", {
                Size = UDim2.fromOffset(2, 16),
                Position = UDim2.fromOffset(6, 6),
                BackgroundColor3 = self.AccentColor,
                BorderSizePixel = 0,
                Visible = isSelected,
                Parent = row,
            })

            Create("TextLabel", {
                Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.fromOffset(14, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = resultModule.Name,
                TextSize = 13,
                TextColor3 = isSelected and self.AccentColor or self.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            local detail = resultModule.Window.Name
            if resultOption then
                detail = resultOption.Config.Text or resultOption.ID
            end

            Create("TextLabel", {
                Size = UDim2.fromOffset(100, 1),
                Position = UDim2.new(1, -106, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = detail,
                TextSize = 10,
                TextColor3 = self:GetDimColor(),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            row.MouseButton1Click:Connect(function()
                self:OpenPopout(resultModule, resultOption)
            end)
            row.MouseEnter:Connect(function()
                if not isSelected then
                    row.BackgroundTransparency = 0.94
                end
            end)
            row.MouseLeave:Connect(function()
                if not isSelected then
                    row.BackgroundTransparency = 1
                end
            end)
        end
    end

    resultsFrame.Visible = self._visible and not self._popoutModule
end

function Library:RefreshSearch()
    local raw = searchBox.Text or ""
    local query = string.lower((raw:gsub("^%s+", ""):gsub("%s+$", "")))
    self._query = query

    local matches = {}
    if query ~= "" then
        for _, module in ipairs(self._modules) do
            local ok, score, option = module:Matches(query)
            if ok then
                table.insert(matches, {
                    Module = module,
                    Score = score,
                    Option = option,
                    Index = module._index or 0,
                })
            end
        end
        table.sort(matches, function(a, b)
            if a.Score ~= b.Score then
                return a.Score < b.Score
            end
            return a.Index < b.Index
        end)
    end

    self._searchResults = matches
    if #matches == 0 then
        self._searchIndex = 0
    elseif self._searchIndex < 1 or self._searchIndex > #matches then
        self._searchIndex = 1
    end

    self:RenderSearchResults()

    for _, module in ipairs(self._modules) do
        module:UpdateVisual()
    end
end

function Library:SelectSearch(delta)
    if #self._searchResults == 0 then
        return
    end
    self._searchIndex = ((self._searchIndex - 1 + delta) % #self._searchResults) + 1
    self:RenderSearchResults()
end

function Library:OpenSelectedResult()
    local entry = self._searchResults[self._searchIndex]
    if entry then
        self:OpenPopout(entry.Module, entry.Option)
    end
end

function Library:OpenPopout(module, option)
    if not module or self._popoutModule or not self._visible then
        return
    end

    self:PlayClick()
    if self._activeKeyPicker and self._activeKeyPicker._cancelPick then
        self._activeKeyPicker._cancelPick(true)
    end
    self._popoutModule = module
    self._keyPicking = false
    pcall(function()
        searchBox:ReleaseFocus()
    end)

    popoutTitle.Text = module.Name
    local count = #module._options
    popoutSub.Text = module.Window.Name
        .. (count > 0 and ("  -  " .. count .. (count == 1 and " setting" or " settings")) or "  -  no settings")

    if module._expanded then
        module:SetExpanded(false, true)
    end

    local settings = module._settings
    if count > 0 then
        settings.Parent = popoutScroll
        popoutEmpty.Visible = false
    else
        popoutEmpty.Visible = true
    end
    popoutScroll.Visible = true

    local viewport = GetViewport()
    local scrollHeight = math.clamp(viewport.Y * 0.45, 160, 420)
    popoutGuiFrame.Size = UDim2.fromOffset(300, 54 + scrollHeight + 10)
    popoutScroll.Size = UDim2.new(1, -20, 0, scrollHeight)

    windowsGui.Enabled = false
    searchGui.Enabled = false
    tooltipFrame.Visible = false
    popoutGui.Enabled = true
    resultsFrame.Visible = false

    task.defer(function()
        task.wait()
        popoutScroll.CanvasPosition = Vector2.new(0, 0)
        if option and option._frame and module._settings then
            local targetY = option._frame.AbsolutePosition.Y - module._settings.AbsolutePosition.Y
            popoutScroll.CanvasPosition = Vector2.new(0, math.max(0, targetY - 6))
        end
    end)
end

function Library:ClosePopout()
    local module = self._popoutModule
    if not module then
        return
    end

    self._popoutModule = nil
    if module._settings then
        module._settings.Parent = module._settingsHome or hiddenHolder
    end

    popoutGui.Enabled = false
    windowsGui.Enabled = self._visible
    searchGui.Enabled = self._visible
    if self._visible and self._query ~= "" then
        self:RenderSearchResults()
    else
        resultsFrame.Visible = false
    end
end

local function SetPlayerListEnabled(enabled)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enabled)
    end)
end

local originalPlayerList = true
pcall(function()
    originalPlayerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
end)

function Library:SetVisible(visible)
    visible = visible == true
    if visible == self._visible then
        return
    end

    if not visible then
        self:ClosePopout()
        tooltipFrame.Visible = false
        resultsFrame.Visible = false
        pcall(function()
            searchBox:ReleaseFocus()
        end)
        if self._activeKeyPicker and self._activeKeyPicker._cancelPick then
            self._activeKeyPicker._cancelPick(true)
        end
        self._keyPicking = false
    end

    self._visible = visible
    windowsGui.Enabled = visible
    searchGui.Enabled = visible
    if visible then
        resultsFrame.Visible = self._query ~= ""
    end

    SetPlayerListEnabled(not visible and originalPlayerList or (visible and false))
end

function Library:Toggle()
    self:SetVisible(not self._visible)
end

function Library:Show()
    self:SetVisible(true)
end

function Library:Hide()
    self:SetVisible(false)
end

function Library:Notify(text, duration)
    local title = "Mercury"
    local description = text
    if type(text) == "table" then
        title = text.Title or title
        description = text.Description or text.Text or ""
        duration = text.Time or text.Duration or duration
    end
    title = LowerString(title)
    description = LowerString(description)
    duration = duration or 3
    if type(duration) ~= "number" then
        duration = 3
    end

    local notification = Create("CanvasGroup", {
        Size = UDim2.fromOffset(280, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.BackgroundColor,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Parent = notifyHolder,
    })
    local stroke = Stroke(notification, self.OutlineColor, 1, 0.2)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 10),
        Parent = notification,
    })
    Create("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.fromOffset(2, 9),
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Parent = notification,
    })
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(title),
        TextSize = 11,
        TextColor3 = self.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification,
    })
    local bodyLabel = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(12, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(description),
        TextSize = 13,
        TextColor3 = self.FontColor,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notification,
    })

    self:Bind(notification, { BackgroundColor3 = "BackgroundColor" })
    self:Bind(stroke, { Color = "OutlineColor" })
    self:Bind(titleLabel, { TextColor3 = "AccentColor" })
    self:Bind(bodyLabel, { TextColor3 = "FontColor" })

    Tween(notification, { GroupTransparency = 0 }, 0.14)
    task.delay(duration, function()
        if not notification.Parent then
            return
        end
        Tween(notification, { GroupTransparency = 1 }, 0.2)
        task.wait(0.22)
        if notification.Parent then
            notification:Destroy()
        end
    end)

    return notification
end

function Library:RefreshUI()
    self.AccentColorDark = self:GetDarkerColor(self.AccentColor)
    self:ApplyRegistry()
    for _, module in ipairs(self._modules) do
        module:UpdateVisual()
    end
    for _, option in ipairs(self._allOptions) do
        option:_Refresh()
    end
    if not self._popoutModule then
        self:RenderSearchResults()
    end
end

function Library:_HandleToggleKey()
    if self._keyPicking then
        return
    end
    local now = os.clock()
    if now - (self._lastToggleInput or 0) < 0.08 then
        return
    end
    self._lastToggleInput = now
    self:Toggle()
end

function Library:_BindToggleAction()
    if self._toggleActionBound then
        pcall(function()
            ContextActionService:UnbindAction("MercuryToggle")
        end)
        self._toggleActionBound = false
    end
    if not self.ToggleKeybind then
        return
    end

    local priority = 3000
    if Enum.ContextActionPriority and Enum.ContextActionPriority.High then
        priority = Enum.ContextActionPriority.High.Value
    end
    local sink = Enum.ContextActionResult and Enum.ContextActionResult.Sink

    local ok = pcall(function()
        ContextActionService:BindActionAtPriority("MercuryToggle", function(_, state)
            if state == Enum.UserInputState.Begin then
                Library:_HandleToggleKey()
            end
            return sink or Enum.UserInputState.Begin
        end, false, priority, self.ToggleKeybind)
    end)
    self._toggleActionBound = ok
end

function Library:SetToggleKey(keyCode)
    self.ToggleKeybind = keyCode or Enum.KeyCode.RightShift
    self:_BindToggleAction()
end



local Module = {}
Module.__index = Module

local Window = {}
Window.__index = Window

function Window:AddModule(name, config)
    name = LowerString(name)
    if Library.ModuleMap[name] then
        error(("[Mercury] a module named %q already exists"):format(name))
    end

    config = config or {}
    if config.Tooltip then
        config.Tooltip = LowerString(config.Tooltip)
    end
    local module = setmetatable({
        Name = name,
        Window = self,
        Config = config,
        Options = {},
        _options = {},
        _layoutOrder = 0,
        _index = #Library._modules + 1,
    }, Module)
    module.Options = Library.Options[name] or {}
    Library.Options[name] = module.Options
    Library.ModuleMap[name] = module
    table.insert(Library._modules, module)
    table.insert(self.modules, module)
    self.moduleOrder[name] = module

    
    local toggle = Option.new("Module", module, name, {
        Text = name,
        Default = config.Default == true,
    })
    Library.Toggles[name] = toggle
    module.Toggle = toggle

    
    local container = Create("Frame", {
        Name = name .. "Container",
        Size = UDim2.new(1, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #self.modules,
        Parent = self._rows,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = container,
    })

    local row = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Parent = container,
    })

    local nameHolder = Create("Frame", {
        Name = "NameHolder",
        Size = UDim2.fromOffset(0, 24),
        Position = UDim2.fromOffset(4, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = row,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = nameHolder,
    })

    local label = Create("TextLabel", {
        Size = UDim2.fromOffset(0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.X,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
        Parent = nameHolder,
    })

    local rowChevron = Create("ImageLabel", {
        Name = "Chevron",
        Size = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Image = Library._chevronImage or "",
        ImageColor3 = Library:GetSubTextColor(),
        Rotation = -90,
        Visible = true,
        LayoutOrder = 2,
        Parent = nameHolder,
    })

    local settingsClip = Create("Frame", {
        Name = "SettingsClip",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = 2,
        Parent = container,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = settingsClip,
    })

    module._row = row
    module._rowLabel = label
    module._rowChevron = rowChevron
    module._container = container
    module._settingsClip = settingsClip
    module._settingsHome = settingsClip
    module._expanded = false
    module._settingsHeight = 0
    module._hover = false

    module._settings = Create("Frame", {
        Name = "Settings_" .. name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = settingsClip,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = module._settings,
    })

    Connect(row.MouseButton1Click, function()
        Library:PlayClick()
        toggle:SetValue(not toggle.Value)
    end)
    Connect(row.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Library:PlayClick()
            module:SetExpanded(not module._expanded)
        end
    end)
    Connect(row.MouseEnter, function()
        Library:PlayHover()
        module._hover = true
        module:UpdateVisual()
        if config.Tooltip and Library._visible and not Library._popoutModule then
            tooltipLabel.Text = config.Tooltip
            tooltipFrame.Visible = true
            local mouse = UserInputService:GetMouseLocation()
            tooltipFrame.Position = UDim2.fromOffset(mouse.X + 16, mouse.Y + 18)
        end
    end)
    Connect(row.MouseLeave, function()
        module._hover = false
        module:UpdateVisual()
        tooltipFrame.Visible = false
    end)
    Connect(row.MouseMoved, function()
        if tooltipFrame.Visible then
            local mouse = UserInputService:GetMouseLocation()
            tooltipFrame.Position = UDim2.fromOffset(mouse.X + 16, mouse.Y + 18)
        end
    end)

    toggle:OnChanged(function()
        module:UpdateVisual()
        if type(config.Callback) == "function" then
            task.spawn(SafeCallback, config.Callback, toggle.Value)
        end
    end)

    self:_UpdateHeight()
    module:UpdateVisual()
    return module
end

function Module:_MeasureSettingsHeight()
    local height = self._settings and self._settings.AbsoluteSize.Y or 0
    if height <= 0 then
        return 0
    end
    return height + 10
end

function Module:SetExpanded(expanded, instant)
    expanded = expanded == true
    if self._expanded == expanded then
        return
    end
    self._expanded = expanded

    local function apply()
        if self._expanded ~= expanded then
            return
        end

        local targetHeight = expanded and self:_MeasureSettingsHeight() or 0
        self._settingsHeight = targetHeight
        local duration = instant and 0 or 0.2
        local targetRotation = expanded and 0 or -90

        if instant then
            self._settingsClip.Size = UDim2.new(1, 0, 0, targetHeight)
            self._rowChevron.Rotation = targetRotation
        else
            Tween(self._settingsClip, { Size = UDim2.new(1, 0, 0, targetHeight) }, duration)
            Tween(self._rowChevron, {
                Rotation = targetRotation,
            }, duration)
        end

        self.Window:_UpdateHeight(not instant)

        if expanded then
            self._settingsClip.Visible = true
        else
            task.delay(duration, function()
                if not self._expanded and self._settingsClip then
                    self._settingsClip.Visible = false
                end
            end)
        end
    end

    if expanded then
        self._settingsClip.Visible = true
        if instant then
            apply()
        else
            task.defer(apply)
        end
    else
        apply()
    end
end

function Window:_UpdateHeight(animate)
    local contentHeight = 0
    local count = #self.modules
    for index, module in ipairs(self.modules) do
        contentHeight = contentHeight + 24
        if module._expanded then
            contentHeight = contentHeight + (module._settingsHeight or 0)
        end
        if index < count then
            contentHeight = contentHeight + 3
        end
    end

    local maxHeight = math.min(GetViewport().Y * 0.62, 540)
    local rowsHeight = math.min(contentHeight, maxHeight)
    self._rowsHeight = rowsHeight
    self._rows.CanvasSize = UDim2.fromOffset(0, contentHeight)

    if self._collapsed then
        self._rows.Size = UDim2.new(1, 0, 0, rowsHeight)
        self._section.Visible = false
        self._section.Size = UDim2.new(1, 0, 0, 0)
        self._body.Size = UDim2.new(1, 0, 0, 24)
        self._frame.Size = UDim2.fromOffset(self._width or 190, 24)
    else
        self._section.Visible = true
        local bodyHeight = 28 + rowsHeight + 4
        if animate then
            Tween(self._rows, { Size = UDim2.new(1, 0, 0, rowsHeight) }, 0.2)
            Tween(self._section, { Size = UDim2.new(1, 0, 0, rowsHeight) }, 0.2)
            Tween(self._body, { Size = UDim2.new(1, 0, 0, bodyHeight) }, 0.2)
            Tween(self._frame, { Size = UDim2.fromOffset(self._width or 190, bodyHeight) }, 0.2)
        else
            self._rows.Size = UDim2.new(1, 0, 0, rowsHeight)
            self._section.Size = UDim2.new(1, 0, 0, rowsHeight)
            self._body.Size = UDim2.new(1, 0, 0, bodyHeight)
            self._frame.Size = UDim2.fromOffset(self._width or 190, bodyHeight)
        end
    end
end

function Window:SetCollapsed(collapsed)
    collapsed = collapsed == true
    if self._collapsed == collapsed then
        return
    end
    self._collapsed = collapsed

    local rowsHeight = self._rowsHeight or 0
    local sectionHeight = collapsed and 0 or rowsHeight
    local bodyHeight = collapsed and 24 or (32 + sectionHeight)
    if not collapsed then
        self._section.Visible = true
    end

    Tween(self._section, { Size = UDim2.new(1, 0, 0, sectionHeight) }, 0.2)
    Tween(self._body, { Size = UDim2.new(1, 0, 0, bodyHeight) }, 0.2)
    Tween(self._frame, { Size = UDim2.fromOffset(self._width or 190, bodyHeight) }, 0.2)
    if self._chevron then
        Tween(self._chevron, { Rotation = collapsed and -90 or 0 }, 0.2)
    end

    if collapsed then
        task.delay(0.2, function()
            if self._collapsed and self._section then
                self._section.Visible = false
            end
        end)
    end
end

function Window:SetPosition(x, y)
    self._frame.Position = UDim2.fromOffset(x, y)
end



function Module:_NextOrder()
    self._layoutOrder = self._layoutOrder + 1
    return self._layoutOrder
end

function Module:_RegisterOption(kind, id, config)
    if type(id) ~= "string" or id == "" then
        error("[Mercury] option ids must be non-empty strings")
    end
    id = LowerString(id)
    if self.Options[id] then
        error(("[Mercury] duplicate option %q in module %q"):format(id, self.Name))
    end

    config = config or {}
    config.Text = LowerString(config.Text or id)

    local option = Option.new(kind, self, id, config)
    self.Options[id] = option
    table.insert(self._options, option)
    table.insert(Library._allOptions, option)

    if kind == "KeyPicker" then
        option.Mode = config.Mode or "Toggle"
    elseif kind == "Dropdown" then
        option.Multi = config.Multi == true
    end

    if self._expanded then
        task.defer(function()
            if self._expanded then
                self._settingsHeight = self:_MeasureSettingsHeight()
                self._settingsClip.Size = UDim2.new(1, 0, 0, self._settingsHeight)
                self.Window:_UpdateHeight(true)
            end
        end)
    end

    return option
end

function Module:SetEnabled(value, silent)
    self.Toggle:SetValue(value == true, silent)
    return self
end

function Module:Matches(query)
    query = string.lower(query)
    if query == "" then
        return true, 0, nil
    end

    local name = string.lower(self.Name)
    local score = nil

    if name == query then
        score = 1
    elseif string.sub(name, 1, #query) == query then
        score = 2
    elseif string.find(name, query, 1, true) then
        score = 3
    end

    local matchedOption = nil
    for _, option in ipairs(self._options) do
        local text = string.lower(option.Config.Text or option.ID)
        if string.find(text, query, 1, true) then
            if not matchedOption then
                matchedOption = option
            end
            if not score then
                if string.sub(text, 1, #query) == query then
                    score = 4
                else
                    score = 5
                end
            end
        end
    end

    if not score then
        local category = string.lower(self.Window.Name)
        if string.find(category, query, 1, true) then
            score = 6
        end
    end

    if not score then
        return false
    end
    return true, score, matchedOption
end

function Module:UpdateVisual()
    local enabled = self.Toggle and self.Toggle.Value == true
    local dimmed = Library._query ~= "" and not (self:Matches(Library._query))
    local row = self._row
    if not row then
        return
    end

    local color
    if dimmed then
        color = Library:GetDimColor()
    elseif enabled or self._expanded or self._hover then
        color = Library.AccentColor
    else
        color = Library.FontColor
    end

    self._rowLabel.TextColor3 = color
    self._rowLabel.TextTransparency = dimmed and 0.45 or 0
    if self._rowChevron then
        self._rowChevron.Rotation = self._expanded and 0 or -90
        self._rowChevron.ImageColor3 = (enabled or self._expanded or self._hover) and Library.AccentColor or Library:GetSubTextColor()
        self._rowChevron.ImageTransparency = dimmed and 0.6 or 0
    end
end

function Module:AddToggle(id, config)
    config = config or {}
    config.Default = config.Default == true
    local option = self:_RegisterOption("Toggle", id, config)

    local holder = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })
    Library:Bind(label, { TextColor3 = "FontColor" })

    local switch = Create("Frame", {
        Size = UDim2.fromOffset(36, 18),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Library:GetRowColor(),
        BorderSizePixel = 0,
        Parent = holder,
    })
    local switchStroke = Stroke(switch, Library.OutlineColor, 1, 0.45)

    local knob = Create("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Library:GetDimColor(),
        BorderSizePixel = 0,
        Parent = switch,
    })

    option:_AddRender(function()
        local on = option.Value == true
        switch.BackgroundColor3 = on and Library.AccentColor or Library:GetRowColor()
        switchStroke.Color = on and Library.AccentColor or Library.OutlineColor
        knob.BackgroundColor3 = on and Color3.new(1, 1, 1) or Library:GetDimColor()
        knob.Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    end)

    Connect(holder.MouseButton1Click, function()
        Library:PlayClick()
        option:SetValue(not option.Value)
    end)

    return option
end

function Module:AddSlider(id, config)
    config = config or {}
    config.Min = config.Min or 0
    config.Max = config.Max or 100
    config.Default = config.Default or config.Min
    local option = self:_RegisterOption("Slider", id, config)

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })
    Library:Bind(label, { TextColor3 = "FontColor" })

    local valueLabel = Create("TextLabel", {
        Size = UDim2.fromOffset(90, 16),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 11,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = holder,
    })
    Library:Bind(valueLabel, { TextColor3 = "AccentColor" })

    local track = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.fromOffset(0, 25),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Parent = holder,
    })
    Library:Bind(track, { BackgroundColor3 = "MainColor" })

    local fill = Create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Parent = track,
    })
    Library:Bind(fill, { BackgroundColor3 = "AccentColor" })

    local knob = Create("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    local knobStroke = Stroke(knob, Library.AccentColor, 1, 0)
    Library:Bind(knobStroke, { Color = "AccentColor" })

    local hitbox = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 17),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })

    local function format(value)
        local decimals = math.max(0, math.floor(config.Rounding or 0))
        local formatted
        if decimals == 0 then
            formatted = string.format("%d", math.floor(value + 0.5))
        else
            formatted = string.format("%." .. decimals .. "f", value)
        end
        return (config.Prefix or "") .. formatted .. (config.Suffix or "")
    end

    local function render()
        local range = config.Max - config.Min
        local percent = range > 0 and (option.Value - config.Min) / range or 0
        percent = math.clamp(percent, 0, 1)
        fill.Size = UDim2.fromScale(percent, 1)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        valueLabel.Text = format(option.Value)
    end
    option:_AddRender(render)

    local dragging = false
    local function update(input)
        local width = math.max(1, track.AbsoluteSize.X)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        option:SetValue(config.Min + (config.Max - config.Min) * percent)
    end

    Connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Library:PlayClick()
            dragging = true
            update(input)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return option
end

function Module:AddDropdown(id, config)
    config = config or {}

    local values = {}
    local rawValues = config.Values or {}
    if #rawValues > 0 then
        for _, value in ipairs(rawValues) do
            table.insert(values, tostring(value))
        end
    else
        for value in pairs(rawValues) do
            table.insert(values, tostring(value))
        end
        table.sort(values)
    end
    config.Values = values

    if config.Multi then
        local selected = {}
        if type(config.Default) == "table" then
            for value, state in pairs(config.Default) do
                if state then
                    selected[tostring(value)] = true
                end
            end
        elseif config.Default ~= nil then
            selected[tostring(config.Default)] = true
        end
        config.Default = selected
    else
        local default = config.Default
        if default == nil then
            default = values[1]
        elseif type(default) == "number" then
            default = values[default]
        end
        config.Default = default
    end

    local option = self:_RegisterOption("Dropdown", id, config)

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 11,
        TextColor3 = Library:GetSubTextColor(),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    Library:Bind(label, {
        TextColor3 = function()
            return Library:GetSubTextColor()
        end,
    })

    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, 18),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })
    local buttonStroke = Stroke(button, Library.OutlineColor, 1, 0.45)
    Library:Bind(button, { BackgroundColor3 = "MainColor" })
    Library:Bind(buttonStroke, { Color = "OutlineColor" })

    local buttonLabel = Create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    })
    Library:Bind(buttonLabel, { TextColor3 = "FontColor" })

    local arrow = Create("TextLabel", {
        Size = UDim2.fromOffset(14, 1),
        Position = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "+",
        TextSize = 14,
        TextColor3 = Library:GetSubTextColor(),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = button,
    })
    Library:Bind(arrow, {
        TextColor3 = function()
            return Library:GetSubTextColor()
        end,
    })

    local list = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 47),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Visible = false,
        Parent = holder,
    })
    local listStroke = Stroke(list, Library.OutlineColor, 1, 0.35)
    Library:Bind(list, { BackgroundColor3 = "BackgroundColor" })
    Library:Bind(listStroke, { Color = "OutlineColor" })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
        Parent = list,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = list,
    })

    local function isSelected(value)
        if option.Multi then
            return type(option.Value) == "table" and option.Value[value] == true
        end
        return option.Value == value
    end

    local function updateLabel()
        local text
        if option.Multi then
            local selected = {}
            if type(option.Value) == "table" then
                for value in pairs(option.Value) do
                    if option.Value[value] then
                        table.insert(selected, value)
                    end
                end
            end
            table.sort(selected)
            text = #selected > 0 and table.concat(selected, ", ") or "none"
        else
            text = option.Value ~= nil and tostring(option.Value) or "none"
        end
        buttonLabel.Text = LowerString(text)
    end

    local items = {}

    local function render()
        updateLabel()
        arrow.Text = list.Visible and "-" or "+"
        for _, item in ipairs(items) do
            local selected = isSelected(item.Value)
            item.Button.BackgroundTransparency = selected and 0.8 or 1
            item.Label.TextColor3 = selected and Library.AccentColor or Library.FontColor
        end
    end

    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        items = {}

        for index, value in ipairs(option.Config.Values) do
            local itemValue = value
            local item = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Library.AccentColor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                Parent = list,
            })

            local itemLabel = Create("TextLabel", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.fromOffset(6, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = LowerString(itemValue),
                TextSize = 13,
                TextColor3 = Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = item,
            })

            table.insert(items, {
                Button = item,
                Label = itemLabel,
                Value = itemValue,
            })

            item.MouseButton1Click:Connect(function()
                Library:PlayClick()
                if option.Multi then
                    local current = {}
                    if type(option.Value) == "table" then
                        for key, state in pairs(option.Value) do
                            current[key] = state
                        end
                    end
                    current[itemValue] = not current[itemValue] or nil
                    option:SetValue(current)
                else
                    option:SetValue(itemValue)
                    list.Visible = false
                    render()
                end
            end)
        end
    end
    option._rebuild = rebuild
    option._setValues = function(newValues)
        local normalized = {}
        for _, value in ipairs(newValues or {}) do
            table.insert(normalized, tostring(value))
        end
        option.Config.Values = normalized
        if option.Multi then
            local allowed = {}
            for _, value in ipairs(normalized) do
                allowed[value] = true
            end
            local selected = {}
            if type(option.Value) == "table" then
                for value, state in pairs(option.Value) do
                    if state and allowed[value] then
                        selected[value] = true
                    end
                end
            end
            option:SetValue(selected, true)
        else
            if option.Value == nil and normalized[1] then
                option:SetValue(normalized[1], true)
            elseif option.Value ~= nil and not table.find(normalized, option.Value) then
                option:SetValue(normalized[1], true)
            end
        end
        rebuild()
        render()
    end

    Connect(button.MouseButton1Click, function()
        Library:PlayClick()
        list.Visible = not list.Visible
        render()
    end)

    option:_AddRender(render)
    rebuild()
    render()

    return option
end

function Module:AddInput(id, config)
    config = config or {}
    config.Default = config.Default or ""
    local option = self:_RegisterOption("Input", id, config)

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 11,
        TextColor3 = Library:GetSubTextColor(),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    Library:Bind(label, {
        TextColor3 = function()
            return Library:GetSubTextColor()
        end,
    })

    local box = Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, 18),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = tostring(option.Value or ""),
        TextSize = 13,
        TextColor3 = Library.FontColor,
        PlaceholderText = LowerString(config.Placeholder),
        PlaceholderColor3 = Library:GetDimColor(),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    local boxStroke = Stroke(box, Library.OutlineColor, 1, 0.45)
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        Parent = box,
    })
    Library:Bind(box, {
        BackgroundColor3 = "MainColor",
        TextColor3 = "FontColor",
        PlaceholderColor3 = function()
            return Library:GetDimColor()
        end,
    })
    Library:Bind(boxStroke, { Color = "OutlineColor" })

    option:_AddRender(function()
        if not box:IsFocused() then
            box.Text = tostring(option.Value or "")
        end
    end)

    Connect(box.FocusLost, function()
        option:SetValue(box.Text)
    end)

    return option
end

function Module:AddKeyPicker(id, config)
    config = config or {}
    config.Default = config.Default or "None"
    config.Mode = config.Mode or "Toggle"
    local option = self:_RegisterOption("KeyPicker", id, config)

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -120, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })
    Library:Bind(label, { TextColor3 = "FontColor" })

    local modeLabel = Create("TextLabel", {
        Size = UDim2.new(1, -120, 0, 12),
        Position = UDim2.fromOffset(0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = option.Mode,
        TextSize = 10,
        TextColor3 = Library:GetDimColor(),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    Library:Bind(modeLabel, {
        TextColor3 = function()
            return Library:GetDimColor()
        end,
    })

    local button = Create("TextButton", {
        Size = UDim2.fromOffset(110, 24),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Text = tostring(option.Value or "None"),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = Library.AccentColor,
        AutoButtonColor = false,
        Parent = holder,
    })
    local buttonStroke = Stroke(button, Library.OutlineColor, 1, 0.45)
    Library:Bind(button, {
        BackgroundColor3 = "MainColor",
        TextColor3 = "AccentColor",
    })
    Library:Bind(buttonStroke, { Color = "OutlineColor" })

    local picking = false
    local function stopPicking(cancel)
        if not picking then
            return
        end
        picking = false
        Library._keyPicking = false
        if Library._activeKeyPicker == option then
            Library._activeKeyPicker = nil
        end
        button.Text = LowerString(option.Value or "none")
        if not cancel then
            Tween(button, { BackgroundColor3 = Library.MainColor }, 0.12)
        end
    end
    option._cancelPick = stopPicking

    local function startPicking()
        if picking then
            return
        end
        if Library._activeKeyPicker and Library._activeKeyPicker ~= option and Library._activeKeyPicker._cancelPick then
            Library._activeKeyPicker._cancelPick(true)
        end
        picking = true
        Library._keyPicking = true
        Library._activeKeyPicker = option
        button.Text = "press a key..."
        Tween(button, { BackgroundColor3 = Library.AccentColorDark }, 0.12)
        task.delay(6, function()
            stopPicking(true)
        end)
    end

    option:_AddRender(function()
        modeLabel.Text = LowerString(option.Mode or "toggle")
        if not picking then
            button.Text = LowerString(option.Value or "none")
        end
    end)

    Connect(button.MouseButton1Click, function()
        Library:PlayClick()
        startPicking()
    end)
    Connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and not picking then
            Library:PlayClick()
            local order = { "Toggle", "Hold", "Press" }
            local index = table.find(order, option.Mode) or 1
            option:SetMode(order[(index % #order) + 1])
        end
    end)

    local function matches(input)
        local key = option.Value
        if key == "MB1" then
            return input.UserInputType == Enum.UserInputType.MouseButton1
        elseif key == "MB2" then
            return input.UserInputType == Enum.UserInputType.MouseButton2
        elseif key == "MB3" then
            return input.UserInputType == Enum.UserInputType.MouseButton3
        elseif type(key) == "string" then
            local keyCode = Enum.KeyCode[key]
            return keyCode ~= nil and input.KeyCode == keyCode
        end
        return false
    end

    Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if picking then
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                stopPicking(true)
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    Library._suppressKeysUntil = os.clock() + 0.05
                    option:SetValue(input.KeyCode.Name)
                    stopPicking()
                end
                return
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                Library._suppressKeysUntil = os.clock() + 0.05
                option:SetValue("MB2")
                stopPicking()
                return
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                Library._suppressKeysUntil = os.clock() + 0.05
                option:SetValue("MB3")
                stopPicking()
                return
            end
        end

        if
            gameProcessed
            or Library._keyPicking
            or UserInputService:GetFocusedTextBox()
            or os.clock() < (Library._suppressKeysUntil or 0)
        then
            return
        end
        if not matches(input) then
            return
        end

        if option.Mode == "Hold" then
            if not option.State then
                option:_SetState(true)
            end
        elseif option.Mode == "Press" then
            option:_SetState(true)
            option.State = false
        else
            option:_SetState(not option.State)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if Library._keyPicking then
            return
        end
        if option.Mode == "Hold" and matches(input) and option.State then
            option:_SetState(false)
        end
    end)

    return option
end

function Module:AddColorPicker(id, config)
    config = config or {}
    config.Default = config.Default or Color3.fromRGB(255, 255, 255)
    local option = self:_RegisterOption("ColorPicker", id, config)
    option._colorPickerTitle = LowerString(config.Title or config.Text or id)

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Text,
        TextSize = 13,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })
    Library:Bind(label, { TextColor3 = "FontColor" })

    local swatch = Create("TextButton", {
        Size = UDim2.fromOffset(46, 20),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = option.Value,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })
    local swatchStroke = Stroke(swatch, Library.OutlineColor, 1, 0.2)
    Library:Bind(swatchStroke, { Color = "OutlineColor" })

    local function render()
        swatch.BackgroundColor3 = option.Value
        if Library._colorPicker and Library._colorPicker.Option == option then
            renderColorPicker()
        end
    end
    option:_AddRender(render)

    Connect(swatch.MouseButton1Click, function()
        Library:PlayClick()
        Library:OpenColorPicker(option, swatch)
    end)

    swatch.BackgroundColor3 = option.Value
    render()

    return option
end

function Module:AddButton(first, second)
    local config
    if type(first) == "table" then
        config = first
    elseif type(second) == "function" then
        config = { Text = first, Func = second }
    elseif type(second) == "table" then
        config = second
        config.Text = config.Text or first
    else
        config = { Text = first }
    end

    local text = LowerString(config.Text or "button")
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Text = text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    local stroke = Stroke(button, Library.AccentColorDark, 1, 0.2)
    Library:Bind(button, { BackgroundColor3 = "AccentColor" })
    Library:Bind(stroke, { Color = "AccentColorDark" })

    Connect(button.MouseButton1Click, function()
        Library:PlayClick()
        SafeCallback(config.Func or config.Callback)
    end)
    Connect(button.MouseEnter, function()
        Tween(button, { BackgroundColor3 = Library.AccentColor:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.1)
    end)
    Connect(button.MouseLeave, function()
        Tween(button, { BackgroundColor3 = Library.AccentColor }, 0.1)
    end)

    local object = { Frame = button, Text = text }
    function object:SetText(newText)
        newText = LowerString(newText)
        self.Text = newText
        button.Text = newText
    end
    return object
end

function Module:AddLabel(text, config)
    if type(text) == "table" then
        config = text
        text = config.Text or ""
    end
    config = config or {}
    text = LowerString(text)

    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = config.Size or 11,
        TextColor3 = config.Color or Library:GetSubTextColor(),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    if not config.Color then
        Library:Bind(label, {
            TextColor3 = function()
                return Library:GetSubTextColor()
            end,
        })
    end

    local object = { Frame = label, Text = text }
    function object:SetText(newText)
        newText = LowerString(newText)
        self.Text = newText
        label.Text = newText
    end
    return object
end

function Module:AddDivider()
    local divider = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    Library:Bind(divider, { BackgroundColor3 = "OutlineColor" })
    return divider
end



function Library:AddWindow(name, config)
    name = LowerString(name)
    if self.Windows[name] then
        error(("[Mercury] a window named %q already exists"):format(name))
    end
    config = config or {}

    local window = setmetatable({
        Name = name,
        Config = config,
        Modules = {},
        modules = {},
        moduleOrder = {},
    }, Window)
    self.Windows[name] = window
    table.insert(self._windows, window)

    local width = config.Width or 190
    local index = #self._windows
    local viewport = GetViewport()
    local x = 24 + (index - 1) * (width + 6)
    local y = 66
    if x + width > viewport.X - 24 then
        x = math.max(24, viewport.X - width - 24)
    end

    local frame = Create("Frame", {
        Name = name,
        Size = UDim2.fromOffset(width, 32),
        Position = UDim2.fromOffset(x, y),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = windowsHolder,
    })

    local body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    self:Bind(body, { BackgroundColor3 = "MainColor" })

    local title = Create("Frame", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = body,
    })
    self:Bind(title, { BackgroundColor3 = "AccentColor" })

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name,
        TextSize = 15,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = title,
    })

    local chevron = Create("ImageLabel", {
        Name = "Chevron",
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Image = Library._chevronImage or "",
        ImageColor3 = Color3.new(1, 1, 1),
        Rotation = 0,
        Parent = title,
    })

    local section = Create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = body,
    })

    local rows = Create("ScrollingFrame", {
        Name = "Rows",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.AccentColor,
        ScrollBarImageTransparency = 0.45,
        ClipsDescendants = true,
        Parent = section,
    })
    self:Bind(rows, { ScrollBarImageColor3 = "AccentColor" })
    Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = rows,
    })

    window._frame = frame
    window._body = body
    window._section = section
    window._title = title
    window._titleLabel = titleLabel
    window._chevron = chevron
    window._rows = rows
    window._width = width
    window._collapsed = false
    window._rowsHeight = 0

    local dragging = false
    local moved = false
    local dragStart
    local startPosition

    Connect(title.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            startPosition = frame.AbsolutePosition
            Library._frontZ = Library._frontZ + 1
            frame.ZIndex = Library._frontZ
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            if not moved and (math.abs(delta.X) > 4 or math.abs(delta.Y) > 4) then
                moved = true
            end
            if moved then
                local viewportNow = GetViewport()
                local newX = math.clamp(startPosition.X + delta.X, -width + 60, viewportNow.X - 60)
                local newY = math.clamp(startPosition.Y + delta.Y, 0, viewportNow.Y - 30)
                frame.Position = UDim2.fromOffset(newX, newY)
            end
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if not moved then
                Library:PlayClick()
                window:SetCollapsed(not window._collapsed)
            end
        end
    end)

    window:_UpdateHeight()
    return window
end



local ThemeManager = {
    Folder = "Mercury",
    Library = Library,
    BuiltInThemes = {
        Mercury = { BackgroundColor = "0a0a0d", MainColor = "16161c", AccentColor = "ff2d87", OutlineColor = "3a3a46", FontColor = "e8e8ee" },
        Lambda = { BackgroundColor = "050507", MainColor = "111114", AccentColor = "f92f7a", OutlineColor = "4a1c33", FontColor = "f2f2f5" },
        Vape = { BackgroundColor = "0d0d10", MainColor = "1a1a20", AccentColor = "3d7bfd", OutlineColor = "2b2b36", FontColor = "f0f0f4" },
        Fatality = { BackgroundColor = "191335", MainColor = "1e1842", AccentColor = "c50754", OutlineColor = "3c355d", FontColor = "ffffff" },
        Jester = { BackgroundColor = "1c1c1c", MainColor = "242424", AccentColor = "db4467", OutlineColor = "373737", FontColor = "ffffff" },
        Mint = { BackgroundColor = "1c1c1c", MainColor = "242424", AccentColor = "3db488", OutlineColor = "373737", FontColor = "ffffff" },
        ['Tokyo Night'] = { BackgroundColor = "16161f", MainColor = "191925", AccentColor = "6759b3", OutlineColor = "323232", FontColor = "f2f2f7" },
        Quartz = { BackgroundColor = "1d1b26", MainColor = "232330", AccentColor = "426e87", OutlineColor = "27232f", FontColor = "ffffff" },
        BBot = { BackgroundColor = "232323", MainColor = "1e1e1e", AccentColor = "7e48a3", OutlineColor = "141414", FontColor = "ffffff" },
        Ubuntu = { BackgroundColor = "323232", MainColor = "3e3e3e", AccentColor = "e2581e", OutlineColor = "191919", FontColor = "ffffff" },
    },
    ThemeFields = { "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor" },
    ThemeOptions = {},
    ThemeModule = nil,
}

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    EnsureFolder(self.Folder)
    EnsureFolder(self.Folder .. "/themes")
end

function ThemeManager:GetThemesPath()
    return self.Folder .. "/themes"
end

function ThemeManager:GetCustomTheme(name)
    if not FileAPI then
        return nil
    end
    local path = self:GetThemesPath() .. "/" .. name .. ".json"
    if not FileExists(path) then
        return nil
    end
    local raw = ReadFile(path)
    if not raw then
        return nil
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return nil
end

function ThemeManager:GetAllThemeNames()
    local names = {}
    for name in pairs(self.BuiltInThemes) do
        table.insert(names, name)
    end

    local folder = self:GetThemesPath()
    local folderOk, folderExists = false, false
    if FileAPI then
        folderOk, folderExists = pcall(isfolder, folder)
    end
    if folderOk and folderExists then
        local ok, files = pcall(listfiles, folder)
        if ok and type(files) == "table" then
            for _, file in ipairs(files) do
                local base = FileBaseName(file)
                if string.sub(base, -5) == ".json" then
                    table.insert(names, string.sub(base, 1, #base - 5))
                end
            end
        end
    end

    table.sort(names)
    return names
end

function ThemeManager:ApplyTheme(name)
    local data = self:GetCustomTheme(name) or self.BuiltInThemes[name]
    if not data then
        return false, "unknown theme"
    end

    Library._applyingTheme = true
    for _, field in ipairs(self.ThemeFields) do
        local hex = data[field]
        if type(hex) == "string" then
            local ok, color = pcall(Color3.fromHex, hex)
            if ok then
                Library[field] = color
                local option = self.ThemeOptions[field]
                if option then
                    option:SetValue(color, true)
                end
            end
        end
    end
    Library._applyingTheme = false
    Library:RefreshUI()
    return true
end

function ThemeManager:SaveCustomTheme(name)
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return false, "invalid theme name"
    end
    if not FileAPI then
        return false, "executor has no file access"
    end
    EnsureFolder(self.Folder)
    EnsureFolder(self:GetThemesPath())

    local data = {}
    for _, field in ipairs(self.ThemeFields) do
        local option = self.ThemeOptions[field]
        local color = option and option.Value or Library[field]
        data[field] = ColorToHex(color)
    end

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then
        return false, "failed to encode theme"
    end
    if not WriteFile(self:GetThemesPath() .. "/" .. name .. ".json", encoded) then
        return false, "failed to write theme"
    end
    return true
end

function ThemeManager:Delete(name)
    if not name or self.BuiltInThemes[name] then
        return false, "cannot delete a built-in theme"
    end
    local path = self:GetThemesPath() .. "/" .. name .. ".json"
    if not FileExists(path) then
        return false, "theme not found"
    end
    if DeleteFile(path) then
        return true
    end
    return false, "failed to delete theme"
end

function ThemeManager:SaveDefault(name)
    if not FileAPI then
        return false
    end
    EnsureFolder(self.Folder)
    EnsureFolder(self:GetThemesPath())
    return WriteFile(self:GetThemesPath() .. "/default.txt", name)
end

function ThemeManager:GetDefault()
    if not FileAPI then
        return "Mercury"
    end
    local value = ReadFile(self:GetThemesPath() .. "/default.txt")
    if value and (self.BuiltInThemes[value] or self:GetCustomTheme(value)) then
        return value
    end
    return "Mercury"
end

function ThemeManager:LoadDefault()
    local name = self:GetDefault()
    local ok, err = self:ApplyTheme(name)
    if ok and self.ThemeDropdown then
        self.ThemeDropdown:SetValue(name, true)
    end
    return ok, err
end

function ThemeManager:ReloadCustomThemes()
    local names = self:GetAllThemeNames()
    if self.ThemeDropdown then
        self.ThemeDropdown:SetValues(names)
    end
    return names
end

function ThemeManager:BuildUI(module)
    module.NoSave = true
    self.ThemeModule = module

    for _, field in ipairs(self.ThemeFields) do
        local themeField = field
        local option = module:AddColorPicker(themeField, {
            Text = themeField:gsub("Color", "") .. " color",
            Default = Library[themeField],
        })
        self.ThemeOptions[themeField] = option
        option:OnChanged(function(value)
            Library[themeField] = value
            if not Library._applyingTheme then
                Library:RefreshUI()
            end
        end)
    end

    module:AddDivider()

    local themeDropdown = module:AddDropdown("ThemeList", {
        Text = "Theme",
        Values = self:GetAllThemeNames(),
        Default = self:GetDefault(),
        AllowNull = true,
    })
    self.ThemeDropdown = themeDropdown

    module:AddButton("Apply theme", function()
        local name = themeDropdown.Value
        if not name then
            Library:Notify("Select a theme first", 2)
            return
        end
        local ok, err = self:ApplyTheme(name)
        if ok then
            Library:Notify(('Applied theme "%s"'):format(name))
        else
            Library:Notify("Failed to apply theme: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Set as default theme", function()
        local name = themeDropdown.Value
        if not name then
            Library:Notify("Select a theme first", 2)
            return
        end
        if self:SaveDefault(name) then
            Library:Notify(('Default theme set to "%s"'):format(name))
        else
            Library:Notify("Could not save the default theme (no file access)", 3)
        end
    end)

    module:AddDivider()

    local themeName = module:AddInput("ThemeName", {
        Text = "Theme name",
        Placeholder = "my theme",
    })

    local function refreshThemeList()
        themeDropdown:SetValues(self:GetAllThemeNames())
    end

    module:AddButton("Save custom theme", function()
        local ok, err = self:SaveCustomTheme(themeName.Value)
        if ok then
            refreshThemeList()
            Library:Notify(('Saved theme "%s"'):format(themeName.Value))
        else
            Library:Notify("Failed to save theme: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Delete selected theme", function()
        local ok, err = self:Delete(themeDropdown.Value)
        if ok then
            Library:Notify(('Deleted theme "%s"'):format(themeDropdown.Value))
            refreshThemeList()
        else
            Library:Notify("Failed to delete theme: " .. tostring(err), 3)
        end
    end)

    module:AddDivider()

    local rainbow = module:AddToggle("RainbowAccent", {
        Text = "Rainbow accent",
        Default = false,
    })

    local rainbowConnection
    local lastRainbow = 0
    local function stopRainbow()
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
    end

    rainbow:OnChanged(function(enabled)
        stopRainbow()
        if enabled then
            rainbowConnection = RunService.Heartbeat:Connect(function()
                local now = os.clock()
                if now - lastRainbow < 1 / 30 then
                    return
                end
                lastRainbow = now
                local color = Color3.fromHSV((now * 0.15) % 1, 1, 1)
                local accentOption = self.ThemeOptions.AccentColor
                if accentOption then
                    accentOption:SetValue(color)
                else
                    Library.AccentColor = color
                    Library:RefreshUI()
                end
            end)
        end
    end)

    Library:OnUnload(stopRainbow)

    local defaultName = self:GetDefault()
    self:ApplyTheme(defaultName)
    themeDropdown:SetValue(defaultName, true)
end



local SaveManager = {
    Folder = "Mercury",
    SubFolder = "",
    Library = Library,
    Ignore = {},
    ConfigModule = nil,
    UseLoadingOrder = false,
    LoadingOrder = {},
}

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function SaveManager:SetSubFolder(folder)
    self.SubFolder = folder or ""
    self:BuildFolderTree()
end

function SaveManager:GetSettingsPath()
    local path = self.Folder .. "/settings"
    if self.SubFolder ~= "" then
        path = path .. "/" .. self.SubFolder
    end
    return path
end

function SaveManager:BuildFolderTree()
    if not FileAPI then
        return false
    end
    EnsureFolder(self.Folder)
    EnsureFolder(self.Folder .. "/settings")
    EnsureFolder(self.Folder .. "/themes")
    if self.SubFolder ~= "" then
        EnsureFolder(self:GetSettingsPath())
    end
    return true
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in ipairs(list or {}) do
        self.Ignore[LowerString(key)] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    for _, field in ipairs(ThemeManager.ThemeFields) do
        self.Ignore["theme." .. LowerString(field)] = true
    end
end

function SaveManager:ClearIgnoreIndexes()
    self.Ignore = {}
end

function SaveManager:SetLoadingOrder(enabled, order)
    self.UseLoadingOrder = enabled == true
    if type(order) == "table" then
        self.LoadingOrder = order
    end
end

local function IsIgnoredOption(option)
    local module = option.Module
    if not module then
        return true
    end
    if module.NoSave then
        return true
    end
    if SaveManager.Ignore[module.Name] then
        return true
    end
    if SaveManager.Ignore[module.Name .. "." .. option.ID] then
        return true
    end
    return false
end

function SaveManager:_Collect()
    local objects = {}
    local modules = self.Library._modules

    for _, module in ipairs(modules) do
        if not module.NoSave and not self.Ignore[module.Name] then
            table.insert(objects, {
                type = "Module",
                module = module.Name,
                id = module.Name,
                value = module.Toggle.Value == true,
            })
        end
    end

    for _, option in ipairs(self.Library._allOptions) do
        if not IsIgnoredOption(option) then
            local entry = {
                type = option.Type,
                module = option.Module.Name,
                id = option.ID,
            }
            if option.Type == "ColorPicker" then
                entry.value = ColorToHex(option.Value)
            elseif option.Type == "KeyPicker" then
                entry.value = option.Value
                entry.mode = option.Mode
            else
                entry.value = option.Value
            end
            table.insert(objects, entry)
        end
    end

    return objects
end

function SaveManager:_Apply(objects)
    if type(objects) ~= "table" then
        return false, "invalid config data"
    end

    if self.UseLoadingOrder and type(self.LoadingOrder) == "table" and #self.LoadingOrder > 0 then
        table.sort(objects, function(a, b)
            local aIndex = table.find(self.LoadingOrder, a.type) or math.huge
            local bIndex = table.find(self.LoadingOrder, b.type) or math.huge
            return aIndex < bIndex
        end)
    end

    for _, data in ipairs(objects) do
        if type(data) == "table" and type(data.type) == "string" and type(data.module) == "string" then
            if data.type == "Module" then
                local module = self.Library:GetModule(data.module)
                if module and not module.NoSave then
                    module:SetEnabled(data.value == true)
                end
            else
                local option = self.Library:FindOption(data.module, data.id)
                if option and option.Type == data.type and not IsIgnoredOption(option) then
                    if option.Type == "ColorPicker" then
                        if type(data.value) == "string" then
                            local ok, color = pcall(Color3.fromHex, data.value)
                            if ok then
                                option:SetValue(color)
                            end
                        end
                    elseif option.Type == "KeyPicker" then
                        if type(data.value) == "string" then
                            option:SetValue(data.value)
                        end
                        if type(data.mode) == "string" then
                            option:SetMode(data.mode)
                        end
                    else
                        option:SetValue(data.value)
                    end
                end
            end
        end
    end

    return true
end

function SaveManager:Save(name)
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return false, "invalid config name"
    end
    if not FileAPI then
        return false, "executor has no file access"
    end
    self:BuildFolderTree()

    local data = {
        version = 1,
        objects = self:_Collect(),
    }

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then
        return false, "failed to encode config"
    end
    if not WriteFile(self:GetSettingsPath() .. "/" .. name .. ".json", encoded) then
        return false, "failed to write config"
    end
    return true
end

function SaveManager:Load(name)
    if type(name) ~= "string" or name == "" then
        return false, "no config selected"
    end
    if not FileAPI then
        return false, "executor has no file access"
    end
    local path = self:GetSettingsPath() .. "/" .. name .. ".json"
    if not FileExists(path) then
        return false, "config not found"
    end
    local raw = ReadFile(path)
    if not raw then
        return false, "failed to read config"
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
        return false, "invalid config data"
    end
    return self:_Apply(decoded.objects)
end

function SaveManager:Delete(name)
    if type(name) ~= "string" or name == "" then
        return false, "no config selected"
    end
    if not FileAPI then
        return false, "executor has no file access"
    end
    local path = self:GetSettingsPath() .. "/" .. name .. ".json"
    if not FileExists(path) then
        return false, "config not found"
    end
    if DeleteFile(path) then
        return true
    end
    return false, "failed to delete config"
end

function SaveManager:Export()
    local data = {
        version = 1,
        objects = self:_Collect(),
    }
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then
        return false, "failed to encode config"
    end
    return true, encoded
end

function SaveManager:Import(raw)
    if type(raw) ~= "string" or raw == "" then
        return false, "no config data given"
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
        return false, "invalid config data"
    end
    return self:_Apply(decoded.objects)
end

function SaveManager:RefreshConfigList()
    local out = {}
    if not FileAPI then
        return out
    end
    self:BuildFolderTree()
    local ok, files = pcall(listfiles, self:GetSettingsPath())
    if not ok or type(files) ~= "table" then
        return out
    end
    for _, file in ipairs(files) do
        local base = FileBaseName(file)
        if string.sub(base, -5) == ".json" then
            table.insert(out, string.sub(base, 1, #base - 5))
        end
    end
    table.sort(out)
    return out
end

function SaveManager:GetAutoloadConfig()
    if not FileAPI then
        return "none"
    end
    local value = ReadFile(self:GetSettingsPath() .. "/autoload.txt")
    if value and value ~= "" then
        return value
    end
    return "none"
end

function SaveManager:SaveAutoloadConfig(name)
    if type(name) ~= "string" or name == "" then
        return false, "no config selected"
    end
    if not FileAPI then
        return false, "executor has no file access"
    end
    self:BuildFolderTree()
    if not WriteFile(self:GetSettingsPath() .. "/autoload.txt", name) then
        return false, "failed to save autoload"
    end
    return true
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if name == "none" then
        return false
    end
    local ok, err = self:Load(name)
    if ok then
        Library:Notify(('Autoloaded config "%s"'):format(name))
    else
        Library:Notify("Autoload failed: " .. tostring(err), 4)
    end
    return ok, err
end

function SaveManager:DeleteAutoLoadConfig()
    if not FileAPI then
        return false, "executor has no file access"
    end
    if DeleteFile(self:GetSettingsPath() .. "/autoload.txt") then
        return true
    end
    return false, "failed to delete autoload"
end

function SaveManager:BuildUI(module)
    module.NoSave = true
    self.ConfigModule = module

    local nameInput = module:AddInput("ConfigName", {
        Text = "Config name",
        Placeholder = "my config",
    })

    local configDropdown = module:AddDropdown("ConfigList", {
        Text = "Saved configs",
        Values = self:RefreshConfigList(),
        AllowNull = true,
    })

    local autoloadLabel = module:AddLabel("")

    local function refreshConfigList(select)
        local names = self:RefreshConfigList()
        configDropdown:SetValues(names)
        if select then
            configDropdown:SetValue(select, true)
        end
        autoloadLabel:SetText("Autoload: " .. self:GetAutoloadConfig())
    end
    refreshConfigList()

    local function selectedName()
        return configDropdown.Value
    end

    module:AddButton("Save config", function()
        local name = nameInput.Value
        if type(name) ~= "string" or name:gsub("%s", "") == "" then
            name = selectedName()
        end
        if not name then
            Library:Notify("Enter a config name first", 2)
            return
        end
        local ok, err = self:Save(name)
        if ok then
            refreshConfigList(name)
            Library:Notify(('Saved config "%s"'):format(name))
        else
            Library:Notify("Save failed: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Load selected config", function()
        local name = selectedName()
        if not name then
            Library:Notify("Select a config first", 2)
            return
        end
        local ok, err = self:Load(name)
        if ok then
            Library:Notify(('Loaded config "%s"'):format(name))
        else
            Library:Notify("Load failed: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Delete selected config", function()
        local name = selectedName()
        if not name then
            Library:Notify("Select a config first", 2)
            return
        end
        local ok, err = self:Delete(name)
        if ok then
            Library:Notify(('Deleted config "%s"'):format(name))
            refreshConfigList()
        else
            Library:Notify("Delete failed: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Refresh config list", function()
        refreshConfigList()
        Library:Notify("Config list refreshed", 2)
    end)

    module:AddDivider()

    module:AddButton("Export to clipboard", function()
        local clip = setclipboard or toclipboard
        if type(clip) ~= "function" then
            Library:Notify("Your executor cannot write to the clipboard", 3)
            return
        end
        local ok, encoded = self:Export()
        if not ok then
            Library:Notify("Export failed: " .. tostring(encoded), 3)
            return
        end
        pcall(clip, encoded)
        Library:Notify("Config copied to clipboard")
    end)

    module:AddButton("Import from clipboard", function()
        if type(getclipboard) ~= "function" then
            Library:Notify("Your executor cannot read the clipboard", 3)
            return
        end
        local ok, raw = pcall(getclipboard)
        if not ok or type(raw) ~= "string" or raw == "" then
            Library:Notify("Clipboard is empty or unreadable", 2)
            return
        end
        local success, err = self:Import(raw)
        if success then
            Library:Notify("Config imported from clipboard")
        else
            Library:Notify("Import failed: " .. tostring(err), 3)
        end
    end)

    module:AddDivider()

    module:AddButton("Set selected as autoload", function()
        local name = selectedName()
        if not name then
            Library:Notify("Select a config first", 2)
            return
        end
        local ok, err = self:SaveAutoloadConfig(name)
        if ok then
            autoloadLabel:SetText("Autoload: " .. name)
            Library:Notify(('Autoload set to "%s"'):format(name))
        else
            Library:Notify("Autoload failed: " .. tostring(err), 3)
        end
    end)

    module:AddButton("Clear autoload", function()
        local ok, err = self:DeleteAutoLoadConfig()
        if ok then
            autoloadLabel:SetText("Autoload: none")
            Library:Notify("Autoload cleared")
        else
            Library:Notify("Could not clear autoload: " .. tostring(err), 3)
        end
    end)

    module:AddDivider()
    module:AddLabel(
        "Configs are stored in " .. self.Folder .. "/settings. "
            .. "Call Library.SaveManager:LoadAutoloadConfig() after building your UI."
    )
end

Library.ThemeManager = ThemeManager
Library.SaveManager = SaveManager



function Library:_BuildClientWindow()
    if self.ClientWindow or self._unloaded then
        return
    end

    local window = self:AddWindow("Client", { Width = 210 })
    self.ClientWindow = window
    if self._clientWindowVisible == false then
        window._frame.Visible = false
    end

    local themeModule = window:AddModule("Theme", {
        Tooltip = "Menu colors, built-in themes and custom themes",
    })
    ThemeManager:BuildUI(themeModule)

    local configModule = window:AddModule("Configs", {
        Tooltip = "Save, load and share your configs",
    })
    SaveManager:BuildUI(configModule)

    self:RefreshSearch()
end

task.defer(function()
    Library:_BuildClientWindow()
end)

function Library:SetClientWindowVisible(visible)
    self._clientWindowVisible = visible == true
    if self.ClientWindow then
        self.ClientWindow._frame.Visible = visible == true
    end
end



Library:_BindToggleAction()

local lastOpen = 0

Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    local key = input.KeyCode
    if key == Library.ToggleKeybind then
        Library:_HandleToggleKey()
        return
    end

    if key == Enum.KeyCode.Tab then
        if not Library._visible or Library._popoutModule or Library._keyPicking then
            return
        end
        if Library._query == "" or #Library._searchResults == 0 then
            return
        end
        local now = os.clock()
        if now - lastOpen < 0.15 then
            return
        end
        lastOpen = now
        Library:OpenSelectedResult()
    elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.Up then
        if
            Library._visible
            and not Library._popoutModule
            and Library._query ~= ""
            and #Library._searchResults > 0
            and (searchBox:IsFocused() or resultsFrame.Visible)
        then
            Library:SelectSearch(key == Enum.KeyCode.Down and 1 or -1)
        end
    elseif key == Enum.KeyCode.Return then
        if
            Library._visible
            and not Library._popoutModule
            and Library._query ~= ""
            and #Library._searchResults > 0
            and searchBox:IsFocused()
        then
            local now = os.clock()
            if now - lastOpen < 0.15 then
                return
            end
            lastOpen = now
            Library:OpenSelectedResult()
        end
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and tooltipFrame.Visible then
        local mouse = UserInputService:GetMouseLocation()
        tooltipFrame.Position = UDim2.fromOffset(mouse.X + 16, mouse.Y + 18)
    end
end)

Connect(searchBox:GetPropertyChangedSignal("Text"), function()
    Library:RefreshSearch()
end)

Connect(searchBox.Focused, function()
    Tween(searchStroke, { Color = Library.AccentColor, Transparency = 0.05 }, 0.12)
end)

Connect(searchBox.FocusLost, function(enterPressed)
    Tween(searchStroke, { Color = Library.OutlineColor, Transparency = 0.35 }, 0.12)
    if enterPressed and Library._visible and not Library._popoutModule then
        if Library._query ~= "" and #Library._searchResults > 0 then
            local now = os.clock()
            if now - lastOpen >= 0.15 then
                lastOpen = now
                Library:OpenSelectedResult()
            end
        end
    end
end)

SetPlayerListEnabled(false)



function Library:Unload()
    if self._unloaded then
        return
    end
    self._unloaded = true

    for _, callback in ipairs(self._unloadCallbacks) do
        SafeCallback(callback)
    end

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    SetPlayerListEnabled(originalPlayerList)

    if self._toggleActionBound then
        pcall(function()
            ContextActionService:UnbindAction("MercuryToggle")
        end)
        self._toggleActionBound = false
    end

    for _, gui in ipairs({ windowsGui, searchGui, tooltipGui, popoutGui, notifyGui }) do
        pcall(function()
            gui:Destroy()
        end)
    end

    for _, sound in ipairs({ self._hoverSound, self._clickSound }) do
        if sound then
            pcall(function()
                sound:Destroy()
            end)
        end
    end

    pcall(function()
        if getgenv then
            getgenv().Mercury = nil
        end
    end)
end

Library.CreateWindow = Library.AddWindow

if getgenv then
    pcall(function()
        getgenv().Mercury = Library
    end)
end

return Library
