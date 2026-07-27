local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Execute UNC and identity checks IMMEDIATELY on load
task.spawn(function()
    local execName = "Unknown Executor"
    if type(identifyexecutor) == "function" then
        execName = identifyexecutor()
    end
    local execIdentity = "Unknown Identity"
    if type(getidentity) == "function" then
        execIdentity = getidentity()
    elseif type(getthreadidentity) == "function" then
        execIdentity = getthreadidentity()
    elseif type(getthreadcontext) == "function" then
        execIdentity = getthreadcontext()
    end
    print("==================================================")
    print("[KittyAuth] Loader Initialized!")
    print("[KittyAuth] Executor: " .. tostring(execName))
    print("[KittyAuth] Thread Identity: " .. tostring(execIdentity))
    print("[KittyAuth] Running required UNC tests...")
    
    local missing = {}
    local checks = {
        ["hookfunction"] = type(hookfunction) == "function",
        ["hookmetamethod"] = type(hookmetamethod) == "function",
        ["setnamecallmethod"] = type(setnamecallmethod) == "function",
        ["getnamecallmethod"] = type(getnamecallmethod) == "function",
        ["checkcaller"] = type(checkcaller) == "function",
        ["loadstring"] = type(loadstring) == "function",
        ["queue_on_teleport"] = type(queue_on_teleport) == "function" or type(queueonteleport) == "function"
    }
    
    local hasHttpGet = false
    pcall(function()
        if game.HttpGet or game.HttpGetAsync then hasHttpGet = true end
    end)
    checks["game.HttpGet"] = hasHttpGet

    for name, passed in pairs(checks) do
        print("- " .. name .. ": " .. tostring(passed))
        if not passed then
            table.insert(missing, name)
        end
    end
    print("==================================================")
    
    if #missing > 0 then
        Players.LocalPlayer:Kick("Unsuportted Executour")
        -- Wait a bit before returning to ensure the kick goes through and script halts
        task.wait(1)
        return
    end
end)

local FolderLocation = "KittyAuth"
if not isfolder(FolderLocation) then makefolder(FolderLocation) end
if not isfolder(FolderLocation.."\\Fonts") then makefolder(FolderLocation.."\\Fonts") end
if not isfolder(FolderLocation.."\\Icons") then makefolder(FolderLocation.."\\Icons") end

local FontsToDownload = {
    ["Zekton"] = { Link = "https://github.com/LuckyHub1/LuckyHub/raw/main/zekton_rg.ttf" }
}

for Name, Table in pairs(FontsToDownload) do
    if not isfile(FolderLocation.."\\Fonts\\"..Name..".ttf") then
        local response = request({
            Url = Table.Link,
            Method = "GET"
        })
        writefile(FolderLocation.."\\Fonts\\"..Name..".ttf", response.Body)
    end
    if not isfile(FolderLocation.."\\Fonts\\"..Name..".font") then
        local Config = {
            name  = Name,
            faces = {{
                name    = "Regular",
                weight  = 400,
                style   = "normal",
                assetId = getcustomasset(FolderLocation.."\\Fonts\\"..Name..".ttf")
            }}
        }
        writefile(FolderLocation.."\\Fonts\\"..Name..".font", HttpService:JSONEncode(Config))
    end
end

if not getgenv().Fonts then
    getgenv().Fonts = { Loaded = {} }
    for _, FontPath in ipairs(listfiles(FolderLocation.."\\Fonts")) do
        -- Support both \ and / for path matching just in case
        local Name = string.match(FontPath, "[\\/]([^\\/]+)%.font$")
        if Name then
            getgenv().Fonts.Loaded[Name] = Font.new(
                getcustomasset(FontPath),
                Enum.FontWeight.Regular
            )
        end
    end
end

local IconsToDownload = {
    ["TTK"] = { Link = "https://tr.rbxcdn.com/180DAY-cf0e1c572e4f8b648541926124e33700/768/432/Image/Webp/noFilter" },
    ["KnifeDuels"] = { Link = "https://tr.rbxcdn.com/180DAY-29270a194544af203a5f6604465e51d7/768/432/Image/Webp/noFilter" },
    ["Rost"] = { Link = "https://tr.rbxcdn.com/180DAY-f3f36d59862c9aae8379103ad348e5b1/768/432/Image/Webp/noFilter" }
}

for Name, Table in pairs(IconsToDownload) do
    if not isfile(FolderLocation.."\\Icons\\"..Name..".webp") then
        local response = request({
            Url = Table.Link,
            Method = "GET"
        })
        writefile(FolderLocation.."\\Icons\\"..Name..".webp", response.Body)
    end
end

local function ApplyFont(element, isBold)
    local loadedFont = getgenv().Fonts and getgenv().Fonts.Loaded["Zekton"]
    if loadedFont then
        element.FontFace = loadedFont
    else
        element.Font = isBold and Enum.Font.Code or Enum.Font.Code
    end
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ""
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Try to parent to CoreGui, fallback to PlayerGui if executor lacks permissions
local success, err = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

local UserInputService = game:GetService("UserInputService")
local function MakeDraggable(gui)
    gui.Active = true
    gui.Draggable = false
    
    local dragging = false
    local dragInput, mousePos, framePos
    
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
            TweenService:Create(gui, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position = newPos}):Play()
        end
    end)
end

-- Outer Frame (Linoria Style: sharp edges, multiple borders)
local OuterFrame = Instance.new("CanvasGroup")
OuterFrame.Name = ""
OuterFrame.Size = UDim2.new(0, 310, 0, 220)
OuterFrame.Position = UDim2.new(0.5, -155, 0.5, -110)
OuterFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
OuterFrame.BorderSizePixel = 1
OuterFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
OuterFrame.Parent = ScreenGui
MakeDraggable(OuterFrame)

-- Inner Frame (Inset styling)
local InnerFrame = Instance.new("Frame")
InnerFrame.Name = ""
InnerFrame.Size = UDim2.new(1, -6, 1, -6)
InnerFrame.Position = UDim2.new(0, 3, 0, 3)
InnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InnerFrame.BorderSizePixel = 1
InnerFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
InnerFrame.Parent = OuterFrame

-- Top Accent Line (Thin line for gradient animation)
local AccentLine = Instance.new("Frame")
AccentLine.Name = ""
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BorderSizePixel = 0
AccentLine.ClipsDescendants = true
AccentLine.Parent = InnerFrame

local GradientFrame = Instance.new("Frame")
GradientFrame.Name = ""
GradientFrame.Size = UDim2.new(2, 0, 1, 0)
GradientFrame.Position = UDim2.new(0, 0, 0, 0)
GradientFrame.BorderSizePixel = 0
GradientFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GradientFrame.Parent = AccentLine

-- Gamesense (Skeet) style animated top bar
local Gradient = Instance.new("UIGradient")
Gradient.Name = ""
-- Seamless repeating sequence: Pink -> Purple -> Blue -> Purple -> Pink
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 180)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(167, 76, 219)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(167, 76, 219)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 180))
})
Gradient.Parent = GradientFrame

-- Smooth seamless hardware-accelerated scroll
local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)
local tween = TweenService:Create(GradientFrame, tweenInfo, {Position = UDim2.new(-1, 0, 0, 0)})
tween:Play()

-- Dashboard Outer Frame
local DashboardOuter = Instance.new("CanvasGroup")
DashboardOuter.Name = ""
DashboardOuter.Size = UDim2.new(0, 550, 0, 350)
DashboardOuter.Position = UDim2.new(0.5, -275, 0.5, -175)
DashboardOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DashboardOuter.BorderSizePixel = 1
DashboardOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
DashboardOuter.GroupTransparency = 1
DashboardOuter.Visible = false
DashboardOuter.Parent = ScreenGui
MakeDraggable(DashboardOuter)

local DashInner = Instance.new("Frame")
DashInner.Name = ""
DashInner.Size = UDim2.new(1, -6, 1, -6)
DashInner.Position = UDim2.new(0, 3, 0, 3)
DashInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DashInner.BorderSizePixel = 1
DashInner.BorderColor3 = Color3.fromRGB(30, 30, 30)
DashInner.Parent = DashboardOuter

local DashAccent = Instance.new("Frame")
DashAccent.Name = ""
DashAccent.Size = UDim2.new(1, 0, 0, 2)
DashAccent.Position = UDim2.new(0, 0, 0, 0)
DashAccent.BorderSizePixel = 0
DashAccent.ClipsDescendants = true
DashAccent.Parent = DashInner

local DashGradFrame = Instance.new("Frame")
DashGradFrame.Name = ""
DashGradFrame.Size = UDim2.new(2, 0, 1, 0)
DashGradFrame.Position = UDim2.new(0, 0, 0, 0)
DashGradFrame.BorderSizePixel = 0
DashGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DashGradFrame.Parent = DashAccent

local DashGrad = Instance.new("UIGradient")
DashGrad.Name = ""
DashGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 180)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(167, 76, 219)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(167, 76, 219)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 180))
})
DashGrad.Parent = DashGradFrame
TweenService:Create(DashGradFrame, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {Position = UDim2.new(-1, 0, 0, 0)}):Play()

local DashTitle = Instance.new("TextLabel")
DashTitle.Name = ""
DashTitle.Size = UDim2.new(1, 0, 0, 30)
DashTitle.Position = UDim2.new(0, 10, 0, 5)
DashTitle.BackgroundTransparency = 1
DashTitle.Text = "KittyAuth | Dashboard"
DashTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
DashTitle.TextSize = 14
DashTitle.TextXAlignment = Enum.TextXAlignment.Left
ApplyFont(DashTitle, true)
DashTitle.Parent = DashInner

local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Size = UDim2.new(0, 150, 0, 20)
UsernameLabel.Position = UDim2.new(1, -160, 0, 5)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = ""
UsernameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
UsernameLabel.TextSize = 13
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Right
ApplyFont(UsernameLabel, false)
UsernameLabel.Parent = DashInner

local PFPImage = Instance.new("ImageLabel")
PFPImage.Size = UDim2.new(0, 24, 0, 24)
PFPImage.Position = UDim2.new(1, -75, 0, 8)
PFPImage.BackgroundTransparency = 0
PFPImage.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
PFPImage.Image = ""
PFPImage.Visible = true
local PFPCorner = Instance.new("UICorner")
PFPCorner.CornerRadius = UDim.new(1, 0)
PFPCorner.Parent = PFPImage
PFPImage.Parent = DashInner

local UIDLabel = Instance.new("TextLabel")
UIDLabel.Size = UDim2.new(0, 150, 0, 15)
UIDLabel.Position = UDim2.new(1, -160, 0, 25)
UIDLabel.BackgroundTransparency = 1
UIDLabel.Text = "uid   1"
UIDLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
UIDLabel.TextSize = 11
UIDLabel.TextXAlignment = Enum.TextXAlignment.Right
ApplyFont(UIDLabel, true)
UIDLabel.Parent = DashInner

local Sidebar = Instance.new("Frame")
Sidebar.Name = ""
Sidebar.Size = UDim2.new(0, 180, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 35)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Sidebar.BorderSizePixel = 1
Sidebar.BorderColor3 = Color3.fromRGB(30, 30, 30)
Sidebar.Parent = DashInner

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = Sidebar

local ContentFrame = Instance.new("CanvasGroup")
ContentFrame.Name = ""
ContentFrame.Size = UDim2.new(1, -200, 1, -45)
ContentFrame.Position = UDim2.new(0, 195, 0, 35)
ContentFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = DashInner

local SelectedTitle = Instance.new("TextLabel")
SelectedTitle.Size = UDim2.new(1, 0, 0, 25)
SelectedTitle.BackgroundTransparency = 1
SelectedTitle.Text = "Select a Game..."
SelectedTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
SelectedTitle.TextSize = 16
SelectedTitle.TextXAlignment = Enum.TextXAlignment.Left
ApplyFont(SelectedTitle, true)
SelectedTitle.Parent = ContentFrame

local UpdatesHeader = Instance.new("TextLabel")
UpdatesHeader.Size = UDim2.new(1, 0, 0, 20)
UpdatesHeader.Position = UDim2.new(0, 0, 0, 30)
UpdatesHeader.BackgroundTransparency = 1
UpdatesHeader.Text = "Updates:"
UpdatesHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
UpdatesHeader.TextSize = 13
UpdatesHeader.TextXAlignment = Enum.TextXAlignment.Left
ApplyFont(UpdatesHeader, true)
UpdatesHeader.Parent = ContentFrame

local UpdatesBox = Instance.new("Frame")
UpdatesBox.Size = UDim2.new(1, 0, 1, -95)
UpdatesBox.Position = UDim2.new(0, 0, 0, 50)
UpdatesBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
UpdatesBox.BorderSizePixel = 1
UpdatesBox.BorderColor3 = Color3.fromRGB(30, 30, 30)
UpdatesBox.Parent = ContentFrame

local UpdatesText = Instance.new("TextLabel")
UpdatesText.Size = UDim2.new(1, -10, 1, -10)
UpdatesText.Position = UDim2.new(0, 5, 0, 5)
UpdatesText.BackgroundTransparency = 1
UpdatesText.Text = "- N/A"
UpdatesText.TextColor3 = Color3.fromRGB(180, 180, 180)
UpdatesText.TextSize = 12
UpdatesText.TextXAlignment = Enum.TextXAlignment.Left
UpdatesText.TextYAlignment = Enum.TextYAlignment.Top
ApplyFont(UpdatesText, false)
UpdatesText.Parent = UpdatesBox

local LoadButton = Instance.new("TextButton")
LoadButton.Size = UDim2.new(1, 0, 0, 35)
LoadButton.Position = UDim2.new(0, 0, 1, -35)
LoadButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LoadButton.BorderSizePixel = 1
LoadButton.BorderColor3 = Color3.fromRGB(40, 40, 40)
LoadButton.Text = "Load"
LoadButton.TextColor3 = Color3.fromRGB(200, 200, 200)
LoadButton.TextSize = 13
LoadButton.AutoButtonColor = false
ApplyFont(LoadButton, true)
LoadButton.Parent = ContentFrame

LoadButton.MouseEnter:Connect(function()
    TweenService:Create(LoadButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), BorderColor3 = Color3.fromRGB(167, 76, 219), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)
LoadButton.MouseLeave:Connect(function()
    TweenService:Create(LoadButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderColor3 = Color3.fromRGB(40, 40, 40), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end)

local currentSelectedScript = nil

LoadButton.MouseButton1Click:Connect(function()
    if not currentSelectedScript then return end
    
    local placeChecks = {
        ["TTK/main.luau"] = 120189115846709,
        ["Rost/main.luau"] = 13769775130,
        ["KnifeDuels/main.luau"] = 112731528776884
    }
    
    local requiredPlaceId = placeChecks[currentSelectedScript]
    if requiredPlaceId and game.PlaceId ~= requiredPlaceId then
        game.Players.LocalPlayer:Kick("Wrong Game")
        return
    end
    
    task.spawn(function()
        local success, err = pcall(function()
            local githubScripts = {
                ["TTK/main.luau"] = "https://raw.githubusercontent.com/AJWOLF321/Kitty/refs/heads/main/TTKTesting.luau",
                ["Rost/main.luau"] = "https://raw.githubusercontent.com/AJWOLF321/Kitty/refs/heads/main/RostAlpha.luau"
            }
            local url = githubScripts[currentSelectedScript]
            local content
            if url then
                content = game:HttpGet(url .. "?t=" .. tostring(os.time()))
            else
                content = readfile(currentSelectedScript)
            end

            if content then
                loadstring(content)()
            end
        end)
        if not success then
            warn("[KittyAuth] Failed to load: " .. tostring(err))
        end
    end)
    
    local fadeOut = TweenService:Create(DashboardOuter, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {GroupTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Wait()
    ScreenGui:Destroy()
end)

local SidebarButtons = {}

local function UpdateSidebarButtons()
    for _, data in ipairs(SidebarButtons) do
        if data.ScriptPath == currentSelectedScript then
            TweenService:Create(data.Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), BorderColor3 = Color3.fromRGB(167, 76, 219)}):Play()
            TweenService:Create(data.Lbl, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(data.Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderColor3 = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(data.Lbl, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        end
    end
end

local function SelectGame(btn, name, scriptPath)
    currentSelectedScript = scriptPath
    UpdateSidebarButtons()
    SelectedTitle.Text = name
    UpdatesText.Text = "- Latest security patches\n- Optimization tweaks"
    ContentFrame.GroupTransparency = 0
end

local function createGameButton(name, iconPath, scriptPath)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 55)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 45, 0, 45)
    icon.Position = UDim2.new(0, 5, 0.5, -22.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconPath
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = btn
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 20)
    lbl.Position = UDim2.new(0, 55, 0, 7)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    ApplyFont(lbl, false)
    lbl.Parent = btn
    
    local durLbl = Instance.new("TextLabel")
    durLbl.Size = UDim2.new(1, -60, 0, 20)
    durLbl.Position = UDim2.new(0, 55, 0, 27)
    durLbl.BackgroundTransparency = 1
    durLbl.Text = getgenv().logged_in_duration or "Lifetime"
    durLbl.TextColor3 = Color3.fromRGB(167, 76, 219)
    durLbl.TextSize = 11
    durLbl.TextXAlignment = Enum.TextXAlignment.Left
    ApplyFont(durLbl, true)
    durLbl.Parent = btn
    
    table.insert(SidebarButtons, {Btn = btn, Lbl = lbl, ScriptPath = scriptPath})
    
    btn.MouseEnter:Connect(function()
        if currentSelectedScript == scriptPath then return end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), BorderColor3 = Color3.fromRGB(167, 76, 219)}):Play()
        TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if currentSelectedScript == scriptPath then return end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderColor3 = Color3.fromRGB(40, 40, 40)}):Play()
        TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end)
    
    local tabTween = nil
    btn.MouseButton1Click:Connect(function()
        if currentSelectedScript == scriptPath then return end
        currentSelectedScript = scriptPath
        UpdateSidebarButtons()
        
        if tabTween then tabTween:Cancel() end
        tabTween = TweenService:Create(ContentFrame, TweenInfo.new(0.15), {GroupTransparency = 1})
        tabTween:Play()
        tabTween.Completed:Wait()
        
        if currentSelectedScript ~= scriptPath then return end
        
        SelectedTitle.Text = name
        UpdatesText.Text = "- Latest security patches\n- Optimization tweaks"
        
        tabTween = TweenService:Create(ContentFrame, TweenInfo.new(0.15), {GroupTransparency = 0})
        tabTween:Play()
    end)
end

-- Use getcustomasset for the downloaded icons
local ttkIcon = isfile(FolderLocation.."\\Icons\\TTK.webp") and getcustomasset(FolderLocation.."\\Icons\\TTK.webp") or ""
local knifeIcon = isfile(FolderLocation.."\\Icons\\KnifeDuels.webp") and getcustomasset(FolderLocation.."\\Icons\\KnifeDuels.webp") or ""
local rostIcon = isfile(FolderLocation.."\\Icons\\Rost.webp") and getcustomasset(FolderLocation.."\\Icons\\Rost.webp") or ""

createGameButton("TTK Testing", ttkIcon, "TTK/main.luau")
createGameButton("Knife Duels", knifeIcon, "KnifeDuels/main.luau")
createGameButton("Rost Alpha", rostIcon, "Rost/main.luau")

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = ""
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KittyAuth"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
ApplyFont(TitleLabel, true)
TitleLabel.Parent = InnerFrame

-- Username TextBox Container (Input Box)
local UserOuter = Instance.new("Frame")
UserOuter.Name = ""
UserOuter.Size = UDim2.new(0, 250, 0, 30)
UserOuter.Position = UDim2.new(0.5, -125, 0, 45)
UserOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
UserOuter.BorderSizePixel = 1
UserOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
UserOuter.Parent = InnerFrame

local UserInner = Instance.new("Frame")
UserInner.Name = ""
UserInner.Size = UDim2.new(1, -2, 1, -2)
UserInner.Position = UDim2.new(0, 1, 0, 1)
UserInner.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
UserInner.BorderSizePixel = 1
UserInner.BorderColor3 = Color3.fromRGB(30, 30, 30)
UserInner.Parent = UserOuter

local UserInput = Instance.new("TextBox")
UserInput.Name = ""
UserInput.Size = UDim2.new(1, -16, 1, 0)
UserInput.Position = UDim2.new(0, 8, 0, 0)
UserInput.BackgroundTransparency = 1
UserInput.PlaceholderText = "Username"
UserInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
UserInput.Text = ""
UserInput.TextColor3 = Color3.fromRGB(240, 240, 240)
UserInput.TextSize = 13
UserInput.TextXAlignment = Enum.TextXAlignment.Left
UserInput.ClearTextOnFocus = false
ApplyFont(UserInput, false)
UserInput.Parent = UserInner

-- Password TextBox Container
local PassOuter = Instance.new("Frame")
PassOuter.Name = ""
PassOuter.Size = UDim2.new(0, 250, 0, 30)
PassOuter.Position = UDim2.new(0.5, -125, 0, 85)
PassOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
PassOuter.BorderSizePixel = 1
PassOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
PassOuter.Parent = InnerFrame

local PassInner = Instance.new("Frame")
PassInner.Name = ""
PassInner.Size = UDim2.new(1, -2, 1, -2)
PassInner.Position = UDim2.new(0, 1, 0, 1)
PassInner.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
PassInner.BorderSizePixel = 1
PassInner.BorderColor3 = Color3.fromRGB(30, 30, 30)
PassInner.Parent = PassOuter

local PassInput = Instance.new("TextBox")
PassInput.Name = ""
PassInput.Size = UDim2.new(1, -16, 1, 0)
PassInput.Position = UDim2.new(0, 8, 0, 0)
PassInput.BackgroundTransparency = 1
PassInput.PlaceholderText = "Password"
PassInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
PassInput.Text = ""
PassInput.TextColor3 = Color3.fromRGB(240, 240, 240)
PassInput.TextSize = 13
PassInput.TextXAlignment = Enum.TextXAlignment.Left
PassInput.ClearTextOnFocus = false
ApplyFont(PassInput, false)
PassInput.Parent = PassInner

-- Status Info Label
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = ""
InfoLabel.Size = UDim2.new(1, 0, 0, 15)
InfoLabel.Position = UDim2.new(0, 0, 0, 125)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = ""
InfoLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
InfoLabel.TextSize = 12
InfoLabel.Visible = false
ApplyFont(InfoLabel, true)
InfoLabel.Parent = InnerFrame

-- Authenticate Button (Flat Linoria style)
local AuthButton = Instance.new("TextButton")
AuthButton.Name = ""
AuthButton.Size = UDim2.new(0, 250, 0, 32)
AuthButton.Position = UDim2.new(0.5, -125, 0, 150)
AuthButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
AuthButton.BorderSizePixel = 1
AuthButton.BorderColor3 = Color3.fromRGB(45, 45, 45)
AuthButton.Text = "Authenticate"
AuthButton.TextColor3 = Color3.fromRGB(200, 200, 200)
AuthButton.TextSize = 13
AuthButton.AutoButtonColor = false
ApplyFont(AuthButton, true)
AuthButton.Parent = InnerFrame

-- Button Hover Styling
AuthButton.MouseEnter:Connect(function()
    TweenService:Create(AuthButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderColor3 = Color3.fromRGB(167, 76, 219) -- Accent color highlight on hover
    }):Play()
end)

AuthButton.MouseLeave:Connect(function()
    TweenService:Create(AuthButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BorderColor3 = Color3.fromRGB(45, 45, 45)
    }):Play()
end)

-- Function to handle authentication
local authSequence = 0

local function authenticate()
    local user = UserInput.Text
    local pass = PassInput.Text
    
    local hwid = "UNKNOWN"
    if gethwid then
        hwid = gethwid()
    elseif rbx_gethwid then
        hwid = rbx_gethwid()
    end
    
    authSequence = authSequence + 1
    local currentSeq = authSequence
    
    local reqData = {
        Url = "http://78.108.218.106:8119/auth",
        Method = "POST",
        Timeout = 5,
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            username = user,
            password = pass,
            hwid = hwid
        })
    }
    
    local success, response = pcall(function()
        return request(reqData)
    end)
    
    local authSuccess = false
    local returnedUID = "unknown"
    local returnedDuration = "Lifetime"
    local returnedDiscordUser = nil
    local returnedAvatar = ""
    local returnedGame = ""
    
    if success and response.StatusCode == 200 then
        local decoded = HttpService:JSONDecode(response.Body)
        if decoded.success then
            authSuccess = true
            returnedUID = tostring(decoded.uid)
            returnedDuration = decoded.duration
            returnedDiscordUser = decoded.discord_username or user
            returnedAvatar = decoded.discord_avatar or ""
            returnedGame = decoded.game or ""
        else
            if decoded.message == "Incorrect HWID" then
                game.Players.LocalPlayer:Kick("Incorrect HWID")
                return
            end
        end
    end
    
    if authSuccess then
        InfoLabel.TextTransparency = 0
        InfoLabel.Visible = true
        InfoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        InfoLabel.Text = "Success"
        
        getgenv().logged_in_duration = returnedDuration
        
        task.spawn(function()
            task.wait(1)
            if currentSeq ~= authSequence then return end
            
            UsernameLabel.Text = returnedDiscordUser or user
            
            local gameMapping = {
                ["TTKTESTING"] = "TTK Testing",
                ["KnifeDuels"] = "Knife Duels",
                ["RostAlpha"] = "Rost Alpha"
            }
            local allowedGameName = gameMapping[returnedGame]
            
            for _, data in ipairs(SidebarButtons) do
                if allowedGameName and data.Lbl.Text ~= allowedGameName then
                    data.Btn.Visible = false
                else
                    data.Btn.Visible = true
                    if allowedGameName then
                        SelectGame(data.Btn, data.Lbl.Text, data.ScriptPath)
                    end
                end
            end
            UpdateSidebarButtons()
            
            if returnedAvatar ~= "" then
                task.spawn(function()
                    local s, imgRes = pcall(function()
                        return request({Url = returnedAvatar, Method = "GET"})
                    end)
                    if s and imgRes.StatusCode == 200 then
                        local fileName = "discord_pfp_" .. tostring(returnedUID) .. ".png"
                        if writefile and getcustomasset then
                            pcall(function()
                                writefile(fileName, imgRes.Body)
                            end)
                            task.wait(0.2)
                            local assetS, assetRes = pcall(function()
                                return getcustomasset(fileName)
                            end)
                            if assetS then
                                PFPImage.Image = assetRes
                            else
                                warn("[KittyAuth] Failed to load getcustomasset: " .. tostring(assetRes))
                            end
                        end
                    end
                end)
            end
            UIDLabel.Text = "uid   " .. returnedUID
            
            -- Update durations on the dashboard buttons
            for _, data in ipairs(SidebarButtons) do
                local durLbl = data.Btn:FindFirstChild("TextLabel", true) -- We'll need to grab the duration specifically if we want to update it post-creation, but since createGameButton runs after, we just update it globally first. Actually wait, they are already created. Let's just find the second textlabel.
                local textLabels = {}
                for _, child in ipairs(data.Btn:GetChildren()) do
                    if child:IsA("TextLabel") then table.insert(textLabels, child) end
                end
                if #textLabels >= 2 then
                    textLabels[2].Text = returnedDuration
                end
            end
            
            TweenService:Create(OuterFrame, TweenInfo.new(0.5), {GroupTransparency = 1}):Play()
            task.wait(0.5)
            OuterFrame.Visible = false
            
            -- Show Dashboard
            DashboardOuter.Visible = true
            TweenService:Create(DashboardOuter, TweenInfo.new(0.5), {GroupTransparency = 0}):Play()
        end)
    else
        InfoLabel.TextTransparency = 0
        InfoLabel.Visible = true
        InfoLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        InfoLabel.Text = "Wrong Credientals"
        
        task.spawn(function()
            task.wait(1)
            if currentSeq ~= authSequence then return end
            
            local fadeTween = TweenService:Create(InfoLabel, TweenInfo.new(0.5), {TextTransparency = 1})
            fadeTween:Play()
            fadeTween.Completed:Wait()
            
            if currentSeq == authSequence then
                InfoLabel.Visible = false
            end
        end)
    end
end

AuthButton.MouseButton1Click:Connect(authenticate)
UserInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        PassInput:CaptureFocus()
    end
end)
PassInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        authenticate()
    end
end)
