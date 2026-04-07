-- // OMEGA V18 SECURE LOADER \\ --

-- 1. link right here inside the quotes:
local GitHub_URL = "https://raw.githubusercontent.com/flyiz12345-del/Project-Delta-script-Actually-tuff-bromosito-/refs/heads/main/CLICK%20HERE.lua"

-- Send a loading notification to your screen
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "67",
    Text = "Fetching master build from GitHub...",
    Duration = 3,
})

-- Safely attempt to fetch and load the script
local success, errorMessage = pcall(function()
    loadstring(game:HttpGet(GitHub_URL))()
end)

-- Check if it worked or if GitHub blocked the connection
if success then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "OMEGA 67",
        Text = "Injection Successful! Have fun.",
        Duration = 5,
    })
    print("[OMEGA] Successfully injected remote payload.")
else
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ERROR",
        Text = "Failed to fetch script. Check Delta console.",
        Duration = 7,
    })
    warn("[OMEGA LOAD ERROR]: " .. tostring(errorMessage))
end
