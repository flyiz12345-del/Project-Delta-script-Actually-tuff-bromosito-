-- // 1. CORE COMPATIBILITY \\ --
local Drawing = Drawing or {}
local function Draw(obj)
    local success, item = pcall(function() return Drawing.new(obj) end)
    return success and item or {Visible = false, Remove = function() end, Position = Vector2.new(), Color = Color3.new(1,1,1), Thickness = 1}
end

-- // 2. PHYSICS & BALLISTICS DATA \\ --
_G.LT = nil; _G.LT_Vel, _G.LT_Drag = 900, 0.001
O = {
    Combat = {S_A = true, AimBot = true, S_A_Auto = true, S_A_WB = true, I_H = false},
    Vis = {E = true, Bx = true, Info = true, Chams = true, ShowFOV = true, FOVSize = 100},
    Settings = {UI_Visible = true}
}
local Ballistics = {
    ["338"] = {AP = 1015, T = 992, D = 0.0008}, ["5.56"] = {AP = 1000, T = 933, D = 0.0012},
    ["762x54"] = {AP = 940, T = 885, D = 0.0010}, ["7.62x51"] = {AP = 900, T = 820, D = 0.0011},
    ["7.62x39"] = {AP = 767, T = 715, D = 0.0015}, ["9x39"] = {AP = 357, CQB = 450, D = 0.0035},
    ["12ga"] = {AP = 625, B = 425, D = 0.0045}
}
local Hardness = {[Enum.Material.Wood]=1.2, [Enum.Material.Concrete]=4.5, [Enum.Material.Metal]=8.5}

-- // 3. UNDETECTED PENETRATION LOGIC \\ --
local function CheckPenetration(origin, direction, char)
    local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {game.Players.LocalPlayer.Character, workspace.CurrentCamera}
    local cur, energy, hits = origin, _G.LT_Vel, 0
    while hits < 3 do
        local res = workspace:Raycast(cur, direction, p)
        if not res or res.Instance:IsDescendantOf(char) then return true, energy end
        if not O.Combat.S_A_WB then break end
        local h = Hardness[res.Instance.Material] or 2.0
        energy = energy - (h * 50); hits = hits + 1
        if energy < (_G.LT_Vel * 0.15) then break end
        local f = p.FilterDescendantsInstances; table.insert(f, res.Instance); p.FilterDescendantsInstances = f
        cur = res.Position + (direction.Unit * 0.05)
    end
    return false, 0
end

-- // 4. SILENT AIM HOOK \\ --
local mt = getrawmetatable(game); setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method, args = getnamecallmethod(), {...}
    if not checkcaller() and O.Combat.S_A and _G.LT and (method == "Raycast" or method == "FindPartOnRay") then
        local tPos, origin = _G.LT.Position, (method == "Raycast" and args[1] or args[1].Origin)
        local canHit, eLeft = CheckPenetration(origin, (tPos - origin), _G.LT.Parent)
        if canHit then
            local dist = (tPos - origin).Magnitude
            local t = dist / eLeft
            local hrp = _G.LT.Parent:FindFirstChild("HumanoidRootPart")
            if hrp and not O.Combat.I_H then
                tPos = tPos + (hrp.AssemblyLinearVelocity * t)
                tPos = tPos + Vector3.new(0, (0.5 * workspace.Gravity * (t^2)) * (1 + (dist * _G.LT_Drag)), 0)
            end
            if method == "Raycast" then args[2] = (tPos - origin).Unit * 5000 else args[1] = Ray.new(origin, (tPos-origin).Unit * 5000) end
        end
        return old(self, unpack(args))
    end
    return old(self, ...)
end)
setreadonly(mt, true)
local LP, Cam = game:GetService("Players").LocalPlayer, workspace.CurrentCamera
local last_s, next_d, VisibilityCache = 0, 0.1, {}
local TargetLine = Draw("Line"); TargetLine.Color = Color3.fromRGB(138, 43, 226)

-- // TELEPORT FUNCTION (Rage) \\ --
local function TeleportToTarget()
    if _G.LT and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = _G.LT.Parent:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            -- TPs 5 studs behind the target to avoid detection/instant death
            LP.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
        end
    end
end

-- // MAIN LOOP \\ --
game:GetService("RunService").RenderStepped:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    
    -- TARGET SELECTOR
    local closest, maxD = nil, O.Vis.FOVSize
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local pos, on = Cam:WorldToViewportPoint(head.Position)
            if on then
                local m = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if m < maxD then
                    local can, e = CheckPenetration(Cam.CFrame.Position, (head.Position - Cam.CFrame.Position), p.Character)
                    VisibilityCache[p.Name] = {Can = can, E = e}
                    if can then maxD, closest = m, head end
                end
            end
        end
    end
    _G.LT = closest
        local LP, Cam = game:GetService("Players").LocalPlayer, workspace.CurrentCamera
local last_s, next_d, VisibilityCache = 0, 0.1, {}
local TargetLine = Draw("Line"); TargetLine.Color = Color3.fromRGB(138, 43, 226)

-- // TELEPORT FUNCTION (Rage) \\ --
local function TeleportToTarget()
    if _G.LT and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = _G.LT.Parent:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            -- TPs 5 studs behind the target to avoid detection/instant death
            LP.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
        end
    end
end

-- // MAIN LOOP \\ --
game:GetService("RunService").RenderStepped:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    
    -- TARGET SELECTOR
    local closest, maxD = nil, O.Vis.FOVSize
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local pos, on = Cam:WorldToViewportPoint(head.Position)
            if on then
                local m = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if m < maxD then
                    local can, e = CheckPenetration(Cam.CFrame.Position, (head.Position - Cam.CFrame.Position), p.Character)
                    VisibilityCache[p.Name] = {Can = can, E = e}
                    if can then maxD, closest = m, head end
                end
            end
        end
    end
    _G.LT = closest

    -- AIMBOT & AUTOSHOOT
    if _G.LT then
        if O.Combat.AimBot then
            local shake = Vector3.new(math.noise(tick()*3,1), math.noise(1,tick()*3), 0) * 0.04
            Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, _G.LT.Position + shake), 0.08)
        end
        if O.Combat.S_A_Auto and (tick() - last_s > next_d) then
            last_s, next_d = tick(), math.random(8,14)/100
            local t = LP.Character:FindFirstChildOfClass("Tool"); if t then t:Activate() end
        end
        local tPos = Cam:WorldToViewportPoint(_G.LT.Position)
        TargetLine.Visible, TargetLine.From, TargetLine.To = true, center, Vector2.new(tPos.X, tPos.Y)
    else TargetLine.Visible = false end
end)

    -- AIMBOT & AUTOSHOOT
    if _G.LT then
        if O.Combat.AimBot then
            local shake = Vector3.new(math.noise(tick()*3,1), math.noise(1,tick()*3), 0) * 0.04
            Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, _G.LT.Position + shake), 0.08)
        end
        if O.Combat.S_A_Auto and (tick() - last_s > next_d) then
            last_s, next_d = tick(), math.random(8,14)/100
            local t = LP.Character:FindFirstChildOfClass("Tool"); if t then t:Activate() end
        end
        local tPos = Cam:WorldToViewportPoint(_G.LT.Position)
        TargetLine.Visible, TargetLine.From, TargetLine.To = true, center, Vector2.new(tPos.X, tPos.Y)
    else TargetLine.Visible = false end
end)
local Core = LP.PlayerGui:FindFirstChild("DeltaHUD") or Instance.new("ScreenGui", LP.PlayerGui)
Core.Name = "DeltaHUD"

-- MASTER HUD (Fixed Position - Non-Draggable)
local HUD = Instance.new("Frame", Core)
HUD.Size, HUD.Position = UDim2.new(0, 220, 0, 300), UDim2.new(0, 20, 0.5, -150)
HUD.BackgroundColor3 = Color3.fromRGB(15, 15, 20); HUD.BorderSizePixel = 0
Instance.new("UICorner", HUD).CornerRadius = UDim.new(0, 4)

-- PURPLE GLOW
local G = Instance.new("ImageLabel", HUD)
G.Size, G.Position = UDim2.new(1, 40, 1, 40), UDim2.new(0, -20, 0, -20)
G.BackgroundTransparency, G.Image = 1, "rbxassetid://1316045217"
G.ImageColor3, G.ImageTransparency, G.ZIndex = Color3.fromRGB(138, 43, 226), 0.6, 0

-- TITLE
local T = Instance.new("TextLabel", HUD)
T.Text = "PROJECT DELTA | ELITE"; T.Size = UDim2.new(1, 0, 0, 30)
T.TextColor3, T.Font, T.TextSize = Color3.fromRGB(138, 43, 226), Enum.Font.GothamBold, 12
T.BackgroundColor3 = Color3.fromRGB(25, 25, 30); T.BorderSizePixel = 0

-- STATUS LIST
local List = Instance.new("UIListLayout", HUD); List.Padding = UDim.new(0, 5)

local function AddStatus(text, var_path)
    local l = Instance.new("TextLabel", HUD)
    l.Size = UDim2.new(1, -20, 0, 20); l.Text = " > " .. text .. ": [ACTIVE]"
    l.TextColor3, l.Font, l.TextSize = Color3.new(0.8,0.8,0.8), Enum.Font.Gotham, 11
    l.BackgroundTransparency, l.TextXAlignment = 1, "Left"
end

AddStatus("SILENT AIM", "S_A")
AddStatus("WALLBANG", "S_A_WB")
AddStatus("BULLET CALC", "CALC")

-- // PROFESSIONAL ACTION BUTTONS \\ --
local ButtonFrame = Instance.new("Frame", HUD)
ButtonFrame.Size, ButtonFrame.Position = UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 1, -90)
ButtonFrame.BackgroundTransparency = 1

local function CreateBtn(text, pos, color, callback)
    local b = Instance.new("TextButton", ButtonFrame)
    b.Size, b.Position = UDim2.new(0.9, 0, 0, 30), pos
    b.BackgroundColor3, b.Text = color, text
    b.TextColor3, b.Font, b.TextSize = Color3.new(1,1,1), Enum.Font.GothamBold, 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(callback)
end

-- TELEPORT BUTTON
CreateBtn("TELEPORT TO TARGET", UDim2.new(0.05, 0, 0, 0), Color3.fromRGB(80, 30, 150), function()
    TeleportToTarget()
end)

-- UI TOGGLE (In the corner of the screen)
local ToggleBtn = Instance.new("TextButton", Core)
ToggleBtn.Size, ToggleBtn.Position = UDim2.new(0, 40, 0, 40), UDim2.new(1, -50, 1, -50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleBtn.Text = "HUD"; ToggleBtn.TextColor3 = Color3.fromRGB(138, 43, 226)
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
ToggleBtn.MouseButton1Click:Connect(function()
    HUD.Visible = not HUD.Visible
end)

print("6777 HUD Loaded. Non-Draggable.")
