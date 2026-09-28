--[[
    ================================================================
                         DEVIL DUMP V4
              PREMIUM CLIENT INSPECTOR + REMOTE LIVE
    ================================================================

    FEATURES
      • Full client-visible hierarchy dump
      • RemoteEvent / RemoteFunction index
      • BindableEvent / BindableFunction index
      • LocalScript / ModuleScript metadata
      • Attributes / Tags / Values / GUI / Parts / Tools
      • Premium responsive dashboard
      • Right-side animated toast notifications
      • Live activity console
      • REMOTE LIVE:
          - Logs RemoteEvent.OnClientEvent
          - Logs BindableEvent.Event
          - Watches newly-created remotes
          - Timestamp + path + serialized arguments
          - Does NOT fire/invoke remotes
      • Start / Stop Live controls
      • Full dump progress
      • Live counters
      • File save notification

    OUTPUT
      DevilDump/DevilDump_<PlaceId>_<timestamp>.txt
      DevilDump/RemoteLive_<PlaceId>_<timestamp>.txt
]]

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
if not Player then return end

local PlayerGui = Player:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
--==============================================================

local CONFIG = {
    Folder = "DevilDump",

    GeneralLimit = 120000,
    WorkspaceLimit = 250000,

    MaxDepth = 120,
    YieldEvery = 300,

    DumpSource = true,
    DumpAttributes = true,
    DumpTags = true,
    DumpProperties = true,
    DumpGUI = true,
    DumpWorkspace = true,

    LiveRemoteEvents = true,
    LiveBindableEvents = true,

    MaxLiveEntries = 15000,
    LiveAutoSaveEvery = 50,

    ToggleKey = Enum.KeyCode.RightShift
}

--==============================================================
-- CLEAN OLD GUI
--==============================================================

local old = PlayerGui:FindFirstChild("DEVIL_DUMP_V4")
if old then
    old:Destroy()
end

--==============================================================
-- THEME
--==============================================================

local C = {
    Background = Color3.fromRGB(5, 7, 13),
    Background2 = Color3.fromRGB(8, 11, 20),

    Surface = Color3.fromRGB(12, 16, 28),
    Surface2 = Color3.fromRGB(17, 22, 38),
    Surface3 = Color3.fromRGB(22, 28, 48),

    Border = Color3.fromRGB(48, 61, 91),

    Purple = Color3.fromRGB(126, 87, 255),
    Purple2 = Color3.fromRGB(91, 65, 210),

    Blue = Color3.fromRGB(51, 137, 255),
    Cyan = Color3.fromRGB(54, 218, 255),

    Green = Color3.fromRGB(64, 226, 151),
    Yellow = Color3.fromRGB(255, 198, 73),
    Red = Color3.fromRGB(255, 82, 108),

    Text = Color3.fromRGB(241, 245, 255),
    Muted = Color3.fromRGB(139, 151, 181),
    Muted2 = Color3.fromRGB(91, 103, 132)
}

--==============================================================
-- HELPERS
--==============================================================

local function new(class, props)
    local obj = Instance.new(class)

    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function()
                obj[k] = v
            end)
        end
    end

    if props and props.Parent then
        obj.Parent = props.Parent
    end

    return obj
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = parent
    })
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or C.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function padding(parent, l, r, t, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent = parent
    })
end

local function label(parent, value, pos, size, font, textSize, color)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Position = pos or UDim2.new(),
        Size = size or UDim2.fromOffset(100, 20),

        Text = value or "",
        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 13,
        TextColor3 = color or C.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,

        Parent = parent
    })
end

local function button(parent, textValue, position, size, color)
    local b = new("TextButton", {
        Position = position,
        Size = size,

        AutoButtonColor = false,

        BackgroundColor3 = color or C.Surface2,
        BorderSizePixel = 0,

        Text = textValue,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.Text,

        Parent = parent
    })

    corner(b, 11)

    local s = stroke(b, C.Border, .45, 1)

    b.MouseEnter:Connect(function()
        TweenService:Create(
            b,
            TweenInfo.new(.15),
            {BackgroundColor3 = C.Surface3}
        ):Play()

        TweenService:Create(
            s,
            TweenInfo.new(.15),
            {Transparency = .1}
        ):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(
            b,
            TweenInfo.new(.15),
            {BackgroundColor3 = color or C.Surface2}
        ):Play()

        TweenService:Create(
            s,
            TweenInfo.new(.15),
            {Transparency = .45}
        ):Play()
    end)

    return b
end

local function safePath(object)
    local result = object.Name

    pcall(function()
        result = object:GetFullName()
    end)

    return result
end

--==============================================================
-- SCREEN GUI
--==============================================================

local GUI = new("ScreenGui", {
    Name = "DEVIL_DUMP_V4",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui
})

--==============================================================
-- BACKDROP / MAIN
--==============================================================

local Shadow = new("Frame", {
    AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.new(.5, 0, .5, 8),
    Size = UDim2.fromOffset(860, 540),

    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = .45,
    BorderSizePixel = 0,

    Parent = GUI
})

corner(Shadow, 24)

local Main = new("Frame", {
    Name = "Main",

    AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5),
    Size = UDim2.fromOffset(860, 540),

    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,

    ClipsDescendants = true,

    Parent = GUI
})

corner(Main, 22)

local MainStroke = stroke(Main, C.Purple, .40, 1.2)

local Scale = new("UIScale", {
    Scale = 1,
    Parent = Main
})

local ShadowScale = new("UIScale", {
    Scale = 1,
    Parent = Shadow
})

--==============================================================
-- TOP GLOW
--==============================================================

local TopGlow = new("Frame", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 3),

    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,

    Parent = Main
})

local GlowGradient = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Blue),
        ColorSequenceKeypoint.new(.5, C.Purple),
        ColorSequenceKeypoint.new(1, C.Cyan)
    }),

    Parent = TopGlow
})

--==============================================================
-- RESPONSIVE
--==============================================================

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    local sx = (viewport.X - 24) / 860
    local sy = (viewport.Y - 24) / 540

    local result = math.min(sx, sy, 1)

    if UserInputService.TouchEnabled then
        result *= .95
    end

    result = math.clamp(result, .30, 1)

    Scale.Scale = result
    ShadowScale.Scale = result
end

updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera
        :GetPropertyChangedSignal("ViewportSize")
        :Connect(updateScale)
end

--==============================================================
-- SIDEBAR
--==============================================================

local Sidebar = new("Frame", {
    Position = UDim2.fromOffset(0, 3),
    Size = UDim2.new(0, 190, 1, -3),

    BackgroundColor3 = C.Background2,
    BorderSizePixel = 0,

    Parent = Main
})

local SidebarLine = new("Frame", {
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),

    BackgroundColor3 = C.Border,
    BackgroundTransparency = .55,
    BorderSizePixel = 0,

    Parent = Sidebar
})

--==============================================================
-- BRAND
--==============================================================

local Logo = new("Frame", {
    Position = UDim2.fromOffset(18, 20),
    Size = UDim2.fromOffset(42, 42),

    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,

    Parent = Sidebar
})

corner(Logo, 13)

new("UIGradient", {
    Rotation = 45,

    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Purple),
        ColorSequenceKeypoint.new(1, C.Blue)
    }),

    Parent = Logo
})

local LogoText = label(
    Logo,
    "D",
    UDim2.new(),
    UDim2.fromScale(1, 1),
    Enum.Font.GothamBlack,
    21,
    Color3.new(1, 1, 1)
)

LogoText.TextXAlignment = Enum.TextXAlignment.Center

label(
    Sidebar,
    "DEVIL DUMP",
    UDim2.fromOffset(70, 20),
    UDim2.fromOffset(110, 20),
    Enum.Font.GothamBold,
    15,
    C.Text
)

label(
    Sidebar,
    "INSPECTOR V4",
    UDim2.fromOffset(70, 41),
    UDim2.fromOffset(110, 16),
    Enum.Font.GothamMedium,
    9,
    C.Muted
)

--==============================================================
-- NAVIGATION
--==============================================================

label(
    Sidebar,
    "TOOLS",
    UDim2.fromOffset(18, 89),
    UDim2.fromOffset(100, 15),
    Enum.Font.GothamBold,
    9,
    C.Muted2
)

local FullDumpButton = button(
    Sidebar,
    "◈  FULL CLIENT DUMP",
    UDim2.fromOffset(14, 112),
    UDim2.fromOffset(162, 40),
    C.Surface2
)

FullDumpButton.TextXAlignment = Enum.TextXAlignment.Left
padding(FullDumpButton, 13, 0, 0, 0)

local LiveButton = button(
    Sidebar,
    "●  START REMOTE LIVE",
    UDim2.fromOffset(14, 160),
    UDim2.fromOffset(162, 40),
    C.Surface2
)

LiveButton.TextXAlignment = Enum.TextXAlignment.Left
padding(LiveButton, 13, 0, 0, 0)

local ClearButton = button(
    Sidebar,
    "⌫  CLEAR CONSOLE",
    UDim2.fromOffset(14, 208),
    UDim2.fromOffset(162, 40),
    C.Surface2
)

ClearButton.TextXAlignment = Enum.TextXAlignment.Left
padding(ClearButton, 13, 0, 0, 0)

--==============================================================
-- LIVE INDICATOR
--==============================================================

local LiveCard = new("Frame", {
    Position = UDim2.new(0, 14, 1, -112),
    Size = UDim2.fromOffset(162, 76),

    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,

    Parent = Sidebar
})

corner(LiveCard, 13)
stroke(LiveCard, C.Border, .55)

local LiveDot = new("Frame", {
    Position = UDim2.fromOffset(13, 14),
    Size = UDim2.fromOffset(8, 8),

    BackgroundColor3 = C.Muted2,
    BorderSizePixel = 0,

    Parent = LiveCard
})

corner(LiveDot, 50)

local LiveStateText = label(
    LiveCard,
    "REMOTE LIVE OFF",
    UDim2.fromOffset(29, 8),
    UDim2.fromOffset(120, 20),
    Enum.Font.GothamBold,
    10,
    C.Muted
)

local LiveCountText = label(
    LiveCard,
    "0 events captured",
    UDim2.fromOffset(13, 32),
    UDim2.fromOffset(136, 18),
    Enum.Font.Gotham,
    10,
    C.Muted
)

local LiveFileText = label(
    LiveCard,
    "No active session",
    UDim2.fromOffset(13, 50),
    UDim2.fromOffset(136, 15),
    Enum.Font.Gotham,
    8,
    C.Muted2
)

LiveFileText.TextTruncate = Enum.TextTruncate.AtEnd

--==============================================================
-- CONTENT
--==============================================================

local Content = new("Frame", {
    Position = UDim2.fromOffset(190, 3),
    Size = UDim2.new(1, -190, 1, -3),

    BackgroundTransparency = 1,

    Parent = Main
})

--==============================================================
-- HEADER
--==============================================================

label(
    Content,
    "Client Inspector",
    UDim2.fromOffset(24, 20),
    UDim2.fromOffset(300, 28),
    Enum.Font.GothamBold,
    21,
    C.Text
)

label(
    Content,
    "Inspect • Capture • Analyze",
    UDim2.fromOffset(24, 48),
    UDim2.fromOffset(300, 18),
    Enum.Font.Gotham,
    10,
    C.Muted
)

local Close = button(
    Content,
    "×",
    UDim2.new(1, -54, 0, 20),
    UDim2.fromOffset(34, 34),
    C.Surface2
)

Close.TextSize = 18

--==============================================================
-- STATUS CARD
--==============================================================

local StatusCard = new("Frame", {
    Position = UDim2.fromOffset(24, 82),
    Size = UDim2.new(1, -48, 0, 74),

    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,

    Parent = Content
})

corner(StatusCard, 14)
stroke(StatusCard, C.Border, .55)

local StatusDot = new("Frame", {
    Position = UDim2.fromOffset(16, 17),
    Size = UDim2.fromOffset(9, 9),

    BackgroundColor3 = C.Green,
    BorderSizePixel = 0,

    Parent = StatusCard
})

corner(StatusDot, 50)

local Status = label(
    StatusCard,
    "READY",
    UDim2.fromOffset(34, 10),
    UDim2.new(1, -50, 0, 22),
    Enum.Font.GothamBold,
    11,
    C.Green
)

local Detail = label(
    StatusCard,
    "Waiting for command",
    UDim2.fromOffset(16, 33),
    UDim2.new(1, -32, 0, 18),
    Enum.Font.Gotham,
    10,
    C.Muted
)

Detail.TextTruncate = Enum.TextTruncate.AtEnd

local ProgressBG = new("Frame", {
    Position = UDim2.new(0, 16, 1, -12),
    Size = UDim2.new(1, -32, 0, 4),

    BackgroundColor3 = C.Surface3,
    BorderSizePixel = 0,

    Parent = StatusCard
})

corner(ProgressBG, 10)

local Progress = new("Frame", {
    Size = UDim2.fromScale(0, 1),

    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,

    Parent = ProgressBG
})

corner(Progress, 10)

new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Blue),
        ColorSequenceKeypoint.new(.5, C.Purple),
        ColorSequenceKeypoint.new(1, C.Cyan)
    }),

    Parent = Progress
})

--==============================================================
-- STATS
--==============================================================

local StatsHolder = new("Frame", {
    Position = UDim2.fromOffset(24, 168),
    Size = UDim2.new(1, -48, 0, 66),

    BackgroundTransparency = 1,

    Parent = Content
})

local function statCard(x, title, initial)
    local card = new("Frame", {
        Position = UDim2.new(x, x == 0 and 0 or 5, 0, 0),
        Size = UDim2.new(.25, -8, 1, 0),

        BackgroundColor3 = C.Surface,
        BorderSizePixel = 0,

        Parent = StatsHolder
    })

    corner(card, 12)
    stroke(card, C.Border, .62)

    label(
        card,
        title,
        UDim2.fromOffset(12, 10),
        UDim2.new(1, -24, 0, 15),
        Enum.Font.GothamBold,
        8,
        C.Muted
    )

    local value = label(
        card,
        tostring(initial),
        UDim2.fromOffset(12, 27),
        UDim2.new(1, -24, 0, 27),
        Enum.Font.GothamBold,
        19,
        C.Text
    )

    return value
end

local InstanceStat = statCard(0, "INSTANCES", 0)
local ScriptStat = statCard(.25, "SCRIPTS", 0)
local RemoteStat = statCard(.50, "REMOTES", 0)
local LiveStat = statCard(.75, "LIVE EVENTS", 0)

--==============================================================
-- CONSOLE
--==============================================================

local ConsoleCard = new("Frame", {
    Position = UDim2.fromOffset(24, 247),
    Size = UDim2.new(1, -48, 1, -324),

    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,

    Parent = Content
})

corner(ConsoleCard, 14)
stroke(ConsoleCard, C.Border, .58)

label(
    ConsoleCard,
    "ACTIVITY",
    UDim2.fromOffset(14, 8),
    UDim2.fromOffset(100, 20),
    Enum.Font.GothamBold,
    9,
    C.Muted
)

local Console = new("TextLabel", {
    Position = UDim2.fromOffset(14, 31),
    Size = UDim2.new(1, -28, 1, -42),

    BackgroundTransparency = 1,

    Text = "> DEVIL DUMP V4 initialized",

    Font = Enum.Font.Code,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(182, 194, 225),

    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,

    TextWrapped = true,

    Parent = ConsoleCard
})

--==============================================================
-- BOTTOM ACTION
--==============================================================

local Bottom = new("Frame", {
    Position = UDim2.new(0, 24, 1, -65),
    Size = UDim2.new(1, -48, 0, 46),

    BackgroundTransparency = 1,

    Parent = Content
})

local DumpButton = button(
    Bottom,
    "START FULL CLIENT DUMP",
    UDim2.fromOffset(0, 0),
    UDim2.new(.64, -5, 1, 0),
    C.Purple
)

local RemoteButton = button(
    Bottom,
    "REMOTE LIVE",
    UDim2.new(.64, 5, 0, 0),
    UDim2.new(.36, -5, 1, 0),
    C.Blue
)

--==============================================================
-- TOAST CONTAINER
--==============================================================

local ToastHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 0),

    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(330, 500),

    BackgroundTransparency = 1,

    Parent = GUI
})

local ToastLayout = new("UIListLayout", {
    Padding = UDim.new(0, 9),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,

    Parent = ToastHolder
})

--==============================================================
-- TOAST SYSTEM
--==============================================================

local ToastOrder = 0

local function notify(titleValue, message, kind, duration)
    ToastOrder += 1

    local color = C.Blue
    local symbol = "i"

    if kind == "success" then
        color = C.Green
        symbol = "✓"
    elseif kind == "error" then
        color = C.Red
        symbol = "!"
    elseif kind == "warning" then
        color = C.Yellow
        symbol = "!"
    elseif kind == "live" then
        color = C.Cyan
        symbol = "●"
    end

    local Toast = new("Frame", {
        Size = UDim2.fromOffset(310, 78),

        BackgroundColor3 = C.Surface,
        BackgroundTransparency = .03,

        BorderSizePixel = 0,

        LayoutOrder = ToastOrder,

        Parent = ToastHolder
    })

    corner(Toast, 14)

    local ts = stroke(Toast, color, .30, 1)

    local Accent = new("Frame", {
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.fromOffset(3, 58),

        BackgroundColor3 = color,
        BorderSizePixel = 0,

        Parent = Toast
    })

    corner(Accent, 10)

    local Icon = new("Frame", {
        Position = UDim2.fromOffset(14, 17),
        Size = UDim2.fromOffset(34, 34),

        BackgroundColor3 = color,
        BackgroundTransparency = .82,
        BorderSizePixel = 0,

        Parent = Toast
    })

    corner(Icon, 10)

    local IconText = label(
        Icon,
        symbol,
        UDim2.new(),
        UDim2.fromScale(1, 1),
        Enum.Font.GothamBold,
        15,
        color
    )

    IconText.TextXAlignment = Enum.TextXAlignment.Center

    label(
        Toast,
        titleValue,
        UDim2.fromOffset(60, 12),
        UDim2.new(1, -75, 0, 22),
        Enum.Font.GothamBold,
        12,
        C.Text
    )

    local msg = label(
        Toast,
        message,
        UDim2.fromOffset(60, 34),
        UDim2.new(1, -75, 0, 31),
        Enum.Font.Gotham,
        9,
        C.Muted
    )

    msg.TextWrapped = true
    msg.TextYAlignment = Enum.TextYAlignment.Top

    local ToastScale = new("UIScale", {
        Scale = .88,
        Parent = Toast
    })

    Toast.BackgroundTransparency = 1
    ts.Transparency = 1

    TweenService:Create(
        ToastScale,
        TweenInfo.new(.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    TweenService:Create(
        Toast,
        TweenInfo.new(.18),
        {BackgroundTransparency = .03}
    ):Play()

    TweenService:Create(
        ts,
        TweenInfo.new(.18),
        {Transparency = .30}
    ):Play()

    task.delay(duration or 4, function()
        if not Toast.Parent then return end

        TweenService:Create(
            ToastScale,
            TweenInfo.new(.18),
            {Scale = .92}
        ):Play()

        TweenService:Create(
            Toast,
            TweenInfo.new(.18),
            {BackgroundTransparency = 1}
        ):Play()

        task.wait(.2)

        if Toast then
            Toast:Destroy()
        end
    end)
end

--==============================================================
-- CONSOLE
--==============================================================

local ConsoleLines = {}

local function log(message)
    local timeText = os.date("%H:%M:%S")

    table.insert(
        ConsoleLines,
        "[" .. timeText .. "] " .. tostring(message)
    )

    while #ConsoleLines > 14 do
        table.remove(ConsoleLines, 1)
    end

    Console.Text = "> " .. table.concat(ConsoleLines, "\n> ")
end

ClearButton.MouseButton1Click:Connect(function()
    table.clear(ConsoleLines)
    Console.Text = "> Console cleared"
    notify("Console cleared", "Activity history was cleared.", "success", 2.5)
end)

--==============================================================
-- STATUS
--==============================================================

local function setStatus(titleValue, detailValue, color)
    color = color or C.Green

    Status.Text = titleValue
    Status.TextColor3 = color

    Detail.Text = detailValue or ""

    StatusDot.BackgroundColor3 = color
end

local function setProgress(value)
    value = math.clamp(value, 0, 1)

    TweenService:Create(
        Progress,
        TweenInfo.new(.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            Size = UDim2.fromScale(value, 1)
        }
    ):Play()
end

--==============================================================
-- SERIALIZER
--==============================================================

local function serialize(value, depth)
    depth = depth or 0

    if depth > 4 then
        return "<max-depth>"
    end

    local kind = typeof(value)

    if kind == "string" then
        if #value > 1500 then
            value = string.sub(value, 1, 1500) .. "...<truncated>"
        end

        return string.format("%q", value)

    elseif kind == "number"
        or kind == "boolean"
        or kind == "nil"
    then
        return tostring(value)

    elseif kind == "Instance" then
        return "<Instance:" .. safePath(value) .. ">"

    elseif kind == "table" then
        local output = {}
        local count = 0

        for k, v in pairs(value) do
            count += 1

            if count > 50 then
                output[#output + 1] = "...<truncated>"
                break
            end

            output[#output + 1] =
                "["
                .. serialize(k, depth + 1)
                .. "]="
                .. serialize(v, depth + 1)
        end

        return "{" .. table.concat(output, ", ") .. "}"

    elseif kind == "Vector3"
        or kind == "Vector2"
        or kind == "CFrame"
        or kind == "Color3"
        or kind == "UDim"
        or kind == "UDim2"
        or kind == "BrickColor"
        or kind == "EnumItem"
    then
        return tostring(value)
    end

    local success, result = pcall(tostring, value)

    return success and result or "<unserializable>"
end

local function serializeArgs(...)
    local args = table.pack(...)
    local result = {}

    for i = 1, args.n do
        result[#result + 1] =
            "[" .. i .. "] " .. serialize(args[i])
    end

    if #result == 0 then
        return "<no arguments>"
    end

    return table.concat(result, " | ")
end

--==============================================================
-- DUMP DATA
--==============================================================

local Output = {}

local Stats = {
    Instances = 0,
    Scripts = 0,
    LocalScripts = 0,
    ModuleScripts = 0,

    RemoteEvents = 0,
    RemoteFunctions = 0,
    BindableEvents = 0,
    BindableFunctions = 0,

    Values = 0,
    Tools = 0,
    Prompts = 0,
    GUI = 0
}

local Interesting = {
    Eggs = {},
    Pets = {},
    Rocks = {},
    Mining = {},
    Shops = {},
    Plots = {},
    Inventory = {},
    Quests = {}
}

local function emit(value)
    Output[#Output + 1] = tostring(value)
end

local function separator(titleValue)
    emit("")
    emit(string.rep("=", 78))
    emit(" " .. titleValue)
    emit(string.rep("=", 78))
end

--==============================================================
-- STATS UI
--==============================================================

local function updateStats()
    local remotes =
        Stats.RemoteEvents
        + Stats.RemoteFunctions
        + Stats.BindableEvents
        + Stats.BindableFunctions

    InstanceStat.Text = tostring(Stats.Instances)
    ScriptStat.Text = tostring(Stats.Scripts)
    RemoteStat.Text = tostring(remotes)
end

--==============================================================
-- PROPERTY
--==============================================================

local function property(object, name)
    local success, result = pcall(function()
        return object[name]
    end)

    if success then
        emit(
            "    "
            .. name
            .. " = "
            .. serialize(result)
        )
    end
end

--==============================================================
-- ATTRIBUTES
--==============================================================

local function dumpAttributes(object)
    if not CONFIG.DumpAttributes then return end

    local success, attributes = pcall(function()
        return object:GetAttributes()
    end)

    if not success then return end

    if next(attributes) then
        emit("    Attributes:")

        for key, value in pairs(attributes) do
            emit(
                "      @"
                .. key
                .. " = "
                .. serialize(value)
            )
        end
    end
end

--==============================================================
-- TAGS
--==============================================================

local function dumpTags(object)
    if not CONFIG.DumpTags then return end

    local success, tags = pcall(function()
        return CollectionService:GetTags(object)
    end)

    if success and #tags > 0 then
        emit("    Tags = " .. table.concat(tags, ", "))
    end
end

--==============================================================
-- PROPERTIES
--==============================================================

local function dumpProperties(object)
    if not CONFIG.DumpProperties then return end

    property(object, "Archivable")

    if object:IsA("BasePart") then
        property(object, "Position")
        property(object, "Size")
        property(object, "CFrame")
        property(object, "Anchored")
        property(object, "CanCollide")
        property(object, "CanTouch")
        property(object, "CanQuery")
        property(object, "Transparency")
        property(object, "Color")
        property(object, "Material")
        property(object, "AssemblyLinearVelocity")

    elseif object:IsA("Humanoid") then
        property(object, "Health")
        property(object, "MaxHealth")
        property(object, "WalkSpeed")
        property(object, "JumpPower")
        property(object, "HipHeight")
        property(object, "RigType")

    elseif object:IsA("Tool") then
        Stats.Tools += 1

        property(object, "RequiresHandle")
        property(object, "CanBeDropped")
        property(object, "ToolTip")

    elseif object:IsA("Sound") then
        property(object, "SoundId")
        property(object, "Volume")
        property(object, "PlaybackSpeed")
        property(object, "Looped")

    elseif object:IsA("Animation") then
        property(object, "AnimationId")

    elseif object:IsA("ProximityPrompt") then
        Stats.Prompts += 1

        property(object, "ActionText")
        property(object, "ObjectText")
        property(object, "HoldDuration")
        property(object, "MaxActivationDistance")
        property(object, "Enabled")

    elseif object:IsA("ClickDetector") then
        Stats.Prompts += 1
        property(object, "MaxActivationDistance")

    elseif object:IsA("ValueBase") then
        Stats.Values += 1
        property(object, "Value")

    elseif object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    then
        Stats.GUI += 1

        property(object, "Text")
        property(object, "Visible")
        property(object, "Position")
        property(object, "Size")

    elseif object:IsA("ImageLabel")
        or object:IsA("ImageButton")
    then
        Stats.GUI += 1

        property(object, "Image")
        property(object, "Visible")
        property(object, "Position")
        property(object, "Size")
    end
end

--==============================================================
-- SPECIAL
--==============================================================

local function inspectSpecial(object)
    if object:IsA("LocalScript") then
        Stats.Scripts += 1
        Stats.LocalScripts += 1

        emit("    SCRIPT_TYPE = LocalScript")

        if CONFIG.DumpSource then
            local success, source = pcall(function()
                return object.Source
            end)

            if success
                and type(source) == "string"
                and #source > 0
            then
                emit("")
                emit("    ----- SOURCE BEGIN -----")
                emit(source)
                emit("    ----- SOURCE END -----")
            else
                emit("    Source = <not exposed>")
            end
        end

    elseif object:IsA("ModuleScript") then
        Stats.Scripts += 1
        Stats.ModuleScripts += 1

        emit("    SCRIPT_TYPE = ModuleScript")

        if CONFIG.DumpSource then
            local success, source = pcall(function()
                return object.Source
            end)

            if success
                and type(source) == "string"
                and #source > 0
            then
                emit("")
                emit("    ----- SOURCE BEGIN -----")
                emit(source)
                emit("    ----- SOURCE END -----")
            else
                emit("    Source = <not exposed>")
            end
        end

    elseif object:IsA("RemoteEvent") then
        Stats.RemoteEvents += 1
        emit("    REMOTE = RemoteEvent")

    elseif object:IsA("RemoteFunction") then
        Stats.RemoteFunctions += 1
        emit("    REMOTE = RemoteFunction")

    elseif object:IsA("BindableEvent") then
        Stats.BindableEvents += 1
        emit("    BINDABLE = BindableEvent")

    elseif object:IsA("BindableFunction") then
        Stats.BindableFunctions += 1
        emit("    BINDABLE = BindableFunction")
    end
end

--==============================================================
-- CLASSIFIER
--==============================================================

local function classify(object)
    local lower = string.lower(object.Name)
    local path = safePath(object)

    local function add(category)
        local list = Interesting[category]

        if list then
            list[#list + 1] = path
        end
    end

    if string.find(lower, "egg", 1, true) then
        add("Eggs")
    end

    if string.find(lower, "pet", 1, true) then
        add("Pets")
    end

    if string.find(lower, "rock", 1, true) then
        add("Rocks")
    end

    if string.find(lower, "mine", 1, true)
        or string.find(lower, "mining", 1, true)
    then
        add("Mining")
    end

    if string.find(lower, "shop", 1, true)
        or string.find(lower, "vendor", 1, true)
        or string.find(lower, "sell", 1, true)
    then
        add("Shops")
    end

    if string.find(lower, "plot", 1, true) then
        add("Plots")
    end

    if string.find(lower, "inventory", 1, true)
        or string.find(lower, "backpack", 1, true)
    then
        add("Inventory")
    end

    if string.find(lower, "quest", 1, true)
        or string.find(lower, "mission", 1, true)
    then
        add("Quests")
    end
end

--==============================================================
-- INSTANCE DUMP
--==============================================================

local function dumpInstance(object, depth, state)
    if depth > CONFIG.MaxDepth then return end

    if state.Count >= state.Limit then
        state.HitLimit = true
        return
    end

    state.Count += 1
    Stats.Instances += 1

    local path = safePath(object)

    emit("")
    emit(
        string.rep("  ", depth)
        .. "["
        .. object.ClassName
        .. "] "
        .. object.Name
    )

    emit(
        string.rep("  ", depth)
        .. "Path = "
        .. path
    )

    dumpAttributes(object)
    dumpTags(object)
    inspectSpecial(object)
    dumpProperties(object)
    classify(object)

    if Stats.Instances % CONFIG.YieldEvery == 0 then
        updateStats()
        Detail.Text = "Scanning " .. path
        task.wait()
    end

    local success, children = pcall(function()
        return object:GetChildren()
    end)

    if not success then return end

    for _, child in ipairs(children) do
        if state.Count >= state.Limit then
            state.HitLimit = true
            break
        end

        dumpInstance(child, depth + 1, state)
    end
end

--==============================================================
-- ROOT SCAN
--==============================================================

local function scanRoot(titleValue, object, limit)
    separator(titleValue)

    if not object then
        emit("<ROOT NOT AVAILABLE>")
        return
    end

    local state = {
        Count = 0,
        Limit = limit or CONFIG.GeneralLimit,
        HitLimit = false
    }

    dumpInstance(object, 0, state)

    emit("")
    emit("ROOT_INSTANCE_COUNT = " .. state.Count)
    emit("ROOT_LIMIT_REACHED = " .. tostring(state.HitLimit))
end

--==============================================================
-- REMOTE INDEX
--==============================================================

local function buildRemoteIndex()
    separator("REMOTE / BINDABLE INDEX")

    local roots = {
        ReplicatedStorage,
        ReplicatedFirst,
        Player:FindFirstChild("PlayerScripts"),
        PlayerGui
    }

    local found = 0

    for _, root in ipairs(roots) do
        if root then
            for _, object in ipairs(root:GetDescendants()) do
                if object:IsA("RemoteEvent")
                    or object:IsA("RemoteFunction")
                    or object:IsA("BindableEvent")
                    or object:IsA("BindableFunction")
                then
                    found += 1

                    emit(
                        object.ClassName
                        .. " | "
                        .. safePath(object)
                    )

                    dumpAttributes(object)
                    dumpTags(object)
                end

                if found > 0 and found % 200 == 0 then
                    task.wait()
                end
            end
        end
    end

    emit("")
    emit("REMOTE_INDEX_TOTAL = " .. found)
end

--==============================================================
-- SCRIPT INDEX
--==============================================================

local function buildScriptIndex()
    separator("LOCAL SCRIPT / MODULE INDEX")

    local roots = {
        ReplicatedStorage,
        ReplicatedFirst,
        Player:FindFirstChild("PlayerScripts"),
        PlayerGui,
        Player:FindFirstChild("Backpack"),
        Player.Character
    }

    local found = 0

    for _, root in ipairs(roots) do
        if root then
            for _, object in ipairs(root:GetDescendants()) do
                if object:IsA("LocalScript")
                    or object:IsA("ModuleScript")
                then
                    found += 1

                    emit(
                        object.ClassName
                        .. " | "
                        .. safePath(object)
                    )

                    dumpAttributes(object)
                    dumpTags(object)
                end

                if found > 0 and found % 200 == 0 then
                    task.wait()
                end
            end
        end
    end

    emit("")
    emit("SCRIPT_INDEX_TOTAL = " .. found)
end

--==============================================================
-- SYSTEM INDEX
--==============================================================

local function writeSystemIndex()
    separator("DISCOVERED GAME SYSTEM INDEX")

    local order = {
        "Eggs",
        "Pets",
        "Rocks",
        "Mining",
        "Shops",
        "Plots",
        "Inventory",
        "Quests"
    }

    for _, category in ipairs(order) do
        emit("")
        emit("[" .. category .. "]")

        local list = Interesting[category]
        local seen = {}
        local count = 0

        for _, path in ipairs(list) do
            if not seen[path] then
                seen[path] = true
                count += 1

                emit("  " .. path)

                if count >= 500 then
                    emit("  <truncated at 500 entries>")
                    break
                end
            end
        end

        emit("  Count = " .. count)
    end
end

--==============================================================
-- HEADER / SUMMARY
--==============================================================

local function writeHeader()
    separator("DEVIL DUMP V4")

    emit("PlaceId = " .. tostring(game.PlaceId))
    emit("GameId = " .. tostring(game.GameId))
    emit("JobId = " .. tostring(game.JobId))
    emit("PlaceVersion = " .. tostring(game.PlaceVersion))
    emit("Player = " .. Player.Name)
    emit("Generated = " .. os.date("%Y-%m-%d %H:%M:%S"))

    emit("")
    emit("Scope = CLIENT-VISIBLE / REPLICATED DATA")
end

local function writeSummary()
    separator("SUMMARY")

    for key, value in pairs(Stats) do
        emit(key .. " = " .. tostring(value))
    end
end

--==============================================================
-- FILE HELPERS
--==============================================================

local function ensureFolder()
    if type(makefolder) ~= "function" then
        return false
    end

    local success = pcall(function()
        if type(isfolder) ~= "function"
            or not isfolder(CONFIG.Folder)
        then
            makefolder(CONFIG.Folder)
        end
    end)

    return success
end

local function makePath(prefix)
    local filename = string.format(
        "%s_%s_%s.txt",
        prefix,
        tostring(game.PlaceId),
        tostring(os.time())
    )

    if ensureFolder() then
        return CONFIG.Folder .. "/" .. filename
    end

    return filename
end

local function saveDump()
    if type(writefile) ~= "function" then
        return false, nil, "writefile unavailable"
    end

    local path = makePath("DevilDump")
    local data = table.concat(Output, "\n")

    local success, err = pcall(function()
        writefile(path, data)
    end)

    if not success then
        return false, path, tostring(err)
    end

    return true, path, #data
end

--==============================================================
-- REMOTE LIVE
--==============================================================

local Live = {
    Enabled = false,
    Count = 0,
    Entries = {},
    Connections = {},
    Registered = {},
    Path = nil,
    SessionStarted = nil
}

local function disconnectLive()
    for _, connection in ipairs(Live.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Live.Connections)
    table.clear(Live.Registered)
end

local function saveLive()
    if not Live.Path then
        return false, "No live session"
    end

    if type(writefile) ~= "function" then
        return false, "writefile unavailable"
    end

    local header = {
        "==============================================================",
        "DEVIL DUMP V4 - REMOTE LIVE SESSION",
        "==============================================================",
        "PlaceId = " .. tostring(game.PlaceId),
        "JobId = " .. tostring(game.JobId),
        "Player = " .. Player.Name,
        "Started = " .. tostring(Live.SessionStarted),
        "Captured = " .. tostring(Live.Count),
        "==============================================================",
        ""
    }

    local output = {}

    for _, line in ipairs(header) do
        output[#output + 1] = line
    end

    for _, line in ipairs(Live.Entries) do
        output[#output + 1] = line
    end

    local success, err = pcall(function()
        writefile(
            Live.Path,
            table.concat(output, "\n")
        )
    end)

    return success, err
end

local function pushLive(className, path, ...)
    if not Live.Enabled then return end

    Live.Count += 1

    local line = string.format(
        "[%s] #%d [%s] %s\nARGS: %s\n",
        os.date("%H:%M:%S"),
        Live.Count,
        className,
        path,
        serializeArgs(...)
    )

    Live.Entries[#Live.Entries + 1] = line

    if #Live.Entries > CONFIG.MaxLiveEntries then
        table.remove(Live.Entries, 1)
    end

    LiveStat.Text = tostring(Live.Count)
    LiveCountText.Text = tostring(Live.Count) .. " events captured"

    log(
        "LIVE #" .. Live.Count
        .. " • "
        .. className
        .. " • "
        .. path
    )

    if Live.Count % CONFIG.LiveAutoSaveEvery == 0 then
        task.spawn(saveLive)
    end
end

local function registerLiveObject(object)
    if Live.Registered[object] then
        return
    end

    if object:IsA("RemoteEvent")
        and CONFIG.LiveRemoteEvents
    then
        Live.Registered[object] = true

        local connection = object.OnClientEvent:Connect(function(...)
            pushLive(
                "RemoteEvent",
                safePath(object),
                ...
            )
        end)

        Live.Connections[#Live.Connections + 1] = connection

    elseif object:IsA("BindableEvent")
        and CONFIG.LiveBindableEvents
    then
        Live.Registered[object] = true

        local connection = object.Event:Connect(function(...)
            pushLive(
                "BindableEvent",
                safePath(object),
                ...
            )
        end)

        Live.Connections[#Live.Connections + 1] = connection
    end
end

local function watchRoot(root)
    if not root then return end

    registerLiveObject(root)

    for _, object in ipairs(root:GetDescendants()) do
        registerLiveObject(object)
    end

    local connection = root.DescendantAdded:Connect(function(object)
        if Live.Enabled then
            registerLiveObject(object)

            if object:IsA("RemoteEvent")
                or object:IsA("BindableEvent")
            then
                log(
                    "New live endpoint: "
                    .. safePath(object)
                )
            end
        end
    end)

    Live.Connections[#Live.Connections + 1] = connection
end

local function startLive()
    if Live.Enabled then
        return
    end

    Live.Enabled = true
    Live.Count = 0
    Live.Entries = {}
    Live.Registered = {}

    Live.SessionStarted = os.date("%Y-%m-%d %H:%M:%S")
    Live.Path = makePath("RemoteLive")

    LiveDot.BackgroundColor3 = C.Green
    LiveStateText.Text = "REMOTE LIVE ACTIVE"
    LiveStateText.TextColor3 = C.Green

    LiveCountText.Text = "0 events captured"
    LiveFileText.Text = Live.Path

    LiveButton.Text = "■  STOP REMOTE LIVE"
    RemoteButton.Text = "STOP LIVE"

    setStatus(
        "REMOTE LIVE",
        "Listening for client-visible incoming events",
        C.Green
    )

    notify(
        "Remote Live started",
        "Listening for incoming RemoteEvent / BindableEvent activity.",
        "live",
        4
    )

    log("Remote Live started")

    local roots = {
        ReplicatedStorage,
        ReplicatedFirst,
        Player:FindFirstChild("PlayerScripts"),
        PlayerGui,
        Player:FindFirstChild("Backpack"),
        Player.Character
    }

    for _, root in ipairs(roots) do
        watchRoot(root)
        task.wait()
    end

    local charConnection = Player.CharacterAdded:Connect(function(character)
        if Live.Enabled then
            task.wait(.5)
            watchRoot(character)
        end
    end)

    Live.Connections[#Live.Connections + 1] = charConnection

    saveLive()
end

local function stopLive()
    if not Live.Enabled then
        return
    end

    Live.Enabled = false

    local count = Live.Count
    local path = Live.Path

    saveLive()
    disconnectLive()

    LiveDot.BackgroundColor3 = C.Muted2

    LiveStateText.Text = "REMOTE LIVE OFF"
    LiveStateText.TextColor3 = C.Muted

    LiveButton.Text = "●  START REMOTE LIVE"
    RemoteButton.Text = "REMOTE LIVE"

    setStatus(
        "LIVE SAVED",
        path or "Remote Live stopped",
        C.Green
    )

    notify(
        "Remote Live saved",
        tostring(count)
        .. " events captured\n"
        .. tostring(path),
        "success",
        5
    )

    log(
        "Remote Live stopped • "
        .. tostring(count)
        .. " captured"
    )
end

local function toggleLive()
    if Live.Enabled then
        stopLive()
    else
        startLive()
    end
end

LiveButton.MouseButton1Click:Connect(toggleLive)
RemoteButton.MouseButton1Click:Connect(toggleLive)

--==============================================================
-- RESET DUMP
--==============================================================

local function resetDump()
    Output = {}

    Stats = {
        Instances = 0,
        Scripts = 0,
        LocalScripts = 0,
        ModuleScripts = 0,

        RemoteEvents = 0,
        RemoteFunctions = 0,
        BindableEvents = 0,
        BindableFunctions = 0,

        Values = 0,
        Tools = 0,
        Prompts = 0,
        GUI = 0
    }

    Interesting = {
        Eggs = {},
        Pets = {},
        Rocks = {},
        Mining = {},
        Shops = {},
        Plots = {},
        Inventory = {},
        Quests = {}
    }

    updateStats()
end

--==============================================================
-- FULL DUMP
--==============================================================

local Busy = false

local function executeDump()
    if Busy then
        notify(
            "Dump already running",
            "Wait for the current scan to finish.",
            "warning",
            3
        )

        return
    end

    Busy = true
    resetDump()

    DumpButton.Text = "SCANNING..."
    FullDumpButton.Text = "◌  DUMP RUNNING..."

    notify(
        "Full dump started",
        "Client hierarchy inspection is now running.",
        "live",
        3
    )

    setStatus(
        "INITIALIZING",
        "Preparing client inspector",
        C.Cyan
    )

    setProgress(.02)

    log("Full dump started")

    writeHeader()

    ----------------------------------------------------------
    -- REMOTES
    ----------------------------------------------------------

    setStatus(
        "REMOTE SCAN",
        "Indexing RemoteEvents / Functions",
        C.Cyan
    )

    log("Remote index...")
    buildRemoteIndex()

    setProgress(.10)

    ----------------------------------------------------------
    -- SCRIPTS
    ----------------------------------------------------------

    setStatus(
        "SCRIPT SCAN",
        "Indexing LocalScripts / Modules",
        C.Cyan
    )

    log("Script index...")
    buildScriptIndex()

    setProgress(.18)

    ----------------------------------------------------------
    -- REPLICATED STORAGE
    ----------------------------------------------------------

    setStatus(
        "REPLICATED STORAGE",
        "Scanning replicated systems",
        C.Cyan
    )

    log("ReplicatedStorage...")

    scanRoot(
        "REPLICATED STORAGE",
        ReplicatedStorage,
        CONFIG.GeneralLimit
    )

    setProgress(.31)

    ----------------------------------------------------------
    -- REPLICATED FIRST
    ----------------------------------------------------------

    setStatus(
        "REPLICATED FIRST",
        "Scanning startup data",
        C.Cyan
    )

    log("ReplicatedFirst...")

    scanRoot(
        "REPLICATED FIRST",
        ReplicatedFirst,
        CONFIG.GeneralLimit
    )

    setProgress(.38)

    ----------------------------------------------------------
    -- PLAYER SCRIPTS
    ----------------------------------------------------------

    local PlayerScripts =
        Player:FindFirstChild("PlayerScripts")

    setStatus(
        "PLAYER SCRIPTS",
        "Scanning local runtime hierarchy",
        C.Cyan
    )

    log("PlayerScripts...")

    scanRoot(
        "PLAYER SCRIPTS",
        PlayerScripts,
        CONFIG.GeneralLimit
    )

    setProgress(.47)

    ----------------------------------------------------------
    -- GUI
    ----------------------------------------------------------

    if CONFIG.DumpGUI then
        setStatus(
            "PLAYER GUI",
            "Scanning UI / text / buttons",
            C.Cyan
        )

        log("PlayerGui...")

        scanRoot(
            "PLAYER GUI",
            PlayerGui,
            CONFIG.GeneralLimit
        )
    end

    setProgress(.57)

    ----------------------------------------------------------
    -- BACKPACK
    ----------------------------------------------------------

    local Backpack =
        Player:FindFirstChild("Backpack")

    setStatus(
        "BACKPACK",
        "Scanning tools / inventory",
        C.Cyan
    )

    log("Backpack...")

    scanRoot(
        "BACKPACK",
        Backpack,
        CONFIG.GeneralLimit
    )

    setProgress(.64)

    ----------------------------------------------------------
    -- CHARACTER
    ----------------------------------------------------------

    setStatus(
        "CHARACTER",
        "Scanning current character",
        C.Cyan
    )

    log("Character...")

    scanRoot(
        "CHARACTER",
        Player.Character,
        CONFIG.GeneralLimit
    )

    setProgress(.70)

    ----------------------------------------------------------
    -- LIGHTING
    ----------------------------------------------------------

    setStatus(
        "LIGHTING",
        "Scanning lighting hierarchy",
        C.Cyan
    )

    log("Lighting...")

    scanRoot(
        "LIGHTING",
        Lighting,
        30000
    )

    setProgress(.74)

    ----------------------------------------------------------
    -- SOUND
    ----------------------------------------------------------

    setStatus(
        "SOUND SERVICE",
        "Scanning audio hierarchy",
        C.Cyan
    )

    log("SoundService...")

    scanRoot(
        "SOUND SERVICE",
        SoundService,
        30000
    )

    setProgress(.78)

    ----------------------------------------------------------
    -- WORKSPACE
    ----------------------------------------------------------

    if CONFIG.DumpWorkspace then
        setStatus(
            "WORKSPACE",
            "Scanning map — high instance limit",
            C.Cyan
        )

        log("Workspace last...")

        scanRoot(
            "WORKSPACE / MAP",
            workspace,
            CONFIG.WorkspaceLimit
        )
    end

    setProgress(.91)

    ----------------------------------------------------------
    -- INDEX
    ----------------------------------------------------------

    setStatus(
        "BUILDING INDEX",
        "Grouping discovered systems",
        C.Cyan
    )

    log("Building system index...")

    writeSystemIndex()
    writeSummary()

    setProgress(.96)

    ----------------------------------------------------------
    -- SAVE
    ----------------------------------------------------------

    setStatus(
        "SAVING",
        "Writing dump file",
        C.Cyan
    )

    log("Writing dump...")

    local success, path, result = saveDump()

    if success then
        setProgress(1)

        setStatus(
            "DUMP COMPLETE",
            path,
            C.Green
        )

        DumpButton.Text = "DUMP COMPLETE"
        FullDumpButton.Text = "✓  DUMP COMPLETE"

        log("Saved: " .. path)
        log("Bytes: " .. tostring(result))

        notify(
            "Dump complete",
            "Saved successfully\n"
            .. tostring(path)
            .. "\n"
            .. tostring(Stats.Instances)
            .. " instances inspected.",
            "success",
            6
        )

        task.delay(2.5, function()
            if not Busy then
                DumpButton.Text = "START FULL CLIENT DUMP"
                FullDumpButton.Text = "◈  FULL CLIENT DUMP"
            end
        end)

    else
        setStatus(
            "SAVE FAILED",
            tostring(result),
            C.Red
        )

        DumpButton.Text = "DUMP FAILED"
        FullDumpButton.Text = "!  DUMP FAILED"

        log("ERROR: " .. tostring(result))

        notify(
            "Dump failed",
            tostring(result),
            "error",
            6
        )
    end

    updateStats()

    Busy = false
end

local function runDumpSafe()
    task.spawn(function()
        local success, err = pcall(executeDump)

        if not success then
            Busy = false

            DumpButton.Text = "DUMP FAILED"
            FullDumpButton.Text = "!  DUMP FAILED"

            setStatus(
                "ERROR",
                tostring(err),
                C.Red
            )

            log("ERROR: " .. tostring(err))

            notify(
                "Inspector error",
                tostring(err),
                "error",
                6
            )
        end
    end)
end

DumpButton.MouseButton1Click:Connect(runDumpSafe)
FullDumpButton.MouseButton1Click:Connect(runDumpSafe)

--==============================================================
-- DRAGGING
--==============================================================

local Dragging = false
local DragStart
local StartPosition

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        )
    then
        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )

        Shadow.Position = UDim2.new(
            Main.Position.X.Scale,
            Main.Position.X.Offset,
            Main.Position.Y.Scale,
            Main.Position.Y.Offset + 8
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        Dragging = false
    end
end)

--==============================================================
-- FLOATING REOPEN BUTTON
--==============================================================

local Floating = new("TextButton", {
    AnchorPoint = Vector2.new(1, .5),

    Position = UDim2.new(1, -18, .5, 0),
    Size = UDim2.fromOffset(54, 54),

    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,

    Text = "D",
    Font = Enum.Font.GothamBlack,
    TextSize = 21,
    TextColor3 = Color3.new(1, 1, 1),

    Visible = false,

    Parent = GUI
})

corner(Floating, 17)
stroke(Floating, C.Cyan, .45)

new("UIGradient", {
    Rotation = 45,

    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Purple),
        ColorSequenceKeypoint.new(1, C.Blue)
    }),

    Parent = Floating
})

local function setMainVisible(value)
    Main.Visible = value
    Shadow.Visible = value
    Floating.Visible = not value
end

Close.MouseButton1Click:Connect(function()
    setMainVisible(false)
end)

Floating.MouseButton1Click:Connect(function()
    setMainVisible(true)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == CONFIG.ToggleKey then
        setMainVisible(not Main.Visible)
    end
end)

--==============================================================
-- LIVE PULSE
--==============================================================

task.spawn(function()
    while GUI.Parent do
        if Live.Enabled then
            TweenService:Create(
                LiveDot,
                TweenInfo.new(.45),
                {
                    BackgroundTransparency = .65,
                    Size = UDim2.fromOffset(11, 11)
                }
            ):Play()

            task.wait(.45)

            if not Live.Enabled then
                continue
            end

            TweenService:Create(
                LiveDot,
                TweenInfo.new(.45),
                {
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(8, 8)
                }
            ):Play()

            task.wait(.45)
        else
            LiveDot.BackgroundTransparency = 0
            LiveDot.Size = UDim2.fromOffset(8, 8)
            task.wait(.5)
        end
    end
end)

--==============================================================
-- READY
--==============================================================

if type(writefile) == "function" then
    setStatus(
        "READY",
        "Full Dump and Remote Live are ready",
        C.Green
    )

    log("writefile ready")
else
    setStatus(
        "LIMITED",
        "writefile unavailable — live view can run but files cannot save",
        C.Yellow
    )

    log("writefile unavailable")

    notify(
        "Limited environment",
        "writefile is unavailable. File output cannot be saved.",
        "warning",
        5
    )
end

log("Premium dashboard loaded")
log("Remote Live ready")
log("Critical scans execute before Workspace")
log("Ready.")

task.delay(.5, function()
    notify(
        "DEVIL DUMP V4",
        "Inspector loaded successfully. Full Dump + Remote Live ready.",
        "success",
        4
    )
end)
