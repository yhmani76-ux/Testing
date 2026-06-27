--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║               ARABY HUB  —  FULL UI v4.0                  ║
    ║                                                           ║
    ║  Splash | Circle Button | Main Window | Sidebar           ║
    ║  Proper Drag | Mobile | X = Destroy All                   ║
    ╚═══════════════════════════════════════════════════════════╝

    Usage:
        local Hub = loadstring(game:HttpGet("YOUR_LINK"))()
        Hub:Init({
            buttonImage = "rbxassetid://YOUR_ASSET_ID",
            windowBg    = "rbxassetid://BG_ASSET_ID",
        })
--]]

local ArabyHub = {}
ArabyHub.__index = ArabyHub

-- ═══════════════════════════════════════
--  Services
-- ═══════════════════════════════════════
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

-- ═══════════════════════════════════════
--  Colors
-- ═══════════════════════════════════════
local C = {
    White       = Color3.fromRGB(255, 255, 255),
    LightGray   = Color3.fromRGB(190, 190, 190),
    MidGray     = Color3.fromRGB(110, 110, 110),
    DarkGray    = Color3.fromRGB(55, 55, 55),
    PanelGray   = Color3.fromRGB(28, 28, 28),
    VeryDark    = Color3.fromRGB(16, 16, 16),
    Accent      = Color3.fromRGB(150, 150, 150),
    Red         = Color3.fromRGB(200, 60, 60),
}

-- ═══════════════════════════════════════
--  Tween Helper
-- ═══════════════════════════════════════
local function tw(obj, props, dur, style, dir, delayTime)
    local info = TweenInfo.new(
        dur or 0.5,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out,
        delayTime or 0
    )
    return TweenService:Create(obj, info, props)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, thickness, color, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Color = color or C.DarkGray
    s.Transparency = transparency or 0.5
    s.Parent = parent
    return s
end

-- ═══════════════════════════════════════
--  Viewport
-- ═══════════════════════════════════════
local function getViewSize()
    local vp = workspace.CurrentCamera.ViewportSize
    return vp.X, vp.Y
end

local function isMobile()
    local w = getViewSize()
    return w < 700 or UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ═══════════════════════════════════════
--  DRAG SYSTEM  (service-level, actually works)
-- ═══════════════════════════════════════
--  Connects to UserInputService so it catches
--  ALL movement even if mouse leaves the button.
--  Returns didDrag flag for click-vs-drag.

local function makeDraggable(frame, handle)
    local DRAG_THRESHOLD = 5

    local isDown     = false
    local didDrag    = false
    local dragInput  = nil
    local startMouse = Vector3.zero
    local startPos   = UDim2.new()

    -- Capture the initial press on the GUI handle
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isDown    = true
            didDrag   = false
            dragInput = input
            startMouse = input.Position
            startPos   = frame.Position
        end
    end)

    -- TRACK MOVEMENT via USER INPUT SERVICE (global level)
    -- This is the fix — btn.InputChanged misses movement.
    -- UIS.InputChanged catches EVERYTHING.
    local moveConn
    moveConn = UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if not isDown then return end
        if input ~= dragInput then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - startMouse

        if not didDrag then
            if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
                didDrag = true
            else
                return
            end
        end

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)

    -- Release
    local endConn
    endConn = UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            isDown    = false
            dragInput = nil
        end
    end)

    return {
        isDragging = function() return didDrag end,
        destroy = function()
            if moveConn then moveConn:Disconnect() end
            if endConn then endConn:Disconnect() end
        end,
    }
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                      SPLASH SCREEN                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local Splash = {
    Text        = "ARABY HUB",
    Font        = Enum.Font.GothamBlack,
    Size        = 82,
    Spacing     = 12,
    WaveSpeed   = 0.35,
    CycleTime   = 1.8,
    FloatAmp    = 6,
    FloatSpeed  = 2.5,
    EnterDelay  = 0.06,
    EnterTime   = 0.5,
    Duration    = 5.0,
    FadeOut     = 0.6,
}

local function lerpColor(a, b, t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end
local function pingPong(t, p)
    local ph = (t%p)/p
    return ph < 0.5 and ph*2 or 2-ph*2
end

function ArabyHub:ShowSplash(onComplete)
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabyHub_Splash"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = C.VeryDark
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = gui
    tw(bg, {BackgroundTransparency=0.02}, 0.4):Play()

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,100)
    container.Position = UDim2.new(0.5,0,0.5,0)
    container.AnchorPoint = Vector2.new(0.5,0.5)
    container.BackgroundTransparency = 1
    container.Parent = gui

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(0,700,0,140)
    glow.Position = UDim2.new(0.5,0,0.5,0)
    glow.AnchorPoint = Vector2.new(0.5,0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://7669168585"
    glow.ImageColor3 = C.MidGray
    glow.ImageTransparency = 1
    glow.ScaleType = Enum.ScaleType.Stretch
    glow.Parent = gui

    -- Build letter labels
    local labels = {}
    local totalW = 0
    for i = 1, #Splash.Text do
        local ch = Splash.Text:sub(i,i)
        if ch == " " then
            local sp = Instance.new("Frame")
            sp.Size = UDim2.new(0, Splash.Spacing*2, 0, 1)
            sp.BackgroundTransparency = 1
            sp.Parent = container
            labels[#labels+1] = {space=true, inst=sp}
            totalW = totalW + Splash.Spacing*2
        else
            local lb = Instance.new("TextLabel")
            lb.BackgroundTransparency = 1
            lb.Text = ch
            lb.Font = Splash.Font
            lb.TextSize = Splash.Size
            lb.TextColor3 = C.White
            lb.TextTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Center
            lb.TextYAlignment = Enum.TextYAlignment.Center
            lb.Size = UDim2.new(0,60,0,90)
            lb.Parent = container
            local w = lb.TextBounds.X
            totalW = totalW + w + Splash.Spacing
            labels[#labels+1] = {space=false, inst=lb, w=w, idx=i}
        end
    end
    local xOff = -totalW/2
    for _,l in ipairs(labels) do
        if l.space then
            l.inst.Position = UDim2.new(0.5, xOff, 0.5, 0)
            l.inst.AnchorPoint = Vector2.new(0, 0.5)
            xOff = xOff + l.inst.Size.X.Offset
        else
            l.inst.Size = UDim2.new(0, l.w, 0, 90)
            l.inst.Position = UDim2.new(0.5, xOff, 0.5, 0)
            l.inst.AnchorPoint = Vector2.new(0, 0.5)
            xOff = xOff + l.w + Splash.Spacing
        end
    end

    -- Entrance
    local li = 0
    for _,l in ipairs(labels) do
        if not l.space then
            li = li+1
            local lb, idx = l.inst, li
            lb.Size = UDim2.new(0, l.w, 0, 0)
            lb.Position = UDim2.new(lb.Position.X.Scale, lb.Position.X.Offset, 0.5, 40)
            task.delay((idx-1)*Splash.EnterDelay, function()
                tw(lb, {Size=UDim2.new(0,l.w,0,90)}, Splash.EnterTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
                tw(lb, {Position=UDim2.new(lb.Position.X.Scale, lb.Position.X.Offset, 0.5, 0)}, Splash.EnterTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
                tw(lb, {TextTransparency=0}, Splash.EnterTime*0.7):Play()
            end)
        end
    end

    local conns = {}
    task.delay((li-1)*Splash.EnterDelay + Splash.EnterTime + 0.1, function()
        -- Color wave
        local t0 = tick()
        conns[#conns+1] = RunService.Heartbeat:Connect(function()
            local el = tick()-t0
            local li2 = 0
            for _,l in ipairs(labels) do
                if not l.space then
                    li2 = li2+1
                    local ph = (el - li2*Splash.WaveSpeed) / Splash.CycleTime
                    local t = pingPong(ph, 1)
                    l.inst.TextColor3 = lerpColor(C.DarkGray, C.White, t)
                    l.inst.TextTransparency = 0.05 + 0.15*math.sin(ph*math.pi*2)
                end
            end
        end)
        -- Float
        local t1 = tick()
        conns[#conns+1] = RunService.Heartbeat:Connect(function()
            local el = tick()-t1
            local li2 = 0
            for _,l in ipairs(labels) do
                if not l.space then
                    li2 = li2+1
                    local off = math.sin((el/Splash.FloatSpeed)*math.pi*2 + li2*0.4)*Splash.FloatAmp
                    l.inst.Position = UDim2.new(l.inst.Position.X.Scale, l.inst.Position.X.Offset, 0.5, off)
                end
            end
        end)
        -- Glow
        tw(glow, {ImageTransparency=0.6}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
        conns[#conns+1] = RunService.Heartbeat:Connect(function()
            local t = tick()-t1
            glow.ImageTransparency = 0.55+0.2*math.sin(t*1.2)
            glow.ImageColor3 = Color3.new((100+60*math.sin(t*0.8))/255, (100+60*math.sin(t*0.8+0.5))/255, (100+60*math.sin(t*0.8+1))/255)
        end)
    end)

    -- Auto dismiss
    task.delay(Splash.Duration, function()
        for _,c in ipairs(conns) do if c.Connected then c:Disconnect() end end
        for _,l in ipairs(labels) do
            if not l.space then
                tw(l.inst, {TextColor3=C.White, TextTransparency=0, Position=UDim2.new(l.inst.Position.X.Scale, l.inst.Position.X.Offset, 0.5, 0)}, 0.2):Play()
                tw(l.inst, {TextTransparency=1}, Splash.FadeOut):Play()
            end
        end
        tw(glow, {ImageTransparency=1}, Splash.FadeOut):Play()
        tw(bg, {BackgroundTransparency=1}, Splash.FadeOut):Play()
        task.delay(Splash.FadeOut+0.15, function()
            if gui.Parent then gui:Destroy() end
            if onComplete then onComplete() end
        end)
    end)
    return gui
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                 CIRCLE TOGGLE BUTTON                         ║
-- ║                                                              ║
-- ║  Properly draggable via UserInputService                     ║
-- ║  Custom image, glow ring, spin ring                          ║
-- ║  Click = toggle UI  |  Drag = move button                   ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:CreateToggleButton(options)
    options = options or {}
    local imageId = options.buttonImage
    local mobile = isMobile()
    local btnSize = mobile and 58 or 52

    -- Root (what gets dragged)
    local root = Instance.new("Frame")
    root.Name = "ToggleRoot"
    root.Size = UDim2.new(0, btnSize+24, 0, btnSize+24)
    root.Position = UDim2.new(0, 24, 0.5, 0)
    root.AnchorPoint = Vector2.new(0, 0.5)
    root.BackgroundTransparency = 1
    root.ZIndex = 100

    -- Soft glow behind
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(0, btnSize+50, 0, btnSize+50)
    glow.Position = UDim2.new(0.5,0,0.5,0)
    glow.AnchorPoint = Vector2.new(0.5,0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://7669168585"
    glow.ImageColor3 = C.MidGray
    glow.ImageTransparency = 0.85
    glow.ScaleType = Enum.ScaleType.Stretch
    glow.ZIndex = 99
    glow.Parent = root

    -- Outer ring (border)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, btnSize+12, 0, btnSize+12)
    ring.Position = UDim2.new(0.5,0,0.5,0)
    ring.AnchorPoint = Vector2.new(0.5,0.5)
    ring.BackgroundColor3 = C.DarkGray
    ring.BackgroundTransparency = 0.25
    ring.BorderSizePixel = 0
    ring.ZIndex = 100
    corner(ring, 50)
    ring.Parent = root

    -- Spinning border ring (UIStroke on a frame)
    local spinRing = Instance.new("Frame")
    spinRing.Size = UDim2.new(0, btnSize+18, 0, btnSize+18)
    spinRing.Position = UDim2.new(0.5,0,0.5,0)
    spinRing.AnchorPoint = Vector2.new(0.5,0.5)
    spinRing.BackgroundTransparency = 1
    spinRing.BorderSizePixel = 0
    spinRing.ZIndex = 101
    corner(spinRing, 50)
    local spinStroke = stroke(spinRing, 2, C.Accent, 0.4)
    spinRing.Parent = root

    -- The actual button
    local btn = Instance.new("ImageButton")
    btn.Name = "CircleButton"
    btn.Size = UDim2.new(0, btnSize, 0, btnSize)
    btn.Position = UDim2.new(0.5,0,0.5,0)
    btn.AnchorPoint = Vector2.new(0.5,0.5)
    btn.BackgroundColor3 = C.PanelGray
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false  -- we handle visuals ourselves
    btn.ZIndex = 102
    corner(btn, btnSize/2)
    stroke(btn, 1, C.DarkGray, 0.3)
    btn.Parent = root

    -- Icon (if image provided)
    if imageId then
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0.55, 0, 0.55, 0)
        icon.Position = UDim2.new(0.5,0,0.5,0)
        icon.AnchorPoint = Vector2.new(0.5,0.5)
        icon.BackgroundTransparency = 1
        icon.Image = imageId
        icon.ImageColor3 = C.White
        icon.ImageTransparency = 0
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = 103
        icon.Parent = btn
    end

    -- ═══ DRAG (service-level) ═══
    local dragState = makeDraggable(root, btn)

    -- ═══ Animations ═══
    task.spawn(function()
        local t0 = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not root.Parent then conn:Disconnect() return end
            local t = tick()-t0
            spinRing.Rotation = t * 50
            glow.ImageTransparency = 0.65 + 0.25*math.sin(t*2)
            local s = 1 + 0.1*math.sin(t*1.5)
            glow.Size = UDim2.new(0, (btnSize+50)*s, 0, (btnSize+50)*s)
        end)
    end)

    -- Hover
    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3=C.DarkGray}, 0.2):Play()
        tw(ring, {BackgroundTransparency=0.05}, 0.2):Play()
        tw(spinStroke, {Transparency=0.1}, 0.2):Play()
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3=C.PanelGray}, 0.2):Play()
        tw(ring, {BackgroundTransparency=0.25}, 0.2):Play()
        tw(spinStroke, {Transparency=0.4}, 0.2):Play()
    end)

    -- Click bounce (only if not dragging)
    btn.MouseButton1Click:Connect(function()
        if dragState.isDragging() then return end
        tw(btn, {Size=UDim2.new(0,btnSize-6,0,btnSize-6)}, 0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
        task.delay(0.08, function()
            tw(btn, {Size=UDim2.new(0,btnSize,0,btnSize)}, 0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out):Play()
        end)
    end)

    return root, btn, dragState
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                      MAIN WINDOW                              ║
-- ║                                                              ║
-- ║  Circle → rectangle open animation                           ║
-- ║  Sidebar with tabs  |  Custom BG  |  X = DESTROY ALL        ║
-- ║  Draggable title bar  |  Mobile responsive                  ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:CreateMainWindow(options, guiRef)
    options = options or {}
    local bgImage = options.windowBg
    local mobile = isMobile()
    local vpW, vpH = getViewSize()
    local winW = math.min(mobile and vpW*0.94 or 440, 520)
    local winH = math.min(mobile and vpH*0.78 or 340, 400)
    local titleH = mobile and 42 or 38
    local sideW = mobile and 0 or 110  -- sidebar width (0 on mobile = no sidebar, tabs go horizontal)

    -- ═══ Main Frame ═══
    local main = Instance.new("Frame")
    main.Name = "ArabyHubWindow"
    main.Size = UDim2.new(0,0,0,0)
    main.Position = UDim2.new(0.5,0,0.5,0)
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.BackgroundColor3 = C.PanelGray
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Visible = false
    main.ZIndex = 50
    local mainCorner = corner(main, 14)
    mainCorner.CornerRadius = UDim.new(0.5, 0)

    -- BG image
    if bgImage then
        local bg = Instance.new("ImageLabel")
        bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundTransparency = 1
        bg.Image = bgImage
        bg.ImageTransparency = 0.4
        bg.ScaleType = Enum.ScaleType.Stretch
        bg.ZIndex = 0
        bg.Parent = main
    end

    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = C.VeryDark
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = main

    -- ═══ Title Bar ═══
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, titleH)
    titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    titleBar.BackgroundTransparency = 0.15
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 10
    titleBar.Parent = main

    -- Title bar bottom line
    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1,0,0,1)
    titleLine.Position = UDim2.new(0,0,1,0)
    titleLine.AnchorPoint = Vector2.new(0,1)
    titleLine.BackgroundColor3 = C.DarkGray
    titleLine.BackgroundTransparency = 0.4
    titleLine.BorderSizePixel = 0
    titleLine.ZIndex = 11
    titleLine.Parent = titleBar

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 14, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "ARABY HUB"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = mobile and 14 or 15
    titleText.TextColor3 = C.White
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 12
    titleText.Parent = titleBar

    -- Close button (X) — DESTROYS ENTIRE GUI
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, titleH-10, 0, titleH-10)
    closeBtn.Position = UDim2.new(1, -(titleH-6), 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = C.Red
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = C.White
    closeBtn.AutoButtonColor = true
    closeBtn.ZIndex = 13
    corner(closeBtn, (titleH-10)/2)
    closeBtn.Parent = titleBar

    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {BackgroundTransparency=0.15}, 0.12):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {BackgroundTransparency=0.5}, 0.12):Play()
    end)

    -- Minimize button (—)
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, titleH-10, 0, titleH-10)
    minBtn.Position = UDim2.new(1, -((titleH-10)*2+10), 0.5, 0)
    minBtn.AnchorPoint = Vector2.new(0, 0.5)
    minBtn.BackgroundColor3 = C.DarkGray
    minBtn.BackgroundTransparency = 0.4
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 15
    minBtn.TextColor3 = C.White
    minBtn.AutoButtonColor = true
    minBtn.ZIndex = 13
    corner(minBtn, (titleH-10)/2)
    minBtn.Parent = titleBar

    minBtn.MouseEnter:Connect(function()
        tw(minBtn, {BackgroundTransparency=0.1}, 0.12):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, {BackgroundTransparency=0.4}, 0.12):Play()
    end)

    -- ═══ Sidebar (desktop only) ═══
    local sidebar = nil
    if not mobile then
        sidebar = Instance.new("Frame")
        sidebar.Name = "Sidebar"
        sidebar.Size = UDim2.new(0, sideW, 1, -(titleH))
        sidebar.Position = UDim2.new(0, 0, 0, titleH)
        sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        sidebar.BackgroundTransparency = 0.1
        sidebar.BorderSizePixel = 0
        sidebar.ZIndex = 5
        sidebar.Parent = main

        -- Sidebar right border
        local sideLine = Instance.new("Frame")
        sideLine.Size = UDim2.new(0, 1, 1, 0)
        sideLine.Position = UDim2.new(1, 0, 0, 0)
        sideLine.BackgroundColor3 = C.DarkGray
        sideLine.BackgroundTransparency = 0.5
        sideLine.BorderSizePixel = 0
        sideLine.ZIndex = 6
        sideLine.Parent = sidebar

        -- Tab buttons in sidebar
        local tabData = {
            {name = "Home",     icon = "rbxassetid://3926305904", layout = 1},
            {name = "Scripts",  icon = "rbxassetid://3926305904", layout = 2},
            {name = "Settings", icon = "rbxassetid://3926305904", layout = 3},
        }

        for i, tab in ipairs(tabData) do
            local tabBtn = Instance.new("TextButton")
            tabBtn.Name = "Tab_" .. tab.name
            tabBtn.Size = UDim2.new(1, -12, 0, 38)
            tabBtn.Position = UDim2.new(0, 6, 0, 8 + (i-1)*46)
            tabBtn.BackgroundColor3 = C.DarkGray
            tabBtn.BackgroundTransparency = 0.85
            tabBtn.BorderSizePixel = 0
            tabBtn.Text = "  " .. tab.name
            tabBtn.Font = Enum.Font.GothamMedium
            tabBtn.TextSize = 13
            tabBtn.TextColor3 = C.MidGray
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
            tabBtn.AutoButtonColor = false
            tabBtn.ZIndex = 7
            corner(tabBtn, 8)
            tabBtn.Parent = sidebar

            -- Tab icon
            local tabIcon = Instance.new("ImageLabel")
            tabIcon.Size = UDim2.new(0, 18, 0, 18)
            tabIcon.Position = UDim2.new(0, 10, 0.5, 0)
            tabIcon.AnchorPoint = Vector2.new(0, 0.5)
            tabIcon.BackgroundTransparency = 1
            tabIcon.Image = tab.icon
            tabIcon.ImageColor3 = C.MidGray
            tabIcon.ImageTransparency = 0
            tabIcon.ScaleType = Enum.ScaleType.Fit
            tabIcon.ZIndex = 8
            tabIcon.Parent = tabBtn

            -- Hover
            tabBtn.MouseEnter:Connect(function()
                tw(tabBtn, {BackgroundTransparency=0.6}):Play()
                tw(tabBtn, {TextColor3=C.White}):Play()
                tw(tabIcon, {ImageColor3=C.White}):Play()
            end)
            tabBtn.MouseLeave:Connect(function()
                tw(tabBtn, {BackgroundTransparency=0.85}):Play()
                tw(tabBtn, {TextColor3=C.MidGray}):Play()
                tw(tabIcon, {ImageColor3=C.MidGray}):Play()
            end)

            -- Click → highlight active tab
            tabBtn.MouseButton1Click:Connect(function()
                -- Reset all tabs
                for _, child in ipairs(sidebar:GetChildren()) do
                    if child:IsA("TextButton") then
                        tw(child, {BackgroundTransparency=0.85}):Play()
                        tw(child, {TextColor3=C.MidGray}):Play()
                        local ic = child:FindFirstChildOfClass("ImageLabel")
                        if ic then tw(ic, {ImageColor3=C.MidGray}):Play() end
                    end
                end
                -- Highlight this one
                tw(tabBtn, {BackgroundTransparency=0.4}):Play()
                tw(tabBtn, {TextColor3=C.White}):Play()
                tw(tabIcon, {ImageColor3=C.White}):Play()
            end)
        end
    end

    -- ═══ Content Area ═══
    local contentX = mobile and 0 or sideW
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -(contentX+20), 1, -(titleH+20))
    content.Position = UDim2.new(0, contentX+10, 0, titleH+10)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = mobile and 3 or 4
    content.ScrollBarImageColor3 = C.MidGray
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ZIndex = 5
    content.Parent = main

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = content

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,4)
    pad.PaddingRight = UDim.new(0,4)
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingBottom = UDim.new(0,4)
    pad.Parent = content

    -- Make draggable from title bar
    makeDraggable(main, titleBar)

    -- ═══ OPEN ═══
    local function open()
        if main.Visible then return end
        main.Visible = true
        main.Size = UDim2.new(0,0,0,0)
        main.BackgroundTransparency = 0.3
        mainCorner.CornerRadius = UDim.new(0.5, 0)
        overlay.BackgroundTransparency = 1
        titleBar.BackgroundTransparency = 1
        titleText.TextTransparency = 1
        closeBtn.TextTransparency = 1
        minBtn.TextTransparency = 1
        titleLine.BackgroundTransparency = 1
        if sidebar then sidebar.BackgroundTransparency = 1 end

        tw(main, {Size=UDim2.new(0,winW,0,winH), BackgroundTransparency=0}, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        tw(mainCorner, {CornerRadius=UDim.new(0,14)}, 0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
        tw(overlay, {BackgroundTransparency=0.3}, 0.35, nil, nil, 0.12):Play()
        tw(titleBar, {BackgroundTransparency=0.15}, 0.25, nil, nil, 0.18):Play()
        tw(titleText, {TextTransparency=0}, 0.25, nil, nil, 0.22):Play()
        tw(closeBtn, {TextTransparency=0}, 0.25, nil, nil, 0.28):Play()
        tw(minBtn, {TextTransparency=0}, 0.25, nil, nil, 0.28):Play()
        tw(titleLine, {BackgroundTransparency=0.4}, 0.25, nil, nil, 0.22):Play()
        if sidebar then tw(sidebar, {BackgroundTransparency=0.1}, 0.3, nil, nil, 0.2):Play() end
    end

    -- ═══ CLOSE (minimize — keep gui alive) ═══
    local function close()
        if not main.Visible then return end
        tw(main, {Size=UDim2.new(0,0,0,0), BackgroundTransparency=0.4}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
        tw(mainCorner, {CornerRadius=UDim.new(0.5,0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
        tw(overlay, {BackgroundTransparency=1}, 0.15):Play()
        tw(titleBar, {BackgroundTransparency=1}, 0.15):Play()
        tw(titleText, {TextTransparency=1}, 0.15):Play()
        tw(closeBtn, {TextTransparency=1}, 0.1):Play()
        tw(minBtn, {TextTransparency=1}, 0.1):Play()
        tw(titleLine, {BackgroundTransparency=1}, 0.15):Play()
        if sidebar then tw(sidebar, {BackgroundTransparency=1}, 0.15):Play() end
        task.delay(0.4, function() main.Visible = false end)
    end

    -- X = DESTROY ENTIRE GUI
    closeBtn.MouseButton1Click:Connect(function()
        -- Animate out first
        close()
        task.delay(0.5, function()
            if guiRef and guiRef.Parent then
                guiRef:Destroy()
            end
        end)
    end)

    minBtn.MouseButton1Click:Connect(close)

    return main, content, {open=open, close=close}
end


-- ╔══════════════════════════════════════════════════════════════╗
-- ║                       INIT                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

function ArabyHub:Init(options)
    options = options or {}

    self:ShowSplash(function()
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

        -- Persistent GUI
        local gui = Instance.new("ScreenGui")
        gui.Name = "ArabyHub_UI"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 100
        gui.Parent = playerGui

        -- Toggle button
        local root, btn, dragState = self:CreateToggleButton(options)
        root.Parent = gui

        -- Main window (pass gui ref so X can destroy it)
        local mainFrame, content, ctrl = self:CreateMainWindow(options, gui)
        mainFrame.Parent = gui

        -- Toggle
        local isOpen = false
        btn.MouseButton1Click:Connect(function()
            if dragState.isDragging() then return end
            isOpen = not isOpen
            if isOpen then
                mainFrame.Position = UDim2.new(0.5,0,0.5,0)
                ctrl.open()
            else
                ctrl.close()
            end
        end)

        -- Expose
        self._gui = gui
        self._content = content
        self._windowCtrl = ctrl
        self._isOpen = false

        function self:Toggle()
            isOpen = not isOpen
            if isOpen then
                mainFrame.Position = UDim2.new(0.5,0,0.5,0)
                ctrl.open()
            else
                ctrl.close()
            end
            self._isOpen = isOpen
        end

        function self:AddContent(element)
            if content and content.Parent then
                element.Parent = content
            end
        end

        function self:Destroy()
            if gui and gui.Parent then gui:Destroy() end
        end

        print("[ArabyHub] Ready. Drag the circle button or click to toggle.")
    end)
end

return ArabyHub