-- // OMEGA V17 (Matcha UI Engine + Unrestricted Master Build) \\ --
-- // PART 1: UI & FRAMEWORK

local P = game:GetService("Players")
local R = game:GetService("RunService")
local U = game:GetService("UserInputService")
local C = game:GetService("CoreGui")
local T = game:GetService("TweenService")
local D = game:GetService("Debris")
local S = game:GetService("SoundService")

local LocalPlayer = P.LocalPlayer
local Cam = workspace.CurrentCamera

-- // CLEANUP PREVIOUS INSTANCES
if _G.OMEGA_CLEANUP then _G.OMEGA_CLEANUP() end
local Cons, DrawObj = {}, {}
local function Draw(c) local o = Drawing.new(c); table.insert(DrawObj, o); return o end
_G.OMEGA_CLEANUP = function() 
    local old = C:FindFirstChild("NL_Omega"); if old then old:Destroy() end 
    for _, v in pairs(Cons) do v:Disconnect() end 
    for _, v in pairs(DrawObj) do v:Remove() end 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.AutoRotate = true end 
end

-- // DATABASES
local WeaponData = {["tfz mod-98"]={AP=1015,Tracer=992},["r700"]={AP=1015,Tracer=992},["m4a1"]={AP=1000,Tracer=933},["adar"]={AP=1000,Tracer=933},["svd"]={AP=940,Tracer=885},["mosin"]={AP=940,Tracer=885},["pkm"]={AP=940,Tracer=885},["fn-fal"]={AP=900,Tracer=820},["akmn"]={AP=767,Tracer=715},["sks"]={AP=767,Tracer=715},["saiga 12"]={AP=625,Tracer=405},["mk23"]={AP=515,Tracer=465},["mp5sd"]={AP=500,Tracer=465},["as val"]={AP=357,Tracer=357},["rpg-7"]={AP=115,Tracer=115}}

-- // CONFIGURATION STATE
local O = {
    Combat = {S_A=false, S_A_Auto=false, S_A_WB=false, Multi=1, AimFOV=150, I_H=false, Pr=true, Vel=933, AimBot=false}, 
    Vis = {E=true, Chams=false, Bx=true, Sk=true, FOV=true, Dot=true, Info=true, Tracers=true, AimTr=true, Beam=false}, 
    Misc = {TP=false, Zm=false, FOV=90, Heal=false, HS=false}, 
    AA = {Enabled=false, Y=0}
}

-- Matcha Aesthetic Colors
local Colors = {
    MainBg = Color3.fromRGB(20, 22, 28), 
    SidebarBg = Color3.fromRGB(15, 17, 22), 
    Accent = Color3.fromRGB(50, 150, 255), 
    Text = Color3.fromRGB(220, 220, 220), 
    DarkText = Color3.fromRGB(150, 150, 150),
    Off = Color3.fromRGB(45, 50, 60),
    Good = Color3.fromRGB(0, 255, 100)
}

local last_heal, last_auto_shoot, activeFOV = 0, 0, O.Combat.AimFOV
local TargetLine = Draw("Line"); TargetLine.Thickness, TargetLine.Color = 1.5, Colors.Accent

-- // EFFECTS ENGINE
local function PlayHS() 
    if not O.Misc.HS then return end
    local h = Instance.new("Sound"); h.SoundId, h.Volume, h.Parent = "rbxassetid://8041570220", 1.5, S; h:Play(); D:AddItem(h, h.TimeLength + 0.1) 
end

local function Draw3DTr(o, e) 
    local b = Instance.new("Part"); b.Anchored, b.CanCollide = true, false; b.Material, b.Color = Enum.Material.Neon, Colors.Accent; b.Size = Vector3.new(0.08, 0.08, (o - e).Magnitude); b.CFrame = CFrame.new(o, e) * CFrame.new(0, 0, -b.Size.Z/2); b.Parent = workspace; T:Create(b, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0,0,b.Size.Z)}):Play(); D:AddItem(b, 0.5) 
end

-- // MATCHA UI FRAMEWORK (Expanded & Clean)
local Gui = Instance.new("ScreenGui", C); Gui.Name = "NL_Omega"

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 650, 0, 350)
Main.Position = UDim2.new(0.5, -325, 0.5, -175)
Main.BackgroundColor3 = Colors.MainBg
Main.BorderSizePixel = 0
Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Main.ClipsDescendants = true

-- Mobile-Safe Custom Dragging
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
U.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
table.insert(Cons, R.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

-- Sidebar Setup
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Colors.SidebarBg
Sidebar.BorderSizePixel = 0
local SideList = Instance.new("UIListLayout", Sidebar)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 5)

local Title = Instance.new("TextLabel", Sidebar)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "  OMEGA V17"
Title.TextColor3 = Colors.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

local ContentContainer = Instance.new("Frame", Main)
ContentContainer.Size = UDim2.new(1, -150, 1, -20)
ContentContainer.Position = UDim2.new(0, 150, 0, 10)
ContentContainer.BackgroundTransparency = 1

local Tabs = {}
local function MakeTab(name)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundTransparency = 1
    btn.Text = "   " .. name
    btn.TextColor3 = Colors.DarkText
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local page = Instance.new("ScrollingFrame", ContentContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 0
    page.Visible = false
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.FillDirection = Enum.FillDirection.Horizontal
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 15)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Btn.TextColor3 = Colors.DarkText; t.Page.Visible = false end
        btn.TextColor3 = Colors.Text
        page.Visible = true
    end)
    
    table.insert(Tabs, {Btn = btn, Page = page})
    return page
end

local function MakeColumn(parentTab, title)
    local col = Instance.new("Frame", parentTab)
    col.Size = UDim2.new(0, 150, 1, 0)
    col.BackgroundTransparency = 1

    local colList = Instance.new("UIListLayout", col)
    colList.SortOrder = Enum.SortOrder.LayoutOrder
    colList.Padding = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", col)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(title)
    lbl.TextColor3 = Colors.DarkText
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    return col
end

local function MakeToggle(parentCol, name, settingTable, settingKey)
    local row = Instance.new("Frame", parentCol)
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bg = Instance.new("TextButton", row)
    bg.Size = UDim2.new(0, 30, 0, 16)
    bg.Position = UDim2.new(1, -30, 0.5, -8)
    bg.BackgroundColor3 = settingTable[settingKey] and Colors.Accent or Colors.Off
    bg.Text = ""
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = settingTable[settingKey] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    bg.MouseButton1Click:Connect(function()
        settingTable[settingKey] = not settingTable[settingKey]
        local state = settingTable[settingKey]
        T:Create(bg, TweenInfo.new(0.15), {BackgroundColor3 = state and Colors.Accent or Colors.Off}):Play()
        T:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
    end)
end

local function MakeSlider(parentCol, name, min, max, settingTable, settingKey, suffix)
    local row = Instance.new("Frame", parentCol)
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. settingTable[settingKey] .. (suffix or "")
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 1, -10)
    track.BackgroundColor3 = Colors.Off
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((settingTable[settingKey] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", fill)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(1, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            local con; con = U.InputChanged:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseMovement or e.UserInputType == Enum.UserInputType.Touch then
                    local rat = math.clamp((e.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    settingTable[settingKey] = math.floor(min + (rat * (max - min)))
                    lbl.Text = name .. ": " .. settingTable[settingKey] .. (suffix or "")
                    fill.Size = UDim2.new(rat, 0, 1, 0)
                end
            end)
            local stop; stop = U.InputEnded:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
                    con:Disconnect(); stop:Disconnect()
                end
            end)
        end
    end)
end

local function MakeButton(parentCol, name, callback)
    local btn = Instance.new("TextButton", parentCol)
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Colors.Off
    btn.Text = name
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
end

-- // BUILDING THE UI MENUS
local tabRage = MakeTab("Rage")
local cMain = MakeColumn(tabRage, "MAIN")
local cOther = MakeColumn(tabRage, "OTHER")
local cAnti = MakeColumn(tabRage, "ANTI-AIM")

MakeToggle(cMain, "Silent Aim", O.Combat, "S_A")
MakeToggle(cMain, "TriggerBot", O.Combat, "S_A_Auto")
MakeToggle(cMain, "Omni-Wallbang", O.Combat, "S_A_WB")
MakeToggle(cMain, "Iron LockBot", O.Combat, "AimBot")
MakeToggle(cMain, "Insta Hit", O.Combat, "I_H")

MakeSlider(cOther, "Burst Setup", 1, 10, O.Combat, "Multi", " x")
MakeSlider(cOther, "Aim FOV", 50, 800, O.Combat, "AimFOV", "px")

MakeToggle(cAnti, "Enable AA", O.AA, "Enabled")

local tabVis = MakeTab("Visuals")
local cVis1 = MakeColumn(tabVis, "ESP CORE")
local cVis2 = MakeColumn(tabVis, "DRAWINGS")

MakeToggle(cVis1, "Master Switch", O.Vis, "E")
MakeToggle(cVis1, "Neon Chams", O.Vis, "Chams")
MakeToggle(cVis1, "Boxes", O.Vis, "Bx")
MakeToggle(cVis1, "Skeletons", O.Vis, "Sk")

MakeToggle(cVis2, "HP & Info", O.Vis, "Info")
MakeToggle(cVis2, "Target Line", O.Vis, "AimTr")
MakeToggle(cVis2, "Show FOV", O.Vis, "FOV")
MakeToggle(cVis2, "3D Beams", O.Vis, "Beam")

local tabMisc = MakeTab("Misc")
local cMisc = MakeColumn(tabMisc, "LOCAL")
local cActions = MakeColumn(tabMisc, "ACTIONS")

MakeToggle(cMisc, "Zoom (FOV)", O.Misc, "Zm")
MakeToggle(cMisc, "3rd Person", O.Misc, "TP")
MakeToggle(cMisc, "Neural Heal", O.Misc, "Heal")
MakeToggle(cMisc, "Hit Sounds", O.Misc, "HS")

MakeButton(cActions, "Execute Safe TP", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp and hum then 
        local cachedAA = O.AA.Enabled; O.AA.Enabled = false
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 35, 0); hrp.Anchored = true; task.wait(0.15) 
        hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; hrp.Anchored = false
        hum:ChangeState(Enum.HumanoidStateType.Landed); hrp.AssemblyLinearVelocity = Vector3.new(0, -5, 0); task.wait(0.1); O.AA.Enabled = cachedAA
    end 
end)

Tabs[1].Btn.TextColor3 = Colors.Text
Tabs[1].Page.Visible = true

local NL = Instance.new("TextButton", Gui)
NL.Size = UDim2.new(0, 45, 0, 45)
NL.Position = UDim2.new(0, 10, 0, 10)
NL.BackgroundColor3 = Colors.SidebarBg
NL.Text = "NL"
NL.TextColor3 = Colors.Accent
NL.Font = Enum.Font.GothamBold
NL.TextSize = 18
Instance.new("UICorner", NL).CornerRadius = UDim.new(1, 0)
NL.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
-- // PART 2: ENGINE & COMBAT LOGIC

U.InputBegan:Connect(function(i, g) 
    if not g and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and _G.LT then 
        PlayHS()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then 
            if O.Vis.Beam then 
                local barrel = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
                if barrel then for idx = 1, O.Combat.Multi do Draw3DTr(barrel.Position, _G.LT.Position) end end 
            end
            if O.Combat.Multi > 1 then 
                task.spawn(function() for idx = 2, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) 
            end 
        end 
    end 
end)

local function IsVisible(char) 
    local p = RaycastParams.new(); p.FilterType, p.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {LocalPlayer.Character, Cam}
    for _, pt in pairs({char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")}) do 
        if pt then 
            local ori, dir = Cam.CFrame.Position, (pt.Position - Cam.CFrame.Position).Unit * 5000
            local current_ori, pens, clear = ori, 0, false
            while pens < 15 do 
                local res = workspace:Raycast(current_ori, dir, p); if not res then break end
                if res.Instance:IsDescendantOf(char) then clear = true break end
                if O.Combat.S_A_WB then 
                    local f = p.FilterDescendantsInstances; table.insert(f, res.Instance); p.FilterDescendantsInstances = f; pens = pens + 1 
                else break end 
            end
            if clear then return true end 
        end 
    end 
    return false 
end

local mt = getrawmetatable(game); setreadonly(mt, false); local oldName = mt.__namecall
mt.__namecall = newcclosure(function(self, ...) 
    local meth, args = getnamecallmethod(), {...}
    if checkcaller() then return oldName(self, ...) end
    if O.Combat.S_A and _G.LT and meth == "Raycast" then 
        local sp = args[1]; local ti = (_G.LT.Position - sp).Magnitude / O.Combat.Vel
        local pos = _G.LT.Position
        if not O.Combat.I_H then 
            if _G.LT.Parent:FindFirstChild("HumanoidRootPart") then pos = pos + (_G.LT.Parent.HumanoidRootPart.AssemblyLinearVelocity * ti) end
            pos = pos + Vector3.new(0, 0.5 * 196.2 * (ti^2), 0) 
        end
        args[2] = (pos - sp).Unit * 1000
        return oldName(self, unpack(args)) 
    end
    return oldName(self, ...) 
end)
setreadonly(mt, true)

-- // ESP ENGINE
local D_T = {}
local function AddESP(p) 
    if p == LocalPlayer then return end 
    local d = {H = Instance.new("Highlight", C), B = Draw("Square"), Sk = {}} 
    for i=1,10 do table.insert(d.Sk, Draw("Line")) end 
    D_T[p] = d 
end
for _,p in pairs(P:GetPlayers()) do AddESP(p) end 
P.PlayerAdded:Connect(AddESP)
P.PlayerRemoving:Connect(function(p) 
    if D_T[p] then 
        for _,v in pairs(D_T[p].Sk) do v:Remove() end 
        D_T[p].B:Remove(); D_T[p].H:Destroy(); D_T[p] = nil 
    end 
end)

-- // MAIN RENDER LOOP
local F_C = Draw("Circle"); local S_C = Draw("Circle")
F_C.Color, S_C.Color = Colors.Accent, Color3.new(1,0,0)

table.insert(Cons, R.RenderStepped:Connect(function()
    Cam.FieldOfView = O.Misc.Zm and 10 or O.Misc.FOV
    LocalPlayer.CameraMaxZoomDistance = O.Misc.TP and 15 or 128
    LocalPlayer.CameraMinZoomDistance = O.Misc.TP and 15 or 0

    F_C.Visible, S_C.Visible, TargetLine.Visible = false, false, false
    
    if _G.LT then
        local ti = (_G.LT.Position - Cam.CFrame.Position).Magnitude / O.Combat.Vel
        local pos = _G.LT.Position
        if not O.Combat.I_H and _G.LT.Parent:FindFirstChild("HumanoidRootPart") then pos = pos + (_G.LT.Parent.HumanoidRootPart.AssemblyLinearVelocity * ti) + Vector3.new(0, 0.5 * 196.2 * (ti^2), 0) end
        local sP, vis = Cam:WorldToViewportPoint(pos)
        local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        local mag = (Vector2.new(sP.X, sP.Y) - center).Magnitude
        activeFOV = math.max(O.Combat.AimFOV, (mag * ((80/math.clamp(Cam.FieldOfView, 5, 80))*2.8)) + 50)
        
        S_C.Visible = O.Combat.S_A and O.Vis.FOV; S_C.Radius, S_C.Position = activeFOV, center
        TargetLine.Visible = O.Vis.AimTr; TargetLine.From, TargetLine.To = center, Vector2.new(sP.X, sP.Y)
        
        if O.Combat.AimBot then Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, pos), 0.6) end
        
        if O.Combat.S_A_Auto and tick() - last_auto_shoot > 0.15 and IsVisible(_G.LT.Parent) then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then last_auto_shoot = tick(); task.spawn(function() for i = 1, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) end
        end
    else activeFOV = O.Combat.AimFOV end

    local cur = _G.LT
    if cur and cur.Parent and cur.Parent:FindFirstChild("HumanoidRootPart") and cur.Parent.Humanoid.Health > 0 then 
        local sP, vis = Cam:WorldToViewportPoint(cur.Position)
        local m = (Vector2.new(sP.X, sP.Y) - Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)).Magnitude
        if not vis or m > (activeFOV + 150) then _G.LT = nil end 
    else _G.LT = nil end
    
    if not _G.LT then 
        local cl, d = nil, O.Combat.AimFOV
        local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2) 
        for p,esp in pairs(D_T) do 
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then 
                local sP, vis = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if vis then 
                    local m = (Vector2.new(sP.X, sP.Y) - center).Magnitude
                    if m < d and IsVisible(p.Character) then d, cl = m, p.Character.Head end 
                end 
            end 
        end 
        _G.LT = cl 
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid; local char = LocalPlayer.Character
        local rootJoint = char:FindFirstChild("LowerTorso") and char.LowerTorso:FindFirstChild("Root") or char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("RootJoint")
        local neck = char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Neck") or char:FindFirstChild("Torso") and char.Torso:FindFirstChild("Neck")
        if not _G.OrigC0s then _G.OrigC0s = {} end
        if rootJoint and not _G.OrigC0s[rootJoint] then _G.OrigC0s[rootJoint] = rootJoint.C0 end
        if neck and not _G.OrigC0s[neck] then _G.OrigC0s[neck] = neck.C0 end
        if O.AA.Enabled then
            hum.AutoRotate = false; O.AA.Y = (O.AA.Y + 45) % 360
            if rootJoint then rootJoint.C0 = _G.OrigC0s[rootJoint] * CFrame.Angles(0, math.rad(O.AA.Y), 0) end
            if neck then neck.C0 = _G.OrigC0s[neck] * CFrame.Angles(math.rad(70), 0, 0) end
        else
            hum.AutoRotate = true
            if rootJoint and _G.OrigC0s[rootJoint] then rootJoint.C0 = _G.OrigC0s[rootJoint] end
            if neck and _G.OrigC0s[neck] then neck.C0 = _G.OrigC0s[neck] end
        end
    end

    local activeTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if activeTool then 
        local toolName = activeTool.Name:lower() 
        for wName, wData in pairs(WeaponData) do 
            if string.find(toolName, wName) then O.Combat.Vel = string.find(toolName, "tracer") and wData.Tracer or wData.AP break end 
        end 
    end

    for p, d in pairs(D_T) do 
        local c = p.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
        if c and r and c.Humanoid.Health > 0 and O.Vis.E then 
            local rP, onScreen = Cam:WorldToViewportPoint(r.Position)
            local look = Cam.CFrame.LookVector; local dir = (r.Position - Cam.CFrame.Position).Unit
            local isBehind = look:Dot(dir) < 0
            if onScreen and not isBehind then 
                local is_v = IsVisible(c); local clr = is_v and Colors.Good or Color3.new(1,1,1); d.B.Color = clr
                if O.Vis.Chams then 
                    d.H.Adornee, d.H.Enabled, d.H.FillColor = c, true, clr
                    for _, part in pairs(c:GetChildren()) do if part:IsA("BasePart") then part.Material, part.Color = Enum.Material.Neon, clr end end 
                else d.H.Enabled = false end
                
                local tP = Cam:WorldToViewportPoint(r.Position + Vector3.new(0,4,0))
                local bP = Cam:WorldToViewportPoint(r.Position - Vector3.new(0,4.5,0))
                local h = math.abs(tP.Y - bP.Y); local w = h/2
                d.B.Size, d.B.Position, d.B.Visible = Vector2.new(w, h), Vector2.new(rP.X-w/2, rP.Y-h/2), O.Vis.Bx
                
                if O.Vis.Sk then 
                    local j = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
                    for i,v in ipairs(j) do 
                        local p1 = c:FindFirstChild(v[1]); local p2 = c:FindFirstChild(v[2]) 
                        if p1 and p2 then 
                            local v1,s1 = Cam:WorldToViewportPoint(p1.Position); local v2,s2 = Cam:WorldToViewportPoint(p2.Position) 
                            if s1 and s2 then d.Sk[i].From, d.Sk[i].To, d.Sk[i].Color, d.Sk[i].Visible = Vector2.new(v1.X,v1.Y), Vector2.new(v2.X,v2.Y), clr, true else d.Sk[i].Visible = false end 
                        end 
                    end
                else for _,l in pairs(d.Sk) do l.Visible = false end end
            else d.H.Enabled, d.B.Visible = false, false; for _,l in pairs(d.Sk) do l.Visible = false end end
        else d.H.Enabled, d.B.Visible = false, false; for _,l in pairs(d.Sk) do l.Visible = false end end
    end
end))
