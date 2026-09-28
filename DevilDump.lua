--==============================================================
-- DEVIL DUMP V4.1
-- PREMIUM RESPONSIVE MOBILE UI
-- Replace the UI section of V4 with this block
--==============================================================

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

    for propertyName, value in pairs(properties or {}) do
        if propertyName ~= "Parent" then
            pcall(function()
                object[propertyName] = value
            end)
        end
    end

    if properties and properties.Parent then
        object.Parent = properties.Parent
    end

    return object
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = parent
    })
end

local function addStroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or C.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function addPadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent
    })
end

local function makeLabel(
    parent,
    value,
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

        Text = value or "",

        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 13,
        TextColor3 = color or C.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,

        Parent = parent
    })
end

local function makeButton(
    parent,
    value,
    position,
    size,
    background
)
    local buttonObject = create("TextButton", {
        AutoButtonColor = false,

        Position = position,
        Size = size,

        BackgroundColor3 = background or C.Surface2,
        BorderSizePixel = 0,

        Text = value,

        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = C.Text,

        Parent = parent
    })

    addCorner(buttonObject, 10)

    local buttonStroke = addStroke(
        buttonObject,
        C.Border,
        .35,
        1
    )

    buttonObject.MouseEnter:Connect(function()
        TweenService:Create(
            buttonObject,
            TweenInfo.new(.14),
            {
                BackgroundColor3 = C.Surface3
            }
        ):Play()

        TweenService:Create(
            buttonStroke,
            TweenInfo.new(.14),
            {
                Color = C.BorderBright,
                Transparency = .1
            }
        ):Play()
    end)

    buttonObject.MouseLeave:Connect(function()
        TweenService:Create(
            buttonObject,
            TweenInfo.new(.14),
            {
                BackgroundColor3 = background or C.Surface2
            }
        ):Play()

        TweenService:Create(
            buttonStroke,
            TweenInfo.new(.14),
            {
                Color = C.Border,
                Transparency = .35
            }
        ):Play()
    end)

    return buttonObject
end

--==============================================================
-- REMOVE OLD UI
--==============================================================

local existing = PlayerGui:FindFirstChild("DEVIL_DUMP_V4")

if existing then
    existing:Destroy()
end

--==============================================================
-- ROOT GUI
--==============================================================

local GUI = create("ScreenGui", {
    Name = "DEVIL_DUMP_V4",

    ResetOnSpawn = false,
    IgnoreGuiInset = true,

    DisplayOrder = 999999,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

    Parent = PlayerGui
})

--==============================================================
-- IMPORTANT:
-- CanvasGroup receives touch input and helps isolate our UI.
--==============================================================

local Root = create("CanvasGroup", {
    AnchorPoint = Vector2.new(.5, .5),

    Position = UDim2.fromScale(.5, .5),

    Size = UDim2.fromOffset(820, 500),

    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,

    ClipsDescendants = true,

    Parent = GUI
})

addCorner(Root, 18)

local RootStroke = addStroke(
    Root,
    C.BorderBright,
    .35,
    1
)

--==============================================================
-- SCALE
--==============================================================

local UIScaleObject = create("UIScale", {
    Scale = 1,
    Parent = Root
})

--==============================================================
-- MOBILE / TABLET / PC RESPONSIVE ENGINE
--==============================================================

local BASE_WIDTH = 820
local BASE_HEIGHT = 500

local SAFE_MARGIN_X = 26
local SAFE_MARGIN_Y = 26

local function calculateResponsiveScale()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local availableWidth =
        math.max(
            viewport.X - SAFE_MARGIN_X * 2,
            100
        )

    local availableHeight =
        math.max(
            viewport.Y - SAFE_MARGIN_Y * 2,
            100
        )

    local widthScale =
        availableWidth / BASE_WIDTH

    local heightScale =
        availableHeight / BASE_HEIGHT

    local finalScale =
        math.min(
            widthScale,
            heightScale,
            1
        )

    ----------------------------------------------------------
    -- PHONE ADJUSTMENTS
    ----------------------------------------------------------

    if UserInputService.TouchEnabled then

        -- Small phones
        if viewport.X < 700 then
            finalScale *= .93

        -- Medium phones / landscape
        elseif viewport.X < 1000 then
            finalScale *= .95

        -- Tablets
        else
            finalScale *= .97
        end
    end

    ----------------------------------------------------------
    -- Never touch screen edges
    ----------------------------------------------------------

    finalScale = math.clamp(
        finalScale,
        .32,
        1
    )

    UIScaleObject.Scale = finalScale

    ----------------------------------------------------------
    -- Keep centered after resolution/orientation changes
    ----------------------------------------------------------

    Root.Position =
        UDim2.fromScale(.5, .5)
end

local function bindCamera()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    camera
        :GetPropertyChangedSignal("ViewportSize")
        :Connect(calculateResponsiveScale)
end

calculateResponsiveScale()
bindCamera()

workspace:GetPropertyChangedSignal(
    "CurrentCamera"
):Connect(function()

    task.wait()

    calculateResponsiveScale()
    bindCamera()
end)

--==============================================================
-- TOP ACCENT
--==============================================================

local Accent = create("Frame", {
    Position = UDim2.new(0, 0, 0, 0),

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
            .52,
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

local BrandIcon = create("Frame", {
    Position = UDim2.fromOffset(20, 16),

    Size = UDim2.fromOffset(36, 36),

    BackgroundColor3 = C.Blue,

    BorderSizePixel = 0,

    Parent = Header
})

addCorner(BrandIcon, 10)

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

    Parent = BrandIcon
})

local BrandLetter = makeLabel(
    BrandIcon,
    "D",
    UDim2.new(),
    UDim2.fromScale(1, 1),
    Enum.Font.GothamBold,
    17,
    Color3.new(1, 1, 1)
)

BrandLetter.TextXAlignment =
    Enum.TextXAlignment.Center

makeLabel(
    Header,
    "DEVIL DUMP",
    UDim2.fromOffset(68, 14),
    UDim2.fromOffset(260, 23),
    Enum.Font.GothamBold,
    16,
    C.Text
)

makeLabel(
    Header,
    "CLIENT INSPECTOR / REMOTE LIVE",
    UDim2.fromOffset(68, 36),
    UDim2.fromOffset(300, 17),
    Enum.Font.GothamMedium,
    9,
    C.Muted
)

local Version = create("TextLabel", {
    AnchorPoint = Vector2.new(1, .5),

    Position = UDim2.new(1, -67, .5, 0),

    Size = UDim2.fromOffset(55, 24),

    BackgroundColor3 = C.Surface2,

    BorderSizePixel = 0,

    Text = "V4.1",

    Font = Enum.Font.GothamBold,

    TextSize = 9,

    TextColor3 = C.BlueSoft,

    Parent = Header
})

addCorner(Version, 7)
addStroke(Version, C.Blue, .65)

local Close = makeButton(
    Header,
    "X",
    UDim2.new(1, -44, .5, -14),
    UDim2.fromOffset(28, 28),
    C.Surface2
)

Close.TextSize = 10

--==============================================================
-- DIVIDER
--==============================================================

create("Frame", {
    Position = UDim2.fromOffset(20, 69),

    Size = UDim2.new(1, -40, 0, 1),

    BackgroundColor3 = C.Border,
    BackgroundTransparency = .55,

    BorderSizePixel = 0,

    Parent = Root
})

--==============================================================
-- LEFT SIDEBAR
--==============================================================

local Sidebar = create("Frame", {
    Position = UDim2.fromOffset(18, 86),

    Size = UDim2.fromOffset(174, 393),

    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,

    Parent = Root
})

addCorner(Sidebar, 13)
addStroke(Sidebar, C.Border, .42)

makeLabel(
    Sidebar,
    "CONTROL CENTER",
    UDim2.fromOffset(14, 12),
    UDim2.new(1, -28, 0, 17),
    Enum.Font.GothamBold,
    8,
    C.Muted
)

--==============================================================
-- NAV BUTTON FACTORY
--==============================================================

local function navButton(
    title,
    subtitle,
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

    addCorner(b, 10)

    local bs = addStroke(
        b,
        C.Border,
        .5
    )

    local bar = create("Frame", {
        Position = UDim2.fromOffset(0, 11),

        Size = UDim2.fromOffset(3, 34),

        BackgroundColor3 =
            accentColor or C.Blue,

        BorderSizePixel = 0,

        Parent = b
    })

    addCorner(bar, 3)

    makeLabel(
        b,
        title,
        UDim2.fromOffset(13, 8),
        UDim2.new(1, -24, 0, 19),
        Enum.Font.GothamSemibold,
        10,
        C.Text
    )

    makeLabel(
        b,
        subtitle,
        UDim2.fromOffset(13, 28),
        UDim2.new(1, -24, 0, 16),
        Enum.Font.Gotham,
        8,
        C.Muted
    )

    b.MouseEnter:Connect(function()

        TweenService:Create(
            b,
            TweenInfo.new(.12),
            {
                BackgroundColor3 =
                    C.Surface3
            }
        ):Play()

        TweenService:Create(
            bs,
            TweenInfo.new(.12),
            {
                Transparency = .2
            }
        ):Play()

    end)

    b.MouseLeave:Connect(function()

        TweenService:Create(
            b,
            TweenInfo.new(.12),
            {
                BackgroundColor3 =
                    C.Surface2
            }
        ):Play()

        TweenService:Create(
            bs,
            TweenInfo.new(.12),
            {
                Transparency = .5
            }
        ):Play()

    end)

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
    "Capture incoming activity",
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
-- LIVE STATUS
--==============================================================

local LiveCard = create("Frame", {
    Position = UDim2.new(0, 10, 1, -103),

    Size = UDim2.new(1, -20, 0, 91),

    BackgroundColor3 = C.Background,

    BorderSizePixel = 0,

    Parent = Sidebar
})

addCorner(LiveCard, 10)
addStroke(LiveCard, C.Border, .5)

local LiveDot = create("Frame", {
    Position = UDim2.fromOffset(13, 14),

    Size = UDim2.fromOffset(7, 7),

    BackgroundColor3 = C.Muted2,

    BorderSizePixel = 0,

    Parent = LiveCard
})

addCorner(LiveDot, 100)

local LiveStateText = makeLabel(
    LiveCard,
    "REMOTE LIVE OFF",
    UDim2.fromOffset(29, 7),
    UDim2.new(1, -39, 0, 20),
    Enum.Font.GothamBold,
    9,
    C.Muted
)

local LiveCountText = makeLabel(
    LiveCard,
    "0 events captured",
    UDim2.fromOffset(13, 33),
    UDim2.new(1, -26, 0, 16),
    Enum.Font.Gotham,
    8,
    C.Muted
)

local LiveFileText = makeLabel(
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

    Size = UDim2.new(1, -225, 1, -107),

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

addCorner(StatusCard, 13)
addStroke(StatusCard, C.Border, .42)

local StatusDot = create("Frame", {
    Position = UDim2.fromOffset(15, 15),

    Size = UDim2.fromOffset(8, 8),

    BackgroundColor3 = C.Green,

    BorderSizePixel = 0,

    Parent = StatusCard
})

addCorner(StatusDot, 100)

local Status = makeLabel(
    StatusCard,
    "READY",
    UDim2.fromOffset(32, 8),
    UDim2.new(1, -45, 0, 20),
    Enum.Font.GothamBold,
    10,
    C.Green
)

local Detail = makeLabel(
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
    Position = UDim2.new(0, 15, 1, -10),

    Size = UDim2.new(1, -30, 0, 3),

    BackgroundColor3 = C.Surface3,

    BorderSizePixel = 0,

    Parent = StatusCard
})

addCorner(ProgressBG, 100)

local Progress = create("Frame", {
    Size = UDim2.fromScale(0, 1),

    BackgroundColor3 = C.Blue,

    BorderSizePixel = 0,

    Parent = ProgressBG
})

addCorner(Progress, 100)

create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            C.Blue
        ),

        ColorSequenceKeypoint.new(
            .55,
            C.Purple
        ),

        ColorSequenceKeypoint.new(
            1,
            C.Cyan
        )
    }),

    Parent = Progress
})

--==============================================================
-- STATS CARDS
--==============================================================

local StatsRow = create("Frame", {
    Position = UDim2.fromOffset(0, 78),

    Size = UDim2.new(1, 0, 0, 59),

    BackgroundTransparency = 1,

    Parent = Content
})

local function createStatCard(
    index,
    title,
    accentColor
)
    local gap = 8

    local card = create("Frame", {
        Position = UDim2.new(
            (index - 1) * .25,
            index == 1 and 0 or gap / 2,
            0,
            0
        ),

        Size = UDim2.new(
            .25,
            -gap + 2,
            1,
            0
        ),

        BackgroundColor3 = C.Surface,

        BorderSizePixel = 0,

        Parent = StatsRow
    })

    addCorner(card, 11)
    addStroke(card, C.Border, .5)

    create("Frame", {
        Position = UDim2.fromOffset(10, 10),

        Size = UDim2.fromOffset(3, 17),

        BackgroundColor3 = accentColor,

        BorderSizePixel = 0,

        Parent = card
    })

    makeLabel(
        card,
        title,
        UDim2.fromOffset(19, 7),
        UDim2.new(1, -25, 0, 17),
        Enum.Font.GothamBold,
        7,
        C.Muted
    )

    local value = makeLabel(
        card,
        "0",
        UDim2.fromOffset(11, 27),
        UDim2.new(1, -22, 0, 23),
        Enum.Font.GothamBold,
        16,
        C.Text
    )

    return value
end

local InstanceStat =
    createStatCard(
        1,
        "INSTANCES",
        C.Blue
    )

local ScriptStat =
    createStatCard(
        2,
        "SCRIPTS",
        C.Purple
    )

local RemoteStat =
    createStatCard(
        3,
        "REMOTES",
        C.Cyan
    )

local LiveStat =
    createStatCard(
        4,
        "LIVE",
        C.Green
    )

--==============================================================
-- CONSOLE
--==============================================================

local ConsoleCard = create("Frame", {
    Position = UDim2.fromOffset(0, 148),

    Size = UDim2.new(1, 0, 1, -207),

    BackgroundColor3 = C.Surface,

    BorderSizePixel = 0,

    Parent = Content
})

addCorner(ConsoleCard, 12)
addStroke(ConsoleCard, C.Border, .48)

makeLabel(
    ConsoleCard,
    "ACTIVITY LOG",
    UDim2.fromOffset(13, 7),
    UDim2.new(1, -26, 0, 19),
    Enum.Font.GothamBold,
    8,
    C.Muted
)

create("Frame", {
    Position = UDim2.fromOffset(13, 29),

    Size = UDim2.new(1, -26, 0, 1),

    BackgroundColor3 = C.Border,

    BackgroundTransparency = .6,

    BorderSizePixel = 0,

    Parent = ConsoleCard
})

local Console = create("TextLabel", {
    Position = UDim2.fromOffset(13, 37),

    Size = UDim2.new(1, -26, 1, -47),

    BackgroundTransparency = 1,

    Text = "> DEVIL DUMP initialized",

    Font = Enum.Font.Code,

    TextSize = 9,

    TextColor3 = C.Text2,

    TextXAlignment =
        Enum.TextXAlignment.Left,

    TextYAlignment =
        Enum.TextYAlignment.Top,

    TextWrapped = true,

    Parent = ConsoleCard
})

--==============================================================
-- ACTION BAR
--==============================================================

local ActionBar = create("Frame", {
    AnchorPoint = Vector2.new(0, 1),

    Position = UDim2.new(0, 0, 1, 0),

    Size = UDim2.new(1, 0, 0, 47),

    BackgroundTransparency = 1,

    Parent = Content
})

local DumpButton = makeButton(
    ActionBar,
    "START FULL CLIENT DUMP",
    UDim2.fromOffset(0, 0),
    UDim2.new(.66, -5, 1, 0),
    C.Blue
)

local RemoteButton = makeButton(
    ActionBar,
    "REMOTE LIVE",
    UDim2.new(.66, 5, 0, 0),
    UDim2.new(.34, -5, 1, 0),
    C.Surface2
)

--==============================================================
-- TOAST NOTIFICATIONS
--==============================================================

local ToastHolder = create("Frame", {
    AnchorPoint = Vector2.new(1, 0),

    Position = UDim2.new(
        1,
        -16,
        0,
        16
    ),

    Size = UDim2.fromOffset(
        300,
        450
    ),

    BackgroundTransparency = 1,

    Parent = GUI
})

create("UIListLayout", {
    Padding = UDim.new(0, 8),

    HorizontalAlignment =
        Enum.HorizontalAlignment.Right,

    VerticalAlignment =
        Enum.VerticalAlignment.Top,

    SortOrder =
        Enum.SortOrder.LayoutOrder,

    Parent = ToastHolder
})

local ToastOrder = 0

local function notify(
    titleValue,
    message,
    kind,
    duration
)
    ToastOrder += 1

    local accentColor = C.Blue

    if kind == "success" then
        accentColor = C.Green
    elseif kind == "error" then
        accentColor = C.Red
    elseif kind == "warning" then
        accentColor = C.Yellow
    elseif kind == "live" then
        accentColor = C.Cyan
    end

    local toast = create("Frame", {
        Size = UDim2.fromOffset(
            286,
            72
        ),

        BackgroundColor3 = C.Surface,

        BorderSizePixel = 0,

        LayoutOrder = ToastOrder,

        Parent = ToastHolder
    })

    addCorner(toast, 12)

    local toastStroke =
        addStroke(
            toast,
            C.Border,
            .25
        )

    local accent = create("Frame", {
        Position = UDim2.fromOffset(
            0,
            10
        ),

        Size = UDim2.fromOffset(
            3,
            52
        ),

        BackgroundColor3 =
            accentColor,

        BorderSizePixel = 0,

        Parent = toast
    })

    addCorner(accent, 5)

    local statusMark =
        create("Frame", {
            Position =
                UDim2.fromOffset(
                    14,
                    18
                ),

            Size =
                UDim2.fromOffset(
                    8,
                    8
                ),

            BackgroundColor3 =
                accentColor,

            BorderSizePixel = 0,

            Parent = toast
        })

    addCorner(statusMark, 100)

    makeLabel(
        toast,
        titleValue,
        UDim2.fromOffset(31, 9),
        UDim2.new(1, -43, 0, 22),
        Enum.Font.GothamBold,
        10,
        C.Text
    )

    local toastMessage =
        makeLabel(
            toast,
            message,
            UDim2.fromOffset(31, 30),
            UDim2.new(1, -43, 0, 32),
            Enum.Font.Gotham,
            8,
            C.Muted
        )

    toastMessage.TextWrapped = true

    toastMessage.TextYAlignment =
        Enum.TextYAlignment.Top

    local toastScale =
        create("UIScale", {
            Scale = .92,
            Parent = toast
        })

    toast.BackgroundTransparency = 1

    TweenService:Create(
        toastScale,
        TweenInfo.new(
            .22,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {
            Scale = 1
        }
    ):Play()

    TweenService:Create(
        toast,
        TweenInfo.new(.18),
        {
            BackgroundTransparency = 0
        }
    ):Play()

    task.delay(
        duration or 4,
        function()

            if not toast.Parent then
                return
            end

            TweenService:Create(
                toastScale,
                TweenInfo.new(.16),
                {
                    Scale = .94
                }
            ):Play()

            TweenService:Create(
                toast,
                TweenInfo.new(.16),
                {
                    BackgroundTransparency = 1
                }
            ):Play()

            TweenService:Create(
                toastStroke,
                TweenInfo.new(.16),
                {
                    Transparency = 1
                }
            ):Play()

            task.wait(.18)

            if toast then
                toast:Destroy()
            end
        end
    )
end

--==============================================================
-- CONSOLE FUNCTIONS
--==============================================================

local ConsoleLines = {}

local function log(message)
    local timeText =
        os.date("%H:%M:%S")

    table.insert(
        ConsoleLines,
        "["
            .. timeText
            .. "] "
            .. tostring(message)
    )

    while #ConsoleLines > 13 do
        table.remove(
            ConsoleLines,
            1
        )
    end

    Console.Text =
        "> "
        .. table.concat(
            ConsoleLines,
            "\n> "
        )
end

ClearButton.MouseButton1Click:Connect(
    function()

        table.clear(
            ConsoleLines
        )

        Console.Text =
            "> Console cleared"

        notify(
            "Console cleared",
            "Activity output has been reset.",
            "success",
            2.5
        )
    end
)

--==============================================================
-- STATUS FUNCTIONS
--==============================================================

local function setStatus(
    titleValue,
    detailValue,
    color
)
    color = color or C.Green

    Status.Text = titleValue
    Status.TextColor3 = color

    Detail.Text =
        detailValue or ""

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
        TweenInfo.new(
            .22,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
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
-- FIX: DRAGGING UI SHOULD NOT ROTATE GAME CAMERA
--
-- Main changes:
--   1. Drag only starts from Header.
--   2. Uses gameProcessedEvent-aware input.
--   3. Touch movement is tracked by the SAME touch object.
--   4. UI consumes the touch through an invisible drag capture.
--   5. Buttons no longer start dragging.
--==============================================================

local Dragging = false
local DragInput = nil
local DragStart = nil
local StartPosition = nil

local DragCapture = create("TextButton", {
    Name = "DragCapture",

    Position = UDim2.new(),
    Size = UDim2.fromScale(1, 1),

    BackgroundTransparency = 1,

    Text = "",

    AutoButtonColor = false,

    Active = true,
    Selectable = false,

    ZIndex = 0,

    Parent = Header
})

-- Keep real header controls above capture layer.
BrandIcon.ZIndex = 2
Close.ZIndex = 3
Version.ZIndex = 2

for _, child in ipairs(Header:GetChildren()) do
    if child:IsA("TextLabel") then
        child.ZIndex = 2
    end
end

DragCapture.InputBegan:Connect(
    function(input)

        if input.UserInputType
                ~= Enum.UserInputType.MouseButton1
            and input.UserInputType
                ~= Enum.UserInputType.Touch
        then
            return
        end

        Dragging = true
        DragInput = input

        DragStart =
            input.Position

        StartPosition =
            Root.Position

        input.Changed:Connect(
            function()

                if input.UserInputState
                    == Enum.UserInputState.End
                then
                    Dragging = false
                    DragInput = nil
                end
            end
        )
    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not Dragging then
            return
        end

        ------------------------------------------------------
        -- Touch:
        -- only react to the finger that started dragging.
        ------------------------------------------------------

        if DragInput
            and DragInput.UserInputType
                == Enum.UserInputType.Touch
        then
            if input ~= DragInput then
                return
            end

        ------------------------------------------------------
        -- Mouse:
        ------------------------------------------------------

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
-- SCREEN CLAMP
--
-- Prevent dragging the UI completely off screen.
-- Works after scaling.
--==============================================================

local function clampWindowToScreen()
    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    local scaleValue =
        UIScaleObject.Scale

    local windowWidth =
        BASE_WIDTH
        * scaleValue

    local windowHeight =
        BASE_HEIGHT
        * scaleValue

    local centerX =
        viewport.X
        * Root.Position.X.Scale
        + Root.Position.X.Offset

    local centerY =
        viewport.Y
        * Root.Position.Y.Scale
        + Root.Position.Y.Offset

    local halfW =
        windowWidth / 2

    local halfH =
        windowHeight / 2

    local margin = 8

    centerX =
        math.clamp(
            centerX,
            halfW + margin,
            viewport.X
                - halfW
                - margin
        )

    centerY =
        math.clamp(
            centerY,
            halfH + margin,
            viewport.Y
                - halfH
                - margin
        )

    Root.Position =
        UDim2.fromOffset(
            centerX,
            centerY
        )

    Root.AnchorPoint =
        Vector2.new(.5, .5)
end

UserInputService.InputEnded:Connect(
    function(input)

        if input == DragInput
            or input.UserInputType
                == Enum.UserInputType.MouseButton1
        then

            Dragging = false
            DragInput = nil

            clampWindowToScreen()
        end
    end
)

--==============================================================
-- FLOATING REOPEN BUTTON
-- No emoji. Simple D mark.
--==============================================================

local Floating = create(
    "TextButton",
    {
        AnchorPoint =
            Vector2.new(1, .5),

        Position =
            UDim2.new(
                1,
                -15,
                .5,
                0
            ),

        Size =
            UDim2.fromOffset(
                48,
                48
            ),

        BackgroundColor3 =
            C.Surface,

        BorderSizePixel = 0,

        Text = "D",

        Font =
            Enum.Font.GothamBold,

        TextSize = 17,

        TextColor3 =
            C.Text,

        AutoButtonColor = false,

        Visible = false,

        Parent = GUI
    }
)

addCorner(
    Floating,
    14
)

addStroke(
    Floating,
    C.Blue,
    .2,
    1
)

create(
    "UIGradient",
    {
        Rotation = 45,

        Color =
            ColorSequence.new({
                ColorSequenceKeypoint.new(
                    0,
                    Color3.fromRGB(
                        17,
                        25,
                        48
                    )
                ),

                ColorSequenceKeypoint.new(
                    1,
                    Color3.fromRGB(
                        27,
                        20,
                        53
                    )
                )
            }),

        Parent = Floating
    }
)

local function setMainVisible(value)
    Root.Visible = value
    Floating.Visible = not value
end

Close.MouseButton1Click:Connect(
    function()
        setMainVisible(false)
    end
)

Floating.MouseButton1Click:Connect(
    function()
        setMainVisible(true)

        calculateResponsiveScale()

        task.defer(
            clampWindowToScreen
        )
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

            setMainVisible(
                not Root.Visible
            )

            if Root.Visible then
                calculateResponsiveScale()

                task.defer(
                    clampWindowToScreen
                )
            end
        end
    end
)

--==============================================================
-- ORIENTATION / RESOLUTION WATCH
--
-- iPhone / Android / tablet / emulator:
-- UI recalculates itself whenever viewport changes.
--==============================================================

local LastViewport =
    Vector2.new()

RunService.Heartbeat:Connect(
    function()

        local camera =
            workspace.CurrentCamera

        if not camera then
            return
        end

        local current =
            camera.ViewportSize

        if current ~= LastViewport then

            LastViewport =
                current

            calculateResponsiveScale()

            task.defer(
                clampWindowToScreen
            )
        end
    end
)

--==============================================================
-- MOBILE TOAST SCALE
--==============================================================

local ToastScale =
    create(
        "UIScale",
        {
            Scale = 1,
            Parent = ToastHolder
        }
    )

local function updateToastScale()

    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    if viewport.X < 650 then

        ToastScale.Scale = .72

    elseif viewport.X < 900 then

        ToastScale.Scale = .82

    else

        ToastScale.Scale = 1
    end
end

updateToastScale()

--==============================================================
-- LIVE INDICATOR ANIMATION
--==============================================================

task.spawn(
    function()

        while GUI.Parent do

            if Live
                and Live.Enabled
            then

                TweenService:Create(
                    LiveDot,
                    TweenInfo.new(.45),
                    {
                        BackgroundTransparency =
                            .55
                    }
                ):Play()

                task.wait(.45)

                if not GUI.Parent then
                    break
                end

                TweenService:Create(
                    LiveDot,
                    TweenInfo.new(.45),
                    {
                        BackgroundTransparency =
                            0
                    }
                ):Play()

                task.wait(.45)

            else

                LiveDot.BackgroundTransparency =
                    0

                task.wait(.4)
            end
        end
    end
)

--==============================================================
-- INITIAL SCREEN FIT
--==============================================================

task.defer(
    function()

        calculateResponsiveScale()

        task.wait()

        clampWindowToScreen()

        updateToastScale()
    end
)
