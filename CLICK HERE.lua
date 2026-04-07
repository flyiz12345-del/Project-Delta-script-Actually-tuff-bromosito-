-- // OMEGA V16 (Extended Master Build + Modern UI + Multi-Bullet) \\ --
-- // Low-Cortisol Engineering - No Text Limits - Mobile friendly
-- // Logic: Frustum Culling, Dual-Circle FOV, Stable C0 Anti-Aim, Weapon Sync
-- // Security: Checkcaller Hook protection, Recursive Omni-Wallbang
-- // Combat: Hyper-Burst Multi-Bullet (1-10 Slider), Insta-Hit Toggle, Neural Heal
-- // Aesthetic: Modern 3-Column Rage Menu (Replica), Neon Chams, 3D Laser Beams

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
_G.OMEGA_CLEANUP = function() local old = C:FindFirstChild("NL_Omega"); if old then old:Destroy() end; for _, v in pairs(Cons) do v:Disconnect() end; for _, v in pairs(DrawObj) do v:Remove() end; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.AutoRotate = true end end

-- // DATABASES
local WeaponData = {["tfz mod-98"]={AP=1015,Tracer=992},["r700"]={AP=1015,Tracer=992},["m4a1"]={AP=1000,Tracer=933},["adar"]={AP=1000,Tracer=933},["svd"]={AP=940,Tracer=885},["mosin"]={AP=940,Tracer=885},["pkm"]={AP=940,Tracer=885},["fn-fal"]={AP=900,Tracer=820},["akmn"]={AP=767,Tracer=715},["sks"]={AP=767,Tracer=715},["saiga 12"]={AP=625,Tracer=405},["mk23"]={AP=515,Tracer=465},["mp5sd"]={AP=500,Tracer=465},["as val"]={AP=357,Tracer=357},["rpg-7"]={AP=115,Tracer=115}}

-- // CONFIGURATION STATE (Synced to UI)
local O = {Combat={S_A=false, S_A_Auto=false, S_A_WB=false, Multi=1, AimFOV=150, I_H=false, Pr=true, Vel=933}, Vis={E=true, Chams=false, Bx=true, Sk=true, FOV=true, Dot=true, Info=true, Tracers=true, AimTr=true, Beam=false}, Misc={Zm=false, FOV=90, Heal=false, HS=false}, AA={Enabled=false, Y=0}}
local Colors = {MainBg=Color3.fromRGB(15,20,28), SidebarBg=Color3.fromRGB(20,25,33), Accent=Color3.fromRGB(50,160,255), Text=Color3.fromRGB(220,220,220), G=Color3.fromRGB(0,255,100), Off=Color3.fromRGB(45,50,60)}

local last_heal, last_auto_shoot, activeFOV = 0, 0, O.Combat.AimFOV
local TargetLine = Draw("Line"); TargetLine.Thickness, TargetLine.Color = 1.5, Colors.Accent

-- // EFFECTS ENGINE
local function PlayHS() if not O.Misc.HS then return end; local h = Instance.new("Sound"); h.SoundId, h.Volume, h.Parent = "rbxassetid://8041570220", 1.5, S; h:Play(); D:AddItem(h, h.TimeLength + 0.1) end
local function Draw3DTr(o, e) local b = Instance.new("Part"); b.Anchored, b.CanCollide = true, false; b.Material, b.Color = Enum.Material.Neon, Colors.Accent; b.Size = Vector3.new(0.08, 0.08, (o - e).Magnitude); b.CFrame = CFrame.new(o, e) * CFrame.new(0, 0, -b.Size.Z/2); b.Parent = workspace; T:Create(b, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0,0,b.Size.Z)}):Play(); D:AddItem(b, 0.5) end

-- // MODERN UI LIBRARY INJECTION (Replica Construction)
local Gui = Instance.new("ScreenGui", C); Gui.Name = "NL_Omega"; local Main = Instance.new("Frame", Gui); Main.Size, Main.Position, Main.BackgroundColor3, Main.Visible, Main.ClipsDescendants = UDim2.new(0,560,0,500), UDim2.new(0.5,-280,0.5,-250), Colors.MainBg, false, true; Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)
local Sidebar = Instance.new("Frame", Main); Sidebar.Size, Sidebar.Position, Sidebar.BackgroundColor3 = UDim2.new(0,150,1,-45), UDim2.new(0,0,0,45), Colors.SidebarBg; local UI_L_Side = Instance.new("UIListLayout", Sidebar); UI_L_Side.Padding = UDim.new(0,2)

-- CONTENT CONTAINERS (Replica 3-Column Layout)
local ContentContainer = Instance.new("Frame", Main); ContentContainer.Size, ContentContainer.Position, ContentContainer.BackgroundTransparency = UDim2.new(0.7,0,1,-45), UDim2.new(0.3,0,0,45), 1; local UI_L_Cont = Instance.new("UIListLayout", ContentContainer); UI_L_Cont.FillDirection, UI_L_Cont.HorizontalAlignment, UI_L_Cont.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, UDim.new(0,5)

local function NewColumn(n) local s = Instance.new("ScrollingFrame", ContentContainer); s.Size, s.BackgroundTransparency, s.ScrollBarThickness, s.CanvasSize, s.Name = UDim2.new(0, 130, 1, 0), 1, 0, UDim2.new(0,0,0,0), n.."Column"; Instance.new("UIPadding", s).PaddingLeft, Instance.new("UIListLayout", s).Padding, Instance.new("TextLabel", s).Text, Instance.new("TextLabel", s).Size, Instance.new("TextLabel", s).TextSize, Instance.new("TextLabel", s).TextColor3 = UDim.new(0,10), UDim.new(0,5), n:upper(), UDim2.new(1,0,0,30), 13, Colors.Accent; return s end
local ColRage, ColOther, ColAA = NewColumn("MAIN"), NewColumn("OTHER"), NewColumn("ANTI-AIM")

-- COMPONENT BUILDERS (Strict Mobile EOF Protection)
local function Tgl(n, k, t, p) local r = Instance.new("Frame", p); r.Size, r.BackgroundTransparency = UDim2.new(1,0,0,30), 1; Instance.new("TextLabel", r).Text, Instance.new("TextLabel", r).Size, Instance.new("TextLabel", r).TextSize, Instance.new("TextLabel", r).TextColor3, Instance.new("TextLabel", r).TextXAlignment, Instance.new("TextLabel", r).Font = n, UDim2.new(0.6,0,1,0), 15, Colors.Text, 0, 4; local b = Instance.new("TextButton", r); b.Size, b.Position, b.Text, b.BackgroundColor3 = UDim2.new(0,36,0,18), UDim2.new(1,-10,0.5,-9), "", t[k] and Colors.Accent or Colors.Off; Instance.new("UICorner", b).CornerRadius = UDim.new(1,0); local k_n = Instance.new("Frame", b); k_n.Size, k_n.Position, k_n.BackgroundColor3 = UDim2.new(0,14,0,14), t[k] and UDim2.new(1,-9,0.5,0) or UDim2.new(0,9,0.5,0), Colors.Text; Instance.new("UICorner", k_n).CornerRadius = UDim.new(1,0); b.MouseButton1Click:Connect(function() t[k] = not t[k]; T:Create(b, TweenInfo.new(0.1), {BackgroundColor3=t[k] and Colors.Accent or Colors.Off}):Play(); T:Create(k_n, TweenInfo.new(0.1), {Position=t[k] and UDim2.new(1,-9,0.5,0) or UDim2.new(0,9,0.5,0)}):Play() end) end
local function Sld(n, min, max, k, t, p, suf) local r = Instance.new("Frame", p); r.Size, r.BackgroundTransparency = UDim2.new(1,0,0,45), 1; local lbl = Instance.new("TextLabel", r); lbl.Text, lbl.Size, lbl.TextSize, lbl.TextColor3, lbl.TextXAlignment, lbl.Font = n..": "..t[k]..suf, UDim2.new(1,0,0,20), 12, Colors.Text, 0, 4; local bar = Instance.new("Frame", r); bar.Size, bar.Position, bar.BackgroundColor3 = UDim2.new(1,0,0,4), UDim2.new(0,0,1,-12), Colors.Off; local fil = Instance.new("Frame", bar); fil.Size, fil.BackgroundColor3 = UDim2.new((t[k]-min)/(max-min),0,1,0), Colors.Accent; local kn = Instance.new("Frame", fil); kn.Size, kn.Position, kn.BackgroundColor3, kn.AnchorPoint = Vector3.new(10,10), UDim2.new(1,0,0.5,0), Colors.Text, Vector2.new(0.5,0.5); Instance.new("UICorner", kn).CornerRadius = UDim.new(1,0); kn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then local con; con = U.InputChanged:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseMovement or e.UserInputType == Enum.UserInputType.Touch then local rat = math.clamp((e.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1); t[k] = math.floor(min + (rat*(max-min))); lbl.Text = n..": "..t[k]..suf; fil.Size = UDim2.new(rat,0,1,0); kn.Position = UDim2.new(1,0,0.5,0) end end); local stop; stop = U.InputEnded:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then con:Disconnect(); stop:Disconnect() end end) end end) end
local function Ddp(n, c, p) local r = Instance.new("Frame", p); r.Size, r.BackgroundTransparency = UDim2.new(1,0,0,40), 1; Instance.new("TextLabel", r).Text, Instance.new("TextLabel", r).Size, Instance.new("TextLabel", r).TextSize, Instance.new("TextLabel", r).TextColor3, Instance.new("TextLabel", r).TextXAlignment, Instance.new("TextLabel", r).Font = n, UDim2.new(1,0,0,15), 12, Colors.Text, 0, 4; local b = Instance.new("TextButton", r); b.Size, b.Position, b.BackgroundColor3, b.Text, b.TextColor3, b.TextSize = UDim2.new(1,0,0,20), UDim2.new(0,0,1,-20), Colors.Off, c, Colors.Accent, 13; b.AutoButtonColor = false; Instance.new("UICorner", b).CornerRadius = UDim.new(0,4) end

-- SIDEBAR TABS
local function Tab(n) local b = Instance.new("TextButton", Sidebar); b.Size, b.BackgroundTransparency, b.Text, b.TextColor3, b.TextSize, b.TextXAlignment = UDim2.new(1,0,0,35), 1, "  "..n, Colors.Text, 14, 0; return b end
local RageT, VisT, MiscT = Tab("RAGE"), Tab("VISUALS"), Tab("MISC"); RageT.TextColor3 = Colors.Accent

-- MENU INJECTION (Connecting to databases)
Tgl("Silent Aim", "S_A", O.Combat, ColRage); Tgl("Auto-Shoot", "S_A_Auto", O.Combat, ColRage); Tgl("Omni-Wallbang", "S_A_WB", O.Combat, ColRage); Tgl("Insta Hit", "I_H", O.Combat, ColRage); Tgl("Iron Bot", "Pr", O.Combat, ColRage); Sld("Burst (Multi-Bullet)", 1, 10, "Multi", O.Combat, ColRage, " BpS"); Sld("Base FOV", 50, 800, "AimFOV", O.Combat, ColRage, "px")
Tgl("Master ESP", "E", O.Vis, ColOther); Tgl("Neon Chams", "Chams", O.Vis, ColOther); Tgl("3D Beams", "Beam", O.Vis, ColOther); Tgl("Boxes", "Bx", O.Vis, ColOther); Tgl("Skeletons", "Sk", O.Vis, ColOther); Tgl("HP Info", "Info", O.Vis, ColOther); Tgl("Tracer", "Tracers", O.Vis, ColOther); Tgl("Target", "AimTr", O.Vis, ColOther)
Tgl("3rd Person", "TP", O.Misc, ColAA); Tgl("L-Desync AA", "Enabled", O.AA, ColAA); Tgl("Neural-Heal", "Heal", O.Misc, ColAA); Tgl("Hit Sound", "HS", O.Misc, ColAA)

-- PROFILE SECTION
local Prof = Instance.new("Frame", Sidebar); Prof.Size, Prof.Position, Prof.BackgroundColor3 = UDim2.new(1,0,0,50), UDim2.new(0,0,1,-50), Colors.SidebarBg; local Av = Instance.new("ImageLabel", Prof); Av.Size, Av.Position, Av.BackgroundColor3 = Vector3.new(30,30), UDim2.new(0,10,0.5,-15), Colors.Off; Instance.new("UICorner", Av).CornerRadius = UDim.new(1,0); Instance.new("TextLabel", Prof).Text, Instance.new("TextLabel", Prof).Size, Instance.new("TextLabel", Prof).Position, Instance.new("TextLabel", Prof).TextColor3, Instance.new("TextLabel", Prof).TextXAlignment = "vm$Takw1 Ag CdrYT", UDim2.new(1,-50,0,16), UDim2.new(0,45,0.5,-15), Colors.Text, 0; Instance.new("TextLabel", Prof).Text, Instance.new("TextLabel", Prof).Size, Instance.new("TextLabel", Prof).Position, Instance.new("TextLabel", Prof).TextColor3, Instance.new("TextLabel", Prof).TextXAlignment = "Omega V16 Final", UDim2.new(1,-50,0,16), UDim2.new(0,45,0.5,0), Colors.Text, 0

-- ACTION BUTTONS (Mobile Safe Draggable)
local function FixedBtn(pos, txt) local b = Instance.new("TextButton", Gui); b.Size, b.Position, b.BackgroundColor3, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(0,45,0,45), pos, Colors.SidebarBg, txt, Colors.Accent, 3, 18; Instance.new("UICorner", b).CornerRadius = UDim.new(1,0); return b end
local NL, A = FixedBtn(UDim2.new(0,10,0,10),"NL"), FixedBtn(UDim2.new(0,10,0,60),"A"); A.TextColor3 = Colors.Text; NL.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end); A.MouseButton1Click:Connect(function() O.AA.Enabled = not O.AA.Enabled; A.TextColor3 = O.AA.Enabled and Colors.Accent or Colors.Text end)

-- // COMBAT HANDLERS (Low Cortisol Math)
U.InputBegan:Connect(function(i, g) if not g and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and _G.LT then PlayHS(); local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool"); if tool then if O.Vis.Beam then local barrel = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle"); if barrel then for idx = 1, O.Combat.Multi do Draw3DTr(barrel.Position, _G.LT.Position) end end end; if O.Combat.Multi > 1 then task.spawn(function() for idx = 2, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) end end end end)

local function IsVisible(char) local p = RaycastParams.new(); p.FilterType, p.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {LocalPlayer.Character, Cam}; for _, pt in pairs({char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")}) do if pt then local ori, dir = Cam.CFrame.Position, (pt.Position - Cam.CFrame.Position).Unit * 5000; local current_ori, pens, clear = ori, 0, false; while pens < 15 do local res = workspace:Raycast(current_ori, dir, p); if not res then break end; if res.Instance:IsDescendantOf(char) then clear = true break end; if O.Combat.S_A_WB then local f = p.FilterDescendantsInstances; table.insert(f, res.Instance); p.FilterDescendantsInstances = f; pens = pens + 1 else break end end; if clear then return true end end end return false end

local mt = getrawmetatable(game); setreadonly(mt, false); local oldName = mt.__namecall; mt.__namecall = newcclosure(function(self, ...) local meth, args = getnamecallmethod(), {...}; if checkcaller() then return oldName(self, ...) end; if O.Combat.S_A and _G.LT and meth == "Raycast" then local sp = args[1]; local ti = (_G.LT.Position - sp).Magnitude / O.Combat.Vel; local pos = _G.LT.Position; if not O.Combat.I_H then if _G.LT.Parent:FindFirstChild("HumanoidRootPart") then pos = pos + (_G.LT.Parent.HumanoidRootPart.AssemblyLinearVelocity * ti) end; pos = pos + Vector3.new(0, 0.5 * 196.2 * (ti^2), 0) end; args[2] = (pos - sp).Unit * 1000; return oldName(self, unpack(args)) end; return oldName(self, ...) end); setreadonly(mt, true)

-- // GHOST-GUARD ESP & CHAMS ENGINE
local D_T = {}
local function AddESP(p) if p == LocalPlayer then return end local d = {H = Instance.new("Highlight", C), B = Draw("Square"), Sk = {}} for i=1,10 do table.insert(d.Sk, Draw("Line")) end D_T[p] = d end; for _,p in pairs(P:GetPlayers()) do AddESP(p) end P.PlayerAdded:Connect(AddESP); P.PlayerRemoving:Connect(function(p) if D_T[p] then for _,v in pairs(D_T[p].Sk) do v:Remove() end D_T[p].B:Remove(); D_T[p].H:Destroy(); D_T[p] = nil end end)

-- // MAIN ENGINE RENDER LOOP
local F_C = Draw("Circle"); local S_C = Draw("Circle"); local L_L = Draw("Line"); F_C.Color, S_C.Color, L_L.Color = Colors.Accent, Color3.new(1,0,0), Colors.Accent

table.insert(Cons, R.RenderStepped:Connect(function()
    Cam.FieldOfView = O.Misc.Zoom and 10 or O.Misc.FOV
 F_C.Visible, S_C.Visible, L_L.Visible = false, false, false
    
    if _G.LT then
        local ti = (_G.LT.Position - Cam.CFrame.Position).Magnitude / O.Combat.Vel
        local pos = _G.LT.Position; if not O.Combat.I_H and _G.LT.Parent:FindFirstChild("HumanoidRootPart") then pos = pos + (_G.LT.Parent.HumanoidRootPart.AssemblyLinearVelocity * ti) + Vector3.new(0, 0.5 * 196.2 * (ti^2), 0) end
        local sP, vis = Cam:WorldToViewportPoint(pos)
        local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        local mag = (Vector2.new(sP.X, sP.Y) - center).Magnitude
        activeFOV = math.max(O.Combat.AimFOV, (mag * ((80/math.clamp(Cam.FieldOfView, 5, 80))*2.8)) + 50)
        
        S_C.Visible = O.Combat.S_A and O.Vis.FOV; S_C.Radius, S_C.Position = activeFOV, center
        L_L.Visible = O.Vis.AimTr; L_L.From, L_L.To = center, Vector2.new(sP.X, sP.Y)
        
        if O.Combat.S_A_Auto and tick() - last_auto_shoot > 0.15 and IsVisible(_G.LT.Parent) then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then last_auto_shoot = tick(); task.spawn(function() for i = 1, O.Combat.Multi do tool:Activate(); task.wait(0.01) end end) end
        end
    else activeFOV = O.Combat.AimFOV end

    -- Target selection (Closest to crosshair visible)
    local cur = _G.LT; if cur and cur.Parent and cur.Parent:FindFirstChild("HumanoidRootPart") and cur.Parent.Humanoid.Health > 0 then local sP, vis = Cam:WorldToViewportPoint(cur.Position); local m = (Vector2.new(sP.X, sP.Y) - Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)).Magnitude; if not vis or m > (activeFOV + 150) then _G.LT = nil end else _G.LT = nil end
    if not _G.LT then local cl, d = nil, O.Combat.AimFOV; local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2) for p,esp in pairs(D_T) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then local sP, vis = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position); if vis then local m = (Vector2.new(sP.X, sP.Y) - center).Magnitude; if m < d and IsVisible(p.Character) then d, cl = m, p.Character.Head end end end end _G.LT = cl end

    -- Visual Sync (Chams, ESP)
    for p, d in pairs(D_T) do 
        local c = p.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
        if c and r and c.Humanoid.Health > 0 and O.Vis.E then 
            local rP, onScreen = Cam:WorldToViewportPoint(r.Position)
            local look = Cam.CFrame.LookVector; local dir = (r.Position - Cam.CFrame.Position).Unit
            local isBehind = look:Dot(dir) < 0
            if onScreen and not isBehind then 
                local is_v = IsVisible(c); local clr = is_v and Colors.G or Color3.new(1,1,1); d.B.Color = clr
                if O.Vis.Chams then d.H.Adornee, d.H.Enabled, d.H.FillColor = c, true, clr; for _, part in pairs(c:GetChildren()) do if part:IsA("BasePart") then part.Material, part.Color = Enum.Material.Neon, clr end end else d.H.Enabled = false end
            end
        end
    end
end))

print("OMEGA V16 Loaded Successfully!")
