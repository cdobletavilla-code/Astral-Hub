--[[
     ✦  A S T R A L   H U B  ✦   —   Dandy's World
     ─────────────────────────────────────────────────
     UI astral propia · Autofarm inteligente · ESP completo · Radar
     Auto skill check · Evento Halloween 2026 · Máquinas Dúo · Escáner

     Abrir / cerrar la interfaz:  RightShift  (configurable en Ajustes)

     Para auto-reejecutar al pasar del lobby a la partida (el juego te
     teletransporta), pega aquí el enlace RAW donde subas este archivo:
]]
local SCRIPT_URL = ""

-- ════════════════════════════════════════════════════════════════
--  Arranque
-- ════════════════════════════════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local G = (getgenv and getgenv()) or _G
if G.AstralDW and type(G.AstralDW.Unload) == "function" then
    pcall(G.AstralDW.Unload)
    task.wait(0.25)
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local TeleportService   = game:GetService("TeleportService")
local StatsService      = game:GetService("Stats")
local SoundService      = game:GetService("SoundService")
local VirtualUser       = game:GetService("VirtualUser")
local VIM               = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
while not LP do task.wait() LP = Players.LocalPlayer end
local PlayerGui = LP:WaitForChild("PlayerGui")

local Hub = {
    Running     = true,
    Version     = "1.1.0",
    Connections = {},
    Flags       = {},
    Setters     = {},
    Sets        = {},
    Drawings    = {},
    StartTime   = os.clock(),
}
G.AstralDW = Hub
local Flags = Hub.Flags

-- Funciones del executor (todas opcionales; se comprueban antes de usarse)
local Env = {
    fireprompt   = fireproximityprompt,
    fireclick    = fireclickdetector,
    firetouch    = firetouchinterest,
    hookmeta     = hookmetamethod,
    getncm       = getnamecallmethod,
    checkcaller  = checkcaller,
    newcc        = newcclosure or function(f) return f end,
    setclip      = setclipboard or toclipboard or (syn and syn.write_clipboard),
    gethui       = gethui,
    writefile    = writefile,
    readfile     = readfile,
    isfile       = isfile,
    makefolder   = makefolder,
    isfolder     = isfolder,
    getconns     = getconnections,
    getgc        = getgc,
    Drawing      = Drawing,
    queue        = queue_on_teleport or (syn and syn.queue_on_teleport),
    getasset     = getcustomasset or getsynasset,
    b64decode    = (crypt and (crypt.base64decode or crypt.base64_decode or (crypt.base64 and crypt.base64.decode)))
                   or base64_decode or (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode),
}

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Hub.Connections, c)
    return c
end

local lastWarn = {}
local function safeWarn(tag, err)
    local key = tag .. tostring(err)
    if not lastWarn[key] or os.clock() - lastWarn[key] > 10 then
        lastWarn[key] = os.clock()
        warn("[Astral] " .. tag .. ": " .. tostring(err))
    end
end

-- Bucle protegido: nunca rompe el script si algo falla
local function Loop(tag, interval, fn)
    task.spawn(function()
        while Hub.Running do
            local ok, err = pcall(fn)
            if not ok then safeWarn(tag, err) end
            local iv = interval
            if type(iv) == "function" then iv = iv() end
            task.wait(iv or 0.1)
        end
    end)
end

local function rndName()
    local s = ""
    for _ = 1, 14 do s = s .. string.char(math.random(97, 122)) end
    return s
end

-- ════════════════════════════════════════════════════════════════
--  Tema astral
-- ════════════════════════════════════════════════════════════════
local Palettes = {
    ["Nebulosa"]  = { Accent = Color3.fromRGB(168, 120, 255), Accent2 = Color3.fromRGB(86, 204, 255) },
    ["Aurora"]    = { Accent = Color3.fromRGB(64, 226, 190),  Accent2 = Color3.fromRGB(122, 140, 255) },
    ["Supernova"] = { Accent = Color3.fromRGB(255, 104, 178), Accent2 = Color3.fromRGB(255, 172, 92) },
    ["Eclipse"]   = { Accent = Color3.fromRGB(255, 202, 96),  Accent2 = Color3.fromRGB(172, 100, 255) },
    ["Andrómeda"] = { Accent = Color3.fromRGB(92, 142, 255),  Accent2 = Color3.fromRGB(206, 122, 255) },
}
local PaletteNames = { "Nebulosa", "Aurora", "Supernova", "Eclipse", "Andrómeda" }

local Theme = {
    Bg0    = Color3.fromRGB(6, 5, 16),
    Bg1    = Color3.fromRGB(15, 11, 36),
    Bg2    = Color3.fromRGB(27, 18, 60),
    Panel  = Color3.fromRGB(17, 14, 38),
    Panel2 = Color3.fromRGB(28, 23, 60),
    Hover  = Color3.fromRGB(40, 33, 82),
    Stroke = Color3.fromRGB(82, 68, 156),
    Text   = Color3.fromRGB(240, 237, 255),
    Sub    = Color3.fromRGB(170, 163, 214),
    Muted  = Color3.fromRGB(112, 106, 158),
    Good   = Color3.fromRGB(96, 232, 156),
    Warn   = Color3.fromRGB(255, 204, 92),
    Bad    = Color3.fromRGB(255, 86, 112),
    Accent = Palettes.Nebulosa.Accent,
    Accent2 = Palettes.Nebulosa.Accent2,
}

local F = {
    Black = Enum.Font.GothamBlack,
    Bold  = Enum.Font.GothamBold,
    Med   = Enum.Font.GothamMedium,
    Reg   = Enum.Font.Gotham,
    Mono  = Enum.Font.Code,
}

local ThemedProps = {}
local ThemedGradients = {}

local function New(class, props)
    local o = Instance.new(class)
    local parent
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then parent = v else o[k] = v end
        end
    end
    if parent then o.Parent = parent end
    return o
end

local function Themed(obj, prop, key)
    table.insert(ThemedProps, { obj, prop, key })
    obj[prop] = Theme[key]
    return obj
end

local function AccentGradient(parent, rotation)
    local g = New("UIGradient", {
        Rotation = rotation or 0,
        Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
        Parent = parent,
    })
    table.insert(ThemedGradients, g)
    return g
end

local function Corner(p, r)
    return New("UICorner", { CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r or 8), Parent = p })
end

local function Stroke(p, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = p,
    })
end

local function Padding(p, t, b, l, r)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        Parent = p,
    })
end

local function List(p, pad, dir, halign)
    return New("UIListLayout", {
        Padding = UDim.new(0, pad or 6),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = p,
    })
end

local function Txt(props)
    local t = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = F.Reg,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    for k, v in pairs(props) do
        if k ~= "Parent" then t[k] = v end
    end
    t.Parent = props.Parent
    return t
end

local function Tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function ApplyPalette(name)
    local p = Palettes[name]
    if not p then return end
    Theme.Accent, Theme.Accent2 = p.Accent, p.Accent2
    for _, t in ipairs(ThemedProps) do
        if t[1] and t[1].Parent then pcall(function() t[1][t[2]] = Theme[t[3]] end) end
    end
    local seq = ColorSequence.new(Theme.Accent, Theme.Accent2)
    for _, g in ipairs(ThemedGradients) do
        if g.Parent then g.Color = seq end
    end
end

-- ════════════════════════════════════════════════════════════════
--  Logo de Astral (PNG incrustado al final del archivo → getcustomasset)
-- ════════════════════════════════════════════════════════════════
local LogoImage
do
    local targets = {}
    local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function luaDecode(data)
        local map = {}
        for i = 1, #B64 do map[string.byte(B64, i)] = i - 1 end
        local out, chunk = {}, {}
        local bits, nbits = 0, 0
        for i = 1, #data do
            local v = map[string.byte(data, i)]
            if v then
                bits = bits * 64 + v
                nbits = nbits + 6
                if nbits >= 8 then
                    nbits = nbits - 8
                    local byte = math.floor(bits / 2 ^ nbits) % 256
                    bits = bits % (2 ^ nbits)
                    chunk[#chunk + 1] = string.char(byte)
                    if #chunk >= 4096 then out[#out + 1] = table.concat(chunk); chunk = {} end
                end
            end
        end
        out[#out + 1] = table.concat(chunk)
        return table.concat(out)
    end

    -- Crea un ImageLabel que mostrará el logo (con "✦" de respaldo si el executor no soporta assets)
    LogoImage = function(props, fallbackSize)
        local img = New("ImageLabel", props)
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Fit
        local fb = Txt({ Parent = img, Text = fallbackSize and "✦" or "", Font = F.Black, TextSize = fallbackSize or 1,
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.new(1, 1, 1) })
        table.insert(targets, { img = img, fb = fb })
        if Hub.LogoAsset then
            img.Image = Hub.LogoAsset
            fb.Visible = false
        end
        return img
    end

    function Hub.ApplyLogo(b64)
        if Hub.LogoAsset or not (Env.getasset and Env.writefile) or type(b64) ~= "string" then return false end
        local ok = pcall(function()
            if Env.makefolder and not (Env.isfolder and Env.isfolder("AstralHub")) then Env.makefolder("AstralHub") end
            local path = "AstralHub/logo_v" .. Hub.Version .. ".png"
            if not (Env.isfile and Env.isfile(path)) then
                local bytes
                if Env.b64decode then
                    local okd, r = pcall(Env.b64decode, b64)
                    if okd and type(r) == "string" and #r > 1000 then bytes = r end
                end
                bytes = bytes or luaDecode(b64)
                Env.writefile(path, bytes)
            end
            Hub.LogoAsset = Env.getasset(path)
        end)
        if not ok or not Hub.LogoAsset then Hub.LogoAsset = nil; return false end
        for _, t in ipairs(targets) do
            if t.img.Parent then
                t.img.Image = Hub.LogoAsset
                t.fb.Visible = false
            end
        end
        return true
    end
end

-- ════════════════════════════════════════════════════════════════
--  ScreenGui protegido
-- ════════════════════════════════════════════════════════════════
local Gui = New("ScreenGui", {
    Name = rndName(),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
})
do
    if syn and syn.protect_gui then pcall(syn.protect_gui, Gui) end
    local ok = false
    if Env.gethui then ok = pcall(function() Gui.Parent = Env.gethui() end) end
    if not ok or not Gui.Parent then ok = pcall(function() Gui.Parent = CoreGui end) end
    if not ok or not Gui.Parent then Gui.Parent = PlayerGui end
end
Hub.Gui = Gui

-- ════════════════════════════════════════════════════════════════
--  Notificaciones
-- ════════════════════════════════════════════════════════════════
do
local NotifHolder = New("Frame", {
    Parent = Gui, BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 300, 1, -36),
})
New("UIListLayout", {
    Parent = NotifHolder, Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
})
local notifOrder = 0
local KindColor = { ok = "Good", warn = "Warn", bad = "Bad" }
local KindIcon = { ok = "✓", warn = "⚠", bad = "✕" }

function Hub.Notify(title, text, duration, kind)
    if Flags.Notifications == false and kind ~= "force" then return end
    if not Hub.Running then return end
    duration = duration or 4
    notifOrder = notifOrder + 1
    local col = KindColor[kind] and Theme[KindColor[kind]] or Theme.Accent

    local wrap = New("Frame", {
        Parent = NotifHolder, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = notifOrder,
    })
    local card = New("Frame", {
        Parent = wrap, BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.06,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, 30, 0, 0), ClipsDescendants = true,
    })
    Corner(card, 10)
    Stroke(card, col, 1, 0.55)
    New("UIGradient", {
        Parent = card, Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 195, 230)),
    })
    local bar = New("Frame", { Parent = card, BackgroundColor3 = col, Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0 })
    if not KindColor[kind] then bar.BackgroundColor3 = Color3.new(1, 1, 1); AccentGradient(bar, 90) end
    local body = New("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    Padding(body, 9, 12, 16, 12)
    List(body, 3)
    Txt({ Parent = body, Text = (KindIcon[kind] or "✦") .. "  " .. tostring(title), Font = F.Bold, TextSize = 13,
        TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1 })
    if text and text ~= "" then
        Txt({ Parent = body, Text = tostring(text), TextSize = 12, TextColor3 = Theme.Sub, TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
    end
    local prog = New("Frame", {
        Parent = card, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2),
    })
    AccentGradient(prog, 0)

    Tween(card, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
    Tween(prog, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        if not wrap.Parent then return end
        Tween(card, 0.35, { Position = UDim2.new(1, 30, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.36)
        wrap:Destroy()
    end)
end
end
local Notify = Hub.Notify
local rng = Random.new()

-- ════════════════════════════════════════════════════════════════
--  Arrastre
-- ════════════════════════════════════════════════════════════════
local function Draggable(handle, target, onClick)
    local dragging, startPos, startInput, moved = false, nil, nil, false
    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startInput, startPos = input.Position, target.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                    if not moved and onClick then onClick() end
                end
            end)
        end
    end)
    Connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if d.Magnitude > 4 then moved = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Ventana principal
-- ════════════════════════════════════════════════════════════════
local Window, Holder, UIScaleObj, FX, ShootingStar, Orb, OrbGrad, BorderGrad, LogoGrad, refreshBorder, Main
do
local WIN_W, WIN_H = 680, 450

Holder = New("Frame", {
    Parent = Gui, Name = "Holder", BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
})
UIScaleObj = New("UIScale", { Parent = Holder, Scale = 1 })
Hub.BaseScale = 1

New("ImageLabel", {
    Parent = Holder, BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    Size = UDim2.new(1, 80, 1, 80), Position = UDim2.fromOffset(-40, -40), ZIndex = 0,
})
local Glow = New("ImageLabel", {
    Parent = Holder, BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993", ImageTransparency = 0.72,
    ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    Size = UDim2.new(1, 60, 1, 60), Position = UDim2.fromOffset(-30, -30), ZIndex = 0,
})
Themed(Glow, "ImageColor3", "Accent")

Main = New("Frame", {
    Parent = Holder, Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true, ZIndex = 1,
})
Corner(Main, 14)
New("UIGradient", {
    Parent = Main, Rotation = 125,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Bg2),
        ColorSequenceKeypoint.new(0.45, Theme.Bg1),
        ColorSequenceKeypoint.new(1, Theme.Bg0),
    }),
})
local MainStroke = New("UIStroke", {
    Parent = Main, Thickness = 1.5, Transparency = 0.1, Color = Color3.new(1, 1, 1),
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
BorderGrad = New("UIGradient", {
    Parent = MainStroke,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Theme.Bg2),
        ColorSequenceKeypoint.new(1, Theme.Accent2),
    }),
})
refreshBorder = function()
    BorderGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Theme.Bg2),
        ColorSequenceKeypoint.new(1, Theme.Accent2),
    })
end

-- Capa de cielo: nebulosas, estrellas y estrellas fugaces
FX = New("Frame", { Parent = Main, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1 })
local function Nebula(key, pos, size, rot, dur, drift)
    local f = New("Frame", {
        Parent = FX, BackgroundTransparency = 0.8, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, Rotation = rot,
    })
    Themed(f, "BackgroundColor3", key)
    Corner(f, "full")
    New("UIGradient", {
        Parent = f, Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
    TweenService:Create(f, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Position = pos + drift, Rotation = rot + 8,
    }):Play()
    return f
end
Nebula("Accent",  UDim2.fromScale(0.78, 0.22), UDim2.fromOffset(420, 160), -18, 14, UDim2.fromOffset(-40, 20))
Nebula("Accent2", UDim2.fromScale(0.30, 0.86), UDim2.fromOffset(460, 150), 12, 17, UDim2.fromOffset(50, -18))
Nebula("Accent",  UDim2.fromScale(0.12, 0.30), UDim2.fromOffset(260, 110), 35, 12, UDim2.fromOffset(20, 30))
Hub.BgLogo = LogoImage({ Parent = FX, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.64, 0.6),
    Size = UDim2.fromOffset(330, 330), ImageTransparency = 0.9 })

local StarColors = {
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 220, 255),
    Color3.fromRGB(230, 205, 255), Color3.fromRGB(255, 240, 215),
}
local Stars = {}
for _ = 1, 75 do
    local r = rng:NextNumber()
    local size = (r > 0.93) and 3 or ((r > 0.62) and 2 or 1)
    local star = New("Frame", {
        Parent = FX, BorderSizePixel = 0,
        BackgroundColor3 = StarColors[rng:NextInteger(1, #StarColors)],
        BackgroundTransparency = rng:NextNumber(0.05, 0.6),
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
    })
    if size >= 2 then Corner(star, "full") end
    TweenService:Create(star, TweenInfo.new(rng:NextNumber(1.2, 3.8), Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 3)),
        { BackgroundTransparency = rng:NextNumber(0.65, 1) }):Play()
    table.insert(Stars, star)
end

ShootingStar = function()
    local ang = math.rad(25)
    local ss = New("Frame", {
        Parent = FX, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0, 0.5), Rotation = -25, Size = UDim2.fromOffset(rng:NextInteger(70, 120), 2),
        Position = UDim2.new(rng:NextNumber(0.35, 1.05), 0, rng:NextNumber(-0.05, 0.35), 0),
    })
    Corner(ss, "full")
    New("UIGradient", { Parent = ss, Transparency = NumberSequence.new(0, 1) })
    local dist = rng:NextInteger(320, 460)
    local tw = Tween(ss, rng:NextNumber(0.8, 1.3), {
        Position = ss.Position + UDim2.fromOffset(-dist * math.cos(ang), dist * math.sin(ang)),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tw.Completed:Connect(function() ss:Destroy() end)
end

-- Barra superior
local Top = New("Frame", { Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), ZIndex = 2 })
local LogoHalo = New("Frame", {
    Parent = Top, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(32, 27),
    Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7,
})
Corner(LogoHalo, "full")
LogoGrad = AccentGradient(LogoHalo, 45)
TweenService:Create(LogoHalo, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Size = UDim2.fromOffset(42, 42), BackgroundTransparency = 0.88 }):Play()
Hub.TopLogo = LogoImage({ Parent = Top, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(32, 27),
    Size = UDim2.fromOffset(44, 44) }, 20)
local TitleL = Txt({ Parent = Top, Text = "ASTRAL", Font = F.Black, TextSize = 19,
    Position = UDim2.fromOffset(58, 10), Size = UDim2.fromOffset(160, 20), TextColor3 = Color3.new(1, 1, 1) })
AccentGradient(TitleL, 0)
Txt({ Parent = Top, Text = "Dandy's World  ·  v" .. Hub.Version, Font = F.Med, TextSize = 11,
    Position = UDim2.fromOffset(58, 30), Size = UDim2.fromOffset(200, 14), TextColor3 = Theme.Muted })

local SearchBox = New("TextBox", {
    Parent = Top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -86, 0, 13),
    Size = UDim2.fromOffset(190, 28), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2,
    Font = F.Med, TextSize = 12, TextColor3 = Theme.Text, PlaceholderText = "⌕   Buscar función…",
    PlaceholderColor3 = Theme.Muted, Text = "", ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
})
Corner(SearchBox, 8)
Padding(SearchBox, 0, 0, 10, 10)
local SearchStroke = Stroke(SearchBox, Theme.Stroke, 1, 0.5)

local function TopButton(text, xOff, hoverKey)
    local b = New("TextButton", {
        Parent = Top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, xOff, 0, 13),
        Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2,
        Text = text, Font = F.Bold, TextSize = 13, TextColor3 = Theme.Sub, AutoButtonColor = false,
    })
    Corner(b, 8)
    Stroke(b, Theme.Stroke, 1, 0.5)
    b.MouseEnter:Connect(function() Tween(b, 0.15, { BackgroundColor3 = Theme[hoverKey], TextColor3 = Theme.Text }) end)
    b.MouseLeave:Connect(function() Tween(b, 0.15, { BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Sub }) end)
    return b
end
local MinBtn = TopButton("—", -50, "Hover")
local CloseBtn = TopButton("✕", -14, "Bad")

local Divider = New("Frame", {
    Parent = Main, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
    Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 0, 1), ZIndex = 2,
})
AccentGradient(Divider, 0)
Divider.BackgroundTransparency = 0.55

-- Barra lateral
local Side = New("Frame", {
    Parent = Main, Position = UDim2.fromOffset(10, 64), Size = UDim2.new(0, 158, 1, -74),
    BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.35, ZIndex = 2,
})
Corner(Side, 12)
Stroke(Side, Theme.Stroke, 1, 0.6)
local TabList = New("ScrollingFrame", {
    Parent = Side, BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, -62), ScrollBarThickness = 0,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
Padding(TabList, 8, 8, 8, 8)
List(TabList, 4)

local Profile = New("Frame", {
    Parent = Side, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8),
    Size = UDim2.new(1, -16, 0, 46), BackgroundColor3 = Theme.Panel2, BackgroundTransparency = 0.3,
})
Corner(Profile, 10)
local Avatar = New("ImageLabel", {
    Parent = Profile, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = Theme.Bg2, Image = "",
})
Corner(Avatar, "full")
local AvStroke = Stroke(Avatar, Color3.new(1, 1, 1), 1.5, 0)
AccentGradient(AvStroke, 45)
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and img then Avatar.Image = img end
end)
Txt({ Parent = Profile, Text = LP.DisplayName, Font = F.Bold, TextSize = 12,
    Position = UDim2.fromOffset(46, 7), Size = UDim2.new(1, -50, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
local ProfileSub = Txt({ Parent = Profile, Text = "@" .. LP.Name, TextSize = 11, TextColor3 = Theme.Muted,
    Position = UDim2.fromOffset(46, 23), Size = UDim2.new(1, -50, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })

-- Contenido
local Content = New("Frame", {
    Parent = Main, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(178, 64), Size = UDim2.new(1, -188, 1, -74), ZIndex = 2,
    ClipsDescendants = true,
})

-- Orbe flotante (cuando la ventana está oculta)
Orb = New("TextButton", {
    Parent = Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 46, 0.5, 0),
    Size = UDim2.fromOffset(50, 50), BackgroundColor3 = Theme.Bg1, BackgroundTransparency = 0.1, Text = "",
    AutoButtonColor = false, Visible = false,
})
Corner(Orb, "full")
local OrbStroke = Stroke(Orb, Color3.new(1, 1, 1), 2, 0)
OrbGrad = AccentGradient(OrbStroke, 45)
Hub.OrbLogo = LogoImage({ Parent = Orb, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.95, 0.95) }, 22)

Draggable(Top, Holder)

-- ════════════════════════════════════════════════════════════════
--  Mostrar / ocultar
-- ════════════════════════════════════════════════════════════════
Hub.Visible = true
local animating = false
function Hub.SetVisible(v)
    if animating or v == Hub.Visible then return end
    animating = true
    Hub.Visible = v
    if v then
        Orb.Visible = false
        Holder.Visible = true
        UIScaleObj.Scale = Hub.BaseScale * 0.92
        Tween(UIScaleObj, 0.35, { Scale = Hub.BaseScale }, Enum.EasingStyle.Back)
        task.wait(0.2)
    else
        Tween(UIScaleObj, 0.2, { Scale = Hub.BaseScale * 0.9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.2)
        Holder.Visible = false
        UIScaleObj.Scale = Hub.BaseScale
        Orb.Visible = Flags.ShowOrb ~= false
        Orb.Size = UDim2.fromOffset(0, 0)
        Tween(Orb, 0.35, { Size = UDim2.fromOffset(50, 50) }, Enum.EasingStyle.Back)
    end
    animating = false
end
Draggable(Orb, Orb, function() task.spawn(Hub.SetVisible, true) end)
MinBtn.MouseButton1Click:Connect(function() task.spawn(Hub.SetVisible, false) end)

-- Diálogo de confirmación al cerrar
local Overlay = New("Frame", {
    Parent = Main, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 20, Active = true,
})
local Dialog = New("Frame", {
    Parent = Overlay, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(300, 140), BackgroundColor3 = Theme.Panel, ZIndex = 21,
})
Corner(Dialog, 12)
local DialogStroke = Stroke(Dialog, Color3.new(1, 1, 1), 1.2, 0.1)
AccentGradient(DialogStroke, 45)
Txt({ Parent = Dialog, Text = "¿Cerrar Astral?", Font = F.Bold, TextSize = 16, ZIndex = 22,
    Position = UDim2.fromOffset(18, 16), Size = UDim2.new(1, -36, 0, 20) })
Txt({ Parent = Dialog, Text = "Se desactivarán todas las funciones y se restaurará el juego.", TextSize = 12,
    TextColor3 = Theme.Sub, TextWrapped = true, ZIndex = 22, TextYAlignment = Enum.TextYAlignment.Top,
    Position = UDim2.fromOffset(18, 42), Size = UDim2.new(1, -36, 0, 34) })
local function DialogButton(text, x, primary)
    local b = New("TextButton", {
        Parent = Dialog, Position = UDim2.new(x, x == 0 and 18 or 6, 1, -46), Size = UDim2.new(0.5, -24, 0, 32),
        BackgroundColor3 = primary and Theme.Bad or Theme.Panel2, Text = text, Font = F.Bold, TextSize = 13,
        TextColor3 = Theme.Text, AutoButtonColor = false, ZIndex = 22,
    })
    Corner(b, 8)
    return b
end
local CancelBtn = DialogButton("Cancelar", 0, false)
local ConfirmBtn = DialogButton("Cerrar", 0.5, true)
CloseBtn.MouseButton1Click:Connect(function()
    Overlay.Visible = true
    Overlay.BackgroundTransparency = 1
    Tween(Overlay, 0.2, { BackgroundTransparency = 0.45 })
    Dialog.Size = UDim2.fromOffset(270, 120)
    Tween(Dialog, 0.3, { Size = UDim2.fromOffset(300, 140) }, Enum.EasingStyle.Back)
end)
CancelBtn.MouseButton1Click:Connect(function()
    Tween(Overlay, 0.15, { BackgroundTransparency = 1 })
    task.wait(0.15)
    Overlay.Visible = false
end)
ConfirmBtn.MouseButton1Click:Connect(function()
    if Hub.Unload then Hub.Unload() end
end)

-- ════════════════════════════════════════════════════════════════
--  Librería de elementos
-- ════════════════════════════════════════════════════════════════
Window = { Tabs = {}, Current = nil }
Hub.Window = Window
local orderCounter = 0
local function nextOrder() orderCounter = orderCounter + 1; return orderCounter end

local dirtyAt = nil
function Hub.MarkDirty() dirtyAt = os.clock() end
function Hub.DirtyAt() return dirtyAt end
function Hub.ClearDirty() dirtyAt = nil end

local function toSet(v)
    local s = {}
    if type(v) == "table" then
        for k, x in pairs(v) do
            if type(k) == "number" then s[x] = true elseif x then s[k] = true end
        end
    end
    return s
end

local SearchIndex = {}
local function applySearch()
    local q = string.lower(SearchBox.Text or "")
    local tab = Window.Current
    if not tab then return end
    local sectionVisible = {}
    for _, e in ipairs(SearchIndex) do
        if e.tab == tab then
            local match = (q == "") or (string.find(e.text, q, 1, true) ~= nil)
            e.frame.Visible = match
            if match then sectionVisible[e.section] = true end
        end
    end
    for _, s in ipairs(tab.Sections) do
        s.Visible = (q == "") or (sectionVisible[s] == true)
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)
SearchBox.Focused:Connect(function() Tween(SearchStroke, 0.15, { Transparency = 0, Color = Theme.Accent }) end)
SearchBox.FocusLost:Connect(function() Tween(SearchStroke, 0.15, { Transparency = 0.5, Color = Theme.Stroke }) end)

local function Ripple(button, x, y)
    local sc = math.max(Hub.BaseScale or 1, 0.1)
    local r = New("Frame", {
        Parent = button, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.75, Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset((x - button.AbsolutePosition.X) / sc, (y - button.AbsolutePosition.Y) / sc),
    })
    Corner(r, "full")
    local s = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) / sc * 2.2
    local tw = Tween(r, 0.5, { Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
    tw.Completed:Connect(function() r:Destroy() end)
end

local function KeyName(k)
    if typeof(k) == "EnumItem" then return k.Name end
    if type(k) == "string" and k ~= "" then return k end
    return "Ninguna"
end

local Keybinds = {}
local listeningKeybind = nil

function Window:Select(tab)
    if Window.Current == tab then return end
    local old = Window.Current
    Window.Current = tab
    for _, t in ipairs(Window.Tabs) do
        local active = (t == tab)
        Tween(t.Button, 0.25, { BackgroundTransparency = active and 0.55 or 1 })
        Tween(t.Label, 0.25, { TextColor3 = active and Theme.Text or Theme.Sub })
        Tween(t.Icon, 0.25, { TextColor3 = active and Theme.Accent or Theme.Muted })
        Tween(t.Bar, 0.3, { Size = active and UDim2.fromOffset(3, 18) or UDim2.fromOffset(3, 0) })
    end
    if old then old.Page.Visible = false end
    tab.Page.Visible = true
    tab.Page.Position = UDim2.fromOffset(0, 14)
    Tween(tab.Page, 0.35, { Position = UDim2.fromOffset(0, 0) })
    applySearch()
    if tab.OnShow then task.spawn(tab.OnShow) end
end

function Window:RefreshTabs()
    for _, t in ipairs(Window.Tabs) do
        local active = (t == Window.Current)
        t.Icon.TextColor3 = active and Theme.Accent or Theme.Muted
    end
end

function Window:Tab(name, icon, desc)
    local tab = { Name = name, Sections = {} }

    local btn = New("TextButton", {
        Parent = TabList, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Hover,
        BackgroundTransparency = 1, AutoButtonColor = false, Text = "", LayoutOrder = #Window.Tabs + 1,
    })
    Corner(btn, 8)
    local bar = New("Frame", {
        Parent = btn, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    })
    Corner(bar, "full")
    AccentGradient(bar, 90)
    local ic = Txt({ Parent = btn, Text = icon, Font = F.Bold, TextSize = 15, TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(24, 34), TextXAlignment = Enum.TextXAlignment.Center })
    local lb = Txt({ Parent = btn, Text = name, Font = F.Med, TextSize = 13, TextColor3 = Theme.Sub,
        Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -44, 1, 0) })
    btn.MouseEnter:Connect(function()
        if Window.Current ~= tab then Tween(btn, 0.15, { BackgroundTransparency = 0.8 }) end
    end)
    btn.MouseLeave:Connect(function()
        if Window.Current ~= tab then Tween(btn, 0.15, { BackgroundTransparency = 1 }) end
    end)

    local page = New("ScrollingFrame", {
        Parent = Content, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageTransparency = 0.3, ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    Themed(page, "ScrollBarImageColor3", "Accent")
    Padding(page, 2, 12, 0, 8)
    List(page, 10)

    local header = New("Frame", { Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 0 })
    local ht = Txt({ Parent = header, Text = name, Font = F.Black, TextSize = 20, Size = UDim2.new(1, 0, 0, 22), TextColor3 = Color3.new(1, 1, 1) })
    AccentGradient(ht, 0)
    Txt({ Parent = header, Text = desc or "", TextSize = 12, TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 16) })

    function tab:Banner(title, text)
        local b = New("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = Color3.new(1, 1, 1),
            LayoutOrder = 1, ClipsDescendants = true })
        Corner(b, 12)
        local g = New("UIGradient", { Parent = b, Rotation = 15, Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
            Transparency = NumberSequence.new(0.5, 0.78) })
        table.insert(ThemedGradients, g)
        Stroke(b, Color3.new(1, 1, 1), 1, 0.75)
        for _ = 1, 16 do
            local s = New("Frame", { Parent = b, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = rng:NextNumber(0.1, 0.6), Size = UDim2.fromOffset(2, 2),
                Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()) })
            Corner(s, "full")
            TweenService:Create(s, TweenInfo.new(rng:NextNumber(1, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = 1 }):Play()
        end
        local t1 = Txt({ Parent = b, Text = title, Font = F.Black, TextSize = 18, Position = UDim2.fromOffset(16, 12),
            Size = UDim2.new(1, -32, 0, 24), TextColor3 = Color3.new(1, 1, 1), RichText = true })
        local t2 = Txt({ Parent = b, Text = text, TextSize = 12, TextColor3 = Color3.fromRGB(232, 228, 255),
            Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -32, 0, 30), TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top, RichText = true })
        return { Title = t1, Text = t2 }
    end

    local cols = New("Frame", { Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
    local left = New("Frame", { Parent = cols, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y })
    local right = New("Frame", { Parent = cols, BackgroundTransparency = 1, Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    List(left, 10)
    List(right, 10)

    tab.Button, tab.Icon, tab.Label, tab.Bar, tab.Page = btn, ic, lb, bar, page
    btn.MouseButton1Click:Connect(function() Window:Select(tab) end)
    table.insert(Window.Tabs, tab)

    function tab:Section(title, side)
        local col = (side == 2) and right or left
        local sec = New("Frame", {
            Parent = col, BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.18,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(),
        })
        Corner(sec, 10)
        Stroke(sec, Theme.Stroke, 1, 0.6)
        Padding(sec, 10, 10, 10, 10)
        List(sec, 6)
        table.insert(tab.Sections, sec)

        local head = New("Frame", { Parent = sec, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0 })
        local dot = New("Frame", { Parent = head, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.new(1, 1, 1), Rotation = 45 })
        Corner(dot, 2)
        AccentGradient(dot, 45)
        Txt({ Parent = head, Text = string.upper(title), Font = F.Bold, TextSize = 11, TextColor3 = Theme.Sub,
            Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -15, 1, 0) })

        local S = {}
        local function register(frame, text)
            table.insert(SearchIndex, { frame = frame, text = string.lower(text or ""), tab = tab, section = sec })
        end

        local function baseRow(height)
            local f = New("TextButton", {
                Parent = sec, Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Panel2,
                BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", LayoutOrder = nextOrder(),
                ClipsDescendants = true,
            })
            Corner(f, 8)
            f.MouseEnter:Connect(function() Tween(f, 0.15, { BackgroundTransparency = 0.2 }) end)
            f.MouseLeave:Connect(function() Tween(f, 0.15, { BackgroundTransparency = 0.45 }) end)
            return f
        end

        -- Toggle ───────────────────────────────────────────
        function S:Toggle(o)
            local h = o.Desc and 44 or 34
            local f = baseRow(h)
            local name = Txt({ Parent = f, Text = o.Name, Font = F.Med, TextSize = 13, TextColor3 = Theme.Sub,
                Position = UDim2.fromOffset(10, o.Desc and 6 or 0), Size = UDim2.new(1, -62, 0, o.Desc and 18 or h),
                TextTruncate = Enum.TextTruncate.AtEnd })
            if o.Desc then
                Txt({ Parent = f, Text = o.Desc, TextSize = 11, TextColor3 = Theme.Muted,
                    Position = UDim2.fromOffset(10, 23), Size = UDim2.new(1, -62, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
            end
            local sw = New("Frame", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(40, 21), BackgroundColor3 = Theme.Bg2 })
            Corner(sw, "full")
            Stroke(sw, Theme.Stroke, 1, 0.35)
            local fill = New("Frame", { Parent = sw, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1 })
            Corner(fill, "full")
            AccentGradient(fill, 0)
            local knob = New("Frame", { Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Theme.Sub })
            Corner(knob, "full")

            local state = false
            local obj = {}
            local function render(t)
                Tween(fill, t, { BackgroundTransparency = state and 0 or 1 })
                Tween(knob, t, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                    BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Sub })
                Tween(name, t, { TextColor3 = state and Theme.Text or Theme.Sub })
            end
            function obj:Set(v, silent)
                state = v and true or false
                if o.Flag then Flags[o.Flag] = state end
                render(0.22)
                if o.Callback and not silent then task.spawn(o.Callback, state) end
                Hub.MarkDirty()
            end
            function obj:Get() return state end
            f.MouseButton1Click:Connect(function() obj:Set(not state) end)
            if o.Flag then
                Flags[o.Flag] = false
                Hub.Setters[o.Flag] = function(v) obj:Set(v) end
            end
            if o.Default then obj:Set(true) else render(0) end
            register(f, o.Name .. " " .. (o.Desc or ""))
            return obj
        end

        -- Slider ───────────────────────────────────────────
        function S:Slider(o)
            local step = o.Step or 1
            local decimals = (step < 1) and ((step < 0.1) and 2 or 1) or 0
            local f = baseRow(48)
            Txt({ Parent = f, Text = o.Name, Font = F.Med, TextSize = 13, TextColor3 = Theme.Text,
                Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -90, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd })
            local val = Txt({ Parent = f, Text = "", Font = F.Bold, TextSize = 12, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 4), Size = UDim2.fromOffset(80, 22), TextXAlignment = Enum.TextXAlignment.Right })
            Themed(val, "TextColor3", "Accent")
            local bar = New("Frame", { Parent = f, Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 0, 6),
                BackgroundColor3 = Theme.Bg2 })
            Corner(bar, "full")
            local fill = New("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
            Corner(fill, "full")
            AccentGradient(fill, 0)
            local knob = New("Frame", { Parent = bar, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(13, 13), BackgroundColor3 = Color3.new(1, 1, 1) })
            Corner(knob, "full")
            local ks = Stroke(knob, Theme.Accent, 2, 0)
            Themed(ks, "Color", "Accent")

            local value = o.Default or o.Min
            local obj = {}
            local function fmt(v)
                if decimals == 0 then return tostring(math.floor(v + 0.5)) end
                return string.format("%." .. decimals .. "f", v)
            end
            function obj:Set(v, silent, instant)
                v = tonumber(v) or o.Min
                v = math.clamp(v, o.Min, o.Max)
                v = math.floor(v / step + 0.5) * step
                v = math.clamp(v, o.Min, o.Max)
                value = v
                if o.Flag then Flags[o.Flag] = v end
                local pct = (o.Max == o.Min) and 0 or (v - o.Min) / (o.Max - o.Min)
                local t = instant and 0 or 0.08
                Tween(fill, t, { Size = UDim2.fromScale(pct, 1) })
                Tween(knob, t, { Position = UDim2.fromScale(pct, 0.5) })
                val.Text = fmt(v) .. (o.Suffix or "")
                if o.Callback and not silent then
                    local ok, err = pcall(o.Callback, v)
                    if not ok then safeWarn("Slider " .. o.Name, err) end
                end
                Hub.MarkDirty()
            end
            function obj:Get() return value end

            local dragging = false
            local function fromX(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                obj:Set(o.Min + (o.Max - o.Min) * rel, false, true)
            end
            Connect(f.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    fromX(input.Position.X)
                    Tween(knob, 0.12, { Size = UDim2.fromOffset(16, 16) })
                end
            end)
            Connect(UIS.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    fromX(input.Position.X)
                end
            end)
            Connect(UIS.InputEnded, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    Tween(knob, 0.12, { Size = UDim2.fromOffset(13, 13) })
                end
            end)
            if o.Flag then Hub.Setters[o.Flag] = function(v) obj:Set(v) end end
            obj:Set(value, true, true)
            register(f, o.Name)
            return obj
        end

        -- Dropdown ─────────────────────────────────────────
        function S:Dropdown(o)
            local options = o.Options or {}
            local multi = o.Multi
            local f = New("Frame", { Parent = sec, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Panel2,
                BackgroundTransparency = 0.45, ClipsDescendants = true, LayoutOrder = nextOrder() })
            Corner(f, 8)
            local head = New("TextButton", { Parent = f, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false })
            Txt({ Parent = head, Text = o.Name, Font = F.Med, TextSize = 13, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(0.5, -10, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
            local cur = Txt({ Parent = head, Text = "", Font = F.Med, TextSize = 12, TextColor3 = Theme.Sub,
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0.5, -30, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
            local arrow = Txt({ Parent = head, Text = "▾", Font = F.Bold, TextSize = 13, TextColor3 = Theme.Sub,
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(16, 34),
                TextXAlignment = Enum.TextXAlignment.Center })
            local listF = New("ScrollingFrame", { Parent = f, Position = UDim2.fromOffset(6, 38), Size = UDim2.new(1, -12, 0, 0),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y })
            Themed(listF, "ScrollBarImageColor3", "Accent")
            List(listF, 2)

            local open = false
            local selected = multi and {} or nil
            local single = nil
            local optButtons = {}
            local obj = {}

            local function display()
                if multi then
                    local names, count = {}, 0
                    for _, op in ipairs(options) do if selected[op] then count = count + 1; names[#names + 1] = op end end
                    if count == 0 then return "Ninguno" end
                    if count == #options and count > 1 then return "Todos" end
                    if count <= 2 then return table.concat(names, ", ") end
                    return names[1] .. ", " .. names[2] .. " +" .. (count - 2)
                end
                return single or "—"
            end
            local function paint()
                cur.Text = display()
                for op, b in pairs(optButtons) do
                    local on = multi and selected[op] or (single == op)
                    b.TextColor3 = on and Theme.Text or Theme.Sub
                    b.BackgroundTransparency = on and 0.5 or 1
                    b.Text = (on and "✓  " or "    ") .. op
                end
            end
            local function listHeight() return math.min(#options * 26, 156) end
            local function setOpen(v)
                open = v
                Tween(f, 0.25, { Size = UDim2.new(1, 0, 0, v and (34 + listHeight() + 8) or 34) })
                Tween(listF, 0.25, { Size = UDim2.new(1, -12, 0, v and listHeight() or 0) })
                Tween(arrow, 0.25, { Rotation = v and 180 or 0 })
            end
            local function fire()
                if o.Flag then
                    if multi then
                        local arr = {}
                        for _, op in ipairs(options) do if selected[op] then arr[#arr + 1] = op end end
                        Flags[o.Flag] = arr
                        Hub.Sets[o.Flag] = toSet(arr)
                    else
                        Flags[o.Flag] = single
                    end
                end
                Hub.MarkDirty()
                if o.Callback then task.spawn(o.Callback, multi and toSet(selected) or single) end
            end
            local function build()
                for _, b in pairs(optButtons) do b:Destroy() end
                optButtons = {}
                for i, op in ipairs(options) do
                    local b = New("TextButton", { Parent = listF, Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = Theme.Hover,
                        BackgroundTransparency = 1, AutoButtonColor = false, Font = F.Med, TextSize = 12,
                        TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left, Text = op, LayoutOrder = i })
                    Corner(b, 6)
                    Padding(b, 0, 0, 8, 4)
                    b.MouseButton1Click:Connect(function()
                        if multi then
                            selected[op] = not selected[op] or nil
                        else
                            single = op
                            setOpen(false)
                        end
                        paint()
                        fire()
                    end)
                    optButtons[op] = b
                end
                paint()
            end
            function obj:Set(v, silent)
                if multi then
                    selected = toSet(v)
                else
                    single = v
                end
                paint()
                if not silent then fire() else
                    if o.Flag then
                        if multi then
                            local arr = {}
                            for _, op in ipairs(options) do if selected[op] then arr[#arr + 1] = op end end
                            Flags[o.Flag] = arr
                            Hub.Sets[o.Flag] = toSet(arr)
                        else Flags[o.Flag] = single end
                    end
                end
            end
            function obj:Get() return multi and toSet(selected) or single end
            function obj:Refresh(newOptions, keep)
                options = newOptions or {}
                if not keep then
                    if multi then selected = {} else single = nil end
                end
                build()
                if open then setOpen(true) end
            end
            head.MouseButton1Click:Connect(function() setOpen(not open) end)
            build()
            if o.Flag then Hub.Setters[o.Flag] = function(v) obj:Set(v) end end
            if o.Default ~= nil then obj:Set(o.Default) else obj:Set(multi and {} or nil, true) end
            register(f, o.Name)
            return obj
        end

        -- Button ───────────────────────────────────────────
        function S:Button(o)
            local f = baseRow(o.Desc and 44 or 32)
            local label = Txt({ Parent = f, Text = o.Name, Font = F.Med, TextSize = 13,
                Position = UDim2.fromOffset(10, o.Desc and 6 or 0), Size = UDim2.new(1, -36, 0, o.Desc and 18 or 32),
                TextTruncate = Enum.TextTruncate.AtEnd })
            if o.Desc then
                Txt({ Parent = f, Text = o.Desc, TextSize = 11, TextColor3 = Theme.Muted,
                    Position = UDim2.fromOffset(10, 23), Size = UDim2.new(1, -36, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
            end
            local chev = Txt({ Parent = f, Text = "›", Font = F.Bold, TextSize = 18, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, -1), Size = UDim2.fromOffset(14, 20), TextXAlignment = Enum.TextXAlignment.Center })
            Themed(chev, "TextColor3", "Accent")
            f.MouseButton1Click:Connect(function()
                local m = UIS:GetMouseLocation()
                Ripple(f, m.X, m.Y)
                Tween(chev, 0.1, { Position = UDim2.new(1, -6, 0.5, -1) })
                task.delay(0.12, function() Tween(chev, 0.2, { Position = UDim2.new(1, -10, 0.5, -1) }) end)
                task.spawn(function()
                    local ok, err = pcall(o.Callback)
                    if not ok then
                        safeWarn("Botón " .. o.Name, err)
                        Notify("Error", tostring(err), 4, "bad")
                    end
                end)
            end)
            register(f, o.Name .. " " .. (o.Desc or ""))
            return { Label = label }
        end

        -- Keybind ──────────────────────────────────────────
        function S:Keybind(o)
            local f = baseRow(34)
            Txt({ Parent = f, Text = o.Name, Font = F.Med, TextSize = 13, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -110, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
            local chip = New("TextButton", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(92, 22), BackgroundColor3 = Theme.Bg2, Font = F.Bold, TextSize = 11,
                TextColor3 = Theme.Text, Text = "", AutoButtonColor = false })
            Corner(chip, 6)
            local cs = Stroke(chip, Theme.Accent, 1, 0.4)
            Themed(cs, "Color", "Accent")
            local key = o.Default
            local obj = { Callback = o.Callback }
            function obj:Set(k)
                if type(k) == "string" and k ~= "" and k ~= "Ninguna" then
                    local ok, e = pcall(function() return Enum.KeyCode[k] end)
                    key = ok and e or nil
                elseif typeof(k) == "EnumItem" then key = k else key = nil end
                chip.Text = KeyName(key)
                if o.Flag then Flags[o.Flag] = key and key.Name or "" end
                if o.Changed then task.spawn(o.Changed, key) end
                Hub.MarkDirty()
            end
            function obj:Get() return key end
            chip.MouseButton1Click:Connect(function()
                listeningKeybind = obj
                chip.Text = "· · ·"
            end)
            obj.Chip = chip
            if o.Flag then Hub.Setters[o.Flag] = function(v) obj:Set(v) end end
            obj:Set(key)
            table.insert(Keybinds, obj)
            register(f, o.Name)
            return obj
        end

        -- Textbox ──────────────────────────────────────────
        function S:Textbox(o)
            local f = New("Frame", { Parent = sec, Size = UDim2.new(1, 0, 0, o.Desc and 60 or 34), BackgroundColor3 = Theme.Panel2,
                BackgroundTransparency = 0.45, LayoutOrder = nextOrder() })
            Corner(f, 8)
            Txt({ Parent = f, Text = o.Name, Font = F.Med, TextSize = 13, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(0.42, -10, 0, 34), TextTruncate = Enum.TextTruncate.AtEnd })
            local box = New("TextBox", { Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6),
                Size = UDim2.new(0.58, -8, 0, 22), BackgroundColor3 = Theme.Bg2, Font = F.Med, TextSize = 12,
                TextColor3 = Theme.Text, PlaceholderText = o.Placeholder or "", PlaceholderColor3 = Theme.Muted,
                Text = o.Default or "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd })
            Corner(box, 6)
            Padding(box, 0, 0, 8, 8)
            local bs = Stroke(box, Theme.Stroke, 1, 0.4)
            if o.Desc then
                Txt({ Parent = f, Text = o.Desc, TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true,
                    Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -20, 0, 24), TextYAlignment = Enum.TextYAlignment.Top })
            end
            local obj = {}
            function obj:Set(v, silent)
                box.Text = tostring(v or "")
                if o.Flag then Flags[o.Flag] = box.Text end
                if o.Callback and not silent then task.spawn(o.Callback, box.Text) end
                Hub.MarkDirty()
            end
            function obj:Get() return box.Text end
            box.Focused:Connect(function() Tween(bs, 0.15, { Color = Theme.Accent, Transparency = 0 }) end)
            box.FocusLost:Connect(function()
                Tween(bs, 0.15, { Color = Theme.Stroke, Transparency = 0.4 })
                obj:Set(box.Text)
            end)
            if o.Flag then
                Flags[o.Flag] = box.Text
                Hub.Setters[o.Flag] = function(v) obj:Set(v) end
            end
            register(f, o.Name)
            return obj
        end

        -- Texto ────────────────────────────────────────────
        function S:Label(text, color)
            local l = Txt({ Parent = sec, Text = text, TextSize = 12, TextColor3 = color or Theme.Sub, TextWrapped = true,
                RichText = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder() })
            register(l, text)
            local obj = { Instance = l }
            function obj:Set(t, c) l.Text = t; if c then l.TextColor3 = c end end
            return obj
        end

        -- Fila de estadística (nombre · valor) ─────────────
        function S:Stat(name, initial)
            local f = New("Frame", { Parent = sec, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = nextOrder() })
            Txt({ Parent = f, Text = name, TextSize = 12, TextColor3 = Theme.Sub, Size = UDim2.new(0.5, 0, 1, 0) })
            local v = Txt({ Parent = f, Text = initial or "—", Font = F.Bold, TextSize = 12, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd, RichText = true })
            local line = New("Frame", { Parent = f, BorderSizePixel = 0, BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.75,
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1) })
            register(f, name)
            local obj = {}
            function obj:Set(t, c) v.Text = tostring(t); v.TextColor3 = c or Theme.Text end
            return obj
        end

        return S
    end

    return tab
end

-- Escucha global de teclas
Connect(UIS.InputBegan, function(input, gpe)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if listeningKeybind then
        local kb = listeningKeybind
        listeningKeybind = nil
        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
            kb:Set(nil)
        else
            kb:Set(input.KeyCode)
        end
        return
    end
    if gpe then return end
    for _, kb in ipairs(Keybinds) do
        local k = kb:Get()
        if k and input.KeyCode == k and kb.Callback then
            task.spawn(kb.Callback)
        end
    end
end)
end

-- ════════════════════════════════════════════════════════════════
--  Personaje
-- ════════════════════════════════════════════════════════════════
local function getChar() return LP.Character end
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function myModel()
    local f = workspace:FindFirstChild("InGamePlayers")
    return f and f:FindFirstChild(LP.Name)
end
local function isMe(inst)
    if inst == nil then return false end
    if inst == LP then return true end
    if typeof(inst) ~= "Instance" then return false end
    if inst == LP.Character then return true end
    local m = myModel()
    if m and inst == m then return true end
    return inst.Name == LP.Name
end
local function modelPart(m)
    if not m or not m.Parent then return nil end
    if m:IsA("BasePart") then return m end
    if m:IsA("Attachment") and m.Parent and m.Parent:IsA("BasePart") then return m.Parent end
    if m:IsA("Model") then
        local p = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Hitbox")
            or m:FindFirstChild("Root") or m:FindFirstChild("Head")
        if p and p:IsA("BasePart") then return p end
    end
    return m:FindFirstChildWhichIsA("BasePart", true)
end
local function posOf(m)
    local p = modelPart(m)
    return p and p.Position
end
local function distTo(m)
    local h, p = getHRP(), posOf(m)
    if h and p then return (h.Position - p).Magnitude end
    return math.huge
end
local function fmtDist(d)
    if not d or d == math.huge then return "?" end
    return string.format("%dm", math.floor(d + 0.5))
end
local function getEvent(name)
    local ev = ReplicatedStorage:FindFirstChild("Events")
    return ev and ev:FindFirstChild(name)
end

-- ════════════════════════════════════════════════════════════════
--  Datos del juego
-- ════════════════════════════════════════════════════════════════
local twistedDisplay, twistedRarity, twistedColor
local ItemInfo, ItemCategories, ItemCatColor, itemMeta
do
    local TwistedRarity = {}
    local function addRarity(list, r) for _, n in ipairs(list) do TwistedRarity[n] = r end end
    addRarity({ "Boxten", "Poppy", "Brusha", "Shrimpo", "Rudie", "Eggson", "Ribecca", "Yatta", "Tisha", "Looey", "Cosmo" }, "Común")
    addRarity({ "Finn", "Teagan", "Rodger", "RazzleDazzle", "Soulvester", "Ginger", "Flyte", "Connie", "Brightney", "Toodles" }, "Poco común")
    addRarity({ "Gigi", "Scraps", "Goob", "Waxwell", "Glisten", "Flutter", "Eclipse", "Cocoa", "Coal", "Squirm", "Blott", "Blot" }, "Raro")
    addRarity({ "Shelly", "Astro", "Pebble", "Vee", "Sprout", "Bassie", "Bobette", "Gourdy" }, "Principal")
    addRarity({ "Dandy", "Dyle" }, "Letal")

    local RarityColor = {
        ["Común"]       = Color3.fromRGB(232, 232, 245),
        ["Poco común"]  = Color3.fromRGB(110, 232, 142),
        ["Raro"]        = Color3.fromRGB(112, 170, 255),
        ["Principal"]   = Color3.fromRGB(255, 206, 92),
        ["Letal"]       = Color3.fromRGB(255, 56, 82),
        ["Evento"]      = Color3.fromRGB(255, 142, 44),
        ["Desconocido"] = Color3.fromRGB(255, 112, 150),
    }
    local EventTwisteds = { Gourdy = true, Eclipse = true, Soulvester = true, Ribecca = true }

    local function twistedBase(name)
        local b = string.gsub(name, "Monster$", "")
        b = string.gsub(b, "^Twisted", "")
        return b
    end
    twistedDisplay = function(name)
        if string.find(name, "BlotHand", 1, true) then return "Mano de Blot" end
        local b = twistedBase(name)
        if b == "RazzleDazzle" then b = "Razzle & Dazzle" end
        return "Twisted " .. b
    end
    twistedRarity = function(name)
        if string.find(name, "BlotHand", 1, true) then return "Raro" end
        return TwistedRarity[twistedBase(name)] or "Desconocido"
    end
    twistedColor = function(name)
        if Flags.EventTwistedColor and EventTwisteds[twistedBase(name)] then return RarityColor["Evento"] end
        return RarityColor[twistedRarity(name)]
    end

    ItemInfo = {
        ResearchCapsule = { "Cápsula de investigación", "Cápsulas" },
        FakeCapsule = { "Cápsula falsa", "Cápsulas" },
        Tape = { "Cinta", "Coleccionables" },
        HealthKit = { "Botiquín", "Curación" },
        Bandage = { "Venda", "Curación" },
        AirHorn = { "Bocina", "Utilidad" },
        SmokeBomb = { "Bomba de humo", "Utilidad" },
        EjectButton = { "Botón de expulsión", "Utilidad" },
        Stopwatch = { "Cronómetro", "Utilidad" },
        JumperCable = { "Cables", "Utilidad" },
        Instructions = { "Instrucciones", "Utilidad" },
        ProteinBar = { "Barra de proteína", "Caramelos" },
        Jawbreaker = { "Jawbreaker", "Caramelos" },
        ExtractionSpeedCandy = { "Caramelo de extracción", "Caramelos" },
        SkillCheckCandy = { "Caramelo skill check", "Caramelos" },
        StaminaCandy = { "Caramelo de estamina", "Caramelos" },
        StealthCandy = { "Caramelo de sigilo", "Caramelos" },
        SpeedCandy = { "Caramelo de velocidad", "Caramelos" },
        Gumball = { "Chicle", "Caramelos" },
        BonBon = { "BonBon", "Caramelos" },
        Chocolate = { "Chocolate", "Caramelos" },
        ChocolateBox = { "Caja de chocolates", "Caramelos" },
        Pop = { "Pop", "Caramelos" },
        PopBottle = { "Botella de Pop", "Caramelos" },
        Pumpkin = { "Calabaza", "Evento" },
        CollectablePiece = { "Carta de Halloween", "Evento" },
        DandyCorn = { "DandyCorn", "Evento" },
        ChristmasCookie = { "Galleta navideña", "Evento" },
        Ornament = { "Adorno", "Evento" },
        Basket = { "Canasta", "Evento" },
        DandyEasterEggs = { "Huevos de Dandy", "Evento" },
    }
    ItemCategories = { "Cápsulas", "Curación", "Utilidad", "Caramelos", "Coleccionables", "Evento", "Otros" }
    ItemCatColor = {
        ["Cápsulas"]       = Color3.fromRGB(92, 255, 146),
        ["Curación"]       = Color3.fromRGB(255, 96, 152),
        ["Utilidad"]       = Color3.fromRGB(122, 202, 255),
        ["Caramelos"]      = Color3.fromRGB(255, 216, 92),
        ["Coleccionables"] = Color3.fromRGB(205, 205, 218),
        ["Evento"]         = Color3.fromRGB(255, 150, 50),
        ["Otros"]          = Color3.fromRGB(192, 172, 255),
    }
    itemMeta = function(inst)
        local i = ItemInfo[inst.Name]
        if i then return i[1], i[2] end
        return inst.Name, "Otros"
    end
end

-- ════════════════════════════════════════════════════════════════
--  Estado del mundo + máquinas
-- ════════════════════════════════════════════════════════════════
local World = {
    Rooms = {}, RoomInst = nil, RoomName = "Lobby",
    Generators = {}, Monsters = {}, Items = {}, Capsules = {}, Event = {}, Doors = {},
    Elevators = {}, Fake = {}, Ichor = {}, Custom = {}, Info = {}, Panic = false, InRun = false,
    FreshUntil = 0,
}
Hub.World = World
Hub.CustomPatterns = {}
local Farm = { Status = "Inactivo", Target = nil, Skip = {}, Machines = 0, Floors = 0 }
Hub.Farm = Farm

local genInfo, machineCounts, nearestTwisted
do
    local CompletedKeys = { completed = true, complete = true, finished = true, done = true, fixed = true, repaired = true, extracted = true, powered = true }
    local ProgressKeys = { progress = true, completion = true, percent = true, percentage = true, extraction = true, extracted = true, amount = true }
    local GenMemo = setmetatable({}, { __mode = "k" })
    local PromptCache = setmetatable({}, { __mode = "k" })

    genInfo = function(g, fresh)
        local memo = GenMemo[g]
        if memo and not fresh and os.clock() - memo.t < 0.15 then return memo.info end
        local info = { completed = false, progress = nil, actives = {}, hasActiveField = false, duo = false, prompt = nil }
        local nl = string.lower(g.Name)
        info.duo = (string.find(nl, "duo", 1, true) ~= nil) or (string.find(nl, "dual", 1, true) ~= nil)
        local function consider(name, val, isObjValue)
            local l = string.lower(name)
            local activeName = string.find(l, "player", 1, true) or string.find(l, "user", 1, true) or string.find(l, "active", 1, true)
            if activeName and (isObjValue or typeof(val) == "Instance") then
                info.hasActiveField = true
                if typeof(val) == "Instance" then table.insert(info.actives, val) end
                return
            end
            if activeName and type(val) == "string" and string.find(l, "player", 1, true) then
                info.hasActiveField = true
                if val ~= "" then table.insert(info.actives, Players:FindFirstChild(val) or workspace:FindFirstChild(val) or g) end
                return
            end
            if type(val) == "boolean" then
                if CompletedKeys[l] then info.completed = info.completed or val end
            elseif type(val) == "number" then
                if ProgressKeys[l] or string.find(l, "progress", 1, true) then info.progress = val end
                if (string.find(l, "required", 1, true) or string.find(l, "needed", 1, true)) and val >= 2 then info.duo = true end
            end
        end
        local stats = g:FindFirstChild("Stats")
        if stats then
            for _, v in ipairs(stats:GetChildren()) do
                if v:IsA("ObjectValue") then
                    consider(v.Name, v.Value, true)
                elseif v:IsA("ValueBase") then
                    consider(v.Name, v.Value, false)
                end
            end
            for k, v in pairs(stats:GetAttributes()) do consider(k, v, false) end
        end
        for k, v in pairs(g:GetAttributes()) do consider(k, v, false) end
        if info.progress then
            if info.progress > 1.0001 then info.progress = info.progress / 100 end
            info.progress = math.clamp(info.progress, 0, 1)
            if info.progress >= 0.999 then info.completed = true end
        end
        local pc = PromptCache[g]
        if not (pc and pc.Parent and pc:IsDescendantOf(g)) then
            pc = g:FindFirstChildWhichIsA("ProximityPrompt", true)
            PromptCache[g] = pc
        end
        info.prompt = pc
        if not info.completed and Flags.PromptHeuristic ~= false and info.progress == nil and #info.actives == 0 then
            if not info.prompt or not info.prompt.Enabled then info.completed = true end
        end
        GenMemo[g] = { t = os.clock(), info = info }
        return info
    end
    Hub.GenInfo = genInfo

    machineCounts = function()
        local done, total = 0, #World.Generators
        for _, g in ipairs(World.Generators) do
            if genInfo(g).completed then done = done + 1 end
        end
        return done, total
    end

    nearestTwisted = function(pos)
        local best, bd = nil, math.huge
        if not pos then return nil, bd end
        for _, m in ipairs(World.Monsters) do
            if m.Parent then
                local p = posOf(m)
                if p then
                    local d = (p - pos).Magnitude
                    if d < bd then best, bd = m, d end
                end
            end
        end
        return best, bd
    end
end

-- ════════════════════════════════════════════════════════════════
--  Escáner del mapa
-- ════════════════════════════════════════════════════════════════
do
    local KnownTwisted = setmetatable({}, { __mode = "k" })
    local EventNames = {
        pumpkin = true, collectablepiece = true, dandycorn = true, candycorn = true, ornament = true,
        basket = true, dandyeastereggs = true, christmascookie = true,
    }
    local IchorNames = { Ichor_Puddle_01 = true, Ichor_Puddle_02 = true, Ichor_Puddle_03 = true, FinnIchorPuddle = true }

    function Hub.ScanFast()
        local cr = workspace:FindFirstChild("CurrentRoom")
        local rooms, gens, mons, items = {}, {}, {}, {}
        if cr then
            for _, m in ipairs(cr:GetChildren()) do
                if m:IsA("Model") or m:IsA("Folder") then
                    rooms[#rooms + 1] = m
                    local g = m:FindFirstChild("Generators")
                    if g then
                        for _, x in ipairs(g:GetChildren()) do
                            if x:IsA("Model") or x:IsA("BasePart") then gens[#gens + 1] = x end
                        end
                    end
                    local mf = m:FindFirstChild("Monsters") or m:FindFirstChild("Mobs")
                    if mf then
                        for _, x in ipairs(mf:GetChildren()) do
                            if x:IsA("Model") then mons[#mons + 1] = x end
                        end
                    end
                    local it = m:FindFirstChild("Items")
                    if it then
                        for _, x in ipairs(it:GetChildren()) do items[#items + 1] = x end
                    end
                end
            end
        end
        for _, x in ipairs(workspace:GetChildren()) do
            if x:IsA("Model") and (string.match(x.Name, "Monster$") or string.match(x.Name, "^BlotHand")) then
                mons[#mons + 1] = x
            end
        end

        World.Rooms, World.Generators, World.Monsters, World.Items = rooms, gens, mons, items
        local room = rooms[1]
        World.RoomName = room and room.Name or "Lobby / intermedio"
        if room ~= World.RoomInst then
            World.RoomInst = room
            if Hub.OnRoomChanged then task.spawn(Hub.OnRoomChanged, room) end
        end

        local info = workspace:FindFirstChild("Info")
        local t = {}
        if info then
            for _, v in ipairs(info:GetChildren()) do
                if v:IsA("ValueBase") then t[v.Name] = v.Value end
            end
            for k, v in pairs(info:GetAttributes()) do t[k] = v end
        end
        World.Info = t
        local wasPanic = World.Panic
        World.Panic = (t.Panic == true)
        if World.Panic and not wasPanic then
            World.PanicAt = os.clock()
            if Flags.NotifyPanic ~= false then Notify("¡PÁNICO!", "El elevador está abierto. ¡Corre!", 5, "warn") end
        end
        World.InRun = (#gens > 0) or (#mons > 0)

        for _, m in ipairs(mons) do
            if not KnownTwisted[m] then
                KnownTwisted[m] = true
                if Flags.NotifyTwisted and os.clock() > World.FreshUntil then
                    Notify(twistedDisplay(m.Name), "Apareció un Twisted " .. twistedRarity(m.Name) .. " a " .. fmtDist(distTo(m)), 4, "warn")
                end
            end
        end
    end

    function Hub.ScanDeep()
        local caps, evt, doors, elev, fake, ichor, custom = {}, {}, {}, {}, {}, {}, {}
        local patterns = Hub.CustomPatterns
        local function classify(d)
            local n = d.Name
            local parent = d.Parent
            if parent and parent.Name == n then return end
            local l = string.lower(n)
            if n == "ResearchCapsule" then
                caps[#caps + 1] = d
            elseif IchorNames[n] then
                ichor[#ichor + 1] = d
            elseif string.find(l, "fakeelevator", 1, true) or string.find(l, "fake_elevator", 1, true) then
                fake[#fake + 1] = d
            elseif n == "Elevator" and d:IsA("Model") then
                elev[#elev + 1] = d
            elseif string.find(l, "trickortreatdoor", 1, true) then
                doors[#doors + 1] = d
            elseif EventNames[l] or string.find(l, "pumpkin", 1, true) or string.find(l, "halloween", 1, true) or string.find(l, "candycorn", 1, true) then
                if d:IsA("Model") or d:IsA("BasePart") then evt[#evt + 1] = d end
            end
            if #patterns > 0 and #custom < 80 and (d:IsA("Model") or d:IsA("BasePart")) then
                for _, p in ipairs(patterns) do
                    if string.find(l, p, 1, true) then custom[#custom + 1] = d; break end
                end
            end
        end
        local cr = workspace:FindFirstChild("CurrentRoom")
        if cr then
            for _, d in ipairs(cr:GetDescendants()) do classify(d) end
        end
        local ef = workspace:FindFirstChild("Elevators")
        if ef then
            for _, d in ipairs(ef:GetChildren()) do
                local l = string.lower(d.Name)
                if string.find(l, "fake", 1, true) then fake[#fake + 1] = d
                elseif d:IsA("Model") or d:IsA("BasePart") then elev[#elev + 1] = d end
            end
        end
        for _, d in ipairs(workspace:GetChildren()) do
            if d ~= cr and d ~= ef then
                local l = string.lower(d.Name)
                if EventNames[l] or string.find(l, "pumpkin", 1, true) or string.find(l, "halloween", 1, true) or string.find(l, "candycorn", 1, true) then evt[#evt + 1] = d
                elseif string.find(l, "fakeelevator", 1, true) then fake[#fake + 1] = d
                elseif string.find(l, "trickortreatdoor", 1, true) then doors[#doors + 1] = d end
            end
        end
        World.Capsules, World.Event, World.Doors, World.Elevators, World.Fake, World.Ichor, World.Custom =
            caps, evt, doors, elev, fake, ichor, custom
    end
end

-- ════════════════════════════════════════════════════════════════
--  Movimiento
-- ════════════════════════════════════════════════════════════════
local Move = { Abort = false }
Hub.TempNoclip = false
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local moveTo, standNear, standInside, getSafeCFrame
do
    local function isTeleportMode(mode)
        return type(mode) == "string" and string.find(mode, "Teleport", 1, true) ~= nil
    end

    moveTo = function(cf, mode)
        local hrp = getHRP()
        if not hrp or not cf then return false end
        mode = mode or Flags.MoveMode or "Tween (seguro)"
        if isTeleportMode(mode) then
            hrp.CFrame = cf
            hrp.AssemblyLinearVelocity = Vector3.zero
            return true
        end
        local dist = (hrp.Position - cf.Position).Magnitude
        if dist < 1.5 then return true end
        local speed = math.max(Flags.TweenSpeed or 55, 5)
        local t = math.clamp(dist / speed, 0.05, 45)
        Hub.TempNoclip = true
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = cf })
        local done = false
        local conn = tw.Completed:Connect(function() done = true end)
        tw:Play()
        local t0 = os.clock()
        while not done and Hub.Running and os.clock() - t0 < t + 1.5 do
            if Move.Abort or not hrp.Parent then tw:Cancel(); break end
            hrp.AssemblyLinearVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
        end
        conn:Disconnect()
        Hub.TempNoclip = false
        Move.Abort = false
        return done
    end

    standNear = function(target, radiusOverride)
        if not target or not target.Parent then return nil end
        local hrp = getHRP()
        local pos, size
        if target:IsA("Model") then
            local cf, sz = target:GetBoundingBox()
            pos, size = cf.Position, sz
        else
            local p = modelPart(target)
            if not p then return nil end
            pos, size = p.Position, p.Size
        end
        local anchor = pos
        local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Parent then
            if prompt.Parent:IsA("BasePart") then anchor = prompt.Parent.Position
            elseif prompt.Parent:IsA("Attachment") then anchor = prompt.Parent.WorldPosition end
        end
        local from = hrp and hrp.Position or (anchor + Vector3.new(6, 0, 0))
        local flat = Vector3.new(from.X - anchor.X, 0, from.Z - anchor.Z)
        if flat.Magnitude < 0.1 then flat = Vector3.new(1, 0, 0) end
        local radius = radiusOverride or math.clamp(math.max(size.X, size.Z) * 0.5 + 2, 3, 8)
        if prompt and anchor ~= pos then radius = math.min(radius, math.max((prompt.MaxActivationDistance or 10) - 2.5, 3)) end
        local spot = Vector3.new(anchor.X, pos.Y, anchor.Z) + flat.Unit * radius
        rayParams.FilterDescendantsInstances = { LP.Character, target }
        local res = workspace:Raycast(spot + Vector3.new(0, size.Y * 0.5 + 4, 0), Vector3.new(0, -(size.Y + 40), 0), rayParams)
        local y = res and (res.Position.Y + 3.2) or pos.Y
        local p = Vector3.new(spot.X, y, spot.Z)
        return CFrame.lookAt(p, Vector3.new(anchor.X, y, anchor.Z))
    end

    standInside = function(model)
        if not model or not model.Parent then return nil end
        local hit = model:FindFirstChild("Hitbox", true)
        local cf, size
        if hit and hit:IsA("BasePart") then
            cf, size = hit.CFrame, hit.Size
        elseif model:IsA("Model") then
            cf, size = model:GetBoundingBox()
        else
            local p = modelPart(model)
            if not p then return nil end
            cf, size = p.CFrame, p.Size
        end
        rayParams.FilterDescendantsInstances = { LP.Character }
        local res = workspace:Raycast(cf.Position + Vector3.new(0, size.Y * 0.4, 0), Vector3.new(0, -(size.Y + 12), 0), rayParams)
        local y = res and (res.Position.Y + 3.2) or cf.Position.Y
        return CFrame.new(cf.Position.X, y, cf.Position.Z)
    end

    local SafePart
    getSafeCFrame = function(mode)
        local hrp = getHRP()
        mode = mode or Flags.EscapeMode or "Plataforma"
        if string.find(mode, "Plataforma", 1, true) or string.find(mode, "Alejarse", 1, true) then
            if not SafePart or not SafePart.Parent then
                SafePart = New("Part", {
                    Name = rndName(), Anchored = true, CanCollide = true, Size = Vector3.new(40, 1, 40),
                    Transparency = 0.75, Material = Enum.Material.ForceField, Color = Theme.Accent, Parent = workspace,
                })
            end
            local base = hrp and hrp.Position or Vector3.zero
            if (SafePart.Position - base).Magnitude > 40 then
                SafePart.Position = Vector3.new(base.X, base.Y + 240, base.Z)
            end
            return SafePart.CFrame + Vector3.new(0, 3.5, 0)
        end
        local best, bestScore
        for _, g in ipairs(World.Generators) do
            local p = posOf(g)
            if p then
                local _, d = nearestTwisted(p)
                if not bestScore or d > bestScore then bestScore, best = d, g end
            end
        end
        if best then return standNear(best) end
        return nil
    end
    Hub.DestroySafePart = function()
        if SafePart then SafePart:Destroy(); SafePart = nil end
    end
end

-- ════════════════════════════════════════════════════════════════
--  Interacción
-- ════════════════════════════════════════════════════════════════
local firePrompt, interact
do
    firePrompt = function(p)
        if not p or not p.Parent then return false end
        pcall(function() p.HoldDuration = 0 end)
        if Env.fireprompt then
            local ok = pcall(Env.fireprompt, p)
            if ok then return true end
        end
        return pcall(function()
            p:InputHoldBegin()
            task.wait(0.05)
            p:InputHoldEnd()
        end)
    end

    interact = function(inst)
        if not inst or not inst.Parent then return false end
        local p = inst:IsA("ProximityPrompt") and inst or inst:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then return firePrompt(p) end
        local cd = inst:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and Env.fireclick then
            pcall(Env.fireclick, cd)
            return true
        end
        local part, hrp = modelPart(inst), getHRP()
        if part and hrp and Env.firetouch then
            pcall(Env.firetouch, hrp, part, 0)
            task.wait()
            pcall(Env.firetouch, hrp, part, 1)
            return true
        end
        return false
    end

    local PPS = game:GetService("ProximityPromptService")
    Connect(PPS.PromptShown, function(prompt)
        if Flags.InstantPrompts then pcall(function() prompt.HoldDuration = 0 end) end
    end)
    Connect(PPS.PromptButtonHoldBegan, function(prompt)
        if Flags.InstantPrompts and Env.fireprompt then pcall(Env.fireprompt, prompt) end
    end)
end

local function otherCharacters()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then t[#t + 1] = p.Character end
    end
    return t
end

-- ════════════════════════════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════════════════════════════
do
    local ESPFolder = New("Folder", { Name = rndName(), Parent = Gui.Parent })
    local ESP = { Entries = {}, HL = 0 }
    Hub.ESP = ESP

    local function espRemove(inst)
        local e = ESP.Entries[inst]
        if not e then return end
        if e.hl then e.hl:Destroy(); ESP.HL = ESP.HL - 1 end
        if e.bb then e.bb:Destroy() end
        if e.tracer then pcall(function() e.tracer:Remove() end) end
        if e.arrow then e.arrow:Destroy() end
        ESP.Entries[inst] = nil
    end

    local function espCreate(inst, kind, color, label, useHL)
        local part = modelPart(inst)
        if not part then return nil end
        local e = { inst = inst, kind = kind, part = part, color = color, label = label }
        if useHL and Flags.ESPChams ~= false and ESP.HL < 30 then
            e.hl = New("Highlight", {
                Adornee = inst, FillColor = color, OutlineColor = color,
                FillTransparency = Flags.ESPFill or 0.72, OutlineTransparency = 0.05,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = ESPFolder,
            })
            ESP.HL = ESP.HL + 1
        end
        local bb = New("BillboardGui", {
            Adornee = part, AlwaysOnTop = true, Size = UDim2.fromOffset(220, 40), LightInfluence = 0,
            StudsOffsetWorldSpace = Vector3.new(0, (kind == "twisted" or kind == "player") and 3.2 or 2.2, 0),
            MaxDistance = Flags.ESPMaxDist or 1500, Parent = ESPFolder,
        })
        local ts = Flags.ESPTextSize or 13
        e.nameL = Txt({ Parent = bb, Text = label, Font = F.Bold, TextSize = ts, TextColor3 = color,
            Size = UDim2.new(1, 0, 0, ts + 3), TextXAlignment = Enum.TextXAlignment.Center,
            TextStrokeTransparency = 0.35, TextStrokeColor3 = Color3.new(0, 0, 0) })
        e.infoL = Txt({ Parent = bb, Text = "", Font = F.Med, TextSize = ts - 2, TextColor3 = Color3.fromRGB(225, 222, 240),
            Position = UDim2.fromOffset(0, ts + 3), Size = UDim2.new(1, 0, 0, ts), TextXAlignment = Enum.TextXAlignment.Center,
            TextStrokeTransparency = 0.45, TextStrokeColor3 = Color3.new(0, 0, 0) })
        e.bb = bb
        ESP.Entries[inst] = e
        return e
    end

    local function espSync(kind, list, enabled, mk)
        local present = {}
        if enabled then
            for _, inst in ipairs(list) do
                if inst and inst.Parent then
                    present[inst] = true
                    if not ESP.Entries[inst] then
                        local color, label, hl = mk(inst)
                        if color then espCreate(inst, kind, color, label, hl) end
                    end
                end
            end
        end
        for inst, e in pairs(ESP.Entries) do
            if e.kind == kind and not present[inst] then espRemove(inst) end
        end
    end

    function Hub.ESPRebuild()
        for inst in pairs(ESP.Entries) do espRemove(inst) end
    end
    function Hub.ESPCleanup()
        for inst in pairs(ESP.Entries) do pcall(espRemove, inst) end
        pcall(function() ESPFolder:Destroy() end)
    end

    local function toonOf(plr)
        if not plr then return nil end
        local a = plr:GetAttribute("SelectedCharacter") or plr:GetAttribute("ToonName") or plr:GetAttribute("Toon")
        if a then return tostring(a) end
        local c = plr.Character
        if c then
            a = c:GetAttribute("SelectedCharacter") or c:GetAttribute("ToonName") or c:GetAttribute("Toon")
            if a then return tostring(a) end
        end
        return nil
    end

    local function espSyncAll()
        local machines = World.Generators
        if Flags.ESPHideDone then
            local t = {}
            for _, g in ipairs(machines) do if not genInfo(g).completed then t[#t + 1] = g end end
            machines = t
        end
        espSync("twisted", World.Monsters, Flags.ESPTwisted, function(m)
            return twistedColor(m.Name), twistedDisplay(m.Name), true
        end)
        espSync("machine", machines, Flags.ESPMachines, function() return Theme.Warn, "Máquina", true end)
        espSync("item", World.Items, Flags.ESPItems, function(it)
            local name, cat = itemMeta(it)
            local filter = Hub.Sets.ESPItemCats
            if filter and next(filter) and not filter[cat] then return nil end
            return ItemCatColor[cat], name, Flags.ESPItemChams
        end)
        espSync("capsule", World.Capsules, Flags.ESPCapsules, function() return ItemCatColor["Cápsulas"], "Cápsula de investigación", false end)
        espSync("player", otherCharacters(), Flags.ESPPlayers, function(c)
            return Color3.fromRGB(110, 220, 255), c.Name, true
        end)
        espSync("elevator", World.Elevators, Flags.ESPElevator, function() return Theme.Good, "Elevador", true end)
        espSync("fake", World.Fake, Flags.ESPFakeElevator, function() return Theme.Bad, "Elevador FALSO", true end)
        espSync("ichor", World.Ichor, Flags.ESPIchor, function() return Color3.fromRGB(150, 90, 255), "Charco de Ichor", false end)
        espSync("event", World.Event, Flags.ESPEvent, function(x)
            local n = itemMeta(x)
            return ItemCatColor["Evento"], n, false
        end)
        espSync("door", World.Doors, Flags.ESPDoors, function() return Color3.fromRGB(255, 120, 30), "Puerta Truco o Trato", false end)
        espSync("custom", World.Custom, Flags.ESPCustom, function(x) return Color3.fromRGB(255, 90, 230), x.Name, false end)
    end

    local function espUpdate()
        local hrp = getHRP()
        local hp = hrp and hrp.Position
        local showDist = Flags.ESPDistance ~= false
        for inst, e in pairs(ESP.Entries) do
            if not inst.Parent then
                espRemove(inst)
            else
                local p = e.part
                if not p or not p.Parent then
                    p = modelPart(inst)
                    e.part = p
                    if p and e.bb then e.bb.Adornee = p end
                end
                if p then
                    local d = hp and (p.Position - hp).Magnitude or 0
                    local name, info, color = e.label, nil, e.color
                    local k = e.kind
                    if k == "twisted" then
                        color = twistedColor(inst.Name)
                        local near = d < (Flags.AlertRadius or 35)
                        name = (near and "⚠ " or "") .. twistedDisplay(inst.Name)
                        info = twistedRarity(inst.Name)
                        if hp then
                            local v = p.AssemblyLinearVelocity
                            local dir = (hp - p.Position)
                            if dir.Magnitude > 0.1 and v:Dot(dir.Unit) > 6 and d < 70 then
                                info = info .. " · ¡te sigue!"
                            end
                        end
                    elseif k == "machine" then
                        local gi = genInfo(inst)
                        name = gi.duo and "Máquina Dúo" or "Máquina"
                        if gi.completed then
                            color, info = Theme.Good, "✓ Completada"
                        else
                            local pct = gi.progress and string.format("%d%%", math.floor(gi.progress * 100 + 0.5)) or "Pendiente"
                            if #gi.actives > 0 then color, info = Theme.Warn, pct .. " · en uso"
                            else color, info = Color3.fromRGB(255, 128, 92), pct end
                        end
                    elseif k == "player" then
                        local plr = Players:GetPlayerFromCharacter(inst)
                        name = plr and plr.DisplayName or inst.Name
                        local hum = inst:FindFirstChildOfClass("Humanoid")
                        local toon = toonOf(plr)
                        info = (toon and (toon .. " · ") or "") .. (hum and string.format("%d HP", math.floor(hum.Health)) or "")
                    end
                    if showDist then
                        info = (info and info ~= "") and (info .. " · " .. fmtDist(d)) or fmtDist(d)
                    end
                    e.color = color
                    e.nameL.Text = name
                    e.nameL.TextColor3 = color
                    e.infoL.Text = info or ""
                    if e.hl then
                        e.hl.FillColor = color
                        e.hl.OutlineColor = color
                        e.hl.FillTransparency = Flags.ESPFill or 0.72
                    end
                    e.bb.MaxDistance = Flags.ESPMaxDist or 1500
                end
            end
        end
    end

    -- Trazadores + flechas fuera de pantalla
    local ArrowLayer = New("Frame", { Parent = Gui, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0 })
    local function makeArrow()
        local a = Txt({ Parent = ArrowLayer, Text = "▲", Font = F.Black, TextSize = 22, AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(30, 30), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Visible = false })
        Txt({ Parent = a, Name = "D", Text = "", Font = F.Bold, TextSize = 11, AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.fromOffset(60, 14), TextXAlignment = Enum.TextXAlignment.Center,
            TextStrokeTransparency = 0.3, TextColor3 = Theme.Text })
        return a
    end

    Connect(RunService.RenderStepped, function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vs = cam.ViewportSize
        local tracers = Flags.Tracers and Env.Drawing
        local arrows = Flags.OffscreenArrows
        local hrp = getHRP()
        local from
        if tracers then
            local origin = Flags.TracerOrigin or "Abajo"
            if origin == "Centro" then from = Vector2.new(vs.X / 2, vs.Y / 2)
            elseif origin == "Ratón" then from = UIS:GetMouseLocation()
            else from = Vector2.new(vs.X / 2, vs.Y - 8) end
        end
        for _, e in pairs(ESP.Entries) do
            if e.kind == "twisted" and e.part and e.part.Parent then
                local sp, on = cam:WorldToViewportPoint(e.part.Position)
                if tracers then
                    if not e.tracer then
                        local ok, l = pcall(function() return Env.Drawing.new("Line") end)
                        if ok and l then
                            l.Thickness = 1.6
                            l.Transparency = 1
                            e.tracer = l
                        end
                    end
                    if e.tracer then
                        e.tracer.Visible = on
                        if on then
                            e.tracer.From = from
                            e.tracer.To = Vector2.new(sp.X, sp.Y)
                            e.tracer.Color = e.color or Theme.Bad
                        end
                    end
                elseif e.tracer then
                    e.tracer.Visible = false
                end
                if arrows and not on and hrp then
                    if not e.arrow then e.arrow = makeArrow() end
                    local rel = cam.CFrame:PointToObjectSpace(e.part.Position)
                    local ang = math.atan2(rel.X, -rel.Z)
                    local r = math.min(vs.X, vs.Y) * 0.36
                    e.arrow.Visible = true
                    e.arrow.Position = UDim2.fromOffset(vs.X / 2 + math.sin(ang) * r, vs.Y / 2 - math.cos(ang) * r)
                    e.arrow.Rotation = math.deg(ang)
                    e.arrow.TextColor3 = e.color or Theme.Bad
                    e.arrow.D.Text = fmtDist((hrp.Position - e.part.Position).Magnitude)
                    e.arrow.D.Rotation = -math.deg(ang)
                elseif e.arrow then
                    e.arrow.Visible = false
                end
            end
        end
    end)

    Hub.ESPTick = function()
        espSyncAll()
        espUpdate()
    end
end

-- ════════════════════════════════════════════════════════════════
--  Radar astral
-- ════════════════════════════════════════════════════════════════
do
    local RADAR = 170
    local Radar = New("Frame", {
        Parent = Gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 80),
        Size = UDim2.fromOffset(RADAR, RADAR + 26), BackgroundTransparency = 1, Visible = false,
    })
    local Disc = New("Frame", { Parent = Radar, Size = UDim2.fromOffset(RADAR, RADAR), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.15 })
    Corner(Disc, "full")
    New("UIGradient", { Parent = Disc, Rotation = 120, Color = ColorSequence.new(Theme.Bg2, Theme.Bg0) })
    local DiscStroke = Stroke(Disc, Color3.new(1, 1, 1), 1.5, 0.1)
    AccentGradient(DiscStroke, 45)
    for _, s in ipairs({ 0.66, 0.33 }) do
        local ring = New("Frame", { Parent = Disc, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(s, s), BackgroundTransparency = 1 })
        Corner(ring, "full")
        Stroke(ring, Theme.Stroke, 1, 0.55)
    end
    New("Frame", { Parent = Disc, BorderSizePixel = 0, BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.6,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 0, 1) })
    New("Frame", { Parent = Disc, BorderSizePixel = 0, BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.6,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 1, 1, -10) })
    local Sweep = New("Frame", { Parent = Disc, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    local SweepLine = New("Frame", { Parent = Sweep, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.25, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.03),
        Size = UDim2.new(0, 2, 0.47, 0) })
    AccentGradient(SweepLine, 90)
    local DotLayer = New("Frame", { Parent = Disc, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    Txt({ Parent = Disc, Text = "▲", Font = F.Black, TextSize = 12, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Color3.new(1, 1, 1) })
    local RadarLabel = Txt({ Parent = Radar, Text = "", Font = F.Bold, TextSize = 11, TextColor3 = Theme.Sub,
        Position = UDim2.fromOffset(0, RADAR + 6), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = 0.5 })
    Draggable(Disc, Radar)

    local DotPool, dotUsed = {}, 0
    local function radarDot(x, y, color, size, edge)
        dotUsed = dotUsed + 1
        local d = DotPool[dotUsed]
        if not d then
            d = New("Frame", { Parent = DotLayer, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 })
            Corner(d, "full")
            DotPool[dotUsed] = d
        end
        d.Visible = true
        d.Size = UDim2.fromOffset(size, size)
        d.Position = UDim2.fromOffset(x, y)
        d.BackgroundColor3 = color
        d.BackgroundTransparency = edge and 0.5 or 0
    end

    Hub.RadarTick = function()
        if not Flags.Radar then Radar.Visible = false; return end
        Radar.Visible = true
        dotUsed = 0
        local hrp, cam = getHRP(), workspace.CurrentCamera
        if hrp and cam then
            local look = cam.CFrame.LookVector
            local fl = Vector3.new(look.X, 0, look.Z)
            if fl.Magnitude < 1e-3 then fl = Vector3.new(0, 0, -1) end
            fl = fl.Unit
            local right = Vector3.new(-fl.Z, 0, fl.X)
            local range = Flags.RadarRange or 120
            local half = RADAR / 2
            local scale = (half - 8) / range
            local function plot(pos, color, size)
                if not pos then return end
                local rel = pos - hrp.Position
                local x, y = rel:Dot(right) * scale, -rel:Dot(fl) * scale
                local len = math.sqrt(x * x + y * y)
                local edge = false
                if len > half - 8 then
                    x, y = x / len * (half - 8), y / len * (half - 8)
                    edge = true
                end
                radarDot(half + x, half + y, color, size, edge)
            end
            for _, g in ipairs(World.Generators) do
                local done = genInfo(g).completed
                if not (done and Flags.ESPHideDone) then
                    plot(posOf(g), done and Theme.Good or Theme.Warn, 7)
                end
            end
            if Flags.RadarItems then
                for _, c in ipairs(World.Capsules) do plot(posOf(c), ItemCatColor["Cápsulas"], 4) end
                for _, it in ipairs(World.Items) do
                    local _, cat = itemMeta(it)
                    plot(posOf(it), ItemCatColor[cat], 4)
                end
            end
            for _, el in ipairs(World.Elevators) do plot(posOf(el), Color3.new(1, 1, 1), 8) end
            for _, c in ipairs(otherCharacters()) do plot(posOf(c), Color3.fromRGB(110, 220, 255), 6) end
            for _, m in ipairs(World.Monsters) do plot(posOf(m), twistedColor(m.Name), 9) end
        end
        for i = dotUsed + 1, #DotPool do DotPool[i].Visible = false end
        local done, total = machineCounts()
        RadarLabel.Text = string.format("⚙ %d/%d   ☠ %d   %s", done, total, #World.Monsters, World.Panic and "· PÁNICO" or "")
    end

    Connect(RunService.RenderStepped, function(dt)
        if Radar.Visible then Sweep.Rotation = (Sweep.Rotation + dt * 140) % 360 end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Alertas de proximidad + HUD
-- ════════════════════════════════════════════════════════════════
do
    local Vignette = New("Frame", { Parent = Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -36, 1, -36), BackgroundTransparency = 1, Visible = false })
    Corner(Vignette, 24)
    local VStroke = New("UIStroke", { Parent = Vignette, Thickness = 18, Color = Theme.Bad, Transparency = 0.5 })
    local AlertPill = New("Frame", { Parent = Gui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56),
        Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.1, Visible = false })
    Corner(AlertPill, "full")
    Stroke(AlertPill, Theme.Bad, 1.2, 0.2)
    Padding(AlertPill, 0, 0, 14, 14)
    local AlertText = Txt({ Parent = AlertPill, Text = "", Font = F.Bold, TextSize = 13, TextColor3 = Theme.Text,
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X })
    local AlertSound = New("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.55, Parent = SoundService })
    Hub.AlertSound = AlertSound
    local lastPing = 0

    Hub.AlertTick = function()
        local hrp = getHRP()
        if not hrp or not Flags.ProximityAlert then
            Vignette.Visible, AlertPill.Visible = false, false
            return
        end
        local tw, d = nearestTwisted(hrp.Position)
        local radius = Flags.AlertRadius or 35
        if tw and d < radius then
            local k = 1 - d / radius
            Vignette.Visible = true
            AlertPill.Visible = true
            local pulse = (math.sin(os.clock() * (6 + k * 8)) + 1) / 2
            VStroke.Transparency = math.clamp(0.85 - k * 0.45 - pulse * 0.15, 0, 1)
            AlertText.Text = "⚠  " .. twistedDisplay(tw.Name) .. "  ·  " .. fmtDist(d)
            if Flags.AlertSound and os.clock() - lastPing > math.max(0.6, 2.4 - k * 2) then
                lastPing = os.clock()
                pcall(function() AlertSound:Play() end)
            end
        else
            Vignette.Visible, AlertPill.Visible = false, false
        end
    end

    local HUD = New("Frame", { Parent = Gui, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.15, Visible = false })
    Corner(HUD, "full")
    local HUDStroke = Stroke(HUD, Color3.new(1, 1, 1), 1, 0.3)
    AccentGradient(HUDStroke, 0)
    Padding(HUD, 0, 0, 6, 12)
    local HUDList = List(HUD, 6, Enum.FillDirection.Horizontal)
    HUDList.VerticalAlignment = Enum.VerticalAlignment.Center
    LogoImage({ Parent = HUD, Size = UDim2.fromOffset(22, 22), LayoutOrder = 0 }, 13)
    local HUDText = Txt({ Parent = HUD, Text = "", Font = F.Bold, TextSize = 12, Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X, RichText = true, LayoutOrder = 1 })
    local fpsFrames, fpsValue, fpsT = 0, 60, os.clock()
    Connect(RunService.RenderStepped, function()
        fpsFrames = fpsFrames + 1
        local now = os.clock()
        if now - fpsT >= 0.5 then
            fpsValue = math.floor(fpsFrames / (now - fpsT) + 0.5)
            fpsFrames, fpsT = 0, now
        end
    end)
    local function getPing()
        local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        return ok and math.floor(v + 0.5) or 0
    end
    Hub.HUDTick = function()
        HUD.Visible = Flags.ShowHUD == true
        if HUD.Visible then
            HUDText.Text = string.format('<font color="#%s">ASTRAL</font>  %d FPS  ·  %d ms  ·  %s',
                Theme.Accent:ToHex(), fpsValue, getPing(), World.RoomName)
        end
    end
end

-- ════════════════════════════════════════════════════════════════
--  Autofarm, elevador y recolección
-- ════════════════════════════════════════════════════════════════
local function setStatus(s) Farm.Status = s end
local collectPass, collectTargets, realElevator
do
    local function dangerRadius() return Flags.SafetyRadius or 30 end
    local function isDangerAt(pos)
        if not Flags.FarmSafety or not pos then return false end
        local _, d = nearestTwisted(pos)
        return d < dangerRadius()
    end

    local function machineAllowed(g, info)
        if info.completed then return false end
        if Farm.Skip[g] and os.clock() - Farm.Skip[g] < 25 then return false end
        if isDangerAt(posOf(g)) then return false end
        local othersOn = false
        for _, a in ipairs(info.actives) do if not isMe(a) then othersOn = true end end
        if info.duo then
            local mode = Flags.DuoMode or "Si hay compañero"
            if mode == "Nunca" then return false end
            if mode == "Si hay compañero" and not othersOn then return false end
            return true
        end
        if othersOn and Flags.FarmSkipBusy ~= false then return false end
        return true
    end

    local function chooseMachine()
        local hrp = getHRP()
        if not hrp then return nil end
        local best, bestScore
        local smart = (Flags.FarmMode or "Inteligente") == "Inteligente"
        for _, g in ipairs(World.Generators) do
            if g.Parent then
                local info = genInfo(g)
                if machineAllowed(g, info) then
                    local p = posOf(g)
                    if p then
                        local score = (p - hrp.Position).Magnitude
                        if smart then
                            local _, td = nearestTwisted(p)
                            score = score - math.min(td, 150) * 1.4
                            if info.progress then score = score - info.progress * 60 end
                        end
                        if not bestScore or score < bestScore then best, bestScore = g, score end
                    end
                end
            end
        end
        return best
    end

    local Collected = setmetatable({}, { __mode = "k" })
    collectTargets = function(farmMode)
        local list, seen = {}, {}
        local function add(x) if x and x.Parent and not seen[x] then seen[x] = true; list[#list + 1] = x end end
        local cats = Hub.Sets.CollectCats or {}
        local wantItems = farmMode and Flags.FarmCollect or (not farmMode and Flags.AutoCollect)
        local wantCaps = farmMode and Flags.FarmCollect or (not farmMode and Flags.AutoCapsules)
        local wantEvent = farmMode and Flags.FarmEvent ~= false or (not farmMode and Flags.AutoEvent)
        if wantItems then
            for _, it in ipairs(World.Items) do
                local _, cat = itemMeta(it)
                if cats[cat] or (cat == "Evento" and wantEvent) then add(it) end
            end
        end
        if wantCaps then
            for _, c in ipairs(World.Capsules) do add(c) end
            for _, it in ipairs(World.Items) do if it.Name == "ResearchCapsule" then add(it) end end
        end
        if wantEvent then
            for _, x in ipairs(World.Event) do add(x) end
            for _, it in ipairs(World.Items) do
                local _, cat = itemMeta(it)
                if cat == "Evento" then add(it) end
            end
        end
        if not farmMode and Flags.AutoIchor then for _, x in ipairs(World.Ichor) do add(x) end end
        local out = {}
        for _, it in ipairs(list) do
            if (Collected[it] or 0) < 3 then out[#out + 1] = it end
        end
        return out
    end

    collectPass = function(maxCount, returnBack, farmMode)
        local hrp = getHRP()
        if not hrp then return 0 end
        local origin = hrp.CFrame
        local pending = collectTargets(farmMode)
        local n = 0
        while #pending > 0 and Hub.Running and n < (maxCount or 50) do
            local h = getHRP()
            if not h then break end
            local bi, bd = nil, math.huge
            for i, it in ipairs(pending) do
                local p = posOf(it)
                if p then
                    local d = (p - h.Position).Magnitude
                    if d < bd then bi, bd = i, d end
                end
            end
            if not bi then break end
            local it = table.remove(pending, bi)
            local p = posOf(it)
            if p and it.Parent and not isDangerAt(p) then
                Collected[it] = (Collected[it] or 0) + 1
                local name, cat = itemMeta(it)
                setStatus("Recogiendo " .. name)
                moveTo(CFrame.new(p + Vector3.new(0, 3, 0)), Flags.MoveMode or "Teleport (rápido)")
                task.wait(0.08)
                interact(it)
                task.wait(Flags.CollectDelay or 0.15)
                if it.Parent then
                    interact(it)
                    task.wait(0.1)
                end
                if not it.Parent or not it:IsDescendantOf(workspace) then
                    Farm.Picked = (Farm.Picked or 0) + 1
                    if cat == "Evento" or World.Event[1] and table.find(World.Event, it) then
                        Farm.EventPicked = (Farm.EventPicked or 0) + 1
                    end
                end
                n = n + 1
            end
        end
        if returnBack and n > 0 then moveTo(origin, Flags.MoveMode or "Teleport (rápido)") end
        return n
    end
    Hub.CollectPass = collectPass

    local function shouldRefire(info, st)
        if info.hasActiveField then
            for _, a in ipairs(info.actives) do if isMe(a) then return false end end
            return os.clock() - st.lastFire > 1.2
        end
        if info.progress then
            if info.progress > st.lastProg + 0.0005 then
                st.lastProg, st.lastProgT = info.progress, os.clock()
                return false
            end
            return os.clock() - st.lastProgT > 3 and os.clock() - st.lastFire > 2.5
        end
        return info.prompt ~= nil and info.prompt.Enabled and os.clock() - st.lastFire > 5
    end

    -- Huida: TP a la plataforma segura o alejarse caminando (tween)
    local function escapeDanger()
        local h = getHRP()
        if not h then return end
        local tw = nearestTwisted(h.Position)
        setStatus("Huyendo de " .. (tw and twistedDisplay(tw.Name) or "Twisted"))
        local mode = Flags.EscapeMode or "Plataforma (TP)"
        if string.find(mode, "Alejarse", 1, true) then
            local tp = tw and posOf(tw)
            if not tp then return end
            local best, bestScore
            rayParams.FilterDescendantsInstances = { LP.Character, tw }
            for i = 0, 11 do
                local a = math.rad(i * 30)
                local dir = Vector3.new(math.cos(a), 0, math.sin(a))
                local len = dangerRadius() + 20
                local wall = workspace:Raycast(h.Position, dir * len, rayParams)
                local reach = wall and math.max((wall.Position - h.Position).Magnitude - 3, 0) or len
                if reach > 8 then
                    local spot = h.Position + dir * reach
                    local floor = workspace:Raycast(spot + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), rayParams)
                    if floor then
                        local _, nd = nearestTwisted(spot)
                        if not bestScore or nd > bestScore then
                            bestScore, best = nd, Vector3.new(spot.X, floor.Position.Y + 3.2, spot.Z)
                        end
                    end
                end
            end
            if best then moveTo(CFrame.new(best), "Tween (seguro)") end
        else
            local cf = getSafeCFrame("Plataforma")
            if cf then moveTo(cf, "Teleport (rápido)") end
        end
    end
    Hub.EscapeDanger = escapeDanger

    local function farmMachine(target)
        Farm.Target = target
        setStatus("Yendo a " .. target.Name)
        moveTo(standNear(target), Flags.MoveMode or "Teleport (rápido)")
        task.wait(0.05)
        local info = genInfo(target, true)
        firePrompt(info.prompt)
        local st = { lastFire = os.clock(), lastProg = info.progress or 0, lastProgT = os.clock() }
        local start = os.clock()
        while Flags.AutoFarm and Hub.Running and target.Parent do
            info = genInfo(target)
            if info.completed then
                Farm.Machines = Farm.Machines + 1
                if Flags.NotifyMachine ~= false then Notify("Máquina completada", "Total en esta sesión: " .. Farm.Machines, 2, "ok") end
                break
            end
            if World.Panic and Flags.AutoElevator then break end
            local hrp = getHRP()
            if not hrp then break end
            -- Peligro: dejamos esta máquina un momento y el bucle elige otra segura
            if isDangerAt(hrp.Position) or isDangerAt(posOf(target)) then
                Farm.Skip[target] = os.clock() - 17
                break
            end
            local tp = posOf(target)
            if tp and (hrp.Position - tp).Magnitude > 16 then
                moveTo(standNear(target), Flags.MoveMode or "Teleport (rápido)")
                firePrompt(info.prompt)
                st.lastFire = os.clock()
            elseif shouldRefire(info, st) then
                firePrompt(info.prompt)
                st.lastFire = os.clock()
            end
            local pct = info.progress and string.format(" · %d%%", math.floor(info.progress * 100 + 0.5)) or ""
            setStatus("Extrayendo " .. target.Name .. pct)
            if os.clock() - start > (Flags.FarmTimeout or 150) then
                Farm.Skip[target] = os.clock()
                break
            end
            task.wait(0.12)
        end
        Farm.Target = nil
    end

    Loop("Autofarm", 0.1, function()
        if not Flags.AutoFarm then
            if Farm.Status ~= "Inactivo" and not Farm.Collecting then setStatus("Inactivo") end
            return
        end
        local hrp, hum = getHRP(), getHum()
        if not hrp or not hum or hum.Health <= 0 then setStatus("Esperando personaje…"); return end
        if #World.Generators == 0 and #World.Event == 0 then setStatus("Esperando piso…"); return end
        if World.Panic and Flags.AutoElevator then setStatus("Pánico → elevador"); return end
        if (Flags.FarmCollect or Flags.FarmEvent ~= false) and #collectTargets(true) > 0 then
            collectPass(8, false, true)
        end
        local target = chooseMachine()
        if target then
            farmMachine(target)
            return
        end
        local done, total = machineCounts()
        if isDangerAt(hrp.Position) then
            escapeDanger()
            task.wait(0.4)
        elseif total > 0 and done >= total then
            setStatus("Piso completado ✓")
        else
            setStatus("Esperando máquina segura…")
        end
    end)

    realElevator = function()
        local best, bd
        for _, el in ipairs(World.Elevators) do
            if el.Parent then
                local d = distTo(el)
                if not bd or d < bd then best, bd = el, d end
            end
        end
        return best
    end
    Hub.RealElevator = realElevator

    local elevatorAnnounced = nil
    Loop("Elevador", 0.3, function()
        if not Flags.AutoElevator then return end
        local go = World.Panic
        if go and World.PanicAt and os.clock() - World.PanicAt < (Flags.ElevatorDelay or 0) then go = false end
        if not go and Flags.ElevatorWhenDone and #World.Generators > 0 then
            local done, total = machineCounts()
            go = total > 0 and done >= total
        end
        if not go then return end
        local el = realElevator()
        local hrp = getHRP()
        if not el or not hrp then return end
        local cf = standInside(el)
        if cf and (hrp.Position - cf.Position).Magnitude > 7 then
            setStatus("Entrando al elevador")
            moveTo(cf, Flags.ElevatorMove or "Teleport (rápido)")
            if elevatorAnnounced ~= World.RoomInst then
                elevatorAnnounced = World.RoomInst
                Notify("Elevador", "Dentro del elevador real ✓", 3, "ok")
            end
        end
    end)

    Loop("Recolección", 0.8, function()
        if Flags.AutoFarm then return end
        if not (Flags.AutoCollect or Flags.AutoCapsules or Flags.AutoEvent or Flags.AutoIchor) then return end
        if #collectTargets() == 0 then return end
        Farm.Collecting = true
        collectPass(nil, Flags.CollectReturn ~= false)
        Farm.Collecting = false
        setStatus("Inactivo")
    end)

    local AuraTried = setmetatable({}, { __mode = "k" })
    Loop("Aura", 0.25, function()
        if not Flags.ItemAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local range = Flags.AuraRange or 12
        local cats = Hub.Sets.CollectCats or {}
        local function try(x)
            local p = posOf(x)
            if p and (p - hrp.Position).Magnitude <= range then
                if not AuraTried[x] or os.clock() - AuraTried[x] > 1 then
                    AuraTried[x] = os.clock()
                    interact(x)
                end
            end
        end
        for _, it in ipairs(World.Items) do
            local _, cat = itemMeta(it)
            if cats[cat] or it.Name == "ResearchCapsule" then try(it) end
        end
        for _, c in ipairs(World.Capsules) do try(c) end
        for _, x in ipairs(World.Event) do try(x) end
        if Flags.AuraDoors then for _, x in ipairs(World.Doors) do try(x) end end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Auto skill check
-- ════════════════════════════════════════════════════════════════
local SC = { roots = {}, last = 0, debug = "Sin skill check activo" }
Hub.SC = SC
do
    local prev = setmetatable({}, { __mode = "k" })
    local cache = setmetatable({}, { __mode = "k" })
    local PTR_NAMES = { "needle", "pointer", "cursor", "arrow", "marker", "indicator", "spinner", "mover", "moving", "hand", "tick", "line" }
    local TGT_NAMES = { "perfect", "great", "sweet", "success", "goal", "target", "zone", "hit", "area", "region", "good", "green" }

    local function nameHas(n, list)
        n = string.lower(n)
        for _, p in ipairs(list) do
            if string.find(n, p, 1, true) then return true end
        end
        return false
    end

    local function shown(g)
        local o = g
        while o and o ~= game do
            if o:IsA("GuiObject") then
                if not o.Visible then return false end
            elseif o:IsA("LayerCollector") then
                return o.Enabled
            end
            o = o.Parent
        end
        return true
    end

    local function considerRoot(d)
        if (d:IsA("GuiObject") or d:IsA("LayerCollector")) and string.find(string.lower(d.Name), "skill", 1, true) then
            SC.roots[d] = true
        end
    end
    for _, d in ipairs(PlayerGui:GetDescendants()) do considerRoot(d) end
    Connect(PlayerGui.DescendantAdded, considerRoot)

    local function findParts(root)
        local c = cache[root]
        if c and c.ptr and c.ptr.Parent and c.tgt and c.tgt.Parent then return c.ptr, c.tgt end
        local ptr, tgt
        local desc = root:GetDescendants()
        for _, want in ipairs(TGT_NAMES) do
            for _, d in ipairs(desc) do
                if d:IsA("GuiObject") and string.find(string.lower(d.Name), want, 1, true) then tgt = d; break end
            end
            if tgt then break end
        end
        for _, want in ipairs(PTR_NAMES) do
            for _, d in ipairs(desc) do
                if d:IsA("GuiObject") and d ~= tgt and not nameHas(d.Name, TGT_NAMES)
                    and string.find(string.lower(d.Name), want, 1, true) then ptr = d; break end
            end
            if ptr then break end
        end
        cache[root] = { ptr = ptr, tgt = tgt }
        return ptr, tgt
    end

    local function scPress(root)
        local mode = Flags.SCInput or "Auto"
        local usedButton = false
        if (mode == "Auto" or mode == "Botón (señal)") and Env.getconns then
            for _, b in ipairs(root:GetDescendants()) do
                if b:IsA("GuiButton") and shown(b) then
                    for _, sig in ipairs({ b.Activated, b.MouseButton1Down, b.MouseButton1Click }) do
                        local ok, conns = pcall(Env.getconns, sig)
                        if ok and conns then
                            for _, c in ipairs(conns) do
                                pcall(function() c:Fire() end)
                                usedButton = true
                            end
                        end
                    end
                    if usedButton then break end
                end
            end
        end
        if usedButton then return end
        if mode == "Clic" then
            local g = root:IsA("GuiObject") and root or nil
            local pos = g and (g.AbsolutePosition + g.AbsoluteSize / 2) or (workspace.CurrentCamera.ViewportSize / 2)
            pcall(function()
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.02)
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            end)
            return
        end
        local key = (mode == "E") and Enum.KeyCode.E or Enum.KeyCode.Space
        pcall(function()
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            VIM:SendKeyEvent(false, key, false, game)
        end)
    end

    Connect(RunService.Heartbeat, function()
        if not (Flags.AutoSkill or Flags.SCRemove or Flags.SCDebug) then return end
        for root in pairs(SC.roots) do
            if not root.Parent then
                SC.roots[root] = nil
            elseif shown(root) then
                if Flags.SCRemove then
                    pcall(function() root:Destroy() end)
                    SC.roots[root] = nil
                else
                    local ptr, tgt = findParts(root)
                    if ptr and tgt and shown(ptr) then
                        local st = prev[ptr] or {}
                        local rot, ap = ptr.Rotation, ptr.AbsolutePosition
                        local hit = false
                        if (st.rot and math.abs(rot - st.rot) > 0.01) or st.mode == "rot" then
                            st.mode = "rot"
                            local diff = ((rot - tgt.Rotation - (Flags.SCOffset or 0)) + 180) % 360 - 180
                            hit = math.abs(diff) <= (Flags.SCTolerance or 10)
                            SC.debug = string.format("Rotación · puntero %s %.1f° · objetivo %s %.1f° · Δ %.1f°", ptr.Name, rot, tgt.Name, tgt.Rotation, diff)
                        else
                            local pc = ap + ptr.AbsoluteSize / 2
                            local ta, ts = tgt.AbsolutePosition, tgt.AbsoluteSize
                            local dx = st.ap and math.abs(ap.X - st.ap.X) or 0
                            local dy = st.ap and math.abs(ap.Y - st.ap.Y) or 0
                            local m = (Flags.SCMargin or 15) / 100
                            if dx >= dy then
                                hit = pc.X >= ta.X + ts.X * m and pc.X <= ta.X + ts.X * (1 - m)
                            else
                                hit = pc.Y >= ta.Y + ts.Y * m and pc.Y <= ta.Y + ts.Y * (1 - m)
                            end
                            SC.debug = string.format("Lineal · puntero %s (%d,%d) · objetivo %s [%d-%d]", ptr.Name,
                                math.floor(pc.X), math.floor(pc.Y), tgt.Name, math.floor(ta.X), math.floor(ta.X + ts.X))
                        end
                        st.rot, st.ap = rot, ap
                        prev[ptr] = st
                        if hit and Flags.AutoSkill and os.clock() - SC.last > 0.35 then
                            SC.last = os.clock()
                            task.spawn(scPress, root)
                        end
                    else
                        SC.debug = "Skill check visible (" .. root.Name .. ") pero sin puntero/objetivo reconocible"
                    end
                end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Hook de remotes: éxito forzado, registro y anti-kick
-- ════════════════════════════════════════════════════════════════
local installHook
do
    local RemoteLog = {}
    Hub.HookInstalled = false

    local function argSummary(...)
        local n = select("#", ...)
        local out = {}
        local args = { ... }
        for i = 1, math.min(n, 6) do
            local v = args[i]
            local t = typeof(v)
            if t == "Instance" then out[#out + 1] = v.ClassName .. ":" .. v.Name
            elseif t == "string" then out[#out + 1] = '"' .. string.sub(v, 1, 30) .. '"'
            else out[#out + 1] = tostring(v) end
        end
        return table.concat(out, ", ")
    end

    installHook = function()
        if Hub.HookInstalled then return true end
        if not (Env.hookmeta and Env.getncm) then return false end
        local ok = pcall(function()
            local old
            old = Env.hookmeta(game, "__namecall", Env.newcc(function(self, ...)
                if Hub.Running and (Flags.SCForce or Flags.RemoteLog or Flags.AntiKick) then
                    local caller = Env.checkcaller and Env.checkcaller()
                    if not caller then
                        local m = Env.getncm()
                        if Flags.AntiKick and (m == "Kick" or m == "kick") and self == LP then
                            return nil
                        end
                        if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
                            if Flags.RemoteLog and #RemoteLog < 400 then
                                RemoteLog[#RemoteLog + 1] = string.format("[%.1f] %s:%s(%s)", os.clock() - Hub.StartTime, self.Name, m, argSummary(...))
                            end
                            if Flags.SCForce then
                                local n = string.lower(self.Name)
                                if string.find(n, "skill", 1, true) or string.find(n, "check", 1, true) then
                                    local cnt = select("#", ...)
                                    local args = { ... }
                                    local changed = false
                                    for i = 1, cnt do
                                        local v = args[i]
                                        if v == false then
                                            args[i] = true
                                            changed = true
                                        elseif type(v) == "string" then
                                            local l = string.lower(v)
                                            if l == "fail" or l == "failed" or l == "miss" or l == "missed" or l == "bad" then
                                                args[i] = "Great"
                                                changed = true
                                            end
                                        end
                                    end
                                    if changed then return old(self, unpack(args, 1, cnt)) end
                                end
                            end
                        end
                    end
                end
                return old(self, ...)
            end))
        end)
        Hub.HookInstalled = ok
        return ok
    end
    Hub.InstallHook = installHook

    function Hub.CopyRemoteLog()
        local txt = table.concat(RemoteLog, "\n")
        if Env.setclip then Env.setclip(txt) end
        return #RemoteLog
    end
    function Hub.ClearRemoteLog() RemoteLog = {} end
end

-- ════════════════════════════════════════════════════════════════
--  Jugador: estamina
-- ════════════════════════════════════════════════════════════════
do
    local StaminaValues, StaminaTables, staminaScanAt = {}, {}, 0
    local function scanStaminaValues()
        StaminaValues = {}
        for _, root in ipairs({ LP.Character, myModel(), LP }) do
            if root then
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("NumberValue") or d:IsA("IntValue") then
                        local l = string.lower(d.Name)
                        if string.find(l, "stamina", 1, true) and not string.find(l, "max", 1, true) then
                            StaminaValues[#StaminaValues + 1] = d
                        end
                    end
                end
            end
        end
        staminaScanAt = os.clock()
    end

    function Hub.ScanStaminaGC()
        StaminaTables = {}
        if not Env.getgc then return 0 end
        local ok, gc = pcall(Env.getgc, true)
        if not ok or type(gc) ~= "table" then return 0 end
        for _, v in ipairs(gc) do
            if type(v) == "table" then
                for _, key in ipairs({ "Stamina", "stamina", "CurrentStamina" }) do
                    local okk, s = pcall(rawget, v, key)
                    if okk and type(s) == "number" then
                        local mx = rawget(v, "MaxStamina") or rawget(v, "maxStamina") or rawget(v, "StaminaMax")
                        StaminaTables[#StaminaTables + 1] = { t = v, key = key, max = (type(mx) == "number") and mx or nil }
                        break
                    end
                end
                if #StaminaTables >= 25 then break end
            end
        end
        return #StaminaTables
    end
    function Hub.StaminaCounts() return #StaminaValues, #StaminaTables end

    local function maxStaminaFor(inst)
        for k, v in pairs(inst:GetAttributes()) do
            local l = string.lower(k)
            if type(v) == "number" and string.find(l, "stamina", 1, true) and string.find(l, "max", 1, true) then return v end
        end
        return nil
    end

    Loop("Estamina", 0.1, function()
        if not Flags.InfStamina then return end
        if os.clock() - staminaScanAt > 5 then scanStaminaValues() end
        for _, root in ipairs({ LP.Character, myModel(), LP }) do
            if root then
                local mx = maxStaminaFor(root)
                for k, v in pairs(root:GetAttributes()) do
                    local l = string.lower(k)
                    if type(v) == "number" and string.find(l, "stamina", 1, true) and not string.find(l, "max", 1, true) then
                        local target = mx or math.max(v, 100)
                        if v < target then root:SetAttribute(k, target) end
                    end
                end
            end
        end
        for _, sv in ipairs(StaminaValues) do
            if sv.Parent then
                local mx = sv.Parent:FindFirstChild("MaxStamina")
                local target = (mx and mx:IsA("ValueBase") and tonumber(mx.Value)) or math.max(sv.Value, 100)
                if sv.Value < target then sv.Value = target end
            end
        end
        for _, e in ipairs(StaminaTables) do
            pcall(function()
                local cur = rawget(e.t, e.key)
                local target = e.max or rawget(e.t, "MaxStamina") or 100
                if type(cur) == "number" and cur < target then rawset(e.t, e.key, target) end
            end)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Jugador: movimiento, noclip, vuelo, anti-AFK, esquiva
-- ════════════════════════════════════════════════════════════════
do
    local Fly = { On = false }
    Connect(RunService.Heartbeat, function(dt)
        local hrp, hum = getHRP(), getHum()
        if not hrp or not hum then return end
        if Flags.WalkSpeedOn and Flags.WalkSpeed then hum.WalkSpeed = Flags.WalkSpeed end
        if Fly.On then
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            if dir.Magnitude < 0.01 and hum.MoveDirection.Magnitude > 0 then dir = hum.MoveDirection end
            hrp.AssemblyLinearVelocity = Vector3.zero
            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * (Flags.FlySpeed or 50) * dt
            end
        elseif (Flags.SpeedBoost or 0) > 0 and hum.MoveDirection.Magnitude > 0 and not Hub.TempNoclip then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection * Flags.SpeedBoost * dt
        end
    end)

    function Hub.SetFly(on)
        Fly.On = on
        local hum = getHum()
        if hum then hum.PlatformStand = on end
    end
    function Hub.FlyOn() return Fly.On end

    -- Noclip en 3 capas:
    --  1) CanCollide=false en el personaje Y en el modelo de InGamePlayers, antes y después de la física
    --  2) Desactiva estados del Humanoid que reactivan colisiones
    --  3) "Fase": si una pared bloquea el movimiento, te coloca al otro lado (funciona aunque el juego fuerce colisiones)
    local NoclipRestore = setmetatable({}, { __mode = "k" })
    local noclipStateSet = false
    local function noclipRoots()
        local roots = {}
        local c = LP.Character
        if c then roots[#roots + 1] = c end
        local m = myModel()
        if m and m ~= c then roots[#roots + 1] = m end
        return roots
    end
    local function noclipActive() return Flags.Noclip or Hub.TempNoclip or Hub.FlyOn() end
    local function applyNoclip()
        for _, root in ipairs(noclipRoots()) do
            for _, p in ipairs(root:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    NoclipRestore[p] = true
                    p.CanCollide = false
                end
            end
        end
    end
    local function noclipStep()
        local hum = getHum()
        if noclipActive() then
            applyNoclip()
            if hum and not noclipStateSet then
                noclipStateSet = true
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                end)
            end
        elseif next(NoclipRestore) then
            for p in pairs(NoclipRestore) do
                if p.Parent and (p.Name == "HumanoidRootPart" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso" or p.Name == "Head") then
                    p.CanCollide = true
                end
            end
            NoclipRestore = setmetatable({}, { __mode = "k" })
            if hum and noclipStateSet then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                end)
            end
            noclipStateSet = false
        end
    end
    Connect(RunService.Stepped, noclipStep)
    Connect(RunService.Heartbeat, function()
        if noclipActive() then applyNoclip() end
    end)
    Connect(LP.CharacterAdded, function() noclipStateSet = false end)

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    local lastPhase = 0
    local function spotFree(pos, ignore)
        overlap.FilterDescendantsInstances = ignore
        local parts = workspace:GetPartBoundsInRadius(pos, 1.6, overlap)
        for _, part in ipairs(parts) do
            if part.CanCollide and part.Transparency < 1.1 then return false end
        end
        return true
    end
    Connect(RunService.Heartbeat, function()
        if not Flags.Noclip or (Flags.NoclipMode or "Colisiones + fase") == "Solo colisiones" then return end
        if os.clock() - lastPhase < 0.12 then return end
        local hrp, hum = getHRP(), getHum()
        if not hrp or not hum then return end
        local md = hum.MoveDirection
        local flat = Vector3.new(md.X, 0, md.Z)
        if flat.Magnitude < 0.2 then return end
        flat = flat.Unit
        local ignore = noclipRoots()
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(hrp.Position, flat * 2.8, rayParams)
        if not hit or math.abs(hit.Normal.Y) > 0.35 then return end
        for dist = 3, 36, 1.5 do
            local probe = hrp.Position + flat * dist
            if spotFree(probe, ignore) then
                lastPhase = os.clock()
                hrp.CFrame = CFrame.new(probe) * (hrp.CFrame - hrp.Position)
                break
            end
        end
    end)

    Connect(LP.Idled, function()
        if Flags.AntiAFK ~= false then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)

    local Mouse = LP:GetMouse()
    Connect(UIS.InputBegan, function(input, gpe)
        if gpe or not Flags.ClickTP then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local hrp = getHRP()
            if hrp and Mouse.Hit then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.2, 0)) end
        end
    end)

    local lastDodge = 0
    Loop("Esquiva", 0.08, function()
        if not Flags.AutoDodge then return end
        if Flags.AutoFarm and Flags.FarmSafety then return end -- el autofarm ya gestiona la huida
        local hrp = getHRP()
        if not hrp or os.clock() - lastDodge < 0.7 then return end
        local tw, d = nearestTwisted(hrp.Position)
        if not tw or d > (Flags.DodgeRadius or 16) then return end
        local tp = posOf(tw)
        if not tp then return end
        local away = Vector3.new(hrp.Position.X - tp.X, 0, hrp.Position.Z - tp.Z)
        if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
        away = away.Unit
        local stepLen = Flags.DodgeDistance or 16
        local bestPos, bestScore
        rayParams.FilterDescendantsInstances = { LP.Character, tw }
        for i = -3, 3 do
            local a = math.rad(i * 30)
            local dir = Vector3.new(away.X * math.cos(a) - away.Z * math.sin(a), 0, away.X * math.sin(a) + away.Z * math.cos(a))
            local wall = workspace:Raycast(hrp.Position, dir * stepLen, rayParams)
            local reach = wall and math.max((wall.Position - hrp.Position).Magnitude - 2, 0) or stepLen
            if reach > 5 then
                local spot = hrp.Position + dir * reach
                local floor = workspace:Raycast(spot + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), rayParams)
                if floor then
                    local _, nd = nearestTwisted(spot)
                    local score = nd + reach * 0.3
                    if not bestScore or score > bestScore then
                        bestScore, bestPos = score, Vector3.new(spot.X, floor.Position.Y + 3.2, spot.Z)
                    end
                end
            end
        end
        if bestPos then
            lastDodge = os.clock()
            hrp.CFrame = CFrame.lookAt(bestPos, bestPos + away)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Jugador: habilidad, Squirm, curación, caramelos
-- ════════════════════════════════════════════════════════════════
local function useAbility(target)
    local ev = getEvent("AbilityEvent")
    local c, h = getChar(), getHRP()
    if not (ev and c and h) then return false end
    task.spawn(function()
        pcall(function() ev:InvokeServer(c, h.CFrame, target or false) end)
    end)
    return true
end
Hub.UseAbility = useAbility

do
    local lastAbility = 0
    Loop("Habilidad", 0.2, function()
        if not Flags.AutoAbility then return end
        if os.clock() - lastAbility < (Flags.AbilityInterval or 2) then return end
        lastAbility = os.clock()
        useAbility(Flags.AbilitySelf and getChar() or false)
    end)

    task.spawn(function()
        local events = ReplicatedStorage:WaitForChild("Events", 30)
        local remote = events and events:WaitForChild("TwistedSquirmGrab", 30)
        if not remote or not Hub.Running then return end
        local grabbed = false
        Connect(remote.OnClientEvent, function(action)
            if action == "GrabStart" then grabbed = true elseif action == "GrabEnd" then grabbed = false end
        end)
        local dir = "left"
        while Hub.Running do
            if Flags.AutoSquirm and grabbed then
                pcall(function() remote:FireServer("Struggle", dir) end)
                dir = (dir == "left") and "right" or "left"
                task.wait(0.06)
            else
                task.wait(0.15)
            end
        end
    end)

    local function inventorySlots()
        local slots = {}
        for _, root in ipairs({ LP.Character, myModel() }) do
            local inv = root and root:FindFirstChild("Inventory")
            if inv then
                for i = 1, 6 do
                    local s = inv:FindFirstChild("Slot" .. i)
                    if s then slots[#slots + 1] = s end
                end
                if #slots > 0 then return slots end
            end
        end
        return slots
    end
    local function slotItemName(slot)
        if slot:IsA("ValueBase") then
            local v = slot.Value
            if typeof(v) == "Instance" then return v.Name end
            return tostring(v or "")
        end
        local a = slot:GetAttribute("Item") or slot:GetAttribute("ItemName") or slot:GetAttribute("Name")
        if a then return tostring(a) end
        local c = slot:GetChildren()[1]
        return c and c.Name or ""
    end
    local function useSlot(slot)
        local ev, c = getEvent("ItemEvent"), getChar()
        if not (ev and c) then return end
        task.spawn(function() pcall(function() ev:InvokeServer(c, slot) end) end)
    end
    local function healthFrac()
        for _, root in ipairs({ myModel(), LP.Character, LP }) do
            if root then
                local h = root:GetAttribute("Health") or root:GetAttribute("Hearts")
                local m = root:GetAttribute("MaxHealth") or root:GetAttribute("MaxHearts")
                if type(h) == "number" and type(m) == "number" and m > 0 then return h / m end
            end
        end
        local hum = getHum()
        if hum and hum.MaxHealth > 0 then return hum.Health / hum.MaxHealth end
        return 1
    end

    local lastHeal, lastCandy = 0, 0
    Loop("Ítems", 0.4, function()
        if not (Flags.AutoHeal or Flags.AutoCandy) then return end
        local slots = inventorySlots()
        if Flags.AutoHeal and os.clock() - lastHeal > 3 and healthFrac() * 100 <= (Flags.HealAt or 50) then
            for _, s in ipairs(slots) do
                local n = string.lower(slotItemName(s))
                if string.find(n, "bandage", 1, true) or string.find(n, "health", 1, true) or string.find(n, "med", 1, true) then
                    useSlot(s)
                    lastHeal = os.clock()
                    Notify("Curación", "Usado: " .. slotItemName(s), 2, "ok")
                    break
                end
            end
        end
        if Flags.AutoCandy and os.clock() - lastCandy > 2 then
            for _, s in ipairs(slots) do
                local info = ItemInfo[slotItemName(s)]
                if info and info[2] == "Caramelos" then
                    useSlot(s)
                    lastCandy = os.clock()
                    break
                end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Mundo: iluminación, cámara, rayos X, mapa
-- ════════════════════════════════════════════════════════════════
local xrayApply, xrayRestore
do
    local LightBackup
    local function backupLighting()
        if LightBackup then return end
        LightBackup = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows, ExposureCompensation = Lighting.ExposureCompensation,
            Effects = {},
        }
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") then
                LightBackup.Effects[e] = { Density = e.Density, Haze = e.Haze }
            elseif e:IsA("PostEffect") then
                LightBackup.Effects[e] = { Enabled = e.Enabled }
            end
        end
    end
    local function restoreLighting()
        if not LightBackup then return end
        for k, v in pairs(LightBackup) do
            if k ~= "Effects" then pcall(function() Lighting[k] = v end) end
        end
        for e, props in pairs(LightBackup.Effects) do
            if e.Parent then for k, v in pairs(props) do pcall(function() e[k] = v end) end end
        end
        LightBackup = nil
    end
    Hub.RestoreLighting = restoreLighting

    local lightState = ""
    Loop("Iluminación", 0.25, function()
        local st = (Flags.FullBright and "B" or "") .. (Flags.NoFog and "F" or "")
        if st ~= lightState then
            restoreLighting()
            lightState = st
        end
        if st == "" then return end
        backupLighting()
        if Flags.FullBright then
            Lighting.Ambient = Color3.fromRGB(190, 190, 205)
            Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 205)
            Lighting.Brightness = Flags.Brightness or 2
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0.15
            for _, e in ipairs(Lighting:GetChildren()) do
                if e:IsA("ColorCorrectionEffect") or e:IsA("BlurEffect") then
                    if not LightBackup.Effects[e] then LightBackup.Effects[e] = { Enabled = e.Enabled } end
                    e.Enabled = false
                end
            end
        end
        if Flags.NoFog then
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 1e6
            for _, e in ipairs(Lighting:GetChildren()) do
                if e:IsA("Atmosphere") then
                    if not LightBackup.Effects[e] then LightBackup.Effects[e] = { Density = e.Density, Haze = e.Haze } end
                    e.Density = 0
                    e.Haze = 0
                end
            end
        end
    end)

    Connect(RunService.RenderStepped, function()
        if Flags.FOVOn then
            local cam = workspace.CurrentCamera
            if cam then cam.FieldOfView = Flags.FOV or 90 end
        end
    end)

    local ZoomBackup
    function Hub.SetZoom(on)
        if on then
            if not ZoomBackup then ZoomBackup = { LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance, LP.CameraMode } end
            LP.CameraMaxZoomDistance = Flags.MaxZoom or 120
            LP.CameraMinZoomDistance = 0.5
            LP.CameraMode = Enum.CameraMode.Classic
        elseif ZoomBackup then
            LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance, LP.CameraMode = ZoomBackup[1], ZoomBackup[2], ZoomBackup[3]
            ZoomBackup = nil
        end
    end
    Loop("Zoom", 1, function()
        if Flags.UnlockZoom then
            LP.CameraMaxZoomDistance = Flags.MaxZoom or 120
        end
        if Flags.ForceThirdPerson and LP.CameraMode == Enum.CameraMode.LockFirstPerson then
            LP.CameraMode = Enum.CameraMode.Classic
        end
    end)

    local XRayParts = setmetatable({}, { __mode = "k" })
    xrayApply = function()
        local cr = workspace:FindFirstChild("CurrentRoom")
        if not cr then return end
        local keep = {}
        for _, list in ipairs({ World.Generators, World.Monsters, World.Items, World.Capsules }) do
            for _, x in ipairs(list) do keep[x] = true end
        end
        local amount = Flags.XRayAmount or 0.6
        for _, d in ipairs(cr:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency < 0.95 then
                local skip = false
                local a = d.Parent
                while a and a ~= cr do
                    if keep[a] then skip = true; break end
                    a = a.Parent
                end
                if not skip then
                    XRayParts[d] = true
                    d.LocalTransparencyModifier = amount
                end
            end
        end
    end
    xrayRestore = function()
        for p in pairs(XRayParts) do
            if p.Parent then p.LocalTransparencyModifier = 0 end
        end
        XRayParts = setmetatable({}, { __mode = "k" })
    end

    function Hub.RemoveBorders()
        local n = 0
        for _, room in ipairs(World.Rooms) do
            for _, d in ipairs(room:GetDescendants()) do
                if d:IsA("BasePart") and (d.Name == "InvisBorder" or (d.Transparency >= 1 and d.CanCollide and string.find(string.lower(d.Name), "border", 1, true))) then
                    d.CanCollide = false
                    n = n + 1
                end
            end
        end
        return n
    end

    function Hub.PerformanceMode()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                d.Enabled = false
                n = n + 1
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
                n = n + 1
            elseif d:IsA("BasePart") then
                d.Material = Enum.Material.SmoothPlastic
                d.Reflectance = 0
            end
        end
        Lighting.GlobalShadows = false
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        return n
    end

    Hub.OnRoomChanged = function(room)
        Farm.Skip = {}
        World.FreshUntil = os.clock() + 5
        if not room then return end
        Farm.Floors = Farm.Floors + 1
        task.wait(4)
        if not Hub.Running then return end
        if Flags.XRay then xrayApply() end
        if Flags.RemoveBordersAuto then Hub.RemoveBorders() end
        if Flags.FloorSummary ~= false and World.RoomInst == room then
            local names = {}
            for _, m in ipairs(World.Monsters) do
                names[#names + 1] = twistedDisplay(m.Name)
                if #names >= 6 then break end
            end
            local done, total = machineCounts()
            Notify("Nuevo piso · " .. World.RoomName,
                string.format("%d máquinas · %d Twisteds%s", total - done, #World.Monsters,
                    (#names > 0) and (": " .. table.concat(names, ", ")) or ""), 6)
        end
    end
end

-- ════════════════════════════════════════════════════════════════
--  Teletransportes
-- ════════════════════════════════════════════════════════════════
local Teleports = {}
do
    function Teleports.Elevator()
        local el = realElevator()
        if not el then return false, "No se encontró el elevador" end
        return moveTo(standInside(el), "Teleport")
    end
    function Teleports.NearestMachine(onlyPending)
        local best, bd
        for _, g in ipairs(World.Generators) do
            if not onlyPending or not genInfo(g).completed then
                local d = distTo(g)
                if not bd or d < bd then best, bd = g, d end
            end
        end
        if not best then return false, "No hay máquinas" end
        return moveTo(standNear(best), "Teleport")
    end
    function Teleports.Nearest(list, label)
        local best, bd
        for _, x in ipairs(list) do
            local d = distTo(x)
            if not bd or d < bd then best, bd = x, d end
        end
        local p = best and posOf(best)
        if not p then return false, "No hay " .. label end
        return moveTo(CFrame.new(p + Vector3.new(0, 3, 0)), "Teleport")
    end
    function Teleports.Safe()
        local cf = getSafeCFrame()
        if not cf then return false, "Sin zona segura" end
        return moveTo(cf, "Teleport")
    end
    function Teleports.Named(path)
        local o = workspace
        for _, n in ipairs(path) do
            o = o and o:FindFirstChild(n)
        end
        if not o then return false, "No disponible aquí (¿estás en el lobby?)" end
        local p = modelPart(o)
        if not p then return false, "Sin posición" end
        return moveTo(CFrame.new(p.Position + Vector3.new(0, 4, 0)), "Teleport")
    end
    Hub.Teleports = Teleports
end

-- ════════════════════════════════════════════════════════════════
--  Servidor + re-ejecución
-- ════════════════════════════════════════════════════════════════
do
    function Hub.Rejoin()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LP)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end
    end
    function Hub.ServerHop()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok then return false, "No se pudo obtener la lista de servidores" end
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok2 or not data or not data.data then return false, "Respuesta inválida" end
        local options = {}
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 0) then options[#options + 1] = s.id end
        end
        if #options == 0 then return false, "No hay servidores libres" end
        TeleportService:TeleportToPlaceInstance(game.PlaceId, options[math.random(1, #options)], LP)
        return true
    end

    local queued = false
    Connect(LP.OnTeleport, function(state)
        if queued or Flags.ReExecute == false then return end
        if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
            local url = (type(Flags.ScriptURL) == "string" and Flags.ScriptURL ~= "") and Flags.ScriptURL or SCRIPT_URL
            if Env.queue and url ~= "" then
                queued = true
                pcall(Env.queue, 'loadstring(game:HttpGet("' .. url .. '"))()')
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
--  Escáner / diagnóstico
-- ════════════════════════════════════════════════════════════════
do
    local function dumpTree(inst, depth, maxDepth, lines, maxLines)
        if not inst or #lines >= maxLines then return end
        local extra = ""
        if inst:IsA("ValueBase") then
            local ok, v = pcall(function() return inst.Value end)
            extra = " = " .. (ok and tostring(v) or "?")
        end
        local at = {}
        for k, v in pairs(inst:GetAttributes()) do at[#at + 1] = k .. "=" .. tostring(v) end
        if #at > 0 then extra = extra .. "  {" .. table.concat(at, ", ") .. "}" end
        if inst:IsA("ProximityPrompt") then
            extra = extra .. string.format("  (Action=%s Hold=%.2f Dist=%d Enabled=%s)", inst.ActionText, inst.HoldDuration,
                math.floor(inst.MaxActivationDistance), tostring(inst.Enabled))
        end
        lines[#lines + 1] = string.rep("  ", depth) .. inst.Name .. " [" .. inst.ClassName .. "]" .. extra
        if depth < maxDepth then
            local ch = inst:GetChildren()
            local shownN = 0
            for _, c in ipairs(ch) do
                shownN = shownN + 1
                if shownN > 40 then
                    lines[#lines + 1] = string.rep("  ", depth + 1) .. "… (" .. (#ch - 40) .. " más)"
                    break
                end
                dumpTree(c, depth + 1, maxDepth, lines, maxLines)
            end
        end
    end

    function Hub.BuildReport()
        local L = {}
        local function H(t) L[#L + 1] = ""; L[#L + 1] = "==== " .. t .. " ====" end
        L[#L + 1] = "Astral DW report  ·  PlaceId " .. game.PlaceId .. "  ·  " .. os.date("%Y-%m-%d %H:%M")
        H("workspace (hijos)")
        local names = {}
        for _, c in ipairs(workspace:GetChildren()) do names[#names + 1] = c.Name .. "[" .. c.ClassName .. "]" end
        L[#L + 1] = table.concat(names, ", ")
        H("CurrentRoom (profundidad 2)")
        dumpTree(workspace:FindFirstChild("CurrentRoom"), 0, 2, L, 900)
        H("Primera máquina (completa)")
        dumpTree(World.Generators[1], 0, 5, L, 900)
        H("Primer Twisted")
        dumpTree(World.Monsters[1], 0, 1, L, 900)
        H("Ítems (nombres únicos)")
        local seen, list = {}, {}
        for _, it in ipairs(World.Items) do if not seen[it.Name] then seen[it.Name] = true; list[#list + 1] = it.Name end end
        L[#L + 1] = table.concat(list, ", ")
        H("workspace.Info")
        dumpTree(workspace:FindFirstChild("Info"), 0, 1, L, 900)
        H("workspace.Elevators")
        dumpTree(workspace:FindFirstChild("Elevators"), 0, 1, L, 900)
        H("ReplicatedStorage.Events")
        dumpTree(ReplicatedStorage:FindFirstChild("Events"), 0, 1, L, 900)
        H("Mi modelo (InGamePlayers)")
        dumpTree(myModel(), 0, 2, L, 900)
        H("Personaje: atributos y valores")
        local c = LP.Character
        if c then
            local at = {}
            for k, v in pairs(c:GetAttributes()) do at[#at + 1] = k .. "=" .. tostring(v) end
            L[#L + 1] = "Char attrs: " .. table.concat(at, ", ")
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("ValueBase") or d.Name == "Inventory" then dumpTree(d, 1, 1, L, 900) end
            end
        end
        local pat = {}
        for k, v in pairs(LP:GetAttributes()) do pat[#pat + 1] = k .. "=" .. tostring(v) end
        L[#L + 1] = "Player attrs: " .. table.concat(pat, ", ")
        H("PlayerGui (skill check)")
        for root in pairs(SC.roots) do
            if root.Parent then dumpTree(root, 0, 3, L, 900) end
        end
        local guis = {}
        for _, g in ipairs(PlayerGui:GetChildren()) do guis[#guis + 1] = g.Name end
        L[#L + 1] = "ScreenGuis: " .. table.concat(guis, ", ")
        return table.concat(L, "\n")
    end
end

-- ════════════════════════════════════════════════════════════════
--  Configuración
-- ════════════════════════════════════════════════════════════════
do
    local CFG_DIR, CFG_FILE = "AstralHub", "AstralHub/DandysWorld.json"
    local NoSave = { Fly = true }
    function Hub.SaveConfig(silent)
        if not (Env.writefile and Env.makefolder) then
            if not silent then Notify("Configuración", "Tu executor no soporta writefile", 3, "bad") end
            return false
        end
        pcall(function() if not (Env.isfolder and Env.isfolder(CFG_DIR)) then Env.makefolder(CFG_DIR) end end)
        local data = {}
        for k, v in pairs(Flags) do
            local t = type(v)
            if not NoSave[k] and (t == "boolean" or t == "number" or t == "string" or t == "table") then data[k] = v end
        end
        local ok = pcall(function() Env.writefile(CFG_FILE, HttpService:JSONEncode(data)) end)
        if not silent then Notify("Configuración", ok and "Guardada ✓" or "No se pudo guardar", 3, ok and "ok" or "bad") end
        Hub.ClearDirty()
        return ok
    end
    function Hub.LoadConfig(silent)
        if not (Env.readfile and Env.isfile) then return false end
        local okF, exists = pcall(Env.isfile, CFG_FILE)
        if not okF or not exists then
            if not silent then Notify("Configuración", "No hay configuración guardada", 3, "warn") end
            return false
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(Env.readfile(CFG_FILE)) end)
        if not ok or type(data) ~= "table" then
            if not silent then Notify("Configuración", "Archivo dañado", 3, "bad") end
            return false
        end
        for k, v in pairs(data) do
            local set = Hub.Setters[k]
            if set and not NoSave[k] then pcall(set, v) end
        end
        Hub.ClearDirty()
        if not silent then Notify("Configuración", "Cargada ✓", 3, "ok") end
        return true
    end
end

-- ════════════════════════════════════════════════════════════════
--  Descargar
-- ════════════════════════════════════════════════════════════════
function Hub.Unload()
    if not Hub.Running then return end
    Hub.Running = false
    Move.Abort = true
    for _, c in ipairs(Hub.Connections) do pcall(function() c:Disconnect() end) end
    pcall(Hub.ESPCleanup)
    pcall(Hub.RestoreLighting)
    pcall(xrayRestore)
    pcall(Hub.SetZoom, false)
    pcall(Hub.DestroySafePart)
    pcall(function() Hub.AlertSound:Destroy() end)
    pcall(function()
        local hum = getHum()
        if hum and Hub.FlyOn() then hum.PlatformStand = false end
    end)
    pcall(function() Gui:Destroy() end)
    if G.AstralDW == Hub then G.AstralDW = nil end
end

-- ════════════════════════════════════════════════════════════════
--  Bucles principales
-- ════════════════════════════════════════════════════════════════
Loop("Escaneo", 0.4, Hub.ScanFast)
Loop("Escaneo profundo", 1.5, Hub.ScanDeep)
Loop("ESP", 0.1, Hub.ESPTick)
Loop("Radar", 0.05, Hub.RadarTick)
Loop("Alertas", 0.1, Hub.AlertTick)
Loop("HUD", 0.5, Hub.HUDTick)

-- ════════════════════════════════════════════════════════════════
--  Construcción de la interfaz
-- ════════════════════════════════════════════════════════════════
local function result(ok, msg)
    if ok == false then Notify("Teletransporte", msg or "No disponible", 3, "bad") end
end

local function setFlags(list, value)
    for _, f in ipairs(list) do
        local s = Hub.Setters[f]
        if s then s(value) end
    end
end

-- ─────────────────────────────── Inicio
local Home
do
Home = Window:Tab("Inicio", "✦", "Panel en vivo de tu partida")
local Hero = Home:Banner("Bienvenido, " .. LP.DisplayName,
    "Astral está listo. Pulsa <b>RightShift</b> para ocultar/mostrar. Usa las acciones rápidas o explora cada categoría.")

local HS = Home:Section("Estado del piso", 1)
local stRoom    = HS:Stat("Sala", "—")
local stMach    = HS:Stat("Máquinas", "—")
local stTw      = HS:Stat("Twisteds", "—")
local stNear    = HS:Stat("Más cercano", "—")
local stItems   = HS:Stat("Cápsulas · ítems", "—")
local stPanic   = HS:Stat("Pánico", "—")
local stFarm    = HS:Stat("Autofarm", "—")
local stSession = HS:Stat("Sesión", "—")
local stPicked  = HS:Stat("Recogidos", "—")

local QA = Home:Section("Acciones rápidas", 2)
QA:Button({ Name = "⚡  Modo farm completo", Desc = "Máquinas + skill check + huida + elevador + cápsulas",
    Callback = function()
        setFlags({ "AutoFarm", "AutoSkill", "FarmSafety", "FarmCollect", "FarmEvent", "AutoElevator", "InfStamina",
            "ESPTwisted", "ESPMachines", "Radar", "AutoSquirm" }, true)
        Notify("Modo farm completo", "Todo activado. ¡A farmear!", 4, "ok")
    end })
QA:Button({ Name = "◉  Visión total", Desc = "ESP completo, radar, alertas y FullBright",
    Callback = function()
        setFlags({ "ESPTwisted", "ESPMachines", "ESPItems", "ESPCapsules", "ESPPlayers", "ESPElevator",
            "ESPFakeElevator", "Radar", "ProximityAlert", "FullBright", "NoFog", "OffscreenArrows" }, true)
        Notify("Visión total", "Lo ves todo.", 3, "ok")
    end })
QA:Button({ Name = "■  Detener automatizaciones", Desc = "Apaga farm, recolección, elevador y esquiva",
    Callback = function()
        setFlags({ "AutoFarm", "AutoCollect", "AutoCapsules", "AutoEvent", "AutoIchor", "ItemAura", "AutoElevator",
            "AutoDodge", "AutoAbility" }, false)
        Notify("Detenido", "Automatizaciones apagadas.", 3, "warn")
    end })

local InfoSec = Home:Section("Datos del juego (Info)", 2)
local infoLabel = InfoSec:Label("Esperando datos…")

local function fmtTime(s)
    s = math.floor(s)
    return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
end

Loop("Panel", 0.5, function()
    if not Hub.Visible or Window.Current ~= Home then return end
    stRoom:Set(World.RoomName)
    local done, total = machineCounts()
    stMach:Set(total > 0 and string.format("%d / %d", done, total) or "—", (total > 0 and done >= total) and Theme.Good or Theme.Text)
    stTw:Set(tostring(#World.Monsters), #World.Monsters > 0 and Theme.Warn or Theme.Text)
    local hrp = getHRP()
    local tw, d = nearestTwisted(hrp and hrp.Position)
    if tw then
        stNear:Set(twistedDisplay(tw.Name) .. " · " .. fmtDist(d), d < (Flags.AlertRadius or 35) and Theme.Bad or twistedColor(tw.Name))
    else
        stNear:Set("Ninguno", Theme.Good)
    end
    stItems:Set(string.format("%d · %d", #World.Capsules, #World.Items))
    stPanic:Set(World.Panic and "SÍ — ve al elevador" or "No", World.Panic and Theme.Bad or Theme.Good)
    stFarm:Set(Farm.Status, Flags.AutoFarm and Theme.Accent or Theme.Sub)
    local hours = math.max((os.clock() - Hub.StartTime) / 3600, 1 / 60)
    stSession:Set(string.format("%s · %d máq · %d pisos · %d/h", fmtTime(os.clock() - Hub.StartTime), Farm.Machines, Farm.Floors,
        math.floor(Farm.Machines / hours + 0.5)))
    stPicked:Set(string.format("%d ítems · %d del evento", Farm.Picked or 0, Farm.EventPicked or 0))
    local keys = {}
    for k in pairs(World.Info) do keys[#keys + 1] = k end
    table.sort(keys)
    local lines = {}
    for _, k in ipairs(keys) do
        lines[#lines + 1] = string.format('<font color="#%s">%s</font>  %s', Theme.Sub:ToHex(), k, tostring(World.Info[k]))
        if #lines >= 14 then break end
    end
    infoLabel:Set(#lines > 0 and table.concat(lines, "\n") or "No hay carpeta <i>workspace.Info</i> (¿lobby?)")
end)

local About = Home:Section("Atajos", 1)
About:Label("<b>RightShift</b> · mostrar/ocultar\n<b>Ctrl + clic</b> · teletransporte (si lo activas)\n<b>⌕ Buscar</b> · filtra funciones de la pestaña actual\nEl orbe ✦ flotante reabre la ventana.")

end

-- ─────────────────────────────── Farm
do
local FarmTab = Window:Tab("Farm", "⚡", "Autofarm de máquinas, skill checks, elevador y recolección")

local FM = FarmTab:Section("Máquinas", 1)
local farmStatus = FM:Label("Estado: Inactivo")
local FarmT = FM:Toggle({ Name = "Autofarm de máquinas", Desc = "TP a cada máquina segura y la completa", Flag = "AutoFarm",
    Callback = function(v)
        if not v then Move.Abort = true end
        Notify("Autofarm", v and "Activado" or "Desactivado", 2, v and "ok" or "warn")
    end })
FM:Dropdown({ Name = "Prioridad", Options = { "Inteligente", "Más cercana" }, Default = "Inteligente", Flag = "FarmMode" })
FM:Keybind({ Name = "Tecla autofarm", Default = Enum.KeyCode.G, Flag = "FarmKey",
    Callback = function() FarmT:Set(not FarmT:Get()) end })
FM:Toggle({ Name = "Huir de Twisteds", Desc = "Cambia a otra máquina segura o escapa", Flag = "FarmSafety", Default = true })
FM:Slider({ Name = "Radio de peligro", Min = 10, Max = 80, Default = 30, Suffix = " st", Flag = "SafetyRadius" })
FM:Dropdown({ Name = "Si no hay máquina segura", Options = { "Plataforma (TP)", "Alejarse (tween)" }, Default = "Plataforma (TP)", Flag = "EscapeMode" })
FM:Dropdown({ Name = "Máquinas Dúo", Options = { "Si hay compañero", "Siempre", "Nunca" }, Default = "Si hay compañero", Flag = "DuoMode" })
FM:Toggle({ Name = "Evitar máquinas ocupadas", Flag = "FarmSkipBusy", Default = true })
FM:Toggle({ Name = "Recoger ítems y cápsulas", Desc = "Por TP, usando las categorías de Recolección", Flag = "FarmCollect", Default = true })
FM:Toggle({ Name = "Recoger objetos del evento", Desc = "Calabazas, cartas, DandyCorn…", Flag = "FarmEvent", Default = true })
FM:Slider({ Name = "Tiempo máximo por máquina", Min = 30, Max = 300, Default = 150, Suffix = " s", Flag = "FarmTimeout" })
FM:Toggle({ Name = "Detectar fin por el prompt", Desc = "Si el juego no expone el progreso", Flag = "PromptHeuristic", Default = true })
FM:Toggle({ Name = "Avisar al completar", Flag = "NotifyMachine", Default = true })

Loop("Estado farm", 0.3, function()
    if Hub.Visible and Window.Current == FarmTab then
        farmStatus:Set("Estado: <b>" .. Farm.Status .. "</b>")
    end
end)

local MV = FarmTab:Section("Movimiento", 1)
MV:Dropdown({ Name = "Modo de viaje", Options = { "Teleport (rápido)", "Tween (seguro)" }, Default = "Teleport (rápido)", Flag = "MoveMode" })
MV:Slider({ Name = "Velocidad del tween", Min = 20, Max = 150, Default = 55, Suffix = " st/s", Flag = "TweenSpeed" })
MV:Label("Teleport = casi instantáneo. Tween = más discreto ante el anticheat.")
MV:Keybind({ Name = "Tecla de pánico (TP seguro)", Default = Enum.KeyCode.X, Flag = "PanicKey",
    Callback = function()
        local cf = getSafeCFrame("Plataforma")
        if cf then moveTo(cf, "Teleport (rápido)"); Notify("Pánico", "Teletransportado a la zona segura", 2, "warn") end
    end })

local SK = FarmTab:Section("Skill checks", 2)
SK:Toggle({ Name = "Auto skill check", Desc = "Pulsa justo cuando el puntero está en la zona", Flag = "AutoSkill" })
SK:Dropdown({ Name = "Entrada", Options = { "Auto", "Espacio", "E", "Clic", "Botón (señal)" }, Default = "Auto", Flag = "SCInput" })
SK:Slider({ Name = "Tolerancia (rotación)", Min = 2, Max = 30, Default = 10, Suffix = "°", Flag = "SCTolerance" })
SK:Slider({ Name = "Desfase (rotación)", Min = -180, Max = 180, Default = 0, Suffix = "°", Flag = "SCOffset" })
SK:Slider({ Name = "Margen (barra)", Min = 0, Max = 45, Default = 15, Suffix = "%", Flag = "SCMargin" })
SK:Toggle({ Name = "Éxito forzado (experimental)", Desc = "Reescribe fallos en el remote del skill check", Flag = "SCForce",
    Callback = function(v)
        if v and not installHook() then Notify("Éxito forzado", "Tu executor no soporta hookmetamethod", 4, "bad") end
    end })
SK:Toggle({ Name = "Eliminar skill checks", Desc = "Alternativa: borra la interfaz al aparecer", Flag = "SCRemove" })

local EL = FarmTab:Section("Elevador", 2)
EL:Toggle({ Name = "Auto elevador en pánico", Desc = "Entra al elevador REAL (ignora el falso)", Flag = "AutoElevator" })
EL:Toggle({ Name = "Ir también al completar", Desc = "Aunque no haya pánico todavía", Flag = "ElevatorWhenDone" })
EL:Slider({ Name = "Retraso tras pánico", Min = 0, Max = 20, Default = 0, Suffix = " s", Flag = "ElevatorDelay" })
EL:Dropdown({ Name = "Viaje al elevador", Options = { "Teleport (rápido)", "Tween (seguro)" }, Default = "Teleport (rápido)", Flag = "ElevatorMove" })

local RC = FarmTab:Section("Recolección", 2)
RC:Toggle({ Name = "Auto recoger ítems", Flag = "AutoCollect" })
RC:Dropdown({ Name = "Categorías", Options = ItemCategories, Multi = true, Flag = "CollectCats",
    Default = { "Cápsulas", "Curación", "Caramelos", "Utilidad", "Evento" } })
RC:Toggle({ Name = "Auto cápsulas de investigación", Flag = "AutoCapsules" })
RC:Toggle({ Name = "Auto charcos de Ichor", Flag = "AutoIchor" })
RC:Toggle({ Name = "Aura de recolección", Desc = "Recoge lo cercano sin moverte", Flag = "ItemAura" })
RC:Slider({ Name = "Rango del aura", Min = 5, Max = 25, Default = 12, Suffix = " st", Flag = "AuraRange" })
RC:Toggle({ Name = "Volver a tu posición", Flag = "CollectReturn", Default = true })
RC:Slider({ Name = "Pausa entre ítems", Min = 0.1, Max = 1.5, Step = 0.05, Default = 0.15, Suffix = " s", Flag = "CollectDelay" })
RC:Toggle({ Name = "Prompts instantáneos", Desc = "Interacciones sin mantener E", Flag = "InstantPrompts" })

end

-- ─────────────────────────────── Visuales
do
local Vis = Window:Tab("Visuales", "◉", "ESP, radar astral, alertas e iluminación")

local ES = Vis:Section("ESP", 1)
ES:Toggle({ Name = "Twisteds", Desc = "Rareza, distancia y si te persiguen", Flag = "ESPTwisted" })
ES:Toggle({ Name = "Máquinas", Desc = "Progreso y estado en color", Flag = "ESPMachines" })
ES:Toggle({ Name = "Ocultar máquinas completadas", Flag = "ESPHideDone" })
ES:Toggle({ Name = "Ítems", Flag = "ESPItems" })
ES:Dropdown({ Name = "Filtrar ítems", Options = ItemCategories, Multi = true, Flag = "ESPItemCats", Default = ItemCategories })
ES:Toggle({ Name = "Chams en ítems", Desc = "Usa resaltado (máx. 30 en total)", Flag = "ESPItemChams",
    Callback = function() Hub.ESPRebuild() end })
ES:Toggle({ Name = "Cápsulas de investigación", Flag = "ESPCapsules" })
ES:Toggle({ Name = "Jugadores", Desc = "Nombre, Toon y vida", Flag = "ESPPlayers" })
ES:Toggle({ Name = "Elevador real", Flag = "ESPElevator" })
ES:Toggle({ Name = "Elevador falso", Desc = "Marcado en rojo", Flag = "ESPFakeElevator" })
ES:Toggle({ Name = "Charcos de Ichor", Flag = "ESPIchor" })

local ESt = Vis:Section("Estilo del ESP", 1)
ESt:Toggle({ Name = "Chams (resaltado)", Flag = "ESPChams", Default = true, Callback = function() Hub.ESPRebuild() end })
ESt:Toggle({ Name = "Mostrar distancia", Flag = "ESPDistance", Default = true })
ESt:Slider({ Name = "Opacidad del relleno", Min = 0, Max = 1, Step = 0.05, Default = 0.72, Flag = "ESPFill" })
ESt:Slider({ Name = "Tamaño del texto", Min = 9, Max = 18, Default = 13, Flag = "ESPTextSize", Callback = function() Hub.ESPRebuild() end })
ESt:Slider({ Name = "Distancia máxima", Min = 100, Max = 3000, Step = 50, Default = 1500, Suffix = " st", Flag = "ESPMaxDist" })
ESt:Toggle({ Name = "Trazadores a Twisteds", Flag = "Tracers" })
ESt:Dropdown({ Name = "Origen del trazador", Options = { "Abajo", "Centro", "Ratón" }, Default = "Abajo", Flag = "TracerOrigin" })
ESt:Toggle({ Name = "Flechas fuera de pantalla", Desc = "Indica Twisteds detrás de ti", Flag = "OffscreenArrows" })

local TPanelSec = Vis:Section("Panel táctico", 1)
TPanelSec:Toggle({ Name = "Panel táctico", Desc = "Lista en vivo de Twisteds y máquinas (arrastrable)", Flag = "TacticalPanel" })
do
    local Panel = New("Frame", { Parent = Gui, Position = UDim2.new(0, 16, 0.5, -130), Size = UDim2.fromOffset(240, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.12, Visible = false })
    Corner(Panel, 12)
    AccentGradient(Stroke(Panel, Color3.new(1, 1, 1), 1.2, 0.2), 45)
    Padding(Panel, 8, 10, 10, 10)
    List(Panel, 4)
    local head = New("Frame", { Parent = Panel, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 0 })
    LogoImage({ Parent = head, Size = UDim2.fromOffset(24, 24) }, 14)
    local ht = Txt({ Parent = head, Text = "PANEL TÁCTICO", Font = F.Black, TextSize = 12, Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -30, 1, 0), TextColor3 = Color3.new(1, 1, 1) })
    AccentGradient(ht, 0)
    local body = Txt({ Parent = Panel, Text = "", TextSize = 12, RichText = true, TextWrapped = true, LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextYAlignment = Enum.TextYAlignment.Top })
    Draggable(head, Panel)
    Loop("Panel táctico", 0.25, function()
        Panel.Visible = Flags.TacticalPanel == true
        if not Panel.Visible then return end
        local hrp = getHRP()
        local hp = hrp and hrp.Position
        local L = {}
        local tws = {}
        for _, m in ipairs(World.Monsters) do
            local p = posOf(m)
            if p then tws[#tws + 1] = { m = m, d = hp and (p - hp).Magnitude or 0 } end
        end
        table.sort(tws, function(a, b) return a.d < b.d end)
        L[#L + 1] = string.format("<b>☠ Twisteds (%d)</b>", #tws)
        for i = 1, math.min(#tws, 6) do
            local t = tws[i]
            local danger = t.d < (Flags.AlertRadius or 35)
            L[#L + 1] = string.format('<font color="#%s">■</font> %s  <font color="#%s">%s</font>', twistedColor(t.m.Name):ToHex(),
                twistedDisplay(t.m.Name), danger and "ff5670" or "a9a3d6", fmtDist(t.d))
        end
        local done, total = machineCounts()
        L[#L + 1] = string.format("<b>⚙ Máquinas %d/%d</b>", done, total)
        local shownM = 0
        for _, g in ipairs(World.Generators) do
            local gi = genInfo(g)
            if not gi.completed and shownM < 6 then
                shownM = shownM + 1
                local pct = gi.progress and string.format("%d%%", math.floor(gi.progress * 100 + 0.5)) or "—"
                L[#L + 1] = string.format('<font color="#%s">■</font> %s%s · %s · %s', #gi.actives > 0 and "ffcc5c" or "ff805c",
                    gi.duo and "Dúo " or "", pct, fmtDist(distTo(g)), #gi.actives > 0 and "en uso" or "libre")
            end
        end
        if World.Panic then
            L[#L + 1] = '<font color="#ff5670"><b>⚠ PÁNICO — al elevador</b></font>'
        else
            L[#L + 1] = '<font color="#a9a3d6">Estado: ' .. Farm.Status .. "</font>"
        end
        body.Text = table.concat(L, "\n")
    end)
end

local RD = Vis:Section("Radar astral", 2)
RD:Toggle({ Name = "Radar", Desc = "Minimapa giratorio (arrastrable)", Flag = "Radar" })
RD:Slider({ Name = "Alcance", Min = 40, Max = 300, Default = 120, Suffix = " st", Flag = "RadarRange" })
RD:Toggle({ Name = "Mostrar ítems en el radar", Flag = "RadarItems" })

local AL = Vis:Section("Alertas", 2)
AL:Toggle({ Name = "Alerta de proximidad", Desc = "Viñeta roja y aviso en pantalla", Flag = "ProximityAlert" })
AL:Slider({ Name = "Radio de alerta", Min = 10, Max = 80, Default = 35, Suffix = " st", Flag = "AlertRadius" })
AL:Toggle({ Name = "Sonido de alerta", Flag = "AlertSound" })
AL:Toggle({ Name = "Avisar Twisteds nuevos", Flag = "NotifyTwisted" })
AL:Toggle({ Name = "Avisar pánico", Flag = "NotifyPanic", Default = true })
AL:Toggle({ Name = "Resumen de cada piso", Flag = "FloorSummary", Default = true })

local LG = Vis:Section("Iluminación y cámara", 2)
LG:Toggle({ Name = "FullBright", Desc = "También contra los apagones", Flag = "FullBright" })
LG:Slider({ Name = "Brillo", Min = 1, Max = 5, Step = 0.1, Default = 2, Flag = "Brightness" })
LG:Toggle({ Name = "Sin niebla", Flag = "NoFog" })
LG:Toggle({ Name = "FOV personalizado", Flag = "FOVOn" })
LG:Slider({ Name = "FOV", Min = 50, Max = 120, Default = 90, Flag = "FOV" })
LG:Toggle({ Name = "Desbloquear zoom", Flag = "UnlockZoom", Callback = function(v) Hub.SetZoom(v) end })
LG:Slider({ Name = "Zoom máximo", Min = 20, Max = 400, Default = 120, Flag = "MaxZoom" })
LG:Toggle({ Name = "Forzar tercera persona", Flag = "ForceThirdPerson" })
LG:Toggle({ Name = "Rayos X (paredes)", Desc = "Paredes translúcidas, objetos visibles", Flag = "XRay",
    Callback = function(v) if v then xrayApply() else xrayRestore() end end })
LG:Slider({ Name = "Transparencia rayos X", Min = 0.2, Max = 0.9, Step = 0.05, Default = 0.6, Flag = "XRayAmount",
    Callback = function() if Flags.XRay then xrayApply() end end })

end

-- ─────────────────────────────── Jugador
do
local Ply = Window:Tab("Jugador", "☄", "Movimiento, estamina y supervivencia")

local PM = Ply:Section("Movimiento", 1)
PM:Slider({ Name = "Velocidad extra", Min = 0, Max = 60, Default = 0, Suffix = " st/s", Flag = "SpeedBoost" })
PM:Toggle({ Name = "Forzar WalkSpeed", Desc = "Más detectable que la velocidad extra", Flag = "WalkSpeedOn" })
PM:Slider({ Name = "WalkSpeed", Min = 8, Max = 100, Default = 20, Flag = "WalkSpeed" })
local NoclipT = PM:Toggle({ Name = "Noclip", Flag = "Noclip" })
PM:Dropdown({ Name = "Modo noclip", Options = { "Colisiones + fase", "Solo colisiones" }, Default = "Colisiones + fase", Flag = "NoclipMode" })
PM:Keybind({ Name = "Tecla noclip", Default = Enum.KeyCode.N, Flag = "NoclipKey",
    Callback = function() NoclipT:Set(not NoclipT:Get()) end })
local FlyT = PM:Toggle({ Name = "Volar", Desc = "WASD + Espacio / Ctrl", Flag = "Fly", Callback = function(v) Hub.SetFly(v) end })
PM:Slider({ Name = "Velocidad de vuelo", Min = 10, Max = 150, Default = 50, Flag = "FlySpeed" })
PM:Keybind({ Name = "Tecla volar", Default = Enum.KeyCode.F, Flag = "FlyKey",
    Callback = function() FlyT:Set(not FlyT:Get()) end })
PM:Toggle({ Name = "Ctrl + clic para teletransportarte", Flag = "ClickTP" })

local STM = Ply:Section("Estamina", 1)
STM:Toggle({ Name = "Estamina infinita", Desc = "Atributos, valores y tablas del juego", Flag = "InfStamina" })
STM:Button({ Name = "Escaneo profundo (getgc)", Desc = "Busca la estamina en la memoria del cliente",
    Callback = function()
        local n = Hub.ScanStaminaGC()
        Notify("Estamina", n > 0 and (n .. " referencias encontradas ✓") or "No se encontraron tablas (o getgc no disponible)", 4, n > 0 and "ok" or "warn")
    end })

local SV = Ply:Section("Supervivencia", 2)
SV:Toggle({ Name = "Esquiva automática", Desc = "Se aparta cuando un Twisted se acerca", Flag = "AutoDodge" })
SV:Slider({ Name = "Radio de esquiva", Min = 6, Max = 40, Default = 16, Suffix = " st", Flag = "DodgeRadius" })
SV:Slider({ Name = "Distancia de esquiva", Min = 8, Max = 30, Default = 16, Suffix = " st", Flag = "DodgeDistance" })
SV:Toggle({ Name = "Auto escapar de Squirm", Flag = "AutoSquirm" })
SV:Toggle({ Name = "Auto curar", Desc = "Usa vendas/botiquín con poca vida", Flag = "AutoHeal" })
SV:Slider({ Name = "Curar por debajo de", Min = 10, Max = 90, Default = 50, Suffix = "%", Flag = "HealAt" })
SV:Toggle({ Name = "Auto usar caramelos", Flag = "AutoCandy" })

local AB = Ply:Section("Habilidad del Toon", 2)
AB:Toggle({ Name = "Auto habilidad", Flag = "AutoAbility" })
AB:Slider({ Name = "Intervalo", Min = 0.5, Max = 15, Step = 0.5, Default = 2, Suffix = " s", Flag = "AbilityInterval" })
AB:Toggle({ Name = "Apuntarme a mí", Desc = "Para curas/boosts propios (Sprout, Shelly…)", Flag = "AbilitySelf" })
AB:Button({ Name = "Usar habilidad ahora", Callback = function()
    if not useAbility(Flags.AbilitySelf and getChar() or false) then Notify("Habilidad", "AbilityEvent no encontrado", 3, "bad") end
end })

local PR = Ply:Section("Protección", 2)
PR:Toggle({ Name = "Anti-AFK", Flag = "AntiAFK", Default = true })
PR:Toggle({ Name = "Anti-kick (cliente)", Desc = "Bloquea kicks lanzados desde scripts locales", Flag = "AntiKick",
    Callback = function(v)
        if v and not installHook() then Notify("Anti-kick", "Tu executor no soporta hookmetamethod", 4, "bad") end
    end })

end

-- ─────────────────────────────── Teleport
do
local TP = Window:Tab("Teleport", "➤", "Viaja al instante")

local TPm = TP:Section("Partida", 1)
TPm:Button({ Name = "Elevador real", Callback = function() result(Teleports.Elevator()) end })
TPm:Button({ Name = "Máquina pendiente más cercana", Callback = function() result(Teleports.NearestMachine(true)) end })
TPm:Button({ Name = "Máquina más cercana", Callback = function() result(Teleports.NearestMachine(false)) end })
TPm:Button({ Name = "Cápsula más cercana", Callback = function() result(Teleports.Nearest(World.Capsules, "cápsulas")) end })
TPm:Button({ Name = "Ítem más cercano", Callback = function() result(Teleports.Nearest(World.Items, "ítems")) end })
TPm:Button({ Name = "Zona segura", Desc = "Plataforma lejos de los Twisteds", Callback = function() result(Teleports.Safe()) end })

local TPl = TP:Section("Lobby", 2)
TPl:Button({ Name = "Sala de maestría", Callback = function() result(Teleports.Named({ "Bed", "JackInTheBox" })) end })
TPl:Button({ Name = "Invocación de skins", Callback = function() result(Teleports.Named({ "RevealRoom", "CurtainL" })) end })
TPl:Button({ Name = "Spawn", Callback = function() result(Teleports.Named({ "SpawnLocation" })) end })

local TPp = TP:Section("Jugadores", 2)
local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then t[#t + 1] = p.Name end end
    return t
end
local PlayerDD = TPp:Dropdown({ Name = "Jugador", Options = playerNames() })
TPp:Button({ Name = "Actualizar lista", Callback = function() PlayerDD:Refresh(playerNames()) end })
TPp:Button({ Name = "Ir al jugador", Callback = function()
    local name = PlayerDD:Get()
    local p = name and Players:FindFirstChild(name)
    local c = p and p.Character
    local part = c and c:FindFirstChild("HumanoidRootPart")
    if not part then return Notify("Teleport", "Jugador no disponible", 3, "bad") end
    moveTo(part.CFrame * CFrame.new(0, 0, 3), "Teleport")
end })
Connect(Players.PlayerAdded, function() PlayerDD:Refresh(playerNames(), true) end)

local SPc = TP:Section("Espectar", 1)
local function spectate(subject, label)
    if not subject then return Notify("Espectar", "No disponible", 2, "bad") end
    workspace.CurrentCamera.CameraSubject = subject
    Notify("Espectar", label, 2)
end
SPc:Button({ Name = "Espectar jugador seleccionado", Callback = function()
    local name = PlayerDD:Get()
    local p = name and Players:FindFirstChild(name)
    local c = p and p.Character
    spectate(c and (c:FindFirstChildOfClass("Humanoid") or c:FindFirstChild("HumanoidRootPart")), "Viendo a " .. tostring(name))
end })
SPc:Button({ Name = "Espectar Twisted más cercano", Callback = function()
    local h = getHRP()
    local tw = nearestTwisted(h and h.Position)
    spectate(tw and (tw:FindFirstChildOfClass("Humanoid") or modelPart(tw)), tw and ("Viendo a " .. twistedDisplay(tw.Name)) or "")
end })
SPc:Button({ Name = "Volver a mi personaje", Callback = function()
    spectate(getHum(), "Cámara restaurada")
end })
Connect(Players.PlayerRemoving, function() task.defer(function() PlayerDD:Refresh(playerNames(), true) end) end)

local TPx = TP:Section("Mapa", 1)
TPx:Button({ Name = "Quitar bordes invisibles", Callback = function()
    Notify("Mapa", Hub.RemoveBorders() .. " bordes desactivados", 3, "ok")
end })
TPx:Toggle({ Name = "Quitar bordes en cada piso", Flag = "RemoveBordersAuto" })
TPx:Button({ Name = "Modo rendimiento", Desc = "Quita partículas/texturas (+FPS)", Callback = function()
    Notify("Rendimiento", Hub.PerformanceMode() .. " efectos desactivados", 3, "ok")
end })

end

-- ─────────────────────────────── Evento / novedades
do
local Ev = Window:Tab("Evento", "☾", "Halloween 2026 · Máquinas Dúo · elevador falso · futuras updates")
Ev:Banner("🎃  Halloween 2026", "El evento regresó el 2 de octubre con calabazas, cartas, DandyCorn y puertas de Truco o Trato.")

local HW = Ev:Section("Halloween", 1)
HW:Toggle({ Name = "Auto recoger coleccionables", Desc = "Calabazas, cartas, DandyCorn…", Flag = "AutoEvent" })
HW:Toggle({ Name = "ESP de coleccionables", Flag = "ESPEvent" })
HW:Toggle({ Name = "ESP puertas Truco o Trato", Flag = "ESPDoors" })
HW:Toggle({ Name = "Auto tocar puertas (aura)", Desc = "Requiere el aura de recolección", Flag = "AuraDoors" })
HW:Button({ Name = "Ir a la puerta más cercana", Callback = function() result(Teleports.Nearest(World.Doors, "puertas")) end })
HW:Button({ Name = "Ir al coleccionable más cercano", Callback = function() result(Teleports.Nearest(World.Event, "coleccionables")) end })
HW:Toggle({ Name = "Colorear Twisteds del evento", Desc = "Gourdy, Eclipse, Soulvester, Ribecca", Flag = "EventTwistedColor" })

local DU = Ev:Section("Máquinas Dúo y elevador falso", 1)
DU:Label("Las <b>máquinas Dúo</b> necesitan a dos Toons. El autofarm puede ayudar cuando ya hay alguien en ellas (Farm › Máquinas › Máquinas Dúo).\nEl <b>elevador falso</b> se marca en rojo en el ESP y el auto elevador lo ignora.")
DU:Button({ Name = "Ir al elevador real", Callback = function() result(Teleports.Elevator()) end })

local CU = Ev:Section("ESP personalizado", 2)
CU:Label("Para contenido nuevo: escribe partes de nombres separadas por comas y Astral los marcará (ej.: <i>vault, ink, key</i>).")
CU:Textbox({ Name = "Nombres", Placeholder = "vault, ink", Flag = "CustomPatterns",
    Callback = function(text)
        local t = {}
        for part in string.gmatch(text or "", "[^,]+") do
            local p = string.gsub(part, "^%s+", "")
            p = string.gsub(p, "%s+$", "")
            p = string.lower(p)
            if p ~= "" then t[#t + 1] = p end
        end
        Hub.CustomPatterns = t
    end })
CU:Toggle({ Name = "Activar ESP personalizado", Flag = "ESPCustom" })

local TW = Ev:Section("Twisteds conocidos", 2)
TW:Label('<font color="#ff3852">■</font> Letal: Dandy, Dyle\n<font color="#ffce5c">■</font> Principal: Shelly, Astro, Pebble, Vee, Sprout, Bassie, Bobette, Gourdy\n<font color="#70aaff">■</font> Raro: Gigi, Scraps, Goob, Waxwell, Glisten, Flutter, Eclipse, Cocoa, Coal, Squirm, Blot\n<font color="#6ee88e">■</font> Poco común: Finn, Teagan, Rodger, Razzle & Dazzle, Soulvester, Ginger, Flyte, Connie, Brightney, Toodles\n<font color="#e8e8f5">■</font> Común: Boxten, Poppy, Brusha, Shrimpo, Rudie, Eggson, Ribecca, Yatta, Tisha, Looey, Cosmo')

end

-- ─────────────────────────────── Ajustes
do
local Set = Window:Tab("Ajustes", "⚙", "Interfaz, configuración y servidor")

local UIc = Set:Section("Interfaz", 1)
UIc:Keybind({ Name = "Mostrar / ocultar", Default = Enum.KeyCode.RightShift, Flag = "UIKey",
    Callback = function() task.spawn(Hub.SetVisible, not Hub.Visible) end })
UIc:Dropdown({ Name = "Paleta astral", Options = PaletteNames, Default = "Nebulosa", Flag = "Palette",
    Callback = function(v)
        ApplyPalette(v)
        refreshBorder()
        Window:RefreshTabs()
    end })
UIc:Toggle({ Name = "Cielo animado", Desc = "Estrellas, nebulosas y estrellas fugaces", Flag = "Stars", Default = true,
    Callback = function(v) FX.Visible = v end })
UIc:Slider({ Name = "Escala de la interfaz", Min = 0.7, Max = 1.3, Step = 0.05, Default = 1, Flag = "UIScale",
    Callback = function(v) Hub.BaseScale = v; UIScaleObj.Scale = v end })
UIc:Toggle({ Name = "Orbe al minimizar", Flag = "ShowOrb", Default = true })
UIc:Toggle({ Name = "Notificaciones", Flag = "Notifications", Default = true })
UIc:Toggle({ Name = "HUD de FPS / ping", Flag = "ShowHUD" })
UIc:Toggle({ Name = "Pantalla de carga", Flag = "Splash", Default = true })
UIc:Toggle({ Name = "Logo animado", Flag = "LogoAnim", Default = true })

local CF = Set:Section("Configuración", 1)
CF:Toggle({ Name = "Autoguardado", Desc = "Guarda tus cambios automáticamente", Flag = "AutoSave", Default = true })
CF:Button({ Name = "Guardar ahora", Callback = function() Hub.SaveConfig(false) end })
CF:Button({ Name = "Cargar", Callback = function() Hub.LoadConfig(false) end })
CF:Button({ Name = "Borrar configuración guardada", Callback = function()
    if Env.writefile then
        pcall(function() Env.writefile("AstralHub/DandysWorld.json", "{}") end)
        Notify("Configuración", "Borrada. Se usarán los valores por defecto la próxima vez.", 3, "warn")
    end
end })

local AE = Set:Section("Auto-ejecución", 2)
AE:Toggle({ Name = "Re-ejecutar tras teletransporte", Desc = "Lobby → partida → lobby", Flag = "ReExecute", Default = true })
AE:Textbox({ Name = "URL del script", Placeholder = "https://raw.githubusercontent.com/…", Flag = "ScriptURL",
    Default = SCRIPT_URL, Desc = "Enlace RAW donde subiste este archivo (necesario para re-ejecutar)." })

local SVc = Set:Section("Servidor", 2)
SVc:Button({ Name = "Reconectar", Callback = function() Hub.Rejoin() end })
SVc:Button({ Name = "Cambiar de servidor", Desc = "Úsalo en el lobby", Callback = function()
    local ok, err = Hub.ServerHop()
    if not ok then Notify("Servidor", err or "Error", 3, "bad") end
end })
SVc:Button({ Name = "Copiar JobId", Callback = function()
    if Env.setclip then Env.setclip(game.JobId); Notify("Servidor", "JobId copiado", 2, "ok") end
end })

local SS = Set:Section("Sesión", 2)
SS:Label("Astral v" .. Hub.Version .. " · UI astral propia\nExecutor: " .. (identifyexecutor and select(1, identifyexecutor()) or "desconocido"))
SS:Button({ Name = "Descargar Astral", Desc = "Apaga todo y elimina la interfaz", Callback = function() Hub.Unload() end })

end

-- ─────────────────────────────── Escáner
do
local Scan = Window:Tab("Escáner", "⌕", "Diagnóstico para adaptar Astral si el juego cambia")

local SCs = Scan:Section("Estructura del juego", 1)
SCs:Label("Genera un informe con las carpetas, máquinas, Twisteds, eventos y la interfaz del skill check. Úsalo dentro de una partida.")
SCs:Button({ Name = "Escanear y copiar informe", Callback = function()
    local rep = Hub.BuildReport()
    if Env.setclip then Env.setclip(rep) end
    print(rep)
    Notify("Escáner", "Informe copiado al portapapeles (" .. #rep .. " caracteres) y enviado a la consola (F9).", 5, "ok")
end })

local RL = Scan:Section("Registro de remotes", 1)
RL:Toggle({ Name = "Registrar remotes", Desc = "Guarda FireServer/InvokeServer del juego", Flag = "RemoteLog",
    Callback = function(v)
        if v and not installHook() then Notify("Registro", "Tu executor no soporta hookmetamethod", 4, "bad") end
    end })
RL:Button({ Name = "Copiar registro", Callback = function()
    local n = Hub.CopyRemoteLog()
    Notify("Registro", n .. " llamadas copiadas", 3, "ok")
end })
RL:Button({ Name = "Limpiar registro", Callback = function() Hub.ClearRemoteLog() end })

local SD = Scan:Section("Skill check en vivo", 2)
SD:Toggle({ Name = "Depuración del skill check", Desc = "Muestra lo que detecta Astral", Flag = "SCDebug" })
local scLabel = SD:Label("—")
local SE = Scan:Section("Detección", 2)
local detLabel = SE:Label("—")
Loop("Escáner UI", 0.25, function()
    if not Hub.Visible or Window.Current ~= Scan then return end
    scLabel:Set(SC.debug)
    local roots = 0
    for _ in pairs(SC.roots) do roots = roots + 1 end
    local sv, stt = Hub.StaminaCounts()
    detLabel:Set(string.format("Máquinas: %d\nTwisteds: %d\nÍtems: %d · Cápsulas: %d\nElevadores: %d · Falsos: %d\nEvento: %d · Puertas: %d · Ichor: %d\nInterfaces skill check: %d\nValores de estamina: %d · Tablas: %d\nHook instalado: %s",
        #World.Generators, #World.Monsters, #World.Items, #World.Capsules, #World.Elevators, #World.Fake,
        #World.Event, #World.Doors, #World.Ichor, roots, sv, stt, Hub.HookInstalled and "sí" or "no"))
end)

end

-- ════════════════════════════════════════════════════════════════
--  Arranque final
-- ════════════════════════════════════════════════════════════════
Window:Select(Home)
Hub.LoadConfig(true)
if Flags.CustomPatterns and Flags.CustomPatterns ~= "" and Hub.Setters.CustomPatterns then
    Hub.Setters.CustomPatterns(Flags.CustomPatterns)
end

Loop("Autoguardado", 1, function()
    local d = Hub.DirtyAt()
    if Flags.AutoSave ~= false and d and os.clock() - d > 2 then Hub.SaveConfig(true) end
end)

Connect(RunService.RenderStepped, function(dt)
    local t = os.clock()
    local anim = Flags.LogoAnim ~= false
    if Holder.Visible then
        BorderGrad.Rotation = (BorderGrad.Rotation + dt * 40) % 360
        LogoGrad.Rotation = (LogoGrad.Rotation + dt * 60) % 360
        if anim then
            local k = 44 + math.sin(t * 2.1) * 2
            Hub.TopLogo.Rotation = math.sin(t * 1.3) * 7
            Hub.TopLogo.Size = UDim2.fromOffset(k, k)
            Hub.BgLogo.Rotation = (Hub.BgLogo.Rotation + dt * 5) % 360
        end
    elseif Orb.Visible then
        OrbGrad.Rotation = (OrbGrad.Rotation + dt * 90) % 360
        if anim then Hub.OrbLogo.Rotation = math.sin(t * 1.6) * 10 end
    end
end)

task.spawn(function()
    while Hub.Running do
        task.wait(rng:NextNumber(2.5, 6))
        if Hub.Running and Holder.Visible and Flags.Stars ~= false then pcall(ShootingStar) end
    end
end)

-- Pantalla de carga + animación de entrada (Hub.Start se llama al final del archivo)
Holder.Visible = false
function Hub.Start()
    Hub.ApplyLogo(Hub.LOGO_B64)
    Hub.LOGO_B64 = nil
    local function enter()
        Hub.Visible = true
        Holder.Visible = true
        Orb.Visible = false
        UIScaleObj.Scale = Hub.BaseScale * 0.85
        Tween(UIScaleObj, 0.55, { Scale = Hub.BaseScale }, Enum.EasingStyle.Back)
        Notify("Astral cargado", "Dandy's World · " .. (World.InRun and "partida detectada" or "lobby") .. " · RightShift para ocultar", 5)
        if not Hub.LogoAsset then
            Notify("Logo", "Tu executor no soporta getcustomasset: se usa el icono ✦", 4, "warn")
        end
    end
    if Flags.Splash == false then enter(); return end

    local S = New("Frame", { Parent = Gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg0,
        BackgroundTransparency = 1, ZIndex = 50 })
    local C = New("Frame", { Parent = S, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47),
        Size = UDim2.fromOffset(340, 300), BackgroundTransparency = 1 })
    local LY = 100
    local halo = New("Frame", { Parent = C, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, LY),
        Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6 })
    Corner(halo, "full")
    AccentGradient(halo, 45)
    local ring = New("Frame", { Parent = C, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, LY),
        Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 })
    Corner(ring, "full")
    local ringStroke = Stroke(ring, Color3.new(1, 1, 1), 2, 0)
    local ringGrad = New("UIGradient", { Parent = ringStroke, Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.85),
            NumberSequenceKeypoint.new(1, 0) }) })
    local logo = LogoImage({ Parent = C, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, LY),
        Size = UDim2.fromOffset(10, 10), Rotation = -120, ImageTransparency = 1 }, 70)
    local title = Txt({ Parent = C, Text = "ASTRAL HUB", Font = F.Black, TextSize = 30, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 196), Size = UDim2.fromOffset(340, 34), TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1 })
    AccentGradient(title, 0)
    local sub = Txt({ Parent = C, Text = "Dandy's World  ·  v" .. Hub.Version, Font = F.Med, TextSize = 13,
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 230), Size = UDim2.fromOffset(340, 16),
        TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Sub, TextTransparency = 1 })
    local barBg = New("Frame", { Parent = C, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 258),
        Size = UDim2.fromOffset(220, 4), BackgroundColor3 = Theme.Bg2, BackgroundTransparency = 1 })
    Corner(barBg, "full")
    local bar = New("Frame", { Parent = barBg, Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
    Corner(bar, "full")
    AccentGradient(bar, 0)
    local status = Txt({ Parent = C, Text = "", TextSize = 11, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 270), Size = UDim2.fromOffset(340, 14), TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Theme.Muted, TextTransparency = 1 })

    local spin = RunService.RenderStepped:Connect(function(dt)
        ringGrad.Rotation = (ringGrad.Rotation + dt * 220) % 360
    end)
    Tween(S, 0.4, { BackgroundTransparency = 0.25 })
    Tween(logo, 1.0, { Size = UDim2.fromOffset(150, 150), Rotation = 0, ImageTransparency = 0 }, Enum.EasingStyle.Back)
    Tween(ring, 1.1, { Size = UDim2.fromOffset(196, 196) })
    Tween(halo, 1.4, { Size = UDim2.fromOffset(180, 180), BackgroundTransparency = 0.9 })
    task.wait(0.45)
    Tween(title, 0.5, { TextTransparency = 0 })
    Tween(sub, 0.5, { TextTransparency = 0 })
    Tween(barBg, 0.4, { BackgroundTransparency = 0 })
    Tween(status, 0.4, { TextTransparency = 0 })
    local steps = { "Alineando constelaciones…", "Escaneando el piso…", "Cargando ESP y radar…", "Listo  ✦" }
    for i, st in ipairs(steps) do
        status.Text = st
        Tween(bar, 0.35, { Size = UDim2.fromScale(i / #steps, 1) })
        task.wait(0.38)
    end
    task.wait(0.25)
    Tween(logo, 0.4, { Size = UDim2.fromOffset(210, 210), ImageTransparency = 1, Rotation = 25 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    Tween(ring, 0.4, { Size = UDim2.fromOffset(300, 300) })
    Tween(ringStroke, 0.4, { Transparency = 1 })
    Tween(halo, 0.4, { BackgroundTransparency = 1 })
    for _, l in ipairs({ title, sub, status }) do Tween(l, 0.3, { TextTransparency = 1 }) end
    Tween(barBg, 0.3, { BackgroundTransparency = 1 })
    Tween(bar, 0.3, { BackgroundTransparency = 1 })
    Tween(S, 0.45, { BackgroundTransparency = 1 })
    task.wait(0.3)
    enter()
    task.wait(0.3)
    spin:Disconnect()
    S:Destroy()
end

-- ════════════════════════════════════════════════════════════════
--  Logo de Astral (PNG 200×200 con transparencia, base64) + arranque
-- ════════════════════════════════════════════════════════════════
Hub.LOGO_B64 = "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"
Hub.Start()
