local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- 1. نظام الإعدادات (سريع ومخفف)
-- ==========================================

_G.Config = {
    PlayerAimbot = false,
    PlayerAimbotKey = "G",
    MobAimbot = false,
    MobAimbotKey = "H",
    ShowHealth = true,
    PlayerHealthColor = {R = 0, G = 255, B = 150},
    MobHealthColor = {R = 255, G = 50, B = 50}
}

-- ==========================================
-- 2. نظام عرض الصحة الخفيف (بدون مسافة)
-- ==========================================

local function CreateHealthUI(character, isPlayer)
    if not character or character:FindFirstChild("HealthUIOverlay") then return end
    local head = character:WaitForChild("Head", 2)
    local hum = character:WaitForChild("Humanoid", 2)
    if not head or not hum then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthUIOverlay"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 140, 0, 22)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local txt = Instance.new("TextLabel")
    txt.Name = "Label"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 10
    txt.TextStrokeTransparency = 0.3
    txt.Parent = bb

    local function UpdateText()
        if not hum or not hum.Parent then return end
        local col = isPlayer and _G.Config.PlayerHealthColor or _G.Config.MobHealthColor
        txt.TextColor3 = Color3.fromRGB(col.R, col.G, col.B)
        local tag = isPlayer and "👤 " or "👾 "
        txt.Text = tag .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
    end

    UpdateText()
    local conn = hum.HealthChanged:Connect(UpdateText)

    hum.Died:Connect(function()
        conn:Disconnect()
        bb:Destroy()
    end)
end

task.spawn(function()
    while true do
        task.wait(2)
        if _G.Config.ShowHealth then
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, mob in pairs(enemies:GetChildren()) do CreateHealthUI(mob, false) end
            end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then CreateHealthUI(p.Character, true) end
            end
        end
    end
end)

-- ==========================================
-- 3. محرك Aimbot خفيف الوزن
-- ==========================================

local function GetClosestTarget(isPlayerTarget)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local closest, shortestDist = nil, math.huge

    if isPlayerTarget then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local pHum = p.Character:FindFirstChild("Humanoid")
                if pHrp and pHum and pHum.Health > 0 then
                    local dist = (myPos - pHrp.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = pHrp end
                end
            end
        end
    else
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in pairs(enemies:GetChildren()) do
                local mHrp = mob:FindFirstChild("HumanoidRootPart")
                local mHum = mob:FindFirstChild("Humanoid")
                if mHrp and mHum and mHum.Health > 0 then
                    local dist = (myPos - mHrp.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = mHrp end
                end
            end
        end
    end
    return closest
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    pcall(function()
        if input.KeyCode == Enum.KeyCode[_G.Config.PlayerAimbotKey] then
            _G.Config.PlayerAimbot = not _G.Config.PlayerAimbot
        elseif input.KeyCode == Enum.KeyCode[_G.Config.MobAimbotKey] then
            _G.Config.MobAimbot = not _G.Config.MobAimbot
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    local targetHrp = nil
    if _G.Config.PlayerAimbot then
        targetHrp = GetClosestTarget(true)
    elseif _G.Config.MobAimbot then
        targetHrp = GetClosestTarget(false)
    end

    if targetHrp and player.Character and player.Character:FindFirstChildOfClass("Tool") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHrp.Position)
    end
end)

-- ==========================================
-- 4. واجهة المستخدم (UI)
-- ==========================================

if CoreGui:FindFirstChild("BloxFruitsUltraHubUI") then
    CoreGui.BloxFruitsUltraHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsUltraHubUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 490, 0, 320)
MainFrame.Position = UDim2.new(0.5, -245, 0.25, 0)
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
Sidebar.Size = UDim2.new(0, 135, 1, 0)
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
TitleLabel.Text = "⚡ ULTRA COMBAT"
TitleLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -145, 1, -10)
ContentArea.Position = UDim2.new(0, 140, 0, 5)
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
        BindBtn.Text = "[ Press Key... ]"
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

local function AddColorPicker(parentPage, title, configKey)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.96, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Text = "  " .. title
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local colorList = {
        {Name = "Green", Color = {R = 0, G = 255, B = 150}},
        {Name = "Red", Color = {R = 255, G = 50, B = 50}},
        {Name = "Cyan", Color = {R = 0, G = 180, B = 255}},
        {Name = "Yellow", Color = {R = 255, G = 220, B = 0}},
        {Name = "Purple", Color = {R = 180, G = 50, B = 255}},
        {Name = "White", Color = {R = 255, G = 255, B = 255}}
    }

    local ColorBtn = Instance.new("TextButton")
    ColorBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
    ColorBtn.Position = UDim2.new(0.62, 0, 0.15, 0)
    local cur = _G.Config[configKey]
    ColorBtn.BackgroundColor3 = Color3.fromRGB(cur.R, cur.G, cur.B)
    ColorBtn.Text = "Change"
    ColorBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    ColorBtn.Font = Enum.Font.GothamBold
    ColorBtn.TextSize = 8
    ColorBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = ColorBtn

    local colorIdx = 1
    ColorBtn.MouseButton1Click:Connect(function()
        colorIdx = (colorIdx % #colorList) + 1
        local selected = colorList[colorIdx]
        _G.Config[configKey] = selected.Color
        ColorBtn.BackgroundColor3 = Color3.fromRGB(selected.Color.R, selected.Color.G, selected.Color.B)
    end)
end

-- بناء الأقسام
local CombatTab = CreateTab("⚔️ Combat & Aimbot")
local VisualsTab = CreateTab("👁️ Health & Colors")

tabs[1].Page.Visible = true
tabs[1].Btn.TextColor3 = Color3.fromRGB(0, 180, 255)

-- عناصر قسم Combat
AddToggle(CombatTab, "Player Skill Aimbot", "PlayerAimbot")
AddKeybindPicker(CombatTab, "Player Aimbot Key", "PlayerAimbotKey")
AddToggle(CombatTab, "Mob Skill Aimbot", "MobAimbot")
AddKeybindPicker(CombatTab, "Mob Aimbot Key", "MobAimbotKey")

-- عناصر قسم Visuals
AddToggle(VisualsTab, "Show Health Above Head", "ShowHealth")
AddColorPicker(VisualsTab, "Player Health Color", "PlayerHealthColor")
AddColorPicker(VisualsTab, "Mob Health Color", "MobHealthColor")
