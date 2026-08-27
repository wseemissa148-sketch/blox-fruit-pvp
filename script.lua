==========================================================

-- ⚔️ PVP COMBAT HUB (Xeno Executor & GitHub Ready)

-- ==========================================================



local Players = game:GetService("Players")

local CoreGui = game:GetService("CoreGui")

local UserInputService = game:GetService("UserInputService")

local RunService = game:GetService("RunService")



local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera



-- ==========================================

-- 1. CONFIGURATION & THEMES

-- ==========================================



_G.Config = {

    PlayerAimbot = false,

    PlayerAimbotKey = "G",

    MobAimbot = false,

    MobAimbotKey = "H",

    

    TargetPart = "Head",

    HitboxSize = 18,



    ShowHealth = true,

    HealthStyle = "Modern Card",

    PlayerHealthColor = {R = 0, G = 255, B = 150},

    MobHealthColor = {R = 255, G = 50, B = 50},



    CurrentTheme = "Cyber Dark",



    Whitelist = {},

    TargetList = {}

}



local Themes = {

    ["Cyber Dark"] = {

        MainBg = Color3.fromRGB(13, 16, 24),

        SidebarBg = Color3.fromRGB(18, 21, 32),

        CardBg = Color3.fromRGB(22, 26, 38),

        Accent = Color3.fromRGB(0, 180, 255),

        Text = Color3.fromRGB(255, 255, 255),

        SubText = Color3.fromRGB(160, 160, 175),

        CornerRadius = 10

    },

    ["Midnight Purple"] = {

        MainBg = Color3.fromRGB(18, 14, 28),

        SidebarBg = Color3.fromRGB(24, 18, 38),

        CardBg = Color3.fromRGB(32, 24, 50),

        Accent = Color3.fromRGB(170, 0, 255),

        Text = Color3.fromRGB(255, 255, 255),

        SubText = Color3.fromRGB(180, 160, 200),

        CornerRadius = 14

    },

    ["Emerald Neon"] = {

        MainBg = Color3.fromRGB(10, 22, 18),

        SidebarBg = Color3.fromRGB(14, 30, 24),

        CardBg = Color3.fromRGB(18, 40, 32),

        Accent = Color3.fromRGB(0, 230, 140),

        Text = Color3.fromRGB(255, 255, 255),

        SubText = Color3.fromRGB(160, 200, 180),

        CornerRadius = 8

    },

    ["Crimson Red"] = {

        MainBg = Color3.fromRGB(24, 12, 14),

        SidebarBg = Color3.fromRGB(32, 16, 18),

        CardBg = Color3.fromRGB(42, 20, 24),

        Accent = Color3.fromRGB(255, 45, 70),

        Text = Color3.fromRGB(255, 255, 255),

        SubText = Color3.fromRGB(200, 160, 165),

        CornerRadius = 6

    },

    ["Minimal Light"] = {

        MainBg = Color3.fromRGB(240, 242, 245),

        SidebarBg = Color3.fromRGB(225, 228, 235),

        CardBg = Color3.fromRGB(255, 255, 255),

        Accent = Color3.fromRGB(40, 90, 230),

        Text = Color3.fromRGB(30, 30, 40),

        SubText = Color3.fromRGB(100, 110, 125),

        CornerRadius = 12

    }

}



local lockedTargetPart = nil

local ThemeUpdateSignals = {}



-- ==========================================

-- 2. HEALTH OVERLAY ENGINE

-- ==========================================



local function RemoveHealthUI(character)

    if character then

        local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

        if head then

            local gui = head:FindFirstChild("HealthUIOverlay")

            if gui then gui:Destroy() end

        end

    end

end



local function CreateHealthUI(character, isPlayer)

    if not character or not _G.Config.ShowHealth then return end

    RemoveHealthUI(character)



    local head = character:WaitForChild("Head", 2) or character:WaitForChild("HumanoidRootPart", 2)

    local hum = character:WaitForChild("Humanoid", 2)

    if not head or not hum then return end



    local bb = Instance.new("BillboardGui")

    bb.Name = "HealthUIOverlay"

    bb.Adornee = head

    bb.Size = UDim2.new(0, 140, 0, 35)

    bb.StudsOffset = Vector3.new(0, 3, 0)

    bb.AlwaysOnTop = true

    bb.MaxDistance = math.huge

    bb.Parent = head



    local col = isPlayer and _G.Config.PlayerHealthColor or _G.Config.MobHealthColor

    local mainColor = Color3.fromRGB(col.R, col.G, col.B)



    if _G.Config.HealthStyle == "Text Only" then

        local txt = Instance.new("TextLabel")

        txt.Name = "Label"

        txt.Size = UDim2.new(1, 0, 1, 0)

        txt.BackgroundTransparency = 1

        txt.Font = Enum.Font.GothamBold

        txt.TextSize = 11

        txt.TextColor3 = mainColor

        txt.TextStrokeTransparency = 0.2

        txt.Parent = bb



        local function UpdateText()

            if not hum or not hum.Parent then return end

            local tag = isPlayer and "👤 " or "👾 "

            txt.Text = tag .. math.floor(math.max(0, hum.Health)) .. " / " .. math.floor(hum.MaxHealth)

        end

        UpdateText()

        hum.HealthChanged:Connect(UpdateText)



    elseif _G.Config.HealthStyle == "Classic Bar" then

        local bg = Instance.new("Frame")

        bg.Size = UDim2.new(1, 0, 0, 8)

        bg.Position = UDim2.new(0, 0, 0.5, -4)

        bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

        bg.BorderSizePixel = 0

        bg.Parent = bb



        local fill = Instance.new("Frame")

        fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)

        fill.BackgroundColor3 = mainColor

        fill.BorderSizePixel = 0

        fill.Parent = bg



        hum.HealthChanged:Connect(function()

            fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)

        end)



    elseif _G.Config.HealthStyle == "Modern Card" then

        local card = Instance.new("Frame")

        card.Size = UDim2.new(1, 0, 1, 0)

        card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)

        card.BackgroundTransparency = 0.2

        card.Parent = bb



        local cCorner = Instance.new("UICorner")

        cCorner.CornerRadius = UDim.new(0, 6)

        cCorner.Parent = card



        local title = Instance.new("TextLabel")

        title.Size = UDim2.new(1, -10, 0, 14)

        title.Position = UDim2.new(0, 5, 0, 2)

        title.BackgroundTransparency = 1

        title.Text = (isPlayer and "👤 " or "👾 ") .. character.Name

        title.TextColor3 = Color3.fromRGB(240, 240, 240)

        title.Font = Enum.Font.GothamBold

        title.TextSize = 9

        title.TextXAlignment = Enum.TextXAlignment.Left

        title.Parent = card



        local bg = Instance.new("Frame")

        bg.Size = UDim2.new(1, -10, 0, 6)

        bg.Position = UDim2.new(0, 5, 0, 18)

        bg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)

        bg.BorderSizePixel = 0

        bg.Parent = card



        local bgCorner = Instance.new("UICorner")

        bgCorner.CornerRadius = UDim.new(0, 4)

        bgCorner.Parent = bg



        local fill = Instance.new("Frame")

        fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)

        fill.BackgroundColor3 = mainColor

        fill.BorderSizePixel = 0

        fill.Parent = bg



        local fillCorner = Instance.new("UICorner")

        fillCorner.CornerRadius = UDim.new(0, 4)

        fillCorner.Parent = fill



        hum.HealthChanged:Connect(function()

            fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)

        end)



    elseif _G.Config.HealthStyle == "Gradient Bar" then

        local bg = Instance.new("Frame")

        bg.Size = UDim2.new(1, 0, 0, 8)

        bg.Position = UDim2.new(0, 0, 0.5, -4)

        bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

        bg.BorderSizePixel = 0

        bg.Parent = bb



        local fill = Instance.new("Frame")

        fill.BorderSizePixel = 0

        fill.Parent = bg



        local function UpdateGradient()

            local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)

            fill.Size = UDim2.new(pct, 0, 1, 0)

            fill.BackgroundColor3 = Color3.fromHSV(pct * 0.35, 0.9, 0.9)

        end

        UpdateGradient()

        hum.HealthChanged:Connect(UpdateGradient)



    elseif _G.Config.HealthStyle == "Compact Line" then

        local fill = Instance.new("Frame")

        fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 0, 4)

        fill.Position = UDim2.new(0, 0, 0.8, 0)

        fill.BackgroundColor3 = mainColor

        fill.BorderSizePixel = 0

        fill.Parent = bb



        hum.HealthChanged:Connect(function()

            fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 0, 4)

        end)

    end



    hum.Died:Connect(function() bb:Destroy() end)

end



local function RefreshAllHealthUI()

    for _, p in pairs(Players:GetPlayers()) do

        if p ~= LocalPlayer and p.Character then

            CreateHealthUI(p.Character, true)

        end

    end

    local enemies = workspace:FindFirstChild("Enemies")

    if enemies then

        for _, mob in pairs(enemies:GetChildren()) do

            CreateHealthUI(mob, false)

        end

    end

end



local function SetupCharacterUI(char, isPlayer)

    if char then

        task.defer(function() CreateHealthUI(char, isPlayer) end)

    end

end



for _, p in pairs(Players:GetPlayers()) do

    if p ~= LocalPlayer then

        if p.Character then SetupCharacterUI(p.Character, true) end

        p.CharacterAdded:Connect(function(c) SetupCharacterUI(c, true) end)

    end

end



Players.PlayerAdded:Connect(function(p)

    p.CharacterAdded:Connect(function(c) SetupCharacterUI(c, true) end)

end)



local function HookEnemies()

    local enemies = workspace:FindFirstChild("Enemies")

    if enemies then

        for _, mob in pairs(enemies:GetChildren()) do SetupCharacterUI(mob, false) end

        enemies.ChildAdded:Connect(function(mob) SetupCharacterUI(mob, false) end)

    end

end

task.spawn(HookEnemies)



-- ==========================================

-- 3. HARD LOCK AIMBOT ENGINE

-- ==========================================



local function IsWhitelisted(name)

    for _, v in ipairs(_G.Config.Whitelist) do

        if v:lower() == name:lower() then return true end

    end

    return false

end



local function IsTargeted(name)

    if #_G.Config.TargetList == 0 then return true end

    for _, v in ipairs(_G.Config.TargetList) do

        if v:lower() == name:lower() then return true end

    end

    return false

end



local function GetClosestToCamera(isPlayerTarget)

    local closestPart = nil

    local shortestDistance = math.huge

    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)



    if isPlayerTarget then

        for _, p in pairs(Players:GetPlayers()) do

            if p ~= LocalPlayer and p.Character and not IsWhitelisted(p.Name) and IsTargeted(p.Name) then

                local targetPart = p.Character:FindFirstChild(_G.Config.TargetPart) or p.Character:FindFirstChild("HumanoidRootPart")

                local hum = p.Character:FindFirstChild("Humanoid")

                if targetPart and hum and hum.Health > 0 then

                    local screenPos = Camera:WorldToViewportPoint(targetPart.Position)

                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude

                    if screenDist < shortestDistance then

                        shortestDistance = screenDist

                        closestPart = targetPart

                    end

                end

            end

        end

    else

        local enemies = workspace:FindFirstChild("Enemies")

        if enemies then

            for _, mob in pairs(enemies:GetChildren()) do

                local targetPart = mob:FindFirstChild(_G.Config.TargetPart) or mob:FindFirstChild("HumanoidRootPart")

                local hum = mob:FindFirstChild("Humanoid")

                if targetPart and hum and hum.Health > 0 then

                    local screenPos = Camera:WorldToViewportPoint(targetPart.Position)

                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude

                    if screenDist < shortestDistance then

                        shortestDistance = screenDist

                        closestPart = targetPart

                    end

                end

            end

        end

    end

    return closestPart

end



RunService.RenderStepped:Connect(function()

    local isAimbotActive = _G.Config.PlayerAimbot or _G.Config.MobAimbot



    if isAimbotActive then

        if not lockedTargetPart or not lockedTargetPart.Parent or not lockedTargetPart.Parent:FindFirstChild("Humanoid") or lockedTargetPart.Parent.Humanoid.Health <= 0 then

            lockedTargetPart = GetClosestToCamera(_G.Config.PlayerAimbot)

        end



        if lockedTargetPart and lockedTargetPart.Parent then

            pcall(function()

                Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)

                lockedTargetPart.Size = Vector3.new(_G.Config.HitboxSize, _G.Config.HitboxSize, _G.Config.HitboxSize)

                lockedTargetPart.Transparency = 0.7

                lockedTargetPart.CanCollide = false

            end)

        end

    else

        lockedTargetPart = nil

    end

end)



UserInputService.InputBegan:Connect(function(input, processed)

    if processed then return end

    pcall(function()

        if input.KeyCode == Enum.KeyCode[_G.Config.PlayerAimbotKey] then

            _G.Config.PlayerAimbot = not _G.Config.PlayerAimbot

            lockedTargetPart = nil

        elseif input.KeyCode == Enum.KeyCode[_G.Config.MobAimbotKey] then

            _G.Config.MobAimbot = not _G.Config.MobAimbot

            lockedTargetPart = nil

        end

    end)

end)



-- ==========================================

-- 4. GUI ENGINE WITH DYNAMIC THEMES

-- ==========================================



if CoreGui:FindFirstChild("PvpCombatHubUI") then

    CoreGui.PvpCombatHubUI:Destroy()

end



local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "PvpCombatHubUI"



if gethui then

    ScreenGui.Parent = gethui()

elseif syn and syn.protect_gui then

    syn.protect_gui(ScreenGui)

    ScreenGui.Parent = CoreGui

else

    ScreenGui.Parent = CoreGui

end



local MainFrame = Instance.new("Frame")

MainFrame.Size = UDim2.new(0, 510, 0, 360)

MainFrame.Position = UDim2.new(0.5, -255, 0.25, 0)

MainFrame.BorderSizePixel = 0

MainFrame.Active = true

MainFrame.Draggable = true

MainFrame.Parent = ScreenGui



local MainCorner = Instance.new("UICorner")

MainCorner.Parent = MainFrame



local MainStroke = Instance.new("UIStroke")

MainStroke.Thickness = 1.5

MainStroke.Parent = MainFrame



local Sidebar = Instance.new("Frame")

Sidebar.Size = UDim2.new(0, 140, 1, 0)

Sidebar.Parent = MainFrame



local SideCorner = Instance.new("UICorner")

SideCorner.Parent = Sidebar



local SideLayout = Instance.new("UIListLayout")

SideLayout.Padding = UDim.new(0, 6)

SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

SideLayout.Parent = Sidebar



local TitleLabel = Instance.new("TextLabel")

TitleLabel.Size = UDim2.new(1, 0, 0, 42)

TitleLabel.Text = "⚔️ PVP COMBAT"

TitleLabel.Font = Enum.Font.GothamBold

TitleLabel.TextSize = 11

TitleLabel.BackgroundTransparency = 1

TitleLabel.Parent = Sidebar



local ContentArea = Instance.new("Frame")

ContentArea.Size = UDim2.new(1, -150, 1, -10)

ContentArea.Position = UDim2.new(0, 145, 0, 5)

ContentArea.BackgroundTransparency = 1

ContentArea.Parent = MainFrame



-- ZER PVP ICON BUTTON

local ToggleBtn = Instance.new("TextButton")

ToggleBtn.Size = UDim2.new(0, 65, 0, 32)

ToggleBtn.Position = UDim2.new(0.02, 0, 0.05, 0)

ToggleBtn.Text = "PVP"

ToggleBtn.Font = Enum.Font.GothamBold

ToggleBtn.TextSize = 12

ToggleBtn.Parent = ScreenGui



local ToggleCorner = Instance.new("UICorner")

ToggleCorner.Parent = ToggleBtn



local ToggleStroke = Instance.new("UIStroke")

ToggleStroke.Thickness = 1

ToggleStroke.Parent = ToggleBtn



ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)



local function ApplyTheme()

    local theme = Themes[_G.Config.CurrentTheme] or Themes["Cyber Dark"]



    MainFrame.BackgroundColor3 = theme.MainBg

    MainStroke.Color = theme.Accent



    Sidebar.BackgroundColor3 = theme.SidebarBg

    TitleLabel.TextColor3 = theme.Accent



    MainCorner.CornerRadius = UDim.new(0, theme.CornerRadius)

    SideCorner.CornerRadius = UDim.new(0, theme.CornerRadius)

    ToggleCorner.CornerRadius = UDim.new(0, theme.CornerRadius)



    ToggleBtn.BackgroundColor3 = theme.SidebarBg

    ToggleBtn.TextColor3 = theme.Accent

    ToggleStroke.Color = theme.Accent



    for _, updateFunc in ipairs(ThemeUpdateSignals) do

        updateFunc(theme)

    end

end



local tabs = {}



local function CreateTab(tabName)

    local TabBtn = Instance.new("TextButton")

    TabBtn.Size = UDim2.new(0.9, 0, 0, 30)

    TabBtn.Text = tabName

    TabBtn.Font = Enum.Font.GothamBold

    TabBtn.TextSize = 9

    TabBtn.Parent = Sidebar



    local BtnCorner = Instance.new("UICorner")

    BtnCorner.Parent = TabBtn



    local TabPage = Instance.new("ScrollingFrame")

    TabPage.Size = UDim2.new(1, 0, 1, 0)

    TabPage.BackgroundTransparency = 1

    TabPage.Visible = false

    TabPage.ScrollBarThickness = 3

    TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)

    TabPage.Parent = ContentArea



    local PageLayout = Instance.new("UIListLayout")

    PageLayout.Padding = UDim.new(0, 6)

    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    PageLayout.Parent = TabPage



    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

        TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)

    end)



    local function UpdateTabStyle(currentTheme)

        BtnCorner.CornerRadius = UDim.new(0, math.max(4, currentTheme.CornerRadius - 4))

        if TabPage.Visible then

            TabBtn.TextColor3 = currentTheme.Accent

            TabBtn.BackgroundColor3 = currentTheme.CardBg

        else

            TabBtn.TextColor3 = currentTheme.SubText

            TabBtn.BackgroundColor3 = currentTheme.SidebarBg

        end

    end

    table.insert(ThemeUpdateSignals, UpdateTabStyle)



    TabBtn.MouseButton1Click:Connect(function()

        for _, t in pairs(tabs) do

            t.Page.Visible = false

        end

        TabPage.Visible = true

        ApplyTheme()

    end)



    table.insert(tabs, {Btn = TabBtn, Page = TabPage})

    return TabPage

end



local function AddToggle(parentPage, name, configVar, callback)

    local Button = Instance.new("TextButton")

    Button.Size = UDim2.new(0.96, 0, 0, 32)

    Button.Text = "  " .. name

    Button.Font = Enum.Font.GothamMedium

    Button.TextSize = 9

    Button.TextXAlignment = Enum.TextXAlignment.Left

    Button.Parent = parentPage



    local BtnCorner = Instance.new("UICorner")

    BtnCorner.Parent = Button



    local Indicator = Instance.new("Frame")

    Indicator.Size = UDim2.new(0, 26, 0, 14)

    Indicator.Position = UDim2.new(1, -32, 0.5, -7)

    Indicator.Parent = Button



    local IndCorner = Instance.new("UICorner")

    IndCorner.CornerRadius = UDim.new(0, 10)

    IndCorner.Parent = Indicator



    local function UpdateToggleStyle(theme)

        BtnCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4))

        Button.BackgroundColor3 = theme.CardBg

        Button.TextColor3 = _G.Config[configVar] and theme.Text or theme.SubText

        Indicator.BackgroundColor3 = _G.Config[configVar] and theme.Accent or Color3.fromRGB(50, 50, 60)

    end

    table.insert(ThemeUpdateSignals, UpdateToggleStyle)



    Button.MouseButton1Click:Connect(function()

        _G.Config[configVar] = not _G.Config[configVar]

        ApplyTheme()

        if callback then callback() end

    end)

    return Button

end



local function AddKeybindPicker(parentPage, name, configVar)

    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.new(0.96, 0, 0, 32)

    Frame.Parent = parentPage



    local Corner = Instance.new("UICorner")

    Corner.Parent = Frame



    local Label = Instance.new("TextLabel")

    Label.Size = UDim2.new(0.6, 0, 1, 0)

    Label.Text = "  " .. name

    Label.Font = Enum.Font.GothamMedium

    Label.TextSize = 9

    Label.TextXAlignment = Enum.TextXAlignment.Left

    Label.BackgroundTransparency = 1

    Label.Parent = Frame



    local BindBtn = Instance.new("TextButton")

    BindBtn.Size = UDim2.new(0.35, 0, 0.7, 0)

    BindBtn.Position = UDim2.new(0.62, 0, 0.15, 0)

    BindBtn.Text = "[" .. tostring(_G.Config[configVar]) .. "]"

    BindBtn.Font = Enum.Font.GothamBold

    BindBtn.TextSize = 9

    BindBtn.Parent = Frame



    local BtnCorner = Instance.new("UICorner")

    BtnCorner.Parent = BindBtn



    local function UpdateBindStyle(theme)

        Corner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4))

        BtnCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 6))

        Frame.BackgroundColor3 = theme.CardBg

        Label.TextColor3 = theme.Text

        BindBtn.BackgroundColor3 = theme.SidebarBg

        BindBtn.TextColor3 = theme.Accent

    end

    table.insert(ThemeUpdateSignals, UpdateBindStyle)



    BindBtn.MouseButton1Click:Connect(function()

        BindBtn.Text = "[ Press... ]"

        local conn

        conn = UserInputService.InputBegan:Connect(function(input)

            if input.UserInputType == Enum.UserInputType.Keyboard then

                local keyName = input.KeyCode.Name

                _G.Config[configVar] = keyName

                BindBtn.Text = "[" .. keyName .. "]"

                conn:Disconnect()

            end

        end)

    end)

end



local function AddDropdown(parentPage, title, optionsList, configVar, callback)

    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.new(0.96, 0, 0, 32)

    Frame.Parent = parentPage



    local Corner = Instance.new("UICorner")

    Corner.Parent = Frame



    local Label = Instance.new("TextLabel")

    Label.Size = UDim2.new(0.45, 0, 1, 0)

    Label.Text = "  " .. title

    Label.Font = Enum.Font.GothamMedium

    Label.TextSize = 9

    Label.TextXAlignment = Enum.TextXAlignment.Left

    Label.BackgroundTransparency = 1

    Label.Parent = Frame



    local DropBtn = Instance.new("TextButton")

    DropBtn.Size = UDim2.new(0.50, 0, 0.7, 0)

    DropBtn.Position = UDim2.new(0.47, 0, 0.15, 0)

    DropBtn.Text = tostring(_G.Config[configVar])

    DropBtn.Font = Enum.Font.GothamBold

    DropBtn.TextSize = 8

    DropBtn.Parent = Frame



    local BtnCorner = Instance.new("UICorner")

    BtnCorner.Parent = DropBtn



    local idx = 1

    for i, opt in ipairs(optionsList) do

        if opt == _G.Config[configVar] then idx = i break end

    end



    local function UpdateDropStyle(theme)

        Corner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4))

        BtnCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 6))

        Frame.BackgroundColor3 = theme.CardBg

        Label.TextColor3 = theme.Text

        DropBtn.BackgroundColor3 = theme.SidebarBg

        DropBtn.TextColor3 = theme.Accent

    end

    table.insert(ThemeUpdateSignals, UpdateDropStyle)



    DropBtn.MouseButton1Click:Connect(function()

        idx = (idx % #optionsList) + 1

        _G.Config[configVar] = optionsList[idx]

        DropBtn.Text = optionsList[idx]

        if callback then callback() end

    end)

end



local function AddListManager(parentPage, title, listTable)

    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.new(0.96, 0, 0, 75)

    Frame.Parent = parentPage



    local Corner = Instance.new("UICorner")

    Corner.Parent = Frame



    local Label = Instance.new("TextLabel")

    Label.Size = UDim2.new(1, -10, 0, 20)

    Label.Position = UDim2.new(0, 5, 0, 2)

    Label.Text = title

    Label.Font = Enum.Font.GothamBold

    Label.TextSize = 9

    Label.TextXAlignment = Enum.TextXAlignment.Left

    Label.BackgroundTransparency = 1

    Label.Parent = Frame



    local TextBox = Instance.new("TextBox")

    TextBox.Size = UDim2.new(0.55, 0, 0, 24)

    TextBox.Position = UDim2.new(0.03, 0, 0.35, 0)

    TextBox.Text = ""

    TextBox.PlaceholderText = "Player Name..."

    TextBox.Font = Enum.Font.GothamMedium

    TextBox.TextSize = 8

    TextBox.Parent = Frame



    local tbCorner = Instance.new("UICorner")

    tbCorner.CornerRadius = UDim.new(0, 4)

    tbCorner.Parent = TextBox



    local AddBtn = Instance.new("TextButton")

    AddBtn.Size = UDim2.new(0.18, 0, 0, 24)

    AddBtn.Position = UDim2.new(0.60, 0, 0.35, 0)

    AddBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

    AddBtn.Text = "Add"

    AddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    AddBtn.Font = Enum.Font.GothamBold

    AddBtn.TextSize = 8

    AddBtn.Parent = Frame



    local RemoveBtn = Instance.new("TextButton")

    RemoveBtn.Size = UDim2.new(0.18, 0, 0, 24)

    RemoveBtn.Position = UDim2.new(0.79, 0, 0.35, 0)

    RemoveBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)

    RemoveBtn.Text = "Remove"

    RemoveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    RemoveBtn.Font = Enum.Font.GothamBold

    RemoveBtn.TextSize = 8

    RemoveBtn.Parent = Frame



    local StatusLabel = Instance.new("TextLabel")

    StatusLabel.Size = UDim2.new(1, -10, 0, 15)

    StatusLabel.Position = UDim2.new(0, 5, 0.75, 0)

    StatusLabel.Text = "List: " .. table.concat(listTable, ", ")

    StatusLabel.Font = Enum.Font.GothamMedium

    StatusLabel.TextSize = 8

    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    StatusLabel.BackgroundTransparency = 1

    StatusLabel.Parent = Frame



    local function UpdateListStyle(theme)

        Corner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4))

        Frame.BackgroundColor3 = theme.CardBg

        Label.TextColor3 = theme.Accent

        TextBox.BackgroundColor3 = theme.MainBg

        TextBox.TextColor3 = theme.Text

        StatusLabel.TextColor3 = theme.SubText

    end

    table.insert(ThemeUpdateSignals, UpdateListStyle)



    AddBtn.MouseButton1Click:Connect(function()

        local name = TextBox.Text:match("^%s*(.-)%s*$")

        if name ~= "" then

            local exists = false

            for _, v in ipairs(listTable) do

                if v:lower() == name:lower() then exists = true; break end

            end

            if not exists then

                table.insert(listTable, name)

                StatusLabel.Text = "List: " .. table.concat(listTable, ", ")

                TextBox.Text = ""

            end

        end

    end)



    RemoveBtn.MouseButton1Click:Connect(function()

        local name = TextBox.Text:match("^%s*(.-)%s*$")

        if name ~= "" then

            for idx, v in ipairs(listTable) do

                if v:lower() == name:lower() then

                    table.remove(listTable, idx)

                    StatusLabel.Text = "List: " .. table.concat(listTable, ", ")

                    TextBox.Text = ""

                    break

                end

            end

        end

    end)

end



-- ==========================================

-- TABS & CONTROLS SETUP

-- ==========================================



local CombatTab = CreateTab("⚔️ Combat & Aimbot")

local VisualsTab = CreateTab("👁️ Health & UI")

local SettingsTab = CreateTab("🎨 UI Themes")



tabs[1].Page.Visible = true



-- Combat Tab

AddToggle(CombatTab, "Player Camera Aimbot", "PlayerAimbot")

AddKeybindPicker(CombatTab, "Player Aimbot Key", "PlayerAimbotKey")

AddToggle(CombatTab, "Mob Camera Aimbot", "MobAimbot")

AddKeybindPicker(CombatTab, "Mob Aimbot Key", "MobAimbotKey")

AddListManager(CombatTab, "🛡️ Whitelist", _G.Config.Whitelist)

AddListManager(CombatTab, "🎯 Target List", _G.Config.TargetList)



-- Visuals Tab

AddToggle(VisualsTab, "Show Health Overlay", "ShowHealth", RefreshAllHealthUI)

AddDropdown(VisualsTab, "Health Style", {"Modern Card", "Classic Bar", "Text Only", "Gradient Bar", "Compact Line"}, "HealthStyle", RefreshAllHealthUI)



-- Settings / Themes Tab

AddDropdown(SettingsTab, "UI Theme Model", {"Cyber Dark", "Midnight Purple", "Emerald Neon", "Crimson Red", "Minimal Light"}, "CurrentTheme", ApplyTheme)



-- Apply initial theme

ApplyTheme()
