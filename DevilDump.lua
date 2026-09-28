--[[
    DEVIL DUMP V3
    Full Client Inspector / Lua Research Dumper

    Dumps client-visible:
      • RemoteEvent / RemoteFunction
      • BindableEvent / BindableFunction
      • LocalScript / ModuleScript metadata
      • Source when exposed by the current environment
      • Attributes
      • CollectionService Tags
      • ValueBase values
      • GUI text / hierarchy
      • Parts / CFrame / Position / Size
      • Humanoids
      • Tools
      • Animations
      • Sounds
      • ProximityPrompts / ClickDetectors
      • Eggs / Pets / Rocks / Mining / Shops / Plots
      • ReplicatedStorage / ReplicatedFirst
      • PlayerScripts / PlayerGui / Backpack / Character
      • Workspace last

    Output:
      Delta/Workspace/DevilDump/DevilDump_<PlaceId>_<timestamp>.txt
]]

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

if not Player then
    return
end

local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local CONFIG = {

    Folder = "DevilDump",

    -- Workspace gets its own larger limit.
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

    ToggleKey = Enum.KeyCode.RightShift
}

--==================================================
-- REMOVE OLD GUI
--==================================================

local old = PlayerGui:FindFirstChild("DEVIL_DUMP_V3")

if old then
    old:Destroy()
end

--==================================================
-- COLORS
--==================================================

local C = {

    Background = Color3.fromRGB(7, 9, 15),

    Surface = Color3.fromRGB(12, 15, 24),

    Surface2 = Color3.fromRGB(17, 20, 31),

    Border = Color3.fromRGB(49, 58, 83),

    Purple = Color3.fromRGB(120, 88, 255),

    Blue = Color3.fromRGB(52, 139, 255),

    Cyan = Color3.fromRGB(62, 213, 255),

    Green = Color3.fromRGB(70, 225, 147),

    Red = Color3.fromRGB(255, 91, 112),

    Text = Color3.fromRGB(239, 242, 255),

    Muted = Color3.fromRGB(145, 154, 181)
}

--==================================================
-- GUI
--==================================================

local GUI = Instance.new("ScreenGui")

GUI.Name = "DEVIL_DUMP_V3"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999999
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.AnchorPoint = Vector2.new(.5, .5)
Main.Position = UDim2.fromScale(.5, .5)
Main.Size = UDim2.fromOffset(720, 470)
Main.BackgroundColor3 = C.Background
Main.BorderSizePixel = 0
Main.Parent = GUI

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = C.Purple
mainStroke.Transparency = .48
mainStroke.Thickness = 1.3
mainStroke.Parent = Main

local scale = Instance.new("UIScale")
scale.Parent = Main

--==================================================
-- RESPONSIVE MOBILE SCALE
--==================================================

local function updateScale()

    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local sx = (viewport.X - 28) / 720
    local sy = (viewport.Y - 28) / 470

    local result = math.min(sx, sy, 1)

    if UserInputService.TouchEnabled and viewport.X > viewport.Y then
        result *= .93
    end

    scale.Scale = math.clamp(result, .27, 1)
end

updateScale()

if workspace.CurrentCamera then

    workspace.CurrentCamera
        :GetPropertyChangedSignal("ViewportSize")
        :Connect(updateScale)

end

--==================================================
-- HELPERS
--==================================================

local function corner(parent, radius)

    local x = Instance.new("UICorner")

    x.CornerRadius = UDim.new(0, radius or 10)
    x.Parent = parent

    return x
end

local function text(
    parent,
    value,
    position,
    size,
    font,
    textSize,
    color
)

    local x = Instance.new("TextLabel")

    x.BackgroundTransparency = 1

    x.Position = position
    x.Size = size

    x.Text = value

    x.Font = font or Enum.Font.Gotham

    x.TextSize = textSize or 14

    x.TextColor3 = color or C.Text

    x.TextXAlignment = Enum.TextXAlignment.Left

    x.Parent = parent

    return x
end

--==================================================
-- HEADER
--==================================================

local Logo = Instance.new("Frame")

Logo.Position = UDim2.fromOffset(22, 18)
Logo.Size = UDim2.fromOffset(38, 38)

Logo.BackgroundColor3 = C.Purple
Logo.BorderSizePixel = 0

Logo.Parent = Main

corner(Logo, 12)

local logoText = text(
    Logo,
    "D",
    UDim2.fromScale(0, 0),
    UDim2.fromScale(1, 1),
    Enum.Font.GothamBlack,
    20,
    Color3.new(1, 1, 1)
)

logoText.TextXAlignment = Enum.TextXAlignment.Center
logoText.TextYAlignment = Enum.TextYAlignment.Center

text(
    Main,
    "DEVIL DUMP",
    UDim2.fromOffset(72, 17),
    UDim2.fromOffset(260, 24),
    Enum.Font.GothamBold,
    19
)

text(
    Main,
    "CLIENT INSPECTOR  •  V3",
    UDim2.fromOffset(72, 40),
    UDim2.fromOffset(280, 20),
    Enum.Font.GothamMedium,
    10,
    C.Muted
)

local Close = Instance.new("TextButton")

Close.Position = UDim2.new(1, -55, 0, 19)

Close.Size = UDim2.fromOffset(34, 34)

Close.Text = "×"

Close.TextSize = 22

Close.Font = Enum.Font.GothamBold

Close.TextColor3 = C.Text

Close.BackgroundColor3 = C.Surface2

Close.BorderSizePixel = 0

Close.Parent = Main

corner(Close, 10)

--==================================================
-- STATUS CARD
--==================================================

local StatusCard = Instance.new("Frame")

StatusCard.Position = UDim2.fromOffset(22, 72)

StatusCard.Size = UDim2.new(1, -44, 0, 62)

StatusCard.BackgroundColor3 = C.Surface

StatusCard.BorderSizePixel = 0

StatusCard.Parent = Main

corner(StatusCard, 13)

local Status = text(
    StatusCard,
    "READY",
    UDim2.fromOffset(15, 10),
    UDim2.new(1, -30, 0, 20),
    Enum.Font.GothamBold,
    12,
    C.Green
)

local Detail = text(
    StatusCard,
    "Waiting for client scan",
    UDim2.fromOffset(15, 31),
    UDim2.new(1, -30, 0, 17),
    Enum.Font.Gotham,
    11,
    C.Muted
)

local ProgressBG = Instance.new("Frame")

ProgressBG.Position = UDim2.new(0, 15, 1, -9)

ProgressBG.Size = UDim2.new(1, -30, 0, 4)

ProgressBG.BackgroundColor3 = C.Surface2

ProgressBG.BorderSizePixel = 0

ProgressBG.Parent = StatusCard

corner(ProgressBG, 5)

local Progress = Instance.new("Frame")

Progress.Size = UDim2.fromScale(0, 1)

Progress.BackgroundColor3 = C.Blue

Progress.BorderSizePixel = 0

Progress.Parent = ProgressBG

corner(Progress, 5)

--==================================================
-- STATS
--==================================================

local StatsText = text(
    Main,
    "INSTANCES  0    •    SCRIPTS  0    •    REMOTES  0    •    VALUES  0",
    UDim2.fromOffset(24, 145),
    UDim2.new(1, -48, 0, 20),
    Enum.Font.GothamMedium,
    11,
    C.Muted
)

--==================================================
-- CONSOLE
--==================================================

local Console = Instance.new("TextLabel")

Console.Position = UDim2.fromOffset(22, 174)

Console.Size = UDim2.new(1, -44, 0, 210)

Console.BackgroundColor3 = C.Surface

Console.BorderSizePixel = 0

Console.Text = "> DEVIL DUMP initialized"

Console.Font = Enum.Font.Code

Console.TextSize = 11

Console.TextColor3 = Color3.fromRGB(183, 193, 221)

Console.TextXAlignment = Enum.TextXAlignment.Left

Console.TextYAlignment = Enum.TextYAlignment.Top

Console.TextWrapped = true

Console.Parent = Main

corner(Console, 13)

local consolePadding = Instance.new("UIPadding")

consolePadding.PaddingLeft = UDim.new(0, 13)
consolePadding.PaddingRight = UDim.new(0, 13)

consolePadding.PaddingTop = UDim.new(0, 11)
consolePadding.PaddingBottom = UDim.new(0, 11)

consolePadding.Parent = Console

--==================================================
-- DUMP BUTTON
--==================================================

local DumpButton = Instance.new("TextButton")

DumpButton.Position = UDim2.fromOffset(22, 400)

DumpButton.Size = UDim2.new(1, -44, 0, 47)

DumpButton.BackgroundColor3 = C.Purple

DumpButton.BorderSizePixel = 0

DumpButton.Text = "START FULL CLIENT DUMP"

DumpButton.TextColor3 = Color3.new(1, 1, 1)

DumpButton.TextSize = 13

DumpButton.Font = Enum.Font.GothamBold

DumpButton.Parent = Main

corner(DumpButton, 13)

--==================================================
-- UI LOGGING
--==================================================

local ConsoleLines = {}

local function log(message)

    table.insert(
        ConsoleLines,
        tostring(message)
    )

    while #ConsoleLines > 11 do
        table.remove(ConsoleLines, 1)
    end

    Console.Text =
        "> " ..
        table.concat(ConsoleLines, "\n> ")
end

local function setStatus(title, detail, color)

    Status.Text = title

    Status.TextColor3 =
        color or C.Green

    Detail.Text =
        detail or ""

end

local function setProgress(value)

    value = math.clamp(value, 0, 1)

    TweenService:Create(
        Progress,
        TweenInfo.new(.18),
        {
            Size =
                UDim2.fromScale(
                    value,
                    1
                )
        }
    ):Play()

end

--==================================================
-- DUMP DATA
--==================================================

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

    Output[#Output + 1] =
        tostring(value)

end

local function separator(title)

    emit("")
    emit(
        string.rep("=", 78)
    )

    emit(
        " " .. title
    )

    emit(
        string.rep("=", 78)
    )

end

--==================================================
-- SERIALIZATION
--==================================================

local function serialize(value)

    local kind = typeof(value)

    if kind == "string" then

        return string.format(
            "%q",
            value
        )

    elseif
        kind == "number"
        or kind == "boolean"
        or kind == "nil"
    then

        return tostring(value)

    elseif kind == "Instance" then

        local ok, full =
            pcall(
                function()
                    return value:GetFullName()
                end
            )

        return ok
            and full
            or value.Name

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

    elseif kind == "table" then

        local success, encoded =
            pcall(
                function()
                    return HttpService:JSONEncode(
                        value
                    )
                end
            )

        if success then
            return encoded
        end
    end

    local success, result =
        pcall(tostring, value)

    return success
        and result
        or "<unserializable>"
end

--==================================================
-- SAFE PROPERTY READER
--==================================================

local function property(object, name)

    local success, result =
        pcall(
            function()
                return object[name]
            end
        )

    if success then

        emit(
            "    "
                .. name
                .. " = "
                .. serialize(result)
        )

    end

end

--==================================================
-- ATTRIBUTES
--==================================================

local function dumpAttributes(object)

    if not CONFIG.DumpAttributes then
        return
    end

    local success, attributes =
        pcall(
            function()
                return object:GetAttributes()
            end
        )

    if not success then
        return
    end

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

--==================================================
-- TAGS
--==================================================

local function dumpTags(object)

    if not CONFIG.DumpTags then
        return
    end

    local success, tags =
        pcall(
            function()
                return CollectionService:GetTags(
                    object
                )
            end
        )

    if success and #tags > 0 then

        emit(
            "    Tags = "
                .. table.concat(
                    tags,
                    ", "
                )
        )

    end
end

--==================================================
-- PROPERTY DUMPER
--==================================================

local function dumpProperties(object)

    if not CONFIG.DumpProperties then
        return
    end

    property(
        object,
        "Archivable"
    )

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

        property(
            object,
            "AssemblyLinearVelocity"
        )

    elseif object:IsA("Humanoid") then

        property(object, "Health")

        property(object, "MaxHealth")

        property(object, "WalkSpeed")

        property(object, "JumpPower")

        property(object, "HipHeight")

        property(object, "RigType")

    elseif object:IsA("Tool") then

        Stats.Tools += 1

        property(
            object,
            "RequiresHandle"
        )

        property(
            object,
            "CanBeDropped"
        )

        property(
            object,
            "ToolTip"
        )

    elseif object:IsA("Sound") then

        property(object, "SoundId")

        property(object, "Volume")

        property(object, "PlaybackSpeed")

        property(object, "Looped")

    elseif object:IsA("Animation") then

        property(
            object,
            "AnimationId"
        )

    elseif object:IsA("ProximityPrompt") then

        Stats.Prompts += 1

        property(
            object,
            "ActionText"
        )

        property(
            object,
            "ObjectText"
        )

        property(
            object,
            "HoldDuration"
        )

        property(
            object,
            "MaxActivationDistance"
        )

        property(
            object,
            "Enabled"
        )

    elseif object:IsA("ClickDetector") then

        Stats.Prompts += 1

        property(
            object,
            "MaxActivationDistance"
        )

    elseif object:IsA("ValueBase") then

        Stats.Values += 1

        property(
            object,
            "Value"
        )

    elseif
        object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    then

        Stats.GUI += 1

        property(object, "Text")

        property(object, "Visible")

        property(object, "Position")

        property(object, "Size")

    elseif
        object:IsA("ImageLabel")
        or object:IsA("ImageButton")
    then

        Stats.GUI += 1

        property(object, "Image")

        property(object, "Visible")

        property(object, "Position")

        property(object, "Size")

    end
end

--==================================================
-- SCRIPT / REMOTE CLASSIFICATION
--==================================================

local function inspectSpecial(object)

    if object:IsA("LocalScript") then

        Stats.Scripts += 1
        Stats.LocalScripts += 1

        emit(
            "    SCRIPT_TYPE = LocalScript"
        )

        if CONFIG.DumpSource then

            local success, source =
                pcall(
                    function()
                        return object.Source
                    end
                )

            if success
                and type(source) == "string"
                and #source > 0
            then

                emit("")

                emit(
                    "    ----- SOURCE BEGIN -----"
                )

                emit(source)

                emit(
                    "    ----- SOURCE END -----"
                )

            else

                emit(
                    "    Source = <not exposed to this client context>"
                )

            end
        end

    elseif object:IsA("ModuleScript") then

        Stats.Scripts += 1
        Stats.ModuleScripts += 1

        emit(
            "    SCRIPT_TYPE = ModuleScript"
        )

        if CONFIG.DumpSource then

            local success, source =
                pcall(
                    function()
                        return object.Source
                    end
                )

            if success
                and type(source) == "string"
                and #source > 0
            then

                emit("")

                emit(
                    "    ----- SOURCE BEGIN -----"
                )

                emit(source)

                emit(
                    "    ----- SOURCE END -----"
                )

            else

                emit(
                    "    Source = <not exposed to this client context>"
                )

            end
        end

    elseif object:IsA("RemoteEvent") then

        Stats.RemoteEvents += 1

        emit(
            "    REMOTE = RemoteEvent"
        )

    elseif object:IsA("RemoteFunction") then

        Stats.RemoteFunctions += 1

        emit(
            "    REMOTE = RemoteFunction"
        )

    elseif object:IsA("BindableEvent") then

        Stats.BindableEvents += 1

        emit(
            "    BINDABLE = BindableEvent"
        )

    elseif object:IsA("BindableFunction") then

        Stats.BindableFunctions += 1

        emit(
            "    BINDABLE = BindableFunction"
        )

    end
end

--==================================================
-- SYSTEM CLASSIFIER
--==================================================

local function classify(object)

    local lower =
        string.lower(
            object.Name
        )

    local path = ""

    pcall(
        function()
            path =
                object:GetFullName()
        end
    )

    local function add(category)

        local list =
            Interesting[category]

        if list then
            list[#list + 1] =
                path
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

    if
        string.find(lower, "mine", 1, true)
        or string.find(lower, "mining", 1, true)
    then

        add("Mining")
    end

    if
        string.find(lower, "shop", 1, true)
        or string.find(lower, "vendor", 1, true)
        or string.find(lower, "sell", 1, true)
    then

        add("Shops")
    end

    if string.find(lower, "plot", 1, true) then
        add("Plots")
    end

    if
        string.find(lower, "inventory", 1, true)
        or string.find(lower, "backpack", 1, true)
    then

        add("Inventory")
    end

    if
        string.find(lower, "quest", 1, true)
        or string.find(lower, "mission", 1, true)
    then

        add("Quests")
    end
end

--==================================================
-- STATS UI
--==================================================

local function updateStats()

    local remotes =
        Stats.RemoteEvents
        + Stats.RemoteFunctions
        + Stats.BindableEvents
        + Stats.BindableFunctions

    StatsText.Text =
        string.format(
            "INSTANCES  %s    •    SCRIPTS  %s    •    REMOTES  %s    •    VALUES  %s",
            Stats.Instances,
            Stats.Scripts,
            remotes,
            Stats.Values
        )

end

--==================================================
-- INSTANCE DUMPER
--==================================================

local function dumpInstance(
    object,
    depth,
    state
)

    if depth > CONFIG.MaxDepth then
        return
    end

    if state.Count >= state.Limit then
        state.HitLimit = true
        return
    end

    state.Count += 1

    Stats.Instances += 1

    local path =
        object.Name

    pcall(
        function()
            path =
                object:GetFullName()
        end
    )

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

    if
        Stats.Instances
        % CONFIG.YieldEvery
        == 0
    then

        updateStats()

        Detail.Text =
            "Scanning "
            .. path

        task.wait()
    end

    local success, children =
        pcall(
            function()
                return object:GetChildren()
            end
        )

    if not success then
        return
    end

    for _, child in ipairs(children) do

        if state.Count >= state.Limit then

            state.HitLimit = true
            break

        end

        dumpInstance(
            child,
            depth + 1,
            state
        )

    end
end

--==================================================
-- ROOT SCAN
--==================================================

local function scanRoot(
    title,
    object,
    limit
)

    separator(title)

    if not object then

        emit(
            "<ROOT NOT AVAILABLE>"
        )

        return
    end

    local state = {

        Count = 0,

        Limit = limit
            or CONFIG.GeneralLimit,

        HitLimit = false
    }

    dumpInstance(
        object,
        0,
        state
    )

    emit("")

    emit(
        "ROOT_INSTANCE_COUNT = "
            .. state.Count
    )

    emit(
        "ROOT_LIMIT_REACHED = "
            .. tostring(
                state.HitLimit
            )
    )

end

--==================================================
-- SPECIAL REMOTE INDEX
--==================================================

local function buildRemoteIndex()

    separator(
        "REMOTE / BINDABLE INDEX"
    )

    local roots = {

        ReplicatedStorage,

        ReplicatedFirst,

        Player:FindFirstChild(
            "PlayerScripts"
        ),

        PlayerGui
    }

    local found = 0

    for _, root in ipairs(roots) do

        if root then

            for _, object in ipairs(
                root:GetDescendants()
            ) do

                if
                    object:IsA("RemoteEvent")
                    or object:IsA("RemoteFunction")
                    or object:IsA("BindableEvent")
                    or object:IsA("BindableFunction")
                then

                    found += 1

                    emit(
                        object.ClassName
                            .. " | "
                            .. object:GetFullName()
                    )

                    dumpAttributes(
                        object
                    )

                    dumpTags(
                        object
                    )
                end

                if found % 200 == 0 then
                    task.wait()
                end
            end
        end
    end

    emit("")

    emit(
        "REMOTE_INDEX_TOTAL = "
            .. found
    )
end

--==================================================
-- SCRIPT INDEX
--==================================================

local function buildScriptIndex()

    separator(
        "LOCAL SCRIPT / MODULE INDEX"
    )

    local roots = {

        ReplicatedStorage,

        ReplicatedFirst,

        Player:FindFirstChild(
            "PlayerScripts"
        ),

        PlayerGui,

        Player:FindFirstChild(
            "Backpack"
        ),

        Player.Character
    }

    local found = 0

    for _, root in ipairs(roots) do

        if root then

            for _, object in ipairs(
                root:GetDescendants()
            ) do

                if
                    object:IsA(
                        "LocalScript"
                    )
                    or object:IsA(
                        "ModuleScript"
                    )
                then

                    found += 1

                    emit(
                        object.ClassName
                            .. " | "
                            .. object:GetFullName()
                    )

                    dumpAttributes(
                        object
                    )

                    dumpTags(
                        object
                    )

                end

                if found % 200 == 0 then
                    task.wait()
                end
            end
        end
    end

    emit("")

    emit(
        "SCRIPT_INDEX_TOTAL = "
            .. found
    )

end

--==================================================
-- INTERESTING SYSTEM INDEX
--==================================================

local function writeSystemIndex()

    separator(
        "DISCOVERED GAME SYSTEM INDEX"
    )

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

        emit(
            "[" .. category .. "]"
        )

        local list =
            Interesting[category]

        local seen = {}

        local count = 0

        for _, path in ipairs(list) do

            if not seen[path] then

                seen[path] = true

                count += 1

                emit(
                    "  " .. path
                )

                if count >= 500 then

                    emit(
                        "  <truncated at 500 entries>"
                    )

                    break
                end
            end
        end

        emit(
            "  Count = "
                .. count
        )

    end
end

--==================================================
-- HEADER
--==================================================

local function writeHeader()

    separator(
        "SCRIPT DEVIL DUMP V3"
    )

    emit(
        "PlaceId = "
            .. tostring(
                game.PlaceId
            )
    )

    emit(
        "GameId = "
            .. tostring(
                game.GameId
            )
    )

    emit(
        "JobId = "
            .. tostring(
                game.JobId
            )
    )

    emit(
        "PlaceVersion = "
            .. tostring(
                game.PlaceVersion
            )
    )

    emit(
        "Player = "
            .. Player.Name
    )

    emit(
        "Generated = "
            .. os.date(
                "%Y-%m-%d %H:%M:%S"
            )
    )

    emit("")

    emit(
        "Scope = CLIENT-VISIBLE / REPLICATED DATA"
    )

    emit(
        "Server-only scripts, server memory and server-only event handlers are not directly visible."
    )
end

--==================================================
-- SUMMARY
--==================================================

local function writeSummary()

    separator(
        "SUMMARY"
    )

    for key, value in pairs(Stats) do

        emit(
            key
                .. " = "
                .. tostring(value)
        )

    end

end

--==================================================
-- FILE SAVE
--==================================================

local function ensureFolder()

    if type(makefolder) ~= "function" then
        return false
    end

    local success =
        pcall(
            function()

                if
                    type(isfolder)
                        ~= "function"
                    or not isfolder(
                        CONFIG.Folder
                    )
                then

                    makefolder(
                        CONFIG.Folder
                    )

                end
            end
        )

    return success
end

local function saveFile()

    if type(writefile) ~= "function" then

        return false,
            nil,
            "writefile is unavailable"

    end

    local filename =
        string.format(
            "DevilDump_%s_%s.txt",
            tostring(game.PlaceId),
            tostring(os.time())
        )

    local folderReady =
        ensureFolder()

    local path =
        folderReady
            and (
                CONFIG.Folder
                .. "/"
                .. filename
            )
            or filename

    local data =
        table.concat(
            Output,
            "\n"
        )

    local success, errorMessage =
        pcall(
            function()

                writefile(
                    path,
                    data
                )

            end
        )

    if not success
        and folderReady
    then

        path = filename

        success, errorMessage =
            pcall(
                function()

                    writefile(
                        path,
                        data
                    )

                end
            )

    end

    if not success then

        return false,
            nil,
            tostring(errorMessage)

    end

    if type(isfile) == "function" then

        local verifySuccess,
            exists =
            pcall(
                isfile,
                path
            )

        if verifySuccess
            and not exists
        then

            return false,
                path,
                "File verification failed"
        end
    end

    return true,
        path,
        #data
end

--==================================================
-- RESET
--==================================================

local function reset()

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

--==================================================
-- FULL DUMP
--==================================================

local Busy = false

local function executeDump()

    if Busy then
        return
    end

    Busy = true

    reset()

    DumpButton.Text =
        "DUMPING..."

    setStatus(
        "SCANNING",
        "Preparing client inspector",
        C.Cyan
    )

    setProgress(.02)

    log(
        "Starting Devil Dump V3"
    )

    writeHeader()

    -- ============================================
    -- CRITICAL INDEXES FIRST
    -- ============================================

    setStatus(
        "REMOTE SCAN",
        "Indexing RemoteEvents / Functions first",
        C.Cyan
    )

    log(
        "Remote index..."
    )

    buildRemoteIndex()

    setProgress(.10)

    setStatus(
        "SCRIPT SCAN",
        "Indexing LocalScripts / Modules",
        C.Cyan
    )

    log(
        "Script index..."
    )

    buildScriptIndex()

    setProgress(.18)

    -- ============================================
    -- REPLICATED STORAGE
    -- ============================================

    setStatus(
        "REPLICATED STORAGE",
        "Scanning replicated game systems",
        C.Cyan
    )

    log(
        "ReplicatedStorage..."
    )

    scanRoot(
        "REPLICATED STORAGE",
        ReplicatedStorage,
        CONFIG.GeneralLimit
    )

    setProgress(.31)

    -- ============================================
    -- REPLICATED FIRST
    -- ============================================

    setStatus(
        "REPLICATED FIRST",
        "Scanning startup client data",
        C.Cyan
    )

    log(
        "ReplicatedFirst..."
    )

    scanRoot(
        "REPLICATED FIRST",
        ReplicatedFirst,
        CONFIG.GeneralLimit
    )

    setProgress(.38)

    -- ============================================
    -- PLAYER SCRIPTS
    -- ============================================

    local PlayerScripts =
        Player:FindFirstChild(
            "PlayerScripts"
        )

    setStatus(
        "PLAYER SCRIPTS",
        "Scanning local runtime hierarchy",
        C.Cyan
    )

    log(
        "PlayerScripts..."
    )

    scanRoot(
        "PLAYER SCRIPTS",
        PlayerScripts,
        CONFIG.GeneralLimit
    )

    setProgress(.47)

    -- ============================================
    -- PLAYER GUI
    -- ============================================

    if CONFIG.DumpGUI then

        setStatus(
            "PLAYER GUI",
            "Scanning UI / text / buttons",
            C.Cyan
        )

        log(
            "PlayerGui..."
        )

        scanRoot(
            "PLAYER GUI",
            PlayerGui,
            CONFIG.GeneralLimit
        )

    end

    setProgress(.57)

    -- ============================================
    -- BACKPACK
    -- ============================================

    local Backpack =
        Player:FindFirstChild(
            "Backpack"
        )

    setStatus(
        "BACKPACK",
        "Scanning tools / inventory",
        C.Cyan
    )

    log(
        "Backpack..."
    )

    scanRoot(
        "BACKPACK",
        Backpack,
        CONFIG.GeneralLimit
    )

    setProgress(.64)

    -- ============================================
    -- CHARACTER
    -- ============================================

    setStatus(
        "CHARACTER",
        "Scanning current character",
        C.Cyan
    )

    log(
        "Character..."
    )

    scanRoot(
        "CHARACTER",
        Player.Character,
        CONFIG.GeneralLimit
    )

    setProgress(.70)

    -- ============================================
    -- LIGHTING
    -- ============================================

    scanRoot(
        "LIGHTING",
        Lighting,
        30000
    )

    setProgress(.74)

    -- ============================================
    -- SOUND
    -- ============================================

    scanRoot(
        "SOUND SERVICE",
        SoundService,
        30000
    )

    setProgress(.78)

    -- ============================================
    -- WORKSPACE LAST
    -- ============================================

    if CONFIG.DumpWorkspace then

        setStatus(
            "WORKSPACE",
            "Scanning map last — high instance limit",
            C.Cyan
        )

        log(
            "Workspace last..."
        )

        scanRoot(
            "WORKSPACE / MAP",
            workspace,
            CONFIG.WorkspaceLimit
        )

    end

    setProgress(.91)

    -- ============================================
    -- INDEX
    -- ============================================

    setStatus(
        "BUILDING INDEX",
        "Grouping discovered game systems",
        C.Cyan
    )

    log(
        "Building system index..."
    )

    writeSystemIndex()

    writeSummary()

    setProgress(.96)

    -- ============================================
    -- SAVE
    -- ============================================

    setStatus(
        "SAVING",
        "Writing dump file",
        C.Cyan
    )

    log(
        "Writing file..."
    )

    local success,
        path,
        result =
        saveFile()

    if success then

        setProgress(1)

        setStatus(
            "DUMP COMPLETE",
            path,
            C.Green
        )

        DumpButton.Text =
            "DUMP SAVED"

        log(
            "Saved: " .. path
        )

        log(
            "Bytes: "
                .. tostring(result)
        )

    else

        setStatus(
            "SAVE FAILED",
            tostring(result),
            C.Red
        )

        DumpButton.Text =
            "DUMP FAILED"

        log(
            "ERROR: "
                .. tostring(result)
        )

    end

    updateStats()

    Busy = false
end

--==================================================
-- BUTTON
--==================================================

DumpButton.MouseButton1Click:Connect(
    function()

        task.spawn(
            function()

                local success,
                    errorMessage =
                    pcall(
                        executeDump
                    )

                if not success then

                    Busy = false

                    DumpButton.Text =
                        "DUMP FAILED"

                    setStatus(
                        "ERROR",
                        tostring(errorMessage),
                        C.Red
                    )

                    log(
                        tostring(errorMessage)
                    )

                end
            end
        )

    end
)

--==================================================
-- DRAG
--==================================================

local Dragging = false

local DragStart

local StartPosition

Main.InputBegan:Connect(
    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseButton1
            or input.UserInputType
                == Enum.UserInputType.Touch
        then

            Dragging = true

            DragStart =
                input.Position

            StartPosition =
                Main.Position

        end
    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if
            Dragging
            and (
                input.UserInputType
                    == Enum.UserInputType.MouseMovement
                or input.UserInputType
                    == Enum.UserInputType.Touch
            )
        then

            local delta =
                input.Position
                - DragStart

            Main.Position =
                UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset
                        + delta.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset
                        + delta.Y
                )

        end
    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseButton1
            or input.UserInputType
                == Enum.UserInputType.Touch
        then

            Dragging = false

        end
    end
)

--==================================================
-- CLOSE / REOPEN
--==================================================

local Floating = Instance.new(
    "TextButton"
)

Floating.AnchorPoint =
    Vector2.new(1, .5)

Floating.Position =
    UDim2.new(
        1,
        -16,
        .5,
        0
    )

Floating.Size =
    UDim2.fromOffset(
        48,
        48
    )

Floating.BackgroundColor3 =
    C.Purple

Floating.BorderSizePixel = 0

Floating.Text = "D"

Floating.Font =
    Enum.Font.GothamBlack

Floating.TextSize = 20

Floating.TextColor3 =
    Color3.new(1, 1, 1)

Floating.Visible = false

Floating.Parent = GUI

corner(
    Floating,
    15
)

Close.MouseButton1Click:Connect(
    function()

        Main.Visible = false

        Floating.Visible = true

    end
)

Floating.MouseButton1Click:Connect(
    function()

        Main.Visible = true

        Floating.Visible = false

    end
)

UserInputService.InputBegan:Connect(
    function(input, processed)

        if processed then
            return
        end

        if
            input.KeyCode
            == CONFIG.ToggleKey
        then

            Main.Visible =
                not Main.Visible

            Floating.Visible =
                not Main.Visible

        end
    end
)

--==================================================
-- READY
--==================================================

if type(writefile) == "function" then

    setStatus(
        "READY",
        "writefile available • press START FULL CLIENT DUMP",
        C.Green
    )

    log(
        "writefile ready"
    )

else

    setStatus(
        "LIMITED",
        "writefile unavailable in this environment",
        C.Red
    )

    log(
        "writefile unavailable"
    )

end

log(
    "Critical scans run before Workspace"
)

log(
    "Ready."
)
