local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local connections = {}
local Window = Rayfield:CreateWindow({Name="Project Nova",Icon=0,LoadingTitle="Project Nova",LoadingSubtitle="by Nova Team",Theme="Default",DisableRayfieldPrompts=false,DisableBuildWarnings=true,ConfigurationSaving={Enabled=true,FolderName="ProjectNova",FileName="Config"},Discord={Enabled=false,Invite="",RememberJoins=false},KeySystem=false})
local TabToggles = Window:CreateTab("Toggles",4483362458)
local TabESP = Window:CreateTab("ESP",4483362458)
local TabLockOn = Window:CreateTab("Lock-On",4483362458)
local TabPlayer = Window:CreateTab("Player",4483362458)
local TabWorld = Window:CreateTab("World",4483362458)
local TabTools = Window:CreateTab("Tools",4483362458)
local TabHubs = Window:CreateTab("Hubs",4483362458)
local function exec(url) loadstring(game:HttpGet(url))() end
local function toggleFullBright(enabled)
    local id="FullBright"
    if enabled then
        local function applyBright()
            Lighting.ClockTime=12.0 Lighting.Brightness=0.9
            Lighting.Ambient=Color3.fromRGB(190,190,190)
            Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
            Lighting.FogEnd=9e9 Lighting.FogStart=9e9-1
            Lighting.ColorShift_Top=Color3.fromRGB(0,0,0)
        end
        applyBright()
        connections[id]=RunService.Heartbeat:Connect(applyBright)
    else
        if connections[id] then connections[id]:Disconnect() connections[id]=nil end
    end
end
local ESPSettings={Enabled=false,MaxDistance=1000}
local function togglePlayerESP(enabled)
    local id="PlayerESP" local HIGHLIGHT="Nova_ESP_Highlight"
    ESPSettings.Enabled=enabled
    if enabled then
        connections[id]={}
        local function isTarget(p)
            if not p or p==LocalPlayer then return false end
            if not p.Character then return false end
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 then return false end
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and myRoot then
                if(root.Position-myRoot.Position).Magnitude>ESPSettings.MaxDistance then return false end
            end
            return true
        end
        local function updateHL(p)
            local char=p.Character if not char then return end
            local hl=char:FindFirstChild(HIGHLIGHT)
            if isTarget(p) then
                if not hl then
                    hl=Instance.new("Highlight") hl.Name=HIGHLIGHT
                    hl.Adornee=char hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=char
                end
                local enemy=#Teams:GetTeams()>0 and LocalPlayer.Team and p.Team and LocalPlayer.Team~=p.Team
                hl.FillColor=enemy and Color3.fromRGB(255,80,120) or Color3.fromRGB(0,150,255)
                hl.OutlineColor=Color3.fromRGB(245,245,255) hl.FillTransparency=0.6 hl.OutlineTransparency=0.2 hl.Enabled=true
            else if hl then hl.Enabled=false end end
        end
        connections[id].distLoop=RunService.Heartbeat:Connect(function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then updateHL(p) end
            end
        end)
        local function setupPlayer(p)
            if connections[id][p] then return end connections[id][p]={}
            connections[id][p].ca=p.CharacterAdded:Connect(function(char)
                task.wait(0.1) updateHL(p)
                local hum=char:WaitForChild("Humanoid")
                if hum then connections[id][p].died=hum.Died:Connect(function() updateHL(p) end) end
            end)
            connections[id][p].cr=p.CharacterRemoving:Connect(function()
                if p.Character then local hl=p.Character:FindFirstChild(HIGHLIGHT) if hl then hl:Destroy() end end
            end)
            if p.Character then updateHL(p) end
        end
        for _,p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
        connections[id].pa=Players.PlayerAdded:Connect(setupPlayer)
        connections[id].pr=Players.PlayerRemoving:Connect(function(p)
            if connections[id][p] then for _,c in pairs(connections[id][p]) do c:Disconnect() end connections[id][p]=nil end
        end)
    else
        if connections[id] then
            for _,v in pairs(connections[id]) do
                if type(v)=="table" then for _,c in pairs(v) do c:Disconnect() end
                elseif type(v)=="userdata" then pcall(function() v:Disconnect() end) end
            end
            connections[id]=nil
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild(HIGHLIGHT) then p.Character[HIGHLIGHT]:Destroy() end
        end
    end
end
local function toggleNoClip(enabled)
    local id="NoClip"
    if enabled then
        connections[id]=RunService.Stepped:Connect(function()
            local char=LocalPlayer.Character if not char then return end
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    else if connections[id] then connections[id]:Disconnect() connections[id]=nil end end
end
local function toggleInfiniteJump(enabled)
    local id="InfiniteJump"
    if enabled then
        connections[id]=UserInputService.InputBegan:Connect(function(input,gp)
            if gp then return end
            if input.KeyCode==Enum.KeyCode.Space then
                local char=LocalPlayer.Character
                if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else if connections[id] then connections[id]:Disconnect() connections[id]=nil end end
end
local LockOnSettings={Smoothness=0.5,FOVRadius=150,MaxDistance=500,TeamCheck=false,AimPart="Head",StickyTarget=true,InstantSnap=false,Prediction=true,PredictAmount=0.08,BulletVelocity=true,BulletSpeed=500,GravityComp=true,Gravity=196.2}
local lockedTarget=nil local lastTargetPos=nil local lastTargetVel=Vector3.new(0,0,0)
local FOVGui=Instance.new("ScreenGui") FOVGui.Name="NovaFOVGui" FOVGui.ResetOnSpawn=false FOVGui.IgnoreGuiInset=true FOVGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
local FOVFrame=Instance.new("Frame") FOVFrame.BackgroundTransparency=1 FOVFrame.BorderSizePixel=0 FOVFrame.Visible=false FOVFrame.Parent=FOVGui
local FOVCorner=Instance.new("UICorner") FOVCorner.CornerRadius=UDim.new(1,0) FOVCorner.Parent=FOVFrame
local FOVStroke=Instance.new("UIStroke") FOVStroke.Color=Color3.fromRGB(0,150,255) FOVStroke.Thickness=2 FOVStroke.Parent=FOVFrame
local function refreshFOV()
    local r=LockOnSettings.FOVRadius local c=Camera.ViewportSize/2
    FOVFrame.Size=UDim2.new(0,r*2,0,r*2) FOVFrame.Position=UDim2.new(0,c.X-r,0,c.Y-r)
end
local function isValidTarget(p)
    if not p or p==LocalPlayer then return false end
    if not p.Character then return false end
    local hum=p.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false end
    local part=p.Character:FindFirstChild("HumanoidRootPart")
    local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if part and myRoot then if(part.Position-myRoot.Position).Magnitude>LockOnSettings.MaxDistance then return false end end
    if LockOnSettings.TeamCheck then
        if #Teams:GetTeams()>0 and LocalPlayer.Team and p.Team and LocalPlayer.Team==p.Team then return false end
    end
    return true
end
local function getClosestTarget()
    local center=Camera.ViewportSize/2 local best,bestDist=nil,LockOnSettings.FOVRadius
    for _,p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local part=p.Character:FindFirstChild(LockOnSettings.AimPart) or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local sp,onScreen=Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d<bestDist then bestDist=d best=p end
                end
            end
        end
    end
    return best
end
local function calculateAimPosition(part,myRoot,dt)
    local targetPos=part.Position
    local distance=(targetPos-myRoot.Position).Magnitude
    local travelTime=LockOnSettings.BulletVelocity and(distance/math.max(LockOnSettings.BulletSpeed,1)) or LockOnSettings.PredictAmount
    local leadOffset=Vector3.new(0,0,0)
    if LockOnSettings.Prediction and lastTargetPos then
        local rawVel=(targetPos-lastTargetPos)/math.max(dt,0.001)
        lastTargetVel=lastTargetVel:Lerp(rawVel,0.4) leadOffset=lastTargetVel*travelTime
    end
    local gravityOffset=Vector3.new(0,0,0)
    if LockOnSettings.BulletVelocity and LockOnSettings.GravityComp then
        gravityOffset=Vector3.new(0,0.5*LockOnSettings.Gravity*(travelTime^2),0)
    end
    return targetPos+leadOffset+gravityOffset
end
local function toggleLockOn(enabled)
    local id="LockOn"
    if enabled then
        FOVFrame.Visible=true refreshFOV()
        lastTargetPos=nil lastTargetVel=Vector3.new(0,0,0)
        connections[id]=RunService.Heartbeat:Connect(function(dt)
            refreshFOV()
            if lockedTarget then
                if not isValidTarget(lockedTarget) then
                    lockedTarget=nil lastTargetPos=nil lastTargetVel=Vector3.new(0,0,0)
                elseif not LockOnSettings.StickyTarget then
                    local part=lockedTarget.Character and(lockedTarget.Character:FindFirstChild(LockOnSettings.AimPart) or lockedTarget.Character:FindFirstChild("HumanoidRootPart"))
                    if part then
                        local sp,onScreen=Camera:WorldToViewportPoint(part.Position)
                        local d=(Vector2.new(sp.X,sp.Y)-Camera.ViewportSize/2).Magnitude
                        if not onScreen or d>LockOnSettings.FOVRadius then lockedTarget=nil lastTargetPos=nil lastTargetVel=Vector3.new(0,0,0) end
                    end
                end
            end
            if not lockedTarget then lockedTarget=getClosestTarget() lastTargetPos=nil lastTargetVel=Vector3.new(0,0,0) end
            if lockedTarget and lockedTarget.Character then
                local part=lockedTarget.Character:FindFirstChild(LockOnSettings.AimPart) or lockedTarget.Character:FindFirstChild("HumanoidRootPart")
                local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if part and myRoot then
                    local aimPos=calculateAimPosition(part,myRoot,dt)
                    lastTargetPos=part.Position
                    local goal=CFrame.new(Camera.CFrame.Position,aimPos)
                    if LockOnSettings.InstantSnap then Camera.CFrame=goal
                    else Camera.CFrame=Camera.CFrame:Lerp(goal,math.clamp(LockOnSettings.Smoothness,0.01,1)) end
                end
            end
        end)
    else
        FOVFrame.Visible=false lockedTarget=nil lastTargetPos=nil lastTargetVel=Vector3.new(0,0,0)
        if connections[id] then connections[id]:Disconnect() connections[id]=nil end
    end
end
print("Nova Part 1 Loaded")
