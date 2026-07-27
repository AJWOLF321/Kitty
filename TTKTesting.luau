local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Block anti-cheat telemetry using a safer hookfunction (avoids breaking namecall on other methods)
local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
    if tostring(self) == "SessionTelemetry" then
        return -- Void the telemetry report
    end
    return oldFireServer(self, ...)
end)

-- Store our event connections so we can disconnect them later
local connections = {}

-- Create a folder in CoreGui to hold all our ESP elements
local espFolder = Instance.new("Folder")
espFolder.Name = "LarpESP"
if CoreGui:FindFirstChild(espFolder.Name) then
    CoreGui[espFolder.Name]:Destroy()
end
espFolder.Parent = CoreGui

local espObjects = {}
local activeGlowChams = {}

-- State variables for toggles
local state = {
    ESP = false,
    SilentAim = false,
    MagicBullet = false,
    InfiniteAmmo = false,
    RapidFire = false,
    NoStamina = false,
    KillEffects = false,
    KillEffectType = "Confetti",
    RemoveAnimations = {},
    TriggerBot = false,
    SkeletonESP = false,
    HealthBar = false,
    RBot = false,
    TracerType = "Zap Confetti",
    TracerColor = Color3.fromRGB(255, 255, 255),
    HandChams = false,
    HandChamsMaterial = "Neon",
    HandChamsColor = Color3.fromRGB(255, 0, 0),
    EnableFOV = false,
    CustomFOV = 70,
    EnemyChams = false,
    EnemyChamsMaterial = "ForceField",
    EnemyChamsColor = Color3.fromRGB(255, 0, 0),
    EnemyChamsVisColor = Color3.fromRGB(0, 255, 0),
    EnemyChamsInvVisColor = Color3.fromRGB(255, 0, 0),
    ThickBullets = false
}

-- ==========================
-- GUI MENU (KittyUI)
-- ==========================
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/AJWOLF321/Kitty/refs/heads/main/Library.luau'))()
Library.ToggleKey = Enum.KeyCode.RightShift

local Window = Library:CreateWindow({
    Title = "Larp Suite - by Ethynwinnn",
    Folder = "Larp",
    AccentColor = Color3.fromRGB(155, 89, 182)
})

local CombatTab = Window:CreateTab("Combat")
local VisualsTab = Window:CreateTab("Visuals")
local MiscTab = Window:CreateTab("Misc")
local LocalTab = Window:CreateTab("Local")
local ConfigTab = Window:CreateTab("Config")

ConfigTab:CreateSection("Configuration", "left")

local function GetConfigs()
    local configs = {}
    if isfolder("KittyAuth") and isfolder("KittyAuth\\Configs") then
        for _, file in ipairs(listfiles("KittyAuth\\Configs")) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    if #configs == 0 then table.insert(configs, "Default") end
    return configs
end

local ConfigName = "LarpConfig"
local ConfigDropdown

ConfigTab:CreateTextBox({
    Name = "Config Name",
    Placeholder = "Enter Config Name",
    Side = "left",
    Callback = function(Value)
        if Value and Value ~= "" then
            ConfigName = Value
        end
    end
})

ConfigDropdown = ConfigTab:CreateDropdown({
    Name = "Select Config",
    Items = GetConfigs(),
    Default = "LarpConfig",
    Multi = false,
    Side = "left",
    Callback = function(SelectedTable)
        local sel = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
        if sel and sel ~= "" then
            ConfigName = sel
        end
    end
})

ConfigTab:CreateButton({
    Name = "Save Config",
    Side = "left",
    Callback = function()
        if Library.ConfigManager then
            Library.ConfigManager:Save(ConfigName)
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown:Refresh(GetConfigs())
            end
        end
    end
})

ConfigTab:CreateButton({
    Name = "Load Config",
    Side = "left",
    Callback = function()
        if Library.ConfigManager then
            Library.ConfigManager:Load(ConfigName)
        end
    end
})

ConfigTab:CreateButton({
    Name = "Refresh Configs",
    Side = "left",
    Callback = function()
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown:Refresh(GetConfigs())
        end
    end
})

local function createKittyToggle(tab, name, text, side)
    tab:CreateToggle({
        Name = text,
        Flag = name, 
        Default = state[name],
        Side = side or "left",
        Callback = function(Value)
            state[name] = Value
            if name == "NoRecoilSpread" or name == "ThickBullets" then
                -- Safely call modifyWeapons if it's defined (since the function is created further down)
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
createKittyToggle(CombatTab, "SilentAim", "Silent Aim", "left")
createKittyToggle(CombatTab, "MagicBullet", "Magic Bullet", "left")
createKittyToggle(CombatTab, "TriggerBot", "TriggerBot", "left")

CombatTab:CreateSection("Gun Mods", "right")
createKittyToggle(CombatTab, "RapidFire", "Rapid Fire", "right")
createKittyToggle(CombatTab, "NoRecoilSpread", "No Recoil/Spread", "right")
createKittyToggle(CombatTab, "ThickBullets", "Thick Bullets", "right")
createKittyToggle(CombatTab, "RBot", "R Bot", "right")

-- ==========================
-- VISUALS TAB
-- ==========================
VisualsTab:CreateSection("ESP Settings", "left")
createKittyToggle(VisualsTab, "ESP", "ESP", "left")
createKittyToggle(VisualsTab, "SkeletonESP", "Skeleton ESP", "left")
createKittyToggle(VisualsTab, "HealthBar", "Health Bar", "left")
createKittyToggle(VisualsTab, "Fullbright", "Fullbright", "left")
createKittyToggle(VisualsTab, "EnemyChams", "Enemy Chams", "left")

VisualsTab:CreateDropdown({
    Name = "Enemy Chams Material",
    Items = {"Glow", "Neon", "ForceField", "Plastic", "SmoothPlastic", "Glass"},
    Default = "ForceField",
    Multi = false,
    Flag = "EnemyChamsMaterial",
    Side = "left",
    Callback = function(SelectedTable)
        local mat = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
        state.EnemyChamsMaterial = mat
    end
})

VisualsTab:CreateColorPicker({
    Name = "Enemy Chams Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "EnemyChamsColor",
    Side = "left",
    Callback = function(Value)
        state.EnemyChamsColor = Value
    end
})

VisualsTab:CreateSection("Tracers & Effects", "right")
createKittyToggle(VisualsTab, "BulletTracers", "Bullet Tracers", "right")
createKittyToggle(VisualsTab, "KillEffects", "Kill Effects", "right")
VisualsTab:CreateDropdown({
    Name = "Kill Effect Style",
    Items = {"Confetti", "Explosion"},
    Default = "Confetti",
    Multi = false,
    Flag = "KillEffectType",
    Side = "right",
    Callback = function(Selected)
        state.KillEffectType = type(Selected) == "table" and Selected[1] or Selected
    end
})



VisualsTab:CreateDropdown({
    Name = "Tracer Type",
    Items = {"Zap Confetti", "Confetti Particles", "Fire Particles", "Zap Flat", "Flat Line"},
    Default = "Zap Confetti",
    Multi = false,
    Flag = "TracerType",
    Side = "right",
    Callback = function(SelectedTable)
        state.TracerType = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
    end
})

VisualsTab:CreateColorPicker({
    Name = "Tracer Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "TracerColor",
    Side = "right",
    Callback = function(Value)
        state.TracerColor = Value
    end
})

-- ==========================
-- MISC TAB
-- ==========================
MiscTab:CreateSection("Misc Settings", "left")
createKittyToggle(MiscTab, "InfiniteAmmo", "Infinite Ammo", "left")
createKittyToggle(MiscTab, "NoStamina", "No Stamina", "left")
createKittyToggle(MiscTab, "Noclip", "Noclip", "left")
MiscTab:CreateDropdown({
    Name = "Remove Animations",
    Items = {"Recoil", "Sway", "Bob"},
    Default = {},
    Multi = true,
    Flag = "RemoveAnimations",
    Side = "left",
    Callback = function(SelectedTable)
        state.RemoveAnimations = SelectedTable
    end
})
-- ==========================
-- LOCAL TAB
-- ==========================
LocalTab:CreateSection("Hand Chams", "left")
createKittyToggle(LocalTab, "HandChams", "Hand Chams", "left")

LocalTab:CreateDropdown({
    Name = "Hand Material",
    Items = {"Glow", "Neon", "ForceField", "Plastic", "SmoothPlastic", "Glass"},
    Default = "Neon",
    Multi = false,
    Flag = "HandChamsMaterial",
    Side = "left",
    Callback = function(SelectedTable)
        state.HandChamsMaterial = type(SelectedTable) == "table" and SelectedTable[1] or SelectedTable
    end
})

LocalTab:CreateColorPicker({
    Name = "Hand Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "HandChamsColor",
    Side = "left",
    Callback = function(Value)
        state.HandChamsColor = Value
    end
})

LocalTab:CreateSection("Field of View", "right")
createKittyToggle(LocalTab, "EnableFOV", "Custom FOV", "right")

LocalTab:CreateSlider({
    Name = "Field of View",
    Min = 70,
    Max = 120,
    Default = 70,
    Flag = "CustomFOV",
    Side = "right",
    Callback = function(Value)
        state.CustomFOV = Value
    end
})

-- ==========================
-- FOV CIRCLE
-- ==========================
local fovRadius = 600 -- 1.2k size (diameter = 1200)

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "LarpFOV"
fovGui.IgnoreGuiInset = true
if CoreGui:FindFirstChild(fovGui.Name) then
    CoreGui[fovGui.Name]:Destroy()
end
fovGui.Parent = CoreGui

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centered
fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = fovGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.new(1, 1, 1) -- White color
fovStroke.Thickness = 1
fovStroke.Parent = fovCircle

table.insert(connections, RunService.RenderStepped:Connect(function()
    fovCircle.Visible = state.SilentAim and not state.RBot
end))

-- ==========================
-- SKELETON & HEALTH BAR (MercPlayers)
-- ==========================
local skellyGuiName = "MercSkeletonESP"
if CoreGui:FindFirstChild(skellyGuiName) then
	CoreGui[skellyGuiName]:Destroy()
end

local skellyScreenGui = Instance.new("ScreenGui")
skellyScreenGui.Name = skellyGuiName
skellyScreenGui.IgnoreGuiInset = true
skellyScreenGui.Parent = CoreGui

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

local activeVisuals = {}

local function createLine()
	local line = Instance.new("Frame")
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Visible = false
	line.Parent = skellyScreenGui
	return line
end

local function createHealthBar()
	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	bg.BorderSizePixel = 1
	bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
	bg.Visible = false
	bg.Parent = skellyScreenGui

	local fg = Instance.new("Frame")
	fg.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	fg.BorderSizePixel = 0
	fg.AnchorPoint = Vector2.new(0, 1)
	fg.Parent = bg

	return bg, fg
end

table.insert(connections, RunService.RenderStepped:Connect(function()
	local mercFolder = workspace:FindFirstChild("MercPlayers")
	if not mercFolder then return end

	local currentHitboxes = {}
	local Camera = workspace.CurrentCamera

	for _, hitboxModel in ipairs(mercFolder:GetChildren()) do
		if string.sub(hitboxModel.Name, 1, 13) == "MercHitboxes_" then
			local playerName = string.sub(hitboxModel.Name, 14)
			
			if playerName ~= LocalPlayer.Name then
				currentHitboxes[hitboxModel] = true
				
				if not activeVisuals[hitboxModel] then
					local lines = {}
					for i = 1, #boneConnections do
						table.insert(lines, createLine())
					end
					local healthBg, healthFg = createHealthBar()
					
					activeVisuals[hitboxModel] = {
						Lines = lines,
						HealthBg = healthBg,
						HealthFg = healthFg
					}
				end

				local visuals = activeVisuals[hitboxModel]
				local player = Players:FindFirstChild(playerName)
				local head = hitboxModel:FindFirstChild("Head")
				local leftFoot = hitboxModel:FindFirstChild("LeftFoot") or hitboxModel:FindFirstChild("LowerTorso")
				
				-- Draw the Skeleton Lines
				for i, connection in ipairs(boneConnections) do
					local partA = hitboxModel:FindFirstChild(connection[1])
					local partB = hitboxModel:FindFirstChild(connection[2])
					local line = visuals.Lines[i]

					if state.SkeletonESP and partA and partB then
						local posA = Camera:WorldToViewportPoint(partA.Position)
						local posB = Camera:WorldToViewportPoint(partB.Position)

						if posA.Z > 0 and posB.Z > 0 then
							local vecA = Vector2.new(posA.X, posA.Y)
							local vecB = Vector2.new(posB.X, posB.Y)
							local dist = (vecB - vecA).Magnitude
							local center = (vecA + vecB) / 2

							line.Size = UDim2.new(0, dist, 0, 1)
							line.Position = UDim2.new(0, center.X, 0, center.Y)
							line.Rotation = math.deg(math.atan2(vecB.Y - vecA.Y, vecB.X - vecA.X))
							line.Visible = true
						else
							line.Visible = false
						end
					else
						line.Visible = false
					end
				end

				-- Draw the Health Bar
				local rootPart = hitboxModel:FindFirstChild("HumanoidRootPart") or hitboxModel:FindFirstChild("LowerTorso") or hitboxModel:FindFirstChild("Torso")
				if state.HealthBar and rootPart and player and player.Character and player.Character:FindFirstChild("Humanoid") then
					local humanoid = player.Character.Humanoid
					local rootPos = Camera:WorldToViewportPoint(rootPart.Position)

					if rootPos.Z > 0 then
						-- Calculate stable height/width based on distance to root part, avoiding animation jitter
						local topPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
						local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
						
						local height = math.abs(topPos.Y - bottomPos.Y)
						local width = math.clamp(height * 0.1, 2, 6)
						local xOffset = math.clamp(height * 0.4, 15, 60)
						
						local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

						visuals.HealthBg.Size = UDim2.new(0, width, 0, height)
						visuals.HealthBg.Position = UDim2.new(0, rootPos.X - xOffset, 0, topPos.Y)
						visuals.HealthBg.Visible = true

						visuals.HealthFg.Size = UDim2.new(1, 0, healthPercent, 0)
						visuals.HealthFg.Position = UDim2.new(0, 0, 1, 0)
					else
						visuals.HealthBg.Visible = false
					end
				else
					if visuals.HealthBg then visuals.HealthBg.Visible = false end
				end
			end
		end
	end

	-- Cleanup
	for model, visuals in pairs(activeVisuals) do
		if not currentHitboxes[model] or not model.Parent then
			for _, line in ipairs(visuals.Lines) do
				line:Destroy()
			end
			if visuals.HealthBg then visuals.HealthBg:Destroy() end
			activeVisuals[model] = nil
		end
	end
end))

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

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

local function modifyWeapons()
    for key, data in pairs(WeaponsModule) do
        if type(data) == "table" then
            -- Save original stats if not already saved
            if not originalWeaponStats[key] then
                originalWeaponStats[key] = {
                    RecoilMult = data.RecoilMult,
                    RecoilTilt = data.RecoilTilt,
                    RecoilPushMult = data.RecoilPushMult,
                    RecoilPitchMult = data.RecoilPitchMult,
                    CameraRecoilMult = data.CameraRecoilMult,
                    CameraRecoilAimMult = data.CameraRecoilAimMult,
                    FovRecoilMult = data.FovRecoilMult,
                    ViewmodelRecoilMult = data.ViewmodelRecoilMult,
                    CameraShakeMult = data.CameraShakeMult,
                    CameraPunchMult = data.CameraPunchMult,
                    CameraRecoilAttackMult = data.CameraRecoilAttackMult,
                    FireDriftScale = data.FireDriftScale,
                    FireAnimSpeed = data.FireAnimSpeed,
                    SpreadAngle = data.SpreadAngle,
                    FireSound = data.FireSound,
                    Sounds = deepCopyOriginalSounds(data.Sounds),
                    FireRate = data.FireRate,
                    FireMode = data.FireMode,
                    BulletSize = data.BulletSize,
                    ProjectileRadius = data.ProjectileRadius,
                    HitboxSize = data.HitboxSize,
                    HitboxRadius = data.HitboxRadius,
                    RayRadius = data.RayRadius,
                    Thickness = data.Thickness,
                    Radius = data.Radius
                }
            end
            
            if state.NoRecoilSpread then
                -- Zero out all recoil, spread, and sounds
                if data.RecoilMult ~= nil then
                    data.RecoilMult = 0
                    data.RecoilTilt = 0
                    data.RecoilPushMult = 0
                    data.RecoilPitchMult = 0
                    data.CameraRecoilMult = 0
                    data.CameraRecoilAimMult = 0
                    data.FovRecoilMult = 0
                    
                    if data.ViewmodelRecoilMult ~= nil then data.ViewmodelRecoilMult = 0 end
                    if data.CameraShakeMult ~= nil then data.CameraShakeMult = 0 end
                    if data.CameraPunchMult ~= nil then data.CameraPunchMult = 0 end
                    if data.CameraRecoilAttackMult ~= nil then data.CameraRecoilAttackMult = 0 end
                    if data.FireDriftScale ~= nil then data.FireDriftScale = 0 end
                    if data.FireAnimSpeed ~= nil then data.FireAnimSpeed = 0 end
                end
                if data.SpreadAngle ~= nil then
                    data.SpreadAngle = 0
                end
                if data.FireSound ~= nil then
                    data.FireSound = ""
                end
                if data.Sounds ~= nil and type(data.Sounds) == "table" then
                    -- Remove specific firing layer sounds or just zero them out
                    if data.Sounds.LowAmmoFireLayer then data.Sounds.LowAmmoFireLayer = "" end
                end
            else
                -- Restore original stats
                local orig = originalWeaponStats[key]
                if orig then
                    if data.RecoilMult ~= nil then
                        data.RecoilMult = orig.RecoilMult
                        data.RecoilTilt = orig.RecoilTilt
                        data.RecoilPushMult = orig.RecoilPushMult
                        data.RecoilPitchMult = orig.RecoilPitchMult
                        data.CameraRecoilMult = orig.CameraRecoilMult
                        data.CameraRecoilAimMult = orig.CameraRecoilAimMult
                        data.FovRecoilMult = orig.FovRecoilMult
                        if orig.ViewmodelRecoilMult ~= nil then data.ViewmodelRecoilMult = orig.ViewmodelRecoilMult end
                        if orig.CameraShakeMult ~= nil then data.CameraShakeMult = orig.CameraShakeMult end
                        if orig.CameraPunchMult ~= nil then data.CameraPunchMult = orig.CameraPunchMult end
                        if orig.CameraRecoilAttackMult ~= nil then data.CameraRecoilAttackMult = orig.CameraRecoilAttackMult end
                        if orig.FireDriftScale ~= nil then data.FireDriftScale = orig.FireDriftScale end
                        if orig.FireAnimSpeed ~= nil then data.FireAnimSpeed = orig.FireAnimSpeed end
                    end
                    if data.SpreadAngle ~= nil then
                        data.SpreadAngle = orig.SpreadAngle
                    end
                    if orig.FireSound ~= nil then
                        data.FireSound = orig.FireSound
                    end
                    if orig.Sounds ~= nil and data.Sounds ~= nil then
                        if orig.Sounds.LowAmmoFireLayer ~= nil then
                            data.Sounds.LowAmmoFireLayer = orig.Sounds.LowAmmoFireLayer
                        end
                    end
                end
            end

            if state.ThickBullets then
                if data.BulletSize ~= nil then data.BulletSize = 5 end
                if data.ProjectileRadius ~= nil then data.ProjectileRadius = 5 end
                if data.HitboxSize ~= nil then data.HitboxSize = 5 end
                if data.HitboxRadius ~= nil then data.HitboxRadius = 5 end
                if data.RayRadius ~= nil then data.RayRadius = 5 end
                if data.Thickness ~= nil then data.Thickness = 5 end
                if data.Radius ~= nil then data.Radius = 5 end
            else
                local orig = originalWeaponStats[key]
                if orig then
                    if data.BulletSize ~= nil then data.BulletSize = orig.BulletSize end
                    if data.ProjectileRadius ~= nil then data.ProjectileRadius = orig.ProjectileRadius end
                    if data.HitboxSize ~= nil then data.HitboxSize = orig.HitboxSize end
                    if data.HitboxRadius ~= nil then data.HitboxRadius = orig.HitboxRadius end
                    if data.RayRadius ~= nil then data.RayRadius = orig.RayRadius end
                    if data.Thickness ~= nil then data.Thickness = orig.Thickness end
                    if data.Radius ~= nil then data.Radius = orig.Radius end
                end
            end
        end
    end
end
_G.LarpModifyWeapons = modifyWeapons

-- Initialize weapons normally
modifyWeapons()

-- ==========================
-- ESP SYSTEM
-- ==========================
local function createESP(player)
    if player == LocalPlayer then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5.5, 0) -- approximate character size
    billboard.StudsOffset = Vector3.new(0, -0.5, 0)
    billboard.ClipsDescendants = false -- CRITICAL: Allows health bar and text to render outside the box
    billboard.Parent = espFolder

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1 -- Removed fill
    frame.BackgroundColor3 = Color3.new(1, 1, 1) -- White color
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.new(1, 1, 1) -- White color
    frame.Parent = billboard
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.new(0, 0, 0)
    uiStroke.Thickness = 1
    uiStroke.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 200, 0, 20)
    nameLabel.Position = UDim2.new(0.5, -100, 0, -25) -- Placed above the box
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0 -- Make text clearly visible
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    -- CRITICAL FIX: Add name label directly to the billboard so FindFirstChild finds it
    nameLabel.Parent = billboard

    local hpBg = Instance.new("Frame")
    hpBg.Name = "HealthBarBg"
    hpBg.Size = UDim2.new(0, 4, 1, 0) -- 4 pixels wide
    hpBg.Position = UDim2.new(0, -6, 0, 0) -- 6 pixels to the left
    hpBg.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBg.BorderSizePixel = 1
    hpBg.BorderColor3 = Color3.new(0, 0, 0)
    hpBg.Parent = billboard

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HealthBarFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.Position = UDim2.new(0, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.new(0, 1, 0)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg

    local hpText = Instance.new("TextLabel")
    hpText.Name = "HealthText"
    hpText.Size = UDim2.new(1, 0, 0, 15)
    hpText.Position = UDim2.new(0, 0, 1, 2)
    hpText.BackgroundTransparency = 1
    hpText.Text = "100 HP"
    hpText.TextColor3 = Color3.new(0, 1, 0)
    hpText.TextStrokeTransparency = 0
    hpText.TextStrokeColor3 = Color3.new(0, 0, 0)
    hpText.TextSize = 12
    hpText.Font = Enum.Font.SourceSansBold
    hpText.Parent = billboard

    espObjects[player] = billboard
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Handle players joining and leaving
table.insert(connections, Players.PlayerAdded:Connect(createESP))
table.insert(connections, Players.PlayerRemoving:Connect(removeESP))

-- Update loop to handle death and respawns smoothly
local previousHealths = {}

local function playKillEffect(targetModel, effectType)
    if not targetModel then return end
    local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("LowerTorso") or targetModel:FindFirstChild("Torso") or targetModel:FindFirstChild("Head")
    if not root then return end
    
    if effectType == "Confetti" then
        local attachment = Instance.new("Attachment")
        attachment.Parent = root
        local colors = { Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1), Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1) }
        for _, color in ipairs(colors) do
            local p = Instance.new("ParticleEmitter")
            p.Color = ColorSequence.new(color)
            p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,0)})
            p.Lifetime = NumberRange.new(8,10)
            p.Speed = NumberRange.new(15,35)
            p.SpreadAngle = Vector2.new(180,180)
            p.Rate = 0
            p.Parent = attachment
            p:Emit(25)
        end
        task.delay(10, function() if attachment then attachment:Destroy() end end)
        
    elseif effectType == "Explosion" then
        local explosion = Instance.new("Explosion")
        explosion.Position = root.Position
        explosion.BlastRadius = 0
        explosion.BlastPressure = 0
        explosion.DestroyJointRadiusPercent = 0
        explosion.Parent = workspace
        
    elseif effectType == "Blood Splash" then
        local attachment = Instance.new("Attachment")
        attachment.Parent = root
        local p = Instance.new("ParticleEmitter")
        p.Color = ColorSequence.new(Color3.fromRGB(138, 3, 3))
        p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
        p.Lifetime = NumberRange.new(1, 2)
        p.Speed = NumberRange.new(10, 25)
        p.SpreadAngle = Vector2.new(45, 45)
        p.EmissionDirection = Enum.NormalId.Top
        p.Acceleration = Vector3.new(0, -30, 0)
        p.Rate = 0
        p.Parent = attachment
        p:Emit(100)
        task.delay(3, function() if attachment then attachment:Destroy() end end)
        
    elseif effectType == "Lightning" then
        for i=1, 3 do
            task.delay(i * 0.1, function()
                if not root then return end
                local p0 = root.Position + Vector3.new(math.random(-5,5), 50, math.random(-5,5))
                local p1 = root.Position
                local beam = Instance.new("Part")
                beam.Anchored = true
                beam.CanCollide = false
                beam.Material = Enum.Material.Neon
                beam.Color = Color3.fromRGB(0, 255, 255)
                beam.Size = Vector3.new(0.5, 0.5, (p0 - p1).Magnitude)
                beam.CFrame = CFrame.lookAt(p0, p1) * CFrame.new(0, 0, -(p0 - p1).Magnitude / 2)
                beam.Parent = workspace
                task.delay(0.2, function()
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(beam, TweenInfo.new(0.3), {Transparency = 1, Size = Vector3.new(0,0,beam.Size.Z)})
                    tw:Play()
                    tw.Completed:Connect(function() beam:Destroy() end)
                end)
            end)
        end
    end
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    for player, billboard in pairs(espObjects) do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            local health = character.Humanoid.Health
            local prevHealth = previousHealths[player] or 100
            
            local mercFolder = workspace:FindFirstChild("MercPlayers")
            local targetModel = character
            local visualModel = character
            local adorneePart = character.HumanoidRootPart
            
            if mercFolder then
                local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. player.Name)
                if hitboxModel then
                    targetModel = hitboxModel
                    adorneePart = hitboxModel:FindFirstChild("HumanoidRootPart") or hitboxModel:FindFirstChild("LowerTorso") or hitboxModel:FindFirstChild("Torso")
                end
                local vModel = mercFolder:FindFirstChild("MercVisual_" .. player.Name)
                if vModel then
                    visualModel = vModel
                end
            end

            if health <= 0 and prevHealth > 0 then
                if state.KillEffects and state.KillEffectType then
                    playKillEffect(visualModel, state.KillEffectType)
                end
            end
            previousHealths[player] = health
            
            if state.ESP and health > 0 then
                billboard.Enabled = true
                billboard.Adornee = adorneePart
                
                if billboard:FindFirstChild("NameLabel") then
                    billboard.NameLabel.Text = player.DisplayName or player.Name
                end
                
                if billboard:FindFirstChild("HealthBarBg") then
                    local hpFill = billboard.HealthBarBg:FindFirstChild("HealthBarFill")
                    if hpFill then
                        local maxHealth = (character.Humanoid.MaxHealth > 0 and character.Humanoid.MaxHealth) or 100
                        local pct = math.clamp(health / maxHealth, 0, 1)
                        hpFill.Size = UDim2.new(1, 0, pct, 0)
                        hpFill.BackgroundColor3 = Color3.new(1 - pct, pct, 0)
                    end
                end
                
                if billboard:FindFirstChild("HealthText") then
                    local maxHealth = (character.Humanoid.MaxHealth > 0 and character.Humanoid.MaxHealth) or 100
                    local pct = math.clamp(health / maxHealth, 0, 1)
                    billboard.HealthText.Text = math.floor(health) .. " HP"
                    billboard.HealthText.TextColor3 = Color3.new(1 - pct, pct, 0)
                end
                
                -- Scale to fit player perfectly, using Hitbox model bounds if available
                local size = targetModel:GetExtentsSize()
                billboard.Size = UDim2.new(size.X, 0, size.Y, 0)
            else
                billboard.Enabled = false
            end
        else
            billboard.Enabled = false
        end
    end
end))

-- ==========================
-- INFINITE AMMO
-- ==========================
local GunController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("GunController"))

local normalSpeed = 50

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if GunController.Weapon and GunController.Weapon.MaxMagSize then
        if state.InfiniteAmmo then
            -- Force mag ammo and max mag size to be high
            GunController.Weapon.MagAmmo = 9999
            GunController.Weapon.MaxMagSize = 9999
            
            -- Hook reserve ammo so it doesn't run out
            if type(GunController.Weapon.GetReserve) == "function" and not GunController.Weapon._infAmmoHooked then
                GunController.Weapon.GetReserve = function() return 9999 end
                GunController.Weapon._infAmmoHooked = true
            end
        end
        
        if state.RapidFire then
            -- Override FireRate and FireMode directly on the weapon instance
            GunController.Weapon.FireRate = 0.01
            GunController.Weapon.FireMode = "auto"
            GunController.Weapon.FireModes = {"auto"}
        end
        
        -- Remove Animations Logic (Multi-Select)
        if type(state.RemoveAnimations) == "table" and GunController.Weapon then
            local removeRecoil = table.find(state.RemoveAnimations, "Recoil")
            local removeSway = table.find(state.RemoveAnimations, "Sway")
            local removeBob = table.find(state.RemoveAnimations, "Bob")
            
            -- Zero out recoil variables completely
            if removeRecoil then
                local function zeroSpring(spring)
                    if spring then
                        spring.t = Vector3.zero
                        spring.p = Vector3.zero
                        spring.v = Vector3.zero
                    end
                end
                zeroSpring(GunController.Weapon.RecoilSpring)
                zeroSpring(GunController.Weapon.RecoilShakeSpring)
                zeroSpring(GunController.Weapon.RecoilTiltSpring)
                zeroSpring(GunController.Weapon.RecoilTiltShakeSpring)
                zeroSpring(GunController.Weapon.RecoilPushSpring)
                zeroSpring(GunController.Weapon.RecoilTrailSpring)
                GunController.Weapon.RecoilAmount = 0
                
                -- Hook the camera recoil effect
                if GunController.Weapon.CameraFX and not GunController.Weapon.CameraFX._recoilHooked then
                    GunController.Weapon.CameraFX._originalRecoil = GunController.Weapon.CameraFX.Recoil
                    GunController.Weapon.CameraFX.Recoil = function(...)
                        if state.RemoveAnimations and table.find(state.RemoveAnimations, "Recoil") then return end
                        return GunController.Weapon.CameraFX._originalRecoil(...)
                    end
                    GunController.Weapon.CameraFX._recoilHooked = true
                end
            end
            
            -- Zero out sway variables
            if removeSway then
                GunController.Weapon.SwayPhase = 0
                GunController.Weapon.WalkSwayX = 0
                GunController.Weapon.WalkSwayY = 0
                if GunController.Weapon.CameraFX then
                    GunController.Weapon.CameraFX.WeaponSwayPhase = 0
                end
            end
            
            -- Zero out bob (Idle and Walk)
            if removeBob then
                if GunController.Weapon.IdleSwayOffset then
                    -- Reset via method if it exists, otherwise just clear the spring/phase
                    GunController.Weapon.IdleSwayPhase = 0
                end
                if GunController.Weapon.Viewmodel then
                    GunController.Weapon.Viewmodel.AdsWalkBobMult = 0
                    GunController.Weapon.Viewmodel.WalkBobMult = 0
                end
            end
        end
        
        if state.TriggerBot then
            local camPos = workspace.CurrentCamera.CFrame.Position
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            if LocalPlayer.Character then
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
            else
                raycastParams.FilterDescendantsInstances = {workspace.CurrentCamera}
            end
            
            local mercFolder = workspace:FindFirstChild("MercPlayers")
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    local targetHead = nil
                    local targetModel = nil
                    if mercFolder then
                        local hitboxModel = mercFolder:FindFirstChild("MercHitboxes_" .. player.Name)
                        if hitboxModel then
                            targetHead = hitboxModel:FindFirstChild("Head")
                            targetModel = hitboxModel
                        end
                    end
                    if not targetHead then
                        targetHead = player.Character:FindFirstChild("Head")
                        targetModel = player.Character
                    end

                    if targetHead and targetModel then
                        local headPos = targetHead.Position
                        local dir = (headPos - camPos)
                        local result = workspace:Raycast(camPos, dir, raycastParams)
                        if result and result.Instance and result.Instance:IsDescendantOf(targetModel) then
                            -- Visible, shoot!
                            GunController:FireWeapon()
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Also use this loop for NO STAMINA since GunController tracks sprint states
    -- The game uses 'ScaredBreath' logic and limits sprinting time, we can spoof it
    -- Or just override LocalPlayer's Humanoid directly:
    local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            local humanoid = character.Humanoid
            -- Force high momentum walkspeed so they never slow down
            if state.NoStamina then
                if humanoid:GetAttribute("MomentumWalkSpeed") then
                    humanoid:SetAttribute("MomentumWalkSpeed", normalSpeed)
                end
                humanoid.WalkSpeed = normalSpeed
            end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored then hrp.Anchored = false end
            
            if state.Noclip then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
    end
    
    -- Also disable fire animations to remove visual recoil entirely
    if not GunController._PlayGunFireHooked then
        GunController._PlayGunFireHooked = true
        GunController._PlayGunFireAnimation = function() end
    end
end))

-- ==========================
-- SILENT AIM
-- ==========================
local CurrentCamera = workspace.CurrentCamera
local BulletController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("BulletController"))
local originalDischarge = BulletController.Discharge

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = state.RBot and math.huge or fovRadius
    local screenCenter = CurrentCamera.ViewportSize / 2
    local myHeadPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position or CurrentCamera.CFrame.Position
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
                if state.RBot then
                    -- 360 Rage Bot: pick closest player in 3D space
                    local dist = (targetHead.Position - myHeadPos).Magnitude
                    if dist < shortestDistance then
                        closestPlayer = player
                        shortestDistance = dist
                    end
                else
                    -- Standard Silent Aim: pick closest to center of screen within FOV
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetHead.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < shortestDistance then
                            closestPlayer = player
                            shortestDistance = dist
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

BulletController.Discharge = function(self, weaponName, origin, direction, muzzleCFrame)
    local targetDirection = direction
    local visualOrigin = origin
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
            local headPos = targetHead.Position
            targetDirection = (headPos - visualOrigin).Unit
            
            if state.MagicBullet then
                -- Magic Bullet: Start the bullet raycast directly in front of the target's head
                -- This bypasses walls and objects between you and the target
                origin = headPos - (targetDirection * 2)
            end
        end
    end
    
    if state.BulletTracers then
        task.spawn(function()
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            if LocalPlayer.Character then
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
            else
                raycastParams.FilterDescendantsInstances = {workspace.CurrentCamera}
            end
            
            local tracerStartPos = visualOrigin
            if muzzleCFrame and typeof(muzzleCFrame) == "CFrame" then
                tracerStartPos = muzzleCFrame.Position
            end
            
            local rayResult = workspace:Raycast(origin, targetDirection * 1000, raycastParams)
            local endPos = rayResult and rayResult.Position or (origin + targetDirection * 1000)
            local dist = (endPos - tracerStartPos).Magnitude
            
            if dist > 0.1 then
                if state.TracerType == "Zap Confetti" or state.TracerType == "Zap Flat" then
                    local segments = math.clamp(math.floor(dist / 4), 2, 20)
                    local currentPos = tracerStartPos
                    local lightningParts = {}
                    local tracerColor = state.TracerType == "Zap Confetti" and Color3.fromHSV(math.random(), 1, 1) or state.TracerColor
                    
                    for i = 1, segments do
                        local nextTarget = tracerStartPos:Lerp(endPos, i / segments)
                        if i < segments then
                            nextTarget = nextTarget + Vector3.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 2, (math.random() - 0.5) * 2)
                        end
                        
                        local segmentDist = (nextTarget - currentPos).Magnitude
                        if segmentDist > 0.01 then
                            local tracer = Instance.new("Part")
                            tracer.Anchored = true
                            tracer.CanCollide = false
                            tracer.CanQuery = false
                            tracer.CastShadow = false
                            tracer.Material = Enum.Material.Neon
                            tracer.Color = tracerColor
                            tracer.Size = Vector3.new(0.1, 0.1, segmentDist)
                            tracer.CFrame = CFrame.lookAt(currentPos, nextTarget) * CFrame.new(0, 0, -segmentDist / 2)
                            tracer.Parent = workspace
                            table.insert(lightningParts, tracer)
                        end
                        currentPos = nextTarget
                    end
                    
                    if state.TracerType == "Zap Confetti" then
                        local attachment = Instance.new("Attachment")
                        attachment.Position = endPos
                        attachment.Parent = workspace.Terrain
                        local impactParticles = Instance.new("ParticleEmitter")
                        impactParticles.Color = ColorSequence.new(tracerColor)
                        impactParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0)})
                        impactParticles.Lifetime = NumberRange.new(0.5, 1)
                        impactParticles.Speed = NumberRange.new(5, 15)
                        impactParticles.SpreadAngle = Vector2.new(180, 180)
                        impactParticles.Rate = 0
                        impactParticles.Parent = attachment
                        impactParticles:Emit(10)
                        task.delay(1, function() attachment:Destroy() end)
                    end
                    
                    for i = 0, 1, 0.1 do
                        for _, p in ipairs(lightningParts) do if p then p.Transparency = i end end
                        task.wait(0.02)
                    end
                    for _, p in ipairs(lightningParts) do if p then p:Destroy() end end
                
                elseif state.TracerType == "Flat Line" then
                    local tracer = Instance.new("Part")
                    tracer.Anchored = true
                    tracer.CanCollide = false
                    tracer.CanQuery = false
                    tracer.CastShadow = false
                    tracer.Material = Enum.Material.Neon
                    tracer.Color = state.TracerColor
                    tracer.Size = Vector3.new(0.1, 0.1, dist)
                    tracer.CFrame = CFrame.lookAt(tracerStartPos, endPos) * CFrame.new(0, 0, -dist / 2)
                    tracer.Parent = workspace
                    
                    for i = 0, 1, 0.05 do
                        if tracer then tracer.Transparency = i end
                        task.wait(0.02)
                    end
                    if tracer then tracer:Destroy() end
                    
                elseif state.TracerType == "Confetti Particles" or state.TracerType == "Fire Particles" then
                    local attachment = Instance.new("Attachment")
                    attachment.Position = tracerStartPos
                    attachment.Parent = workspace.Terrain
                    
                    local emitter = Instance.new("ParticleEmitter")
                    if state.TracerType == "Confetti Particles" then
                        emitter.Color = ColorSequence.new(state.TracerColor)
                        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0)})
                        -- Default roblox particle for confetti-like effect
                    else
                        emitter.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(1, 0.5, 0)),
                            ColorSequenceKeypoint.new(1, state.TracerColor)
                        })
                        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
                    end
                    
                    emitter.Lifetime = NumberRange.new(5, 10)
                    emitter.Speed = NumberRange.new(20, 50) -- Make them shoot out fast
                    emitter.SpreadAngle = Vector2.new(5, 5) -- Keep them tightly packed
                    emitter.Rate = 0
                    
                    -- Make particles emit in the direction of the bullet
                    emitter.EmissionDirection = Enum.NormalId.Front
                    emitter.Parent = attachment
                    
                    -- Calculate the direction the bullet is travelling
                    local bulletDir = (endPos - tracerStartPos).Unit
                    
                    -- Emit particles along the path rapidly
                    local steps = math.clamp(math.floor(dist / 2), 5, 50)
                    for i = 1, steps do
                        local currentSpawnPos = tracerStartPos:Lerp(endPos, i / steps)
                        
                        -- Re-orient the attachment to face the bullet's travel direction
                        attachment.CFrame = CFrame.lookAt(currentSpawnPos, currentSpawnPos + bulletDir)
                        
                        emitter:Emit(1)
                        if i % 5 == 0 then task.wait() end -- Wait only every 5 steps to make trail fast
                    end
                    
                    task.delay(10, function() attachment:Destroy() end)
                end
            end
        end)
    end
    
    return originalDischarge(self, weaponName, origin, targetDirection, muzzleCFrame)
end

-- ==========================
-- FULLBRIGHT
-- ==========================
local Lighting = game:GetService("Lighting")
table.insert(connections, RunService.RenderStepped:Connect(function()
    if state.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
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
                -- Always remove SurfaceAppearance so we can actually see the changes
                local surfaceApp = obj:FindFirstChildOfClass("SurfaceAppearance")
                if surfaceApp then
                    surfaceApp:Destroy()
                end
                
                if state.HandChams then
                    if state.HandChamsMaterial == "Glow" then
                        local hl = obj:FindFirstChild("LarpHighlight")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "LarpHighlight"
                            hl.Parent = obj
                        end
                        hl.FillColor = state.HandChamsColor
                        hl.FillTransparency = 0
                        hl.OutlineColor = state.HandChamsColor
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    else
                        local hl = obj:FindFirstChild("LarpHighlight")
                        if hl then hl:Destroy() end
                        
                        obj.Material = Enum.Material[state.HandChamsMaterial] or Enum.Material.Neon
                        obj.Color = state.HandChamsColor
                    end
                else
                    local hl = obj:FindFirstChild("LarpHighlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
    
    applyChams("SK_Gloves5A")
    applyChams("SK_ShirtSleevesB")
    applyChams("SK_RashguardSleevesA")
end))

-- ==========================
-- ENEMY CHAMS
-- ==========================
table.insert(connections, RunService.RenderStepped:Connect(function()
    local mercFolder = workspace:FindFirstChild("MercPlayers")
    if not mercFolder then return end



    local function applyChamsToPart(part, isHitbox, isGlow)
        if state.EnemyChams then
            if not isGlow then
                part.Material = Enum.Material[state.EnemyChamsMaterial] or Enum.Material.ForceField
                part.Color = state.EnemyChamsColor
            else
                part.Material = Enum.Material.SmoothPlastic
                part.Color = Color3.new(1, 1, 1)
            end
            
            if isHitbox and part.Transparency > 0.8 then
                part.Transparency = isGlow and 1 or 0.5 -- Hide hitboxes slightly, or fully if using highlight so we don't get double render
            end
        else
            if isHitbox and part.Transparency < 1 then
                part.Transparency = 1
            end
        end
    end

    for _, model in ipairs(mercFolder:GetChildren()) do
        local isHitbox = string.sub(model.Name, 1, 13) == "MercHitboxes_"
        local isVisual = string.sub(model.Name, 1, 11) == "MercVisual_"

        if isHitbox or isVisual then
            local playerName = isHitbox and string.sub(model.Name, 14) or string.sub(model.Name, 12)
            
            if playerName ~= LocalPlayer.Name then
                local isGlow = state.EnemyChams and state.EnemyChamsMaterial == "Glow"

                if isGlow then
                    local hl = model:FindFirstChild("LarpHighlight")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "LarpHighlight"
                        hl.Parent = model
                    end
                    hl.FillColor = state.EnemyChamsColor
                    hl.FillTransparency = 0
                    hl.OutlineColor = state.EnemyChamsColor
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                else
                    local hl = model:FindFirstChild("LarpHighlight")
                    if hl then hl:Destroy() end
                end

                if state.EnemyChams and isVisual then
                    -- Destroy all SurfaceAppearances (textures) on the visual model
                    for _, obj in ipairs(model:GetDescendants()) do
                        if obj:IsA("SurfaceAppearance") or obj:IsA("Texture") or obj:IsA("Decal") then
                            obj:Destroy()
                        end
                    end
                end

                -- Apply chams to parts
                for _, part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        applyChamsToPart(part, isHitbox, isGlow)
                    end
                end
            end
        end
    end
end))

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
        -- Remove Vignettes from PlayerGui
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local vignettes = playerGui:FindFirstChild("Vignettes")
            if vignettes then
                vignettes:Destroy()
            end
        end
        
        -- Remove annoying Lighting effects
        for _, effectName in ipairs(lightingEffects) do
            local effect = Lighting:FindFirstChild(effectName)
            if effect then
                effect:Destroy()
            end
        end
    end
end)

-- ==========================
-- UNLOAD FUNCTION
-- ==========================
local function unload()
    -- Disconnect all events (RenderStepped, PlayerAdded, etc.)
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    table.clear(connections)

    -- Destroy UI
    if espFolder then
        espFolder:Destroy()
    end
    
    if fovGui then
        fovGui:Destroy()
    end
    
    if Library then
        Library:Unload()
    end

    if skellyScreenGui then
        skellyScreenGui:Destroy()
    end
    
    if activeGlowChams then
        for model, data in pairs(activeGlowChams) do
            if data.ChamsModel then data.ChamsModel:Destroy() end
            if data.LOS then data.LOS:Destroy() end
            if data.OCC then data.OCC:Destroy() end
        end
        table.clear(activeGlowChams)
    end

    -- Restore original stats
    modifyWeapons(false)
    
    -- Restore BulletController
    if originalDischarge then
        BulletController.Discharge = originalDischarge
    end
end

-- Listen for the End key to unload
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.End then
            unload()
        elseif input.KeyCode == Enum.KeyCode.N then
            -- Toggle via keybind still updates the GUI if possible
            if Library and Library.Options and Library.Options.Noclip then
                local toggled = not state.Noclip
                Library.Options.Noclip:Set(toggled)
            end
            
            if not state.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
        end
    end
end))
