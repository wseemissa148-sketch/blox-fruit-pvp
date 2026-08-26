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
    -- Aimbot Modes
    NormalAimbot = false,
    NormalAimbotKey = "E",

    TargetLock = false,
    TargetLockKey = "G",

    -- Settings
    Smoothness = 0.35,
    TargetPart = "Head",
    HitboxSize = 15,

    -- Visuals & Colors
    ShowHealth = true,
    HealthStyle = "Modern Card",
    PlayerHealthColor = {R = 0, G = 255, B = 150},
    TargetColor = {R = 170, G = 0, B = 255}, -- اللون البنفسجي المخصص للهدف المثبت

    Whitelist = {},
    TargetList = {}
}

local lockedTargetPart = nil
local lockedTargetChar = nil
local originalPartProperties = {}

-- ==========================================
-- 2. HEALTH OVERLAY ENGINE (إعادة الألوان)
-- ==========================================

local function RemoveHealthUI(character)
    if character and character:FindFirstChild("Head") then
        local gui = character.Head:FindFirstChild("HealthUIOverlay")
        if gui then gui:Destroy() end
    end
end

local function CreateHealthUI(character)
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

    local col = _G.Config.PlayerHealthColor
    local mainColor = Color3.fromRGB(col.R, col.G, col.B)

    if _G.Config.HealthStyle == "Modern Card" then
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
        title.Text = "⚔️ PVP: " .. character.Name
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
    end

    hum.Died:Connect(function() bb:Destroy() end)
end

local function SetupCharacterUI(char)
    if char then task.defer(function() CreateHealthUI(char) end) end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        if p.Character then SetupCharacterUI(p.Character) end
        p.CharacterAdded:Connect(function(c) SetupCharacterUI(c) end)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) SetupCharacterUI(c) end)
end)

-- ==========================================
-- 3. STICKY AIMBOT & LOCK-ON ENGINE
-- ==========================================

local function IsWhitelisted(name)
    for _, v in ipairs(_G.Config.Whitelist) do
        if v:lower() == name:lower() then return true end
    end
    return false
end

local function ResetPreviousHitbox()
    if lockedTargetPart and originalPartProperties[lockedTargetPart] then
        pcall(function()
            lockedTargetPart.Size = originalPartProperties[lockedTargetPart].Size
            lockedTargetPart.Transparency = originalPartProperties[lockedTargetPart].Transparency
            lockedTargetPart.Color = originalPartProperties[lockedTargetPart].Color
        end)
    end
    lockedTargetPart = nil
    lockedTargetChar = nil
end

local function GetClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, shortestDist = nil, math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not IsWhitelisted(p.Name) then
            local part = p.Character:FindFirstChild(_G.Config.TargetPart) or p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = {Part = part, Char = p.Character}
                    end
                end
            end
        end
    end
    return closest
end

-- التحكم بالأزرار (Keybind Handling)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    pcall(function()
        -- 1. زر الأيم بوت (Normal Sticky Aimbot)
        if input.KeyCode == Enum.KeyCode[_G.Config.NormalAimbotKey] then
            _G.Config.NormalAimbot = not _G.Config.NormalAimbot
            _G.Config.TargetLock = false
            
            if _G.Config.NormalAimbot then
                local target = GetClosestTarget()
                if target then
                    ResetPreviousHitbox()
                    lockedTargetPart = target.Part
                    lockedTargetChar = target.Char
                else
                    _G.Config.NormalAimbot = false
                end
            else
                ResetPreviousHitbox()
            end

        -- 2. زر التثبيت اليدوي (Target Lock)
        elseif input.KeyCode == Enum.KeyCode[_G.Config.TargetLockKey] then
            _G.Config.TargetLock = not _G.Config.TargetLock
            _G.Config.NormalAimbot = false

            if _G.Config.TargetLock then
                local target = GetClosestTarget()
                if target then
                    ResetPreviousHitbox()
                    lockedTargetPart = target.Part
                    lockedTargetChar = target.Char
                    originalPartProperties[lockedTargetPart] = {
                        Size = lockedTargetPart.Size,
                        Transparency = lockedTargetPart.Transparency,
                        Color = lockedTargetPart.Color
                    }
                else
                    _G.Config.TargetLock = false
                end
            else
                ResetPreviousHitbox()
            end
        end
    end)
end)

-- حلقة التثبيت المستمر وتكبير الـ Hitbox
RunService.RenderStepped:Connect(function()
    if (_G.Config.NormalAimbot or _G.Config.TargetLock) and lockedTargetPart and lockedTargetChar then
        local hum = lockedTargetChar:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            pcall(function()
                -- توجيه الكاميرا بسلاسة
                local targetCFrame = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.Config.Smoothness)

                -- تكبير الـ Hitbox وتغيير لونه (في وضع Target Lock)
                if _G.Config.TargetLock then
                    local tc = _G.Config.TargetColor
                    lockedTargetPart.Size = Vector3.new(_G.Config.HitboxSize, _G.Config.HitboxSize, _G.Config.HitboxSize)
                    lockedTargetPart.Color = Color3.fromRGB(tc.R, tc.G, tc.B)
                    lockedTargetPart.Transparency = 0.5
                    lockedTargetPart.CanCollide = false
                end
            end)
        else
            -- إلغاء التثبيت فور موت اللاعب
            _G.Config.NormalAimbot = false
            _G.Config.TargetLock = false
            ResetPreviousHitbox()
        end
    end
end)

-- ==========================================
-- 4. USER INTERFACE (PVP GUI)
-- ==========================================

if CoreGui:FindFirstChild("PvpUltraHubUI") then
    CoreGui.PvpUltraHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PvpUltraHubUI"
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
MainStroke.Color = Color3.fromRGB(255, 45, 85)
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
TitleLabel.Size = UDim2.new(1, 0, 0, 45)
TitleLabel.Text = "⚔️ PVP ULTRA"
TitleLabel.TextColor3 = Color3.fromRGB(255, 45, 85)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, -10)
ContentArea.Position = UDim2.new(0, 145, 0, 5)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 32)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.05, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 21, 32)
ToggleBtn.Text = "⚔️ PVP MENU"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 45, 85)
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
        TabBtn.TextColor3 = Color3.fromRGB(255, 45, 85)
        TabBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 38)
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
    Indicator.BackgroundColor3 = _G.Config[configVar] and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(45, 50, 65)
    Indicator.Parent = Button

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 10)
    IndCorner.Parent = Indicator

    Button.MouseButton1Click:Connect(function()
        _G.Config[configVar] = not _G.Config[configVar]
        if not _G.Config[configVar] then ResetPreviousHitbox() end
        Indicator.BackgroundColor3 = _G.Config[configVar] and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(45, 50, 65)
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
    BindBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 38)
    BindBtn.Text = "[" .. tostring(_G.Config[configVar]) .. "]"
    BindBtn.TextColor3 = Color3.fromRGB(255, 45, 85)
    BindBtn.Font = Enum.Font.GothamBold
    BindBtn.TextSize = 9
    BindBtn.Parent = Frame

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

local function AddColorPicker(parentPage, title, configVar)
    local colors = {
        ["Purple 💜"] = {R = 170, G = 0, B = 255},
        ["Cyan 🩵"]   = {R = 0, G = 225, B = 255},
        ["Red 🔴"]    = {R = 255, G = 40, B = 40},
        ["Green 🟢"]  = {R = 0, G = 255, B = 100},
        ["Yellow 🟡"] = {R = 255, G = 220, B = 0}
    }
    local colorNames = {"Purple 💜", "Cyan 🩵", "Red 🔴", "Green 🟢", "Yellow 🟡"}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.96, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    Frame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Text = "  " .. title
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(0.45, 0, 0.7, 0)
    DropBtn.Position = UDim2.new(0.52, 0, 0.15, 0)
    DropBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 68)
    DropBtn.Text = "Purple 💜"
    DropBtn.TextColor3 = Color3.fromRGB(170, 0, 255)
    DropBtn.Font = Enum.Font.GothamBold
    DropBtn.TextSize = 8
    DropBtn.Parent = Frame

    local idx = 1
    DropBtn.MouseButton1Click:Connect(function()
        idx = (idx % #colorNames) + 1
        local selectedName = colorNames[idx]
        _G.Config[configVar] = colors[selectedName]
        DropBtn.Text = selectedName
        local c = colors[selectedName]
        DropBtn.TextColor3 = Color3.fromRGB(c.R, c.G, c.B)
    end)
end

-- ==========================================
-- TABS SETUP
-- ==========================================

local CombatTab = CreateTab("⚔️ PVP Controls")
local VisualsTab = CreateTab("👁️ Health & Colors")

tabs[1].Page.Visible = true
tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 45, 85)

-- PVP Controls
AddToggle(CombatTab, "Normal Aimbot (Sticky)", "NormalAimbot")
AddKeybindPicker(CombatTab, "Aimbot Key", "NormalAimbotKey")

AddToggle(CombatTab, "Target Lock (Manual)", "TargetLock")
AddKeybindPicker(CombatTab, "Target Lock Key", "TargetLockKey")

-- Visuals & Colors
AddToggle(VisualsTab, "Show PVP Health Bar", "ShowHealth")
AddColorPicker(VisualsTab, "Target Hitbox Color", "TargetColor")
AddColorPicker(VisualsTab, "Player Health Color", "PlayerHealthColor")
