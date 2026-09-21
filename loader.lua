--[[
    Survive The Swarm [ZOMBIES] - Universal GitHub Loader (.lua alias)
    Repository: https://github.com/itenku01/SurviveTheSwarm
    
    วิธีรัน (1 บรรทัดจบ):
    loadstring(game:HttpGet("https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main/loader.lua"))()
--]]

local RAW_BASE = "https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main"
local SCRIPT_URL = RAW_BASE .. "/games/survive_the_swarm.luau"

local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and game.Players.LocalPlayer then
    pcall(function()
        game.Players.LocalPlayer.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                qot(string.format([[
                    repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer
                    task.wait(1.5)
                    pcall(function()
                        loadstring(game:HttpGet("%s/loader.lua", true))()
                    end)
                ]], RAW_BASE))
            end
        end)
    end)
end

print("[SurviveTheSwarm] กำลังดึงสคริปต์เวอร์ชันล่าสุดจาก GitHub...")
local success, scriptContent = pcall(function()
    return game:HttpGet(SCRIPT_URL, true)
end)

if success and scriptContent and #scriptContent > 0 then
    local execSuccess, execErr = pcall(function()
        loadstring(scriptContent)()
    end)
    if not execSuccess then
        warn("[SurviveTheSwarm] ข้อผิดพลาด:", tostring(execErr))
    else
        print("[SurviveTheSwarm] โหลดสคริปต์เรียบร้อย!")
    end
else
    warn("[SurviveTheSwarm] ไม่สามารถดึงสคริปต์จาก GitHub ได้")
end
