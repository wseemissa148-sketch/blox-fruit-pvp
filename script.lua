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
    HitboxSize = 14, -- تم تقليل الحجم قليلاً لمنع كشف الـ Suspicious Kill

    -- إعدادات الباونتي والـ Legit Mode
    BountySafeMode = true, -- تفعيل وضع كسب الباونتي الآمن
    AutoResetHitboxOnLowHP = true, -- تصغير الـ Hitbox عندما يقترب اللاعب من الموت لضمان كسب الباونتي

    ShowHealth = true,
    HealthStyle = "Modern Card",
    PlayerHealthColor = {R = 0, G = 255, B = 150},
    MobHealthColor = {R = 255, G = 50, B = 50},

    Whitelist = {},
    TargetList = {}
}

local currentTargetPart = nil
local originalSizes = {}

-- ==========================================
-- 2. HEALTH OVERLAY ENGINE
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

    local head = character:WaitForChild("Head", 2)
    local hum = character:WaitForChild("Humanoid", 2)
    if not head or not hum then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthUIOverlay"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 140, 0, 35)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
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
            txt.Text = tag .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
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

local function HookEnemies()
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in pairs(enemies:GetChildren()) do SetupCharacterUI(mob, false) end
        enemies.ChildAdded:Connect(function(mob) SetupCharacterUI(mob, false) end)
    end
end
task.spawn(HookEnemies)

-- ==========================================
-- 3. HARD LOCK & BOUNTY SAFE AIMBOT ENGINE
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

local function GetClosestTarget(isPlayerTarget)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local closest, shortestDist = nil, math.huge

    if isPlayerTarget then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsWhitelisted(p.Name) and IsTargeted(p.Name) then
                local targetPart = p.Character:FindFirstChild(_G.Config.TargetPart) or p.Character:FindFirstChild("HumanoidRootPart")
                local pHum = p.Character:FindFirstChild("Humanoid")
                if targetPart and pHum and pHum.Health > 0 then
                    local dist = (myPos - targetPart.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = targetPart end
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
                    local dist = (myPos - targetPart.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = targetPart end
                end
            end
        end
    end
    return closest
end

-- اختيار الهدف بدقة
task.spawn(function()
    while task.wait(0.03) do
        if _G.Config.PlayerAimbot then
            currentTargetPart = GetClosestTarget(true)
        elseif _G.Config.MobAimbot then
            currentTargetPart = GetClosestTarget(false)
        else
            currentTargetPart = nil
        end
    end
end)

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

-- تثبيت الكاميرا وتعديل الـ Hitbox بأسلوب يضمن كسب الباونتي
RunService.RenderStepped:Connect(function()
    if currentTargetPart and currentTargetPart.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local targetHum = currentTargetPart.Parent:FindFirstChild("Humanoid")
            local isLowHP = targetHum and (targetHum.Health / targetHum.MaxHealth) < 0.25

            -- تثبيت الكاميرا
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentTargetPart.Position)

            -- حفظ الحجم الأصلي للـ Part للعودة إليه
            if not originalSizes[currentTargetPart] then
                originalSizes[currentTargetPart] = currentTargetPart.Size
            end

            -- إذا كان مفعل وضع الباونتي الآمن، والصحة منخفضة، يعود الـ Hitbox للحجم الطبيعي لمنع رسالة Suspicious Kill
            if _G.Config.BountySafeMode and _G.Config.AutoResetHitboxOnLowHP and isLowHP then
                currentTargetPart.Size = originalSizes[currentTargetPart] or Vector3.new(2, 2, 1)
                currentTargetPart.Transparency = 0
            else
                currentTargetPart.Size = Vector3.new(_G.Config.HitboxSize, _G.Config.HitboxSize, _G.Config.HitboxSize)
                currentTargetPart.Transparency = 0.6
            end
            
            currentTargetPart.CanCollide = false
        end)
    end
end)

-- ==========================================
-- 4. USER INTERFACE (GUI)
-- ==========================================

if CoreGui:FindFirstChild("BloxFruitsUltraHubUI") then
    CoreGui.BloxFruitsUltraHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsUltraHubUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 510, 0, 370)
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
TitleLabel.Text = "⚡ ULTRA COMBAT"
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

local function AddListManager(parentPage, title, listTable)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.96, 0, 0, 75)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 20)
    Label.Position = UDim2.new(0, 5, 0, 2)
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(0, 180, 255)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0.55, 0, 0, 24)
    TextBox.Position = UDim2.new(0.03, 0, 0.35, 0)
    TextBox.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    TextBox.Text = ""
    TextBox.PlaceholderText = "Player Name..."
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    StatusLabel.TextColor3 = Color3.fromRGB(150, 160, 175)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextSize = 8
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Parent = Frame

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
-- TABS SETUP
-- ==========================================

local CombatTab = CreateTab("⚔️ Combat & Aimbot")
local VisualsTab = CreateTab("👁️ Health & UI")

tabs[1].Page.Visible = true
tabs[1].Btn.TextColor3 = Color3.fromRGB(0, 180, 255)

-- Combat & Bounty Options
AddToggle(CombatTab, "Player Skill Aimbot", "PlayerAimbot")
AddKeybindPicker(CombatTab, "Player Aimbot Key", "PlayerAimbotKey")
AddToggle(CombatTab, "Mob Skill Aimbot", "MobAimbot")
AddKeybindPicker(CombatTab, "Mob Aimbot Key", "MobAimbotKey")

-- خيارات حماية كسب الباونتي الجديدة
AddToggle(CombatTab, "Bounty Safe-Mode (Anti-Suspicious)", "BountySafeMode")
AddToggle(CombatTab, "Reset Hitbox on Low HP (Get Bounty)", "AutoResetHitboxOnLowHP")

AddListManager(CombatTab, "🛡️ Whitelist", _G.Config.Whitelist)
AddListManager(CombatTab, "🎯 Target List", _G.Config.TargetList)

-- Visual Options
AddToggle(VisualsTab, "Show Health Overlay", "ShowHealth")
AddDropdown(VisualsTab, "Health Style", {"Modern Card", "Classic Bar", "Text Only"}, "HealthStyle")
