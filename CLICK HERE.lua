-- // OMEGA V18 (Matcha-Elite Build) \\ --
-- // PART 1: UI, CONFIG, & QUICK-HUB

local P = game:GetService("Players")
local R = game:GetService("RunService")
local U = game:GetService("UserInputService")
local C = game:GetService("CoreGui")
local T = game:GetService("TweenService")
local D = game:GetService("Debris")
local S = game:GetService("SoundService")

local L = P.LocalPlayer
local Cam = workspace.CurrentCamera

if _G.OMEGA_CLEANUP then _G.OMEGA_CLEANUP() end
local Cons, DrawObj = {}, {}
local function Draw(c) local o = Drawing.new(c); table.insert(DrawObj, o); return o end

_G.OMEGA_CLEANUP = function() 
    local old = C:FindFirstChild("NL_Omega"); if old then old:Destroy() end 
    for _, v in pairs(Cons) do v:Disconnect() end 
    for _, v in pairs(DrawObj) do v:Remove() end 
    if L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.AutoRotate = true end 
end

local WeaponData = {["tfz mod-98"]={AP=1015,Tracer=992},["r700"]={AP=1015,Tracer=992},["m4a1"]={AP=1000,Tracer=933},["adar"]={AP=1000,Tracer=933},["svd"]={AP=940,Tracer=885},["mosin"]={AP=940,Tracer=885},["pkm"]={AP=940,Tracer=885},["fn-fal"]={AP=900,Tracer=820},["akmn"]={AP=767,Tracer=715},["sks"]={AP=767,Tracer=715},["saiga 12"]={AP=625,Tracer=405},["mk23"]={AP=515,Tracer=465},["mp5sd"]={AP=500,Tracer=465},["as val"]={AP=357,Tracer=357},["rpg-7"]={AP=115,Tracer=115}}

local O = {
    Combat = {S_A=false, S_A_Auto=false, S_A_WB=false, Multi=1, AimFOV=150, I_H=false, Pr=true, Vel=933, AimBot=false}, 
    Vis = {E=true, Chams=false, Bx=true, Sk=true, FOV=true, Dot=true, Info=true, Tracers=true, AimTr=true, Beam=false, FOVSize=150}, 
    Misc = {TP=false, Zm=false, FOV=90, Heal=false, HS=false}, 
    AA = {Enabled=false, Y=0}
}

local Colors = {MainBg=Color3.fromRGB(20,22,28), SidebarBg=Color3.fromRGB(15,17,22), Accent=Color3.fromRGB(50,150,255), Text=Color3.fromRGB(220,220,220), DarkText=Color3.fromRGB(150,150,150), Off=Color3.fromRGB(45,50,60), Good=Color3.fromRGB(0,255,100)}
local last_heal, last_auto_shoot = 0, 0

-- // UI BUILDER
local Gui = Instance.new("ScreenGui", C); Gui.Name = "NL_Omega"
local Main = Instance.new("Frame", Gui); Main.Size = UDim2.new(0, 580, 0, 350); Main.Position = UDim2.new(0.5, -290, 0.5, -175); Main.BackgroundColor3 = Colors.MainBg; Main.BorderSizePixel = 0; Main.Visible = false; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Draggable Logic
local function MakeDraggable(obj)
    local drag, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then drag = false end end) end end)
    U.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    table.insert(Cons, R.RenderStepped:Connect(function() if drag and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))
end
MakeDraggable(Main)

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 130, 1, 0); Sidebar.BackgroundColor3 = Colors.SidebarBg; Sidebar.BorderSizePixel = 0; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 5)
local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1, -140, 1, -20); Content.Position = UDim2.new(0, 140, 0, 10); Content.BackgroundTransparency = 1

local Tabs = {}
local function MakeTab(name)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundTransparency = 1; btn.Text = "  " .. name; btn.TextColor3 = Colors.DarkText; btn.Font = 3; btn.TextSize = 14; btn.TextXAlignment = 0
    local page = Instance.new("ScrollingFrame", Content); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.ScrollBarThickness = 0; page.Visible = false; local lay = Instance.new("UIListLayout", page); lay.FillDirection, lay.Padding = 1, UDim.new(0, 15)
    btn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Btn.TextColor3 = Colors.DarkText; t.Page.Visible = false end; btn.TextColor3 = Colors.Text; page.Visible = true end)
    table.insert(Tabs, {Btn = btn, Page = page}); return page
end

local function MakeColumn(page, title)
    local col = Instance.new("Frame", page); col.Size = UDim2.new(0, 135, 1, 0); col.BackgroundTransparency = 1; Instance.new("UIListLayout", col).Padding = UDim.new(0, 8); local lbl = Instance.new("TextLabel", col); lbl.Size = UDim2.new(1, 0, 0, 20); lbl.BackgroundTransparency = 1; lbl.Text = title:upper(); lbl.TextColor3 = Colors.Accent; lbl.Font = 4; lbl.TextSize = 11; lbl.TextXAlignment = 0; return col
end

local function Tgl(col, name, tab, key)
    local r = Instance.new("Frame", col); r.Size = UDim2.new(1, 0, 0, 20); r.BackgroundTransparency = 1; local lbl = Instance.new("TextLabel", r); lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Colors.Text; lbl.Font = 3; lbl.TextSize = 12; lbl.TextXAlignment = 0
    local bg = Instance.new("TextButton", r); bg.Size = UDim2.new(0, 28, 0, 14); bg.Position = UDim2.new(1, -30, 0.5, -7); bg.BackgroundColor3 = tab[key] and Colors.Accent or Colors.Off; bg.Text = ""; Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local kn = Instance.new("Frame", bg); kn.Size = UDim2.new(0, 10, 0, 10); kn.Position = tab[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5); kn.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)
    bg.MouseButton1Click:Connect(function() tab[key] = not tab[key]; T:Create(bg, TweenInfo.new(0.1), {BackgroundColor3 = tab[key] and Colors.Accent or Colors.Off}):Play(); T:Create(kn, TweenInfo.new(0.1), {Position = tab[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)}):Play() end)
end

local function Sld(col, name, min, max, tab, key, suf)
    local r = Instance.new("Frame", col); r.Size = UDim2.new(1, 0, 0, 35); r.BackgroundTransparency = 1; local lbl = Instance.new("TextLabel", r); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. tab[key] .. (suf or ""); lbl.TextColor3 = Colors.Text; lbl.Font = 3; lbl.TextSize = 11; lbl.TextXAlignment = 0
    local tr = Instance.new("Frame", r); tr.Size = UDim2.new(1, 0, 0, 3); tr.Position = UDim2.new(0, 0, 1, -8); tr.BackgroundColor3 = Colors.Off; local fil = Instance.new("Frame", tr); fil.Size = UDim2.new((tab[key]-min)/(max-min), 0, 1, 0); fil.BackgroundColor3 = Colors.Accent
    local kn = Instance.new("TextButton", fil); kn.Size = UDim2.new(0, 8, 0, 8); kn.Position = UDim2.new(1, -4, 0.5, -4); kn.BackgroundColor3 = Color3.new(1,1,1); kn.Text = ""; Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)
    kn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then local con; con = U.InputChanged:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseMovement or e.UserInputType == Enum.UserInputType.Touch then local rat = math.clamp((e.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1); tab[key] = math.floor(min + (rat * (max - min))); lbl.Text = name .. ": " .. tab[key] .. (suf or ""); fil.Size = UDim2.new(rat, 0, 1, 0) end end); local st; st = U.InputEnded:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then con:Disconnect(); st:Disconnect() end end) end end)
end

-- Tabs
local pRage = MakeTab("Combat"); local cR1 = MakeColumn(pRage, "Main"); local cR2 = MakeColumn(pRage, "Settings")
Tgl(cR1, "Silent Aim", O.Combat, "S_A"); Tgl(cR1, "TriggerBot", O.Combat, "S_A_Auto"); Tgl(cR1, "Omni-Wallbang", O.Combat, "S_A_WB"); Tgl(cR1, "Hard Aimlock", O.Combat, "AimBot"); Sld(cR2, "Burst Count", 1, 10, O.Combat, "Multi", "x"); Sld(cR2, "Aim FOV", 50, 800, O.Combat, "AimFOV", "px")

local pVis = MakeTab("Visuals"); local cV1 = MakeColumn(pVis, "ESP"); local cV2 = MakeColumn(pVis, "Visuals")
Tgl(cV1, "Master ESP", O.Vis, "E"); Tgl(cV1, "Boxes", O.Vis, "Bx"); Tgl(cV1, "Skeletons", O.Vis, "Sk"); Tgl(cV1, "Neon Chams", O.Vis, "Chams"); Sld(cV2, "Circle Size", 50, 800, O.Vis, "FOVSize", "px"); Tgl(cV2, "Show Circle", O.Vis, "FOV"); Tgl(cV2, "3D Beams", O.Vis, "Beam"); Tgl(cV2, "Target Line", O.Vis, "AimTr")

local pMisc = MakeTab("Misc"); local cM1 = MakeColumn(pMisc, "Local"); local cM2 = MakeColumn(pMisc, "Exploits")
Tgl(cM1, "Neural Heal", O.Misc, "Heal"); Tgl(cM1, "Hit Sounds", O.Misc, "HS"); Tgl(cM2, "Anti-Aim", O.AA, "Enabled")

Tabs[1].Btn.TextColor3 = Colors.Text; Tabs[1].Page.Visible = true

-- Quick-Action Hub
local Hub = Instance.new("Frame", Gui); Hub.Size = UDim2.new(0, 160, 0, 45); Hub.Position = UDim2.new(0.5, -80, 0, 10); Hub.BackgroundColor3 = Colors.SidebarBg; Instance.new("UICorner", Hub); MakeDraggable(Hub)
local function QuickBtn(n, p, cb) local b = Instance.new("TextButton", Hub); b.Size = UDim2.new(0, 35, 0, 35); b.Position = p; b.BackgroundColor3 = Colors.Off; b.Text = n; b.TextColor3 = Colors.Text; b.Font = 4; b.TextSize = 14; Instance.new("UICorner", b); b.MouseButton1Click:Connect(cb); return b end
local qMenu = QuickBtn("NL", UDim2.new(0, 5, 0.5, -17), function() Main.Visible = not Main.Visible end)
local qZoom = QuickBtn("Z", UDim2.new(0, 45, 0.5, -17), function() O.Misc.Zm = not O.Misc.Zm end)
local qTP = QuickBtn("T", UDim2.new(0, 85, 0.5, -17), function() local hrp = L.Character and L.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 35, 0) end end)
local qAim = QuickBtn("A", UDim2.new(0, 125, 0.5, -17), function() O.Combat.AimBot = not O.Combat.AimBot end)

table.insert(Cons, R.RenderStepped:Connect(function() qZoom.TextColor3 = O.Misc.Zm and Colors.Accent or Colors.Text; qAim.TextColor3 = O.Combat.AimBot and Colors.Accent or Colors.Text end))
-- // PART 2: ENGINE & COMBAT LOGIC

local TargetLine = Draw("Line"); TargetLine.Thickness, TargetLine.Color = 1.5, Colors.Accent
local FOV_Circle = Draw("Circle"); FOV_Circle.Thickness, FOV_Circle.Filled = 1.2, false; FOV_Circle.Color = Colors.Accent

-- Hit Effects
local function PlayHS() if not O.Misc.HS then return end; local h = Instance.new("Sound"); h.SoundId, h.Volume, h.Parent = "rbxassetid://8041570220", 1.5, S; h:Play(); D:AddItem(h, 2) end
local function Draw3DTr(o, e) local b = Instance.new("Part"); b.Anchored, b.CanCollide = true, false; b.Material, b.Color = Enum.Material.Neon, Colors.Accent; b.Size = Vector3.new(0.08, 0.08, (o - e).Magnitude); b.CFrame = CFrame.new(o, e) * CFrame.new(0, 0, -b.Size.Z/2); b.Parent = workspace; T:Create(b, TweenInfo.new(0.5), {Transparency=1}):Play(); D:AddItem(b, 0.5) end

-- Input Hook
U.InputBegan:Connect(function(i, g) 
    if not g and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and _G.LT then 
        PlayHS()
        local tool = L.Character and L.Character:FindFirstChildOfClass("Tool")
        if tool then 
            if O.Vis.Beam then local b = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle") if b then for i=1, O.Combat.Multi do Draw3DTr(b.Position, _G.LT.Position) end end end
            if O.Combat.Multi > 1 then task.spawn(function() for i=2, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) end
        end 
    end 
end)

-- Visibility Check
local function IsVisible(char) 
    local p = RaycastParams.new(); p.FilterType, p.FilterDescendantsInstances = 1, {L.Character, Cam}
    for _, pt in pairs({char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")}) do 
        if pt then 
            local ori, dir = Cam.CFrame.Position, (pt.Position - Cam.CFrame.Position).Unit * 5000; local cur, pens, clear = ori, 0, false
            while pens < 15 do 
                local res = workspace:Raycast(cur, dir, p); if not res then break end
                if res.Instance:IsDescendantOf(char) then clear = true break end
                if O.Combat.S_A_WB then local f = p.FilterDescendantsInstances; table.insert(f, res.Instance); p.FilterDescendantsInstances = f; pens = pens + 1 else break end 
            end
            if clear then return true end 
        end 
    end 
    return false 
end

-- Silent Aim Hook
local mt = getrawmetatable(game); setreadonly(mt, false); local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...) 
    local meth, args = getnamecallmethod(), {...}
    if not checkcaller() and O.Combat.S_A and _G.LT and meth == "Raycast" then 
        local ti = (_G.LT.Position - args[1]).Magnitude / O.Combat.Vel; local pos = _G.LT.Position
        if not O.Combat.I_H and _G.LT.Parent:FindFirstChild("HumanoidRootPart") then pos = pos + (_G.LT.Parent.HumanoidRootPart.AssemblyLinearVelocity * ti) + Vector3.new(0, 0.5 * 196.2 * (ti^2), 0) end
        args[2] = (pos - args[1]).Unit * 1000; return old(self, unpack(args)) 
    end
    return old(self, ...) 
end)
setreadonly(mt, true)

-- ESP Engine
local D_T = {}
local function AddESP(p) if p == L then return end local d = {H = Instance.new("Highlight", C), B = Draw("Square"), Sk = {}} for i=1,10 do table.insert(d.Sk, Draw("Line")) end D_T[p] = d end
for _,p in pairs(P:GetPlayers()) do AddESP(p) end; P.PlayerAdded:Connect(AddESP); P.PlayerRemoving:Connect(function(p) if D_T[p] then for _,v in pairs(D_T[p].Sk) do v:Remove() end D_T[p].B:Remove(); D_T[p].H:Destroy(); D_T[p] = nil end end)

-- Main Loop
table.insert(Cons, R.RenderStepped:Connect(function()
    Cam.FieldOfView = O.Misc.Zm and 10 or O.Misc.FOV
    L.CameraMaxZoomDistance = O.Misc.TP and 15 or 128
    
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    FOV_Circle.Visible = O.Vis.FOV; FOV_Circle.Radius = O.Vis.FOVSize; FOV_Circle.Position = center
    TargetLine.Visible = false
    
    -- Target Selection
    if not _G.LT or not _G.LT.Parent or _G.LT.Parent.Humanoid.Health <= 0 then 
        local cl, d = nil, O.Vis.FOVSize
        for p,esp in pairs(D_T) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then 
            local sP, vis = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position); if vis then local m = (Vector2.new(sP.X, sP.Y) - center).Magnitude
            if m < d and IsVisible(p.Character) then d, cl = m, p.Character.Head end end end end _G.LT = cl 
    end

    if _G.LT then
        local sP, vis = Cam:WorldToViewportPoint(_G.LT.Position)
        if O.Vis.AimTr then TargetLine.Visible = true; TargetLine.From, TargetLine.To = center, Vector2.new(sP.X, sP.Y) end
        if O.Combat.AimBot then Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, _G.LT.Position), 0.2) end
        if O.Combat.S_A_Auto and tick() - last_auto_shoot > 0.15 and IsVisible(_G.LT.Parent) then local tool = L.Character and L.Character:FindFirstChildOfClass("Tool") if tool then last_auto_shoot = tick(); task.spawn(function() for i=1, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) end end
    end

    -- AA & Weapon Sync
    local activeTool = L.Character and L.Character:FindFirstChildOfClass("Tool")
    if activeTool then for wName, wData in pairs(WeaponData) do if string.find(activeTool.Name:lower(), wName) then O.Combat.Vel = wData.AP break end end end

    -- Visual Sync
    for p, d in pairs(D_T) do 
        local c = p.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
        if c and r and c.Humanoid.Health > 0 and O.Vis.E then 
            local rP, onScreen = Cam:WorldToViewportPoint(r.Position); if onScreen then 
                local is_v = IsVisible(c); local clr = is_v and Colors.Good or Color3.new(1,1,1); d.B.Color = clr
                if O.Vis.Chams then d.H.Adornee, d.H.Enabled, d.H.FillColor = c, true, clr else d.H.Enabled = false end
                local tP = Cam:WorldToViewportPoint(r.Position + Vector3.new(0,4,0)); local bP = Cam:WorldToViewportPoint(r.Position - Vector3.new(0,4.5,0))
                local h = math.abs(tP.Y - bP.Y); local w = h/2
                d.B.Size, d.B.Position, d.B.Visible = Vector2.new(w, h), Vector2.new(rP.X-w/2, rP.Y-h/2), O.Vis.Bx
                if O.Vis.Sk then local j = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
                    for i,v in ipairs(j) do local p1, p2 = c:FindFirstChild(v[1]), c:FindFirstChild(v[2]) if p1 and p2 then local v1,s1 = Cam:WorldToViewportPoint(p1.Position); local v2,s2 = Cam:WorldToViewportPoint(p2.Position) if s1 and s2 then d.Sk[i].From, d.Sk[i].To, d.Sk[i].Color, d.Sk[i].Visible = Vector2.new(v1.X,v1.Y), Vector2.new(v2.X,v2.Y), clr, true else d.Sk[i].Visible = false end end end
                else for _,l in pairs(d.Sk) do l.Visible = false end end
            else d.H.Enabled, d.B.Visible = false, false; for _,l in pairs(d.Sk) do l.Visible = false end end
        else d.H.Enabled, d.B.Visible = false, false; for _,l in pairs(d.Sk) do l.Visible = false end end
    end
end))
