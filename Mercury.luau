local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

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

local SOUND_BASE = "https://raw.githubusercontent.com/tcp25565/mercury/main/assets/"

local function LoadUISound(name, volume)
    if not FileAPI then
        return nil
    end

    local path = "Mercury/assets/" .. name .. ".mp3"
    if not FileExists(path) then
        local downloaded = false
        pcall(function()
            local body = game:HttpGet(SOUND_BASE .. name .. ".mp3")
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

    local sound = Instance.new("Sound")
    sound.Name = "Mercury" .. name
    sound.SoundId = asset
    sound.Volume = volume
    sound.Parent = SoundService
    return sound
end

local Library = {}
Library.Version = "0.1.0"
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


Library.BackgroundColor = Color3.fromRGB(10, 10, 13)
Library.MainColor = Color3.fromRGB(22, 22, 28)
Library.AccentColor = Color3.fromRGB(255, 45, 135)
Library.OutlineColor = Color3.fromRGB(58, 58, 70)
Library.FontColor = Color3.fromRGB(232, 232, 238)

Library._hoverSound = LoadUISound("hover", 0.35)
Library._clickSound = LoadUISound("click", 0.5)

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
    local namespace = self.Options[moduleName]
    return namespace and namespace[id] or nil
end

function Library:GetModule(name)
    return self.ModuleMap[name]
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
    Font = Enum.Font.Code,
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
    Font = Enum.Font.Code,
    Text = "",
    TextSize = 14,
    TextColor3 = Library.FontColor,
    PlaceholderText = "Search modules...",
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
    Font = Enum.Font.Code,
    Text = "",
    TextSize = 12,
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
    Font = Enum.Font.Code,
    Text = "Module",
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
    Font = Enum.Font.Code,
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
    Font = Enum.Font.Code,
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
    Font = Enum.Font.Code,
    Text = "This module has no settings.",
    TextSize = 12,
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
            Font = Enum.Font.Code,
            Text = "No matches",
            TextSize = 12,
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
                Font = Enum.Font.Code,
                Text = resultModule.Name,
                TextSize = 12,
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
                Font = Enum.Font.Code,
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
        module._settings.Parent = hiddenHolder
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
        Text = tostring(description),
        TextSize = 12,
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

function Library:SetToggleKey(keyCode)
    self.ToggleKeybind = keyCode or Enum.KeyCode.RightShift
end



local Module = {}
Module.__index = Module

local Window = {}
Window.__index = Window

function Window:AddModule(name, config)
    if Library.ModuleMap[name] then
        error(("[Mercury] a module named %q already exists"):format(name))
    end

    config = config or {}
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

    
    local row = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Library:GetRowColor(),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._rows,
    })
    local rowStroke = Stroke(row, Library.OutlineColor, 1, 0.8)

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = name,
        TextSize = 12,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    module._row = row
    module._rowLabel = label
    module._rowStroke = rowStroke
    module._hover = false
    module._settings = Create("Frame", {
        Name = "Settings_" .. name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = hiddenHolder,
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
            Library:OpenPopout(module)
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

function Window:_UpdateHeight()
    local count = #self.modules
    local contentHeight = math.max(0, count * 24 + math.max(0, count - 1) * 3)
    local maxHeight = math.min(GetViewport().Y * 0.62, 540)
    local rowsHeight = math.min(contentHeight, maxHeight)
    local sectionHeight = rowsHeight + 2
    self._rows.Size = UDim2.new(1, -2, 0, rowsHeight)
    self._rows.CanvasSize = UDim2.fromOffset(0, contentHeight)
    self._section.Size = UDim2.new(1, -12, 0, sectionHeight)
    local bodyHeight = 30 + sectionHeight + 4
    self._body.Size = UDim2.new(1, -2, 0, bodyHeight)
    self._frame.Size = UDim2.fromOffset(self._width or 190, bodyHeight + 2)
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
    if self.Options[id] then
        error(("[Mercury] duplicate option %q in module %q"):format(id, self.Name))
    end

    config = config or {}
    config.Text = config.Text or id

    local option = Option.new(kind, self, id, config)
    self.Options[id] = option
    table.insert(self._options, option)
    table.insert(Library._allOptions, option)

    if kind == "KeyPicker" then
        option.Mode = config.Mode or "Toggle"
    elseif kind == "Dropdown" then
        option.Multi = config.Multi == true
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

    if enabled then
        row.BackgroundColor3 = Library.AccentColor
        row.BackgroundTransparency = dimmed and 0.6 or 0
        self._rowLabel.TextColor3 = Color3.new(1, 1, 1)
        self._rowLabel.TextTransparency = dimmed and 0.45 or 0
    else
        row.BackgroundColor3 = self._hover and Library:GetRowHoverColor() or Library:GetRowColor()
        row.BackgroundTransparency = dimmed and 0.7 or 0
        self._rowLabel.TextColor3 = dimmed and Library:GetDimColor() or Library.FontColor
        self._rowLabel.TextTransparency = 0
    end
    self._rowStroke.Color = enabled and Library.AccentColor or Library.OutlineColor
    self._rowStroke.Transparency = dimmed and 0.95 or (enabled and 0.7 or 0.85)
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
        Font = Enum.Font.Code,
        Text = config.Text,
        TextSize = 12,
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
        Font = Enum.Font.Code,
        Text = config.Text,
        TextSize = 12,
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
        Text = "",
        TextSize = 12,
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
        Font = Enum.Font.Code,
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
            text = #selected > 0 and table.concat(selected, ", ") or "None"
        else
            text = option.Value ~= nil and tostring(option.Value) or "None"
        end
        buttonLabel.Text = text
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
                Font = Enum.Font.Code,
                Text = itemValue,
                TextSize = 12,
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
        Text = tostring(option.Value or ""),
        TextSize = 12,
        TextColor3 = Library.FontColor,
        PlaceholderText = config.Placeholder or "",
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
        Font = Enum.Font.Code,
        Text = config.Text,
        TextSize = 12,
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
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
        button.Text = tostring(option.Value or "None")
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
        modeLabel.Text = option.Mode or "Toggle"
        if not picking then
            button.Text = tostring(option.Value or "None")
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

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self._settings,
    })
    option._frame = holder

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 26),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = config.Text,
        TextSize = 12,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })
    Library:Bind(label, { TextColor3 = "FontColor" })

    local swatch = Create("TextButton", {
        Size = UDim2.fromOffset(46, 20),
        Position = UDim2.new(1, 0, 0, 3),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = option.Value,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })
    local swatchStroke = Stroke(swatch, Library.OutlineColor, 1, 0.2)
    Library:Bind(swatchStroke, { Color = "OutlineColor" })

    local panel = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 30),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Visible = false,
        Parent = holder,
    })
    local panelStroke = Stroke(panel, Library.OutlineColor, 1, 0.35)
    Library:Bind(panel, { BackgroundColor3 = "BackgroundColor" })
    Library:Bind(panelStroke, { Color = "OutlineColor" })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = panel,
    })

    local palette = Create("Frame", {
        Size = UDim2.new(1, -8, 0, 39),
        Position = UDim2.fromOffset(4, 4),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    Create("UIGridLayout", {
        CellSize = UDim2.fromOffset(26, 18),
        CellPadding = UDim2.fromOffset(3, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = palette,
    })

    local colors = {}
    for hue = 0, 7 do
        table.insert(colors, Color3.fromHSV(hue / 8, 1, 1))
    end
    table.insert(colors, Color3.fromRGB(255, 255, 255))
    table.insert(colors, Color3.fromRGB(200, 200, 205))
    table.insert(colors, Color3.fromRGB(140, 140, 150))
    table.insert(colors, Color3.fromRGB(80, 80, 90))
    table.insert(colors, Color3.fromRGB(40, 40, 48))
    table.insert(colors, Color3.fromRGB(10, 10, 13))
    table.insert(colors, Color3.fromRGB(255, 90, 90))
    table.insert(colors, Color3.fromRGB(255, 190, 70))
    table.insert(colors, Color3.fromRGB(110, 220, 140))
    table.insert(colors, Color3.fromRGB(80, 180, 255))
    table.insert(colors, Color3.fromRGB(140, 130, 255))

    local swatches = {}
    for index, color in ipairs(colors) do
        local swatchColor = color
        local cell = Create("TextButton", {
            Size = UDim2.fromOffset(26, 18),
            BackgroundColor3 = swatchColor,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = index,
            Parent = palette,
        })
        local cellStroke = Stroke(cell, Color3.new(1, 1, 1), 1, 0.75)
        table.insert(swatches, { Cell = cell, Stroke = cellStroke, Color = swatchColor })
        Connect(cell.MouseButton1Click, function()
            Library:PlayClick()
            option:SetValue(swatchColor)
        end)
    end

    local hexBox = Create("TextBox", {
        Size = UDim2.new(1, -8, 0, 24),
        Position = UDim2.fromOffset(4, 48),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        Text = "#" .. option.Value:ToHex(),
        TextSize = 11,
        TextColor3 = Library.FontColor,
        PlaceholderText = "hex color, e.g. ff2d87",
        PlaceholderColor3 = Library:GetDimColor(),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = panel,
    })
    local hexStroke = Stroke(hexBox, Library.OutlineColor, 1, 0.45)
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        Parent = hexBox,
    })
    Library:Bind(hexBox, {
        BackgroundColor3 = "MainColor",
        TextColor3 = "FontColor",
        PlaceholderColor3 = function()
            return Library:GetDimColor()
        end,
    })
    Library:Bind(hexStroke, { Color = "OutlineColor" })

    local function render()
        swatch.BackgroundColor3 = option.Value
        for _, swatchInfo in ipairs(swatches) do
            local selected = swatchInfo.Color == option.Value
            swatchInfo.Stroke.Transparency = selected and 0 or 0.75
            swatchInfo.Stroke.Color = selected and Library.AccentColor or Color3.new(1, 1, 1)
        end
        if not hexBox:IsFocused() then
            hexBox.Text = "#" .. option.Value:ToHex()
        end
    end
    option:_AddRender(render)

    local function applyHex()
        local text = string.gsub(hexBox.Text or "", "#", "")
        local ok, color = pcall(Color3.fromHex, text)
        if ok then
            option:SetValue(color)
        else
            hexBox.Text = "#" .. option.Value:ToHex()
        end
    end

    Connect(hexBox.FocusLost, function(enterPressed)
        if enterPressed then
            applyHex()
        else
            hexBox.Text = "#" .. option.Value:ToHex()
        end
    end)
    Connect(swatch.MouseButton1Click, function()
        Library:PlayClick()
        panel.Visible = not panel.Visible
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

    local text = config.Text or "Button"
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Text = text,
        TextSize = 12,
        Font = Enum.Font.Code,
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

    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = tostring(text),
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

    local object = { Frame = label, Text = tostring(text) }
    function object:SetText(newText)
        self.Text = tostring(newText)
        label.Text = tostring(newText)
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
        Size = UDim2.fromOffset(width, 40),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = windowsHolder,
    })

    local body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -2, 0, 38),
        Position = UDim2.fromOffset(1, 1),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Parent = frame,
    })
    self:Bind(body, { BackgroundColor3 = "MainColor", BorderColor3 = "AccentColor" })

    local title = Create("Frame", {
        Name = "Title",
        Size = UDim2.new(1, -12, 0, 22),
        Position = UDim2.fromOffset(6, 4),
        BackgroundTransparency = 1,
        Parent = body,
    })
    local titleLabel = Create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = name,
        TextSize = 15,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = title,
    })
    self:Bind(titleLabel, { TextColor3 = "FontColor" })

    local section = Create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, -12, 0, 2),
        Position = UDim2.fromOffset(6, 30),
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Parent = body,
    })
    self:Bind(section, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })

    local rows = Create("ScrollingFrame", {
        Name = "Rows",
        Size = UDim2.new(1, -2, 0, 0),
        Position = UDim2.fromOffset(1, 1),
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
    window._rows = rows
    window._width = width

    local dragging = false
    local dragStart
    local startPosition

    Connect(title.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = frame.AbsolutePosition
            Library._frontZ = Library._frontZ + 1
            frame.ZIndex = Library._frontZ
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local viewportNow = GetViewport()
            local newX = math.clamp(startPosition.X + delta.X, -width + 60, viewportNow.X - 60)
            local newY = math.clamp(startPosition.Y + delta.Y, 0, viewportNow.Y - 30)
            frame.Position = UDim2.fromOffset(newX, newY)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
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
        data[field] = color:ToHex()
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
        self.Ignore[key] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    for _, field in ipairs(ThemeManager.ThemeFields) do
        self.Ignore["Theme." .. field] = true
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
                entry.value = option.Value:ToHex()
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



local lastOpen = 0

Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    local key = input.KeyCode
    if key == Library.ToggleKeybind then
        if not Library._keyPicking then
            Library:Toggle()
        end
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
