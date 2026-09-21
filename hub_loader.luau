--[[
    Universal Game Hub Loader
    Supports: Survive The Swarm [ZOMBIES] (PlaceId: 100227226022278)
--]]

local supportedGames = {
    [100227226022278] = "games/survive_the_swarm.luau", -- Lobby
    [139536658319600] = "games/survive_the_swarm.luau", -- Game Match
    [10741792653] = "games/survive_the_swarm.luau"     -- Universe GameId
}

local gameScript = supportedGames[game.PlaceId] or supportedGames[game.GameId]

if gameScript then
    print(string.format("[Hub Loader] Detected game: %s (PlaceId: %s)", gameScript, tostring(game.PlaceId)))
    
    -- Teleport persistence queue
    local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qot and game.Players.LocalPlayer then
        pcall(function()
            game.Players.LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                    local bridgeUrl = getgenv().BridgeURL or "192.168.1.100:16384"
                    qot(string.format([[
                        repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer
                        task.wait(1.5)
                        pcall(function()
                            if isfile and isfile("hub_loader.luau") then
                                loadstring(readfile("hub_loader.luau"))()
                            elseif game.HttpGet then
                                loadstring(game:HttpGet("http://%s/hub_loader.luau"))()
                            end
                        end)
                    ]], bridgeUrl))
                end
            end)
        end)
    end

    -- Option 1: Load from local file if supported by executor
    if readfile and isfile and isfile(gameScript) then
        loadstring(readfile(gameScript))()
    else
        -- Option 2: Fallback to local MCP bridge or hosted URL
        local bridgeUrl = getgenv().BridgeURL or "localhost:16384"
        local ok, res = pcall(function()
            return game:HttpGet("http://" .. bridgeUrl .. "/" .. gameScript)
        end)
        if ok and res and #res > 0 then
            loadstring(res)()
        else
            warn("[Hub Loader] Could not fetch script from local bridge, please verify gameScript path.")
        end
    end
else
    warn(string.format("[Hub Loader] Unsupported PlaceId: %s / GameId: %s", tostring(game.PlaceId), tostring(game.GameId)))
end

