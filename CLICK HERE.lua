-- // CONFIGURATION & SERVICES \\ --
local P = game:GetService("Players")
local R = game:GetService("RunService")
local LocalPlayer = P.LocalPlayer
local Cam = workspace.CurrentCamera

-- // DRAWING OBJECTS
local TargetLine = Draw("Line"); TargetLine.Thickness, TargetLine.Color = 1.0, Colors.Accent
local FOV_Circle = Draw("Circle"); FOV_Circle.Thickness, FOV_Circle.Filled = 1.2, false; FOV_Circle.Color = Colors.Accent

-- // SHARED STATE & CACHE
_G.LT = nil -- Locked Target
local VisibilityCache = {} 
local last_auto_shoot = 0
local next_shot_delay = 0.1
local p_params = RaycastParams.new()
p_params.FilterType = Enum.RaycastFilterType.Exclude
p_params.IgnoreWater = true

-- HUMANIZATION CONSTANTS
local MAX_AOI = 5        -- Angle of Intent Limit (Degrees)
local SMOOTHNESS = 0.08  -- Lower = More "Human"
local SHAKE = 0.04       -- Procedural tremor intensity

-- // UTILITY: VISIBILITY (RECYCLED PARAMS)
local function IsVisible(char) 
    if not char or not char:FindFirstChild("Head") then return false end
    
    -- Update params once per check
    p_params.FilterDescendantsInstances = {LocalPlayer.Character, Cam}
    
    local origin = Cam.CFrame.Position
    local targetPos = char.Head.Position
    local result = workspace:Raycast(origin, (targetPos - origin), p_params)
    
    -- If the ray hits nothing or the target, it's visible
    return (not result or result.Instance:IsDescendantOf(char))
end

-- // SILENT AIM: THE STEALTH INTERCEPTOR \\ --
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Verify the call and ensuring a target is locked
    if not checkcaller() and O.Combat.S_A and _G.LT and (method == "Raycast" or method == "FindPartOnRay") then
        local targetPos = _G.LT.Position
        local origin = (method == "Raycast") and args[1] or args[1].Origin
        
        -- CALCULATION: Angle of Intent
        -- Ensures the bullet doesn't fly out at a weird angle relative to your face
        local camDir = Cam.CFrame.LookVector
        local targetDir = (targetPos - origin).Unit
        local dotProduct = camDir:Dot(targetDir)
        local angle = math.acos(math.clamp(dotProduct, -1, 1))
        
        if math.deg(angle) <= MAX_AOI then
            -- PREDICTION MATH: t = distance / velocity
            local dist = (targetPos - origin).Magnitude
            local velocity = O.Combat.Vel > 0 and O.Combat.Vel or 900
            local time = dist / velocity
            
            if not O.Combat.I_H then
                local hrp = _G.LT.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Lead: Pos + (Velocity * Time)
                    targetPos = targetPos + (hrp.AssemblyLinearVelocity * time) 
                    -- Drop: 0.5 * Gravity * Time^2
                    targetPos = targetPos + Vector3.new(0, (0.5 * workspace.Gravity * (time^2)), 0)
                end
            end
            
            -- Redirect the bullet vector
            local newDir = (targetPos - origin).Unit * 5000
            if method == "Raycast" then args[2] = newDir else args[1] = Ray.new(origin, newDir) end
        end
        
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

print("Part 1: Hooks and Math Loaded Successfully.")
-- // MAIN RENDER LOOP \\ --
table.insert(Cons, R.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    
    table.clear(VisibilityCache)
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local myHRP = myChar.HumanoidRootPart
    local tool = myChar:FindFirstChildOfClass("Tool")

    -- UPDATE WEAPON DATA
    if tool then
        for name, data in pairs(WeaponData) do
            if tool.Name:lower():find(name) then
                O.Combat.Vel = data.AP
                break
            end
        end
    end

    -- TARGET SELECTOR (CLOSET TO CROSSHAIR)
    local closestTarget = nil
    local maxDist = O.Vis.FOVSize
    
    for _, p in pairs(P:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local char = p.Character
            local head = char:FindFirstChild("Head")
            if head then
                local pos, onScreen = Cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < maxDist then
                        -- Check visibility before locking
                        local visible = IsVisible(char)
                        VisibilityCache[p.Name] = visible
                        
                        if visible then
                            maxDist = mag
                            closestTarget = head
                        end
                    end
                end
            end
        end
    end
    _G.LT = closestTarget

    -- EXECUTION: AIMBOT & TRIGGERBOT
    if _G.LT then
        -- AIMBOT: Lerp with Procedural Shake
        if O.Combat.AimBot then
            local noise = Vector3.new(
                math.noise(tick() * 2.5, 1), 
                math.noise(1, tick() * 2.5), 
                0
            ) * SHAKE
            
            local targetCF = CFrame.new(Cam.CFrame.Position, _G.LT.Position + noise)
            Cam.CFrame = Cam.CFrame:Lerp(targetCF, SMOOTHNESS)
        end
        
        -- JITTERED TRIGGERBOT: Prevents perfect pattern detection
        if O.Combat.S_A_Auto and (tick() - last_auto_shoot > next_shot_delay) and tool then
            last_auto_shoot = tick()
            next_shot_delay = math.random(8, 14) / 100 -- 0.08s to 0.14s
            tool:Activate()
        end
        
        -- SNAPLINE
        local targetScreenPos = Cam:WorldToViewportPoint(_G.LT.Position)
        TargetLine.Visible = true
        TargetLine.From, TargetLine.To = center, Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    else
        TargetLine.Visible = false
    end

    -- FOV & VISUALS
    FOV_Circle.Visible, FOV_Circle.Radius, FOV_Circle.Position = O.Vis.ShowFOV, O.Vis.FOVSize, center

    -- ESP SYSTEM
    for p, d in pairs(D_T) do
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and O.Vis.E then
            local hrp = char.HumanoidRootPart
            local screenPos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local is_vis = VisibilityCache[p.Name] or false
                local color = is_vis and Colors.Good or Color3.new(1, 1, 1)
                
                -- Dynamic Box Scaling
                local top = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bottom = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local h = math.abs(top.Y - bottom.Y)
                local w = h / 1.8
                
                d.B.Visible, d.B.Size, d.B.Color = O.Vis.Bx, Vector2.new(w, h), color
                d.B.Position = Vector2.new(screenPos.X - w/2, screenPos.Y - h/2)
                
                d.I.Visible = O.Vis.Info
                d.I.Text = string.format("[%d HP] %d m", char.Humanoid.Health, (hrp.Position - myHRP.Position).Magnitude)
                d.I.Position = Vector2.new(screenPos.X, bottom.Y + 5)
                
                if O.Vis.Chams then d.H.Enabled, d.H.FillColor = true, color else d.H.Enabled = false end
            else
                d.B.Visible, d.I.Visible, d.H.Enabled = false, false, false
            end
        else
            d.B.Visible, d.I.Visible, d.H.Enabled = false, false, false
        end
    end
end))

print("Part 2: Main Loop and ESP Loaded Successfully.")
