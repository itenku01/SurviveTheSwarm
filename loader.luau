--[[
    Survive The Swarm [ZOMBIES] - Universal GitHub Loader
    Repository: https://github.com/itenku01/SurviveTheSwarm
    
    วิธีรัน (1 บรรทัดจบ):
    loadstring(game:HttpGet("https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main/loader.luau"))()
--]]

local RAW_BASE = "https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main"
local SCRIPT_URL = RAW_BASE .. "/games/survive_the_swarm.luau"

-- ตรวจสอบ Place ID ที่รองรับ
local SUPPORTED_PLACES = {
    [100227226022278] = "Lobby",
    [139536658319600] = "Match Arena",
    [10741792653]     = "Universe GameId"
}

local currentPlaceName = SUPPORTED_PLACES[game.PlaceId] or SUPPORTED_PLACES[game.GameId]
if currentPlaceName then
    print(string.format("[SurviveTheSwarm] กำลังอยู่ในโซน: %s (PlaceId: %s)", currentPlaceName, tostring(game.PlaceId)))
else
    warn(string.format("[SurviveTheSwarm] ข้อความแจ้งเตือน: ตรวจพบ PlaceId ที่ไม่รู้จัก (%s) กำลังโหลดสคริปต์เพื่อทำงานต่อ", tostring(game.PlaceId)))
end

-- ระบบกันหลุดอัตโนมัติเมื่อวาร์ปข้ามแมพ (Teleport Persistence)
local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and game.Players.LocalPlayer then
    pcall(function()
        game.Players.LocalPlayer.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                qot(string.format([[
                    repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer
                    task.wait(1.5)
                    pcall(function()
                        loadstring(game:HttpGet("%s/loader.luau", true))()
                    end)
                ]], RAW_BASE))
            end
        end)
    end)
end

-- ดึงโค้ดเวอร์ชันล่าสุดจาก GitHub
print("[SurviveTheSwarm] กำลังดึงสคริปต์เวอร์ชันล่าสุดจาก GitHub...")
local success, scriptContent = pcall(function()
    return game:HttpGet(SCRIPT_URL, true)
end)

if success and scriptContent and #scriptContent > 0 then
    local execSuccess, execErr = pcall(function()
        loadstring(scriptContent)()
    end)
    if not execSuccess then
        warn("[SurviveTheSwarm] เกิดข้อผิดพลาดขณะเริ่มต้นสคริปต์:", tostring(execErr))
    else
        print("[SurviveTheSwarm] โหลดสคริปต์ v1.4.0 สำเร็จเรียบร้อยแล้ว!")
    end
else
    warn("[SurviveTheSwarm] ไม่สามารถดาวน์โหลดสคริปต์จาก GitHub ได้ โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
end
