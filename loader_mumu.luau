--[[
    ========================================================
    Roblox Executor MCP - Loader for MuMu Player (ตัวจำลอง)
    ========================================================
    นำโค้ดทั้งหมดนี้ไปวางใน Executor บน MuMu Player แล้วกด Execute
--]]

-- บังคับใช้ HTTP Polling เพื่อความเสถียรสูงสุดบน Android Emulator
getgenv().DisableWebSocket = true

-- ข้ามการ Decompile สคริปต์ทั้งแมพตอนเริ่ม เพื่อป้องกันเน็ตเวิร์กของตัวจำลองชนกันจนขึ้น ConnectFail
getgenv().DisableInitialScriptDecompMapping = true

-- รายการที่อยู่ IP ที่จะลองเชื่อมต่อ (ลอง LAN IP เครื่อง Host ก่อน ถ้าไม่ได้จะลอง Gateway จำลอง)
local candidateUrls = {
    "192.168.1.100:16384", -- IP ของคอมพิวเตอร์หลัก (Host PC)
    "10.0.2.2:16384",      -- Standard Android Loopback Gateway
    "localhost:16384"      -- Fallback
}

local connected = false

for _, url in ipairs(candidateUrls) do
    if getgenv().MCP_Loaded then break end
    print("[Roblox MCP] Trying to connect to: " .. url)
    
    local success, scriptContent = pcall(function()
        return game:HttpGet("http://" .. url .. "/script.luau")
    end)
    
    if success and scriptContent and #scriptContent > 50 then
        print("[Roblox MCP] Found server at: " .. url)
        getgenv().BridgeURL = url
        
        local runSuccess, runErr = pcall(function()
            loadstring(scriptContent)()
        end)
        
        if runSuccess then
            connected = true
            print("[Roblox MCP] Successfully loaded from: " .. url)
            break
        else
            warn("[Roblox MCP] Execution failed: " .. tostring(runErr))
        end
    else
        warn("[Roblox MCP] Could not reach: " .. url)
    end
end

if not connected and not getgenv().MCP_Loaded then
    warn("[Roblox MCP] FAILED: ไม่สามารถเชื่อมต่อไปยัง MCP Server ได้")
    warn("[Roblox MCP] ตรวจสอบว่าเซิร์ฟเวอร์เปิดอยู่ และ Windows Firewall ไม่ได้บล็อกพอร์ต 16384")
else
    -- แจ้งเตือนบนหน้าจอในเกม
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Roblox MCP Bridge",
            Text = "Connected to Antigravity IDE!",
            Duration = 5
        })
    end)
    
    -- Auto-persist bridge across teleports (Lobby <-> Game Match)
    local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qot and game.Players.LocalPlayer then
        pcall(function()
            game.Players.LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                    local url = getgenv().BridgeURL or "192.168.1.100:16384"
                    qot(string.format([[
                        repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer
                        task.wait(1.5)
                        pcall(function()
                            getgenv().DisableWebSocket = true
                            getgenv().DisableInitialScriptDecompMapping = true
                            getgenv().BridgeURL = "%s"
                            loadstring(game:HttpGet("http://%s/loader_mumu.luau"))()
                        end)
                    ]], url, url))
                end
            end)
        end)
    end
end

