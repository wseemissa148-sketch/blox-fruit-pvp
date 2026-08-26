local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AimbotEnabled = false
local CurrentTarget = nil
local AimKey = Enum.UserInputType.MouseButton2 -- كليك يمين للتشغيل

-- البحث عن أقرب هدف مرة واحدة عند ضغط الزر
local function GetClosestPlayer()
    local Closest = nil
    local ShortestDistance = math.huge
    local MousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local Head = player.Character:FindFirstChild("Head")
            if Head then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Dist < ShortestDistance then
                        ShortestDistance = Dist
                        Closest = player
                    end
                end
            end
        end
    end
    return Closest
end

-- تفعيل الـ Lock عند الضغط
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == AimKey then
        AimbotEnabled = true
        CurrentTarget = GetClosestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimKey then
        AimbotEnabled = false
        CurrentTarget = nil -- فك التثبيت عند ترك الزر
    end
end)

-- تحديث الكاميرا كل فريم لتظل متصلة بالهدف (Sticky)
RunService.RenderStepped:Connect(function()
    if AimbotEnabled and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
        local Humanoid = CurrentTarget.Character:FindFirstChild("Humanoid")
        if Humanoid and Humanoid.Health > 0 then
            -- التوجيه المباشر نحو الرأس (Sticky / Instant Lock)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentTarget.Character.Head.Position)
        else
            CurrentTarget = nil -- إذا مات اللاعب ابحث عن غيره أو افصل
        end
    end
end)
