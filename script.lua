-- ==========================================================
-- ⚔️ PVP COMBAT HUB (Xeno Executor & GitHub Ready) - V2 (Full)
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
    
    AimbotSmoothness = 0.25, 
    DisableAtHealth = 3000, 
    TargetPart = "Head",
    HitboxSize = 18,

    ShowHealth = true,
    HealthStyle = "Modern Card",
    PlayerHealthColor = {R = 0, G = 255, B = 150},
    MobHealthColor = {R = 255, G = 50, B = 50},

    CurrentTheme = "Cyber Dark",
}

local Themes = {
    ["Cyber Dark"] = { MainBg = Color3.fromRGB(13, 16, 24), SidebarBg = Color3.fromRGB(18, 21, 32), CardBg = Color3.fromRGB(22, 26, 38), Accent = Color3.fromRGB(0, 180, 255), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(160, 160, 175), CornerRadius = 10 },
    ["Midnight Purple"] = { MainBg = Color3.fromRGB(18, 14, 28), SidebarBg = Color3.fromRGB(24, 18, 38), CardBg = Color3.fromRGB(32, 24, 50), Accent = Color3.fromRGB(170, 0, 255), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(180, 160, 200), CornerRadius = 14 },
    ["Emerald Neon"] = { MainBg = Color3.fromRGB(10, 22, 18), SidebarBg = Color3.fromRGB(14, 30, 24), CardBg = Color3.fromRGB(18, 40, 32), Accent = Color3.fromRGB(0, 230, 140), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(160, 200, 180), CornerRadius = 8 }
}

local lockedTargetPart = nil
local ThemeUpdateSignals = {}

-- ==========================================
-- 2. HEALTH & RACE OVERLAY ENGINE
-- ==========================================

local function RemoveHealthUI(character)
    if character then
        local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
        if head and head:FindFirstChild("HealthUIOverlay") then head.HealthUIOverlay:Destroy() end
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
    bb.Size = UDim2.new(0, 140, 0, 45) 
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.Parent = head

    local col = isPlayer and _G.Config.PlayerHealthColor or _G.Config.MobHealthColor
    local mainColor = Color3.fromRGB(col.R, col.G, col.B)

    if _G.Config.HealthStyle == "Modern Card" then
        local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 1, 0); card.BackgroundColor3 = Color3.fromRGB(15, 18, 26); card.BackgroundTransparency = 0.2; card.Parent = bb
        local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 6); cCorner.Parent = card
        
        local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -10, 0, 14); title.Position = UDim2.new(0, 5, 0, 2); title.BackgroundTransparency = 1; title.Text = (isPlayer and "👤 " or "👾 ") .. character.Name; title.TextColor3 = Color3.fromRGB(240, 240, 240); title.Font = Enum.Font.GothamBold; title.TextSize = 9; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = card
        
        local bg = Instance.new("Frame"); bg.Size = UDim2.new(1, -10, 0, 6); bg.Position = UDim2.new(0, 5, 0, 18); bg.BackgroundColor3 = Color3.fromRGB(35, 40, 55); bg.BorderSizePixel = 0; bg.Parent = card
        local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 4); bgCorner.Parent = bg
        local fill = Instance.new("Frame"); fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0); fill.BackgroundColor3 = mainColor; fill.BorderSizePixel = 0; fill.Parent = bg
        local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0, 4); fillCorner.Parent = fill
        
        local raceBg = Instance.new("Frame"); raceBg.Size = UDim2.new(1, -10, 0, 4); raceBg.Position = UDim2.new(0, 5, 0, 28); raceBg.BackgroundColor3 = Color3.fromRGB(35, 30, 55); raceBg.BorderSizePixel = 0; raceBg.Parent = card
        local rBgCorner = Instance.new("UICorner"); rBgCorner.CornerRadius = UDim.new(0, 4); rBgCorner.Parent = raceBg
        local raceFill = Instance.new("Frame"); raceFill.Size = UDim2.new(0, 0, 1, 0); raceFill.BackgroundColor3 = Color3.fromRGB(170, 0, 255); raceFill.BorderSizePixel = 0; raceFill.Parent = raceBg
        local rFillCorner = Instance.new("UICorner"); rFillCorner.CornerRadius = UDim.new(0, 4); rFillCorner.Parent = raceFill

        local function UpdateBars()
            if not hum or not hum.Parent then return end
            fill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)
            
            local maxRace, currentRace = 100, 0
            local energyObj = character:FindFirstChild("Energy") or character:FindFirstChild("RaceMeter") or character:FindFirstChild("Awakening")
            if energyObj and (energyObj:IsA("NumberValue") or energyObj:IsA("IntValue")) then
                currentRace = energyObj.Value
                local maxObj = character:FindFirstChild("MaxEnergy") or character:FindFirstChild("MaxRaceMeter")
                if maxObj then maxRace = maxObj.Value else maxRace = math.max(currentRace, 100) end
            end
            raceFill.Size = UDim2.new(math.clamp(currentRace / maxRace, 0, 1), 0, 1, 0)
        end
        
        hum.HealthChanged:Connect(UpdateBars)
        RunService.RenderStepped:Connect(function() if bb and bb.Parent then pcall(UpdateBars) end end)
    end
    hum.Died:Connect(function() bb:Destroy() end)
end

local function RefreshAllHealthUI()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then CreateHealthUI(p.Character, true) end
    end
end

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.defer(function() CreateHealthUI(c, true) end) end) end)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then task.defer(function() CreateHealthUI(p.Character, true) end) p.CharacterAdded:Connect(function(c) task.defer(function() CreateHealthUI(c, true) end) end) end end

-- ==========================================
-- 3. SMOOTH & OPTIMIZED AIMBOT ENGINE
-- ==========================================

local function GetClosestTarget()
    local closestPart = nil
    local shortestDistance = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function CheckTarget(character)
        if character then
            local targetPart = character:FindFirstChild(_G.Config.TargetPart) or character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChild("Humanoid")
            
            if targetPart and hum and hum.Health > _G.Config.DisableAtHealth then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if screenDist < shortestDistance then
                        shortestDistance = screenDist
                        closestPart = targetPart
                    end
                end
            end
        end
    end

    if _G.Config.PlayerAimbot then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CheckTarget(p.Character) end end
    end

    if _G.Config.MobAimbot then
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, mob in pairs(enemiesFolder:GetChildren()) do CheckTarget(mob) end
        end
    end

    return closestPart
end

RunService.RenderStepped:Connect(function()
    if _G.Config.PlayerAimbot or _G.Config.MobAimbot then
        if lockedTargetPart and lockedTargetPart.Parent then
            local hum = lockedTargetPart.Parent:FindFirstChild("Humanoid")
            if not hum or hum.Health <= _G.Config.DisableAtHealth then lockedTargetPart = nil end
        end
        if not lockedTargetPart then lockedTargetPart = GetClosestTarget() end
        if lockedTargetPart and lockedTargetPart.Parent then
            pcall(function()
                local targetCFrame = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, tonumber(_G.Config.AimbotSmoothness) or 0.25)
            end)
        end
    else
        lockedTargetPart = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode[_G.Config.PlayerAimbotKey] then
        _G.Config.PlayerAimbot = not _G.Config.PlayerAimbot; lockedTargetPart = nil
    elseif input.KeyCode == Enum.KeyCode[_G.Config.MobAimbotKey] then
        _G.Config.MobAimbot = not _G.Config.MobAimbot; lockedTargetPart = nil
    end
end)

-- ==========================================
-- 4. GUI ENGINE
-- ==========================================

local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "PvpCombatHubUI"; ScreenGui.Parent = gethui and gethui() or CoreGui
local MainFrame = Instance.new("Frame"); MainFrame.Size = UDim2.new(0, 520, 0, 380); MainFrame.Position = UDim2.new(0.5, -260, 0.25, 0); MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner"); MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke"); MainStroke.Thickness = 1.5; MainStroke.Parent = MainFrame

local Sidebar = Instance.new("Frame"); Sidebar.Size = UDim2.new(0, 140, 1, 0); Sidebar.Parent = MainFrame
local SideCorner = Instance.new("UICorner"); SideCorner.Parent = Sidebar
local SideLayout = Instance.new("UIListLayout"); SideLayout.Padding = UDim.new(0, 6); SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideLayout.Parent = Sidebar
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Size = UDim2.new(1, 0, 0, 42); TitleLabel.Text = "⚔️ PVP COMBAT"; TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 11; TitleLabel.BackgroundTransparency = 1; TitleLabel.Parent = Sidebar

local ContentArea = Instance.new("Frame"); ContentArea.Size = UDim2.new(1, -150, 1, -10); ContentArea.Position = UDim2.new(0, 145, 0, 5); ContentArea.BackgroundTransparency = 1; ContentArea.Parent = MainFrame

local function ApplyTheme()
    local theme = Themes[_G.Config.CurrentTheme] or Themes["Cyber Dark"]
    MainFrame.BackgroundColor3 = theme.MainBg; MainStroke.Color = theme.Accent
    Sidebar.BackgroundColor3 = theme.SidebarBg; TitleLabel.TextColor3 = theme.Accent
    MainCorner.CornerRadius = UDim.new(0, theme.CornerRadius); SideCorner.CornerRadius = UDim.new(0, theme.CornerRadius)
    for _, updateFunc in ipairs(ThemeUpdateSignals) do updateFunc(theme) end
end

local tabs = {}
local function CreateTab(tabName)
    local TabBtn = Instance.new("TextButton"); TabBtn.Size = UDim2.new(0.9, 0, 0, 30); TabBtn.Text = tabName; TabBtn.Font = Enum.Font.GothamBold; TabBtn.TextSize = 9; TabBtn.Parent = Sidebar
    local BtnCorner = Instance.new("UICorner"); BtnCorner.Parent = TabBtn
    local TabPage = Instance.new("ScrollingFrame"); TabPage.Size = UDim2.new(1, 0, 1, 0); TabPage.BackgroundTransparency = 1; TabPage.Visible = false; TabPage.ScrollBarThickness = 3; TabPage.Parent = ContentArea
    local PageLayout = Instance.new("UIListLayout"); PageLayout.Padding = UDim.new(0, 6); PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; PageLayout.Parent = TabPage
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10) end)
    local function UpdateTabStyle(theme) BtnCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4)); if TabPage.Visible then TabBtn.TextColor3 = theme.Accent; TabBtn.BackgroundColor3 = theme.CardBg else TabBtn.TextColor3 = theme.SubText; TabBtn.BackgroundColor3 = theme.SidebarBg end end
    table.insert(ThemeUpdateSignals, UpdateTabStyle)
    TabBtn.MouseButton1Click:Connect(function() for _, t in pairs(tabs) do t.Page.Visible = false end; TabPage.Visible = true; ApplyTheme() end)
    table.insert(tabs, {Btn = TabBtn, Page = TabPage})
    return TabPage
end

local function AddToggle(parentPage, name, configVar, callback)
    local Button = Instance.new("TextButton"); Button.Size = UDim2.new(0.96, 0, 0, 32); Button.Text = "  " .. name; Button.Font = Enum.Font.GothamMedium; Button.TextSize = 9; Button.TextXAlignment = Enum.TextXAlignment.Left; Button.Parent = parentPage
    local BtnCorner = Instance.new("UICorner"); BtnCorner.Parent = Button
    local Indicator = Instance.new("Frame"); Indicator.Size = UDim2.new(0, 26, 0, 14); Indicator.Position = UDim2.new(1, -32, 0.5, -7); Indicator.Parent = Button
    local IndCorner = Instance.new("UICorner"); IndCorner.CornerRadius = UDim.new(0, 10); IndCorner.Parent = Indicator
    local function UpdateToggleStyle(theme) BtnCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4)); Button.BackgroundColor3 = theme.CardBg; Button.TextColor3 = _G.Config[configVar] and theme.Text or theme.SubText; Indicator.BackgroundColor3 = _G.Config[configVar] and theme.Accent or Color3.fromRGB(50, 50, 60) end
    table.insert(ThemeUpdateSignals, UpdateToggleStyle)
    Button.MouseButton1Click:Connect(function() _G.Config[configVar] = not _G.Config[configVar]; ApplyTheme(); if callback then callback() end end)
end

local function AddInput(parentPage, title, configVar, isNumber, callback)
    local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(0.96, 0, 0, 32); Frame.Parent = parentPage
    local Corner = Instance.new("UICorner"); Corner.Parent = Frame
    local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Text = "  " .. title; Label.Font = Enum.Font.GothamMedium; Label.TextSize = 9; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1; Label.Parent = Frame
    local TextBox = Instance.new("TextBox"); TextBox.Size = UDim2.new(0.4, 0, 0.7, 0); TextBox.Position = UDim2.new(0.55, 0, 0.15, 0); TextBox.Text = tostring(_G.Config[configVar]); TextBox.Font = Enum.Font.GothamBold; TextBox.TextSize = 9; TextBox.Parent = Frame
    local tbCorner = Instance.new("UICorner"); tbCorner.Parent = TextBox
    local function UpdateInputStyle(theme) Corner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 4)); tbCorner.CornerRadius = UDim.new(0, math.max(4, theme.CornerRadius - 6)); Frame.BackgroundColor3 = theme.CardBg; Label.TextColor3 = theme.Text; TextBox.BackgroundColor3 = theme.SidebarBg; TextBox.TextColor3 = theme.Accent end
    table.insert(ThemeUpdateSignals, UpdateInputStyle)
    TextBox.FocusLost:Connect(function() 
        if isNumber then
            local num = tonumber(TextBox.Text); if num then _G.Config[configVar] = num else TextBox.Text = tostring(_G.Config[configVar]) end
        else
            if TextBox.Text ~= "" then _G.Config[configVar] = TextBox.Text end
        end
        if callback then callback() end
    end)
end

-- بناء التبويبات
local CombatTab = CreateTab("⚔️ Combat")
local SettingsTab = CreateTab("🎨 Settings")
tabs[1].Page.Visible = true

-- إعدادات القتال (تم استرجاع كل الخصائص)
AddToggle(CombatTab, "Player Aimbot", "PlayerAimbot")
AddInput(CombatTab, "Player Aimbot Key", "PlayerAimbotKey", false)
AddToggle(CombatTab, "Mob Aimbot (Enemies)", "MobAimbot")
AddInput(CombatTab, "Mob Aimbot Key", "MobAimbotKey", false)
AddInput(CombatTab, "Target Part (Head/HumanoidRootPart)", "TargetPart", false)
AddInput(CombatTab, "Aimbot Smoothness", "AimbotSmoothness", true)
AddInput(CombatTab, "Stop Aimbot At Health (Max)", "DisableAtHealth", true)

-- الإعدادات العامة (تم استرجاع الثيمات)
AddToggle(SettingsTab, "Show Player/Mob Health UI", "ShowHealth", RefreshAllHealthUI)
AddInput(SettingsTab, "Hitbox Size", "HitboxSize", true)
AddInput(SettingsTab, "Theme (Cyber Dark/Midnight Purple/Emerald Neon)", "CurrentTheme", false, function() 
    if Themes[_G.Config.CurrentTheme] then ApplyTheme() end 
end)

ApplyTheme()
