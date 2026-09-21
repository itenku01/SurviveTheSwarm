-- STS Auto-Installer and Launcher
pcall(function()
    if not isfolder("SurviveTheSwarm") then makefolder("SurviveTheSwarm") end
    writefile("SurviveTheSwarm/main.luau", [=====[--[[
    ================================================================================
    Survive The Swarm [ZOMBIES] - Elite Mobile Hub & Smart Forge Engine
    Place ID: 100227226022278
    
    Features:
    - 5-Tier Weighted Smart Card Selection & Slot Reservation Engine
    - Smart Hover (14 studs) & Emergency High-Altitude Retreat (62 studs)
    - Anti-AFK, FPS Boost, Auto Reconnect, NoClip
    - Full Configuration & Autoload Manager (writefile / readfile)
    - Modern Dark / Hot-Pink Mobile Touch UI with Draggable FAB
    - Real-Time Manual Adjustments on Every Setting
    ================================================================================
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Clean up existing UI if reloaded
pcall(function()
    for _, location in ipairs({ PlayerGui, CoreGui, CoreGui:FindFirstChild("RobloxGui") }) do
        if location then
            for _, child in ipairs(location:GetChildren()) do
                if child.Name == "STS_MobileHub" then
                    child:Destroy()
                end
            end
        end
    end
    if getgenv().STS_RunningThread then
        task.cancel(getgenv().STS_RunningThread)
    end
end)

-- Universal Click / Input Simulator (firesignal + VirtualInputManager fallback)
local function SimulateClick(gui)
    if not gui then return end
    pcall(function()
        if firesignal then
            pcall(firesignal, gui.Activated)
            pcall(firesignal, gui.MouseButton1Click)
            pcall(firesignal, gui.MouseButton1Down)
            pcall(firesignal, gui.MouseButton1Up)
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim and gui:IsA("GuiObject") then
            local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
            if pos.X > 0 and pos.Y > 0 then
                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.04)
                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            end
        end
    end)
end

-- File System Safe Wrappers
local hasFileSystem = (writefile ~= nil and readfile ~= nil)
local CONFIG_DIR = "SurviveTheSwarm"
local CONFIG_SUBDIR = CONFIG_DIR .. "/Configs"
local AUTOLOAD_FILE = CONFIG_DIR .. "/autoload.txt"

if hasFileSystem then
    pcall(function()
        if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
        if not isfolder(CONFIG_SUBDIR) then makefolder(CONFIG_SUBDIR) end
    end)
end

-- Seamless Auto-Teleport Persistence (Lobby Place: 100227226022278 <-> Game Match Place: 139536658319600)
local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and LocalPlayer then
    pcall(function()
        LocalPlayer.OnTeleport:Connect(function(teleportState)
            if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
                pcall(function()
                    if hasFileSystem and writefile then
                        local snapshot = {
                            FarmEnabled = State.FarmEnabled,
                            AutoDraft = State.AutoDraft,
                            AutoReroll = State.AutoReroll,
                            TargetEvolutions = State.TargetEvolutions,
                            TargetPassives = State.TargetPassives,
                            HoverHeight = State.HoverHeight,
                            FlySpeed = State.FlySpeed,
                            SlotReservation = State.SlotReservation,
                            RetreatHealth = State.RetreatHealth,
                            RetreatResume = State.RetreatResume,
                            RetreatAltitude = State.RetreatAltitude,
                            CampAtExitPillar = State.CampAtExitPillar,
                            EmergencyExtractHP = State.EmergencyExtractHP
                        }
                        writefile(CONFIG_DIR .. "/_teleport_cache.json", HttpService:JSONEncode(snapshot))
                    end
                end)

                local bridgeUrl = getgenv().BridgeURL or "192.168.1.100:16384"
                local teleportScript = string.format([[
                    repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer
                    task.wait(1.5)
                    pcall(function()
                        if isfile and isfile("SurviveTheSwarm/main.luau") then
                            loadstring(readfile("SurviveTheSwarm/main.luau"))()
                        elseif isfile and isfile("games/survive_the_swarm.luau") then
                            loadstring(readfile("games/survive_the_swarm.luau"))()
                        elseif game.HttpGet then
                            loadstring(game:HttpGet("http://%s/games/survive_the_swarm.luau"))()
                        end

                    end)
                ]], bridgeUrl)
                
                qot(teleportScript)
                print("[STS] Teleport detected! Queued auto-reconnect for destination place.")
            end
        end)
    end)
end

-- ============================================================================
-- 1. FORGE DATABASE (Dynamic Game Extraction & Fallback)

-- ============================================================================
local ForgeDatabase = {}

-- Dynamically fetch official definitions directly from game memory
pcall(function()
    local evosMod = require(game:GetService("ReplicatedStorage").SharedBase.config.Evolutions)
    if evosMod and evosMod.defs then
        for evoName, def in pairs(evosMod.defs) do
            ForgeDatabase[evoName] = {
                name = evoName,
                ingredients = def.ingredients or {},
                tier = "Official"
            }
        end
    end
end)

-- Fallback defaults with exact official game ingredient names
if not ForgeDatabase["Arrowgeddon"] then
    ForgeDatabase["Arrowgeddon"] = { name = "Arrowgeddon", ingredients = { "Bow", "HeavensArrow" }, tier = "Mythic" }
    ForgeDatabase["Teslabot"] = { name = "Teslabot", ingredients = { "LightningStaff", "SteelSentinel" }, tier = "Legendary" }
    ForgeDatabase["Vesuvius"] = { name = "Vesuvius", ingredients = { "EarthSplitter", "CinderTrail" }, tier = "Legendary" }
    ForgeDatabase["Birdshot"] = { name = "Birdshot", ingredients = { "Gun", "FalconEye" }, tier = "Epic" }
    ForgeDatabase["Mint"] = { name = "Mint", ingredients = { "Sentry", "LuckyCoin" }, tier = "Epic" }
    ForgeDatabase["Crossfire"] = { name = "Crossfire", ingredients = { "Sword", "Gun" }, tier = "Epic" }
    ForgeDatabase["Jackpot"] = { name = "Jackpot", ingredients = { "LuckyCoin", "LoadedDice" }, tier = "Legendary" }
end

-- Official Passives Database (Extracted from ReplicatedStorage.SharedBase.config.Passives)
local PassivesDatabase = {}
pcall(function()
    local passivesMod = ReplicatedStorage:WaitForChild("SharedBase", 3):WaitForChild("config", 3):WaitForChild("Passives", 3)
    local data = require(passivesMod)
    local defs = data.defs or data
    for k, v in pairs(defs) do
        if type(v) == "table" then
            PassivesDatabase[k] = {
                id = k,
                name = v.name or v.title or k,
                blurb = v.blurb or v.description or v.desc or "",
                maxLevel = v.maxLevel or 8,
                icon = v.icon or ""
            }
        end
    end
end)

-- Fallback defaults for Passives (with official in-game icon asset IDs)
if not next(PassivesDatabase) then
    local fallbackPassives = {
        { id = "HorseshoeMagnet", name = "Horseshoe Magnet", blurb = "Pulls XP orbs from farther away.", icon = "rbxassetid://123239738297114" },
        { id = "Boots", name = "Swift Boots", blurb = "Makes you run faster.", icon = "rbxassetid://138291106779891" },
        { id = "Whetstone", name = "Whetstone", blurb = "Makes all your weapons hit harder.", icon = "rbxassetid://83359261024317" },
        { id = "MendingCharm", name = "Mending Charm", blurb = "Slowly heals you over time.", icon = "rbxassetid://138295585367294" },
        { id = "ParchmentOfGreed", name = "Parchment of Greed", blurb = "Chance to shoot an extra projectile.", icon = "rbxassetid://79051679409656" },
        { id = "DuelistsRing", name = "Duelist's Ring", blurb = "Lucky hits hit much harder.", icon = "rbxassetid://110393750243310" },
        { id = "PlateShoulders", name = "Plate Shoulders", blurb = "Extra max health.", icon = "rbxassetid://102395512517278" },
        { id = "IronGauntlet", name = "Iron Gauntlet", blurb = "Hits send enemies flying farther.", icon = "rbxassetid://78597873021795" },
        { id = "PhaseBoots", name = "Phase Boots", blurb = "Getting hit briefly boosts speed.", icon = "rbxassetid://105141452969871" },
        { id = "VoltVeil", name = "Volt Veil", blurb = "Hits sometimes chain lightning.", icon = "rbxassetid://110542135653825" },
        { id = "SparkPlug", name = "Spark Plug", blurb = "Hits sometimes zap enemies.", icon = "rbxassetid://96530136710997" },
        { id = "Thorns", name = "Thorns", blurb = "Enemies that hurt you get stung back.", icon = "rbxassetid://88348298724706" },
        { id = "InAPickle", name = "In a Pickle", blurb = "Blast shoves enemies when hurt.", icon = "rbxassetid://115431089930305" },
        { id = "ButcherKnife", name = "Butcher's Knife", blurb = "Boosts damage to bleeding foes.", icon = "rbxassetid://131323796537760" },
        { id = "PlateBoots", name = "Plate Boots", blurb = "Reduces damage taken.", icon = "rbxassetid://125747588457013" },
        { id = "Shuriken", name = "Shuriken", blurb = "Throws piercing stars at nearby foes.", icon = "rbxassetid://82699100917548" },
        { id = "GravesGrenade", name = "Grave's Grenade", blurb = "Drops an explosive grenade when struck.", icon = "rbxassetid://76074521085649" },
        { id = "MagnifyingGlass", name = "Magnifying Glass", blurb = "Increases weapon hit radius/area.", icon = "rbxassetid://108919491116821" }
    }
    for _, p in ipairs(fallbackPassives) do
        PassivesDatabase[p.id] = p
    end
end

-- General Beneficial Passives (Tier 4)
local BeneficialPassives = {
    ["Damage"] = true,
    ["Attack Power"] = true,
    ["Attack Speed"] = true,
    ["Cooldown"] = true,
    ["Max Health"] = true,
    ["Health Regen"] = true,
    ["Movement Speed"] = true,
    ["Pickup Range"] = true,
    ["Magnet"] = true,
    ["Critical Chance"] = true,
    ["Armor"] = true,
    ["Experience Boost"] = true,
    ["Luck"] = true
}

-- ============================================================================
-- 2. CONFIGURATION & STATE SYSTEM
-- ============================================================================
local State = {
    -- Farm
    FarmEnabled = false,
    FarmMode = "Hover", -- "Hover"
    HoverHeight = 14,
    FlySpeed = 60,
    RetreatHealth = 45,
    RetreatResume = 70,
    RetreatAltitude = 62,
    NoClip = true,
    AutoOrbs = true,
    OrbDangerRadius = 18,
    CollectMode = "Teleport",

    -- Smart Cards & Passives
    AutoDraft = true,
    AutoReroll = true,
    PrimaryTarget = "Arrowgeddon",
    SecondaryTarget = "Teslabot",
    TargetEvolutions = { "Arrowgeddon", "Teslabot", "Vesuvius" },
    TargetPassives = { "Horseshoe Magnet", "Swift Boots", "Whetstone" },
    SlotReservation = true,
    DraftDelay = 0.5,

    -- Utilities & Lifecycle
    AntiAfk = true,
    FpsBoost = false,
    AutoReconnect = true,
    NoGameplayPaused = true,
    HideUIOnStart = false,
    AutoStartGame = true,
    AutoReplay = true,
    EndGameAction = "Retry", -- "Retry" or "Lobby"
    StayForBonusWaves = true,
    CampExitOnBonus = true,
    EmergencyExtractHP = 15,
    BonusWavesToClear = 5,
    SkipCutscenes = true,

    -- Runtime Transient Status
    IsRetreating = false,
    BossDefeated = false,
    BonusWavesCleared = 0,
    CurrentGroundY = 0,
    CurrentHP = 100,
    MaxHP = 100,
    ActiveConfigName = "SSS"
}

-- Helper: Save Config to File
local function SaveConfigFile(name)
    if not hasFileSystem then return false, "No executor file system support" end
    local payload = {
        FarmEnabled = State.FarmEnabled,
        FarmMode = State.FarmMode,
        HoverHeight = State.HoverHeight,
        FlySpeed = State.FlySpeed,
        RetreatHealth = State.RetreatHealth,
        RetreatResume = State.RetreatResume,
        RetreatAltitude = State.RetreatAltitude,
        NoClip = State.NoClip,
        AutoOrbs = State.AutoOrbs,
        OrbDangerRadius = State.OrbDangerRadius,
        CollectMode = State.CollectMode,
        AutoDraft = State.AutoDraft,
        AutoReroll = State.AutoReroll,
        PrimaryTarget = State.PrimaryTarget,
        SecondaryTarget = State.SecondaryTarget,
        TargetEvolutions = State.TargetEvolutions,
        TargetPassives = State.TargetPassives,
        SlotReservation = State.SlotReservation,
        DraftDelay = State.DraftDelay,
        AntiAfk = State.AntiAfk,
        FpsBoost = State.FpsBoost,
        AutoReconnect = State.AutoReconnect,
        NoGameplayPaused = State.NoGameplayPaused,
        HideUIOnStart = State.HideUIOnStart,
        EndGameAction = State.EndGameAction,
        SkipCutscenes = State.SkipCutscenes
    }


    local filePath = CONFIG_SUBDIR .. "/" .. name .. ".json"
    local jsonStr = HttpService:JSONEncode(payload)
    local ok, err = pcall(function()
        writefile(filePath, jsonStr)
    end)
    return ok, err
end

-- Helper: Load Config from File
local function LoadConfigFile(name)
    if not hasFileSystem then return false, "No executor file system support" end
    local filePath = CONFIG_SUBDIR .. "/" .. name .. ".json"
    if not isfile(filePath) then return false, "Config file not found" end

    local content = readfile(filePath)
    local ok, parsed = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if ok and type(parsed) == "table" then
        for k, v in pairs(parsed) do
            if State[k] ~= nil then
                State[k] = v
            end
        end
        State.ActiveConfigName = name
        return true, parsed
    end
    return false, "Failed to parse JSON"
end

-- Helper: Get List of Configs
local function GetConfigList()
    local list = {}
    if not hasFileSystem then return { "Default", "SSS" } end
    local ok, files = pcall(function()
        return listfiles(CONFIG_SUBDIR)
    end)
    if ok and type(files) == "table" then
        for _, fullPath in ipairs(files) do
            local cleanName = fullPath:match("([^/\\]+)%.json$")
            if cleanName then
                table.insert(list, cleanName)
            end
        end
    end
    if #list == 0 then
        table.insert(list, "SSS")
    end
    return list
end

-- Helper: Set Autoload
local function SetAutoload(name)
    if not hasFileSystem then return false end
    local ok = pcall(function()
        writefile(AUTOLOAD_FILE, name)
    end)
    return ok
end

-- Helper: Get Autoload
local function GetAutoload()
    if not hasFileSystem then return "SSS" end
    if isfile(AUTOLOAD_FILE) then
        local ok, val = pcall(function()
            return readfile(AUTOLOAD_FILE):gsub("%s+", "")
        end)
        if ok and val ~= "" then return val end
    end
    return "SSS"
end

-- Helper: Reset Autoload
local function ResetAutoload()
    if not hasFileSystem then return false end
    if isfile(AUTOLOAD_FILE) then
        pcall(function() delfile(AUTOLOAD_FILE) end)
    end
    return true
end

-- Initialize Autoload on startup
local autoloadName = GetAutoload()
if autoloadName and autoloadName ~= "" then
    local loaded, _ = LoadConfigFile(autoloadName)
    if not loaded then
        -- Default SSS Preset
        SaveConfigFile("SSS")
        State.ActiveConfigName = "SSS"
    end
end

-- ============================================================================
-- 3. 5-TIER SMART CARD & FORGE ENGINE
-- ============================================================================
local function GetCharacterOwnedItems()
    local owned = {}
    local char = LocalPlayer.Character
    if not char then return owned end

    -- Check player backpack and tools
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                owned[tool.Name:lower()] = true
            end
        end
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            owned[item.Name:lower()] = true
        end
    end
    return owned
end

-- Score a card candidate (5-Tier Multi-Target Weighted Logic)
local function ScoreCardCandidate(cardTitle, ownedItems)
    local titleLower = cardTitle:lower()
    
    -- Tier 1: Multi-Target Evolutions (Priority ranked in order of selection)
    if State.TargetEvolutions and #State.TargetEvolutions > 0 then
        for rank, targetName in ipairs(State.TargetEvolutions) do
            local evo = ForgeDatabase[targetName]
            if evo and evo.ingredients then
                for _, ingredient in ipairs(evo.ingredients) do
                    if titleLower:find(ingredient:lower(), 1, true) then
                        local weight = math.max(1100 - (rank * 100), 500)
                        return weight, "Target Evo #" .. rank .. " (" .. targetName .. " -> " .. ingredient .. ")"
                    end
                end
            end
        end
    end

    -- Tier 2: Multi-Target Passives (Priority ranked in order of selection)
    if State.TargetPassives and #State.TargetPassives > 0 then
        for rank, passiveName in ipairs(State.TargetPassives) do
            local pLower = passiveName:lower()
            local matches = false
            if titleLower:find(pLower, 1, true) then
                matches = true
            else
                for word in pLower:gmatch("%w+") do
                    if #word >= 4 and titleLower:find(word, 1, true) then
                        matches = true
                        break
                    end
                end
            end
            if matches then
                local weight = math.max(750 - (rank * 40), 450)
                return weight, "Target Passive #" .. rank .. " (" .. passiveName .. ")"
            end
        end
    end

    -- Tier 3: Upgrading Already Owned Weapons/Passives (Weight: 300)
    for ownedName, _ in pairs(ownedItems) do
        if titleLower:find(ownedName, 1, true) then
            return 300, "Tier 3: Upgrade Owned (" .. ownedName .. ")"
        end
    end

    -- Tier 4: General Helpful Stat Passives (Weight: 100)
    for passiveName, _ in pairs(BeneficialPassives) do
        if titleLower:find(passiveName:lower(), 1, true) then
            return 100, "Tier 4: Beneficial Passive (" .. passiveName .. ")"
        end
    end

    -- Tier 5: Safe Anti-Stuck Fallback (Weight: 10)
    return 10, "Tier 5: Fallback"
end

-- Inspect and pick cards from Draft Modal
local function ProcessCardDraft()
    if not State.AutoDraft then return end

    local stackUp = PlayerGui:FindFirstChild("StackUp")
    if not stackUp then return end
    local modals = stackUp:FindFirstChild("Frame") and stackUp.Frame:FindFirstChild("SafeArea") and stackUp.Frame.SafeArea:FindFirstChild("Modals")
    if not modals or #modals:GetChildren() == 0 then return end

    local ownedItems = GetCharacterOwnedItems()
    local bestCard = nil
    local bestScore = -1
    local rerollButton = nil

    -- Scan descendants of Modals for card buttons and reroll buttons
    for _, desc in ipairs(modals:GetDescendants()) do
        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
            local descName = desc.Name:lower()
            if descName:find("reroll") or descName:find("roll") then
                rerollButton = desc
            else
                -- Find card title
                local cardTitle = desc.Name
                for _, child in ipairs(desc:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Text ~= "" and #child.Text > 2 then
                        cardTitle = child.Text
                        break
                    end
                end

                local score, reason = ScoreCardCandidate(cardTitle, ownedItems)
                if score > bestScore then
                    bestScore = score
                    bestCard = { button = desc, title = cardTitle, score = score, reason = reason }
                end
            end
        end
    end

    -- If no good card (score <= 10) and Reroll is enabled & available, reroll!
    if bestScore <= 10 and State.AutoReroll and rerollButton and rerollButton.Visible then
        task.wait(State.DraftDelay)
        SimulateClick(rerollButton)
        return
    end

    -- Otherwise pick the highest-ranked card
    if bestCard and bestCard.button then
        task.wait(State.DraftDelay)
        SimulateClick(bestCard.button)
    end
end

-- ============================================================================
-- 4. AUTO FARM & SURVIVAL ENGINE
-- ============================================================================
local function GetGroundHeight(pos)
    local rayOrigin = pos + Vector3.new(0, 10, 0)
    local rayDir = Vector3.new(0, -100, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }
    end

    local result = workspace:Raycast(rayOrigin, rayDir, raycastParams)
    if result then
        return result.Position.Y
    end
    return pos.Y - 14
end

-- Run Farm Physics on Stepped Loop
local lastDraftCheck = 0
RunService.Stepped:Connect(function(time, deltaTime)
    -- 1. Process Draft Modal periodically
    if tick() - lastDraftCheck > 0.6 then
        lastDraftCheck = tick()
        pcall(ProcessCardDraft)
    end

    -- 2. Character & Health Monitoring
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    State.CurrentHP = math.floor(hum.Health)
    State.MaxHP = math.floor(hum.MaxHealth)
    local hpPercent = (hum.Health / math.max(hum.MaxHealth, 1)) * 100

    -- 3. NoClip
    if State.NoClip and State.FarmEnabled then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- 4. Farm Movement
    if not State.FarmEnabled then return end

    -- Emergency Retreat Logic
    if State.IsRetreating then
        if hpPercent >= State.RetreatResume then
            State.IsRetreating = false
        end
    else
        if hpPercent <= State.RetreatHealth then
            State.IsRetreating = true
        end
    end

    local groundY = GetGroundHeight(hrp.Position)
    State.CurrentGroundY = groundY

    local targetY = groundY + State.HoverHeight
    if State.IsRetreating then
        targetY = groundY + State.RetreatAltitude
    end

    -- Smooth Hover / Ascend velocity
    local yDiff = targetY - hrp.Position.Y
    local yVelocity = math.clamp(yDiff * 6, -State.FlySpeed, State.FlySpeed)

    -- POST-BOSS BONUS WAVES: Camp directly at Exit Pillar / Pad
    local exitPadPos, exitPadPart = nil, nil
    local tz = workspace:FindFirstChild("TeleportZones")
    if tz then
        for _, zone in ipairs(tz:GetChildren()) do
            local anchor = zone:FindFirstChild("TeleportAnchor") or zone:FindFirstChildWhichIsA("BasePart")
            if anchor then exitPadPos = anchor.Position; exitPadPart = anchor; break end
        end
    end
    if not exitPadPos then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("gatepad") or n:find("exit") or n:find("teleportanchor") or n:find("sallygate") then
                    exitPadPos = obj.Position; exitPadPart = obj; break
                end
            end
        end
    end

    if State.BossDefeated and State.CampExitOnBonus and exitPadPos then
        -- Hover directly above Exit Pad
        local padTarget = Vector3.new(exitPadPos.X, targetY, exitPadPos.Z)
        local diff = padTarget - hrp.Position
        hrp.AssemblyLinearVelocity = Vector3.new(
            math.clamp(diff.X * 3, -State.FlySpeed, State.FlySpeed),
            yVelocity,
            math.clamp(diff.Z * 3, -State.FlySpeed, State.FlySpeed)
        )

        -- EMERGENCY EXTRACTION: If HP <= EmergencyExtractHP (10-15%), step on pad immediately!
        if hpPercent <= State.EmergencyExtractHP and exitPadPart then
            hrp.CFrame = exitPadPart.CFrame + Vector3.new(0, 2, 0)
            pcall(function()
                for _, prompt in ipairs(exitPadPart:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        fireproximityprompt(prompt)
                    end
                end
            end)
            print(string.format("[STS Hub] 🚨 HP Critical (%.0f%%)! Extracted safely at Exit Pillar!", hpPercent))
            return
        end
    else
        hrp.AssemblyLinearVelocity = Vector3.new(0, yVelocity, 0)
    end

    -- 5. Safe Orb & Item Collection (Supports Workspace.RaidLoot + Teleport & Glide)
    if State.AutoOrbs and not State.IsRetreating then
        local targetDrop = nil
        local closestDist = math.huge

        local candidates = {}
        local raidLoot = workspace:FindFirstChild("RaidLoot")
        if raidLoot then
            for _, item in ipairs(raidLoot:GetChildren()) do
                table.insert(candidates, item)
            end
        end
        local xpVisuals = workspace:FindFirstChild("XpOrbVisuals")
        if xpVisuals then
            for _, item in ipairs(xpVisuals:GetChildren()) do
                table.insert(candidates, item)
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("gem") or obj.Name:lower():find("orb") or obj.Name:lower():find("coin") or obj.Name:lower():find("drop")) then
                table.insert(candidates, obj)
            end
        end

        for _, item in ipairs(candidates) do
            local p = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
            if p then
                local dist = (p.Position - hrp.Position).Magnitude
                if dist < 85 and dist < closestDist then
                    closestDist = dist
                    targetDrop = p
                end
            end
        end

        if targetDrop then
            if State.CollectMode == "Teleport" then
                -- Instant snap to touch and snap back up
                local origCF = hrp.CFrame
                hrp.CFrame = CFrame.new(targetDrop.Position + Vector3.new(0, 1.2, 0))
                task.delay(0.04, function()
                    if hrp and hrp.Parent then
                        hrp.CFrame = CFrame.new(origCF.Position.X, targetY, origCF.Position.Z)
                    end
                end)
            else
                local dir = (targetDrop.Position - hrp.Position).Unit
                hrp.AssemblyLinearVelocity = Vector3.new(dir.X * State.FlySpeed, yVelocity, dir.Z * State.FlySpeed)
            end
        end
    end
end)

-- ============================================================================
-- 5. UTILITIES (Anti-AFK, FPS Boost, Auto Reconnect)
-- ============================================================================
-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if State.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- FPS Boost
local function ApplyFpsBoost(enable)
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = not enable
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = enable and 1 or 0
            elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = not enable
            end
        end
    end)
end

-- Auto Reconnect on Kick
pcall(function()
    local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
    if promptGui then
        local overlay = promptGui:WaitForChild("promptOverlay", 5)
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if State.AutoReconnect and child.Name == "ErrorPrompt" then
                    task.wait(2)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
        end
    end
end)

-- Game Lifecycle & Post-Boss Bonus Waves Engine
task.spawn(function()
    -- Hook BossService FightWon
    pcall(function()
        for _, desc in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if desc.Name == "FightWon" and desc:IsA("RemoteEvent") then
                desc.OnClientEvent:Connect(function(...)
                    State.BossDefeated = true
                    print("[STS Hub] 🏆 Stage Boss Defeated! Staying to farm bonus reward waves...")
                end)
            end
        end
    end)

    -- Cutscene Skipper Hook (Drop Pod & Boss Arrivals)
    pcall(function()

        local ok, CC = pcall(function()
            return require(LocalPlayer.PlayerScripts.SharedClient.controllers.CutsceneController)
        end)
        if ok and CC and CC.Play then
            local origPlay = CC.Play
            CC.Play = function(self, ...)
                if State.SkipCutscenes then
                    task.spawn(function()
                        task.wait(0.02)
                        pcall(function() self:Stop() end)
                        pcall(function()
                            if workspace.CurrentCamera then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
                        end)
                    end)
                    return
                end
                return origPlay(self, ...)
            end
        end
    end)

    while true do
        task.wait(1.0)
        pcall(function()
            local stackUp = PlayerGui:FindFirstChild("StackUp")
            if not stackUp then return end
            local safeArea = stackUp:FindFirstChild("Frame") and stackUp.Frame:FindFirstChild("SafeArea")
            if not safeArea then return end

            -- Cutscene Skipper Active Monitor
            if State.SkipCutscenes then
                pcall(function()
                    local CC = require(LocalPlayer.PlayerScripts.SharedClient.controllers.CutsceneController)
                    if CC and CC.IsPlaying and CC:IsPlaying() then
                        CC:Stop()
                        if workspace.CurrentCamera then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
                    end
                    local cl = safeArea:FindFirstChild("CutsceneLayer")
                    if cl and cl.Visible then cl.Visible = false end
                end)
            end


            -- 1. Auto Start & Auto Launch (Lobby & In-Match Drop Pod)
            if State.AutoStartGame then
                -- Method A: Universal Screen Scan for ANY "LAUNCH" or "START RUN" or "READY" Button
                pcall(function()
                    for _, obj in ipairs(PlayerGui:GetDescendants()) do
                        if obj.Name ~= "STS_MobileHub" and not obj:IsDescendantOf(CoreGui) then
                            local isLaunch = false
                            local targetBtn = nil

                            -- If it's a TextLabel with "LAUNCH"
                            if obj:IsA("TextLabel") and obj.Visible and (obj.Text:lower():find("launch") or obj.Text:lower():find("start run")) then
                                targetBtn = obj:FindFirstAncestorWhichIsA("GuiButton") 
                                    or (obj.Parent and obj.Parent:FindFirstChildWhichIsA("GuiButton"))
                                    or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent:FindFirstChildWhichIsA("GuiButton"))
                                if targetBtn then
                                    isLaunch = true
                                end
                            -- If it's a GuiButton with "launch" in name, text, or any child text
                            elseif obj:IsA("GuiButton") and obj.Visible then
                                local txt = (obj:IsA("TextButton") and obj.Text or obj.Name):lower()
                                for _, c in ipairs(obj:GetDescendants()) do
                                    if c:IsA("TextLabel") and c.Visible then
                                        txt = txt .. " " .. c.Text:lower()
                                    end
                                end
                                if txt:find("launch") or txt:find("start run") or txt:find("ready") then
                                    isLaunch = true
                                    targetBtn = obj
                                end
                            end

                            if isLaunch and targetBtn then
                                SimulateClick(targetBtn)
                                break
                            end
                        end
                    end
                end)

                -- Method B: Lobby Bottom Play Button
                if safeArea then
                    local playBtn = safeArea:FindFirstChild("PlayButton")
                    if playBtn and playBtn.Visible then
                        local artBtn = playBtn:FindFirstChild("Art") or playBtn:FindFirstChildWhichIsA("GuiButton")
                        if artBtn and artBtn.Visible then
                            SimulateClick(artBtn)
                        end
                    end
                end

                -- Method C: Knit Controller Launch / Start Run
                pcall(function()
                    local PS = LocalPlayer:FindFirstChild("PlayerScripts")
                    if PS then
                        local RLC = PS.Client.controllers:FindFirstChild("RoomLaunchController")
                        if RLC then
                            local mod = require(RLC)
                            if type(mod) == "table" then
                                if mod.Launch then mod:Launch() end
                                if mod.StartRun then mod:StartRun() end
                            end
                        end
                    end
                -- Method D: Direct DropPodService RemoteFunction Launch
                pcall(function()
                    local knitSvc = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index")
                    if knitSvc then
                        local rf = knitSvc["sleitnick_knit@1.7.0"].knit.Services.DropPodService.RF:FindFirstChild("Launch")
                        if rf and rf:IsA("RemoteFunction") then
                            task.spawn(function()
                                pcall(function() rf:InvokeServer() end)
                            end)
                        end
                    end
                end)
            end

            -- 2. Match End Handler (Auto Retry / Return to Lobby)
            if State.AutoReplay then
                -- Check if still farming bonus waves after boss
                if State.StayForBonusWaves and State.BossDefeated and State.BonusWavesCleared < State.BonusWavesToClear then
                    -- Continue farming bonus waves!
                else
                    -- Method A: Direct DirectorService Remote Invocation
                    pcall(function()
                        local knitSvc = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index")
                        if knitSvc then
                            local ds = knitSvc["sleitnick_knit@1.7.0"].knit.Services:FindFirstChild("DirectorService")
                            if ds and ds:FindFirstChild("RF") then
                                if State.EndGameAction == "Lobby" then
                                    local rfLobby = ds.RF:FindFirstChild("ReturnToLobby")
                                    if rfLobby then
                                        task.spawn(function()
                                            pcall(function() rfLobby:InvokeServer() end)
                                            State.BossDefeated = false
                                            State.BonusWavesCleared = 0
                                        end)
                                    end
                                else
                                    local rfRetry = ds.RF:FindFirstChild("Retry")
                                    if rfRetry then
                                        task.spawn(function()
                                            pcall(function() rfRetry:InvokeServer() end)
                                            State.BossDefeated = false
                                            State.BonusWavesCleared = 0
                                        end)
                                    end
                                end
                            end
                        end
                    end)

                    -- Method B: UI Button Scan Fallback
                    pcall(function()
                        for _, desc in ipairs(PlayerGui:GetDescendants()) do
                            if desc:IsA("GuiButton") and desc.Visible and desc.Name ~= "STS_MobileHub" and not desc:IsDescendantOf(CoreGui) then
                                local txt = (desc:IsA("TextButton") and desc.Text or desc.Name):lower()
                                for _, c in ipairs(desc:GetDescendants()) do
                                    if c:IsA("TextLabel") and c.Visible then
                                        txt = txt .. " " .. c.Text:lower()
                                    end
                                end

                                if State.EndGameAction == "Lobby" then
                                    if txt:find("return") or txt:find("lobby") or txt:find("leave") then
                                        task.wait(0.5)
                                        SimulateClick(desc)
                                        State.BossDefeated = false
                                        State.BonusWavesCleared = 0
                                        break
                                    end
                                else
                                    if txt:find("retry") or txt:find("play again") or txt:find("again") or txt:find("restart") or txt:find("claim") then
                                        task.wait(0.5)
                                        SimulateClick(desc)
                                        State.BossDefeated = false
                                        State.BonusWavesCleared = 0
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end

        end)
    end
end)

-- ============================================================================
-- 6. MODERN TOUCH UI (Dark / Hot-Pink Mobile Experience)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "STS_MobileHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or PlayerGui
    end
end)

-- Theme Colors
local Theme = {
    Bg = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(26, 26, 32),
    Card = Color3.fromRGB(34, 34, 42),
    Accent = Color3.fromRGB(255, 42, 133), -- Hot Pink (#FF2A85)
    AccentGlow = Color3.fromRGB(255, 100, 180),
    Text = Color3.fromRGB(245, 245, 250),
    TextDim = Color3.fromRGB(150, 150, 170),
    ToggleOff = Color3.fromRGB(60, 60, 75),
    Border = Color3.fromRGB(48, 48, 60)
}

-- Helper to dynamically pull official card icons from client catalog or PassivesDatabase
local function GetCardIcon(category, name)
    local ok, icon = pcall(function()
        local catalog = require(LocalPlayer.PlayerScripts.SharedClient.components.armory.catalog)
        local data = catalog.info(category, name)
        return data and data.icon
    end)
    if ok and type(icon) == "string" and icon ~= "" then
        return icon
    end
    if category == "passive" then
        local p = PassivesDatabase[name]
        if p and p.icon and p.icon ~= "" then return p.icon end
        for _, v in pairs(PassivesDatabase) do
            if v.name == name and v.icon and v.icon ~= "" then
                return v.icon
            end
        end
    end
    return ""
end

-- ----------------------------------------------------------------------------
-- Draggable Floating Action Button (FAB) for Mobile
-- ----------------------------------------------------------------------------
local FabButton = Instance.new("TextButton")
FabButton.Name = "STS_FAB"
FabButton.Size = UDim2.new(0, 52, 0, 52)
FabButton.Position = UDim2.new(0.04, 0, 0.25, 0)
FabButton.BackgroundColor3 = Theme.Bg
FabButton.TextColor3 = Theme.Accent
FabButton.Text = "⚡"
FabButton.TextSize = 22
FabButton.Font = Enum.Font.GothamBold
FabButton.BorderSizePixel = 0
FabButton.Parent = ScreenGui

local FabCorner = Instance.new("UICorner")
FabCorner.CornerRadius = UDim.new(0, 26)
FabCorner.Parent = FabButton

local FabStroke = Instance.new("UIStroke")
FabStroke.Color = Theme.Accent
FabStroke.Thickness = 2.5
FabStroke.Parent = FabButton

-- Touch Drag Logic for FAB
local isDraggingFab = false
local dragStartPos = nil
local fabStartPos = nil
local hasMoved = false

FabButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingFab = true
        dragStartPos = input.Position
        fabStartPos = FabButton.Position
        hasMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingFab and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            hasMoved = true
        end
        FabButton.Position = UDim2.new(
            fabStartPos.X.Scale,
            fabStartPos.X.Offset + delta.X,
            fabStartPos.Y.Scale,
            fabStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ----------------------------------------------------------------------------
-- Main Hub Window
-- ----------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = not State.HideUIOnStart
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Tap FAB toggles UI
FabButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingFab = false
        if not hasMoved then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Theme.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 12)
TitleBarCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -115, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SURVIVE THE SWARM  ⚡  เมนูมือถือ"
TitleLabel.TextColor3 = Theme.Accent
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -76, 0, 5)
MinimizeBtn.BackgroundColor3 = Theme.Card
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.Text = "-"
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Text = "X"
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Navigation Sidebar (Tabs)
local NavSidebar = Instance.new("Frame")
NavSidebar.Name = "NavSidebar"
NavSidebar.Size = UDim2.new(0, 140, 1, -42)
NavSidebar.Position = UDim2.new(0, 0, 0, 42)
NavSidebar.BackgroundColor3 = Theme.Panel
NavSidebar.BorderSizePixel = 0
NavSidebar.Parent = MainFrame

local NavListLayout = Instance.new("UIListLayout")
NavListLayout.Padding = UDim.new(0, 6)
NavListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavListLayout.Parent = NavSidebar

local NavPadding = Instance.new("UIPadding")
NavPadding.PaddingTop = UDim.new(0, 10)
NavPadding.PaddingLeft = UDim.new(0, 8)
NavPadding.PaddingRight = UDim.new(0, 8)
NavPadding.Parent = NavSidebar

-- Content Area (Pages)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -140, 1, -42)
ContentArea.Position = UDim2.new(0, 140, 0, 42)
ContentArea.BackgroundColor3 = Theme.Bg
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

-- Page Factory
local Pages = {}
local TabButtons = {}

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Theme.Accent
    page.Visible = false
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)

    page.Parent = ContentArea

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 30)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = page

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
    end)

    Pages[name] = page
    return page
end

local function SwitchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Color3.new(1, 1, 1)
        else
            btn.BackgroundColor3 = Theme.Card
            btn.TextColor3 = Theme.TextDim
        end
    end
end

local function AddNavTab(name, displayName, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Theme.Card
    btn.TextColor3 = Theme.TextDim
    btn.Text = displayName or name
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    btn.Parent = NavSidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    TabButtons[name] = btn
end

-- ----------------------------------------------------------------------------
-- UI Widget Generators (Toggle, Slider, Dropdown, Button)
-- ----------------------------------------------------------------------------
local function CreateToggleWidget(parent, labelText, initialVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 44, 0, 24)
    switch.Position = UDim2.new(1, -54, 0.5, -12)
    switch.BackgroundColor3 = initialVal and Theme.Accent or Theme.ToggleOff
    switch.Text = ""
    switch.BorderSizePixel = 0
    switch.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 12)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = initialVal and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 9)
    knobCorner.Parent = knob

    local currentVal = initialVal
    switch.MouseButton1Click:Connect(function()
        currentVal = not currentVal
        local targetColor = currentVal and Theme.Accent or Theme.ToggleOff
        local targetKnobPos = currentVal and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

        TweenService:Create(switch, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), { Position = targetKnobPos }):Play()
        callback(currentVal)
    end)

    return {
        SetValue = function(newVal)
            currentVal = newVal
            switch.BackgroundColor3 = currentVal and Theme.Accent or Theme.ToggleOff
            knob.Position = currentVal and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        end
    }
end

local function CreateSliderWidget(parent, labelText, minVal, maxVal, initialVal, suffix, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 24)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, 0, 0, 24)
    valLabel.Position = UDim2.new(1, -12, 0, 6)
    valLabel.AnchorPoint = Vector2.new(1, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(initialVal) .. (suffix or "")
    valLabel.TextColor3 = Theme.Accent
    valLabel.TextSize = 13
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Position = UDim2.new(0, 12, 0, 36)
    track.BackgroundColor3 = Theme.ToggleOff
    track.Text = ""
    track.BorderSizePixel = 0
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 4)
    trackCorner.Parent = track

    local fillPct = math.clamp((initialVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(fillPct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local isDragging = false
    local function UpdateFromX(x)
        local relX = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local rawVal = minVal + (relX * (maxVal - minVal))
        local val = math.floor(rawVal + 0.5)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        valLabel.Text = tostring(val) .. (suffix or "")
        callback(val)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    return {
        SetValue = function(newVal)
            local relX = math.clamp((newVal - minVal) / (maxVal - minVal), 0, 1)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            valLabel.Text = tostring(newVal) .. (suffix or "")
        end
    }
end

local function CreateDropdownWidget(parent, labelText, options, currentSelection, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local cycleBtn = Instance.new("TextButton")
    cycleBtn.Size = UDim2.new(0.5, 0, 0, 28)
    cycleBtn.Position = UDim2.new(1, -12, 0.5, -14)
    cycleBtn.AnchorPoint = Vector2.new(1, 0)
    cycleBtn.BackgroundColor3 = Theme.Panel
    cycleBtn.TextColor3 = Theme.Accent
    cycleBtn.Text = currentSelection .. " ▼"
    cycleBtn.TextSize = 12
    cycleBtn.Font = Enum.Font.GothamBold
    cycleBtn.BorderSizePixel = 0
    cycleBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = cycleBtn

    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == currentSelection then
            currentIndex = i
            break
        end
    end

    cycleBtn.MouseButton1Click:Connect(function()
        currentIndex = (currentIndex % #options) + 1
        local selected = options[currentIndex]
        cycleBtn.Text = selected .. " ▼"
        callback(selected)
    end)

    return {
        SetOptions = function(newOpts, newSelect)
            options = newOpts
            currentSelection = newSelect or options[1] or ""
            cycleBtn.Text = currentSelection .. " ▼"
            for i, opt in ipairs(options) do
                if opt == currentSelection then currentIndex = i break end
            end
        end,
        SetValue = function(newSelect)
            currentSelection = newSelect
            cycleBtn.Text = currentSelection .. " ▼"
            for i, opt in ipairs(options) do
                if opt == currentSelection then currentIndex = i break end
            end
        end
    }
end

local function CreateActionBtn(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color or Theme.Card
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================================================
-- 7. BUILD PAGES & TABS
-- ============================================================================
local farmPage = CreatePage("Farm")
local cardsPage = CreatePage("Cards")
local configPage = CreatePage("Config")
local utilsPage = CreatePage("Utils")
local statusPage = CreatePage("Status")

AddNavTab("Farm", "⚡ ฟาร์ม", 1)
AddNavTab("Cards", "🃏 การ์ด", 2)
AddNavTab("Config", "⚙️ ตั้งค่า", 3)
AddNavTab("Utils", "🛠️ ตัวช่วย", 4)
AddNavTab("Status", "📊 สถานะ", 5)

-- ----------------------------------------------------------------------------
-- Tab 1: Farm Page
-- ----------------------------------------------------------------------------
local farmToggleWidget = CreateToggleWidget(farmPage, "เปิดใช้งาน ออโต้ฟาร์ม (Auto Farm)", State.FarmEnabled, function(val)
    State.FarmEnabled = val
end)

local hoverSlider = CreateSliderWidget(farmPage, "ความสูงการบินลอยตัว (Hover Height)", 8, 30, State.HoverHeight, " สตัด", function(val)
    State.HoverHeight = val
end)

local flySpeedSlider = CreateSliderWidget(farmPage, "ความเร็วการบิน (Fly Speed)", 20, 120, State.FlySpeed, " สตัด/วิ", function(val)
    State.FlySpeed = val
end)

local retreatHpSlider = CreateSliderWidget(farmPage, "บินหนีฉุกเฉินเมื่อเลือดต่ำกว่า % (Retreat HP)", 20, 70, State.RetreatHealth, "%", function(val)
    State.RetreatHealth = val
end)

local resumeHpSlider = CreateSliderWidget(farmPage, "กลับลงมาฟาร์มเมื่อเลือดฟื้นถึง % (Resume HP)", 50, 95, State.RetreatResume, "%", function(val)
    State.RetreatResume = val
end)

local retreatAltSlider = CreateSliderWidget(farmPage, "ความสูงตอนบินหลบฉุกเฉิน (Retreat Altitude)", 40, 100, State.RetreatAltitude, " สตัด", function(val)
    State.RetreatAltitude = val
end)

local noclipToggleWidget = CreateToggleWidget(farmPage, "เดินทะลุมอนสเตอร์ (NoClip)", State.NoClip, function(val)
    State.NoClip = val
end)

local autoOrbsWidget = CreateToggleWidget(farmPage, "ดูดเก็บลูกแก้ว EXP & ไอเทมดรอป (Auto Orbs)", State.AutoOrbs, function(val)
    State.AutoOrbs = val
end)

-- ----------------------------------------------------------------------------
-- Tab 2: Smart Cards & Forge Page
-- ----------------------------------------------------------------------------
local autoDraftWidget = CreateToggleWidget(cardsPage, "เลือกการ์ดเลเวลอัปอัตโนมัติ (Auto Pick)", State.AutoDraft, function(val)
    State.AutoDraft = val
end)

local autoRerollWidget = CreateToggleWidget(cardsPage, "สุ่มการ์ดใหม่เมื่อไม่มีของตามสูตร (Auto Reroll)", State.AutoReroll, function(val)
    State.AutoReroll = val
end)

-- Multi-Target Evolution Wishlist & Status
local targetWishlistLabel = Instance.new("TextLabel")
targetWishlistLabel.Size = UDim2.new(1, 0, 0, 36)
targetWishlistLabel.BackgroundColor3 = Theme.Card
targetWishlistLabel.TextColor3 = Theme.Accent
targetWishlistLabel.Text = "อาวุธเป้าหมาย: " .. table.concat(State.TargetEvolutions, " -> ")
targetWishlistLabel.TextSize = 12
targetWishlistLabel.Font = Enum.Font.GothamMedium
targetWishlistLabel.TextWrapped = true
targetWishlistLabel.BorderSizePixel = 0
targetWishlistLabel.Parent = cardsPage

local targetWishlistCorner = Instance.new("UICorner")
targetWishlistCorner.CornerRadius = UDim.new(0, 8)
targetWishlistCorner.Parent = targetWishlistLabel

-- Multi-Target Evolution POPUP Modal (with Search Bar)
local EvoModal = Instance.new("Frame")
EvoModal.Name = "EvolutionModal"
EvoModal.Size = UDim2.new(0, 530, 0, 370)
EvoModal.Position = UDim2.new(0.5, -265, 0.5, -185)
EvoModal.BackgroundColor3 = Theme.Bg
EvoModal.BorderSizePixel = 0
EvoModal.Visible = false
EvoModal.ZIndex = 20
EvoModal.Parent = ScreenGui

local EvoModalCorner = Instance.new("UICorner")
EvoModalCorner.CornerRadius = UDim.new(0, 12)
EvoModalCorner.Parent = EvoModal

local EvoModalStroke = Instance.new("UIStroke")
EvoModalStroke.Color = Theme.Accent
EvoModalStroke.Thickness = 2
EvoModalStroke.Parent = EvoModal

-- Evo Header
local EvoHeader = Instance.new("Frame")
EvoHeader.Size = UDim2.new(1, 0, 0, 42)
EvoHeader.BackgroundColor3 = Theme.Panel
EvoHeader.BorderSizePixel = 0
EvoHeader.ZIndex = 21
EvoHeader.Parent = EvoModal

local EvoHeaderCorner = Instance.new("UICorner")
EvoHeaderCorner.CornerRadius = UDim.new(0, 12)
EvoHeaderCorner.Parent = EvoHeader

local EvoTitle = Instance.new("TextLabel")
EvoTitle.Size = UDim2.new(1, -50, 1, 0)
EvoTitle.Position = UDim2.new(0, 14, 0, 0)
EvoTitle.BackgroundTransparency = 1
EvoTitle.Text = "🎯 เลือกอาวุธเป้าหมายที่ต้องการผสม (เลือกได้หลายชิ้น)"
EvoTitle.TextColor3 = Theme.Accent
EvoTitle.TextSize = 13
EvoTitle.Font = Enum.Font.GothamBold
EvoTitle.TextXAlignment = Enum.TextXAlignment.Left
EvoTitle.ZIndex = 22
EvoTitle.Parent = EvoHeader

local EvoClose = Instance.new("TextButton")
EvoClose.Size = UDim2.new(0, 28, 0, 28)
EvoClose.Position = UDim2.new(1, -34, 0, 7)
EvoClose.BackgroundColor3 = Theme.Card
EvoClose.TextColor3 = Theme.Text
EvoClose.Text = "X"
EvoClose.TextSize = 13
EvoClose.Font = Enum.Font.GothamBold
EvoClose.BorderSizePixel = 0
EvoClose.ZIndex = 22
EvoClose.Parent = EvoHeader

local EvoCloseCorner = Instance.new("UICorner")
EvoCloseCorner.CornerRadius = UDim.new(0, 6)
EvoCloseCorner.Parent = EvoClose

-- Evo Subtitle
local EvoSub = Instance.new("TextLabel")
EvoSub.Size = UDim2.new(1, -24, 0, 20)
EvoSub.Position = UDim2.new(0, 12, 0, 44)
EvoSub.BackgroundTransparency = 1
EvoSub.Text = "แตะเพื่อเลือก/ยกเลิก บอทจะพยายามเก็บของผสมตามลำดับความสำคัญก่อนหลัง!"
EvoSub.TextColor3 = Theme.TextDim
EvoSub.TextSize = 11
EvoSub.Font = Enum.Font.Gotham
EvoSub.TextXAlignment = Enum.TextXAlignment.Left
EvoSub.ZIndex = 21
EvoSub.Parent = EvoModal

-- Evo Search Bar Container
local evoSearchBox = Instance.new("Frame")
evoSearchBox.Size = UDim2.new(1, -20, 0, 32)
evoSearchBox.Position = UDim2.new(0, 10, 0, 66)
evoSearchBox.BackgroundColor3 = Theme.Card
evoSearchBox.BorderSizePixel = 0
evoSearchBox.ZIndex = 21
evoSearchBox.Parent = EvoModal

local evoSearchCorner = Instance.new("UICorner")
evoSearchCorner.CornerRadius = UDim.new(0, 6)
evoSearchCorner.Parent = evoSearchBox

local evoSearchIcon = Instance.new("TextLabel")
evoSearchIcon.Size = UDim2.new(0, 26, 1, 0)
evoSearchIcon.Position = UDim2.new(0, 6, 0, 0)
evoSearchIcon.BackgroundTransparency = 1
evoSearchIcon.Text = "🔍"
evoSearchIcon.TextSize = 12
evoSearchIcon.ZIndex = 22
evoSearchIcon.Parent = evoSearchBox

local evoSearchInput = Instance.new("TextBox")
evoSearchInput.Size = UDim2.new(1, -60, 1, 0)
evoSearchInput.Position = UDim2.new(0, 30, 0, 0)
evoSearchInput.BackgroundTransparency = 1
evoSearchInput.PlaceholderText = "พิมพ์ค้นหาอาวุธ หรือ วัตถุดิบ (เช่น Bow, Tesla, Sword)..."
evoSearchInput.PlaceholderColor3 = Theme.TextDim
evoSearchInput.TextColor3 = Theme.Text
evoSearchInput.Text = ""
evoSearchInput.TextSize = 12
evoSearchInput.Font = Enum.Font.Gotham
evoSearchInput.TextXAlignment = Enum.TextXAlignment.Left
evoSearchInput.ClearTextOnFocus = false
evoSearchInput.ZIndex = 22
evoSearchInput.Parent = evoSearchBox

local evoClearBtn = Instance.new("TextButton")
evoClearBtn.Size = UDim2.new(0, 24, 0, 24)
evoClearBtn.Position = UDim2.new(1, -28, 0.5, -12)
evoClearBtn.BackgroundTransparency = 1
evoClearBtn.Text = "X"
evoClearBtn.TextColor3 = Theme.TextDim
evoClearBtn.TextSize = 12
evoClearBtn.Font = Enum.Font.GothamBold
evoClearBtn.ZIndex = 22
evoClearBtn.Parent = evoSearchBox

evoClearBtn.MouseButton1Click:Connect(function()
    evoSearchInput.Text = ""
end)

-- Scrollable List
local EvoScroll = Instance.new("ScrollingFrame")
EvoScroll.Size = UDim2.new(1, -20, 1, -112)
EvoScroll.Position = UDim2.new(0, 10, 0, 104)
EvoScroll.BackgroundTransparency = 1
EvoScroll.BorderSizePixel = 0
EvoScroll.ScrollBarThickness = 4
EvoScroll.ScrollBarImageColor3 = Theme.Accent
EvoScroll.ZIndex = 21
EvoScroll.Parent = EvoModal

local EvoList = Instance.new("UIListLayout")
EvoList.Padding = UDim.new(0, 4)
EvoList.SortOrder = Enum.SortOrder.LayoutOrder
EvoList.Parent = EvoScroll

local function RefreshWishlistLabel()
    if #State.TargetEvolutions == 0 then
        targetWishlistLabel.Text = "อาวุธเป้าหมาย: ยังไม่ได้เลือก (กดปุ่มด้านล่างเพื่อเลือก)"
        targetWishlistLabel.TextColor3 = Theme.TextDim
    else
        targetWishlistLabel.Text = "อาวุธเป้าหมาย (" .. #State.TargetEvolutions .. " ชิ้น): " .. table.concat(State.TargetEvolutions, " -> ")
        targetWishlistLabel.TextColor3 = Theme.Accent
    end
end

-- Populate EvoScroll items
local sortedEvoNames = {}
for name, _ in pairs(ForgeDatabase) do table.insert(sortedEvoNames, name) end
table.sort(sortedEvoNames)
EvoScroll.CanvasSize = UDim2.new(0, 0, 0, #sortedEvoNames * 42)

local evoRows = {}
for _, evoName in ipairs(sortedEvoNames) do
    local evoData = ForgeDatabase[evoName]
    local ingText = table.concat(evoData.ingredients or {}, " + ")

    local itemRow = Instance.new("Frame")
    itemRow.Size = UDim2.new(1, -6, 0, 38)
    itemRow.BackgroundColor3 = Theme.Card
    itemRow.BorderSizePixel = 0
    itemRow.ZIndex = 22
    itemRow.Parent = EvoScroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = itemRow

    local evoIcon = GetCardIcon("weapon", evoName)
    if evoIcon and evoIcon ~= "" then
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 26, 0, 26)
        iconImg.Position = UDim2.new(0, 8, 0.5, -13)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = evoIcon
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 23
        iconImg.Parent = itemRow

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 4)
        iconCorner.Parent = iconImg
    end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -150, 1, 0)
    titleLbl.Position = UDim2.new(0, (evoIcon and evoIcon ~= "") and 40 or 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "<b>" .. evoName .. "</b>  <font color='#999999'>(" .. ingText .. ")</font>"
    titleLbl.RichText = true
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 23
    titleLbl.Parent = itemRow

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(0, 95, 0, 26)
    selectBtn.Position = UDim2.new(1, -100, 0.5, -13)
    selectBtn.BorderSizePixel = 0
    selectBtn.TextSize = 11
    selectBtn.Font = Enum.Font.GothamBold
    selectBtn.ZIndex = 23
    selectBtn.Parent = itemRow

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = selectBtn

    local function UpdateBtnState()
        local isSelected = table.find(State.TargetEvolutions, evoName) ~= nil
        if isSelected then
            selectBtn.BackgroundColor3 = Theme.Accent
            selectBtn.TextColor3 = Color3.new(1, 1, 1)
            selectBtn.Text = "✓ เลือกแล้ว"
        else
            selectBtn.BackgroundColor3 = Theme.Panel
            selectBtn.TextColor3 = Theme.TextDim
            selectBtn.Text = "+ เลือก"
        end
    end
    UpdateBtnState()

    selectBtn.MouseButton1Click:Connect(function()
        local idx = table.find(State.TargetEvolutions, evoName)
        if idx then
            table.remove(State.TargetEvolutions, idx)
        else
            table.insert(State.TargetEvolutions, evoName)
        end
        UpdateBtnState()
        RefreshWishlistLabel()
    end)

    table.insert(evoRows, {
        frame = itemRow,
        key = (evoName .. " " .. ingText):lower()
    })
end

-- Evo Search filtering
local function FilterEvoRows(query)
    query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local vis = 0
    for _, row in ipairs(evoRows) do
        if query == "" or row.key:find(query, 1, true) then
            row.frame.Visible = true
            vis = vis + 1
        else
            row.frame.Visible = false
        end
    end
    EvoScroll.CanvasSize = UDim2.new(0, 0, 0, vis * 42)
end

evoSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    FilterEvoRows(evoSearchInput.Text)
end)

EvoClose.MouseButton1Click:Connect(function()
    EvoModal.Visible = false
end)

CreateActionBtn(cardsPage, "🎯 ตั้งค่าอาวุธเป้าหมาย (เปิดหน้าต่าง POPUP)", Theme.Accent, function()
    EvoModal.Visible = not EvoModal.Visible
end)

-- ----------------------------------------------------------------------------
-- Passive Skills Selection & POPUP Modal (with Search Bar)
-- ----------------------------------------------------------------------------
local targetPassivesLabel = Instance.new("TextLabel")
targetPassivesLabel.Size = UDim2.new(1, 0, 0, 36)
targetPassivesLabel.BackgroundColor3 = Theme.Card
targetPassivesLabel.TextColor3 = Color3.fromRGB(80, 220, 140)
targetPassivesLabel.Text = "พาสซีพเป้าหมาย: " .. table.concat(State.TargetPassives or {}, " -> ")
targetPassivesLabel.TextSize = 12
targetPassivesLabel.Font = Enum.Font.GothamMedium
targetPassivesLabel.TextWrapped = true
targetPassivesLabel.BorderSizePixel = 0
targetPassivesLabel.Parent = cardsPage

local targetPassivesCorner = Instance.new("UICorner")
targetPassivesCorner.CornerRadius = UDim.new(0, 8)
targetPassivesCorner.Parent = targetPassivesLabel

local function RefreshPassivesLabel()
    if not State.TargetPassives or #State.TargetPassives == 0 then
        targetPassivesLabel.Text = "พาสซีพเป้าหมาย: ยังไม่ได้เลือก (กดปุ่มด้านล่างเพื่อเลือก)"
        targetPassivesLabel.TextColor3 = Theme.TextDim
    else
        targetPassivesLabel.Text = "พาสซีพเป้าหมาย (" .. #State.TargetPassives .. " ชิ้น): " .. table.concat(State.TargetPassives, " -> ")
        targetPassivesLabel.TextColor3 = Color3.fromRGB(80, 220, 140)
    end
end

-- Passive POPUP Modal
local PassiveModal = Instance.new("Frame")
PassiveModal.Name = "PassiveModal"
PassiveModal.Size = UDim2.new(0, 530, 0, 370)
PassiveModal.Position = UDim2.new(0.5, -265, 0.5, -185)
PassiveModal.BackgroundColor3 = Theme.Bg
PassiveModal.BorderSizePixel = 0
PassiveModal.Visible = false
PassiveModal.ZIndex = 20
PassiveModal.Parent = ScreenGui

local PassiveModalCorner = Instance.new("UICorner")
PassiveModalCorner.CornerRadius = UDim.new(0, 12)
PassiveModalCorner.Parent = PassiveModal

local PassiveModalStroke = Instance.new("UIStroke")
PassiveModalStroke.Color = Color3.fromRGB(50, 200, 120)
PassiveModalStroke.Thickness = 2
PassiveModalStroke.Parent = PassiveModal

-- Passive Header
local PassiveHeader = Instance.new("Frame")
PassiveHeader.Size = UDim2.new(1, 0, 0, 42)
PassiveHeader.BackgroundColor3 = Theme.Panel
PassiveHeader.BorderSizePixel = 0
PassiveHeader.ZIndex = 21
PassiveHeader.Parent = PassiveModal

local PassiveHeaderCorner = Instance.new("UICorner")
PassiveHeaderCorner.CornerRadius = UDim.new(0, 12)
PassiveHeaderCorner.Parent = PassiveHeader

local PassiveTitle = Instance.new("TextLabel")
PassiveTitle.Size = UDim2.new(1, -50, 1, 0)
PassiveTitle.Position = UDim2.new(0, 14, 0, 0)
PassiveTitle.BackgroundTransparency = 1
PassiveTitle.Text = "🛡️ เลือกสกิล PASSIVE เป้าหมาย (เลือกได้หลายชิ้น)"
PassiveTitle.TextColor3 = Color3.fromRGB(80, 220, 140)
PassiveTitle.TextSize = 13
PassiveTitle.Font = Enum.Font.GothamBold
PassiveTitle.TextXAlignment = Enum.TextXAlignment.Left
PassiveTitle.ZIndex = 22
PassiveTitle.Parent = PassiveHeader

local PassiveClose = Instance.new("TextButton")
PassiveClose.Size = UDim2.new(0, 28, 0, 28)
PassiveClose.Position = UDim2.new(1, -34, 0, 7)
PassiveClose.BackgroundColor3 = Theme.Card
PassiveClose.TextColor3 = Theme.Text
PassiveClose.Text = "X"
PassiveClose.TextSize = 13
PassiveClose.Font = Enum.Font.GothamBold
PassiveClose.BorderSizePixel = 0
PassiveClose.ZIndex = 22
PassiveClose.Parent = PassiveHeader

local PassiveCloseCorner = Instance.new("UICorner")
PassiveCloseCorner.CornerRadius = UDim.new(0, 6)
PassiveCloseCorner.Parent = PassiveClose

-- Passive Subtitle
local PassiveSub = Instance.new("TextLabel")
PassiveSub.Size = UDim2.new(1, -24, 0, 20)
PassiveSub.Position = UDim2.new(0, 12, 0, 44)
PassiveSub.BackgroundTransparency = 1
PassiveSub.Text = "แตะเพื่อเลือก/ยกเลิก บอทจะพยายามเก็บพาสซีพตามลำดับความสำคัญก่อนหลัง!"
PassiveSub.TextColor3 = Theme.TextDim
PassiveSub.TextSize = 11
PassiveSub.Font = Enum.Font.Gotham
PassiveSub.TextXAlignment = Enum.TextXAlignment.Left
PassiveSub.ZIndex = 21
PassiveSub.Parent = PassiveModal

-- Passive Search Bar Container
local passiveSearchBox = Instance.new("Frame")
passiveSearchBox.Size = UDim2.new(1, -20, 0, 32)
passiveSearchBox.Position = UDim2.new(0, 10, 0, 66)
passiveSearchBox.BackgroundColor3 = Theme.Card
passiveSearchBox.BorderSizePixel = 0
passiveSearchBox.ZIndex = 21
passiveSearchBox.Parent = PassiveModal

local passiveSearchCorner = Instance.new("UICorner")
passiveSearchCorner.CornerRadius = UDim.new(0, 6)
passiveSearchCorner.Parent = passiveSearchBox

local passiveSearchIcon = Instance.new("TextLabel")
passiveSearchIcon.Size = UDim2.new(0, 26, 1, 0)
passiveSearchIcon.Position = UDim2.new(0, 6, 0, 0)
passiveSearchIcon.BackgroundTransparency = 1
passiveSearchIcon.Text = "🔍"
passiveSearchIcon.TextSize = 12
passiveSearchIcon.ZIndex = 22
passiveSearchIcon.Parent = passiveSearchBox

local passiveSearchInput = Instance.new("TextBox")
passiveSearchInput.Size = UDim2.new(1, -60, 1, 0)
passiveSearchInput.Position = UDim2.new(0, 30, 0, 0)
passiveSearchInput.BackgroundTransparency = 1
passiveSearchInput.PlaceholderText = "พิมพ์ค้นหาสกิล Passive (เช่น Magnet, Boots, Damage)..."
passiveSearchInput.PlaceholderColor3 = Theme.TextDim
passiveSearchInput.TextColor3 = Theme.Text
passiveSearchInput.Text = ""
passiveSearchInput.TextSize = 12
passiveSearchInput.Font = Enum.Font.Gotham
passiveSearchInput.TextXAlignment = Enum.TextXAlignment.Left
passiveSearchInput.ClearTextOnFocus = false
passiveSearchInput.ZIndex = 22
passiveSearchInput.Parent = passiveSearchBox

local passiveClearBtn = Instance.new("TextButton")
passiveClearBtn.Size = UDim2.new(0, 24, 0, 24)
passiveClearBtn.Position = UDim2.new(1, -28, 0.5, -12)
passiveClearBtn.BackgroundTransparency = 1
passiveClearBtn.Text = "X"
passiveClearBtn.TextColor3 = Theme.TextDim
passiveClearBtn.TextSize = 12
passiveClearBtn.Font = Enum.Font.GothamBold
passiveClearBtn.ZIndex = 22
passiveClearBtn.Parent = passiveSearchBox

passiveClearBtn.MouseButton1Click:Connect(function()
    passiveSearchInput.Text = ""
end)

-- Passive Scrollable List
local PassiveScroll = Instance.new("ScrollingFrame")
PassiveScroll.Size = UDim2.new(1, -20, 1, -112)
PassiveScroll.Position = UDim2.new(0, 10, 0, 104)
PassiveScroll.BackgroundTransparency = 1
PassiveScroll.BorderSizePixel = 0
PassiveScroll.ScrollBarThickness = 4
PassiveScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 200, 120)
PassiveScroll.ZIndex = 21
PassiveScroll.Parent = PassiveModal

local PassiveList = Instance.new("UIListLayout")
PassiveList.Padding = UDim.new(0, 4)
PassiveList.SortOrder = Enum.SortOrder.LayoutOrder
PassiveList.Parent = PassiveScroll

-- Populate PassiveScroll items
local sortedPassives = {}
for _, pData in pairs(PassivesDatabase) do table.insert(sortedPassives, pData) end
table.sort(sortedPassives, function(a, b) return a.name < b.name end)
PassiveScroll.CanvasSize = UDim2.new(0, 0, 0, #sortedPassives * 42)

local passiveRows = {}
for _, pData in ipairs(sortedPassives) do
    local pName = pData.name
    local pBlurb = pData.blurb or ""

    local itemRow = Instance.new("Frame")
    itemRow.Size = UDim2.new(1, -6, 0, 38)
    itemRow.BackgroundColor3 = Theme.Card
    itemRow.BorderSizePixel = 0
    itemRow.ZIndex = 22
    itemRow.Parent = PassiveScroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = itemRow

    local pIcon = GetCardIcon("passive", pData.id) or pData.icon
    if pIcon and pIcon ~= "" then
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 26, 0, 26)
        iconImg.Position = UDim2.new(0, 8, 0.5, -13)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = pIcon
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 23
        iconImg.Parent = itemRow

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 4)
        iconCorner.Parent = iconImg
    end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -150, 1, 0)
    titleLbl.Position = UDim2.new(0, (pIcon and pIcon ~= "") and 40 or 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "<b>" .. pName .. "</b>  <font color='#999999'>(" .. pBlurb .. ")</font>"
    titleLbl.RichText = true
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 23
    titleLbl.Parent = itemRow

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(0, 95, 0, 26)
    selectBtn.Position = UDim2.new(1, -100, 0.5, -13)
    selectBtn.BorderSizePixel = 0
    selectBtn.TextSize = 11
    selectBtn.Font = Enum.Font.GothamBold
    selectBtn.ZIndex = 23
    selectBtn.Parent = itemRow

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = selectBtn

    local function UpdateBtnState()
        local isSelected = table.find(State.TargetPassives or {}, pName) ~= nil
        if isSelected then
            selectBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
            selectBtn.TextColor3 = Color3.new(1, 1, 1)
            selectBtn.Text = "✓ เลือกแล้ว"
        else
            selectBtn.BackgroundColor3 = Theme.Panel
            selectBtn.TextColor3 = Theme.TextDim
            selectBtn.Text = "+ เลือก"
        end
    end
    UpdateBtnState()

    selectBtn.MouseButton1Click:Connect(function()
        if not State.TargetPassives then State.TargetPassives = {} end
        local idx = table.find(State.TargetPassives, pName)
        if idx then
            table.remove(State.TargetPassives, idx)
        else
            table.insert(State.TargetPassives, pName)
        end
        UpdateBtnState()
        RefreshPassivesLabel()
    end)

    table.insert(passiveRows, {
        frame = itemRow,
        key = (pName .. " " .. pBlurb .. " " .. pData.id):lower()
    })
end

-- Passive Search filtering
local function FilterPassiveRows(query)
    query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local vis = 0
    for _, row in ipairs(passiveRows) do
        if query == "" or row.key:find(query, 1, true) then
            row.frame.Visible = true
            vis = vis + 1
        else
            row.frame.Visible = false
        end
    end
    PassiveScroll.CanvasSize = UDim2.new(0, 0, 0, vis * 42)
end

passiveSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    FilterPassiveRows(passiveSearchInput.Text)
end)

PassiveClose.MouseButton1Click:Connect(function()
    PassiveModal.Visible = false
end)

CreateActionBtn(cardsPage, "🛡️ ตั้งค่าสกิล Passive เป้าหมาย (เปิดหน้าต่าง POPUP)", Color3.fromRGB(35, 145, 95), function()
    PassiveModal.Visible = not PassiveModal.Visible
end)

local slotResWidget = CreateToggleWidget(cardsPage, "จองช่องอาวุธ (บล็อกการเลือกไอเทมขยะที่ไม่ตรงสูตร)", State.SlotReservation, function(val)
    State.SlotReservation = val
end)

-- ----------------------------------------------------------------------------
-- Tab 3: Configuration & Autoload Page (Exact Match to User Screenshot)
-- ----------------------------------------------------------------------------
-- Tab 3: Configuration & Autoload Page (Redesigned: Clear, Compact & Modern)
-- ----------------------------------------------------------------------------
-- 1. Executive Status Dashboard Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 72)
statusCard.BackgroundColor3 = Theme.Card
statusCard.BorderSizePixel = 0
statusCard.Parent = configPage

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusCard

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Theme.Border
statusStroke.Thickness = 1
statusStroke.Parent = statusCard

local statusCardTitle = Instance.new("TextLabel")
statusCardTitle.Size = UDim2.new(1, -20, 0, 18)
statusCardTitle.Position = UDim2.new(0, 10, 0, 4)
statusCardTitle.BackgroundTransparency = 1
statusCardTitle.Text = "📌 สถานะโปรไฟล์ปัจจุบัน (Profile Status)"
statusCardTitle.TextColor3 = Theme.TextDim
statusCardTitle.TextSize = 11
statusCardTitle.Font = Enum.Font.GothamBold
statusCardTitle.TextXAlignment = Enum.TextXAlignment.Left
statusCardTitle.Parent = statusCard

local activeProfileLabel = Instance.new("TextLabel")
activeProfileLabel.Size = UDim2.new(1, -20, 0, 20)
activeProfileLabel.Position = UDim2.new(0, 10, 0, 24)
activeProfileLabel.BackgroundTransparency = 1
activeProfileLabel.Text = "⚡ ใช้งานอยู่ตอนนี้ (Active): <b><font color='#FF2A85'>" .. (State.ActiveConfigName or "SSS") .. "</font></b>"
activeProfileLabel.RichText = true
activeProfileLabel.TextColor3 = Theme.Text
activeProfileLabel.TextSize = 12
activeProfileLabel.Font = Enum.Font.Gotham
activeProfileLabel.TextXAlignment = Enum.TextXAlignment.Left
activeProfileLabel.Parent = statusCard

local autoloadProfileLabel = Instance.new("TextLabel")
autoloadProfileLabel.Size = UDim2.new(1, -20, 0, 20)
autoloadProfileLabel.Position = UDim2.new(0, 10, 0, 46)
autoloadProfileLabel.BackgroundTransparency = 1
autoloadProfileLabel.RichText = true
autoloadProfileLabel.TextColor3 = Theme.Text
autoloadProfileLabel.TextSize = 12
autoloadProfileLabel.Font = Enum.Font.Gotham
autoloadProfileLabel.TextXAlignment = Enum.TextXAlignment.Left
autoloadProfileLabel.Parent = statusCard

local function UpdateAutoloadStatusLabel()
    local curAuto = GetAutoload()
    if curAuto and curAuto ~= "" then
        autoloadProfileLabel.Text = "🟢 โหลดอัตโนมัติ (Autoload): <b><font color='#40FF70'>" .. curAuto .. "</font></b>  <font color='#888888'>(เปิดใช้งาน)</font>"
    else
        autoloadProfileLabel.Text = "⚪ โหลดอัตโนมัติ (Autoload): <font color='#AAAAAA'>ยังไม่ได้ตั้งค่า (ปิดอยู่)</font>"
    end
end
UpdateAutoloadStatusLabel()

-- 2. Input Container for Config Name
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, 0, 0, 36)
inputContainer.BackgroundColor3 = Theme.Card
inputContainer.BorderSizePixel = 0
inputContainer.Parent = configPage

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputContainer

local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(0, 95, 1, 0)
inputLabel.Position = UDim2.new(0, 10, 0, 0)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "ชื่อโปรไฟล์:"
inputLabel.TextColor3 = Theme.TextDim
inputLabel.TextSize = 12
inputLabel.Font = Enum.Font.GothamMedium
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = inputContainer

local configNameInput = Instance.new("TextBox")
configNameInput.Size = UDim2.new(1, -110, 1, 0)
configNameInput.Position = UDim2.new(0, 105, 0, 0)
configNameInput.BackgroundTransparency = 1
configNameInput.TextColor3 = Theme.Text
configNameInput.PlaceholderText = "พิมพ์ชื่อโปรไฟล์ (เช่น SSS, Afk)..."
configNameInput.PlaceholderColor3 = Theme.TextDim
configNameInput.Text = State.ActiveConfigName or "SSS"
configNameInput.TextSize = 13
configNameInput.Font = Enum.Font.GothamBold
configNameInput.TextXAlignment = Enum.TextXAlignment.Left
configNameInput.ClearTextOnFocus = false
configNameInput.Parent = inputContainer

-- 3. Dropdown to choose config
local configDropdown = CreateDropdownWidget(configPage, "เลือกโปรไฟล์ที่บันทึกไว้", GetConfigList(), State.ActiveConfigName or "SSS", function(val)
    configNameInput.Text = val
end)

-- 4. 2x2 Action Button Grid (Compact & Easy on Mobile)
local actionGrid = Instance.new("Frame")
actionGrid.Size = UDim2.new(1, 0, 0, 76)
actionGrid.BackgroundTransparency = 1
actionGrid.Parent = configPage

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -4, 0, 34)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = actionGrid

-- Notice Label for feedback
local noticeLabel = Instance.new("TextLabel")
noticeLabel.Size = UDim2.new(1, 0, 0, 20)
noticeLabel.BackgroundTransparency = 1
noticeLabel.Text = "เลือกโปรไฟล์แล้วกดบันทึกหรือโหลดได้ทันที"
noticeLabel.TextColor3 = Theme.TextDim
noticeLabel.TextSize = 11
noticeLabel.Font = Enum.Font.GothamMedium
noticeLabel.TextXAlignment = Enum.TextXAlignment.Center

local function ShowNotice(msg, color)
    noticeLabel.Text = msg
    noticeLabel.TextColor3 = color or Theme.Accent
end

local function CreateGridBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = color or Theme.Card
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = actionGrid

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Save Button
CreateGridBtn("💾 บันทึกโปรไฟล์", Theme.Accent, function()
    local name = configNameInput.Text:gsub("%s+", "")
    if name == "" then name = "Config1" end
    local ok, _ = SaveConfigFile(name)
    if ok then
        State.ActiveConfigName = name
        activeProfileLabel.Text = "⚡ ใช้งานอยู่ตอนนี้ (Active): <b><font color='#FF2A85'>" .. name .. "</font></b>"
        configDropdown.SetOptions(GetConfigList(), name)
        ShowNotice("✅ บันทึกโปรไฟล์ '" .. name .. "' เรียบร้อยแล้ว!", Color3.fromRGB(80, 255, 120))
    end
end)

-- Load Button
CreateGridBtn("📂 โหลดโปรไฟล์", Color3.fromRGB(35, 95, 160), function()
    local name = configNameInput.Text:gsub("%s+", "")
    local ok, _ = LoadConfigFile(name)
    if ok then
        State.ActiveConfigName = name
        activeProfileLabel.Text = "⚡ ใช้งานอยู่ตอนนี้ (Active): <b><font color='#FF2A85'>" .. name .. "</font></b>"
        farmToggleWidget.SetValue(State.FarmEnabled)
        hoverSlider.SetValue(State.HoverHeight)
        flySpeedSlider.SetValue(State.FlySpeed)
        retreatHpSlider.SetValue(State.RetreatHealth)
        resumeHpSlider.SetValue(State.RetreatResume)
        retreatAltSlider.SetValue(State.RetreatAltitude)
        noclipToggleWidget.SetValue(State.NoClip)
        autoOrbsWidget.SetValue(State.AutoOrbs)
        autoDraftWidget.SetValue(State.AutoDraft)
        autoRerollWidget.SetValue(State.AutoReroll)
        RefreshWishlistLabel()
        RefreshPassivesLabel()
        ShowNotice("📂 โหลดโปรไฟล์ '" .. name .. "' สำเร็จ!", Color3.fromRGB(80, 220, 255))
    else
        ShowNotice("❌ ไม่พบไฟล์โปรไฟล์ '" .. name .. "'", Color3.fromRGB(255, 100, 100))
    end
end)

-- Set Autoload Button
CreateGridBtn("⭐ ตั้งเป็น Autoload", Color3.fromRGB(35, 145, 75), function()
    local name = configNameInput.Text:gsub("%s+", "")
    if name == "" then name = State.ActiveConfigName or "SSS" end
    SetAutoload(name)
    UpdateAutoloadStatusLabel()
    ShowNotice("⭐ ตั้ง '" .. name .. "' เป็น Autoload สำเร็จ!", Color3.fromRGB(80, 255, 120))
end)

-- Clear Autoload Button
CreateGridBtn("🔄 ยกเลิก Autoload", Color3.fromRGB(160, 50, 60), function()
    ResetAutoload()
    UpdateAutoloadStatusLabel()
    ShowNotice("🔄 ยกเลิก Autoload เรียบร้อย (ไม่มีการโหลดอัตโนมัติ)", Color3.fromRGB(255, 160, 80))
end)

noticeLabel.Parent = configPage

CreateActionBtn(configPage, "📋 คัดลอกการตั้งค่าลงคลิปบอร์ด (Export JSON)", Theme.Card, function()
    local payload = HttpService:JSONEncode(State)
    if setclipboard then
        setclipboard(payload)
        ShowNotice("📋 คัดลอกการตั้งค่าลงคลิปบอร์ดแล้ว!", Theme.Accent)
    elseif toclipboard then
        toclipboard(payload)
        ShowNotice("📋 คัดลอกการตั้งค่าลงคลิปบอร์ดแล้ว!", Theme.Accent)
    end
end)

-- ----------------------------------------------------------------------------
-- Tab 4: Utilities Page (Refined & Scroll-Perfect)
-- ----------------------------------------------------------------------------
CreateToggleWidget(utilsPage, "ป้องกันหลุดจากเกม (Anti-AFK)", State.AntiAfk, function(val)
    State.AntiAfk = val
end)

CreateToggleWidget(utilsPage, "ลดกราฟิกช่วยให้ลื่น/ไม่แลค (FPS Boost)", State.FpsBoost, function(val)
    State.FpsBoost = val
    ApplyFpsBoost(val)
end)

CreateToggleWidget(utilsPage, "ข้ามคัตซีนอัตโนมัติ (Skip Cutscenes - ยานตก & บอส)", State.SkipCutscenes, function(val)
    State.SkipCutscenes = val
end)

CreateToggleWidget(utilsPage, "เข้าเกมใหม่อัตโนมัติเมื่อหลุด (Auto Reconnect)", State.AutoReconnect, function(val)
    State.AutoReconnect = val
end)

CreateToggleWidget(utilsPage, "ซ่อนเมนูเมื่อเริ่มรันสคริปต์ (เปิดผ่านปุ่มลอย ⚡)", State.HideUIOnStart, function(val)
    State.HideUIOnStart = val
end)

CreateToggleWidget(utilsPage, "กด Launch / เริ่มเกมอัตโนมัติ (Auto Launch)", State.AutoStartGame, function(val)
    State.AutoStartGame = val
end)

CreateToggleWidget(utilsPage, "รับรางวัลและจัดการจบรอบอัตโนมัติ (Auto Match End)", State.AutoReplay, function(val)
    State.AutoReplay = val
end)

CreateDropdownWidget(utilsPage, "เมื่อจบรอบ/ตาย ให้ทำอะไร", { "🔄 เล่นอีกรอบทันที (Retry)", "🏠 กลับไปล็อบบี้ (Return to Lobby)" }, State.EndGameAction == "Lobby" and "🏠 กลับไปล็อบบี้ (Return to Lobby)" or "🔄 เล่นอีกรอบทันที (Retry)", function(choice)
    if choice:find("ล็อบบี้") or choice:find("Lobby") then
        State.EndGameAction = "Lobby"
    else
        State.EndGameAction = "Retry"
    end
end)

CreateToggleWidget(utilsPage, "หลังบอสตาย: อยู่ฟาร์มเวฟโบนัสต่อ (Bonus Waves)", State.StayForBonusWaves, function(val)
    State.StayForBonusWaves = val
end)

CreateSliderWidget(utilsPage, "จำนวนเวฟโบนัสที่ต้องการเคลียร์", 1, 15, State.BonusWavesToClear, " เวฟ", function(val)
    State.BonusWavesToClear = val
end)

CreateToggleWidget(utilsPage, "ตอนเวฟโบนัส: บินปักหลักเฝ้าเสาทางออก (Camp Exit)", State.CampExitOnBonus, function(val)
    State.CampExitOnBonus = val
end)

CreateSliderWidget(utilsPage, "วาร์ปออกเสาทันทีเมื่อเลือดต่ำกว่า % (Emergency Extract)", 5, 30, State.EmergencyExtractHP, "%", function(val)
    State.EmergencyExtractHP = val
end)


-- ----------------------------------------------------------------------------
-- Tab 5: Real-Time Status & Diagnostics Page
-- ----------------------------------------------------------------------------
local function CreateStatusCard(parent, title, defaultVal)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 38)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(0.5, 0, 1, 0)
    tLabel.Position = UDim2.new(0, 12, 0, 0)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = title
    tLabel.TextColor3 = Theme.TextDim
    tLabel.TextSize = 13
    tLabel.Font = Enum.Font.GothamMedium
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = card

    local vLabel = Instance.new("TextLabel")
    vLabel.Size = UDim2.new(0.45, 0, 1, 0)
    vLabel.Position = UDim2.new(1, -12, 0, 0)
    vLabel.AnchorPoint = Vector2.new(1, 0)
    vLabel.BackgroundTransparency = 1
    vLabel.Text = defaultVal
    vLabel.TextColor3 = Theme.Accent
    vLabel.TextSize = 13
    vLabel.Font = Enum.Font.GothamBold
    vLabel.TextXAlignment = Enum.TextXAlignment.Right
    vLabel.Parent = card

    return vLabel
end

local hpStatusLabel = CreateStatusCard(statusPage, "พลังชีวิต (HP)", "100 / 100")
local modeStatusLabel = CreateStatusCard(statusPage, "สถานะการทำงาน", "หยุดทำงาน")
local groundStatusLabel = CreateStatusCard(statusPage, "ความสูงจากพื้นดิน", "0 สตัด")
local targetEvoStatusLabel = CreateStatusCard(statusPage, "สูตรผสมที่กำลังติดตาม", "ไม่มี")

-- Update Status Page in real-time
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            hpStatusLabel.Text = tostring(State.CurrentHP) .. " / " .. tostring(State.MaxHP)
            if State.FarmEnabled then
                modeStatusLabel.Text = State.IsRetreating and "🚨 บินหลบฉุกเฉิน (อยู่บนฟ้า)" or "⚡ กำลังฟาร์มลอยตัว"
                modeStatusLabel.TextColor3 = State.IsRetreating and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 120)
            else
                modeStatusLabel.Text = "หยุดทำงาน (ปิดอยู่)"
                modeStatusLabel.TextColor3 = Theme.TextDim
            end
            groundStatusLabel.Text = string.format("%.1f สตัด (Studs)", State.CurrentGroundY)
            if #State.TargetEvolutions > 0 then
                targetEvoStatusLabel.Text = table.concat(State.TargetEvolutions, ", ")
            else
                targetEvoStatusLabel.Text = "ไม่มีเป้าหมาย"
            end
        end)
    end
end)

-- Switch to initial default tab
SwitchTab("Farm")

-- Restore Settings from Autoload or Teleport Cache
pcall(function()
    local autoName = GetAutoload()
    if autoName and autoName ~= "" then
        local ok = LoadConfigFile(autoName)
        if ok then
            print("[STS Mobile Hub] Autoloaded profile: " .. autoName)
        end
    elseif hasFileSystem and isfile and isfile(CONFIG_DIR .. "/_teleport_cache.json") then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_DIR .. "/_teleport_cache.json"))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                State[k] = v
            end
            pcall(RefreshWishlistLabel)
            pcall(RefreshPassivesLabel)
            print("[STS Mobile Hub] Seamlessly restored state across teleport from cache!")
        end
    end
end)

print("[STS Mobile Hub] Successfully loaded and initialized!")

]=====])
    print("[STS Installer] Successfully saved SurviveTheSwarm/main.luau to executor filesystem!")
end)

-- Execute
loadstring(readfile("SurviveTheSwarm/main.luau"))()
