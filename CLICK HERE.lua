-- // CORE SETUP \\ --
local Drawing = Drawing or {}
local function Draw(obj)
    local success, item = pcall(function() return Drawing.new(obj) end)
    return success and item or {Visible = false, Remove = function() end}
end

-- // 1. COMPREHENSIVE CALIBER & WEAPON DATABASE \\ --
local WeaponRegistry = {
    ["M4A1"] = "5.56", ["ADAR"] = "5.56", ["M249"] = "5.56", ["AKMN"] = "7.62x39", ["AKM"] = "7.62x39",
    ["AS VAL"] = "9x39", ["VSS"] = "9x39", ["R700"] = "7.62x51", ["MOSIN"] = "762x54", ["SVD"] = "762x54",
    ["PKM"] = "762x54", ["TFZ MOD-98"] = "338", ["MP5"] = "9x19", ["PPSH"] = "7.62x25", ["VECTOR"] = "45",
    ["SAIGA"] = "12ga", ["IZH-81"] = "12ga", ["MAKAROV"] = "9x18", ["TT-33"] = "7.62x25", ["MK23"] = "45"
}

local Ballistics = {
    ["338"] = {AP = 1015, T = 992, D = 0.0007},   ["5.56"] = {AP = 1000, T = 933, D = 0.0011},
    ["762x54"] = {AP = 940, T = 885, D = 0.0009}, ["7.62x51"] = {AP = 900, T = 820, D = 0.0010},
    ["7.62x39"] = {AP = 767, T = 715, D = 0.0014}, ["12ga"] = {AP = 625, B = 425, D = 0.0040},
    ["45"] = {AP = 515, T = 465, D = 0.0022},      ["9x19"] = {AP = 500, T = 465, D = 0.0026},
    ["7.62x25"] = {AP = 484, T = 460, D = 0.0028}, ["9x39"] = {AP = 357, CQB = 450, D = 0.0045},
    ["9x18"] = {AP = 359, CQB = 404, D = 0.0042}
}

-- GLOBAL STATE
_G.LT = nil; _G.LT_Vel, _G.LT_Drag = 900, 0.001
O = { Combat = {S_A = true, AimBot = true, S_A_Auto = true, S_A_WB = true, I_H = false, N_R = true},
      Vis = {E = true, Bx = true, Info = true, Chams = true, ShowFOV = true, FOVSize = 100},
      Local = {ModArm = true, ArmMat = "ForceField", ArmColor = Color3.fromRGB(138,43,226), ArmTrans = 0.5}}
Colors = {Main = Color3.fromRGB(138,43,226), Good = Color3.fromRGB(0,255,0), Bad = Color3.fromRGB(255,0,0)}

-- BALLISTICS CALIBRATOR
local function UpdateBallistics(tool)
    if not tool then return end
    local n, cal = tool.Name:upper(), nil
    for model, caliber in pairs(WeaponRegistry) do if n:find(model) then cal = caliber break end end
    if not cal then if n:find("5.56") then cal = "5.56" elseif n:find("7.62") then cal = "762x39" end end
    if cal and Ballistics[cal] then
        local data = Ballistics[cal]
        _G.LT_Drag = data.D
        if n:find("AP") or n:find("SLUG") then _G.LT_Vel = data.AP
        elseif n:find("T") or n:find("TRACER") then _G.LT_Vel = data.T or data.AP
        elseif n:find("CQB") then _G.LT_Vel = data.CQB or data.AP
        else _G.LT_Vel = data.AP end
    end
end

-- SILENT AIM HOOK
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method, args = getnamecallmethod(), {...}
    if not checkcaller() and O.Combat.S_A and _G.LT and (method == "Raycast" or method == "FindPartOnRay") then
        local tPos, origin = _G.LT.Position, (method == "Raycast" and args[1] or args[1].Origin)
        if O.Combat.I_H then -- INSTA HIT LOGIC
            local newDir = (tPos - origin).Unit * 5000
            if method == "Raycast" then args[2] = newDir else args[1] = Ray.new(origin, newDir) end
        else -- BULLET CALCULATOR LOGIC
            local dist = (tPos - origin).Magnitude
            local time = dist / _G.LT_Vel
            local hrp = _G.LT.Parent:FindFirstChild("HumanoidRootPart")
            if hrp then
                tPos = tPos + (hrp.AssemblyLinearVelocity * time)
                -- 500 m/s Rule: Increase drop factor for slow rounds
                local dropFactor = (_G.LT_Vel < 500) and 1.8 or 1.0
                local drop = (0.5 * workspace.Gravity * (time^2)) * (1 + (dist * _G.LT_Drag * dropFactor))
                tPos = tPos + Vector3.new(0, drop, 0)
            end
            local newDir = (tPos - origin).Unit * 5000
            if method == "Raycast" then args[2] = newDir else args[1] = Ray.new(origin, newDir) end
        end
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)
local P, R = game:GetService("Players"), game:GetService("RunService")
local LP, Cam = P.LocalPlayer, workspace.CurrentCamera
local TargetLine, FOV_Circle = Draw("Line"), Draw("Circle")
TargetLine.Thickness, TargetLine.Color = 1, Colors.Main
FOV_Circle.Thickness, FOV_Circle.Filled = 1, false
local last_shoot, next_delay, VisibilityCache, D_T = 0, 0.1, {}, {}

-- WALLBANG & VISIBILITY
local p_params = RaycastParams.new()
p_params.FilterType, p_params.IgnoreWater = Enum.RaycastFilterType.Exclude, true
local function GetVisibility(char)
    if not char:FindFirstChild("Head") then return false end
    p_params.FilterDescendantsInstances = {LP.Character, Cam}
    local origin, dir, hits = Cam.CFrame.Position, (char.Head.Position - Cam.CFrame.Position), 0
    while hits < 3 do -- Max 3 walls for Rage Wallbang
        local res = workspace:Raycast(origin, dir, p_params)
        if not res or res.Instance:IsDescendantOf(char) then return true end
        if O.Combat.S_A_WB then
            local f = p_params.FilterDescendantsInstances; table.insert(f, res.Instance); p_params.FilterDescendantsInstances = f
            origin = res.Position + (dir.Unit * 0.05); hits = hits + 1
        else break end
    end
    return false
end

-- MAIN EXECUTION LOOP
R.RenderStepped:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if tool then UpdateBallistics(tool) end

    -- TARGETING
    local closest, maxD = nil, O.Vis.FOVSize
    for _, p in pairs(P:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, on = Cam:WorldToViewportPoint(head.Position)
                if on then
                    local m = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if m < maxD then
                        local vis = GetVisibility(p.Character)
                        VisibilityCache[p.Name] = vis
                        if vis then maxD, closest = m, head end
                    end
                end
            end
        end
    end
    _G.LT = closest

    -- RAGE EXECUTION
    if _G.LT then
        if O.Combat.AimBot then
            local targetCF = CFrame.new(Cam.CFrame.Position, _G.LT.Position)
            if O.Combat.I_H then Cam.CFrame = targetCF else -- Insta-hit snap
                local shake = Vector3.new(math.noise(tick()*3,1), math.noise(1,tick()*3), 0) * 0.04
                Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, _G.LT.Position + shake), 0.08)
            end
        end
        if O.Combat.S_A_Auto and (tick() - last_shoot > next_delay) and tool then
            last_shoot, next_delay = tick(), math.random(8,14)/100; tool:Activate()
        end
    end

    -- LOCAL MODIFIERS
    if O.Local.ModArm and LP.Character then
        for _, v in pairs(LP.Character:GetChildren()) do
            if v:IsA("BasePart") and (v.Name:find("Arm") or v.Name:find("Hand")) then
                v.Transparency, v.Color, v.Material = O.Local.ArmTrans, O.Local.ArmColor, Enum.Material[O.Local.ArmMat]
            end
        end
    end

    FOV_Circle.Visible, FOV_Circle.Radius, FOV_Circle.Position = O.Vis.ShowFOV, O.Vis.FOVSize, center
end)
local UIS = game:GetService("UserInputService")
local Core = LP.PlayerGui:FindFirstChild("DeltaSuite") or Instance.new("ScreenGui", LP.PlayerGui)
Core.Name = "DeltaSuite"

local Main = Instance.new("Frame", Core)
Main.Size, Main.Position = UDim2.new(0, 550, 0, 420), UDim2.new(0.5, -275, 0.5, -210)
Main.BackgroundColor3, Main.BorderSizePixel = Color3.fromRGB(18, 18, 22), 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 4)

-- NEON GLOW (Matching image_1.png)
local Glow = Instance.new("ImageLabel", Main)
Glow.Size, Glow.Position = UDim2.new(1, 60, 1, 60), UDim2.new(0, -30, 0, -30)
Glow.BackgroundTransparency, Glow.Image = 1, "rbxassetid://1316045217"
Glow.ImageColor3, Glow.ImageTransparency, Glow.ZIndex = Colors.Main, 0.5, 0

-- TABS
local TabBar = Instance.new("Frame", Main)
TabBar.Size, TabBar.BackgroundColor3 = UDim2.new(1, 0, 0, 35), Color3.fromRGB(25, 25, 30)
local Tabs = {"main", "visual", "local visual", "misc", "settings"}
for i, name in pairs(Tabs) do
    local t = Instance.new("TextButton", TabBar)
    t.Size, t.Position = UDim2.new(0.2, 0, 1, 0), UDim2.new((i-1)*0.2, 0, 0, 0)
    t.Text, t.TextColor3, t.BackgroundTransparency = name, (name == "local visual" and Colors.Main or Color3.new(0.7,0.7,0.7)), 1
    t.Font, t.TextSize = Enum.Font.GothamMedium, 11
end

-- SECTIONS (Replicating Image 1 layout)
local function Section(name, pos, size)
    local s = Instance.new("Frame", Main)
    s.Position, s.Size = pos, size
    s.BackgroundColor3, s.BackgroundTransparency = Color3.new(0,0,0), 0.95
    local l = Instance.new("TextLabel", s)
    l.Text, l.Size = "  " .. name, UDim2.new(1, 0, 0, 20)
    l.TextColor3, l.Font, l.TextXAlignment = Colors.Main, Enum.Font.GothamBold, "Left"
    l.BackgroundTransparency = 1; return s
end

local ItemChanger = Section("item changers", UDim2.new(0, 15, 0, 50), UDim2.new(0.46, 0, 0.42, 0))
local ArmESP = Section("local arm esp", UDim2.new(0.52, 0, 0, 50), UDim2.new(0.46, 0, 0.42, 0))
local ItemESP = Section("local item esp", UDim2.new(0, 15, 0, 235), UDim2.new(0.46, 0, 0.42, 0))

-- TOGGLE FACTORY
local function Toggle(parent, text, var_path, offset_y)
    local f = Instance.new("Frame", parent); f.Size, f.Position = UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, offset_y)
    f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 14, 0, 14)
    b.Position = UDim2.new(0, 10, 0, 5); b.Text = ""
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    local l = Instance.new("TextLabel", f); l.Text = text; l.Position = UDim2.new(0, 32, 0, 0)
    l.Size, l.BackgroundTransparency, l.TextColor3 = UDim2.new(1, -35, 1, 0), 1, Color3.new(0.8,0.8,0.8)
    l.TextXAlignment, l.Font, l.TextSize = "Left", Enum.Font.Gotham, 12
    b.MouseButton1Click:Connect(function()
        _G[var_path] = not _G[var_path]; b.BackgroundColor3 = _G[var_path] and Colors.Main or Color3.fromRGB(40,40,45)
    end)
end

Toggle(ItemChanger, "model offset", "ModOff", 25)
Toggle(ArmESP, "modify arm visual", "ModArm", 25)
Toggle(ArmESP, "change arm transparency", "ArmT", 50)
Toggle(ArmESP, "change arm color", "ArmC", 100)
Toggle(ArmESP, "change arm material", "ArmM", 125)

-- MATERIAL DROPDOWN
local DD = Instance.new("TextButton", ArmESP); DD.Size = UDim2.new(0.9, 0, 0, 22)
DD.Position, DD.BackgroundColor3 = UDim2.new(0.05, 0, 0, 155), Color3.fromRGB(30, 30, 35)
DD.Text, DD.TextColor3, DD.Font = "ForceField", Color3.new(0.6,0.6,0.6), Enum.Font.Gotham
DD.BorderSizePixel = 0

print("Project Delta Elite Suite Loaded.")
