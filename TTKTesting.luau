local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local GunController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("GunController"))
local SoundController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("SoundController"))
-- Block anti-cheat telemetry
local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
    if tostring(self) == "SessionTelemetry" then
        return
    end
    return oldFireServer(self, ...)
end)

local connections = {}

-- State variables
local state = {
    ESP = false,
    NameESP = false,
    BoxESP = false,
    SkeletonESP = false,
    HealthBar = false,
    SilentAim = false,
    WallCheck = false,
    FOVSize = 600,
    InfiniteAmmo = false,
    RapidFire = false,
    NoRecoilSpread = false,
    NoStamina = false,
    Noclip = false,
    HandChams = false,
    HandChamsMaterial = "Neon",
    HandChamsColor = Color3.fromRGB(255, 0, 0),
    EnableFOV = false,
    CustomFOV = 70,
    EnemyChams = false,
    EnemyChamsColor = Color3.fromRGB(255, 0, 0),
    EnemyChamsFillTransparency = 0.5,
    EnemyChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    EnemyChamsOutlineTransparency = 0,
    HitSound = "None",
    HitSoundVolume = 1,
    CustomViewmodel = false,
    ViewmodelX = 0,
    ViewmodelY = 0,
    ViewmodelZ = 0,
    ThirdPerson = false,
    ThirdPersonDistance = 10,
    AspectRatioEnabled = false,
    AspectRatioX = 1.00,
    AspectRatioY = 1.00,
    RemoveTextures = false,
    RemoveSunGlare = false,
    RemoveCameraShake = false,
    Fullbright = false,
}

-- ==========================
-- DOWNLOAD HITSOUNDS ON STARTUP
-- ==========================
local hitsoundNames = {"bubble", "fatality", "neverlose", "primordial", "skeet", "sparkle"}
local baseHitsoundUrl = "https://raw.githubusercontent.com/AJWOLF321/Kitty/main/Assets/Hitsounds/"

task.spawn(function()
    if not isfolder("KittyAuth") then makefolder("KittyAuth") end
    if not isfolder("KittyAuth/Hitsounds") then makefolder("KittyAuth/Hitsounds") end
    for _, name in ipairs(hitsoundNames) do
        local path = "KittyAuth/Hitsounds/" .. name .. ".wav"
        if not isfile(path) then
            local ok, data = pcall(function() return game:HttpGet(baseHitsoundUrl .. name .. ".wav") end)
            if ok and data then
                writefile(path, data)
            end
        end
    end
end)

local hitSoundCache = {}
local function getHitSoundUrl(soundName)
    if soundName == "None" then return "" end
    if hitSoundCache[soundName] then return hitSoundCache[soundName] end
    local path = "KittyAuth/Hitsounds/" .. soundName .. ".wav"
    if not isfile(path) then return "" end
    local ok, asset = pcall(function() return getcustomasset(path) end)
    if ok and asset then
        hitSoundCache[soundName] = asset
        return asset
    end
    return ""
end

local function getHitsoundList()
    local list = {"None"}
    local added = {}
    if isfolder("KittyAuth/Hitsounds") then
        for _, file in ipairs(listfiles("KittyAuth/Hitsounds")) do
            local name = file:match("([^/\\]+)%.wav$")
            if name then
                table.insert(list, name)
                added[name] = true
            end
        end
    end
    for _, n in ipairs(hitsoundNames) do
        if not added[n] then
            table.insert(list, n)
            added[n] = true
        end
    end
    return list
end

-- ==========================
-- GUI MENU (KittyUI)
-- ==========================
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/AJWOLF321/Kitty/refs/heads/main/Library.luau'))()
Library.ToggleKey = Enum.KeyCode.RightShift

local Window = Library:CreateWindow({
    Title = "KittyAuth - TTK Testing",
    Folder = "Larp",
    AccentColor = Color3.fromRGB(155, 89, 182)
})

local CombatTab = Window:CreateTab("Combat")
local VisualsTab = Window:CreateTab("Visuals")
local LocalTab = Window:CreateTab("Local")
local SettingsTab = Window:CreateTab("Settings")

local function createKittyToggle(tab, name, text, side)
    tab:CreateToggle({
        Name = text,
        Flag = name,
        Default = state[name] or false,
        Side = side or "left",
        Callback = function(Value)
            state[name] = Value
            if name == "NoRecoilSpread" then
                if _G.LarpModifyWeapons then
                    _G.LarpModifyWeapons()
                end
            end
        end
    })
end

-- ==========================
-- COMBAT TAB
-- ==========================
CombatTab:CreateSection("Aimbot Settings", "left")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Side = "left",
    Callback = function(Value)
        state.SilentAim = Value
    end
})

CombatTab:CreateToggle({
    Name = "Rage",
    Flag = "Rage",
    Default = false,
    Side = "left",
    Callback = function(Value)
        state.Rage = Value
    end
})

CombatTab:CreateSlider({
    Name = "FOV Size",
    Min = 0,
    Max = 800,
    Default = 600,
    Rounding = 0,
    Flag = "FOVSize",
    Side = "left",
    Callback = function(Value) state.FOVSize = Value end
})

createKittyToggle(CombatTab, "Wallcheck", "Wall Check", "left")

CombatTab:CreateSection("Gun Mods", "right")
createKittyToggle(CombatTab, "RapidFire", "Rapid Fire", "right")

CombatTab:CreateToggle({
    Name = "No Recoil",
    Flag = "NoRecoil",
    Default = false,
    Side = "right",
    Callback = function(Value)
        state.NoRecoil = Value
    end
})

CombatTab:CreateToggle({
    Name = "No Spread",
    Flag = "NoSpread",
    Default = false,
    Side = "right",
    Callback = function(Value)
        state.NoSpread = Value
    end
})

-- ==========================
-- VISUALS TAB
-- ==========================
VisualsTab:CreateSection("ESP Settings", "left")
createKittyToggle(VisualsTab, "NameESP", "Names", "left")
createKittyToggle(VisualsTab, "BoxESP", "Boxes", "left")
createKittyToggle(VisualsTab, "SkeletonESP", "Skeleton", "left")
createKittyToggle(VisualsTab, "HealthBar", "Health Bar", "left")
createKittyToggle(VisualsTab, "Fullbright", "Fullbright", "left")
createKittyToggle(VisualsTab, "EnemyChams", "Player Chams", "left")

VisualsTab:CreateColorPicker({
    Name = "Chams Fill Color",
    Default = Color3.fromRGB(255, 0, 0),
    UseAlpha = true,
    Flag = "EnemyChamsColor",
    Side = "left",
    Callback = function(Value, Alpha)
        state.EnemyChamsColor = Value
        state.EnemyChamsFillTransparency = Alpha and (1 - Alpha) or 0.5
    end
})

VisualsTab:CreateColorPicker({
    Name = "Chams Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    UseAlpha = true,
    Flag = "EnemyChamsOutlineColor",
    Side = "left",
    Callback = function(Value, Alpha)
        state.EnemyChamsOutlineColor = Value
        state.EnemyChamsOutlineTransparency = Alpha and (1 - Alpha) or 0
    end
})

VisualsTab:CreateSection("Viewmodel", "left")
createKittyToggle(VisualsTab, "CustomViewmodel", "Enable Viewmodel Changer", "left")
VisualsTab:CreateSlider({
    Name = "X Offset",
    Min = -5,
    Max = 5,
    Default = 0,
    Rounding = 2,
    Flag = "ViewmodelX",
    Side = "left",
    Callback = function(Value) state.ViewmodelX = Value end
})
VisualsTab:CreateSlider({
    Name = "Y Offset",
    Min = -5,
    Max = 5,
    Default = 0,
    Rounding = 2,
    Flag = "ViewmodelY",
    Side = "left",
    Callback = function(Value) state.ViewmodelY = Value end
})
VisualsTab:CreateSlider({
    Name = "Z Offset",
    Min = -5,
    Max = 5,
    Default = 0,
    Rounding = 2,
    Flag = "ViewmodelZ",
    Side = "left",
    Callback = function(Value) state.ViewmodelZ = Value end
})

VisualsTab:CreateSection("Hitsounds", "right")
VisualsTab:CreateDropdown({
    Name = "Hit Sound",
    Items = getHitsoundList(),
    Default = "None",
    Multi = false,
    Flag = "HitSound",
    Side = "right",
    Callback = function(SelectedTable)
        local soundName = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
        state.HitSound = soundName
        
        if soundName ~= "None" then
            local assetId = getHitSoundUrl(soundName)
            if assetId ~= "" then
                local sound = Instance.new("Sound", workspace)
                sound.SoundId = assetId
                sound.Volume = state.HitSoundVolume or 1
                sound:Play()
                task.delay(3, function() sound:Destroy() end)
            end
        end
    end
})
VisualsTab:CreateSlider({
    Name = "Hit Volume",
    Min = 0,
    Max = 5,
    Default = 1,
    Rounding = 2,
    Flag = "HitSoundVolume",
    Side = "right",
    Callback = function(Value) state.HitSoundVolume = Value end
})

-- ==========================
-- LOCAL TAB
-- ==========================


LocalTab:CreateSection("Local Modifiers", "left")
createKittyToggle(LocalTab, "ThirdPerson", "Third Person", "left")
LocalTab:CreateSlider({
    Name = "Distance",
    Min = 5,
    Max = 30,
    Default = 10,
    Rounding = 2,
    Flag = "ThirdPersonDistance",
    Side = "left",
    Callback = function(Value) state.ThirdPersonDistance = Value end
})
LocalTab:CreateToggle({
    Name = "Infinite Ammo",
    Flag = "InfAmmo",
    Default = false,
    Side = "left",
    Callback = function(Value) state.InfAmmo = Value end
})

LocalTab:CreateToggle({
    Name = "No Stamina",
    Flag = "NoStamina",
    Default = false,
    Side = "left",
    Callback = function(Value) state.NoStamina = Value end
})
SettingsTab:CreateColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(167, 76, 219),
    Flag = "AccentColor",
    Side = "left",
    Callback = function(Value)
        if Library.SetTheme then
            Library:SetTheme("Accent", Value)
        end
    end
})

SettingsTab:CreateColorPicker({
    Name = "Background Color",
    Default = Color3.fromRGB(15, 15, 15),
    Flag = "MainColor",
    Side = "left",
    Callback = function(Value)
        if Library.SetTheme then
            Library:SetTheme("Background", Value)
        end
    end
})

SettingsTab:CreateColorPicker({
    Name = "Text Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "TextColor",
    Side = "left",
    Callback = function(Value)
        if Library.SetTheme then
            Library:SetTheme("Text", Value)
        end
    end
})

SettingsTab:CreateSection("Configuration", "right")

local ConfigName = "LarpConfig"

SettingsTab:CreateTextBox({
    Name = "Config Name",
    Placeholder = "Enter Config Name",
    Side = "right",
    Callback = function(Value)
        if Value and Value ~= "" then
            ConfigName = Value
        end
    end
})

local function GetConfigs()
    local configs = {}
    if isfolder("KittyAuth") and isfolder("KittyAuth/Configs") then
        for _, file in ipairs(listfiles("KittyAuth/Configs")) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    if #configs == 0 then table.insert(configs, "Default") end
    return configs
end

local ConfigDropdown = SettingsTab:CreateDropdown({
    Name = "Select Config",
    Items = GetConfigs(),
    Default = "LarpConfig",
    Multi = false,
    Side = "right",
    Callback = function(SelectedTable)
        local sel = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
        if sel and sel ~= "" then
            ConfigName = sel
        end
    end
})

SettingsTab:CreateButton({
    Name = "Create Config",
    Side = "right",
    Callback = function()
        if ConfigName and ConfigName ~= "" then
            if not isfolder("KittyAuth") then makefolder("KittyAuth") end
            if not isfolder("KittyAuth/Configs") then makefolder("KittyAuth/Configs") end
            if Library.ConfigManager then
                Library.ConfigManager:Save(ConfigName)
            end
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown:Refresh(GetConfigs())
            end
        end
    end
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Side = "right",
    Callback = function()
        if Library.ConfigManager then
            Library.ConfigManager:Save(ConfigName)
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown:Refresh(GetConfigs())
            end
        end
    end
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Side = "right",
    Callback = function()
        if Library.ConfigManager then
            Library.ConfigManager:Load(ConfigName)
        end
    end
})

SettingsTab:CreateButton({
    Name = "Refresh Configs",
    Side = "right",
    Callback = function()
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown:Refresh(GetConfigs())
        end
    end
})

SettingsTab:CreateSection("Keybinds", "left")
SettingsTab:CreateToggle({
    Name = "Show Keybind List",
    Flag = "ShowKeybindList",
    Default = false,
    Side = "left",
    Callback = function(Value)
        if Library.KeybindList then
            Library.KeybindList.Visible = Value
        end
    end
})

-- ==========================
-- FOV CIRCLE (Drawing API)
-- ==========================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Filled = false
fovCircle.Visible = false

table.insert(connections, RunService.RenderStepped:Connect(function()
    if state.SilentAim then
        fovCircle.Visible = true
        fovCircle.Radius = state.FOVSize
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        if vp then
            fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        end
    else
        fovCircle.Visible = false
    end
end))

-- ==========================
-- RAGE TRIGGERBOT (Auto Shoot)
-- ==========================

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = state.FOVSize
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local screenCenter = cam.ViewportSize / 2
    local mercFolder = workspace:FindFirstChild("MercPlayers")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetHead = nil
            if mercFolder then
                local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. player.Name)
                if hitboxModel then
                    targetHead = hitboxModel:FindFirstChild("Head")
                end
            end
            if not targetHead then
                targetHead = player.Character:FindFirstChild("Head")
            end

            if targetHead then
                local screenPos, onScreen = cam:WorldToViewportPoint(targetHead.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < shortestDistance then
                        -- Wall check
                        if state.Wallcheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local filter = {cam}
                            if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
                            if targetHead.Parent then table.insert(filter, targetHead.Parent) end
                            rayParams.FilterDescendantsInstances = filter
                            local result = workspace:Raycast(cam.CFrame.Position, (targetHead.Position - cam.CFrame.Position), rayParams)
                            if result then
                                continue
                            end
                        end
                        closestPlayer = player
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    if state.Rage then
        local target = getClosestPlayerToCursor()
        
        if target then
            local targetHead = nil
            local mercFolder = workspace:FindFirstChild("MercPlayers")
            if mercFolder then
                local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. target.Name)
                if hitboxModel then
                    targetHead = hitboxModel:FindFirstChild("Head")
                end
            end
            if not targetHead and target.Character then
                targetHead = target.Character:FindFirstChild("Head")
            end
            
            if targetHead then
                if GunController and type(GunController.FireWeapon) == "function" then
                    GunController:FireWeapon()
                end
                return
            end
        end
    end
end))

-- ==========================
-- WEAPON MODIFICATION
-- ==========================
local originalWeaponStats = {}
local WeaponsModule = require(ReplicatedStorage:WaitForChild("Registries"):WaitForChild("Weapons"))

local function deepCopyOriginalSounds(sounds)
    if type(sounds) ~= "table" then return sounds end
    local copy = {}
    for k, v in pairs(sounds) do
        if type(v) == "table" then
            copy[k] = deepCopyOriginalSounds(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function modifyWeapons(revert)
    for weaponName, weaponData in pairs(WeaponsModule) do
        if type(weaponData) == "table" and weaponData.Stats then
            if not originalWeaponStats[weaponName] then
                originalWeaponStats[weaponName] = {
                    BulletSpread = weaponData.Stats.BulletSpread,
                    RecoilPatternScale = weaponData.Stats.RecoilPatternScale,
                    BulletSize = weaponData.Stats.BulletSize,
                }
            end

            if revert == false then
                weaponData.Stats.BulletSpread = originalWeaponStats[weaponName].BulletSpread
                weaponData.Stats.RecoilPatternScale = originalWeaponStats[weaponName].RecoilPatternScale
                weaponData.Stats.BulletSize = originalWeaponStats[weaponName].BulletSize
            else
                if state.NoRecoilSpread then
                    weaponData.Stats.BulletSpread = 0
                    weaponData.Stats.RecoilPatternScale = 0
                end
            end
        end
    end
end

_G.LarpModifyWeapons = modifyWeapons
modifyWeapons()

-- ==========================
-- ESP SYSTEM (Drawing API)
-- ==========================
local ESPObjects = {}
local boneConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local function createESP(target)
    local esp = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        HealthOutline = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
        HealthText = Drawing.new("Text"),
        Name = Drawing.new("Text"),
        SkeletonLines = {}
    }

    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Visible = false

    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.Box.Filled = false
    esp.Box.Visible = false

    esp.HealthOutline.Thickness = 3
    esp.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthOutline.Visible = false

    esp.HealthBar.Thickness = 1
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Visible = false

    esp.HealthText.Size = 13
    esp.HealthText.Font = 2
    esp.HealthText.Text = ""
    esp.HealthText.Center = true
    esp.HealthText.Outline = true
    esp.HealthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.HealthText.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthText.Visible = false

    esp.Name.Size = 13
    esp.Name.Font = 2
    esp.Name.Text = ""
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Visible = false

    for i = 1, #boneConnections do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        esp.SkeletonLines[i] = line
    end

    return esp
end

local function removeESP(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.Box then esp.Box:Remove() end
        if esp.BoxOutline then esp.BoxOutline:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.HealthBar then esp.HealthBar:Remove() end
        if esp.HealthOutline then esp.HealthOutline:Remove() end
        if esp.HealthText then esp.HealthText:Remove() end
        if esp.SkeletonLines then
            for _, line in ipairs(esp.SkeletonLines) do
                if line then line:Remove() end
            end
        end
        ESPObjects[player] = nil
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        ESPObjects[player] = createESP(player)
    end
end

table.insert(connections, Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        ESPObjects[player] = createESP(player)
    end
end))
table.insert(connections, Players.PlayerRemoving:Connect(removeESP))

-- ESP Render Loop
table.insert(connections, RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    for player, esp in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            local health = character.Humanoid.Health
            local maxHealth = (character.Humanoid.MaxHealth > 0 and character.Humanoid.MaxHealth) or 100

            local mercFolder = workspace:FindFirstChild("MercPlayers")
            local adorneePart = character.HumanoidRootPart
            local visualModel = character

            local hitboxModel = nil

            if mercFolder then
                hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. player.Name)
                if hitboxModel then
                    adorneePart = hitboxModel:FindFirstChild("HumanoidRootPart") or hitboxModel:FindFirstChild("LowerTorso") or hitboxModel:FindFirstChild("Torso") or adorneePart
                end
                local vModel = mercFolder:FindFirstChild("MercVisual_" .. player.Name)
                if vModel then visualModel = vModel end
            end

            local onScreen = false
            if adorneePart then
                local pos, vis = camera:WorldToViewportPoint(adorneePart.Position)
                onScreen = vis
            end

            if health > 0 and onScreen then
                local head = nil
                if hitboxModel then head = hitboxModel:FindFirstChild("Head") end
                if not head then head = visualModel:FindFirstChild("Head") or character:FindFirstChild("Head") end
                
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                local anyOnScreen = false
                
                -- Iterate skeleton points to find bounds
                for _, joint in ipairs(boneConnections) do
                    for _, partName in ipairs(joint) do
                        local p = nil
                        if hitboxModel then p = hitboxModel:FindFirstChild(partName) end
                        if not p then p = visualModel:FindFirstChild(partName) or character:FindFirstChild(partName) end
                        if p then
                            local pos, vis = camera:WorldToViewportPoint(p.Position)
                            if vis then anyOnScreen = true end
                            minX = math.min(minX, pos.X)
                            minY = math.min(minY, pos.Y)
                            maxX = math.max(maxX, pos.X)
                            maxY = math.max(maxY, pos.Y)
                        end
                    end
                end
                
                local boxX, boxY, boxWidth, boxHeight = 0, 0, 0, 0
                if anyOnScreen and maxX > minX and maxY > minY then
                    boxX = minX
                    boxY = minY
                    boxWidth = maxX - minX
                    boxHeight = maxY - minY
                else
                    local rootPos = camera:WorldToViewportPoint(adorneePart.Position - Vector3.new(0, 2.8, 0))
                    local headPos = camera:WorldToViewportPoint(head and (head.Position + Vector3.new(0, 1, 0)) or (adorneePart.Position + Vector3.new(0, 2, 0)))
                    boxHeight = math.abs(headPos.Y - rootPos.Y)
                    boxWidth = boxHeight / 1.75
                    boxX = rootPos.X - boxWidth / 2
                    boxY = math.min(headPos.Y, rootPos.Y)
                end
                local pct = math.clamp(health / maxHealth, 0, 1)

                if state.BoxESP then
                    esp.Box.Visible = true
                    esp.BoxOutline.Visible = true
                    esp.Box.Size = Vector2.new(boxWidth, boxHeight)
                    esp.Box.Position = Vector2.new(boxX, boxY)
                    esp.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    esp.BoxOutline.Position = Vector2.new(boxX, boxY)
                else
                    esp.Box.Visible = false
                    esp.BoxOutline.Visible = false
                end

                if state.HealthBar then
                    esp.HealthOutline.Visible = true
                    esp.HealthBar.Visible = true
                    esp.HealthText.Visible = true

                    local barX = boxX - 6
                    local startY = boxY + boxHeight
                    local endY = boxY
                    local currentHealthY = startY - (boxHeight * pct)

                    esp.HealthOutline.From = Vector2.new(barX, startY + 1)
                    esp.HealthOutline.To = Vector2.new(barX, endY - 1)

                    esp.HealthBar.From = Vector2.new(barX, startY)
                    esp.HealthBar.To = Vector2.new(barX, currentHealthY)
                    esp.HealthBar.Color = Color3.new(1 - pct, pct, 0)

                    esp.HealthText.Text = tostring(math.floor(health))
                    esp.HealthText.Color = Color3.new(1 - pct, pct, 0)
                    local boundsX = (esp.HealthText.TextBounds and esp.HealthText.TextBounds.X > 0) and esp.HealthText.TextBounds.X or 24
                    esp.HealthText.Position = Vector2.new(barX - (boundsX / 2) - 2, currentHealthY - 6)
                else
                    esp.HealthOutline.Visible = false
                    esp.HealthBar.Visible = false
                    esp.HealthText.Visible = false
                end

                if state.NameESP then
                    esp.Name.Visible = true
                    esp.Name.Text = player.DisplayName or player.Name
                    esp.Name.Position = Vector2.new(boxX + (boxWidth / 2), boxY - 16)
                else
                    esp.Name.Visible = false
                end

                if state.SkeletonESP then
                    for i, joint in ipairs(boneConnections) do
                        local p1 = nil
                        local p2 = nil
                        if hitboxModel then
                            p1 = hitboxModel:FindFirstChild(joint[1])
                            p2 = hitboxModel:FindFirstChild(joint[2])
                        end
                        if not p1 then p1 = visualModel:FindFirstChild(joint[1]) or character:FindFirstChild(joint[1]) end
                        if not p2 then p2 = visualModel:FindFirstChild(joint[2]) or character:FindFirstChild(joint[2]) end
                        
                        if p1 and p2 then
                            local s1, o1 = camera:WorldToViewportPoint(p1.Position)
                            local s2, o2 = camera:WorldToViewportPoint(p2.Position)
                            if o1 and o2 then
                                local line = esp.SkeletonLines[i]
                                if line then
                                    line.Visible = true
                                    line.From = Vector2.new(s1.X, s1.Y)
                                    line.To = Vector2.new(s2.X, s2.Y)
                                end
                            else
                                if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                            end
                        else
                            if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                        end
                    end
                else
                    for _, line in ipairs(esp.SkeletonLines) do line.Visible = false end
                end
            else
                esp.Box.Visible = false
                esp.BoxOutline.Visible = false
                esp.HealthOutline.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthText.Visible = false
                esp.Name.Visible = false
                for _, line in ipairs(esp.SkeletonLines) do line.Visible = false end
            end
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthText.Visible = false
            esp.Name.Visible = false
            for _, line in ipairs(esp.SkeletonLines) do line.Visible = false end
        end
    end
end))

-- ==========================
-- INFINITE AMMO / GUN MODS / NO STAMINA / NOCLIP
-- ==========================

local oldApplyRecoil = GunController.ApplyRecoil
GunController.ApplyRecoil = function(...)
    if state.NoRecoil then return end
    return oldApplyRecoil(...)
end

if GunController.CameraFX then
    local oldCamRecoil = GunController.CameraFX.Recoil
    GunController.CameraFX.Recoil = function(...)
        if state.NoRecoil then return end
        return oldCamRecoil(...)
    end
end

local oldGetEffectiveBloomDeg = GunController._GetEffectiveBloomDeg
GunController._GetEffectiveBloomDeg = function(...)
    if state.NoSpread then return 0 end
    return oldGetEffectiveBloomDeg(...)
end






table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if GunController.Weapon and GunController.Weapon.MaxMagSize then
        if state.InfAmmo then
            GunController.Weapon.MagAmmo = 9999
            GunController.Weapon.MaxMagSize = 9999
        end

        if not GunController.Weapon._originalStatsCached then
            GunController.Weapon._originalFireRate = GunController.Weapon.FireRate
            GunController.Weapon._originalFireMode = GunController.Weapon.FireMode
            GunController.Weapon._originalFireModes = GunController.Weapon.FireModes
            GunController.Weapon._originalStatsCached = true
        end

        if state.RapidFire then
            GunController.Weapon.FireRate = 0.01
            GunController.Weapon.FireMode = "auto"
            GunController.Weapon.FireModes = {"auto"}
        else
            GunController.Weapon.FireRate = GunController.Weapon._originalFireRate
            GunController.Weapon.FireMode = GunController.Weapon._originalFireMode
            GunController.Weapon.FireModes = GunController.Weapon._originalFireModes
        end
    end

    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if state.NoStamina then
            humanoid:SetAttribute("MomentumWalkSpeed", 34)
            if humanoid.WalkSpeed < 34 then
                humanoid.WalkSpeed = 34
            end
        end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Anchored then hrp.Anchored = false end
    end

    if not GunController._PlayGunFireHooked then
        GunController._PlayGunFireHooked = true
        GunController._PlayGunFireAnimation = function() end
    end
end))

local CurrentCamera = workspace.CurrentCamera
local BulletController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("BulletController"))
local originalDischarge = BulletController.Discharge

BulletController.Discharge = function(self, weaponName, origin, direction, muzzleCFrame)
    local targetDirection = direction
    local target = state.SilentAim and getClosestPlayerToCursor() or nil

    if target then
        local targetHead = nil
        local mercFolder = workspace:FindFirstChild("MercPlayers")
        if mercFolder then
            local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. target.Name)
            if hitboxModel then
                targetHead = hitboxModel:FindFirstChild("Head")
            end
        end
        if not targetHead and target.Character then
            targetHead = target.Character:FindFirstChild("Head")
        end

        if targetHead then
            targetDirection = (targetHead.Position - origin).Unit
        end
    end

    return originalDischarge(self, weaponName, origin, targetDirection, muzzleCFrame)
end

-- ==========================
-- FULLBRIGHT
-- ==========================
local oldAmbient = Lighting.Ambient
local oldColorShift_Bottom = Lighting.ColorShift_Bottom
local oldColorShift_Top = Lighting.ColorShift_Top
local oldGlobalShadows = Lighting.GlobalShadows
local oldOutdoorAmbient = Lighting.OutdoorAmbient
local oldFogEnd = Lighting.FogEnd
local oldBrightness = Lighting.Brightness

table.insert(connections, RunService.RenderStepped:Connect(function()
    if state.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
    else
        Lighting.Ambient = oldAmbient
        Lighting.ColorShift_Bottom = oldColorShift_Bottom
        Lighting.ColorShift_Top = oldColorShift_Top
        Lighting.GlobalShadows = oldGlobalShadows
        Lighting.OutdoorAmbient = oldOutdoorAmbient
        Lighting.FogEnd = oldFogEnd
        Lighting.Brightness = oldBrightness
    end
end))

-- ==========================
-- FIELD OF VIEW
-- ==========================
table.insert(connections, RunService.RenderStepped:Connect(function()
    if state.EnableFOV and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = state.CustomFOV
    end
end))

-- ==========================
-- HAND CHAMS
-- ==========================
table.insert(connections, RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local function applyChams(partName)
        for _, obj in pairs(cam:GetDescendants()) do
            if obj:IsA("MeshPart") and obj.Name == partName then
                local surfaceApp = obj:FindFirstChildOfClass("SurfaceAppearance")
                if surfaceApp then surfaceApp:Destroy() end

                if state.HandChams then
                    if state.HandChamsMaterial == "Glow" then
                        local hl = obj:FindFirstChild("LarpHighlight")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "LarpHighlight"
                            hl.Parent = obj
                        end
                        hl.FillColor = state.HandChamsColor
                        hl.FillTransparency = state.HandChamsTransparency or 0
                        hl.OutlineColor = state.HandChamsColor
                        hl.OutlineTransparency = state.HandChamsTransparency or 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    else
                        local hl = obj:FindFirstChild("LarpHighlight")
                        if hl then hl:Destroy() end
                        obj.Material = Enum.Material[state.HandChamsMaterial] or Enum.Material.Neon
                        obj.Color = state.HandChamsColor
                        obj.Transparency = state.HandChamsTransparency or 0
                    end
                else
                    local hl = obj:FindFirstChild("LarpHighlight")
                    if hl then hl:Destroy() end
                    obj.Transparency = 0
                end
            end
        end
    end

    applyChams("SK_Gloves5A")
    applyChams("SK_ShirtSleevesB")
    applyChams("SK_RashguardSleevesA")
end))

-- ==========================
-- ENEMY CHAMS (Highlight)
-- ==========================
table.insert(connections, RunService.RenderStepped:Connect(function()
    local mercFolder = workspace:FindFirstChild("MercPlayers")
    if not mercFolder then return end

    for _, model in ipairs(mercFolder:GetChildren()) do
        local isHitbox = string.sub(model.Name, 1, 13) == "MercHitboxes_"
        local isVisual = string.sub(model.Name, 1, 11) == "MercVisual_"

        if isHitbox or isVisual then
            local playerName = isHitbox and string.sub(model.Name, 14) or string.sub(model.Name, 12)

            if playerName ~= LocalPlayer.Name then
                local hl = model:FindFirstChild("LarpHighlight")

                if state.EnemyChams then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "LarpHighlight"
                        hl.Parent = model
                    end
                    hl.FillColor = state.EnemyChamsColor
                    hl.FillTransparency = state.EnemyChamsFillTransparency
                    hl.OutlineColor = state.EnemyChamsOutlineColor
                    hl.OutlineTransparency = state.EnemyChamsOutlineTransparency
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

                    if isHitbox then
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                            end
                        end
                    end
                else
                    if hl then hl:Destroy() end
                    if isHitbox then
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                            end
                        end
                    end
                end
            end
        end
    end
end))

-- ==========================
-- CAMERA, VIEWMODEL, ASPECT RATIO, HITSOUNDS
-- ==========================
local originalMaterials = {}
local originalTransparencies = {}
local originalSunRays = {}
local hitSoundObj = Instance.new("Sound", workspace)

local originalViewmodelOffsets = {}

table.insert(connections, RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if camera then
        if state.ThirdPerson then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            camera.CFrame = camera.CFrame * CFrame.new(0, 0, state.ThirdPersonDistance)
        end
    end

    -- Custom Viewmodel via GunController
    if GunController.Weapon then
        if not originalViewmodelOffsets[GunController.Weapon.Name] then
            originalViewmodelOffsets[GunController.Weapon.Name] = GunController.Weapon.ViewmodelOffset
        end

        local target = state.Rage and getClosestPlayerToCursor() or nil
        local targetHead = nil
        if target and target.Character then
            local mercFolder = workspace:FindFirstChild("MercPlayers")
            if mercFolder then
                local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. target.Name)
                if hitboxModel then
                    targetHead = hitboxModel:FindFirstChild("Head")
                end
            end
            if not targetHead then
                targetHead = target.Character:FindFirstChild("Head")
            end
        end

        if targetHead then
            local cam = workspace.CurrentCamera
            local T = targetHead.Position
            local dir = (T - cam.CFrame.Position).Unit
            local pos = T - dir * 5
            local targetWorldCFrame = CFrame.lookAt(pos, T)
            GunController.Weapon.ViewmodelOffset = cam.CFrame:ToObjectSpace(targetWorldCFrame)
        elseif state.CustomViewmodel then
            GunController.Weapon.ViewmodelOffset = originalViewmodelOffsets[GunController.Weapon.Name] * CFrame.new(state.ViewmodelX, state.ViewmodelY, state.ViewmodelZ)
        else
            GunController.Weapon.ViewmodelOffset = originalViewmodelOffsets[GunController.Weapon.Name]
        end
    end
end))

local oldPlaySound
oldPlaySound = hookfunction(SoundController.PlaySound, function(...)
    local args = {...}
    local soundName = args[2]

    if soundName == "Hitmarker" or soundName == "HitmarkerHeadshot" then
        if state.HitSound ~= "None" then
            local soundUrl = getHitSoundUrl(state.HitSound)
            if soundUrl ~= "" then
                task.spawn(function()
                    hitSoundObj.SoundId = soundUrl
                    hitSoundObj.Volume = state.HitSoundVolume or 1
                    hitSoundObj.TimePosition = 0
                    hitSoundObj:Play()
                end)
            end
            return nil
        end
    end

    return oldPlaySound(...)
end)

-- ==========================
-- ANNOYING EFFECTS REMOVER
-- ==========================
task.spawn(function()
    local lightingEffects = {
        "NVG_BLOOM", "NVG_CC", "NVG_DOF",
        "AimDOF", "Bloom", "ColorCorrection",
        "ColorGrading", "CursorFreeBlur", "DeathBlur",
        "DeathCC", "DepthOfField"
    }

    while task.wait(1) do
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local vignettes = playerGui:FindFirstChild("Vignettes")
            if vignettes then vignettes:Destroy() end
        end

        for _, effectName in ipairs(lightingEffects) do
            local effect = Lighting:FindFirstChild(effectName)
            if effect then effect:Destroy() end
        end

        if state.RemoveTextures then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    if not originalMaterials[v] then
                        originalMaterials[v] = v.Material
                    end
                    v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Texture") or v:IsA("Decal") then
                    if not originalTransparencies[v] then
                        originalTransparencies[v] = v.Transparency
                    end
                    v.Transparency = 1
                end
            end
        else
            for v, mat in pairs(originalMaterials) do
                if v and v.Parent then v.Material = mat end
            end
            for v, trans in pairs(originalTransparencies) do
                if v and v.Parent then v.Transparency = trans end
            end
            table.clear(originalMaterials)
            table.clear(originalTransparencies)
        end

        if state.RemoveSunGlare then
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("SunRaysEffect") then
                    if originalSunRays[v] == nil then
                        originalSunRays[v] = v.Enabled
                    end
                    v.Enabled = false
                end
            end
        else
            for v, enabled in pairs(originalSunRays) do
                if v and v.Parent then v.Enabled = enabled end
            end
            table.clear(originalSunRays)
        end
    end
end)

-- ==========================
-- UNLOAD FUNCTION
-- ==========================
local function unload()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    table.clear(connections)

    -- Remove Drawing objects
    for player, esp in pairs(ESPObjects) do
        removeESP(player)
    end
    table.clear(ESPObjects)

    if fovCircle then fovCircle:Remove() end
    if hitSoundObj then hitSoundObj:Destroy() end

    if Library then
        Library:Unload()
    end

    if modifyWeapons then
        modifyWeapons(false)
    end

    for v, mat in pairs(originalMaterials) do
        if v and v.Parent then v.Material = mat end
    end
    for v, trans in pairs(originalTransparencies) do
        if v and v.Parent then v.Transparency = trans end
    end
    for v, enabled in pairs(originalSunRays) do
        if v and v.Parent then v.Enabled = enabled end
    end
end

-- Listen for End key to unload
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.End then
            unload()
        end
    end
end))
