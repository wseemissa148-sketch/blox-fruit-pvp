-- ==========================================================
-- ⚔️ PVP COMBAT HUB (Xeno & GitHub Loadstring Ready)
-- ==========================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- 1. CONFIGURATION
-- ==========================================

_G.Config = {
    PlayerAimbot = false,
    PlayerAimbotKey = "G",
    MobAimbot = false,
    MobAimbotKey = "H",
    
    TargetPart = "Head",
    HitboxSize = 18,
    Smoothness = 0.5, -- قيمة 1 تعني التصاق فوري ومطلق بالهدف (Sticky Lock)

    ShowHealth = true,
    HealthStyle = "Modern Card",
    PlayerHealthColor = {R = 0, G = 255, B = 150},
    MobHealthColor = {R = 255, G = 50, B = 50},

    Whitelist = {},
    TargetList = {}
}

local lockedTargetPart = nil

-- ==========================================
-- 2. HEALTH OVERLAY ENGINE (FIXED)
-- ==========================================

local function RemoveHealthUI(character)
    if character and character:FindFirstChild("Head") then
        local gui = character.Head:FindFirstChild("HealthUIOverlay")
        if gui then gui:Destroy() end
    end
end

local function CreateHealthUI(character, isPlayer)
    if not character or not _G.Config.ShowHealth then return end
    RemoveHealthUI(character)

    local head = character:WaitForChild("Head", 3)
    local hum = character:WaitForChild("Humanoid", 3)
    if not head or not hum then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthUIOverlay"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 140, 0, 35)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
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
        fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        fill.BackgroundColor3 = mainColor
        fill.BorderSizePixel = 0
        fill.Parent = bg

        hum.HealthChanged:Connect(function()
            fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
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
        fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        fill.BackgroundColor3 = mainColor
        fill.BorderSizePixel = 0
        fill.Parent = bg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = fill

        hum.HealthChanged:Connect(function()
            fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        end)

    elseif _G.Config.HealthStyle == "Gradient Bar" then
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 0, 6)
        bg.Position = UDim2.new(0, 0, 0.5, -3)
        bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        bg.BorderSizePixel = 0
        bg.Parent = bb

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        fill.BorderSizePixel = 0
        fill.Parent = bg

        local function UpdateGradient()
            local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            fill.Size = UDim2.new(hpPercent, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.35, 0.9, 0.9)
        end
        UpdateGradient()
        hum.HealthChanged:Connect(UpdateGradient)
    end

    hum.Died:Connect(function() bb:Destroy() end)
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

-- ==========================================
-- 3. STICKY AIMBOT ENGINE (XENO OPTIMIZED)
-- ==========================================

local function IsWhitelisted(name)
    for _, v in ipairs(_G.Config.Whitelist) do
        if v:lower() == name:lower() then return true end
    end
    return false
end

local function GetClosestTargetToCamera(isPlayerTarget)
    local closest, shortestDist = nil, math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if isPlayerTarget then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsWhitelisted(p.Name) then
                local targetPart = p.Character:FindFirstChild(_G.Config.TargetPart) or p.Character:FindFirstChild("HumanoidRootPart")
                local pHum = p.Character:FindFirstChild("Humanoid")
                if targetPart and pHum and pHum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                        if screenDist < shortestDist then
                            shortestDist = screenDist
                            closest = targetPart
                        end
                    end
                end
            end
        end
    else
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in pairs(enemies:GetChildren()) do
                local targetPart = mob:FindFirstChild(_G.Config.TargetPart) or mob:FindFirstChild("HumanoidRootPart")
                local mHum = mob:FindFirstChild("Humanoid")
                if targetPart and mHum and mHum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                        if screenDist < shortestDist then
                            shortestDist = screenDist
                            closest = targetPart
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- نظام التثبيت المباشر (Sticky Logic)
RunService.RenderStepped:Connect(function()
    local isAimbotActive = _G.Config.PlayerAimbot or _G.Config.MobAimbot
    
    if isAimbotActive then
        -- إذا لم يكن هناك هدف محدد حالياً أو أن الهدف الملتصق به مات، ابحث عن هدف جديد
        if not lockedTargetPart or not lockedTargetPart.Parent or not lockedTargetPart.Parent:FindFirstChild("Humanoid") or lockedTargetPart.Parent.Humanoid.Health <= 0 then
            lockedTargetPart = GetClosestTargetToCamera(_G.Config.PlayerAimbot)
        end

        -- الالتصاق التام بالهدف (Sticky Lock)
        if lockedTargetPart and lockedTargetPart.Parent then
            pcall(function()
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)
                
                -- Hitbox Expander
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
-- 4. GUI ENGINE (XENO & CORE GUI COMPATIBLE)
-- ==========================================

if CoreGui:FindFirstChild("PvpCombatHubUI") then
    CoreGui.PvpCombatHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PvpCombatHubUI"

-- حماية الواجهة لرفع التوافق مع Xeno
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
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 180, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 21, 32)
Sidebar.Parent = MainFrame

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 10)
SideCorner.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Parent = Sidebar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 42)
TitleLabel.Text = "⚔️ PVP COMBAT"
TitleLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, -10)
ContentArea.Position = UDim2.new(0, 145, 0, 5)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 85, 0, 30)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.05, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 21, 32)
ToggleBtn.Text = "TOGGLE MENU"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 9
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local tabs = {}

local function CreateTab(tabName)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.9, 0, 0, 30)
    TabBtn.BackgroundColor3 = Color3.fromRGB(26, 31, 46)
    TabBtn.Text = tabName
    TabBtn.TextColor3 = Color3.fromRGB(160, 160, 175)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 9
    TabBtn.Parent = Sidebar

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
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

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Btn.TextColor3 = Color3.fromRGB(160, 160, 175)
            t.Btn.BackgroundColor3 = Color3.fromRGB(26, 31, 46)
        end
        TabPage.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 68)
    end)

    table.insert(tabs, {Btn = TabBtn, Page = TabPage})
    return TabPage
end

local function AddToggle(parentPage, name, configVar)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.96, 0, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Button.Text = "  " .. name
    Button.TextColor3 = _G.Config[configVar] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
    Button.Font = Enum.Font.GothamMedium
    Button.TextSize = 9
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Parent = parentPage

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 26, 0, 14)
    Indicator.Position = UDim2.new(1, -32, 0.5, -7)
    Indicator.BackgroundColor3 = _G.Config[configVar] and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(45, 50, 65)
    Indicator.Parent = Button

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 10)
    IndCorner.Parent = Indicator

    Button.MouseButton1Click:Connect(function()
        _G.Config[configVar] = not _G.Config[configVar]
        Indicator.BackgroundColor3 = _G.Config[configVar] and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(45, 50, 65)
        Button.TextColor3 = _G.Config[configVar] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
    end)
    return Button
end

local function AddKeybindPicker(parentPage, name, configVar)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.96, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Text = "  " .. name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local BindBtn = Instance.new("TextButton")
    BindBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
    BindBtn.Position = UDim2.new(0.62, 0, 0.15, 0)
    BindBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 68)
    BindBtn.Text = "[" .. tostring(_G.Config[configVar]) .. "]"
    BindBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
    BindBtn.Font = Enum.Font.GothamBold
    BindBtn.TextSize = 9
    BindBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = BindBtn

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

local function AddDropdown(parentPage, title, optionsList, configVar)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.96, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.45, 0, 1, 0)
    Label.Text = "  " .. title
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(0.50, 0, 0.7, 0)
    DropBtn.Position = UDim2.new(0.47, 0, 0.15, 0)
    DropBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 68)
    DropBtn.Text = tostring(_G.Config[configVar])
    DropBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
    DropBtn.Font = Enum.Font.GothamBold
    DropBtn.TextSize = 8
    DropBtn.Parent = Frame

    local idx = 1
    for i, opt in ipairs(optionsList) do
        if opt == _G.Config[configVar] then idx = i break end
    end

    DropBtn.MouseButton1Click:Connect(function()
        idx = (idx % #optionsList) + 1
        _G.Config[configVar] = optionsList[idx]
        DropBtn.Text = optionsList[idx]
    end)
end

-- Tabs Setup
local CombatTab = CreateTab("⚔️ Combat & Aimbot")
local VisualsTab = CreateTab("👁️ Health ESP")

tabs[1].Page.Visible = true
tabs[1].Btn.TextColor3 = Color3.fromRGB(0, 180, 255)

AddToggle(CombatTab, "Player Sticky Aimbot", "PlayerAimbot")
AddKeybindPicker(CombatTab, "Player Aimbot Key", "PlayerAimbotKey")
AddToggle(CombatTab, "Mob Sticky Aimbot", "MobAimbot")
AddKeybindPicker(CombatTab, "Mob Aimbot Key", "MobAimbotKey")

AddToggle(VisualsTab, "Show Health Overlay", "ShowHealth")
AddDropdown(VisualsTab, "Health Style", {"Modern Card", "Classic Bar", "Text Only", "Gradient Bar"}, "HealthStyle")
