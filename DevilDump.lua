--[[
    ============================================================
                     SCRIPT DEVIL DUMP
                 Standalone Client Inspector
    ============================================================

    Output:
      Delta/Workspace/DevilDump/
        DevilDump_<PlaceId>_<timestamp>.txt

    Features:
      - Responsive mobile / tablet / PC GUI
      - Workspace hierarchy
      - ReplicatedStorage
      - ReplicatedFirst
      - PlayerGui
      - PlayerScripts
      - Backpack
      - Character
      - Lighting
      - SoundService
      - LocalScript / ModuleScript inventory
      - RemoteEvent / RemoteFunction inventory
      - BindableEvent / BindableFunction inventory
      - Attributes
      - CollectionService tags
      - Common readable properties
      - File write + read-back verification

    NOTE:
      This inspects data actually visible to the client.
      Server-only scripts/state are not available from a client.
--]]

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer

if not Player then
    warn("[DEVIL] LocalPlayer unavailable")
    return
end

local PlayerGui = Player:WaitForChild("PlayerGui", 10)

if not PlayerGui then
    warn("[DEVIL] PlayerGui unavailable")
    return
end

--==============================================================
-- REMOVE OLD GUI
--==============================================================

local OLD_NAME = "SCRIPT_DEVIL_DUMP"

local old = PlayerGui:FindFirstChild(OLD_NAME)

if old then
    old:Destroy()
end

--==============================================================
-- CONFIG
--==============================================================

local CONFIG = {
    BaseWidth = 680,
    BaseHeight = 430,

    ScreenPaddingX = 30,
    ScreenPaddingY = 30,

    MaxScale = 1,
    MinScale = 0.28,

    MaxInstances = 100000,
    MaxDepth = 100,

    OutputFolder = "DevilDump",

    ToggleKey = Enum.KeyCode.RightShift,
}

--==============================================================
-- THEME
--==============================================================

local COLOR = {
    Background = Color3.fromRGB(5, 6, 10),

    Surface = Color3.fromRGB(10, 12, 18),
    Surface2 = Color3.fromRGB(14, 16, 24),
    Surface3 = Color3.fromRGB(19, 21, 31),

    Border = Color3.fromRGB(37, 41, 55),

    Text = Color3.fromRGB(242, 244, 250),
    Muted = Color3.fromRGB(128, 135, 157),

    Purple = Color3.fromRGB(110, 78, 255),
    Blue = Color3.fromRGB(62, 133, 255),

    Green = Color3.fromRGB(62, 218, 151),
    Yellow = Color3.fromRGB(255, 192, 86),
    Red = Color3.fromRGB(255, 76, 104),
}

--==============================================================
-- HELPERS
--==============================================================

local function newCorner(object, radius)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius or 10)
    ui.Parent = object
    return ui
end

local function newStroke(object, color, transparency, thickness)
    local ui = Instance.new("UIStroke")

    ui.Color = color or COLOR.Border
    ui.Transparency = transparency or 0
    ui.Thickness = thickness or 1

    ui.Parent = object

    return ui
end

local function newGradient(object, a, b, rotation)
    local ui = Instance.new("UIGradient")

    ui.Color = ColorSequence.new(a, b)
    ui.Rotation = rotation or 0

    ui.Parent = object

    return ui
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()

    return animation
end

local function safeCall(callback, fallback)
    local success, result = pcall(callback)

    if success then
        return result
    end

    return fallback
end

local function safeString(value)
    return safeCall(function()
        return tostring(value)
    end, "<unreadable>")
end

local function getPath(object)
    return safeCall(function()
        return object:GetFullName()
    end, object.Name)
end

--==============================================================
-- SCREEN GUI
--==============================================================

local Gui = Instance.new("ScreenGui")

Gui.Name = OLD_NAME
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder = 99999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Gui.Parent = PlayerGui

--==============================================================
-- MAIN WINDOW
--==============================================================

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)

Main.Size = UDim2.fromOffset(
    CONFIG.BaseWidth,
    CONFIG.BaseHeight
)

Main.BackgroundColor3 = COLOR.Background
Main.BorderSizePixel = 0

Main.Parent = Gui

newCorner(Main, 18)
newStroke(Main, COLOR.Border, 0.15, 1)

local Scale = Instance.new("UIScale")

Scale.Name = "ResponsiveScale"
Scale.Scale = 1
Scale.Parent = Main

--==============================================================
-- RESPONSIVE ENGINE
--==============================================================

local cameraConnection

local function updateScale()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local availableWidth =
        math.max(
            viewport.X - CONFIG.ScreenPaddingX * 2,
            100
        )

    local availableHeight =
        math.max(
            viewport.Y - CONFIG.ScreenPaddingY * 2,
            100
        )

    local widthScale =
        availableWidth / CONFIG.BaseWidth

    local heightScale =
        availableHeight / CONFIG.BaseHeight

    local finalScale =
        math.min(
            widthScale,
            heightScale,
            CONFIG.MaxScale
        )

    -- extra room for mobile CoreGui
    if UserInputService.TouchEnabled
        and viewport.X > viewport.Y then

        finalScale *= 0.92
    end

    Scale.Scale = math.clamp(
        finalScale,
        CONFIG.MinScale,
        CONFIG.MaxScale
    )

    Main.Position = UDim2.fromScale(0.5, 0.5)
end

local function bindCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    local camera = workspace.CurrentCamera

    if camera then
        cameraConnection =
            camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(updateScale)
    end

    updateScale()
end

bindCamera()

workspace:GetPropertyChangedSignal("CurrentCamera")
    :Connect(bindCamera)

--==============================================================
-- HEADER
--==============================================================

local Header = Instance.new("Frame")

Header.Size = UDim2.new(1, 0, 0, 72)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

--==============================================================
-- LOGO
--==============================================================

local Logo = Instance.new("Frame")

Logo.Size = UDim2.fromOffset(42, 42)
Logo.Position = UDim2.fromOffset(20, 15)

Logo.BackgroundColor3 = COLOR.Purple
Logo.BorderSizePixel = 0

Logo.Parent = Header

newCorner(Logo, 12)
newGradient(Logo, COLOR.Purple, COLOR.Blue, 45)

local LogoText = Instance.new("TextLabel")

LogoText.Size = UDim2.fromScale(1, 1)
LogoText.BackgroundTransparency = 1

LogoText.Text = "D"
LogoText.TextColor3 = Color3.new(1, 1, 1)

LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 22

LogoText.Parent = Logo

--==============================================================
-- TITLE
--==============================================================

local Title = Instance.new("TextLabel")

Title.Position = UDim2.fromOffset(76, 12)
Title.Size = UDim2.new(1, -170, 0, 30)

Title.BackgroundTransparency = 1

Title.Text = "SCRIPT DEVIL DUMP"
Title.TextColor3 = COLOR.Text

Title.Font = Enum.Font.GothamBold
Title.TextSize = 19

Title.TextXAlignment = Enum.TextXAlignment.Left

Title.Parent = Header

local Subtitle = Instance.new("TextLabel")

Subtitle.Position = UDim2.fromOffset(77, 40)
Subtitle.Size = UDim2.new(1, -170, 0, 18)

Subtitle.BackgroundTransparency = 1

Subtitle.Text = "CLIENT INSPECTOR  /  DEVIL CORE"
Subtitle.TextColor3 = COLOR.Muted

Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 9

Subtitle.TextXAlignment = Enum.TextXAlignment.Left

Subtitle.Parent = Header

--==============================================================
-- CLOSE BUTTON
--==============================================================

local Close = Instance.new("TextButton")

Close.AnchorPoint = Vector2.new(1, 0)

Close.Position = UDim2.new(1, -18, 0, 18)
Close.Size = UDim2.fromOffset(34, 34)

Close.BackgroundColor3 = COLOR.Surface2
Close.BorderSizePixel = 0

Close.Text = "×"
Close.TextColor3 = COLOR.Muted

Close.Font = Enum.Font.GothamBold
Close.TextSize = 20

Close.AutoButtonColor = false

Close.Parent = Header

newCorner(Close, 9)
newStroke(Close, COLOR.Border, 0.3, 1)

--==============================================================
-- STATUS
--==============================================================

local StatusCard = Instance.new("Frame")

StatusCard.Position = UDim2.fromOffset(20, 75)
StatusCard.Size = UDim2.new(1, -40, 0, 66)

StatusCard.BackgroundColor3 = COLOR.Surface
StatusCard.BorderSizePixel = 0

StatusCard.Parent = Main

newCorner(StatusCard, 12)
newStroke(StatusCard, COLOR.Border, 0.35, 1)

local StatusDot = Instance.new("Frame")

StatusDot.Size = UDim2.fromOffset(9, 9)
StatusDot.Position = UDim2.fromOffset(17, 18)

StatusDot.BackgroundColor3 = COLOR.Green
StatusDot.BorderSizePixel = 0

StatusDot.Parent = StatusCard

newCorner(StatusDot, 99)

local DotGlow =
    newStroke(
        StatusDot,
        COLOR.Green,
        0.35,
        4
    )

local StatusTitle = Instance.new("TextLabel")

StatusTitle.Position = UDim2.fromOffset(38, 8)
StatusTitle.Size = UDim2.new(1, -55, 0, 23)

StatusTitle.BackgroundTransparency = 1

StatusTitle.Text = "SYSTEM READY"
StatusTitle.TextColor3 = COLOR.Text

StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextSize = 12

StatusTitle.TextXAlignment =
    Enum.TextXAlignment.Left

StatusTitle.Parent = StatusCard

local StatusText = Instance.new("TextLabel")

StatusText.Position = UDim2.fromOffset(38, 32)
StatusText.Size = UDim2.new(1, -55, 0, 19)

StatusText.BackgroundTransparency = 1

StatusText.Text = "Ready to scan client hierarchy"
StatusText.TextColor3 = COLOR.Muted

StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 10

StatusText.TextXAlignment =
    Enum.TextXAlignment.Left

StatusText.TextTruncate =
    Enum.TextTruncate.AtEnd

StatusText.Parent = StatusCard

--==============================================================
-- PROGRESS
--==============================================================

local ProgressBackground = Instance.new("Frame")

ProgressBackground.Position =
    UDim2.new(0, 16, 1, -8)

ProgressBackground.Size =
    UDim2.new(1, -32, 0, 3)

ProgressBackground.BackgroundColor3 =
    Color3.fromRGB(30, 33, 44)

ProgressBackground.BorderSizePixel = 0
ProgressBackground.Parent = StatusCard

newCorner(ProgressBackground, 99)

local Progress = Instance.new("Frame")

Progress.Size = UDim2.new(0, 0, 1, 0)
Progress.BackgroundColor3 = COLOR.Purple
Progress.BorderSizePixel = 0

Progress.Parent = ProgressBackground

newCorner(Progress, 99)
newGradient(Progress, COLOR.Purple, COLOR.Blue, 0)

--==============================================================
-- STAT CARDS
--==============================================================

local StatsHolder = Instance.new("Frame")

StatsHolder.Position = UDim2.fromOffset(20, 154)
StatsHolder.Size = UDim2.new(1, -40, 0, 75)

StatsHolder.BackgroundTransparency = 1
StatsHolder.Parent = Main

local StatsLayout = Instance.new("UIListLayout")

StatsLayout.FillDirection =
    Enum.FillDirection.Horizontal

StatsLayout.Padding = UDim.new(0, 8)

StatsLayout.Parent = StatsHolder

local function createStat(name)
    local Card = Instance.new("Frame")

    Card.Size = UDim2.new(0.25, -6, 1, 0)

    Card.BackgroundColor3 = COLOR.Surface
    Card.BorderSizePixel = 0

    Card.Parent = StatsHolder

    newCorner(Card, 11)
    newStroke(Card, COLOR.Border, 0.4, 1)

    local Value = Instance.new("TextLabel")

    Value.Position = UDim2.fromOffset(13, 11)
    Value.Size = UDim2.new(1, -26, 0, 28)

    Value.BackgroundTransparency = 1

    Value.Text = "0"
    Value.TextColor3 = COLOR.Text

    Value.Font = Enum.Font.GothamBold
    Value.TextSize = 18

    Value.TextXAlignment =
        Enum.TextXAlignment.Left

    Value.Parent = Card

    local Label = Instance.new("TextLabel")

    Label.Position = UDim2.fromOffset(13, 43)
    Label.Size = UDim2.new(1, -26, 0, 17)

    Label.BackgroundTransparency = 1

    Label.Text = name
    Label.TextColor3 = COLOR.Muted

    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 9

    Label.TextXAlignment =
        Enum.TextXAlignment.Left

    Label.Parent = Card

    return Value
end

local InstancesValue = createStat("INSTANCES")
local ScriptsValue = createStat("SCRIPTS")
local RemotesValue = createStat("REMOTES")
local FileValue = createStat("OUTPUT")

FileValue.Text = "READY"

--==============================================================
-- CONSOLE
--==============================================================

local ConsoleFrame = Instance.new("Frame")

ConsoleFrame.Position = UDim2.fromOffset(20, 242)
ConsoleFrame.Size = UDim2.new(1, -40, 0, 105)

ConsoleFrame.BackgroundColor3 =
    Color3.fromRGB(7, 8, 12)

ConsoleFrame.BorderSizePixel = 0

ConsoleFrame.Parent = Main

newCorner(ConsoleFrame, 11)
newStroke(ConsoleFrame, COLOR.Border, 0.4, 1)

local ConsoleTitle = Instance.new("TextLabel")

ConsoleTitle.Position = UDim2.fromOffset(13, 8)
ConsoleTitle.Size = UDim2.new(1, -26, 0, 15)

ConsoleTitle.BackgroundTransparency = 1

ConsoleTitle.Text = "DEVIL CONSOLE"
ConsoleTitle.TextColor3 = COLOR.Muted

ConsoleTitle.Font = Enum.Font.GothamBold
ConsoleTitle.TextSize = 8

ConsoleTitle.TextXAlignment =
    Enum.TextXAlignment.Left

ConsoleTitle.Parent = ConsoleFrame

local Console = Instance.new("TextLabel")

Console.Position = UDim2.fromOffset(13, 28)
Console.Size = UDim2.new(1, -26, 1, -35)

Console.BackgroundTransparency = 1

Console.Text =
[[> Devil Core initialized
> File writer detected
> Awaiting operation...]]

Console.TextColor3 =
    Color3.fromRGB(150, 157, 180)

Console.Font = Enum.Font.Code
Console.TextSize = 10

Console.TextXAlignment =
    Enum.TextXAlignment.Left

Console.TextYAlignment =
    Enum.TextYAlignment.Top

Console.TextWrapped = true

Console.Parent = ConsoleFrame

--==============================================================
-- DUMP BUTTON
--==============================================================

local DumpButton = Instance.new("TextButton")

DumpButton.Position = UDim2.fromOffset(20, 362)
DumpButton.Size = UDim2.new(1, -40, 0, 48)

DumpButton.BackgroundColor3 = COLOR.Purple
DumpButton.BorderSizePixel = 0

DumpButton.Text = "START DEVIL DUMP"
DumpButton.TextColor3 = Color3.new(1, 1, 1)

DumpButton.Font = Enum.Font.GothamBold
DumpButton.TextSize = 12

DumpButton.AutoButtonColor = false

DumpButton.Parent = Main

newCorner(DumpButton, 12)
newGradient(DumpButton, COLOR.Purple, COLOR.Blue, 0)

--==============================================================
-- UI METHODS
--==============================================================

local consoleLines = {
    "> Devil Core initialized",
    "> File writer detected",
    "> Awaiting operation..."
}

local function log(message)
    table.insert(
        consoleLines,
        "> " .. tostring(message)
    )

    while #consoleLines > 5 do
        table.remove(consoleLines, 1)
    end

    Console.Text =
        table.concat(consoleLines, "\n")
end

local function setProgress(value)
    value = math.clamp(value, 0, 1)

    tween(
        Progress,
        0.2,
        {
            Size = UDim2.new(
                value,
                0,
                1,
                0
            )
        }
    )
end

local function setStatus(mode, text)
    if mode == "ready" then
        StatusDot.BackgroundColor3 = COLOR.Green
        DotGlow.Color = COLOR.Green

        StatusTitle.Text = "SYSTEM READY"

    elseif mode == "working" then
        StatusDot.BackgroundColor3 = COLOR.Yellow
        DotGlow.Color = COLOR.Yellow

        StatusTitle.Text = "DUMP IN PROGRESS"

    elseif mode == "success" then
        StatusDot.BackgroundColor3 = COLOR.Green
        DotGlow.Color = COLOR.Green

        StatusTitle.Text = "DUMP COMPLETE"

    elseif mode == "error" then
        StatusDot.BackgroundColor3 = COLOR.Red
        DotGlow.Color = COLOR.Red

        StatusTitle.Text = "DUMP FAILED"
    end

    StatusText.Text = text or ""
end

--==============================================================
-- DRAG
--==============================================================

local dragging = false
local dragStart
local startPosition
local dragInput

Header.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true

        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseMovement
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or input ~= dragInput then
        return
    end

    local delta =
        input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,

        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==============================================================
-- OUTPUT DATA
--==============================================================

local Lines = {}

local Stats = {
    Instances = 0,

    Scripts = 0,
    LocalScripts = 0,
    ModuleScripts = 0,

    RemoteEvents = 0,
    RemoteFunctions = 0,

    BindableEvents = 0,
    BindableFunctions = 0,
}

local function resetDump()
    table.clear(Lines)

    for key in pairs(Stats) do
        Stats[key] = 0
    end

    InstancesValue.Text = "0"
    ScriptsValue.Text = "0"
    RemotesValue.Text = "0"
    FileValue.Text = "WAIT"

    setProgress(0)
end

local function addLine(text)
    Lines[#Lines + 1] = tostring(text)
end

local function addSection(title)
    addLine("")
    addLine(("="):rep(78))
    addLine(" " .. title)
    addLine(("="):rep(78))
end

--==============================================================
-- SERIALIZER
--==============================================================

local function serialize(value, depth)
    depth = depth or 0

    if depth > 4 then
        return "<max-depth>"
    end

    local valueType = typeof(value)

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType == "number"
        or valueType == "boolean"
        or valueType == "nil" then

        return tostring(value)
    end

    if valueType == "Instance" then
        return "<Instance:" .. getPath(value) .. ">"
    end

    if valueType == "table" then
        local result = {}
        local count = 0

        for key, item in pairs(value) do
            count += 1

            if count > 80 then
                result[#result + 1] = "..."
                break
            end

            result[#result + 1] =
                "[" ..
                serialize(key, depth + 1) ..
                "]=" ..
                serialize(item, depth + 1)
        end

        return "{" ..
            table.concat(result, ", ") ..
            "}"
    end

    return safeString(value)
end

--==============================================================
-- ATTRIBUTES
--==============================================================

local function dumpAttributes(object, indent)
    local attributes =
        safeCall(function()
            return object:GetAttributes()
        end, {})

    if not next(attributes) then
        return
    end

    addLine(indent .. "Attributes:")

    for name, value in pairs(attributes) do
        addLine(
            indent ..
            "  @" ..
            tostring(name) ..
            " = " ..
            serialize(value)
        )
    end
end

--==============================================================
-- TAGS
--==============================================================

local function dumpTags(object, indent)
    local tags =
        safeCall(function()
            return CollectionService:GetTags(object)
        end, {})

    if #tags == 0 then
        return
    end

    addLine(
        indent ..
        "Tags = [" ..
        table.concat(tags, ", ") ..
        "]"
    )
end

--==============================================================
-- SAFE PROPERTY READER
--==============================================================

local function property(object, name, indent)
    local success, value =
        pcall(function()
            return object[name]
        end)

    if not success or value == nil then
        return
    end

    addLine(
        indent ..
        name ..
        " = " ..
        serialize(value)
    )
end

local function dumpProperties(object, indent)
    property(object, "Archivable", indent)

    if object:IsA("BasePart") then
        property(object, "Position", indent)
        property(object, "Size", indent)
        property(object, "CFrame", indent)
        property(object, "Anchored", indent)
        property(object, "CanCollide", indent)
        property(object, "CanTouch", indent)
        property(object, "CanQuery", indent)
        property(object, "Transparency", indent)
        property(object, "Color", indent)
        property(object, "Material", indent)
    end

    if object:IsA("Humanoid") then
        property(object, "Health", indent)
        property(object, "MaxHealth", indent)
        property(object, "WalkSpeed", indent)
        property(object, "JumpPower", indent)
        property(object, "HipHeight", indent)
        property(object, "RigType", indent)
    end

    if object:IsA("GuiObject") then
        property(object, "Visible", indent)
        property(object, "Position", indent)
        property(object, "Size", indent)
        property(object, "Rotation", indent)
        property(object, "ZIndex", indent)
    end

    if object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox") then

        property(object, "Text", indent)
        property(object, "TextSize", indent)
    end

    if object:IsA("ImageLabel")
        or object:IsA("ImageButton") then

        property(object, "Image", indent)
    end

    if object:IsA("Sound") then
        property(object, "SoundId", indent)
        property(object, "Volume", indent)
        property(object, "PlaybackSpeed", indent)
        property(object, "Looped", indent)
    end

    if object:IsA("Animation") then
        property(object, "AnimationId", indent)
    end

    if object:IsA("ValueBase") then
        property(object, "Value", indent)
    end
end

--==============================================================
-- SPECIAL INSTANCE TYPES
--==============================================================

local function inspectSpecial(object, indent)
    if object:IsA("LocalScript") then
        Stats.Scripts += 1
        Stats.LocalScripts += 1

        addLine(indent .. "Type = LocalScript")

        local source =
            safeCall(function()
                return object.Source
            end, nil)

        if source and source ~= "" then
            addLine(indent .. "Source:")
            addLine(source)
        else
            addLine(
                indent ..
                "Source = <not exposed to this client context>"
            )
        end

    elseif object:IsA("ModuleScript") then
        Stats.Scripts += 1
        Stats.ModuleScripts += 1

        addLine(indent .. "Type = ModuleScript")

        local source =
            safeCall(function()
                return object.Source
            end, nil)

        if source and source ~= "" then
            addLine(indent .. "Source:")
            addLine(source)
        else
            addLine(
                indent ..
                "Source = <not exposed to this client context>"
            )
        end

    elseif object:IsA("RemoteEvent") then
        Stats.RemoteEvents += 1

        addLine(indent .. "Type = RemoteEvent")

    elseif object:IsA("RemoteFunction") then
        Stats.RemoteFunctions += 1

        addLine(indent .. "Type = RemoteFunction")

    elseif object:IsA("BindableEvent") then
        Stats.BindableEvents += 1

        addLine(indent .. "Type = BindableEvent")

    elseif object:IsA("BindableFunction") then
        Stats.BindableFunctions += 1

        addLine(indent .. "Type = BindableFunction")
    end
end

--==============================================================
-- INSTANCE WALKER
--==============================================================

local function dumpInstance(object, depth)
    if Stats.Instances >= CONFIG.MaxInstances then
        return
    end

    if depth > CONFIG.MaxDepth then
        return
    end

    Stats.Instances += 1

    local indent =
        string.rep("  ", depth)

    addLine("")
    addLine(
        indent ..
        "[" ..
        object.ClassName ..
        "] " ..
        object.Name
    )

    addLine(
        indent ..
        "Path = " ..
        getPath(object)
    )

    inspectSpecial(
        object,
        indent .. "  "
    )

    dumpAttributes(
        object,
        indent .. "  "
    )

    dumpTags(
        object,
        indent .. "  "
    )

    dumpProperties(
        object,
        indent .. "  "
    )

    local children =
        safeCall(function()
            return object:GetChildren()
        end, {})

    for _, child in ipairs(children) do
        if Stats.Instances >= CONFIG.MaxInstances then
            break
        end

        dumpInstance(
            child,
            depth + 1
        )

        if Stats.Instances % 250 == 0 then
            InstancesValue.Text =
                tostring(Stats.Instances)

            ScriptsValue.Text =
                tostring(Stats.Scripts)

            RemotesValue.Text =
                tostring(
                    Stats.RemoteEvents +
                    Stats.RemoteFunctions
                )

            task.wait()
        end
    end
end

local function dumpRoot(title, root)
    if not root then
        return
    end

    addSection(title)

    log("Scanning " .. title)

    dumpInstance(root, 0)
end

--==============================================================
-- HEADER DATA
--==============================================================

local function buildDumpHeader()
    addSection("SCRIPT DEVIL DUMP")

    addLine(
        "PlaceId = " ..
        tostring(game.PlaceId)
    )

    addLine(
        "GameId = " ..
        tostring(game.GameId)
    )

    addLine(
        "JobId = " ..
        tostring(game.JobId)
    )

    addLine(
        "PlaceVersion = " ..
        tostring(game.PlaceVersion)
    )

    addLine(
        "Player = " ..
        Player.Name
    )

    addLine(
        "UserId = " ..
        tostring(Player.UserId)
    )

    addLine(
        "Generated = " ..
        os.date("%Y-%m-%d %H:%M:%S")
    )
end

--==============================================================
-- SUMMARY
--==============================================================

local function buildSummary()
    addSection("SUMMARY")

    addLine(
        "Instances = " ..
        tostring(Stats.Instances)
    )

    addLine(
        "Scripts = " ..
        tostring(Stats.Scripts)
    )

    addLine(
        "LocalScripts = " ..
        tostring(Stats.LocalScripts)
    )

    addLine(
        "ModuleScripts = " ..
        tostring(Stats.ModuleScripts)
    )

    addLine(
        "RemoteEvents = " ..
        tostring(Stats.RemoteEvents)
    )

    addLine(
        "RemoteFunctions = " ..
        tostring(Stats.RemoteFunctions)
    )

    addLine(
        "BindableEvents = " ..
        tostring(Stats.BindableEvents)
    )

    addLine(
        "BindableFunctions = " ..
        tostring(Stats.BindableFunctions)
    )

    addSection("END")
end

--==============================================================
-- FILE SYSTEM
--==============================================================

local function ensureFolder()
    if type(makefolder) ~= "function" then
        return false
    end

    if type(isfolder) == "function" then
        local success, exists =
            pcall(function()
                return isfolder(
                    CONFIG.OutputFolder
                )
            end)

        if success and exists then
            return true
        end
    end

    local success =
        pcall(function()
            makefolder(
                CONFIG.OutputFolder
            )
        end)

    return success
end

local function saveDump()
    if type(writefile) ~= "function" then
        return false, nil,
            "writefile() unavailable"
    end

    if #Lines == 0 then
        return false, nil,
            "Dump output is empty"
    end

    ensureFolder()

    local fileName =
        "DevilDump_" ..
        tostring(game.PlaceId) ..
        "_" ..
        tostring(os.time()) ..
        ".txt"

    local path

    if type(isfolder) == "function"
        and safeCall(function()
            return isfolder(
                CONFIG.OutputFolder
            )
        end, false) then

        path =
            CONFIG.OutputFolder ..
            "/" ..
            fileName
    else
        -- fallback:
        -- Delta/Workspace/DevilDump_xxx.txt
        path = fileName
    end

    local output =
        table.concat(Lines, "\n")

    local success, err =
        pcall(function()
            writefile(path, output)
        end)

    if not success then
        return false, path, tostring(err)
    end

    --==========================================================
    -- VERIFY EXISTS
    --==========================================================

    if type(isfile) == "function" then
        local checkSuccess, exists =
            pcall(function()
                return isfile(path)
            end)

        if checkSuccess and not exists then
            return false, path,
                "File missing after writefile()"
        end
    end

    --==========================================================
    -- VERIFY READBACK
    --==========================================================

    if type(readfile) == "function" then
        local readSuccess, content =
            pcall(function()
                return readfile(path)
            end)

        if not readSuccess then
            return false, path,
                "readfile verification failed"
        end

        if type(content) ~= "string"
            or #content == 0 then

            return false, path,
                "Saved file is empty"
        end
    end

    return true, path, nil
end

--==============================================================
-- EXECUTE DUMP
--==============================================================

local Dumping = false

local function executeDump()
    resetDump()

    buildDumpHeader()

    setStatus(
        "working",
        "Scanning Workspace..."
    )

    setProgress(0.05)

    --==========================================================
    -- WORKSPACE
    --==========================================================

    dumpRoot(
        "WORKSPACE / MAP",
        workspace
    )

    setProgress(0.30)

    --==========================================================
    -- REPLICATED STORAGE
    --==========================================================

    setStatus(
        "working",
        "Scanning ReplicatedStorage..."
    )

    dumpRoot(
        "REPLICATED STORAGE",
        ReplicatedStorage
    )

    setProgress(0.48)

    --==========================================================
    -- REPLICATED FIRST
    --==========================================================

    dumpRoot(
        "REPLICATED FIRST",
        ReplicatedFirst
    )

    setProgress(0.58)

    --==========================================================
    -- PLAYER GUI
    --==========================================================

    setStatus(
        "working",
        "Scanning PlayerGui..."
    )

    dumpRoot(
        "PLAYER GUI",
        PlayerGui
    )

    setProgress(0.68)

    --==========================================================
    -- PLAYER SCRIPTS
    --==========================================================

    dumpRoot(
        "PLAYER SCRIPTS",
        Player:FindFirstChild(
            "PlayerScripts"
        )
    )

    setProgress(0.75)

    --==========================================================
    -- BACKPACK
    --==========================================================

    dumpRoot(
        "BACKPACK",
        Player:FindFirstChildOfClass(
            "Backpack"
        )
    )

    --==========================================================
    -- CHARACTER
    --==========================================================

    dumpRoot(
        "CHARACTER",
        Player.Character
    )

    setProgress(0.83)

    --==========================================================
    -- LIGHTING / SOUND
    --==========================================================

    dumpRoot(
        "LIGHTING",
        Lighting
    )

    dumpRoot(
        "SOUND SERVICE",
        SoundService
    )

    setProgress(0.90)

    --==========================================================
    -- SUMMARY
    --==========================================================

    buildSummary()

    InstancesValue.Text =
        tostring(Stats.Instances)

    ScriptsValue.Text =
        tostring(Stats.Scripts)

    RemotesValue.Text =
        tostring(
            Stats.RemoteEvents +
            Stats.RemoteFunctions
        )

    --==========================================================
    -- SAVE
    --==========================================================

    setStatus(
        "working",
        "Writing output file..."
    )

    FileValue.Text = "WRITE"

    log("Writing dump file")

    setProgress(0.95)

    local success, path, errorMessage =
        saveDump()

    if not success then
        FileValue.Text = "ERROR"

        setStatus(
            "error",
            tostring(errorMessage)
        )

        log(
            "SAVE ERROR: " ..
            tostring(errorMessage)
        )

        warn(
            "[DEVIL DUMP]",
            errorMessage
        )

        return false
    end

    FileValue.Text = "SAVED"

    setProgress(1)

    setStatus(
        "success",
        "Saved: " .. tostring(path)
    )

    log(
        "Saved: " ..
        tostring(path)
    )

    print(
        "[DEVIL DUMP] SAVED:",
        path
    )

    return true
end

--==============================================================
-- BUTTON
--==============================================================

DumpButton.MouseButton1Click:Connect(function()
    if Dumping then
        return
    end

    Dumping = true

    DumpButton.Text =
        "SCANNING..."

    local success, result =
        pcall(executeDump)

    if not success then
        FileValue.Text = "ERROR"

        setStatus(
            "error",
            tostring(result)
        )

        log(
            "FATAL: " ..
            tostring(result)
        )

        warn(
            "[DEVIL DUMP] FATAL:",
            result
        )
    end

    Dumping = false

    if success and result then
        DumpButton.Text =
            "DUMP SAVED"
    else
        DumpButton.Text =
            "DUMP FAILED"
    end

    task.delay(2, function()
        if not Dumping
            and DumpButton.Parent then

            DumpButton.Text =
                "START DEVIL DUMP"
        end
    end)
end)

--==============================================================
-- CLOSE / REOPEN
--==============================================================

local OpenButton = Instance.new("TextButton")

OpenButton.AnchorPoint =
    Vector2.new(1, 1)

OpenButton.Position =
    UDim2.new(
        1,
        -20,
        1,
        -20
    )

OpenButton.Size =
    UDim2.fromOffset(
        50,
        50
    )

OpenButton.BackgroundColor3 =
    COLOR.Purple

OpenButton.BorderSizePixel = 0

OpenButton.Text = "D"

OpenButton.TextColor3 =
    Color3.new(1, 1, 1)

OpenButton.Font =
    Enum.Font.GothamBlack

OpenButton.TextSize = 20

OpenButton.Visible = false

OpenButton.Parent = Gui

newCorner(OpenButton, 14)

newGradient(
    OpenButton,
    COLOR.Purple,
    COLOR.Blue,
    45
)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false

    updateScale()
end)

--==============================================================
-- KEY TOGGLE
--==============================================================

UserInputService.InputBegan:Connect(
    function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == CONFIG.ToggleKey then
            Main.Visible =
                not Main.Visible

            OpenButton.Visible =
                not Main.Visible

            if Main.Visible then
                updateScale()
            end
        end
    end
)

--==============================================================
-- STARTUP
--==============================================================

task.defer(function()
    task.wait(0.15)

    updateScale()

    if type(writefile) == "function" then
        setStatus(
            "ready",
            "File writer detected • Ready to dump"
        )

        log("writefile() available")
    else
        setStatus(
            "error",
            "writefile() unavailable"
        )

        FileValue.Text = "NO API"

        log("writefile() unavailable")
    end
end)

print("[DEVIL] SCRIPT Devil Dump loaded")
