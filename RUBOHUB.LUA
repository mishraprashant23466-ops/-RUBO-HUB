-- RUBO HUB | Brookhaven RP | Rayfield UI
-- Feature: Client-side Shaders & Weather (sirf tumhe dikhega, server pe kuch change nahi hota)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- ===== Original lighting save (Reset ke liye) =====
local Original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    ExposureCompensation = Lighting.ExposureCompensation,
}

-- ===== Effects (apne naam se banaye, game ke effects ko touch nahi karte) =====
local function getOrMake(class, name)
    local e = Lighting:FindFirstChild(name)
    if not e then
        e = Instance.new(class)
        e.Name = name
        e.Parent = Lighting
    end
    return e
end

local Bloom = getOrMake("BloomEffect", "RuboBloom")
local Color = getOrMake("ColorCorrectionEffect", "RuboColor")
local Rays = getOrMake("SunRaysEffect", "RuboRays")
local DOF = getOrMake("DepthOfFieldEffect", "RuboDOF")
local Atmos = getOrMake("Atmosphere", "RuboAtmosphere")

Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = false, false, false, false
Bloom.Intensity, Bloom.Size, Bloom.Threshold = 0.6, 30, 1.6
Rays.Intensity, Rays.Spread = 0.15, 0.8
DOF.FarIntensity, DOF.FocusDistance, DOF.InFocusRadius, DOF.NearIntensity = 0.25, 60, 40, 0

-- ===== Shader Presets =====
local Presets = {
    ["Cinematic"] = function()
        Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = true, true, true, true
        Bloom.Intensity, Bloom.Size, Bloom.Threshold = 0.5, 28, 1.7
        Color.Saturation, Color.Contrast, Color.Brightness = 0.15, 0.2, -0.02
        Color.TintColor = Color3.fromRGB(255, 244, 230)
        Atmos.Density, Atmos.Haze, Atmos.Color = 0.28, 1.2, Color3.fromRGB(199, 214, 235)
    end,
    ["Sunset"] = function()
        Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = true, true, true, false
        Bloom.Intensity = 0.7
        Color.Saturation, Color.Contrast, Color.Brightness = 0.25, 0.15, 0
        Color.TintColor = Color3.fromRGB(255, 205, 160)
        Lighting.ClockTime = 17.8
        Atmos.Density, Atmos.Haze, Atmos.Color = 0.32, 1.8, Color3.fromRGB(255, 190, 140)
    end,
    ["Night Neon"] = function()
        Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = true, true, false, false
        Bloom.Intensity, Bloom.Size, Bloom.Threshold = 1.1, 40, 1.2
        Color.Saturation, Color.Contrast, Color.Brightness = 0.35, 0.25, -0.05
        Color.TintColor = Color3.fromRGB(190, 215, 255)
        Lighting.ClockTime = 0
        Atmos.Density, Atmos.Haze, Atmos.Color = 0.35, 0.8, Color3.fromRGB(40, 70, 140)
    end,
    ["RUBO Blue"] = function()
        Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = true, true, true, false
        Bloom.Intensity, Bloom.Size, Bloom.Threshold = 0.9, 36, 1.3
        Color.Saturation, Color.Contrast, Color.Brightness = 0.3, 0.2, 0
        Color.TintColor = Color3.fromRGB(170, 215, 255)
        Atmos.Density, Atmos.Haze, Atmos.Color = 0.3, 1.0, Color3.fromRGB(120, 190, 255)
    end,
    ["Off"] = function()
        Bloom.Enabled, Color.Enabled, Rays.Enabled, DOF.Enabled = false, false, false, false
        Atmos.Density, Atmos.Haze = 0, 0
    end,
}

-- ===== Weather System =====
local weatherPart = Instance.new("Part")
weatherPart.Name = "RuboWeather"
weatherPart.Anchored = true
weatherPart.CanCollide = false
weatherPart.CanQuery = false
weatherPart.CanTouch = false
weatherPart.Transparency = 1
weatherPart.Size = Vector3.new(90, 1, 90)
weatherPart.Parent = Workspace

local rain = Instance.new("ParticleEmitter")
rain.Name = "Rain"
rain.Enabled = false
rain.Rate = 900
rain.Lifetime = NumberRange.new(0.8, 1)
rain.Speed = NumberRange.new(110, 130)
rain.Size = NumberSequence.new(0.18)
rain.Transparency = NumberSequence.new(0.45)
rain.Color = ColorSequence.new(Color3.fromRGB(190, 215, 255))
rain.LightEmission = 0.2
rain.EmissionDirection = Enum.NormalId.Bottom
rain.SpreadAngle = Vector2.new(4, 4)
rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.Parent = weatherPart

local snow = Instance.new("ParticleEmitter")
snow.Name = "Snow"
snow.Enabled = false
snow.Rate = 220
snow.Lifetime = NumberRange.new(6, 8)
snow.Speed = NumberRange.new(6, 10)
snow.Size = NumberSequence.new(0.35)
snow.Transparency = NumberSequence.new(0.1)
snow.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
snow.LightEmission = 0.6
snow.RotSpeed = NumberRange.new(-60, 60)
snow.EmissionDirection = Enum.NormalId.Bottom
snow.SpreadAngle = Vector2.new(25, 25)
snow.Parent = weatherPart

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if cam then
        weatherPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 45, 0))
    end
end)

local currentWeather = "Clear"
local stormLoop = false

local function setFog(startDist, endDist, color)
    Lighting.FogStart = startDist
    Lighting.FogEnd = endDist
    Lighting.FogColor = color
end

local function lightningLoop()
    task.spawn(function()
        while stormLoop do
            task.wait(math.random(6, 14))
            if not stormLoop then break end
            local base = Lighting.Brightness
            Lighting.Brightness = 6
            Color.Brightness = 0.4
            task.wait(0.07)
            Lighting.Brightness = base
            Color.Brightness = 0
            task.wait(0.12)
            Lighting.Brightness = 5
            task.wait(0.05)
            Lighting.Brightness = base
        end
    end)
end

local Weather = {
    ["Clear"] = function()
        rain.Enabled, snow.Enabled = false, false
        Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = Original.FogStart, Original.FogEnd, Original.FogColor
        Lighting.Brightness = Original.Brightness
    end,
    ["Rain"] = function()
        rain.Enabled, snow.Enabled = true, false
        rain.Rate = 900
        setFog(20, 450, Color3.fromRGB(110, 120, 140))
        Lighting.Brightness = 1.2
    end,
    ["Thunderstorm"] = function()
        rain.Enabled, snow.Enabled = true, false
        rain.Rate = 1800
        setFog(10, 300, Color3.fromRGB(60, 65, 80))
        Lighting.Brightness = 0.8
        stormLoop = true
        lightningLoop()
    end,
    ["Snow"] = function()
        rain.Enabled, snow.Enabled = false, true
        setFog(30, 500, Color3.fromRGB(220, 230, 245))
        Lighting.Brightness = 2
    end,
    ["Foggy"] = function()
        rain.Enabled, snow.Enabled = false, false
        setFog(0, 160, Color3.fromRGB(190, 195, 205))
        Lighting.Brightness = 1.5
    end,
}

local function applyWeather(name)
    stormLoop = false
    currentWeather = name
    if Weather[name] then Weather[name]() end
end

-- ===== UI =====
local Window = Rayfield:CreateWindow({
    Name = "RUBO HUB | Brookhaven RP",
    LoadingTitle = "RUBO HUB",
    LoadingSubtitle = "Shaders & Weather",
    ConfigurationSaving = { Enabled = true, FolderName = "RuboHub", FileName = "Brookhaven" },
    KeySystem = false,
})

local ShaderTab = Window:CreateTab("Shaders", "sparkles")
local WeatherTab = Window:CreateTab("Weather", "cloud-rain")

-- Shaders tab
ShaderTab:CreateSection("Presets")
ShaderTab:CreateDropdown({
    Name = "Shader Preset",
    Options = { "Cinematic", "Sunset", "Night Neon", "RUBO Blue", "Off" },
    CurrentOption = { "Off" },
    MultipleOptions = false,
    Flag = "ShaderPreset",
    Callback = function(opt)
        local name = type(opt) == "table" and opt[1] or opt
        if Presets[name] then Presets[name]() end
    end,
})

ShaderTab:CreateSection("Manual Controls")
ShaderTab:CreateToggle({ Name = "Bloom", CurrentValue = false, Flag = "Bloom",
    Callback = function(v) Bloom.Enabled = v end })
ShaderTab:CreateSlider({ Name = "Bloom Intensity", Range = { 0, 3 }, Increment = 0.1, CurrentValue = 0.6, Flag = "BloomInt",
    Callback = function(v) Bloom.Intensity = v end })
ShaderTab:CreateToggle({ Name = "Color Correction", CurrentValue = false, Flag = "CC",
    Callback = function(v) Color.Enabled = v end })
ShaderTab:CreateSlider({ Name = "Saturation", Range = { -1, 1 }, Increment = 0.05, CurrentValue = 0, Flag = "Sat",
    Callback = function(v) Color.Saturation = v end })
ShaderTab:CreateSlider({ Name = "Contrast", Range = { -1, 1 }, Increment = 0.05, CurrentValue = 0, Flag = "Con",
    Callback = function(v) Color.Contrast = v end })
ShaderTab:CreateColorPicker({ Name = "Tint Color", Color = Color3.fromRGB(255, 255, 255), Flag = "Tint",
    Callback = function(c) Color.TintColor = c end })
ShaderTab:CreateToggle({ Name = "Sun Rays", CurrentValue = false, Flag = "Rays",
    Callback = function(v) Rays.Enabled = v end })
ShaderTab:CreateToggle({ Name = "Depth of Field", CurrentValue = false, Flag = "DOF",
    Callback = function(v) DOF.Enabled = v end })
ShaderTab:CreateSlider({ Name = "Atmosphere Density", Range = { 0, 0.6 }, Increment = 0.01, CurrentValue = 0, Flag = "AtmDen",
    Callback = function(v) Atmos.Density = v end })
ShaderTab:CreateSlider({ Name = "Time of Day", Range = { 0, 24 }, Increment = 0.1, CurrentValue = Original.ClockTime, Flag = "Clock",
    Callback = function(v) Lighting.ClockTime = v end })

ShaderTab:CreateButton({ Name = "Reset Lighting", Callback = function()
    Presets["Off"]()
    for prop, val in pairs(Original) do
        Lighting[prop] = val
    end
end })

-- Weather tab
WeatherTab:CreateSection("Weather")
WeatherTab:CreateDropdown({
    Name = "Select Weather",
    Options = { "Clear", "Rain", "Thunderstorm", "Snow", "Foggy" },
    CurrentOption = { "Clear" },
    MultipleOptions = false,
    Flag = "WeatherSel",
    Callback = function(opt)
        applyWeather(type(opt) == "table" and opt[1] or opt)
    end,
})
WeatherTab:CreateSlider({ Name = "Rain / Snow Amount", Range = { 100, 3000 }, Increment = 50, CurrentValue = 900, Flag = "Amount",
    Callback = function(v)
        rain.Rate = v
        snow.Rate = math.floor(v / 4)
    end })
WeatherTab:CreateButton({ Name = "Clear Weather", Callback = function() applyWeather("Clear") end })

-- ===== AVATAR COPYING SYSTEM (client-side) =====
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local AvatarTab = Window:CreateTab("Avatar", "user")

local savedDesc          -- tera original avatar (restore ke liye)
local lastCopiedUserId   -- respawn ke baad dobara apply karne ke liye
local keepOnRespawn = false
local selectedName

local function notify(title, text)
    Rayfield:Notify({ Title = title, Content = text, Duration = 3.5 })
end

local function getHum(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function saveOriginal()
    if savedDesc then return end
    local hum = getHum(LP.Character)
    if hum then
        local ok, d = pcall(function() return hum:GetAppliedDescription() end)
        if ok then savedDesc = d end
    end
end

-- Mode 1: Catalog copy (HumanoidDescription) - kisi bhi UserId pe kaam karta hai
local function copyCatalog(userId)
    local hum = getHum(LP.Character)
    if not hum then return false, "Tera character abhi load nahi hua" end
    saveOriginal()
    local okD, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    if not okD or not desc then return false, "Avatar data nahi mila" end
    local okA, err = pcall(function() hum:ApplyDescription(desc) end)
    if not okA then return false, tostring(err) end
    lastCopiedUserId = userId
    return true
end

-- Mode 2: Live clone - jo player abhi pehne hua hai wahi copy (custom outfits ke liye best)
local function liveClone(plr)
    local myChar, tChar = LP.Character, plr.Character
    local myHum, tHum = getHum(myChar), getHum(tChar)
    if not (myHum and tHum) then return false, "Character load nahi hua" end
    saveOriginal()

    local function isGear(v)
        return v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants")
            or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors")
    end

    for _, v in ipairs(myChar:GetChildren()) do
        if isGear(v) then v:Destroy() end
    end
    for _, v in ipairs(tChar:GetChildren()) do
        if isGear(v) then
            local c = v:Clone()
            if c:IsA("Accessory") then
                myHum:AddAccessory(c)
            else
                c.Parent = myChar
            end
        end
    end

    -- face
    local myHead, tHead = myChar:FindFirstChild("Head"), tChar:FindFirstChild("Head")
    if myHead and tHead then
        local myFace = myHead:FindFirstChildOfClass("Decal")
        local tFace = tHead:FindFirstChildOfClass("Decal")
        if myFace and tFace then myFace.Texture = tFace.Texture end
    end
    lastCopiedUserId = plr.UserId
    return true
end

local function restoreMine()
    local hum = getHum(LP.Character)
    if not (hum and savedDesc) then return false, "Original avatar save nahi hai (pehle kuch copy karo)" end
    local ok, err = pcall(function() hum:ApplyDescription(savedDesc) end)
    if not ok then return false, tostring(err) end
    lastCopiedUserId = nil
    return true
end

local function otherPlayerNames()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.Name) end
    end
    table.sort(list)
    if #list == 0 then list = { "(no players)" } end
    return list
end

AvatarTab:CreateSection("Player Select")
local PlayerDropdown = AvatarTab:CreateDropdown({
    Name = "Select Player",
    Options = otherPlayerNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "AvatarTarget",
    Callback = function(opt)
        selectedName = type(opt) == "table" and opt[1] or opt
    end,
})

AvatarTab:CreateButton({ Name = "Refresh Player List", Callback = function()
    PlayerDropdown:Refresh(otherPlayerNames())
end })

local function selectedPlayer()
    local p = selectedName and Players:FindFirstChild(selectedName)
    if not p or p == LP then
        notify("Avatar", "Pehle dropdown se player select karo")
        return nil
    end
    return p
end

AvatarTab:CreateSection("Copy")
AvatarTab:CreateButton({ Name = "Copy Avatar (Catalog)", Callback = function()
    local p = selectedPlayer(); if not p then return end
    local ok, err = copyCatalog(p.UserId)
    notify("Avatar", ok and ("Copied: " .. p.Name) or ("Failed: " .. tostring(err)))
end })

AvatarTab:CreateButton({ Name = "Copy Avatar (Live Clone - jo pehna hai wahi)", Callback = function()
    local p = selectedPlayer(); if not p then return end
    local ok, err = liveClone(p)
    notify("Avatar", ok and ("Cloned: " .. p.Name) or ("Failed: " .. tostring(err)))
end })

AvatarTab:CreateButton({ Name = "Copy Random Player", Callback = function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p) end
    end
    if #list == 0 then return notify("Avatar", "Server me koi aur nahi hai") end
    local p = list[math.random(1, #list)]
    local ok, err = copyCatalog(p.UserId)
    notify("Avatar", ok and ("Copied: " .. p.Name) or ("Failed: " .. tostring(err)))
end })

AvatarTab:CreateSection("Copy by Username (offline bhi chalega)")
AvatarTab:CreateInput({
    Name = "Roblox Username",
    PlaceholderText = "username likho aur Enter dabao",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if not text or text == "" then return end
        local okId, userId = pcall(function() return Players:GetUserIdFromNameAsync(text) end)
        if not okId or not userId then return notify("Avatar", "Username nahi mila: " .. text) end
        local ok, err = copyCatalog(userId)
        notify("Avatar", ok and ("Copied: " .. text) or ("Failed: " .. tostring(err)))
    end,
})

AvatarTab:CreateSection("Options")
AvatarTab:CreateToggle({ Name = "Respawn ke baad bhi avatar rakho", CurrentValue = false, Flag = "KeepAvatar",
    Callback = function(v) keepOnRespawn = v end })

AvatarTab:CreateButton({ Name = "Restore My Avatar", Callback = function()
    local ok, err = restoreMine()
    notify("Avatar", ok and "Tera original avatar wapas" or tostring(err))
end })

LP.CharacterAdded:Connect(function(char)
    if keepOnRespawn and lastCopiedUserId then
        char:WaitForChild("Humanoid", 10)
        task.wait(1)
        copyCatalog(lastCopiedUserId)
    end
end)

Players.PlayerAdded:Connect(function() PlayerDropdown:Refresh(otherPlayerNames()) end)
Players.PlayerRemoving:Connect(function() task.defer(function() PlayerDropdown:Refresh(otherPlayerNames()) end) end)

-- ===== HEADLESS & KORBLOX MODIFIER (client-side) =====
local BodyTab = Window:CreateTab("Body Mods", "skull")

local HEADLESS_ID = 134082579    -- Headless Head
local KORBLOX_ID = 139607718     -- Korblox Deathspeaker (right leg)

local state = {
    headlessFast = false,   -- transparency method (instant)
    hideHeadAcc = false,
    invisibleLeg = false,
    catalogHeadless = false,
    catalogKorblox = false,
}

local headAttachments = {
    HairAttachment = true, HatAttachment = true,
    FaceFrontAttachment = true, FaceCenterAttachment = true,
}

-- Catalog method: sirf Head / RightLeg badalta hai, baaki avatar same rehta hai
local function patchDescription(changes)
    local hum = getHum(LP.Character)
    if not hum then return false, "Character load nahi hua" end
    saveOriginal()
    local okG, desc = pcall(function() return hum:GetAppliedDescription() end)
    if not okG then return false, "Description nahi mila" end
    for k, v in pairs(changes) do desc[k] = v end
    local okA, err = pcall(function() hum:ApplyDescription(desc) end)
    if not okA then return false, tostring(err) end
    return true
end

local function notifyResult(ok, err, good)
    notify("Body Mods", ok and good or ("Failed: " .. tostring(err)))
end

-- Fast headless + invisible leg + hide head accessories (har frame lagta hai, game reset kare tab bhi)
RunService.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end

    if state.headlessFast then
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 1
            for _, d in ipairs(head:GetChildren()) do
                if d:IsA("Decal") then d.Transparency = 1 end
            end
        end
    end

    if state.hideHeadAcc then
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                local att = handle and handle:FindFirstChildOfClass("Attachment")
                if att and headAttachments[att.Name] then handle.Transparency = 1 end
            end
        end
    end

    if state.invisibleLeg then
        for _, name in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
            local part = char:FindFirstChild(name)
            if part then part.Transparency = 1 end
        end
    end
end)

local function resetVisuals()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") then d.Transparency = 0 end
        end
    end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then acc.Handle.Transparency = 0 end
    end
    for _, name in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
        local part = char:FindFirstChild(name)
        if part then part.Transparency = 0 end
    end
end

BodyTab:CreateSection("Headless")
BodyTab:CreateToggle({ Name = "Headless (Fast)", CurrentValue = false, Flag = "HeadlessFast",
    Callback = function(v)
        state.headlessFast = v
        if not v then resetVisuals() end
    end })
BodyTab:CreateToggle({ Name = "Hide Hair / Hats too", CurrentValue = false, Flag = "HideHeadAcc",
    Callback = function(v)
        state.hideHeadAcc = v
        if not v then resetVisuals() end
    end })
BodyTab:CreateButton({ Name = "Headless (Catalog Mesh)", Callback = function()
    local ok, err = patchDescription({ Head = HEADLESS_ID })
    if ok then state.catalogHeadless = true end
    notifyResult(ok, err, "Headless applied")
end })

BodyTab:CreateSection("Korblox")
BodyTab:CreateButton({ Name = "Korblox Leg (Catalog Mesh)", Callback = function()
    local ok, err = patchDescription({ RightLeg = KORBLOX_ID })
    if ok then state.catalogKorblox = true end
    notifyResult(ok, err, "Korblox applied")
end })
BodyTab:CreateToggle({ Name = "Invisible Right Leg (Fast)", CurrentValue = false, Flag = "InvisLeg",
    Callback = function(v)
        state.invisibleLeg = v
        if not v then resetVisuals() end
    end })

BodyTab:CreateSection("Combo")
BodyTab:CreateButton({ Name = "Headless + Korblox (Both)", Callback = function()
    local ok, err = patchDescription({ Head = HEADLESS_ID, RightLeg = KORBLOX_ID })
    if ok then state.catalogHeadless, state.catalogKorblox = true, true end
    notifyResult(ok, err, "Headless + Korblox applied")
end })

BodyTab:CreateSection("Custom Asset ID (apna head ya leg)")
BodyTab:CreateInput({ Name = "Custom Head Asset ID", PlaceholderText = "e.g. 134082579", RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local id = tonumber(text)
        if not id then return notify("Body Mods", "Sahi number daalo") end
        local ok, err = patchDescription({ Head = id })
        notifyResult(ok, err, "Custom head applied")
    end })
BodyTab:CreateInput({ Name = "Custom Right Leg Asset ID", PlaceholderText = "e.g. 139607718", RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local id = tonumber(text)
        if not id then return notify("Body Mods", "Sahi number daalo") end
        local ok, err = patchDescription({ RightLeg = id })
        notifyResult(ok, err, "Custom leg applied")
    end })

BodyTab:CreateSection("Options")
local keepBodyMods = true
BodyTab:CreateToggle({ Name = "Respawn ke baad dobara apply karo", CurrentValue = true, Flag = "KeepBody",
    Callback = function(v) keepBodyMods = v end })

BodyTab:CreateButton({ Name = "Reset Body Mods", Callback = function()
    state.headlessFast, state.hideHeadAcc, state.invisibleLeg = false, false, false
    state.catalogHeadless, state.catalogKorblox = false, false
    resetVisuals()
    if savedDesc then
        patchDescription({ Head = savedDesc.Head, RightLeg = savedDesc.RightLeg })
    end
    notify("Body Mods", "Reset ho gaya")
end })

LP.CharacterAdded:Connect(function(char)
    if not keepBodyMods then return end
    if state.catalogHeadless or state.catalogKorblox then
        char:WaitForChild("Humanoid", 10)
        task.wait(1.2)
        local changes = {}
        if state.catalogHeadless then changes.Head = HEADLESS_ID end
        if state.catalogKorblox then changes.RightLeg = KORBLOX_ID end
        patchDescription(changes)
    end
end)

-- ===== HOUSE UNBAN & MANAGER (client-side) =====
local HouseTab = Window:CreateTab("House", "home")

local HS = {
    unbanLoop = false,
    noclip = false,
    doorNoclip = false,
}

local function isBanBarrier(p)
    if not p:IsA("BasePart") then return false end
    local n = p.Name:lower()
    if n:find("ban") or n:find("barrier") or n:find("block") or n:find("wall") then
        return true
    end
    -- red transparent barriers (common for house bans)
    if p.Transparency >= 0.4 and p.CanCollide then
        local c = p.Color
        if c.R > 0.7 and c.G < 0.4 and c.B < 0.4 then
            return true
        end
    end
    return false
end

local function killBarriers()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isBanBarrier(v) then
            pcall(function()
                v.CanCollide = false
                v.Transparency = 1
                v.CanQuery = false
                if v.Name:lower():find("ban") or v.Name:lower():find("barrier") then
                    v:Destroy()
                end
            end)
            count = count + 1
        end
    end
    return count
end

HouseTab:CreateSection("Unban / Barrier Bypass")
HouseTab:CreateButton({ Name = "Unban All Houses (Destroy Barriers)", Callback = function()
    local n = killBarriers()
    notify("House", n > 0 and ("Barriers cleared: " .. n) or "Koi barrier nahi mila (already clear?)")
end })

HouseTab:CreateToggle({ Name = "Auto Unban Loop (har 2 sec check)", CurrentValue = false,
    Callback = function(v)
        HS.unbanLoop = v
        if v then
            task.spawn(function()
                while HS.unbanLoop do
                    killBarriers()
                    task.wait(2)
                end
            end)
            notify("House", "Auto Unban ON")
        else
            notify("House", "Auto Unban OFF")
        end
    end })

HouseTab:CreateSection("Walk Through")
HouseTab:CreateToggle({ Name = "Noclip (Character)", CurrentValue = false,
    Callback = function(v)
        HS.noclip = v
        notify("House", v and "Noclip ON" or "Noclip OFF")
    end })

HouseTab:CreateToggle({ Name = "Doors + Barriers Collision Off", CurrentValue = false,
    Callback = function(v)
        HS.doorNoclip = v
        if v then
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    local n = d.Name:lower()
                    if n:find("door") or n:find("gate") or n:find("barrier") or isBanBarrier(d) then
                        d.CanCollide = false
                    end
                end
            end
            notify("House", "Doors/Barriers collision disabled")
        else
            notify("House", "Door collision toggle OFF (new doors may still collide)")
        end
    end })

-- continuous noclip
RunService.Stepped:Connect(function()
    if not HS.noclip then return end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end)

HouseTab:CreateSection("Quick Teleport")
HouseTab:CreateButton({ Name = "TP to Nearest House Plot", Callback = function()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return notify("House", "Character load nahi hua") end

    local best, bestDist = nil, math.huge
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") and (m.Name:lower():find("house") or m.Name:lower():find("plot") or m.Name:lower():find("home")) then
            local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
            if pp then
                local d = (pp.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = pp
                end
            end
        end
    end
    if best then
        root.CFrame = best.CFrame + Vector3.new(0, 5, 0)
        notify("House", "Teleported to nearest house")
    else
        notify("House", "Koi house plot nahi mila")
    end
end })

HouseTab:CreateButton({ Name = "Clear All House Barriers Now", Callback = function()
    local n = killBarriers()
    notify("House", "Force clear done (" .. n .. " parts)")
end })

-- ===== 70+ GAMEPASS-STYLE EFFECTS (client-side, sirf tujhe dikhenge) =====
local FXControl = Window:CreateTab("Effects", "star")
local FXParticles = Window:CreateTab("Particles", "flame")
local FXTrails = Window:CreateTab("Trails & Auras", "zap")
local FXSkins = Window:CreateTab("Skins & Misc", "gem")

local TEX = {
    sparkle = "rbxasset://textures/particles/sparkles_main.dds",
    fire = "rbxasset://textures/particles/fire_main.dds",
    smoke = "rbxasset://textures/particles/smoke_main.dds",
}

local fxIntensity = 1
local fxKeep = true
local FX, FXOrder, FXActive, FXWanted, FXToggles = {}, {}, {}, {}, {}
local setFX

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function fxRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function seq(...)
    local cols, kps = { ... }, {}
    for i, c in ipairs(cols) do
        kps[i] = ColorSequenceKeypoint.new((i - 1) / (#cols - 1), c)
    end
    return ColorSequence.new(kps)
end

local RAINBOW = seq(rgb(255, 60, 60), rgb(255, 200, 50), rgb(80, 255, 100), rgb(60, 220, 255),
    rgb(120, 80, 255), rgb(255, 80, 220), rgb(255, 60, 60))

local FADE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(0.7, 0.4),
    NumberSequenceKeypoint.new(1, 1),
})

-- ---------- Builders ----------
local function particleBuilder(cfg)
    return function(char)
        local root = fxRoot()
        if not root then return end
        local e = Instance.new("ParticleEmitter")
        e.Name = "RuboFX"
        e.Texture = cfg.tex or TEX.sparkle
        e.Color = typeof(cfg.color) == "ColorSequence" and cfg.color or ColorSequence.new(cfg.color)
        local base = cfg.rate or 30
        e:SetAttribute("BaseRate", base)
        e.Rate = base * fxIntensity
        e.Lifetime = NumberRange.new(table.unpack(cfg.life or { 1, 2 }))
        e.Speed = NumberRange.new(table.unpack(cfg.speed or { 2, 5 }))
        local s = cfg.size or 1
        e.Size = type(s) == "table" and NumberSequence.new(s[1], s[2]) or NumberSequence.new(s)
        e.Transparency = FADE
        e.LightEmission = cfg.light or 0.5
        e.Acceleration = cfg.accel or Vector3.zero
        e.SpreadAngle = Vector2.new(cfg.spread or 180, cfg.spread or 180)
        e.EmissionDirection = cfg.dir or Enum.NormalId.Top
        e.RotSpeed = NumberRange.new(-80, 80)
        e.Rotation = NumberRange.new(0, 360)
        e.Parent = root
        return function() e:Destroy() end
    end
end

local function lightBuilder(color, range, bright)
    return function(char)
        local root = fxRoot()
        if not root then return end
        local l = Instance.new("PointLight")
        l.Color, l.Range, l.Brightness, l.Shadows = color, range or 18, bright or 3, false
        l.Parent = root
        return function() l:Destroy() end
    end
end

local function rainbowLightBuilder()
    return function(char)
        local root = fxRoot()
        if not root then return end
        local l = Instance.new("PointLight")
        l.Range, l.Shadows, l.Parent = 20, false, root
        local conn = RunService.Heartbeat:Connect(function()
            local t = tick()
            l.Color = Color3.fromHSV((t * 0.25) % 1, 0.8, 1)
            l.Brightness = 2.5 + math.sin(t * 4) * 1.2
        end)
        return function() conn:Disconnect() l:Destroy() end
    end
end

local function highlightBuilder(color, rainbow)
    return function(char)
        local h = Instance.new("Highlight")
        h.Adornee = char
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = color or Color3.new(1, 1, 1)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        local conn
        if rainbow then
            conn = RunService.Heartbeat:Connect(function()
                h.OutlineColor = Color3.fromHSV((tick() * 0.3) % 1, 0.9, 1)
            end)
        end
        return function() if conn then conn:Disconnect() end h:Destroy() end
    end
end

local function trailBuilder(colorSeq, life)
    return function(char)
        local root = fxRoot()
        if not root then return end
        local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
        a0.Name, a1.Name = "RuboTrailA", "RuboTrailB"
        a0.Position, a1.Position = Vector3.new(0, 0.9, 0), Vector3.new(0, -0.9, 0)
        a0.Parent, a1.Parent = root, root
        local t = Instance.new("Trail")
        t.Attachment0, t.Attachment1 = a0, a1
        t.Color = colorSeq
        t.Lifetime = life or 0.9
        t.LightEmission = 0.8
        t.Transparency = NumberSequence.new(0.1, 1)
        t.WidthScale = NumberSequence.new(1, 0.1)
        t.FaceCamera = true
        t.Parent = root
        return function() t:Destroy() a0:Destroy() a1:Destroy() end
    end
end

local function skinBuilder(o)
    return function(char)
        local saved, parts = {}, {}
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                saved[p] = { p.Material, p.Color, p.Transparency, p.Reflectance }
                parts[#parts + 1] = p
            end
        end
        for _, p in ipairs(parts) do
            if o.material then p.Material = o.material end
            if o.color then p.Color = o.color end
            if o.transparency then p.Transparency = o.transparency end
            if o.reflectance then p.Reflectance = o.reflectance end
        end
        local conn
        if o.rainbow then
            conn = RunService.Heartbeat:Connect(function()
                local c = Color3.fromHSV((tick() * 0.3) % 1, 0.8, 1)
                for _, p in ipairs(parts) do if p.Parent then p.Color = c end end
            end)
        end
        return function()
            if conn then conn:Disconnect() end
            for p, s in pairs(saved) do
                if p.Parent then p.Material, p.Color, p.Transparency, p.Reflectance = s[1], s[2], s[3], s[4] end
            end
        end
    end
end

local function haloBuilder(color, rainbow)
    return function(char)
        local head = char:FindFirstChild("Head")
        if not head then return end
        local ring = Instance.new("Part")
        ring.Name = "RuboHalo"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.18, 2.4, 2.4)
        ring.Material = Enum.Material.Neon
        ring.Color = color
        ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.Massless = false, false, false, true
        ring.CFrame = head.CFrame * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.pi / 2)
        ring.Parent = char
        local w = Instance.new("WeldConstraint")
        w.Part0, w.Part1, w.Parent = head, ring, ring
        local l = Instance.new("PointLight")
        l.Color, l.Range, l.Brightness, l.Parent = color, 10, 2, ring
        local conn
        if rainbow then
            conn = RunService.Heartbeat:Connect(function()
                local c = Color3.fromHSV((tick() * 0.3) % 1, 0.8, 1)
                ring.Color, l.Color = c, c
            end)
        end
        return function() if conn then conn:Disconnect() end ring:Destroy() end
    end
end

local function orbBuilder(colors, count)
    return function(char)
        local orbs = {}
        for i = 1, count do
            local o = Instance.new("Part")
            o.Name = "RuboOrb"
            o.Shape = Enum.PartType.Ball
            o.Size = Vector3.new(0.7, 0.7, 0.7)
            o.Material = Enum.Material.Neon
            o.Color = colors[(i - 1) % #colors + 1]
            o.Anchored, o.CanCollide, o.CanQuery, o.CanTouch = true, false, false, false
            o.Parent = Workspace
            local l = Instance.new("PointLight")
            l.Color, l.Range, l.Brightness, l.Parent = o.Color, 8, 2, o
            orbs[i] = o
        end
        local conn = RunService.Heartbeat:Connect(function()
            local r = fxRoot()
            if not r then return end
            local t = tick()
            for i, o in ipairs(orbs) do
                local a = t * 2 + (i - 1) * (2 * math.pi / count)
                o.CFrame = CFrame.new(r.Position + Vector3.new(math.cos(a) * 3.8, 0.5 + math.sin(t * 3 + i) * 0.6, math.sin(a) * 3.8))
            end
        end)
        return function()
            conn:Disconnect()
            for _, o in ipairs(orbs) do o:Destroy() end
        end
    end
end

local function ringBuilder(color)
    return function(char)
        local p = Instance.new("Part")
        p.Name = "RuboRing"
        p.Shape = Enum.PartType.Cylinder
        p.Material = Enum.Material.Neon
        p.Color, p.Transparency = color, 0.35
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
        p.Size = Vector3.new(0.2, 6, 6)
        p.Parent = Workspace
        local conn = RunService.Heartbeat:Connect(function()
            local r = fxRoot()
            if not r then return end
            local s = 5 + math.sin(tick() * 3) * 0.8
            p.Size = Vector3.new(0.2, s, s)
            p.CFrame = CFrame.new(r.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.pi / 2)
        end)
        return function() conn:Disconnect() p:Destroy() end
    end
end

-- ---------- Enable / Disable ----------
local function disableFX(name)
    local c = FXActive[name]
    if c then pcall(c) FXActive[name] = nil end
end

local function enableFX(name)
    disableFX(name)
    local def, char = FX[name], LP.Character
    if not (def and char) then return end
    local ok, cleanup = pcall(def.build, char)
    if ok and cleanup then
        FXActive[name] = cleanup
    elseif not ok then
        notify("Effects", "Error: " .. name)
    end
end

setFX = function(name, on)
    local def = FX[name]
    if not def then return end
    if on then
        FXWanted[name] = true
        if def.group then
            for other, od in pairs(FX) do
                if other ~= name and od.group == def.group and FXWanted[other] then
                    FXWanted[other] = nil
                    disableFX(other)
                    if FXToggles[other] then FXToggles[other]:Set(false) end
                end
            end
        end
        enableFX(name)
    else
        FXWanted[name] = nil
        disableFX(name)
    end
end

local function addFX(tab, name, builder, group)
    FX[name] = { build = builder, group = group }
    table.insert(FXOrder, name)
    FXToggles[name] = tab:CreateToggle({ Name = name, CurrentValue = false,
        Callback = function(v) setFX(name, v) end })
end

local function disableAllFX()
    for _, name in ipairs(FXOrder) do
        if FXWanted[name] then
            FXWanted[name] = nil
            disableFX(name)
            FXToggles[name]:Set(false)
        end
    end
end

-- ---------- 1) PARTICLES (30) ----------
local V3 = Vector3.new
local PARTICLES = {
    "Fire & Flames",
    { "Fire", { tex = TEX.fire, color = seq(rgb(255, 210, 70), rgb(255, 100, 0), rgb(110, 0, 0)), rate = 40, life = { 0.8, 1.4 }, speed = { 2, 4 }, size = { 2.2, 0.4 }, light = 0.8, accel = V3(0, 6, 0), spread = 25 } },
    { "Blue Fire", { tex = TEX.fire, color = seq(rgb(120, 220, 255), rgb(0, 120, 255), rgb(0, 40, 160)), rate = 40, life = { 0.8, 1.4 }, speed = { 2, 4 }, size = { 2.2, 0.4 }, light = 0.8, accel = V3(0, 6, 0), spread = 25 } },
    { "Green Fire", { tex = TEX.fire, color = seq(rgb(200, 255, 120), rgb(60, 220, 60), rgb(0, 100, 20)), rate = 40, life = { 0.8, 1.4 }, speed = { 2, 4 }, size = { 2.2, 0.4 }, light = 0.8, accel = V3(0, 6, 0), spread = 25 } },
    { "Purple Fire", { tex = TEX.fire, color = seq(rgb(230, 150, 255), rgb(150, 50, 230), rgb(60, 0, 120)), rate = 40, life = { 0.8, 1.4 }, speed = { 2, 4 }, size = { 2.2, 0.4 }, light = 0.8, accel = V3(0, 6, 0), spread = 25 } },
    { "White Fire", { tex = TEX.fire, color = seq(rgb(255, 255, 255), rgb(220, 230, 255), rgb(140, 160, 200)), rate = 40, life = { 0.8, 1.4 }, speed = { 2, 4 }, size = { 2.2, 0.4 }, light = 0.9, accel = V3(0, 6, 0), spread = 25 } },
    { "Embers", { tex = TEX.fire, color = seq(rgb(255, 140, 30), rgb(255, 60, 0)), rate = 25, life = { 1.5, 2.5 }, speed = { 3, 6 }, size = 0.5, light = 1, accel = V3(0, 6, 0), spread = 60 } },
    { "Lava Drip", { tex = TEX.fire, color = seq(rgb(255, 160, 40), rgb(200, 30, 0)), rate = 15, life = { 1, 1.5 }, speed = { 1, 2 }, size = 0.6, light = 1, accel = V3(0, -20, 0), spread = 30, dir = Enum.NormalId.Bottom } },

    "Smoke & Mist",
    { "Smoke", { tex = TEX.smoke, color = seq(rgb(180, 180, 180), rgb(90, 90, 90)), rate = 25, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 6 }, light = 0, accel = V3(0, 3, 0), spread = 40 } },
    { "Black Smoke", { tex = TEX.smoke, color = seq(rgb(40, 40, 40), rgb(10, 10, 10)), rate = 25, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 6 }, light = 0, accel = V3(0, 3, 0), spread = 40 } },
    { "Dust Cloud", { tex = TEX.smoke, color = seq(rgb(190, 160, 120), rgb(120, 95, 70)), rate = 20, life = { 1.5, 2.5 }, speed = { 3, 6 }, size = { 1.5, 4 }, light = 0, spread = 180 } },
    { "Frost Mist", { tex = TEX.smoke, color = seq(rgb(220, 245, 255), rgb(140, 200, 255)), rate = 18, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 5 }, light = 0.3, spread = 180 } },
    { "Toxic Gas", { tex = TEX.smoke, color = seq(rgb(120, 255, 60), rgb(40, 120, 10)), rate = 20, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 5 }, light = 0.4, accel = V3(0, 2, 0), spread = 180 } },
    { "Blood Mist", { tex = TEX.smoke, color = seq(rgb(180, 0, 0), rgb(80, 0, 0)), rate = 20, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 5 }, light = 0.1, spread = 180 } },
    { "Shadow Mist", { tex = TEX.smoke, color = seq(rgb(30, 30, 45), rgb(5, 5, 10)), rate = 30, life = { 2, 3 }, speed = { 1, 3 }, size = { 2, 6 }, light = 0, spread = 180 } },
    { "Void", { tex = TEX.smoke, color = seq(rgb(20, 0, 40), rgb(90, 0, 160)), rate = 25, life = { 2, 3 }, speed = { 1, 3 }, size = { 3, 6 }, light = 0.2, spread = 180 } },

    "Sparkles & Magic",
    { "Gold Sparkles", { color = seq(rgb(255, 230, 120), rgb(255, 180, 40)), rate = 35, life = { 1, 2 }, speed = { 1, 4 }, size = { 0.5, 0 }, light = 1 } },
    { "Silver Sparkles", { color = seq(rgb(255, 255, 255), rgb(170, 180, 200)), rate = 35, life = { 1, 2 }, speed = { 1, 4 }, size = { 0.5, 0 }, light = 1 } },
    { "Pink Sparkles", { color = seq(rgb(255, 190, 230), rgb(255, 90, 190)), rate = 35, life = { 1, 2 }, speed = { 1, 4 }, size = { 0.5, 0 }, light = 1 } },
    { "Cyan Sparkles", { color = seq(rgb(190, 255, 255), rgb(40, 190, 255)), rate = 35, life = { 1, 2 }, speed = { 1, 4 }, size = { 0.5, 0 }, light = 1 } },
    { "Stardust", { color = seq(rgb(255, 255, 255), rgb(150, 190, 255), rgb(190, 130, 255)), rate = 50, life = { 1, 2 }, speed = { 5, 9 }, size = 0.4, light = 1 } },
    { "Electric Sparks", { color = seq(rgb(180, 220, 255), rgb(80, 140, 255)), rate = 60, life = { 0.2, 0.4 }, speed = { 8, 14 }, size = 0.5, light = 1 } },
    { "Rainbow Burst", { color = RAINBOW, rate = 45, life = { 1, 2 }, speed = { 4, 8 }, size = 0.6, light = 0.8 } },
    { "Galaxy", { color = seq(rgb(140, 60, 255), rgb(40, 60, 200), rgb(255, 80, 200)), rate = 45, life = { 1.5, 2.5 }, speed = { 2, 5 }, size = 0.7, light = 1 } },
    { "Holy Light", { color = seq(rgb(255, 255, 230), rgb(255, 220, 120)), rate = 25, life = { 2, 3 }, speed = { 1, 3 }, size = { 1.2, 0 }, light = 1, accel = V3(0, 8, 0), spread = 40 } },

    "Nature & Fun",
    { "Snowfall", { color = seq(rgb(255, 255, 255), rgb(220, 235, 255)), rate = 30, life = { 3, 4 }, speed = { 1, 3 }, size = 0.35, light = 0.5, accel = V3(0, -3, 0) } },
    { "Bubbles", { color = seq(rgb(190, 235, 255), rgb(120, 200, 255)), rate = 15, life = { 2, 3 }, speed = { 1, 3 }, size = { 0.8, 1 }, light = 0.3, accel = V3(0, 2, 0) } },
    { "Fireflies", { color = seq(rgb(220, 255, 100), rgb(255, 255, 160)), rate = 14, life = { 3, 4 }, speed = { 0.5, 1.5 }, size = 0.4, light = 1 } },
    { "Confetti", { color = RAINBOW, rate = 40, life = { 1.5, 2 }, speed = { 6, 10 }, size = 0.4, light = 0.4, accel = V3(0, -12, 0), spread = 90 } },
    { "Heart Glow", { color = seq(rgb(255, 150, 190), rgb(255, 60, 130)), rate = 14, life = { 2, 3 }, speed = { 1, 3 }, size = { 0.9, 0.2 }, light = 0.6, accel = V3(0, 3, 0), spread = 60 } },
    { "Healing Green", { color = seq(rgb(190, 255, 200), rgb(60, 220, 110)), rate = 20, life = { 1.5, 2.5 }, speed = { 1, 3 }, size = 0.6, light = 0.9, accel = V3(0, 6, 0), spread = 50 } },
}

for _, entry in ipairs(PARTICLES) do
    if type(entry) == "string" then
        FXParticles:CreateSection(entry)
    else
        addFX(FXParticles, entry[1], particleBuilder(entry[2]))
    end
end

-- ---------- 2) TRAILS & AURAS (26) ----------
FXTrails:CreateSection("Trails")
local TRAILS = {
    { "Rainbow Trail", RAINBOW },
    { "Fire Trail", seq(rgb(255, 220, 80), rgb(255, 90, 0), rgb(120, 0, 0)) },
    { "Ice Trail", seq(rgb(230, 250, 255), rgb(100, 190, 255)) },
    { "Neon Blue Trail", seq(rgb(80, 200, 255), rgb(0, 80, 255)) },
    { "Neon Pink Trail", seq(rgb(255, 150, 230), rgb(255, 0, 150)) },
    { "Neon Green Trail", seq(rgb(180, 255, 150), rgb(0, 255, 80)) },
    { "Gold Trail", seq(rgb(255, 245, 160), rgb(255, 180, 0)) },
    { "Purple Trail", seq(rgb(220, 150, 255), rgb(110, 0, 220)) },
    { "Blood Trail", seq(rgb(255, 80, 80), rgb(110, 0, 0)) },
    { "White Trail", seq(rgb(255, 255, 255), rgb(200, 210, 230)) },
    { "Shadow Trail", seq(rgb(60, 60, 80), rgb(0, 0, 0)) },
    { "Cyber Trail", seq(rgb(0, 255, 255), rgb(255, 0, 200)) },
}
for _, t in ipairs(TRAILS) do
    addFX(FXTrails, t[1], trailBuilder(t[2]))
end

FXTrails:CreateSection("Light Auras")
local LIGHTS = {
    { "Red Glow", rgb(255, 50, 50) }, { "Orange Glow", rgb(255, 140, 30) },
    { "Yellow Glow", rgb(255, 235, 60) }, { "Green Glow", rgb(60, 255, 100) },
    { "Cyan Glow", rgb(40, 240, 255) }, { "Blue Glow", rgb(50, 100, 255) },
    { "Purple Glow", rgb(170, 70, 255) }, { "Pink Glow", rgb(255, 90, 200) },
    { "White Glow", rgb(255, 255, 255) },
}
for _, l in ipairs(LIGHTS) do
    addFX(FXTrails, l[1], lightBuilder(l[2]))
end
addFX(FXTrails, "Rainbow Pulse Glow", rainbowLightBuilder())

FXTrails:CreateSection("Outline Glow")
addFX(FXTrails, "Cyan Outline", highlightBuilder(rgb(0, 240, 255)))
addFX(FXTrails, "Pink Outline", highlightBuilder(rgb(255, 80, 200)))
addFX(FXTrails, "Gold Outline", highlightBuilder(rgb(255, 210, 60)))
addFX(FXTrails, "Rainbow Outline", highlightBuilder(nil, true))

-- ---------- 3) SKINS & MISC (17) ----------
FXSkins:CreateSection("Body Skins (ek time pe ek)")
local M = Enum.Material
local SKINS = {
    { "Neon Skin", { material = M.Neon } },
    { "Gold Skin", { material = M.Metal, color = rgb(255, 200, 60), reflectance = 0.3 } },
    { "Ice Skin", { material = M.Ice, color = rgb(170, 225, 255) } },
    { "Glass Skin", { material = M.Glass, transparency = 0.5, reflectance = 0.2 } },
    { "Marble Skin", { material = M.Marble, color = rgb(245, 245, 250) } },
    { "Diamond Skin", { material = M.DiamondPlate, color = rgb(190, 230, 255), reflectance = 0.25 } },
    { "ForceField Skin", { material = M.ForceField } },
    { "Ghost Skin", { material = M.Neon, color = rgb(230, 245, 255), transparency = 0.6 } },
    { "Rainbow Skin", { material = M.Neon, rainbow = true } },
    { "Shadow Skin", { material = M.SmoothPlastic, color = rgb(8, 8, 12) } },
}
for _, s in ipairs(SKINS) do
    addFX(FXSkins, s[1], skinBuilder(s[2]), "skin")
end

FXSkins:CreateSection("Halos")
addFX(FXSkins, "Gold Halo", haloBuilder(rgb(255, 215, 80)))
addFX(FXSkins, "Cyan Halo", haloBuilder(rgb(60, 235, 255)))
addFX(FXSkins, "Rainbow Halo", haloBuilder(rgb(255, 255, 255), true))

FXSkins:CreateSection("Orbiting Orbs & Rings")
addFX(FXSkins, "Blue Orbs", orbBuilder({ rgb(60, 170, 255), rgb(120, 220, 255) }, 4))
addFX(FXSkins, "Pink Orbs", orbBuilder({ rgb(255, 90, 200), rgb(255, 170, 230) }, 4))
addFX(FXSkins, "Rainbow Orbs", orbBuilder({ rgb(255, 70, 70), rgb(255, 200, 50), rgb(80, 255, 100), rgb(60, 200, 255), rgb(170, 90, 255) }, 5))
addFX(FXSkins, "Cyan Ground Ring", ringBuilder(rgb(40, 220, 255)))
addFX(FXSkins, "Gold Ground Ring", ringBuilder(rgb(255, 205, 70)))

-- ---------- CONTROL TAB ----------
FXControl:CreateSection("Controls")
FXControl:CreateSlider({ Name = "Effect Intensity", Range = { 0.2, 3 }, Increment = 0.1, CurrentValue = 1, Flag = "FXIntensity",
    Callback = function(v)
        fxIntensity = v
        local char = LP.Character
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            local b = d:GetAttribute("BaseRate")
            if b then d.Rate = b * fxIntensity end
        end
    end })
FXControl:CreateToggle({ Name = "Respawn ke baad effects rakho", CurrentValue = true, Flag = "FXKeep",
    Callback = function(v) fxKeep = v end })
FXControl:CreateButton({ Name = "Random Effect", Callback = function()
    local name = FXOrder[math.random(1, #FXOrder)]
    FXToggles[name]:Set(true)
    notify("Effects", "Enabled: " .. name)
end })
FXControl:CreateButton({ Name = "Disable All Effects", Callback = function()
    disableAllFX()
    notify("Effects", "Sab effects band")
end })

FXControl:CreateSection("Combos (ek click me poora look)")
local COMBOS = {
    { "Dominus Look", { "Fire", "Gold Halo", "Gold Skin", "Gold Trail" } },
    { "Ice Queen", { "Frost Mist", "Snowfall", "Ice Skin", "Ice Trail", "Cyan Halo" } },
    { "Galaxy Lord", { "Galaxy", "Stardust", "Purple Glow", "Cyber Trail", "Blue Orbs" } },
    { "Rainbow Party", { "Rainbow Burst", "Confetti", "Rainbow Trail", "Rainbow Halo", "Rainbow Orbs" } },
    { "Dark Lord", { "Shadow Mist", "Void", "Shadow Skin", "Shadow Trail", "Red Glow" } },
    { "RUBO Blue", { "Blue Fire", "Electric Sparks", "Neon Blue Trail", "Cyan Outline", "Cyan Ground Ring" } },
}
for _, combo in ipairs(COMBOS) do
    FXControl:CreateButton({ Name = combo[1], Callback = function()
        disableAllFX()
        for _, n in ipairs(combo[2]) do FXToggles[n]:Set(true) end
        notify("Effects", combo[1] .. " ON")
    end })
end

LP.CharacterAdded:Connect(function(char)
    for name in pairs(FXActive) do disableFX(name) end
    char:WaitForChild("HumanoidRootPart", 10)
    task.wait(1.5)
    if fxKeep then
        for name in pairs(FXWanted) do enableFX(name) end
    else
        disableAllFX()
    end
end)

-- ===== RGB NAME, BIO & VEHICLE (client-side) =====
local RGBTab = Window:CreateTab("RGB", "palette")
local VehTab = Window:CreateTab("RGB Vehicle", "car")

local lerp3 = function(a, b, k) return a:Lerp(b, k) end
local function wave(t) return (math.sin(t * 2 * math.pi) + 1) / 2 end

local ColorFns = {
    ["Rainbow"] = function(t) return Color3.fromHSV(t % 1, 0.85, 1) end,
    ["Fire"] = function(t) return lerp3(rgb(255, 50, 0), rgb(255, 225, 50), wave(t)) end,
    ["Ice"] = function(t) return lerp3(rgb(0, 200, 255), rgb(190, 235, 255), wave(t)) end,
    ["Police"] = function(t) return (math.floor(t * 4) % 2 == 0) and rgb(255, 20, 20) or rgb(20, 60, 255) end,
    ["Neon Pulse"] = function(t) return lerp3(rgb(255, 40, 200), rgb(0, 240, 255), wave(t)) end,
    ["Gold"] = function(t) return lerp3(rgb(190, 130, 15), rgb(255, 245, 160), wave(t)) end,
    ["Matrix"] = function(t) return lerp3(rgb(0, 70, 0), rgb(0, 255, 70), wave(t)) end,
}
local styleList = { "Rainbow", "Fire", "Ice", "Police", "Neon Pulse", "Gold", "Matrix" }

local RGBS = {
    speed = 1, mode = "Rainbow",
    gameTags = false, hideGame = false,
    customTag = false, letterWave = true,
    customName = LP.DisplayName, customBio = "RUBO HUB",
}

local tagList, tagOrig, hiddenGuis = {}, {}, {}

local function scanTags()
    local list = {}
    local char = LP.Character
    if not char then return list end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BillboardGui") and d.Name ~= "RuboCustomTag" then
            if RGBS.hideGame then
                if hiddenGuis[d] == nil then hiddenGuis[d] = d.Enabled end
                d.Enabled = false
            end
            if RGBS.gameTags then
                for _, l in ipairs(d:GetDescendants()) do
                    if l:IsA("TextLabel") then
                        if not tagOrig[l] then tagOrig[l] = l.TextColor3 end
                        list[#list + 1] = l
                    end
                end
            end
        end
    end
    return list
end

local function restoreTagColors()
    for l, c in pairs(tagOrig) do
        if l.Parent then l.TextColor3 = c end
    end
    tagOrig = {}
end

local function restoreHiddenGuis()
    for g, en in pairs(hiddenGuis) do
        if g.Parent then g.Enabled = en end
    end
    hiddenGuis = {}
end

-- ---------- Custom overhead tag ----------
local customGui, nameLbl, bioLbl

local function destroyCustomTag()
    if customGui then customGui:Destroy() end
    customGui, nameLbl, bioLbl = nil, nil, nil
end

local function buildCustomTag(char)
    destroyCustomTag()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    local g = Instance.new("BillboardGui")
    g.Name = "RuboCustomTag"
    g.Adornee = head
    g.Size = UDim2.new(0, 320, 0, 80)
    g.StudsOffset = Vector3.new(0, 3.4, 0)
    g.AlwaysOnTop = true
    g.LightInfluence = 0
    g.Parent = head

    local function makeLabel(font, pos, size)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position, l.Size = pos, size
        l.Font = font
        l.TextScaled = true
        l.RichText = true
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Parent = g
        local s = Instance.new("UIStroke")
        s.Thickness, s.Transparency, s.Color = 1.5, 0.35, Color3.new(0, 0, 0)
        s.Parent = l
        return l
    end
    nameLbl = makeLabel(Enum.Font.GothamBlack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.6, 0))
    bioLbl = makeLabel(Enum.Font.GothamMedium, UDim2.new(0, 0, 0.6, 0), UDim2.new(1, 0, 0.4, 0))
    nameLbl.Text, bioLbl.Text = RGBS.customName, RGBS.customBio
    customGui = g
end

local function escapeRich(s)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    return s
end

local function richRGB(text, t, fn)
    local out, i = {}, 0
    local ok = pcall(function()
        for _, cp in utf8.codes(text) do
            i += 1
            local c = fn(t + i * 0.07)
            out[#out + 1] = string.format('<font color="#%s">%s</font>', c:ToHex(), escapeRich(utf8.char(cp)))
        end
    end)
    if not ok then return escapeRich(text) end
    return table.concat(out)
end

local function updateCustomTag(t)
    if not (customGui and customGui.Parent) then return end
    local fn = ColorFns[RGBS.mode]
    if RGBS.letterWave then
        nameLbl.RichText, bioLbl.RichText = true, true
        nameLbl.Text = richRGB(RGBS.customName, t, fn)
        bioLbl.Text = richRGB(RGBS.customBio, t + 0.3, fn)
    else
        nameLbl.RichText, bioLbl.RichText = false, false
        nameLbl.Text, bioLbl.Text = RGBS.customName, RGBS.customBio
        nameLbl.TextColor3 = fn(t)
        bioLbl.TextColor3 = fn(t + 0.3)
    end
end

-- ---------- Vehicle ----------
local VEH = {
    on = false, speed = 1, mode = "Rainbow", flow = true, skip = true, keep = true,
    neon = false, glow = false, outline = false, trail = false,
    custom = rgb(0, 200, 255),
}
local paintedVeh, vehSaved, vehLight, vehHL, vehTrail, vehTrailParts

local function currentVehicle()
    local hum = getHum(LP.Character)
    local seat = hum and hum.SeatPart
    if not seat then return nil end
    local best, cur = nil, seat.Parent
    while cur and cur ~= Workspace and cur:IsA("Model") do
        best = cur
        cur = cur.Parent
    end
    return best or (seat.Parent ~= Workspace and seat.Parent) or nil
end

local function isSkippable(p)
    if p.Material == Enum.Material.Glass or p.Transparency >= 0.3 then return true end
    local n = p.Name:lower()
    for _, k in ipairs({ "wheel", "tire", "rim", "glass", "window", "windshield", "light" }) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function vehAnchor(veh)
    return veh.PrimaryPart or veh:FindFirstChildWhichIsA("VehicleSeat", true)
        or veh:FindFirstChildWhichIsA("Seat", true) or veh:FindFirstChildWhichIsA("BasePart", true)
end

local function clearExtras()
    if vehLight then vehLight:Destroy() vehLight = nil end
    if vehHL then vehHL:Destroy() vehHL = nil end
    if vehTrailParts then
        for _, i in ipairs(vehTrailParts) do i:Destroy() end
        vehTrailParts = nil
    end
end

local function refreshExtras()
    if not paintedVeh then return end
    local anchor = vehAnchor(paintedVeh)
    if not anchor then return end
    if VEH.glow and not vehLight then
        vehLight = Instance.new("PointLight")
        vehLight.Range, vehLight.Brightness, vehLight.Shadows = 28, 4, false
        vehLight.Parent = anchor
    elseif not VEH.glow and vehLight then
        vehLight:Destroy() vehLight = nil
    end
    if VEH.outline and not vehHL then
        vehHL = Instance.new("Highlight")
        vehHL.Adornee = paintedVeh
        vehHL.FillTransparency, vehHL.OutlineTransparency = 1, 0
        vehHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        vehHL.Parent = paintedVeh
    elseif not VEH.outline and vehHL then
        vehHL:Destroy() vehHL = nil
    end
    if VEH.trail and not vehTrailParts then
        local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
        a0.Position, a1.Position = Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
        a0.Parent, a1.Parent = anchor, anchor
        local tr = Instance.new("Trail")
        tr.Attachment0, tr.Attachment1 = a0, a1
        tr.Color = RAINBOW
        tr.Lifetime = 1.2
        tr.LightEmission = 0.8
        tr.Transparency = NumberSequence.new(0.1, 1)
        tr.FaceCamera = true
        tr.Parent = anchor
        vehTrailParts = { tr, a0, a1 }
    elseif not VEH.trail and vehTrailParts then
        for _, i in ipairs(vehTrailParts) do i:Destroy() end
        vehTrailParts = nil
    end
end

local function clearVehicle()
    if vehSaved then
        for p, s in pairs(vehSaved) do
            if p.Parent then p.Color, p.Material = s[1], s[2] end
        end
    end
    clearExtras()
    paintedVeh, vehSaved = nil, nil
end

local function setupVehicle(veh)
    paintedVeh, vehSaved = veh, {}
    for _, d in ipairs(veh:GetDescendants()) do
        if d:IsA("BasePart") and not (VEH.skip and isSkippable(d)) then
            vehSaved[d] = { d.Color, d.Material }
            if VEH.neon then d.Material = Enum.Material.Neon end
        end
    end
    refreshExtras()
end

local function vehicleColor(t)
    if VEH.mode == "Custom Color" then return VEH.custom end
    return ColorFns[VEH.mode](t)
end

local function vehicleStep(t)
    if not VEH.on then
        if paintedVeh then clearVehicle() end
        return
    end
    local target = currentVehicle() or (VEH.keep and paintedVeh) or nil
    if target and not target.Parent then target = nil end
    if target ~= paintedVeh then
        clearVehicle()
        if target then setupVehicle(target) end
    end
    if not paintedVeh then return end
    for p in pairs(vehSaved) do
        if p.Parent then
            local phase = VEH.flow and (p.Position.X + p.Position.Z) * 0.03 or 0
            p.Color = vehicleColor(t + phase)
        end
    end
    local c = vehicleColor(t)
    if vehLight then vehLight.Color = c end
    if vehHL then vehHL.OutlineColor = c end
end

-- ---------- Main loop ----------
local lastScan, lastTagUpdate = 0, 0
RunService.Heartbeat:Connect(function()
    local now = tick()

    if RGBS.gameTags or RGBS.hideGame then
        if now - lastScan > 0.3 then
            lastScan = now
            tagList = scanTags()
        end
        if RGBS.gameTags then
            local fn = ColorFns[RGBS.mode]
            for i, l in ipairs(tagList) do
                if l.Parent then l.TextColor3 = fn(now * RGBS.speed + i * 0.15) end
            end
        end
    end

    if RGBS.customTag and now - lastTagUpdate > 1 / 15 then
        lastTagUpdate = now
        updateCustomTag(now * RGBS.speed)
    end

    vehicleStep(now * VEH.speed)
end)

LP.CharacterAdded:Connect(function(char)
    tagOrig, hiddenGuis = {}, {}
    if RGBS.customTag then
        char:WaitForChild("Head", 10)
        task.wait(0.5)
        buildCustomTag(char)
    end
end)

-- ---------- UI: Name & Bio ----------
RGBTab:CreateSection("Style")
RGBTab:CreateDropdown({ Name = "Name / Bio Style", Options = styleList, CurrentOption = { "Rainbow" },
    MultipleOptions = false, Flag = "RGBStyle",
    Callback = function(o) RGBS.mode = type(o) == "table" and o[1] or o end })
RGBTab:CreateSlider({ Name = "RGB Speed", Range = { 0.1, 3 }, Increment = 0.1, CurrentValue = 1, Flag = "RGBSpeed",
    Callback = function(v) RGBS.speed = v end })

RGBTab:CreateSection("Game ka Name / Bio Tag")
RGBTab:CreateToggle({ Name = "RGB on Game Name & Bio", CurrentValue = false, Flag = "RGBGameTags",
    Callback = function(v)
        RGBS.gameTags = v
        if not v then restoreTagColors() end
    end })
RGBTab:CreateToggle({ Name = "Hide Game Tag (sirf tujhe)", CurrentValue = false, Flag = "HideGameTag",
    Callback = function(v)
        RGBS.hideGame = v
        if not v then restoreHiddenGuis() end
    end })

RGBTab:CreateSection("Custom RGB Tag (apna naam + bio)")
RGBTab:CreateInput({ Name = "Name Text", PlaceholderText = LP.DisplayName, RemoveTextAfterFocusLost = false,
    Callback = function(t) if t ~= "" then RGBS.customName = t end end })
RGBTab:CreateInput({ Name = "Bio Text", PlaceholderText = "RUBO HUB", RemoveTextAfterFocusLost = false,
    Callback = function(t) if t ~= "" then RGBS.customBio = t end end })
RGBTab:CreateToggle({ Name = "Per-Letter Wave", CurrentValue = true, Flag = "LetterWave",
    Callback = function(v) RGBS.letterWave = v end })
RGBTab:CreateToggle({ Name = "Show Custom RGB Tag", CurrentValue = false, Flag = "CustomTag",
    Callback = function(v)
        RGBS.customTag = v
        if v then buildCustomTag(LP.Character) else destroyCustomTag() end
    end })

RGBTab:CreateButton({ Name = "Reset Name / Bio", Callback = function()
    RGBS.gameTags, RGBS.hideGame, RGBS.customTag = false, false, false
    restoreTagColors()
    restoreHiddenGuis()
    destroyCustomTag()
    notify("RGB", "Name / Bio reset")
end })

-- ---------- UI: Vehicle ----------
VehTab:CreateSection("Vehicle RGB (gaadi me baith ke on karo)")
VehTab:CreateToggle({ Name = "RGB Vehicle", CurrentValue = false, Flag = "VehOn",
    Callback = function(v) VEH.on = v end })
local vehStyles = { "Rainbow", "Fire", "Ice", "Police", "Neon Pulse", "Gold", "Matrix", "Custom Color" }
VehTab:CreateDropdown({ Name = "Vehicle Style", Options = vehStyles, CurrentOption = { "Rainbow" },
    MultipleOptions = false, Flag = "VehStyle",
    Callback = function(o) VEH.mode = type(o) == "table" and o[1] or o end })
VehTab:CreateColorPicker({ Name = "Custom Color", Color = VEH.custom, Flag = "VehCustom",
    Callback = function(c) VEH.custom = c end })
VehTab:CreateSlider({ Name = "Vehicle RGB Speed", Range = { 0.1, 3 }, Increment = 0.1, CurrentValue = 1, Flag = "VehSpeed",
    Callback = function(v) VEH.speed = v end })

VehTab:CreateSection("Options")
VehTab:CreateToggle({ Name = "Flow Effect (rang gaadi pe behta hai)", CurrentValue = true, Flag = "VehFlow",
    Callback = function(v) VEH.flow = v end })
VehTab:CreateToggle({ Name = "Wheels & Glass skip karo", CurrentValue = true, Flag = "VehSkip",
    Callback = function(v)
        VEH.skip = v
        local keepVeh = paintedVeh
        if keepVeh then clearVehicle() setupVehicle(keepVeh) end
    end })
VehTab:CreateToggle({ Name = "Neon Material", CurrentValue = false, Flag = "VehNeon",
    Callback = function(v)
        VEH.neon = v
        if vehSaved then
            for p, s in pairs(vehSaved) do
                if p.Parent then p.Material = v and Enum.Material.Neon or s[2] end
            end
        end
    end })
VehTab:CreateToggle({ Name = "Underglow Light", CurrentValue = false, Flag = "VehGlow",
    Callback = function(v) VEH.glow = v refreshExtras() end })
VehTab:CreateToggle({ Name = "Outline Glow", CurrentValue = false, Flag = "VehOutline",
    Callback = function(v) VEH.outline = v refreshExtras() end })
VehTab:CreateToggle({ Name = "Rainbow Trail", CurrentValue = false, Flag = "VehTrail",
    Callback = function(v) VEH.trail = v refreshExtras() end })
VehTab:CreateToggle({ Name = "Gaadi se utarne ke baad bhi chalta rahe", CurrentValue = true, Flag = "VehKeep",
    Callback = function(v) VEH.keep = v end })

VehTab:CreateButton({ Name = "Reset Vehicle", Callback = function()
    clearVehicle()
    notify("RGB", "Vehicle original colors me wapas")
end })

-- ===== CUSTOM MUSIC & ID LIBRARY (client-side: sirf tujhe sunai dega) =====
do
    local SoundService = game:GetService("SoundService")
    local HttpService = game:GetService("HttpService")
    local MusicTab = Window:CreateTab("Music", "music")
    local LibTab = Window:CreateTab("Music Library", "library")

    local MU = {
        vol = 1, speed = 1, loop = false, mode = "Global (2D)",
        auto = true, shuffle = false, index = 0, current = nil, token = 0,
        sleepToken = 0, addName = "", addId = "", selIdx = nil, histIdx = nil,
    }
    local Library, History = {}, {}
    local LIB_FILE = "RuboHub/music_library.json"

    -- ---------- Sound + effects ----------
    local sound = Instance.new("Sound")
    sound.Name = "RuboMusic"
    sound.Volume = 1
    sound.Parent = SoundService

    local function mkFx(class, name, props)
        local e = Instance.new(class)
        e.Name = name
        e.Enabled = false
        for k, v in pairs(props or {}) do e[k] = v end
        e.Parent = sound
        return e
    end
    local fxReverb = mkFx("ReverbSoundEffect", "RuboReverb", { DecayTime = 3, Density = 1, Diffusion = 1, DryLevel = -2, WetLevel = 0 })
    local fxEcho = mkFx("EchoSoundEffect", "RuboEcho", { Delay = 0.35, Feedback = 0.4, DryLevel = 0, WetLevel = -6 })
    local fxEQ = mkFx("EqualizerSoundEffect", "RuboEQ")
    local fxDist = mkFx("DistortionSoundEffect", "RuboDist", { Level = 0.5 })
    local fxChorus = mkFx("ChorusSoundEffect", "RuboChorus", { Depth = 0.45, Mix = 0.5, Rate = 5 })
    local fxPitch = mkFx("PitchShiftSoundEffect", "RuboPitch", { Octave = 1 })

    local function setEQ(name)
        fxEQ.Enabled = name ~= "Off"
        if name == "Bass Boost" then fxEQ.LowGain, fxEQ.MidGain, fxEQ.HighGain = 9, -1, 0
        elseif name == "Treble Boost" then fxEQ.LowGain, fxEQ.MidGain, fxEQ.HighGain = -3, 0, 8
        elseif name == "Muffled" then fxEQ.LowGain, fxEQ.MidGain, fxEQ.HighGain = 2, -15, -40
        elseif name == "Radio" then fxEQ.LowGain, fxEQ.MidGain, fxEQ.HighGain = -30, 5, -30
        end
    end

    -- ---------- Mode: Global / Character 3D / 8D ----------
    local orbit
    local function destroyOrbit()
        if orbit then orbit:Destroy() orbit = nil end
    end

    local function applyMode()
        local pos, playing = sound.TimePosition, sound.IsPlaying
        if MU.mode == "From Character (3D)" then
            destroyOrbit()
            local r = fxRoot()
            sound.RollOffMode = Enum.RollOffMode.Linear
            sound.RollOffMinDistance, sound.RollOffMaxDistance = 15, 400
            sound.Parent = r or SoundService
        elseif MU.mode == "8D Orbit" then
            if not orbit then
                orbit = Instance.new("Part")
                orbit.Name = "RuboOrbitSound"
                orbit.Anchored, orbit.CanCollide, orbit.CanQuery, orbit.CanTouch = true, false, false, false
                orbit.Transparency = 1
                orbit.Size = Vector3.new(1, 1, 1)
                orbit.Parent = Workspace
            end
            sound.RollOffMode = Enum.RollOffMode.Linear
            sound.RollOffMinDistance, sound.RollOffMaxDistance = 4, 120
            sound.Parent = orbit
        else
            destroyOrbit()
            sound.Parent = SoundService
        end
        if playing then
            sound.TimePosition = pos
            sound:Play()
        end
    end

    -- ---------- Helpers ----------
    local function fmt(s)
        s = math.max(0, math.floor(s or 0))
        return string.format("%d:%02d", math.floor(s / 60), s % 60)
    end
    local function copyText(t)
        if setclipboard then setclipboard(t) return true end
        if toclipboard then toclipboard(t) return true end
        return false
    end

    local function saveLib()
        pcall(function()
            if writefile then
                if makefolder and isfolder and not isfolder("RuboHub") then makefolder("RuboHub") end
                writefile(LIB_FILE, HttpService:JSONEncode(Library))
            end
        end)
    end
    local function loadLib()
        pcall(function()
            if isfile and readfile and isfile(LIB_FILE) then
                local d = HttpService:JSONDecode(readfile(LIB_FILE))
                if type(d) == "table" then
                    local clean = {}
                    for _, e in ipairs(d) do
                        if type(e) == "table" and tonumber(e.id) then
                            clean[#clean + 1] = { name = tostring(e.name or e.id), id = tonumber(e.id) }
                        end
                    end
                    Library = clean
                end
            end
        end)
    end
    loadLib()

    local function libOptions()
        local o = {}
        for i, e in ipairs(Library) do o[i] = i .. ". " .. e.name end
        if #o == 0 then o = { "(library khali hai)" } end
        return o
    end
    local function histOptions()
        local o = {}
        for i, e in ipairs(History) do o[i] = i .. ". " .. e.name end
        if #o == 0 then o = { "(history khali hai)" } end
        return o
    end

    -- ---------- UI: labels ----------
    MusicTab:CreateSection("Now Playing")
    local NowLabel = MusicTab:CreateLabel("Kuch nahi chal raha")
    local TimeLabel = MusicTab:CreateLabel("0:00 / 0:00")

    local LibDropdown, HistDropdown

    -- ---------- Play ----------
    local function playId(id, name, libIndex)
        id = tonumber(id)
        if not id then
            notify("Music", "Sahi ID daalo (sirf number)")
            return false
        end
        sound:Stop()
        sound.SoundId = "rbxassetid://" .. id
        sound.Volume = MU.vol
        sound.PlaybackSpeed = MU.speed
        sound.Looped = MU.loop
        sound.TimePosition = 0
        MU.current = { id = id, name = name or ("Track " .. id) }
        MU.index = libIndex or 0

        for i = #History, 1, -1 do
            if History[i].id == id then table.remove(History, i) end
        end
        table.insert(History, 1, MU.current)
        while #History > 15 do table.remove(History) end
        if HistDropdown then HistDropdown:Refresh(histOptions()) end

        sound:Play()
        NowLabel:Set("▶ " .. MU.current.name .. "  (ID " .. id .. ")")

        MU.token += 1
        local my = MU.token
        task.delay(8, function()
            if MU.token == my and not sound.IsLoaded then
                notify("Music", "ID load nahi hua (private, invalid ya blocked ho sakta hai)")
            end
        end)
        return true
    end

    local function playLibrary(i)
        local e = Library[i]
        if not e then
            notify("Music", "Library me pehle track select karo")
            return
        end
        playId(e.id, e.name, i)
    end

    local function nextTrack(step)
        if #Library == 0 then return end
        local i
        if MU.shuffle and #Library > 1 then
            repeat i = math.random(1, #Library) until i ~= MU.index
        else
            i = ((MU.index - 1 + step) % #Library) + 1
        end
        playLibrary(i)
    end

    sound.Ended:Connect(function()
        if MU.auto and not MU.loop and #Library > 0 and MU.index > 0 then
            nextTrack(1)
        end
    end)

    -- ---------- UI: Music tab ----------
    MusicTab:CreateSection("Play by ID")
    MusicTab:CreateInput({ Name = "Audio ID (Enter dabao)", PlaceholderText = "e.g. 1843463175", RemoveTextAfterFocusLost = false,
        Callback = function(t) if t and t ~= "" then playId(t) end end })

    MusicTab:CreateSection("Controls")
    MusicTab:CreateButton({ Name = "Pause / Resume", Callback = function()
        if sound.IsPlaying then sound:Pause() else sound:Resume() end
    end })
    MusicTab:CreateButton({ Name = "Stop", Callback = function()
        sound:Stop()
        MU.token += 1
        NowLabel:Set("Stopped")
    end })
    MusicTab:CreateButton({ Name = "Restart", Callback = function()
        sound.TimePosition = 0
        sound:Play()
    end })
    MusicTab:CreateButton({ Name = "-10 sec", Callback = function()
        sound.TimePosition = math.max(0, sound.TimePosition - 10)
    end })
    MusicTab:CreateButton({ Name = "+10 sec", Callback = function()
        sound.TimePosition = math.min(sound.TimeLength, sound.TimePosition + 10)
    end })
    MusicTab:CreateSlider({ Name = "Seek (%)", Range = { 0, 100 }, Increment = 1, CurrentValue = 0, Suffix = "%",
        Callback = function(v)
            if sound.TimeLength > 0 then sound.TimePosition = sound.TimeLength * (v / 100) end
        end })
    MusicTab:CreateSlider({ Name = "Volume", Range = { 0, 10 }, Increment = 0.1, CurrentValue = 1, Flag = "MusicVol",
        Callback = function(v) MU.vol = v sound.Volume = v end })
    MusicTab:CreateSlider({ Name = "Speed (pitch ke saath)", Range = { 0.25, 3 }, Increment = 0.05, CurrentValue = 1, Flag = "MusicSpeed",
        Callback = function(v) MU.speed = v sound.PlaybackSpeed = v end })
    MusicTab:CreateSlider({ Name = "Pitch Shift (speed same)", Range = { 0.5, 2 }, Increment = 0.05, CurrentValue = 1, Flag = "MusicPitch",
        Callback = function(v)
            fxPitch.Octave = v
            fxPitch.Enabled = math.abs(v - 1) > 0.01
        end })
    MusicTab:CreateToggle({ Name = "Loop Track", CurrentValue = false, Flag = "MusicLoop",
        Callback = function(v) MU.loop = v sound.Looped = v end })
    MusicTab:CreateToggle({ Name = "Auto-Next (library playlist)", CurrentValue = true, Flag = "MusicAuto",
        Callback = function(v) MU.auto = v end })
    MusicTab:CreateToggle({ Name = "Shuffle", CurrentValue = false, Flag = "MusicShuffle",
        Callback = function(v) MU.shuffle = v end })
    MusicTab:CreateButton({ Name = "Copy Current ID", Callback = function()
        if not MU.current then return notify("Music", "Kuch play nahi ho raha") end
        notify("Music", copyText(tostring(MU.current.id)) and "ID copy ho gaya" or "Executor me clipboard support nahi hai")
    end })

    MusicTab:CreateSection("Sound Mode")
    MusicTab:CreateDropdown({ Name = "Output Mode", Options = { "Global (2D)", "From Character (3D)", "8D Orbit" },
        CurrentOption = { "Global (2D)" }, MultipleOptions = false, Flag = "MusicMode",
        Callback = function(o)
            MU.mode = type(o) == "table" and o[1] or o
            applyMode()
        end })

    MusicTab:CreateSection("Presets")
    local function resetFx()
        fxReverb.Enabled, fxEcho.Enabled, fxDist.Enabled, fxChorus.Enabled, fxEQ.Enabled = false, false, false, false, false
        MU.speed = 1
        sound.PlaybackSpeed = 1
    end
    local presets = {
        ["Normal"] = function() resetFx() end,
        ["Nightcore"] = function() resetFx() MU.speed = 1.25 sound.PlaybackSpeed = 1.25 end,
        ["Slowed + Reverb"] = function() resetFx() MU.speed = 0.85 sound.PlaybackSpeed = 0.85 fxReverb.Enabled = true end,
        ["Bass Boosted"] = function() resetFx() setEQ("Bass Boost") fxDist.Level = 0.12 fxDist.Enabled = true end,
        ["Muffled (Club)"] = function() resetFx() setEQ("Muffled") end,
        ["Radio"] = function() resetFx() setEQ("Radio") fxDist.Level = 0.3 fxDist.Enabled = true end,
        ["Underwater"] = function() resetFx() setEQ("Muffled") fxChorus.Enabled = true end,
        ["Concert Hall"] = function() resetFx() fxReverb.DecayTime = 4.5 fxReverb.Enabled = true fxEcho.Enabled = true end,
    }
    MusicTab:CreateDropdown({ Name = "Sound Preset", Options = { "Normal", "Nightcore", "Slowed + Reverb", "Bass Boosted", "Muffled (Club)", "Radio", "Underwater", "Concert Hall" },
        CurrentOption = { "Normal" }, MultipleOptions = false,
        Callback = function(o)
            local name = type(o) == "table" and o[1] or o
            if presets[name] then presets[name]() end
        end })

    MusicTab:CreateSection("Manual Effects")
    MusicTab:CreateToggle({ Name = "Reverb", CurrentValue = false, Callback = function(v) fxReverb.Enabled = v end })
    MusicTab:CreateToggle({ Name = "Echo", CurrentValue = false, Callback = function(v) fxEcho.Enabled = v end })
    MusicTab:CreateToggle({ Name = "Distortion", CurrentValue = false, Callback = function(v) fxDist.Enabled = v end })
    MusicTab:CreateToggle({ Name = "Chorus", CurrentValue = false, Callback = function(v) fxChorus.Enabled = v end })
    MusicTab:CreateDropdown({ Name = "Equalizer", Options = { "Off", "Bass Boost", "Treble Boost", "Muffled", "Radio" },
        CurrentOption = { "Off" }, MultipleOptions = false,
        Callback = function(o) setEQ(type(o) == "table" and o[1] or o) end })

    -- ---------- Beat visualizer ----------
    MusicTab:CreateSection("Beat Visualizer (music ke saath react)")
    local viz = { light = false, bloom = false, parts = false }
    local vizLight, vizEmitter, bloomPrev

    MusicTab:CreateToggle({ Name = "Beat Light (aas-paas glow)", CurrentValue = false,
        Callback = function(v)
            viz.light = v
            if not v and vizLight then vizLight:Destroy() vizLight = nil end
        end })
    MusicTab:CreateToggle({ Name = "Beat Bloom (screen glow)", CurrentValue = false,
        Callback = function(v)
            viz.bloom = v
            if v then
                bloomPrev = { Bloom.Enabled, Bloom.Intensity }
            elseif bloomPrev then
                Bloom.Enabled, Bloom.Intensity = bloomPrev[1], bloomPrev[2]
                bloomPrev = nil
            end
        end })
    MusicTab:CreateToggle({ Name = "Beat Particles", CurrentValue = false,
        Callback = function(v)
            viz.parts = v
            if not v and vizEmitter then vizEmitter:Destroy() vizEmitter = nil end
        end })

    -- ---------- UI: Library tab ----------
    LibTab:CreateSection("Library")
    LibDropdown = LibTab:CreateDropdown({ Name = "Saved Tracks", Options = libOptions(), CurrentOption = {},
        MultipleOptions = false,
        Callback = function(o)
            local s = type(o) == "table" and o[1] or o
            MU.selIdx = tonumber(tostring(s):match("^(%d+)%."))
        end })

    local function refreshLib()
        LibDropdown:Refresh(libOptions())
        saveLib()
    end

    LibTab:CreateButton({ Name = "Play Selected", Callback = function() playLibrary(MU.selIdx) end })
    LibTab:CreateButton({ Name = "Previous", Callback = function() nextTrack(-1) end })
    LibTab:CreateButton({ Name = "Next", Callback = function() nextTrack(1) end })
    LibTab:CreateButton({ Name = "Copy Selected ID", Callback = function()
        local e = MU.selIdx and Library[MU.selIdx]
        if not e then return notify("Music", "Pehle track select karo") end
        notify("Music", copyText(tostring(e.id)) and "ID copy ho gaya" or "Executor me clipboard support nahi hai")
    end })
    LibTab:CreateButton({ Name = "Remove Selected", Callback = function()
        local i = MU.selIdx
        if not (i and Library[i]) then return notify("Music", "Pehle track select karo") end
        local removed = table.remove(Library, i)
        MU.selIdx = nil
        refreshLib()
        notify("Music", "Removed: " .. removed.name)
    end })

    LibTab:CreateSection("Add Track")
    LibTab:CreateInput({ Name = "Track Name", PlaceholderText = "song ka naam", RemoveTextAfterFocusLost = false,
        Callback = function(t) MU.addName = t or "" end })
    LibTab:CreateInput({ Name = "Track ID", PlaceholderText = "audio id", RemoveTextAfterFocusLost = false,
        Callback = function(t) MU.addId = t or "" end })

    local function addTrack(name, id)
        id = tonumber(id)
        if not id then notify("Music", "Sahi ID daalo") return nil end
        if name == nil or name == "" then name = "Track " .. id end
        table.insert(Library, { name = name, id = id })
        return #Library
    end

    LibTab:CreateButton({ Name = "Add to Library", Callback = function()
        local i = addTrack(MU.addName, MU.addId)
        if i then refreshLib() notify("Music", "Added: " .. Library[i].name) end
    end })
    LibTab:CreateButton({ Name = "Add & Play", Callback = function()
        local i = addTrack(MU.addName, MU.addId)
        if i then refreshLib() playLibrary(i) end
    end })
    LibTab:CreateButton({ Name = "Add Current Track to Library", Callback = function()
        if not MU.current then return notify("Music", "Kuch play nahi ho raha") end
        local i = addTrack(MU.current.name, MU.current.id)
        if i then refreshLib() notify("Music", "Added: " .. Library[i].name) end
    end })

    LibTab:CreateSection("Bulk Import / Export")
    LibTab:CreateInput({ Name = "Bulk Import", PlaceholderText = "Naam:ID, Naam2:ID2  ya  ID1, ID2", RemoveTextAfterFocusLost = true,
        Callback = function(text)
            if not text or text == "" then return end
            local count = 0
            for entry in text:gmatch("[^,;\n]+") do
                entry = entry:match("^%s*(.-)%s*$")
                local name, id = entry:match("^(.-)%s*:%s*(%d+)$")
                if not id then
                    id = entry:match("^(%d+)$")
                    name = id and ("Track " .. id) or nil
                end
                if id then
                    table.insert(Library, { name = name ~= "" and name or ("Track " .. id), id = tonumber(id) })
                    count += 1
                end
            end
            refreshLib()
            notify("Music", count .. " tracks import hue")
        end })
    LibTab:CreateButton({ Name = "Copy Library (Naam:ID format)", Callback = function()
        local parts = {}
        for _, e in ipairs(Library) do parts[#parts + 1] = e.name:gsub("[,:;]", " ") .. ":" .. e.id end
        if #parts == 0 then return notify("Music", "Library khali hai") end
        notify("Music", copyText(table.concat(parts, ", ")) and "Library copy ho gayi" or "Executor me clipboard support nahi hai")
    end })
    LibTab:CreateButton({ Name = "Save Library (file me)", Callback = function()
        saveLib()
        notify("Music", writefile and "Saved: " .. LIB_FILE or "Executor me file support nahi hai")
    end })
    LibTab:CreateButton({ Name = "Reload Library (file se)", Callback = function()
        loadLib()
        LibDropdown:Refresh(libOptions())
        notify("Music", #Library .. " tracks loaded")
    end })

    LibTab:CreateSection("History (last 15)")
    HistDropdown = LibTab:CreateDropdown({ Name = "Recently Played", Options = histOptions(), CurrentOption = {},
        MultipleOptions = false,
        Callback = function(o)
            local s = type(o) == "table" and o[1] or o
            MU.histIdx = tonumber(tostring(s):match("^(%d+)%."))
        end })
    LibTab:CreateButton({ Name = "Play from History", Callback = function()
        local e = MU.histIdx and History[MU.histIdx]
        if not e then return notify("Music", "Pehle history se select karo") end
        playId(e.id, e.name)
    end })

    LibTab:CreateSection("Sleep Timer")
    LibTab:CreateInput({ Name = "Music band karo (minutes me)", PlaceholderText = "e.g. 30", RemoveTextAfterFocusLost = true,
        Callback = function(t)
            local mins = tonumber(t)
            if not mins or mins <= 0 then return notify("Music", "Sahi minutes daalo") end
            MU.sleepToken += 1
            local my = MU.sleepToken
            notify("Music", "Music " .. mins .. " min baad band hoga")
            task.delay(mins * 60, function()
                if MU.sleepToken == my then
                    sound:Stop()
                    NowLabel:Set("Sleep timer: stopped")
                end
            end)
        end })

    -- ---------- Main loop ----------
    local lastLabel = 0
    RunService.Heartbeat:Connect(function()
        local now = tick()

        if now - lastLabel > 0.5 then
            lastLabel = now
            TimeLabel:Set(fmt(sound.TimePosition) .. " / " .. fmt(sound.TimeLength) .. (sound.IsPlaying and "   ▶" or "   ⏸"))
        end

        if MU.mode == "8D Orbit" and orbit and orbit.Parent then
            local cam = Workspace.CurrentCamera
            if cam then
                local a = now * 1.2
                orbit.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.cos(a) * 6, math.sin(a * 0.5) * 1.5, math.sin(a) * 6))
            end
        end

        local loud = sound.IsPlaying and sound.PlaybackLoudness or 0
        local root = fxRoot()

        if viz.light and root then
            if not vizLight then
                vizLight = Instance.new("PointLight")
                vizLight.Shadows = false
                vizLight.Parent = root
            end
            vizLight.Brightness = math.clamp(loud / 90, 0, 6)
            vizLight.Range = 10 + math.clamp(loud / 40, 0, 20)
            vizLight.Color = Color3.fromHSV((now * 0.2) % 1, 0.8, 1)
        end

        if viz.bloom then
            Bloom.Enabled = true
            Bloom.Intensity = math.clamp(0.4 + loud / 220, 0, 3)
        end

        if viz.parts and root then
            if not vizEmitter then
                vizEmitter = Instance.new("ParticleEmitter")
                vizEmitter.Texture = TEX.sparkle
                vizEmitter.Rate = 0
                vizEmitter.Lifetime = NumberRange.new(0.6, 1.2)
                vizEmitter.Speed = NumberRange.new(6, 12)
                vizEmitter.Size = NumberSequence.new(0.6, 0)
                vizEmitter.LightEmission = 1
                vizEmitter.SpreadAngle = Vector2.new(180, 180)
                vizEmitter.Color = RAINBOW
                vizEmitter.Parent = root
            end
            vizEmitter.Rate = math.clamp(loud * 0.4, 0, 200)
        end
    end)

    LP.CharacterAdded:Connect(function()
        if MU.mode == "From Character (3D)" then
            task.wait(1.5)
            applyMode()
        end
        vizLight, vizEmitter = nil, nil
    end)
end

-- ===== PLAYER TELEPORT & LOCATIONS =====
do
    local UIS = game:GetService("UserInputService")
    local TPTab = Window:CreateTab("Teleport", "map-pin")

    local TP = { smooth = false, ctrlClick = false, tapTP = false, spectate = false,
        targetName = nil, locIdx = nil, patrol = false, patrolDelay = 6, patrolToken = 0,
        newName = "" }
    local Locations = {}
    local LOC_FILE = "RuboHub/locations.json"
    local HttpService = game:GetService("HttpService")

    local function saveLocs()
        pcall(function()
            if writefile then
                if makefolder and isfolder and not isfolder("RuboHub") then makefolder("RuboHub") end
                writefile(LOC_FILE, HttpService:JSONEncode(Locations))
            end
        end)
    end
    pcall(function()
        if isfile and readfile and isfile(LOC_FILE) then
            local d = HttpService:JSONDecode(readfile(LOC_FILE))
            for _, e in ipairs(d) do
                if type(e) == "table" and tonumber(e.x) and tonumber(e.y) and tonumber(e.z) then
                    Locations[#Locations + 1] = { name = tostring(e.name), x = e.x, y = e.y, z = e.z }
                end
            end
        end
    end)

    local function teleportTo(cf)
        local char, root = LP.Character, fxRoot()
        if not (char and root) then return false end
        local veh = currentVehicle()
        local hum = getHum(char)
        if veh and hum and hum.SeatPart then
            local piv = veh:GetPivot()
            veh:PivotTo(CFrame.new(cf.Position + Vector3.new(0, 4, 0)) * (piv - piv.Position))
            return true
        end
        if TP.smooth then
            TweenService:Create(root, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { CFrame = cf }):Play()
        else
            char:PivotTo(cf)
        end
        return true
    end

    local function locOptions()
        local o = {}
        for i, l in ipairs(Locations) do o[i] = i .. ". " .. l.name end
        if #o == 0 then o = { "(koi saved location nahi)" } end
        return o
    end

    -- ---------- Player teleport ----------
    TPTab:CreateSection("Player Teleport")
    local TPPlayers = TPTab:CreateDropdown({ Name = "Select Player", Options = otherPlayerNames(), CurrentOption = {},
        MultipleOptions = false,
        Callback = function(o) TP.targetName = type(o) == "table" and o[1] or o end })
    TPTab:CreateButton({ Name = "Refresh Player List", Callback = function()
        TPPlayers:Refresh(otherPlayerNames())
    end })

    local function targetPlayer()
        local p = TP.targetName and Players:FindFirstChild(TP.targetName)
        if not p or p == LP then
            notify("Teleport", "Pehle dropdown se player select karo")
            return nil
        end
        return p
    end

    TPTab:CreateButton({ Name = "Teleport to Player", Callback = function()
        local p = targetPlayer(); if not p then return end
        local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not r then return notify("Teleport", "Us player ka character load nahi hua") end
        teleportTo(r.CFrame * CFrame.new(0, 2, 5))
        notify("Teleport", "Teleported: " .. p.Name)
    end })

    TPTab:CreateToggle({ Name = "Spectate Player", CurrentValue = false,
        Callback = function(v)
            TP.spectate = v
            if v then
                local p = targetPlayer()
                local h = p and getHum(p.Character)
                if h then Workspace.CurrentCamera.CameraSubject = h else TP.spectate = false end
            else
                local h = getHum(LP.Character)
                if h then Workspace.CurrentCamera.CameraSubject = h end
            end
        end })

    -- ---------- Saved locations ----------
    TPTab:CreateSection("Saved Locations")
    local LocDropdown = TPTab:CreateDropdown({ Name = "My Locations", Options = locOptions(), CurrentOption = {},
        MultipleOptions = false,
        Callback = function(o)
            local s = type(o) == "table" and o[1] or o
            TP.locIdx = tonumber(tostring(s):match("^(%d+)%."))
        end })
    TPTab:CreateInput({ Name = "Location Name", PlaceholderText = "e.g. Meri Ghar", RemoveTextAfterFocusLost = false,
        Callback = function(t) TP.newName = t or "" end })
    TPTab:CreateButton({ Name = "Save Current Position", Callback = function()
        local r = fxRoot()
        if not r then return notify("Teleport", "Character load nahi hua") end
        local p = r.Position
        local name = TP.newName ~= "" and TP.newName or ("Spot " .. (#Locations + 1))
        table.insert(Locations, { name = name, x = p.X, y = p.Y, z = p.Z })
        LocDropdown:Refresh(locOptions())
        saveLocs()
        notify("Teleport", "Saved: " .. name)
    end })
    TPTab:CreateButton({ Name = "Teleport to Selected", Callback = function()
        local l = TP.locIdx and Locations[TP.locIdx]
        if not l then return notify("Teleport", "Pehle location select karo") end
        teleportTo(CFrame.new(l.x, l.y + 3, l.z))
    end })
    TPTab:CreateButton({ Name = "Delete Selected", Callback = function()
        local i = TP.locIdx
        if not (i and Locations[i]) then return notify("Teleport", "Pehle location select karo") end
        table.remove(Locations, i)
        TP.locIdx = nil
        LocDropdown:Refresh(locOptions())
        saveLocs()
    end })
    TPTab:CreateButton({ Name = "Copy My Position (x, y, z)", Callback = function()
        local r = fxRoot()
        if not r then return end
        local p = r.Position
        local s = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        local ok = (setclipboard and (setclipboard(s) or true)) or (toclipboard and (toclipboard(s) or true))
        notify("Teleport", ok and ("Copied: " .. s) or s)
    end })
    TPTab:CreateInput({ Name = "Teleport to Coordinates", PlaceholderText = "x, y, z", RemoveTextAfterFocusLost = false,
        Callback = function(t)
            local n = {}
            for num in tostring(t):gmatch("(-?%d+%.?%d*)") do n[#n + 1] = tonumber(num) end
            if #n < 3 then return notify("Teleport", "Format: x, y, z") end
            teleportTo(CFrame.new(n[1], n[2] + 3, n[3]))
        end })

    -- ---------- Click / Tap TP ----------
    TPTab:CreateSection("Click Teleport")
    TPTab:CreateToggle({ Name = "Ctrl + Click TP (PC)", CurrentValue = false,
        Callback = function(v) TP.ctrlClick = v end })
    TPTab:CreateToggle({ Name = "Tap TP (mobile - har tap pe teleport)", CurrentValue = false,
        Callback = function(v) TP.tapTP = v end })
    TPTab:CreateToggle({ Name = "Smooth Teleport", CurrentValue = false,
        Callback = function(v) TP.smooth = v end })

    UIS.InputBegan:Connect(function(input, processed)
        local t = input.UserInputType
        local isClick = TP.ctrlClick and t == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        local isTap = TP.tapTP and t == Enum.UserInputType.Touch
        if not (isClick or isTap) then return end
        if isTap and processed then return end
        local cam = Workspace.CurrentCamera
        local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LP.Character }
        local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if hit then teleportTo(CFrame.new(hit.Position + Vector3.new(0, 3, 0))) end
    end)

    -- ---------- Patrol loop (apni saved locations ke beech) ----------
    TPTab:CreateSection("Location Loop (apni saved spots ke beech)")
    TPTab:CreateSlider({ Name = "Loop Delay", Range = { 1, 30 }, Increment = 1, CurrentValue = 6, Suffix = " sec",
        Callback = function(v) TP.patrolDelay = v end })
    TPTab:CreateToggle({ Name = "Loop Through Saved Locations", CurrentValue = false,
        Callback = function(v)
            TP.patrol = v
            TP.patrolToken += 1
            if not v then return end
            if #Locations < 2 then
                TP.patrol = false
                return notify("Teleport", "Loop ke liye kam se kam 2 locations save karo")
            end
            local my = TP.patrolToken
            task.spawn(function()
                while TP.patrol and TP.patrolToken == my do
                    for _, l in ipairs(Locations) do
                        if not (TP.patrol and TP.patrolToken == my) then break end
                        teleportTo(CFrame.new(l.x, l.y + 3, l.z))
                        task.wait(TP.patrolDelay)
                    end
                end
            end)
        end })

    -- spectate safety
    RunService.Heartbeat:Connect(function()
        if TP.spectate then
            local p = TP.targetName and Players:FindFirstChild(TP.targetName)
            local h = p and getHum(p.Character)
            if h then
                Workspace.CurrentCamera.CameraSubject = h
            else
                TP.spectate = false
                local mine = getHum(LP.Character)
                if mine then Workspace.CurrentCamera.CameraSubject = mine end
            end
        end
    end)

    Players.PlayerAdded:Connect(function() TPPlayers:Refresh(otherPlayerNames()) end)
    Players.PlayerRemoving:Connect(function() task.defer(function() TPPlayers:Refresh(otherPlayerNames()) end) end)
end

-- ===== VEHICLE SPEED & TURBO SYSTEM =====
do
    local UIS = game:GetService("UserInputService")
    local VSTab = Window:CreateTab("Vehicle Speed", "gauge")

    local VS = {
        mult = false, multVal = 2,
        alwaysTurbo = false, keyTurbo = true, accel = 90, maxSpeed = 180, reverseDir = false,
        keyHeld = false, btnHeld = false,
        flames = false, fovKick = false,
    }
    local lastSeat, seatOrig, emitter, baseFov
    local speedLabel

    local function restoreSeat()
        if seatOrig and seatOrig.seat.Parent then
            seatOrig.seat.MaxSpeed = seatOrig.MaxSpeed
            seatOrig.seat.Torque = seatOrig.Torque
        end
        seatOrig = nil
    end
    local function killEmitter()
        if emitter then emitter:Destroy() emitter = nil end
    end

    VSTab:CreateSection("Speed")
    speedLabel = VSTab:CreateLabel("Gaadi me baitho")
    VSTab:CreateToggle({ Name = "Speed Multiplier (VehicleSeat)", CurrentValue = false, Flag = "VSMult",
        Callback = function(v)
            VS.mult = v
            if not v then restoreSeat() end
        end })
    VSTab:CreateSlider({ Name = "Multiplier", Range = { 1, 6 }, Increment = 0.25, CurrentValue = 2, Suffix = "x", Flag = "VSMultVal",
        Callback = function(v) VS.multVal = v end })

    VSTab:CreateSection("Turbo")
    VSTab:CreateToggle({ Name = "Turbo Key (Left Shift)", CurrentValue = true, Flag = "VSKey",
        Callback = function(v) VS.keyTurbo = v end })
    VSTab:CreateToggle({ Name = "Always Turbo (jab gas dabao)", CurrentValue = false, Flag = "VSAlways",
        Callback = function(v) VS.alwaysTurbo = v end })
    VSTab:CreateSlider({ Name = "Turbo Power", Range = { 20, 300 }, Increment = 5, CurrentValue = 90, Flag = "VSAccel",
        Callback = function(v) VS.accel = v end })
    VSTab:CreateSlider({ Name = "Turbo Max Speed", Range = { 50, 500 }, Increment = 10, CurrentValue = 180, Suffix = " studs/s", Flag = "VSMax",
        Callback = function(v) VS.maxSpeed = v end })
    VSTab:CreateToggle({ Name = "Direction Ulta Karo (agar turbo peeche jaye)", CurrentValue = false, Flag = "VSRev",
        Callback = function(v) VS.reverseDir = v end })

    VSTab:CreateSection("Visuals")
    VSTab:CreateToggle({ Name = "Turbo Flames", CurrentValue = false, Flag = "VSFlames",
        Callback = function(v) VS.flames = v if not v then killEmitter() end end })
    VSTab:CreateToggle({ Name = "FOV Kick (speed ka feel)", CurrentValue = false, Flag = "VSFov",
        Callback = function(v)
            VS.fovKick = v
            if not v and baseFov then Workspace.CurrentCamera.FieldOfView = baseFov end
        end })

    VSTab:CreateSection("Tools")
    local function getSeat()
        local hum = getHum(LP.Character)
        return hum and hum.SeatPart
    end
    VSTab:CreateButton({ Name = "Emergency Brake", Callback = function()
        local seat = getSeat()
        if not seat then return notify("Vehicle", "Pehle gaadi me baitho") end
        local part = seat.AssemblyRootPart or seat
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end })
    VSTab:CreateButton({ Name = "Flip Vehicle Upright", Callback = function()
        local seat, veh = getSeat(), currentVehicle()
        if not (seat and veh) then return notify("Vehicle", "Pehle gaadi me baitho") end
        local look = seat.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        local rel = seat.CFrame:ToObjectSpace(veh:GetPivot())
        local desired = CFrame.new(seat.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, yaw, 0)
        veh:PivotTo(desired * rel)
        local part = seat.AssemblyRootPart or seat
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end })

    -- ---------- On-screen turbo button (mobile) ----------
    local btnGui
    VSTab:CreateToggle({ Name = "On-screen Turbo Button (mobile)", CurrentValue = false, Flag = "VSBtn",
        Callback = function(v)
            if btnGui then btnGui:Destroy() btnGui = nil end
            VS.btnHeld = false
            if not v then return end
            local g = Instance.new("ScreenGui")
            g.Name = "RuboTurbo"
            g.ResetOnSpawn = false
            local okP = pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
            if not okP or not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 96, 0, 96)
            b.Position = UDim2.new(1, -130, 1, -240)
            b.BackgroundColor3 = Color3.fromRGB(10, 40, 110)
            b.Text = "TURBO"
            b.TextColor3 = Color3.fromRGB(140, 230, 255)
            b.Font = Enum.Font.GothamBlack
            b.TextSize = 20
            b.AutoButtonColor = false
            b.Parent = g
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = b
            local s = Instance.new("UIStroke")
            s.Color, s.Thickness = Color3.fromRGB(80, 210, 255), 3
            s.Parent = b
            b.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    VS.btnHeld = true
                end
            end)
            b.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    VS.btnHeld = false
                end
            end)
            btnGui = g
        end })

    UIS.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.LeftShift and VS.keyTurbo and not processed then VS.keyHeld = true end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift then VS.keyHeld = false end
    end)

    -- ---------- Main loop ----------
    local lastLabel = 0
    RunService.Heartbeat:Connect(function(dt)
        local seat = getSeat()

        if seat ~= lastSeat then
            restoreSeat()
            killEmitter()
            lastSeat = seat
        end

        local cam = Workspace.CurrentCamera
        if not baseFov and cam then baseFov = cam.FieldOfView end

        if not seat then
            if VS.fovKick and cam and baseFov then
                cam.FieldOfView = cam.FieldOfView + (baseFov - cam.FieldOfView) * 0.15
            end
            if tick() - lastLabel > 0.3 then
                lastLabel = tick()
                speedLabel:Set("Gaadi me baitho")
            end
            return
        end

        local part = seat.AssemblyRootPart or seat
        local isVSeat = seat:IsA("VehicleSeat")

        if VS.mult and isVSeat then
            if not seatOrig then
                seatOrig = { seat = seat, MaxSpeed = seat.MaxSpeed, Torque = seat.Torque }
            end
            seat.MaxSpeed = seatOrig.MaxSpeed * VS.multVal
            seat.Torque = seatOrig.Torque * VS.multVal
        elseif seatOrig then
            restoreSeat()
        end

        local throttle = isVSeat and seat.ThrottleFloat or 0
        local pressed = VS.keyHeld or VS.btnHeld
        local active = pressed or (VS.alwaysTurbo and throttle ~= 0)

        if active then
            local sign = (throttle < 0) and -1 or 1
            if VS.reverseDir then sign = -sign end
            local look = seat.CFrame.LookVector
            local dir = Vector3.new(look.X, 0, look.Z)
            if dir.Magnitude > 0.01 then
                dir = dir.Unit * sign
                local vel = part.AssemblyLinearVelocity
                local flat = Vector3.new(vel.X, 0, vel.Z)
                if flat.Magnitude < VS.maxSpeed then
                    part.AssemblyLinearVelocity = vel + dir * VS.accel * dt
                end
            end
        end

        if VS.flames then
            if not emitter then
                emitter = Instance.new("ParticleEmitter")
                emitter.Texture = TEX.fire
                emitter.Rate = 0
                emitter.Lifetime = NumberRange.new(0.3, 0.6)
                emitter.Speed = NumberRange.new(8, 16)
                emitter.Size = NumberSequence.new(2.4, 0.2)
                emitter.LightEmission = 1
                emitter.Color = ColorSequence.new(rgb(120, 220, 255), rgb(0, 80, 255))
                emitter.EmissionDirection = Enum.NormalId.Back
                emitter.SpreadAngle = Vector2.new(12, 12)
                emitter.Parent = seat
            end
            emitter.Rate = active and 140 or 0
        end

        if VS.fovKick and cam and baseFov then
            local target = active and (baseFov + 18) or baseFov
            cam.FieldOfView = cam.FieldOfView + (target - cam.FieldOfView) * 0.12
        end

        if tick() - lastLabel > 0.2 then
            lastLabel = tick()
            local sp = part.AssemblyLinearVelocity.Magnitude
            speedLabel:Set(string.format("Speed: %d studs/s  (~%d km/h)%s", sp, sp * 1.0, active and "   TURBO" or ""))
        end
    end)
end

-- ===== PROP RGB & ORBIT SYSTEM =====
-- Sirf tumhare apne props pe kaam karta hai: jo tool tumne pakda hai, aur jo loose props
-- tumhare network control me hain (isnetworkowner). Dusre players ke props/gaadi/character ko touch nahi karta.
do
    local PropTab = Window:CreateTab("Props", "box")
    local hasOwner = typeof(isnetworkowner) == "function"

    local PR = {
        -- RGB
        rgbOn = false, mode = "Rainbow", custom = Color3.fromRGB(0, 200, 255),
        speed = 1, flow = true, neon = false, glow = false, source = "Both",
        -- Orbit
        orbitOn = false, pattern = "Circle", radius = 12, orbitSpeed = 1, height = 3,
        tilt = 0, spin = true, reverse = false, bob = true, maxProps = 12, range = 60,
    }

    local patternList = { "Circle", "Spiral", "Sphere", "Galaxy", "Wave", "Figure 8" }
    local sourceList = { "Held Tools", "Owned Props", "Both" }

    local members = {}      -- { {root = BasePart, parts = {BasePart}} } orbit/RGB targets (owned props)
    local heldParts = {}    -- parts of tools in hand (RGB only)
    local colorSaved = {}   -- [part] = { Color, Material }
    local orbitSaved = {}   -- [part] = CanCollide
    local glowLights = {}   -- [root] = PointLight
    local countLabel
    local lastScan = 0

    local function charRoot()
        local c = LP.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    local function inCharacter(part)
        local m = part:FindFirstAncestorOfClass("Model")
        while m do
            if m:FindFirstChildOfClass("Humanoid") then return true end
            local p = m.Parent
            m = p and p:FindFirstAncestorOfClass("Model") or nil
        end
        return false
    end

    local function seatAssembly()
        local c = LP.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        return seat and seat.AssemblyRootPart or nil
    end

    -- ---------- restore helpers ----------
    local function restoreColor(p)
        local s = colorSaved[p]
        if s then
            if p.Parent then p.Color, p.Material = s[1], s[2] end
            colorSaved[p] = nil
        end
    end

    local function restoreAllColors()
        for p in pairs(colorSaved) do restoreColor(p) end
    end

    local function restoreCollide(p)
        local s = orbitSaved[p]
        if s ~= nil then
            if p.Parent then p.CanCollide = s end
            orbitSaved[p] = nil
        end
    end

    local function restoreAllCollide()
        for p in pairs(orbitSaved) do restoreCollide(p) end
    end

    local function dropGlow(root)
        local l = glowLights[root]
        if l then l:Destroy() glowLights[root] = nil end
    end

    local function dropAllGlow()
        for r in pairs(glowLights) do dropGlow(r) end
    end

    local function releaseMember(m)
        for _, p in ipairs(m.parts) do
            restoreColor(p)
            restoreCollide(p)
        end
        dropGlow(m.root)
    end

    local function releaseAll()
        for _, m in ipairs(members) do releaseMember(m) end
        members = {}
        restoreAllColors()
        restoreAllCollide()
        dropAllGlow()
        heldParts = {}
    end

    -- ---------- scanning ----------
    local function memberIndex(root)
        for i, m in ipairs(members) do
            if m.root == root then return i end
        end
    end

    local function scanProps()
        local char = LP.Character
        local root = charRoot()
        if not (char and root) then return end

        -- held tools
        heldParts = {}
        if PR.rgbOn and (PR.source == "Held Tools" or PR.source == "Both") then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then
                    for _, d in ipairs(t:GetDescendants()) do
                        if d:IsA("BasePart") and d.Transparency < 0.95 then
                            heldParts[#heldParts + 1] = d
                        end
                    end
                end
            end
        end

        -- owned loose props
        local wantOwned = hasOwner and (PR.orbitOn or (PR.rgbOn and PR.source ~= "Held Tools"))
        if not wantOwned then
            for i = #members, 1, -1 do
                releaseMember(members[i])
                table.remove(members, i)
            end
            return
        end

        -- purane / door ho gaye props hatao
        local seatRoot = seatAssembly()
        for i = #members, 1, -1 do
            local m = members[i]
            local bad = (not m.root.Parent) or m.root.Anchored
                or (m.root.Position - root.Position).Magnitude > PR.range * 1.6
                or m.root.AssemblyRootPart == seatRoot or i > PR.maxProps
            if not bad then
                local ok, owner = pcall(isnetworkowner, m.root)
                bad = not (ok and owner)
            end
            if bad then
                releaseMember(m)
                table.remove(members, i)
            end
        end

        if #members >= PR.maxProps then return end

        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        local found = Workspace:GetPartBoundsInRadius(root.Position, PR.range, params)

        local cands = {}
        for _, p in ipairs(found) do
            if not p.Anchored and p.Size.Magnitude <= 25 and p.Transparency < 0.95 then
                local r = p.AssemblyRootPart or p
                if r ~= seatRoot and not r.Anchored and not memberIndex(r) and not inCharacter(r) then
                    local ok, owner = pcall(isnetworkowner, r)
                    if ok and owner then
                        local dup = false
                        for _, c in ipairs(cands) do
                            if c.root == r then dup = true break end
                        end
                        if not dup then
                            cands[#cands + 1] = { root = r, dist = (r.Position - root.Position).Magnitude }
                        end
                    end
                end
            end
        end
        table.sort(cands, function(a, b) return a.dist < b.dist end)

        for _, c in ipairs(cands) do
            if #members >= PR.maxProps then break end
            local parts = {}
            local okC, connected = pcall(function() return c.root:GetConnectedParts(true) end)
            if okC then
                for _, cp in ipairs(connected) do
                    if #parts >= 30 then break end
                    if cp.Transparency < 0.95 then parts[#parts + 1] = cp end
                end
            end
            if #parts == 0 then parts[1] = c.root end
            members[#members + 1] = { root = c.root, parts = parts }
        end
    end

    -- ---------- orbit pattern ----------
    local GOLDEN = math.pi * (3 - math.sqrt(5))

    local function patternOffset(i, n, t)
        local R, H = PR.radius, PR.height
        local dir = PR.reverse and -1 or 1
        local a = t * dir + (i / n) * math.pi * 2
        local pat = PR.pattern

        if pat == "Spiral" then
            local k = (i - 1) / math.max(n - 1, 1)
            local r = R * (0.35 + 0.65 * k)
            return Vector3.new(math.cos(a) * r, H + k * R * 0.5, math.sin(a) * r)
        elseif pat == "Sphere" then
            local y = 1 - 2 * ((i - 0.5) / n)
            local r = math.sqrt(math.max(0, 1 - y * y))
            local phi = i * GOLDEN + t * dir
            return Vector3.new(math.cos(phi) * r * R, H + y * R, math.sin(phi) * r * R)
        elseif pat == "Galaxy" then
            local ring = (i - 1) % 3
            local r = R * (0.45 + 0.28 * ring)
            local ang = t * dir * (1.4 - ring * 0.4) + (i / n) * math.pi * 2
            return Vector3.new(math.cos(ang) * r, H + (ring - 1) * 1.2, math.sin(ang) * r)
        elseif pat == "Wave" then
            return Vector3.new(math.cos(a) * R, H + math.sin(a * 3 + t * 2) * 1.8, math.sin(a) * R)
        elseif pat == "Figure 8" then
            return Vector3.new(math.sin(a) * R, H, math.sin(a) * math.cos(a) * R * 1.6)
        end

        -- Circle
        local y = PR.bob and math.sin(t * 2 + i) * 0.6 or 0
        return Vector3.new(math.cos(a) * R, H + y, math.sin(a) * R)
    end

    local function orbitStep(now)
        local root = charRoot()
        if not root then return end
        local n = #members
        if n == 0 then return end
        local t = now * PR.orbitSpeed
        local center = root.Position
        local tiltCF = CFrame.Angles(math.rad(PR.tilt), 0, 0)

        for i, m in ipairs(members) do
            local r = m.root
            if r.Parent then
                for _, p in ipairs(m.parts) do
                    if p.Parent and orbitSaved[p] == nil then
                        orbitSaved[p] = p.CanCollide
                        p.CanCollide = false
                    end
                end
                local off = tiltCF * patternOffset(i, n, t)
                local pos = center + off
                local target
                if PR.spin then
                    target = CFrame.new(pos) * CFrame.Angles(now * 2 + i, now * 3, 0)
                else
                    target = CFrame.lookAt(pos, center)
                end
                r.CFrame = r.CFrame:Lerp(target, 0.35)
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    -- ---------- RGB ----------
    local function propColor(t)
        if PR.mode == "Custom Color" then return PR.custom end
        return ColorFns[PR.mode](t)
    end

    local function paintPart(p, t, phaseSrc)
        if not p.Parent then return end
        if not colorSaved[p] then colorSaved[p] = { p.Color, p.Material } end
        if PR.neon then p.Material = Enum.Material.Neon
        elseif p.Material == Enum.Material.Neon and colorSaved[p][2] ~= Enum.Material.Neon then
            p.Material = colorSaved[p][2]
        end
        local phase = PR.flow and (phaseSrc.X + phaseSrc.Z) * 0.05 or 0
        p.Color = propColor(t + phase)
    end

    local function rgbStep(now)
        local t = now * PR.speed
        local live = {}

        for _, p in ipairs(heldParts) do
            if p.Parent then
                live[p] = true
                paintPart(p, t, p.Position)
            end
        end

        if PR.source ~= "Held Tools" then
            for _, m in ipairs(members) do
                for _, p in ipairs(m.parts) do
                    if p.Parent then
                        live[p] = true
                        paintPart(p, t, p.Position)
                    end
                end
                if PR.glow then
                    local l = glowLights[m.root]
                    if not l then
                        l = Instance.new("PointLight")
                        l.Range, l.Brightness, l.Shadows = 10, 3, false
                        l.Parent = m.root
                        glowLights[m.root] = l
                    end
                    l.Color = propColor(t)
                else
                    dropGlow(m.root)
                end
            end
        end

        -- jo ab list me nahi (drop ho gaye), unka color wapas
        for p in pairs(colorSaved) do
            if not live[p] then restoreColor(p) end
        end
    end

    -- ---------- main loop ----------
    RunService.Heartbeat:Connect(function()
        local anyOn = PR.rgbOn or PR.orbitOn
        local now = tick()

        if not anyOn then
            if next(colorSaved) or next(orbitSaved) or #members > 0 then releaseAll() end
            return
        end

        if now - lastScan > 0.5 then
            lastScan = now
            scanProps()
            if countLabel then
                countLabel:Set(string.format("Props controlled: %d  |  Held parts: %d", #members, #heldParts))
            end
        end

        if PR.orbitOn then
            orbitStep(now)
        else
            restoreAllCollide()
        end

        if PR.rgbOn then
            rgbStep(now)
        else
            restoreAllColors()
            dropAllGlow()
        end
    end)

    LP.CharacterAdded:Connect(function()
        members, heldParts = {}, {}
        colorSaved, orbitSaved, glowLights = {}, {}, {}
    end)

    -- ---------- UI ----------
    PropTab:CreateSection("Status")
    countLabel = PropTab:CreateLabel(hasOwner and "Props controlled: 0  |  Held parts: 0"
        or "Executor me isnetworkowner nahi hai: sirf Held Tools RGB chalega")

    PropTab:CreateSection("Prop RGB")
    PropTab:CreateToggle({ Name = "Prop RGB", CurrentValue = false, Flag = "PropRGB",
        Callback = function(v)
            PR.rgbOn = v
            lastScan = 0
            if not v then restoreAllColors() dropAllGlow() end
        end })
    PropTab:CreateDropdown({ Name = "RGB Style", Options = { "Rainbow", "Fire", "Ice", "Police", "Neon Pulse", "Gold", "Matrix", "Custom Color" },
        CurrentOption = { "Rainbow" }, MultipleOptions = false, Flag = "PropStyle",
        Callback = function(opt) PR.mode = type(opt) == "table" and opt[1] or opt end })
    PropTab:CreateColorPicker({ Name = "Custom Color", Color = PR.custom, Flag = "PropCustom",
        Callback = function(c) PR.custom = c end })
    PropTab:CreateSlider({ Name = "RGB Speed", Range = { 0.2, 5 }, Increment = 0.1, CurrentValue = 1, Suffix = "x", Flag = "PropRGBSpeed",
        Callback = function(v) PR.speed = v end })
    PropTab:CreateDropdown({ Name = "Which Props", Options = sourceList, CurrentOption = { "Both" }, MultipleOptions = false, Flag = "PropSource",
        Callback = function(opt)
            PR.source = type(opt) == "table" and opt[1] or opt
            lastScan = 0
        end })
    PropTab:CreateToggle({ Name = "Color Flow (wave effect)", CurrentValue = true, Flag = "PropFlow",
        Callback = function(v) PR.flow = v end })
    PropTab:CreateToggle({ Name = "Neon Material", CurrentValue = false, Flag = "PropNeon",
        Callback = function(v) PR.neon = v end })
    PropTab:CreateToggle({ Name = "Glow Light", CurrentValue = false, Flag = "PropGlow",
        Callback = function(v) PR.glow = v if not v then dropAllGlow() end end })

    PropTab:CreateSection("Prop Orbit")
    PropTab:CreateToggle({ Name = "Prop Orbit", CurrentValue = false, Flag = "PropOrbit",
        Callback = function(v)
            if v and not hasOwner then
                Rayfield:Notify({ Title = "Props", Content = "Orbit ke liye executor me isnetworkowner chahiye", Duration = 4 })
            end
            PR.orbitOn = v
            lastScan = 0
            if not v then restoreAllCollide() end
        end })
    PropTab:CreateDropdown({ Name = "Orbit Pattern", Options = patternList, CurrentOption = { "Circle" }, MultipleOptions = false, Flag = "PropPattern",
        Callback = function(opt) PR.pattern = type(opt) == "table" and opt[1] or opt end })
    PropTab:CreateSlider({ Name = "Orbit Radius", Range = { 3, 40 }, Increment = 1, CurrentValue = 12, Suffix = " studs", Flag = "PropRadius",
        Callback = function(v) PR.radius = v end })
    PropTab:CreateSlider({ Name = "Orbit Speed", Range = { 0.2, 6 }, Increment = 0.1, CurrentValue = 1, Suffix = "x", Flag = "PropOrbitSpeed",
        Callback = function(v) PR.orbitSpeed = v end })
    PropTab:CreateSlider({ Name = "Height", Range = { -3, 15 }, Increment = 0.5, CurrentValue = 3, Flag = "PropHeight",
        Callback = function(v) PR.height = v end })
    PropTab:CreateSlider({ Name = "Tilt", Range = { 0, 90 }, Increment = 5, CurrentValue = 0, Suffix = " deg", Flag = "PropTilt",
        Callback = function(v) PR.tilt = v end })
    PropTab:CreateToggle({ Name = "Spin Props", CurrentValue = true, Flag = "PropSpin",
        Callback = function(v) PR.spin = v end })
    PropTab:CreateToggle({ Name = "Reverse Direction", CurrentValue = false, Flag = "PropReverse",
        Callback = function(v) PR.reverse = v end })
    PropTab:CreateToggle({ Name = "Bobbing (Circle)", CurrentValue = true, Flag = "PropBob",
        Callback = function(v) PR.bob = v end })

    PropTab:CreateSection("Limits")
    PropTab:CreateSlider({ Name = "Max Props", Range = { 1, 40 }, Increment = 1, CurrentValue = 12, Flag = "PropMax",
        Callback = function(v) PR.maxProps = v lastScan = 0 end })
    PropTab:CreateSlider({ Name = "Search Range", Range = { 10, 150 }, Increment = 5, CurrentValue = 60, Suffix = " studs", Flag = "PropRange",
        Callback = function(v) PR.range = v lastScan = 0 end })

    PropTab:CreateSection("Tools")
    PropTab:CreateButton({ Name = "Rescan Props", Callback = function() lastScan = 0 end })
    PropTab:CreateButton({ Name = "Release Props (stop + restore)", Callback = function()
        releaseAll()
        lastScan = 0
        if countLabel then countLabel:Set("Props controlled: 0  |  Held parts: 0") end
    end })
end

-- =====================================================================
-- EXTRA SYSTEMS (client-side): Server utils, Fire & Smoke, Signs,
-- Bike/Radio RGB, Vehicle Cam. Har block pcall me hai taaki ek fail
-- ho to baaki hub na ruke.
-- =====================================================================

local function safeBlock(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[RUBO HUB] " .. name .. " failed: " .. tostring(err))
        Rayfield:Notify({ Title = "RUBO HUB", Content = name .. " load nahi hua (console dekho)", Duration = 5 })
    end
end

local function inCharacterModel(inst)
    local m = inst:FindFirstAncestorOfClass("Model")
    while m do
        if m:FindFirstChildOfClass("Humanoid") then return true end
        local p = m.Parent
        m = p and p:FindFirstAncestorOfClass("Model") or nil
    end
    return false
end

-- ===== SERVER TIMER, UPTIME & REJOIN =====
safeBlock("Server Utils", function()
    local TeleportService = game:GetService("TeleportService")
    local Stats = game:GetService("Stats")
    local Tab = Window:CreateTab("Server", "clock")
    local joinedAt = tick()

    local function fmt(s)
        s = math.max(0, math.floor(s))
        return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
    end

    Tab:CreateSection("Live Info")
    local sessionL = Tab:CreateLabel("Session: 00:00:00")
    local uptimeL = Tab:CreateLabel("Server uptime: --")
    local playersL = Tab:CreateLabel("Players: --")
    local netL = Tab:CreateLabel("Ping: --  |  FPS: --")

    local frames, fpsT, fps = 0, tick(), 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - fpsT >= 1 then
            fps = frames / (now - fpsT)
            frames, fpsT = 0, now
        end
    end)

    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc < 0.5 then return end
        acc = 0
        sessionL:Set("Session: " .. fmt(tick() - joinedAt))
        uptimeL:Set("Server uptime: " .. fmt(Workspace.DistributedGameTime))
        playersL:Set(string.format("Players: %d / %d", #Players:GetPlayers(), Players.MaxPlayers))
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        netL:Set(string.format("Ping: %s  |  FPS: %d", ok and (math.floor(ping) .. " ms") or "n/a", fps))
    end)

    Tab:CreateSection("Rejoin")
    Tab:CreateButton({ Name = "Rejoin Same Server", Callback = function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LP)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end
    end })
    Tab:CreateButton({ Name = "Join New Server", Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end })
    Tab:CreateButton({ Name = "Copy Server JobId", Callback = function()
        if typeof(setclipboard) == "function" then
            setclipboard(game.JobId)
            Rayfield:Notify({ Title = "Server", Content = "JobId copy ho gaya", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Server", Content = "setclipboard executor me nahi hai", Duration = 4 })
        end
    end })
end)

-- ===== CUSTOM FIRE & SMOKE =====
safeBlock("Fire & Smoke", function()
    local Tab = Window:CreateTab("Fire & Smoke", "flame")
    local FS = {
        fire = false, smoke = false, rgbOn = false, speed = 1, mode = "Rainbow",
        fireColor = Color3.fromRGB(255, 100, 0), fireColor2 = Color3.fromRGB(255, 220, 50),
        smokeColor = Color3.fromRGB(90, 90, 90),
        size = 7, heat = 9, smokeSize = 6, opacity = 0.5, rise = 4, target = "Body",
    }
    local made = {}

    local function targets()
        local c = LP.Character
        if not c then return {} end
        local out = {}
        if FS.target == "Body" then
            local r = c:FindFirstChild("HumanoidRootPart")
            if r then out[1] = r end
        elseif FS.target == "Head" then
            local h = c:FindFirstChild("Head")
            if h then out[1] = h end
        else
            for _, n in ipairs({ "LeftHand", "RightHand", "LeftFoot", "RightFoot",
                "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
                local p = c:FindFirstChild(n)
                if p then out[#out + 1] = p end
            end
        end
        return out
    end

    local function applyProps()
        local k = (FS.target == "Limbs") and 0.5 or 1
        for _, i in ipairs(made) do
            if i.Parent then
                if i:IsA("Fire") then
                    i.Size = math.clamp(FS.size * k, 2, 30)
                    i.Heat = FS.heat
                    if not FS.rgbOn then
                        i.Color, i.SecondaryColor = FS.fireColor, FS.fireColor2
                    end
                else
                    i.Size = math.clamp(FS.smokeSize * k, 1, 25)
                    i.Opacity = FS.opacity
                    i.RiseVelocity = FS.rise
                    if not FS.rgbOn then i.Color = FS.smokeColor end
                end
            end
        end
    end

    local function clear()
        for _, i in ipairs(made) do i:Destroy() end
        made = {}
    end

    local function rebuild()
        clear()
        if not (FS.fire or FS.smoke) then return end
        for _, p in ipairs(targets()) do
            if FS.fire then
                local f = Instance.new("Fire")
                f.Name = "RuboFire"
                f.Parent = p
                made[#made + 1] = f
            end
            if FS.smoke then
                local s = Instance.new("Smoke")
                s.Name = "RuboSmoke"
                s.Parent = p
                made[#made + 1] = s
            end
        end
        applyProps()
    end

    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        if not FS.rgbOn or #made == 0 then return end
        acc = acc + dt
        if acc < 0.05 then return end
        acc = 0
        local t = tick() * FS.speed
        local c = ColorFns[FS.mode](t)
        local h, s, v = c:ToHSV()
        local c2 = Color3.fromHSV((h + 0.12) % 1, s, v)
        for _, i in ipairs(made) do
            if i.Parent then
                if i:IsA("Fire") then i.Color, i.SecondaryColor = c, c2
                else i.Color = c end
            end
        end
    end)

    LP.CharacterAdded:Connect(function(char)
        made = {}
        char:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.5)
        rebuild()
    end)

    Tab:CreateSection("Toggles")
    Tab:CreateToggle({ Name = "Fire", CurrentValue = false, Flag = "FSFire",
        Callback = function(v) FS.fire = v rebuild() end })
    Tab:CreateToggle({ Name = "Smoke", CurrentValue = false, Flag = "FSSmoke",
        Callback = function(v) FS.smoke = v rebuild() end })
    Tab:CreateDropdown({ Name = "Attach To", Options = { "Body", "Head", "Limbs" }, CurrentOption = { "Body" },
        MultipleOptions = false, Flag = "FSTarget",
        Callback = function(opt) FS.target = type(opt) == "table" and opt[1] or opt rebuild() end })

    Tab:CreateSection("Fire")
    Tab:CreateColorPicker({ Name = "Fire Color", Color = FS.fireColor, Flag = "FSFireC",
        Callback = function(c) FS.fireColor = c applyProps() end })
    Tab:CreateColorPicker({ Name = "Fire Inner Color", Color = FS.fireColor2, Flag = "FSFireC2",
        Callback = function(c) FS.fireColor2 = c applyProps() end })
    Tab:CreateSlider({ Name = "Fire Size", Range = { 2, 30 }, Increment = 1, CurrentValue = 7, Flag = "FSSize",
        Callback = function(v) FS.size = v applyProps() end })
    Tab:CreateSlider({ Name = "Fire Heat", Range = { 0, 25 }, Increment = 1, CurrentValue = 9, Flag = "FSHeat",
        Callback = function(v) FS.heat = v applyProps() end })

    Tab:CreateSection("Smoke")
    Tab:CreateColorPicker({ Name = "Smoke Color", Color = FS.smokeColor, Flag = "FSSmokeC",
        Callback = function(c) FS.smokeColor = c applyProps() end })
    Tab:CreateSlider({ Name = "Smoke Size", Range = { 1, 25 }, Increment = 1, CurrentValue = 6, Flag = "FSSmokeSize",
        Callback = function(v) FS.smokeSize = v applyProps() end })
    Tab:CreateSlider({ Name = "Smoke Opacity", Range = { 0, 1 }, Increment = 0.05, CurrentValue = 0.5, Flag = "FSOpacity",
        Callback = function(v) FS.opacity = v applyProps() end })
    Tab:CreateSlider({ Name = "Rise Speed", Range = { -10, 25 }, Increment = 1, CurrentValue = 4, Flag = "FSRise",
        Callback = function(v) FS.rise = v applyProps() end })

    Tab:CreateSection("RGB")
    Tab:CreateToggle({ Name = "RGB Fire & Smoke", CurrentValue = false, Flag = "FSRGB",
        Callback = function(v) FS.rgbOn = v applyProps() end })
    Tab:CreateDropdown({ Name = "RGB Style", Options = styleList, CurrentOption = { "Rainbow" },
        MultipleOptions = false, Flag = "FSStyle",
        Callback = function(opt) FS.mode = type(opt) == "table" and opt[1] or opt end })
    Tab:CreateSlider({ Name = "RGB Speed", Range = { 0.2, 5 }, Increment = 0.1, CurrentValue = 1, Suffix = "x", Flag = "FSSpeed",
        Callback = function(v) FS.speed = v end })
end)

-- ===== SIGN & HOUSE TEXT (local: sirf tumhe dikhega) =====
safeBlock("Sign Text", function()
    local Tab = Window:CreateTab("Signs & Text", "type")
    local SG = {
        edit = false, text = "RUBO HUB", rgbOn = false, mode = "Rainbow", speed = 1,
        useColor = false, color = Color3.fromRGB(255, 255, 255), dyn = "Static", range = 60,
    }
    local dynList = { "Static", "Typewriter", "Blink", "Scroll", "Rainbow Letters" }
    local targets, saved = {}, {}
    local charCache, charCacheFor = {}, nil

    local function charsOf(str)
        if charCacheFor ~= str then
            charCache, charCacheFor = {}, str
            local ok = pcall(function()
                for _, c in utf8.codes(str) do charCache[#charCache + 1] = utf8.char(c) end
            end)
            if not ok then
                charCache = {}
                for i = 1, #str do charCache[i] = str:sub(i, i) end
            end
        end
        return charCache
    end

    local function esc(c)
        if c == "&" then return "&amp;" elseif c == "<" then return "&lt;" elseif c == ">" then return "&gt;" end
        return c
    end

    local function restore(l)
        local s = saved[l]
        if s then
            if l.Parent then l.Text, l.TextColor3, l.RichText = s[1], s[2], s[3] end
            saved[l] = nil
        end
    end

    local function restoreAll()
        for l in pairs(saved) do restore(l) end
    end

    local function scan()
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        local parts = Workspace:GetPartBoundsInRadius(root.Position, SG.range, params)
        local list, seen = {}, {}
        for _, p in ipairs(parts) do
            if not seen[p] then
                seen[p] = true
                if not inCharacterModel(p) then
                    for _, g in ipairs(p:GetChildren()) do
                        if (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) and g.Name ~= "RuboCustomTag" then
                            for _, d in ipairs(g:GetDescendants()) do
                                if d:IsA("TextLabel") and #list < 80 then list[#list + 1] = d end
                            end
                        end
                    end
                end
            end
        end
        local live = {}
        for _, l in ipairs(list) do live[l] = true end
        for l in pairs(saved) do
            if not live[l] then restore(l) end
        end
        targets = list
    end

    local function composeText(t, i)
        local base = SG.text
        local ch = charsOf(base)
        local n = #ch
        if n == 0 then return base end
        local d = SG.dyn
        if d == "Typewriter" then
            local k = math.floor(t * 8) % (n + 8)
            return table.concat(ch, "", 1, math.min(k, n))
        elseif d == "Blink" then
            return (math.floor(t * 2) % 2 == 0) and base or ""
        elseif d == "Scroll" then
            local off = math.floor(t * 6) % (n + 3)
            local padded = {}
            for j = 1, n + 3 do padded[j] = ch[j] or " " end
            local out = {}
            for j = 1, n do out[j] = padded[((j - 1 + off) % (n + 3)) + 1] end
            return table.concat(out)
        elseif d == "Rainbow Letters" then
            local out = {}
            for j = 1, n do
                local c = ColorFns[SG.mode](t + j * 0.07 + i * 0.03)
                out[j] = string.format('<font color="#%s">%s</font>', c:ToHex(), esc(ch[j]))
            end
            return table.concat(out), true
        end
        return base
    end

    local lastScan, acc = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        local active = SG.edit or SG.rgbOn or SG.useColor
        if not active then
            if next(saved) then restoreAll() end
            return
        end
        acc = acc + dt
        if acc < 0.1 then return end
        acc = 0
        local now = tick()
        if now - lastScan > 0.8 then
            lastScan = now
            scan()
        end
        local t = now * SG.speed
        for i, l in ipairs(targets) do
            if l.Parent then
                if not saved[l] then saved[l] = { l.Text, l.TextColor3, l.RichText } end
                if SG.edit then
                    local txt, rich = composeText(t, i)
                    if rich then l.RichText = true else l.RichText = saved[l][3] end
                    l.Text = txt
                end
                if SG.rgbOn then
                    l.TextColor3 = ColorFns[SG.mode](t + i * 0.1)
                elseif SG.useColor then
                    l.TextColor3 = SG.color
                end
            end
        end
        if not SG.edit then
            for l, s in pairs(saved) do
                if l.Parent then l.Text, l.RichText = s[1], s[3] end
            end
        end
        if not (SG.rgbOn or SG.useColor) then
            for l, s in pairs(saved) do
                if l.Parent then l.TextColor3 = s[2] end
            end
        end
    end)

    Tab:CreateSection("Info")
    Tab:CreateLabel("Ye sirf tumhari screen pe badlega, dusre players ko nahi dikhega")

    Tab:CreateSection("Text")
    Tab:CreateInput({ Name = "Sign Text", PlaceholderText = "RUBO HUB", RemoveTextAfterFocusLost = false, Flag = "SGText",
        Callback = function(t) SG.text = (t ~= "" and t) or "RUBO HUB" end })
    Tab:CreateToggle({ Name = "Edit Nearby Sign / House Text", CurrentValue = false, Flag = "SGEdit",
        Callback = function(v) SG.edit = v lastScan = 0 end })
    Tab:CreateDropdown({ Name = "Text Animation", Options = dynList, CurrentOption = { "Static" },
        MultipleOptions = false, Flag = "SGDyn",
        Callback = function(opt) SG.dyn = type(opt) == "table" and opt[1] or opt end })

    Tab:CreateSection("Color")
    Tab:CreateToggle({ Name = "Text RGB", CurrentValue = false, Flag = "SGRGB",
        Callback = function(v) SG.rgbOn = v lastScan = 0 end })
    Tab:CreateDropdown({ Name = "RGB Style", Options = styleList, CurrentOption = { "Rainbow" },
        MultipleOptions = false, Flag = "SGStyle",
        Callback = function(opt) SG.mode = type(opt) == "table" and opt[1] or opt end })
    Tab:CreateToggle({ Name = "Use Static Color (RGB off ho tab)", CurrentValue = false, Flag = "SGUseColor",
        Callback = function(v) SG.useColor = v lastScan = 0 end })
    Tab:CreateColorPicker({ Name = "Static Color", Color = SG.color, Flag = "SGColor",
        Callback = function(c) SG.color = c end })
    Tab:CreateSlider({ Name = "Animation / RGB Speed", Range = { 0.2, 5 }, Increment = 0.1, CurrentValue = 1, Suffix = "x", Flag = "SGSpeed",
        Callback = function(v) SG.speed = v end })
    Tab:CreateSlider({ Name = "Search Range", Range = { 10, 150 }, Increment = 5, CurrentValue = 60, Suffix = " studs", Flag = "SGRange",
        Callback = function(v) SG.range = v lastScan = 0 end })

    Tab:CreateSection("Tools")
    Tab:CreateButton({ Name = "Restore Original Text", Callback = function()
        SG.edit, SG.rgbOn, SG.useColor = false, false, false
        restoreAll()
    end })
end)

-- ===== BICYCLE & RADIO RGB =====
safeBlock("Bike & Radio RGB", function()
    local Tab = Window:CreateTab("Bike & Radio", "bike")
    local BR = { bike = false, radio = false, anyVeh = false, anyTool = false, mode = "Rainbow", speed = 1, flow = true, neon = false }
    local saved, list = {}, {}
    local bikeKeys = { "bike", "bicycle", "cycle", "bmx", "scooter" }
    local radioKeys = { "radio", "boombox", "boom box", "speaker", "stereo", "music" }

    local function hasKey(name, keys)
        name = name:lower()
        for _, k in ipairs(keys) do
            if name:find(k, 1, true) then return true end
        end
        return false
    end

    local function skippable(p)
        return p.Material == Enum.Material.Glass or p.Transparency >= 0.3
    end

    local function restorePart(p)
        local s = saved[p]
        if s then
            if p.Parent then p.Color, p.Material = s[1], s[2] end
            saved[p] = nil
        end
    end

    local function restoreAll()
        for p in pairs(saved) do restorePart(p) end
        list = {}
    end

    local function collect()
        local out = {}
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if BR.bike and hum and hum.SeatPart then
            local seat = hum.SeatPart
            local ok = BR.anyVeh
            local node = seat
            while node and node ~= Workspace and not ok do
                if hasKey(node.Name, bikeKeys) then ok = true end
                node = node.Parent
            end
            if ok then
                local root = seat.AssemblyRootPart or seat
                local okC, conn = pcall(function() return root:GetConnectedParts(true) end)
                if okC then
                    for _, p in ipairs(conn) do
                        if #out < 250 and not skippable(p) and not inCharacterModel(p) then out[#out + 1] = p end
                    end
                end
            end
        end
        if BR.radio and char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and (BR.anyTool or hasKey(tool.Name, radioKeys)) then
                    for _, d in ipairs(tool:GetDescendants()) do
                        if d:IsA("BasePart") and not skippable(d) and #out < 250 then out[#out + 1] = d end
                    end
                end
            end
        end
        return out
    end

    local lastCollect, acc = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        if not (BR.bike or BR.radio) then
            if next(saved) then restoreAll() end
            return
        end
        acc = acc + dt
        if acc < 0.033 then return end
        acc = 0
        local now = tick()
        if now - lastCollect > 0.4 then
            lastCollect = now
            list = collect()
        end
        local t = now * BR.speed
        local live = {}
        for _, p in ipairs(list) do
            if p.Parent then
                live[p] = true
                if not saved[p] then saved[p] = { p.Color, p.Material } end
                if BR.neon then p.Material = Enum.Material.Neon
                elseif p.Material == Enum.Material.Neon and saved[p][2] ~= Enum.Material.Neon then
                    p.Material = saved[p][2]
                end
                local phase = BR.flow and (p.Position.X + p.Position.Z) * 0.05 or 0
                p.Color = ColorFns[BR.mode](t + phase)
            end
        end
        for p in pairs(saved) do
            if not live[p] then restorePart(p) end
        end
    end)

    Tab:CreateSection("Bicycle")
    Tab:CreateToggle({ Name = "Bicycle RGB (cycle pe baitho)", CurrentValue = false, Flag = "BRBike",
        Callback = function(v) BR.bike = v lastCollect = 0 if not v then restoreAll() end end })
    Tab:CreateToggle({ Name = "Any Vehicle (naam check mat karo)", CurrentValue = false, Flag = "BRAnyVeh",
        Callback = function(v) BR.anyVeh = v lastCollect = 0 end })

    Tab:CreateSection("Radio")
    Tab:CreateToggle({ Name = "Radio RGB (radio haath me pakdo)", CurrentValue = false, Flag = "BRRadio",
        Callback = function(v) BR.radio = v lastCollect = 0 if not v then restoreAll() end end })
    Tab:CreateToggle({ Name = "Any Held Tool (naam check mat karo)", CurrentValue = false, Flag = "BRAnyTool",
        Callback = function(v) BR.anyTool = v lastCollect = 0 end })

    Tab:CreateSection("Style")
    Tab:CreateDropdown({ Name = "RGB Style", Options = styleList, CurrentOption = { "Rainbow" },
        MultipleOptions = false, Flag = "BRStyle",
        Callback = function(opt) BR.mode = type(opt) == "table" and opt[1] or opt end })
    Tab:CreateSlider({ Name = "RGB Speed", Range = { 0.2, 5 }, Increment = 0.1, CurrentValue = 1, Suffix = "x", Flag = "BRSpeed",
        Callback = function(v) BR.speed = v end })
    Tab:CreateToggle({ Name = "Color Flow", CurrentValue = true, Flag = "BRFlow",
        Callback = function(v) BR.flow = v end })
    Tab:CreateToggle({ Name = "Neon Material", CurrentValue = false, Flag = "BRNeon",
        Callback = function(v) BR.neon = v end })
    Tab:CreateButton({ Name = "Restore Colors", Callback = function()
        BR.bike, BR.radio = false, false
        restoreAll()
    end })

    LP.CharacterAdded:Connect(function() saved, list = {}, {} end)
end)

-- ===== VEHICLE CAMERA SPECTATOR (sirf camera, kuch change nahi hota) =====
safeBlock("Vehicle Cam", function()
    local Tab = Window:CreateTab("Vehicle Cam", "video")
    local seatMap, selected, watching = {}, nil, nil
    local dd

    local function stopWatch()
        watching = nil
        local cam = Workspace.CurrentCamera
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if cam and hum then
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
        end
    end

    local function refreshList()
        seatMap = {}
        local origin
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        origin = root and root.Position or Workspace.CurrentCamera.CFrame.Position
        local found = Workspace:GetPartBoundsInRadius(origin, 500)
        local seats, seen = {}, {}
        for _, p in ipairs(found) do
            if p:IsA("VehicleSeat") and not seen[p] then
                seen[p] = true
                seats[#seats + 1] = { seat = p, dist = (p.Position - origin).Magnitude }
            end
        end
        table.sort(seats, function(a, b) return a.dist < b.dist end)
        local opts = {}
        for i, s in ipairs(seats) do
            if i > 25 then break end
            local model = s.seat:FindFirstAncestorOfClass("Model")
            local occ = s.seat.Occupant
            local who = occ and occ.Parent and occ.Parent.Name or "empty"
            local label = string.format("%d) %s | %dm | %s", i, model and model.Name or s.seat.Name, math.floor(s.dist), who)
            opts[#opts + 1] = label
            seatMap[label] = s.seat
        end
        if #opts == 0 then opts = { "(koi gaadi nahi mili)" } end
        selected = nil
        if dd then dd:Refresh(opts) end
    end

    Tab:CreateSection("Spectate Vehicle")
    dd = Tab:CreateDropdown({ Name = "Nearby Vehicles", Options = { "(Refresh dabao)" }, CurrentOption = {},
        MultipleOptions = false, Flag = "VCList",
        Callback = function(opt) selected = type(opt) == "table" and opt[1] or opt end })
    Tab:CreateButton({ Name = "Refresh List", Callback = refreshList })
    Tab:CreateButton({ Name = "Watch Selected Vehicle", Callback = function()
        local seat = selected and seatMap[selected]
        if not (seat and seat.Parent) then
            return Rayfield:Notify({ Title = "Vehicle Cam", Content = "Pehle list refresh karke gaadi chuno", Duration = 3 })
        end
        local cam = Workspace.CurrentCamera
        cam.CameraSubject = seat
        cam.CameraType = Enum.CameraType.Custom
        watching = seat
    end })
    Tab:CreateButton({ Name = "Stop Watching (camera wapas)", Callback = stopWatch })

    RunService.Heartbeat:Connect(function()
        if watching and not watching.Parent then stopWatch() end
    end)
    LP.CharacterAdded:Connect(function() watching = nil end)
end)

Rayfield:Notify({ Title = "RUBO HUB", Content = "Loaded: Shaders, Weather, Avatar, Body, House Unban, Effects, RGB, Music, Teleport, Vehicle, Props, Server, Fire, Signs, Bike/Radio & Vehicle Cam!", Duration = 5 })
Rayfield:LoadConfiguration()
