--==============================================================
-- DEVIL DUMP V4.2
-- FULL STANDALONE / MOBILE RESPONSIVE / PASSIVE REMOTE LIVE
--==============================================================

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer

if not Player then
    warn("[DEVIL DUMP] LocalPlayer unavailable")
    return
end

local PlayerGui = Player:WaitForChild("PlayerGui", 15)

if not PlayerGui then
    warn("[DEVIL DUMP] PlayerGui unavailable")
    return
end

--==============================================================
-- CONFIG
--==============================================================

local CONFIG = {
    ToggleKey = Enum.KeyCode.RightShift,

    Folder = "DevilDump",

    BaseWidth = 820,
    BaseHeight = 500,

    MarginX = 26,
    MarginY = 26,

    MaxConsoleLines = 14,
    MaxLiveEntries = 15000,

    AutoSaveEvery = 50
}

--==============================================================
-- FILE SUPPORT
--==============================================================

local FILE_SUPPORT =
    type(writefile) == "function"

local FOLDER_SUPPORT =
    type(makefolder) == "function"
    and type(isfolder) == "function"

local function ensureFolder()
    if not FOLDER_SUPPORT then
        return false
    end

    local ok = pcall(function()
        if not isfolder(CONFIG.Folder) then
            makefolder(CONFIG.Folder)
        end
    end)

    return ok
end

ensureFolder()

--==============================================================
-- STATE
--==============================================================

local State = {
    Dumping = false,

    Instances = 0,
    Scripts = 0,
    Remotes = 0,

    LastDumpFile = nil
}

local Live = {
    Enabled = false,

    Count = 0,

    Entries = {},
    Connections = {},
    Registered = {},

    File = nil
}

--==============================================================
-- THEME
--==============================================================

local C = {
    Background = Color3.fromRGB(5, 7, 12),

    Surface = Color3.fromRGB(10, 14, 23),
    Surface2 = Color3.fromRGB(14, 19, 31),
    Surface3 = Color3.fromRGB(19, 25, 40),

    Border = Color3.fromRGB(42, 53, 78),
    BorderBright = Color3.fromRGB(67, 83, 120),

    Blue = Color3.fromRGB(72, 128, 255),
    BlueSoft = Color3.fromRGB(95, 151, 255),

    Purple = Color3.fromRGB(137, 92, 255),
    Cyan = Color3.fromRGB(77, 211, 255),

    Green = Color3.fromRGB(68, 218, 146),
    Yellow = Color3.fromRGB(255, 194, 82),
    Red = Color3.fromRGB(255, 91, 112),

    Text = Color3.fromRGB(244, 247, 255),
    Text2 = Color3.fromRGB(190, 200, 222),

    Muted = Color3.fromRGB(122, 135, 164),
    Muted2 = Color3.fromRGB(77, 89, 116)
}

--==============================================================
-- HELPERS
--==============================================================

local function create(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            pcall(function()
                object[property] = value
            end)
        end
    end

    if properties and properties.Parent then
        object.Parent = properties.Parent
    end

    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = parent
    })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or C.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function label(
    parent,
    text,
    position,
    size,
    font,
    textSize,
    color
)
    return create("TextLabel", {
        BackgroundTransparency = 1,

        Position = position or UDim2.new(),
        Size = size or UDim2.fromOffset(100, 20),

        Text = text or "",

        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 13,

        TextColor3 = color or C.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,

        Parent = parent
    })
end

local function button(
    parent,
    text,
    position,
    size,
    background
)
    local b = create("TextButton", {
        AutoButtonColor = false,

        Position = position,
        Size = size,

        BackgroundColor3 = background or C.Surface2,
        BorderSizePixel = 0,

        Text = text,

        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
        TextColor3 = C.Text,

        Parent = parent
    })

    corner(b, 10)

    local s = stroke(
        b,
        C.Border,
        0.35,
        1
    )

    b.MouseEnter:Connect(function()
        TweenService:Create(
            b,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 = C.Surface3
            }
        ):Play()

        TweenService:Create(
            s,
            TweenInfo.new(0.12),
            {
                Color = C.BorderBright,
                Transparency = 0.1
            }
        ):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(
            b,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 = background or C.Surface2
            }
        ):Play()

        TweenService:Create(
            s,
            TweenInfo.new(0.12),
            {
                Color = C.Border,
                Transparency = 0.35
            }
        ):Play()
    end)

    return b
end

--==============================================================
-- REMOVE PREVIOUS GUI
--==============================================================

local old = PlayerGui:FindFirstChild("DEVIL_DUMP_V42")

if old then
    old:Destroy()
end

--==============================================================
-- GUI
--==============================================================

local GUI = create("ScreenGui", {
    Name = "DEVIL_DUMP_V42",

    ResetOnSpawn = false,
    IgnoreGuiInset = true,

    DisplayOrder = 999999,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

    Parent = PlayerGui
})

--==============================================================
-- ROOT
--==============================================================

local Root = create("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5),

    Position = UDim2.fromScale(0.5, 0.5),

    Size = UDim2.fromOffset(
        CONFIG.BaseWidth,
        CONFIG.BaseHeight
    ),

    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,

    ClipsDescendants = true,

    Parent = GUI
})

corner(Root, 18)
stroke(Root, C.BorderBright, 0.35)

local UIScaleObject = create("UIScale", {
    Scale = 1,
    Parent = Root
})

--==============================================================
-- RESPONSIVE ENGINE
--==============================================================

local function updateScale()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local availableX =
        math.max(
            viewport.X - CONFIG.MarginX * 2,
            100
        )

    local availableY =
        math.max(
            viewport.Y - CONFIG.MarginY * 2,
            100
        )

    local sx =
        availableX / CONFIG.BaseWidth

    local sy =
        availableY / CONFIG.BaseHeight

    local scale =
        math.min(sx, sy, 1)

    if UserInputService.TouchEnabled then
        scale = scale * 0.94
    end

    UIScaleObject.Scale =
        math.clamp(scale, 0.28, 1)
end

local function centerWindow()
    Root.AnchorPoint =
        Vector2.new(0.5, 0.5)

    Root.Position =
        UDim2.fromScale(0.5, 0.5)
end

updateScale()
centerWindow()

--==============================================================
-- ACCENT
--==============================================================

local Accent = create("Frame", {
    Size = UDim2.new(1, 0, 0, 2),

    BackgroundColor3 = C.Blue,
    BorderSizePixel = 0,

    Parent = Root
})

create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            C.Blue
        ),

        ColorSequenceKeypoint.new(
            0.5,
            C.Purple
        ),

        ColorSequenceKeypoint.new(
            1,
            C.Cyan
        )
    }),

    Parent = Accent
})

--==============================================================
-- HEADER
--==============================================================

local Header = create("Frame", {
    Position = UDim2.fromOffset(0, 2),

    Size = UDim2.new(1, 0, 0, 68),

    BackgroundTransparency = 1,

    Active = true,

    Parent = Root
})

local DragArea = create("TextButton", {
    Size = UDim2.fromScale(1, 1),

    BackgroundTransparency = 1,

    Text = "",

    AutoButtonColor = false,

    Active = true,

    ZIndex = 1,

    Parent = Header
})

local Brand = create("Frame", {
    Position = UDim2.fromOffset(20, 16),

    Size = UDim2.fromOffset(36, 36),

    BackgroundColor3 = C.Blue,

    BorderSizePixel = 0,

    ZIndex = 3,

    Parent = Header
})

corner(Brand, 10)

create("UIGradient", {
    Rotation = 45,

    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            C.Blue
        ),

        ColorSequenceKeypoint.new(
            1,
            C.Purple
        )
    }),

    Parent = Brand
})

local BrandText = label(
    Brand,
    "D",
    UDim2.new(),
    UDim2.fromScale(1, 1),
    Enum.Font.GothamBold,
    17,
    C.Text
)

BrandText.TextXAlignment =
    Enum.TextXAlignment.Center

BrandText.ZIndex = 4

local Title = label(
    Header,
    "DEVIL DUMP",
    UDim2.fromOffset(68, 13),
    UDim2.fromOffset(270, 23),
    Enum.Font.GothamBold,
    16,
    C.Text
)

Title.ZIndex = 3

local Subtitle = label(
    Header,
    "CLIENT INSPECTOR / REMOTE LIVE",
    UDim2.fromOffset(68, 36),
    UDim2.fromOffset(300, 16),
    Enum.Font.GothamMedium,
    9,
    C.Muted
)

Subtitle.ZIndex = 3

local Version = create("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),

    Position = UDim2.new(
        1,
        -65,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(50, 24),

    BackgroundColor3 = C.Surface2,

    BorderSizePixel = 0,

    Text = "V4.2",

    Font = Enum.Font.GothamBold,

    TextSize = 9,
    TextColor3 = C.BlueSoft,

    ZIndex = 4,

    Parent = Header
})

corner(Version, 7)
stroke(Version, C.Blue, 0.65)

local Close = button(
    Header,
    "X",
    UDim2.new(1, -44, 0.5, -14),
    UDim2.fromOffset(28, 28),
    C.Surface2
)

Close.ZIndex = 5

--==============================================================
-- DIVIDER
--==============================================================

create("Frame", {
    Position = UDim2.fromOffset(20, 69),

    Size = UDim2.new(1, -40, 0, 1),

    BackgroundColor3 = C.Border,
    BackgroundTransparency = 0.55,

    BorderSizePixel = 0,

    Parent = Root
})

--==============================================================
-- SIDEBAR
--==============================================================

local Sidebar = create("Frame", {
    Position = UDim2.fromOffset(18, 86),

    Size = UDim2.fromOffset(174, 393),

    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,

    Parent = Root
})

corner(Sidebar, 13)
stroke(Sidebar, C.Border, 0.42)

label(
    Sidebar,
    "CONTROL CENTER",
    UDim2.fromOffset(14, 12),
    UDim2.new(1, -28, 0, 17),
    Enum.Font.GothamBold,
    8,
    C.Muted
)

local function navButton(
    titleText,
    subtitleText,
    y,
    accentColor
)
    local b = create("TextButton", {
        Position = UDim2.fromOffset(10, y),

        Size = UDim2.new(1, -20, 0, 56),

        BackgroundColor3 = C.Surface2,

        BorderSizePixel = 0,

        AutoButtonColor = false,

        Text = "",

        Parent = Sidebar
    })

    corner(b, 10)
    stroke(b, C.Border, 0.5)

    local bar = create("Frame", {
        Position = UDim2.fromOffset(0, 11),

        Size = UDim2.fromOffset(3, 34),

        BackgroundColor3 = accentColor,

        BorderSizePixel = 0,

        Parent = b
    })

    corner(bar, 3)

    label(
        b,
        titleText,
        UDim2.fromOffset(13, 8),
        UDim2.new(1, -24, 0, 19),
        Enum.Font.GothamSemibold,
        10,
        C.Text
    )

    label(
        b,
        subtitleText,
        UDim2.fromOffset(13, 28),
        UDim2.new(1, -24, 0, 16),
        Enum.Font.Gotham,
        8,
        C.Muted
    )

    return b
end

local FullDumpButton = navButton(
    "FULL CLIENT DUMP",
    "Scan visible client data",
    39,
    C.Blue
)

local LiveButton = navButton(
    "REMOTE LIVE",
    "Passive incoming monitor",
    103,
    C.Cyan
)

local ClearButton = navButton(
    "CLEAR CONSOLE",
    "Reset activity output",
    167,
    C.Purple
)

--==============================================================
-- LIVE CARD
--==============================================================

local LiveCard = create("Frame", {
    Position = UDim2.new(
        0,
        10,
        1,
        -103
    ),

    Size = UDim2.new(
        1,
        -20,
        0,
        91
    ),

    BackgroundColor3 = C.Background,

    BorderSizePixel = 0,

    Parent = Sidebar
})

corner(LiveCard, 10)
stroke(LiveCard, C.Border, 0.5)

local LiveDot = create("Frame", {
    Position = UDim2.fromOffset(13, 14),

    Size = UDim2.fromOffset(7, 7),

    BackgroundColor3 = C.Muted2,

    BorderSizePixel = 0,

    Parent = LiveCard
})

corner(LiveDot, 100)

local LiveStateText = label(
    LiveCard,
    "REMOTE LIVE OFF",
    UDim2.fromOffset(29, 7),
    UDim2.new(1, -39, 0, 20),
    Enum.Font.GothamBold,
    9,
    C.Muted
)

local LiveCountText = label(
    LiveCard,
    "0 events captured",
    UDim2.fromOffset(13, 33),
    UDim2.new(1, -26, 0, 16),
    Enum.Font.Gotham,
    8,
    C.Muted
)

local LiveFileText = label(
    LiveCard,
    "No active session",
    UDim2.fromOffset(13, 52),
    UDim2.new(1, -26, 0, 27),
    Enum.Font.Code,
    7,
    C.Muted2
)

LiveFileText.TextWrapped = true

--==============================================================
-- CONTENT
--==============================================================

local Content = create("Frame", {
    Position = UDim2.fromOffset(207, 86),

    Size = UDim2.new(
        1,
        -225,
        1,
        -107
    ),

    BackgroundTransparency = 1,

    Parent = Root
})

--==============================================================
-- STATUS
--==============================================================

local StatusCard = create("Frame", {
    Size = UDim2.new(1, 0, 0, 67),

    BackgroundColor3 = C.Surface,

    BorderSizePixel = 0,

    Parent = Content
})

corner(StatusCard, 13)
stroke(StatusCard, C.Border, 0.42)

local StatusDot = create("Frame", {
    Position = UDim2.fromOffset(15, 15),

    Size = UDim2.fromOffset(8, 8),

    BackgroundColor3 = C.Green,

    BorderSizePixel = 0,

    Parent = StatusCard
})

corner(StatusDot, 100)

local Status = label(
    StatusCard,
    "READY",
    UDim2.fromOffset(32, 8),
    UDim2.new(1, -45, 0, 20),
    Enum.Font.GothamBold,
    10,
    C.Green
)

local Detail = label(
    StatusCard,
    "Waiting for command",
    UDim2.fromOffset(15, 30),
    UDim2.new(1, -30, 0, 17),
    Enum.Font.Gotham,
    9,
    C.Muted
)

Detail.TextTruncate =
    Enum.TextTruncate.AtEnd

local ProgressBG = create("Frame", {
    Position = UDim2.new(
        0,
        15,
        1,
        -10
    ),

    Size = UDim2.new(
        1,
        -30,
        0,
        3
    ),

    BackgroundColor3 = C.Surface3,

    BorderSizePixel = 0,

    Parent = StatusCard
})

corner(ProgressBG, 100)

local Progress = create("Frame", {
    Size = UDim2.fromScale(0, 1),

    BackgroundColor3 = C.Blue,

    BorderSizePixel = 0,

    Parent = ProgressBG
})

corner(Progress, 100)

--==============================================================
-- STATS
--==============================================================

local StatsRow = create("Frame", {
    Position = UDim2.fromOffset(0, 78),

    Size = UDim2.new(1, 0, 0, 59),

    BackgroundTransparency = 1,

    Parent = Content
})

local function statCard(x, titleText, color)
    local card = create("Frame", {
        Position = UDim2.new(
            x,
            x == 0 and 0 or 3,
            0,
            0
        ),

        Size = UDim2.new(
            0.25,
            -6,
            1,
            0
        ),

        BackgroundColor3 = C.Surface,

        BorderSizePixel = 0,

        Parent = StatsRow
    })

    corner(card, 10)
    stroke(card, C.Border, 0.5)

    create("Frame", {
        Position = UDim2.fromOffset(9, 10),

        Size = UDim2.fromOffset(3, 17),

        BackgroundColor3 = color,

        BorderSizePixel = 0,

        Parent = card
    })

    label(
        card,
        titleText,
        UDim2.fromOffset(18, 7),
        UDim2.new(1, -23, 0, 17),
        Enum.Font.GothamBold,
        7,
        C.Muted
    )

    return label(
        card,
        "0",
        UDim2.fromOffset(10, 27),
        UDim2.new(1, -20, 0, 23),
        Enum.Font.GothamBold,
        16,
        C.Text
    )
end

local InstanceStat =
    statCard(
        0,
        "INSTANCES",
        C.Blue
    )

local ScriptStat =
    statCard(
        0.25,
        "SCRIPTS",
        C.Purple
    )

local RemoteStat =
    statCard(
        0.50,
        "REMOTES",
        C.Cyan
    )

local LiveStat =
    statCard(
        0.75,
        "LIVE",
        C.Green
    )

--==============================================================
-- CONSOLE
--==============================================================

local ConsoleCard = create("Frame", {
    Position = UDim2.fromOffset(0, 148),

    Size = UDim2.new(
        1,
        0,
        1,
        -207
    ),

    BackgroundColor3 = C.Surface,

    BorderSizePixel = 0,

    Parent = Content
})

corner(ConsoleCard, 12)
stroke(ConsoleCard, C.Border, 0.48)

label(
    ConsoleCard,
    "ACTIVITY LOG",
    UDim2.fromOffset(13, 7),
    UDim2.new(1, -26, 0, 19),
    Enum.Font.GothamBold,
    8,
    C.Muted
)

local Console = create("TextLabel", {
    Position = UDim2.fromOffset(13, 33),

    Size = UDim2.new(
        1,
        -26,
        1,
        -42
    ),

    BackgroundTransparency = 1,

    Text = "> DEVIL DUMP initialized",

    Font = Enum.Font.Code,

    TextSize = 9,

    TextColor3 = C.Text2,

    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,

    TextWrapped = true,

    Parent = ConsoleCard
})

--==============================================================
-- ACTION BAR
--==============================================================

local ActionBar = create("Frame", {
    AnchorPoint = Vector2.new(0, 1),

    Position = UDim2.new(
        0,
        0,
        1,
        0
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        47
    ),

    BackgroundTransparency = 1,

    Parent = Content
})

local DumpButton = button(
    ActionBar,
    "START FULL CLIENT DUMP",
    UDim2.fromOffset(0, 0),
    UDim2.new(
        0.66,
        -5,
        1,
        0
    ),
    C.Blue
)

local RemoteButton = button(
    ActionBar,
    "START REMOTE LIVE",
    UDim2.new(
        0.66,
        5,
        0,
        0
    ),
    UDim2.new(
        0.34,
        -5,
        1,
        0
    ),
    C.Surface2
)

--==============================================================
-- TOAST
--==============================================================

local ToastHolder = create("Frame", {
    AnchorPoint = Vector2.new(1, 0),

    Position = UDim2.new(
        1,
        -14,
        0,
        14
    ),

    Size = UDim2.fromOffset(290, 400),

    BackgroundTransparency = 1,

    Parent = GUI
})

create("UIListLayout", {
    Padding = UDim.new(0, 8),

    HorizontalAlignment =
        Enum.HorizontalAlignment.Right,

    SortOrder =
        Enum.SortOrder.LayoutOrder,

    Parent = ToastHolder
})

local ToastScale = create("UIScale", {
    Scale = 1,
    Parent = ToastHolder
})

local ToastOrder = 0

local function notify(
    titleText,
    message,
    kind
)
    ToastOrder += 1

    local accent = C.Blue

    if kind == "success" then
        accent = C.Green

    elseif kind == "error" then
        accent = C.Red

    elseif kind == "warning" then
        accent = C.Yellow

    elseif kind == "live" then
        accent = C.Cyan
    end

    local toast = create("Frame", {
        Size = UDim2.fromOffset(280, 68),

        BackgroundColor3 = C.Surface,

        BorderSizePixel = 0,

        LayoutOrder = ToastOrder,

        Parent = ToastHolder
    })

    corner(toast, 11)
    stroke(toast, C.Border, 0.25)

    local bar = create("Frame", {
        Position = UDim2.fromOffset(0, 9),

        Size = UDim2.fromOffset(3, 50),

        BackgroundColor3 = accent,

        BorderSizePixel = 0,

        Parent = toast
    })

    corner(bar, 3)

    local dot = create("Frame", {
        Position = UDim2.fromOffset(14, 17),

        Size = UDim2.fromOffset(7, 7),

        BackgroundColor3 = accent,

        BorderSizePixel = 0,

        Parent = toast
    })

    corner(dot, 100)

    label(
        toast,
        titleText,
        UDim2.fromOffset(30, 8),
        UDim2.new(1, -40, 0, 20),
        Enum.Font.GothamBold,
        10,
        C.Text
    )

    local msg = label(
        toast,
        message,
        UDim2.fromOffset(30, 29),
        UDim2.new(1, -40, 0, 30),
        Enum.Font.Gotham,
        8,
        C.Muted
    )

    msg.TextWrapped = true
    msg.TextYAlignment =
        Enum.TextYAlignment.Top

    task.delay(4, function()
        if not toast.Parent then
            return
        end

        TweenService:Create(
            toast,
            TweenInfo.new(0.18),
            {
                BackgroundTransparency = 1
            }
        ):Play()

        task.wait(0.2)

        if toast then
            toast:Destroy()
        end
    end)
end

--==============================================================
-- LOGGING
--==============================================================

local ConsoleLines = {}

local function log(message)
    local line =
        "[" ..
        os.date("%H:%M:%S") ..
        "] " ..
        tostring(message)

    table.insert(
        ConsoleLines,
        line
    )

    while #ConsoleLines >
        CONFIG.MaxConsoleLines
    do
        table.remove(
            ConsoleLines,
            1
        )
    end

    Console.Text =
        "> " ..
        table.concat(
            ConsoleLines,
            "\n> "
        )
end

local function setStatus(
    titleText,
    detailText,
    color
)
    color = color or C.Green

    Status.Text = titleText
    Status.TextColor3 = color

    Detail.Text =
        detailText or ""

    StatusDot.BackgroundColor3 =
        color
end

local function setProgress(value)
    value =
        math.clamp(
            value,
            0,
            1
        )

    TweenService:Create(
        Progress,
        TweenInfo.new(0.15),
        {
            Size =
                UDim2.fromScale(
                    value,
                    1
                )
        }
    ):Play()
end

--==============================================================
-- SERIALIZER
--==============================================================

local function safeString(value)
    local t = typeof(value)

    if t == "string" then
        local text = value

        if #text > 500 then
            text =
                text:sub(1, 500)
                .. "...[truncated]"
        end

        return string.format("%q", text)

    elseif t == "Instance" then
        local ok, fullName =
            pcall(function()
                return value:GetFullName()
            end)

        return ok
            and fullName
            or value.Name

    elseif t == "Vector3"
        or t == "Vector2"
        or t == "CFrame"
        or t == "Color3"
        or t == "UDim2"
        or t == "UDim"
    then
        return tostring(value)

    elseif t == "table" then
        return "{table}"

    else
        return tostring(value)
    end
end

local function serializeArgs(...)
    local args = table.pack(...)

    local output = {}

    for i = 1, args.n do
        output[#output + 1] =
            "[" ..
            i ..
            "]=" ..
            safeString(args[i])
    end

    return table.concat(
        output,
        ", "
    )
end

--==============================================================
-- OBJECT PATH
--==============================================================

local function objectPath(object)
    local ok, result =
        pcall(function()
            return object:GetFullName()
        end)

    if ok then
        return result
    end

    return object.Name
end

--==============================================================
-- DUMP ENGINE
--==============================================================

local function inspectObject(object, output)
    if object == GUI
        or object:IsDescendantOf(GUI)
    then
        return
    end

    State.Instances += 1

    local className =
        object.ClassName

    local path =
        objectPath(object)

    output[#output + 1] =
        string.format(
            "[%s] %s",
            className,
            path
        )

    -- Scripts
    if object:IsA("LocalScript")
        or object:IsA("ModuleScript")
    then
        State.Scripts += 1

        output[#output + 1] =
            "  Script.Enabled="
            .. tostring(
                not object:IsA("LocalScript")
                or object.Enabled
            )

        local okSource, source =
            pcall(function()
                return object.Source
            end)

        if okSource
            and source
            and source ~= ""
        then
            output[#output + 1] =
                "  SourceLength="
                .. tostring(#source)
        end
    end

    -- Remotes
    if object:IsA("RemoteEvent")
        or object:IsA("RemoteFunction")
        or object:IsA("BindableEvent")
        or object:IsA("BindableFunction")
    then
        State.Remotes += 1
    end

    -- ValueBase
    if object:IsA("ValueBase") then
        local ok, value =
            pcall(function()
                return object.Value
            end)

        if ok then
            output[#output + 1] =
                "  Value="
                .. safeString(value)
        end
    end

    -- Attributes
    local okAttributes, attributes =
        pcall(function()
            return object:GetAttributes()
        end)

    if okAttributes
        and next(attributes)
    then
        for name, value in pairs(attributes) do
            output[#output + 1] =
                "  Attribute."
                .. tostring(name)
                .. "="
                .. safeString(value)
        end
    end

    -- Tags
    local okTags, tags =
        pcall(function()
            return CollectionService:GetTags(
                object
            )
        end)

    if okTags and #tags > 0 then
        output[#output + 1] =
            "  Tags="
            .. table.concat(tags, ",")
    end

    -- BasePart
    if object:IsA("BasePart") then
        output[#output + 1] =
            "  Position="
            .. tostring(object.Position)

        output[#output + 1] =
            "  Size="
            .. tostring(object.Size)
    end

    -- GUI text
    if object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    then
        if object.Text ~= "" then
            output[#output + 1] =
                "  Text="
                .. safeString(object.Text)
        end
    end

    -- Sound
    if object:IsA("Sound") then
        output[#output + 1] =
            "  SoundId="
            .. tostring(object.SoundId)
    end

    -- Animation
    if object:IsA("Animation") then
        output[#output + 1] =
            "  AnimationId="
            .. tostring(
                object.AnimationId
            )
    end

    -- Prompt
    if object:IsA(
        "ProximityPrompt"
    ) then
        output[#output + 1] =
            "  ActionText="
            .. safeString(
                object.ActionText
            )

        output[#output + 1] =
            "  ObjectText="
            .. safeString(
                object.ObjectText
            )
    end
end

local function performDump()
    if State.Dumping then
        notify(
            "Dump already running",
            "Wait for the current scan to finish.",
            "warning"
        )

        return
    end

    State.Dumping = true

    State.Instances = 0
    State.Scripts = 0
    State.Remotes = 0

    InstanceStat.Text = "0"
    ScriptStat.Text = "0"
    RemoteStat.Text = "0"

    DumpButton.Text =
        "SCANNING..."

    setStatus(
        "SCANNING",
        "Collecting client-visible instances",
        C.Blue
    )

    setProgress(0)

    log("Full client dump started")

    task.spawn(function()
        local ok, err =
            pcall(function()

                local roots = {}

                local serviceNames = {
                    "ReplicatedStorage",
                    "ReplicatedFirst",
                    "Lighting",
                    "SoundService",
                    "Workspace"
                }

                for _, serviceName
                    in ipairs(serviceNames)
                do
                    local okService, service =
                        pcall(function()
                            return game:GetService(
                                serviceName
                            )
                        end)

                    if okService and service then
                        roots[#roots + 1] =
                            service
                    end
                end

                local playerScripts =
                    Player:FindFirstChild(
                        "PlayerScripts"
                    )

                local backpack =
                    Player:FindFirstChild(
                        "Backpack"
                    )

                if playerScripts then
                    roots[#roots + 1] =
                        playerScripts
                end

                if PlayerGui then
                    roots[#roots + 1] =
                        PlayerGui
                end

                if backpack then
                    roots[#roots + 1] =
                        backpack
                end

                if Player.Character then
                    roots[#roots + 1] =
                        Player.Character
                end

                local objects = {}

                for _, root
                    in ipairs(roots)
                do
                    objects[#objects + 1] =
                        root

                    local okDesc, descendants =
                        pcall(function()
                            return root:GetDescendants()
                        end)

                    if okDesc then
                        for _, object
                            in ipairs(descendants)
                        do
                            if object ~= GUI
                                and not object:IsDescendantOf(GUI)
                            then
                                objects[#objects + 1] =
                                    object
                            end
                        end
                    end
                end

                local output = {
                    "==============================================",
                    "DEVIL DUMP V4.2",
                    "PlaceId = " .. tostring(game.PlaceId),
                    "Player = " .. tostring(Player.Name),
                    "Time = " .. os.date("%Y-%m-%d %H:%M:%S"),
                    "==============================================",
                    ""
                }

                local total =
                    math.max(#objects, 1)

                for index, object
                    in ipairs(objects)
                do
                    inspectObject(
                        object,
                        output
                    )

                    if index % 150 == 0
                        or index == total
                    then
                        InstanceStat.Text =
                            tostring(
                                State.Instances
                            )

                        ScriptStat.Text =
                            tostring(
                                State.Scripts
                            )

                        RemoteStat.Text =
                            tostring(
                                State.Remotes
                            )

                        setProgress(
                            index / total
                        )

                        Detail.Text =
                            string.format(
                                "%d / %d objects",
                                index,
                                total
                            )

                        task.wait()
                    end
                end

                output[#output + 1] = ""
                output[#output + 1] =
                    "=============================================="

                output[#output + 1] =
                    "Instances = "
                    .. State.Instances

                output[#output + 1] =
                    "Scripts = "
                    .. State.Scripts

                output[#output + 1] =
                    "Remotes = "
                    .. State.Remotes

                output[#output + 1] =
                    "=============================================="

                local fileName =
                    CONFIG.Folder
                    .. "/DevilDump_"
                    .. tostring(game.PlaceId)
                    .. "_"
                    .. os.date("%Y%m%d_%H%M%S")
                    .. ".txt"

                State.LastDumpFile =
                    fileName

                if FILE_SUPPORT then
                    ensureFolder()

                    writefile(
                        fileName,
                        table.concat(
                            output,
                            "\n"
                        )
                    )
                end
            end)

        State.Dumping = false

        DumpButton.Text =
            "START FULL CLIENT DUMP"

        if ok then
            setProgress(1)

            setStatus(
                "COMPLETE",
                FILE_SUPPORT
                    and State.LastDumpFile
                    or "Scan complete - file API unavailable",
                C.Green
            )

            log(
                "Dump complete | "
                .. State.Instances
                .. " instances"
            )

            notify(
                "Dump completed",
                FILE_SUPPORT
                    and (
                        State.Instances
                        .. " objects saved."
                    )
                    or (
                        State.Instances
                        .. " objects scanned."
                    ),
                "success"
            )

        else
            setStatus(
                "ERROR",
                tostring(err),
                C.Red
            )

            log(
                "Dump error: "
                .. tostring(err)
            )

            notify(
                "Dump failed",
                tostring(err),
                "error"
            )
        end
    end)
end

--==============================================================
-- PASSIVE REMOTE LIVE
--
-- Only observes incoming RemoteEvent.OnClientEvent
-- and BindableEvent.Event.
-- It does not FireServer / InvokeServer.
--==============================================================

local function saveLive()
    if not Live.File
        or not FILE_SUPPORT
    then
        return
    end

    ensureFolder()

    local header = {
        "==============================================",
        "DEVIL REMOTE LIVE V4.2",
        "PlaceId = " .. tostring(game.PlaceId),
        "Player = " .. tostring(Player.Name),
        "Entries = " .. tostring(Live.Count),
        "==============================================",
        ""
    }

    local content = {}

    for _, lineText in ipairs(header) do
        content[#content + 1] =
            lineText
    end

    for _, lineText
        in ipairs(Live.Entries)
    do
        content[#content + 1] =
            lineText
    end

    pcall(function()
        writefile(
            Live.File,
            table.concat(
                content,
                "\n"
            )
        )
    end)
end

local function liveRecord(
    kind,
    remote,
    ...
)
    if not Live.Enabled then
        return
    end

    Live.Count += 1

    local entry =
        string.format(
            "[%s] [%s] %s | %s",
            os.date("%H:%M:%S"),
            kind,
            objectPath(remote),
            serializeArgs(...)
        )

    table.insert(
        Live.Entries,
        entry
    )

    while #Live.Entries >
        CONFIG.MaxLiveEntries
    do
        table.remove(
            Live.Entries,
            1
        )
    end

    LiveStat.Text =
        tostring(Live.Count)

    LiveCountText.Text =
        tostring(Live.Count)
        .. " events captured"

    log(
        kind
        .. " | "
        .. remote.Name
    )

    if Live.Count %
        CONFIG.AutoSaveEvery == 0
    then
        saveLive()
    end
end

local function registerLiveObject(object)
    if Live.Registered[object] then
        return
    end

    if object == GUI
        or object:IsDescendantOf(GUI)
    then
        return
    end

    if object:IsA("RemoteEvent") then
        Live.Registered[object] =
            true

        local connection =
            object.OnClientEvent:Connect(
                function(...)
                    liveRecord(
                        "RemoteEvent",
                        object,
                        ...
                    )
                end
            )

        table.insert(
            Live.Connections,
            connection
        )

    elseif object:IsA("BindableEvent") then
        Live.Registered[object] =
            true

        local connection =
            object.Event:Connect(
                function(...)
                    liveRecord(
                        "BindableEvent",
                        object,
                        ...
                    )
                end
            )

        table.insert(
            Live.Connections,
            connection
        )
    end
end

local function startLive()
    if Live.Enabled then
        return
    end

    Live.Enabled = true

    Live.Count = 0
    Live.Entries = {}
    Live.Connections = {}
    Live.Registered = {}

    Live.File =
        CONFIG.Folder
        .. "/RemoteLive_"
        .. tostring(game.PlaceId)
        .. "_"
        .. os.date("%Y%m%d_%H%M%S")
        .. ".txt"

    LiveStat.Text = "0"

    LiveStateText.Text =
        "REMOTE LIVE ON"

    LiveStateText.TextColor3 =
        C.Cyan

    LiveDot.BackgroundColor3 =
        C.Cyan

    LiveCountText.Text =
        "0 events captured"

    LiveFileText.Text =
        FILE_SUPPORT
            and Live.File
            or "File API unavailable"

    RemoteButton.Text =
        "STOP REMOTE LIVE"

    log("Remote Live started")

    setStatus(
        "REMOTE LIVE",
        "Listening for incoming client events",
        C.Cyan
    )

    local roots = {
        game:GetService(
            "ReplicatedStorage"
        ),

        workspace,

        PlayerGui
    }

    local playerScripts =
        Player:FindFirstChild(
            "PlayerScripts"
        )

    if playerScripts then
        roots[#roots + 1] =
            playerScripts
    end

    for _, root in ipairs(roots) do
        registerLiveObject(root)

        for _, object
            in ipairs(root:GetDescendants())
        do
            registerLiveObject(object)
        end

        local connection =
            root.DescendantAdded:Connect(
                function(object)
                    if Live.Enabled then
                        registerLiveObject(
                            object
                        )
                    end
                end
            )

        table.insert(
            Live.Connections,
            connection
        )
    end

    notify(
        "Remote Live started",
        "Incoming client events are now being monitored.",
        "live"
    )
end

local function stopLive()
    if not Live.Enabled then
        return
    end

    Live.Enabled = false

    saveLive()

    for _, connection
        in ipairs(Live.Connections)
    do
        pcall(function()
            connection:Disconnect()
        end)
    end

    Live.Connections = {}
    Live.Registered = {}

    LiveStateText.Text =
        "REMOTE LIVE OFF"

    LiveStateText.TextColor3 =
        C.Muted

    LiveDot.BackgroundColor3 =
        C.Muted2

    RemoteButton.Text =
        "START REMOTE LIVE"

    setStatus(
        "READY",
        "Remote Live stopped",
        C.Green
    )

    log(
        "Remote Live stopped | "
        .. Live.Count
        .. " events"
    )

    notify(
        "Remote Live stopped",
        tostring(Live.Count)
            .. " events captured.",
        "success"
    )
end

local function toggleLive()
    if Live.Enabled then
        stopLive()
    else
        startLive()
    end
end

--==============================================================
-- BUTTON EVENTS
--==============================================================

DumpButton.MouseButton1Click:Connect(
    performDump
)

FullDumpButton.MouseButton1Click:Connect(
    performDump
)

RemoteButton.MouseButton1Click:Connect(
    toggleLive
)

LiveButton.MouseButton1Click:Connect(
    toggleLive
)

ClearButton.MouseButton1Click:Connect(
    function()
        table.clear(ConsoleLines)

        Console.Text =
            "> Console cleared"

        notify(
            "Console cleared",
            "Activity output reset.",
            "success"
        )
    end
)

--==============================================================
-- FLOATING REOPEN BUTTON
--==============================================================

local Floating = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),

    Position = UDim2.new(
        1,
        -14,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(48, 48),

    BackgroundColor3 = C.Surface,

    BorderSizePixel = 0,

    Text = "D",

    Font = Enum.Font.GothamBold,

    TextSize = 17,
    TextColor3 = C.Text,

    AutoButtonColor = false,

    Visible = false,

    Parent = GUI
})

corner(Floating, 14)
stroke(Floating, C.Blue, 0.2)

local function setVisible(value)
    Root.Visible = value
    Floating.Visible = not value
end

Close.MouseButton1Click:Connect(
    function()
        setVisible(false)
    end
)

Floating.MouseButton1Click:Connect(
    function()
        setVisible(true)

        updateScale()
    end
)

--==============================================================
-- DRAG
--==============================================================

local Dragging = false
local DragInput = nil

local DragStart
local StartPosition

DragArea.InputBegan:Connect(
    function(input)
        local inputType =
            input.UserInputType

        if inputType
                ~= Enum.UserInputType.Touch
            and inputType
                ~= Enum.UserInputType.MouseButton1
        then
            return
        end

        Dragging = true
        DragInput = input

        DragStart =
            input.Position

        StartPosition =
            Root.Position

        input.Changed:Connect(function()
            if input.UserInputState
                == Enum.UserInputState.End
            then
                Dragging = false
                DragInput = nil
            end
        end)
    end
)

UserInputService.InputChanged:Connect(
    function(input)
        if not Dragging
            or not DragInput
        then
            return
        end

        if DragInput.UserInputType
            == Enum.UserInputType.Touch
        then
            if input ~= DragInput then
                return
            end

        elseif input.UserInputType
            ~= Enum.UserInputType.MouseMovement
        then
            return
        end

        local delta =
            input.Position
            - DragStart

        Root.Position =
            UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset
                    + delta.X,

                StartPosition.Y.Scale,
                StartPosition.Y.Offset
                    + delta.Y
            )
    end
)

--==============================================================
-- CLAMP WINDOW
--==============================================================

local function clampWindow()
    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    local scale =
        UIScaleObject.Scale

    local width =
        CONFIG.BaseWidth
        * scale

    local height =
        CONFIG.BaseHeight
        * scale

    local centerX =
        viewport.X
            * Root.Position.X.Scale
        + Root.Position.X.Offset

    local centerY =
        viewport.Y
            * Root.Position.Y.Scale
        + Root.Position.Y.Offset

    local halfW = width / 2
    local halfH = height / 2

    local margin = 8

    local minX =
        halfW + margin

    local maxX =
        viewport.X
        - halfW
        - margin

    local minY =
        halfH + margin

    local maxY =
        viewport.Y
        - halfH
        - margin

    if minX <= maxX then
        centerX =
            math.clamp(
                centerX,
                minX,
                maxX
            )
    else
        centerX =
            viewport.X / 2
    end

    if minY <= maxY then
        centerY =
            math.clamp(
                centerY,
                minY,
                maxY
            )
    else
        centerY =
            viewport.Y / 2
    end

    Root.AnchorPoint =
        Vector2.new(0.5, 0.5)

    Root.Position =
        UDim2.fromOffset(
            centerX,
            centerY
        )
end

UserInputService.InputEnded:Connect(
    function(input)
        if input == DragInput
            or input.UserInputType
                == Enum.UserInputType.MouseButton1
        then
            Dragging = false
            DragInput = nil

            clampWindow()
        end
    end
)

--==============================================================
-- KEYBOARD TOGGLE
--==============================================================

UserInputService.InputBegan:Connect(
    function(input, processed)
        if processed then
            return
        end

        if input.KeyCode
            == CONFIG.ToggleKey
        then
            setVisible(
                not Root.Visible
            )
        end
    end
)

--==============================================================
-- VIEWPORT / MOBILE ORIENTATION
--==============================================================

local LastViewport =
    Vector2.new(-1, -1)

local function updateResponsive()
    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    if viewport == LastViewport then
        return
    end

    LastViewport = viewport

    updateScale()

    if viewport.X < 650 then
        ToastScale.Scale = 0.70

    elseif viewport.X < 900 then
        ToastScale.Scale = 0.82

    else
        ToastScale.Scale = 1
    end

    -- Re-center after orientation change.
    centerWindow()
end

RunService.Heartbeat:Connect(
    updateResponsive
)

workspace:GetPropertyChangedSignal(
    "CurrentCamera"
):Connect(function()
    task.wait()

    updateResponsive()
end)

--==============================================================
-- LIVE PULSE
--==============================================================

task.spawn(function()
    while GUI.Parent do
        if Live.Enabled then
            TweenService:Create(
                LiveDot,
                TweenInfo.new(0.35),
                {
                    BackgroundTransparency =
                        0.55
                }
            ):Play()

            task.wait(0.35)

            if not GUI.Parent then
                break
            end

            TweenService:Create(
                LiveDot,
                TweenInfo.new(0.35),
                {
                    BackgroundTransparency =
                        0
                }
            ):Play()

            task.wait(0.35)
        else
            LiveDot.BackgroundTransparency =
                0

            task.wait(0.35)
        end
    end
end)

--==============================================================
-- STARTUP
--==============================================================

updateResponsive()

setStatus(
    "READY",
    FILE_SUPPORT
        and "File system ready"
        or "GUI ready - file API unavailable",
    C.Green
)

log("DEVIL DUMP V4.2 loaded")
log(
    "Viewport: "
    .. workspace.CurrentCamera.ViewportSize.X
    .. "x"
    .. workspace.CurrentCamera.ViewportSize.Y
)

if UserInputService.TouchEnabled then
    log("Mobile / touch mode detected")
end

if not FILE_SUPPORT then
    log("Warning: writefile unavailable")

    notify(
        "Limited file support",
        "GUI works, but this environment does not expose writefile.",
        "warning"
    )
else
    notify(
        "DEVIL DUMP ready",
        "V4.2 loaded successfully.",
        "success"
    )
end
