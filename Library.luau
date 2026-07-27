local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Font Setup
local FolderLocation = "KittyAuth"
if not isfolder(FolderLocation) then makefolder(FolderLocation) end
if not isfolder(FolderLocation.."\\Fonts") then makefolder(FolderLocation.."\\Fonts") end

local FontsToDownload = {
    ["Zekton"] = { Link = "https://github.com/LuckyHub1/LuckyHub/raw/main/zekton_rg.ttf" }
}

for Name, Table in pairs(FontsToDownload) do
    if not isfile(FolderLocation.."\\Fonts\\"..Name..".ttf") then
        local response = request({Url = Table.Link, Method = "GET"})
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
        local Name = string.match(FontPath, "[\\/]([^\\/]+)%.font$")
        if Name then
            getgenv().Fonts.Loaded[Name] = Font.new(
                getcustomasset(FontPath),
                Enum.FontWeight.Regular
            )
        end
    end
end

local function ApplyFont(GuiObject)
    if getgenv().Fonts.Loaded["Zekton"] then
        GuiObject.FontFace = getgenv().Fonts.Loaded["Zekton"]
    else
        GuiObject.Font = Enum.Font.Code
    end
end

local Library = {}
Library.Toggled = true
Library.Keybinds = {}
Library.ActiveKeybinds = {}
Library.Flags = {}
Library.Options = {}
Library.OnTabChange = Instance.new("BindableEvent")
Library.Theme = {
    Accent = Color3.fromRGB(167, 76, 219),
    Main = Color3.fromRGB(10, 10, 10),
    Background = Color3.fromRGB(15, 15, 15),
    Text = Color3.fromRGB(255, 255, 255)
}
Library.ThemeObjects = {Accent = {}, Main = {}, Background = {}, Text = {}}
function Library:GetColorPlus(color, mult)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.clamp(v + (0.02 * (mult or 1)), 0, 1))
end

function Library:SetTheme(themeType, color, alpha)
    alpha = alpha or 1
    local trans = 1 - alpha
    Library.Theme[themeType] = color
    local colorPlus1 = Library:GetColorPlus(color, 1)
    local colorPlus2 = Library:GetColorPlus(color, 2)
    local h, s, v = Color3.toHSV(color)

    for _, obj in ipairs(Library.ThemeObjects[themeType]) do
        if obj.Type == 'BackgroundColor3' then 
            pcall(function() obj.Inst.BackgroundColor3 = color end)
        elseif obj.Type == 'BackgroundColor3+1' then 
            pcall(function() obj.Inst.BackgroundColor3 = colorPlus1 end)
        elseif obj.Type == 'BackgroundColor3+2' then 
            pcall(function() obj.Inst.BackgroundColor3 = colorPlus2 end)
        elseif obj.Type == 'TextColor3' then pcall(function() obj.Inst.TextColor3 = color end)
        elseif obj.Type == 'BorderColor3' then pcall(function() obj.Inst.BorderColor3 = color end)
        elseif obj.Type == 'Gradient' then
            pcall(function()
                local shiftedColor = Color3.fromHSV((h + 0.08) % 1, math.clamp(s + 0.1, 0, 1), v)
                obj.Inst.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, color),
                    ColorSequenceKeypoint.new(0.25, shiftedColor),
                    ColorSequenceKeypoint.new(0.5, color),
                    ColorSequenceKeypoint.new(0.75, shiftedColor),
                    ColorSequenceKeypoint.new(1, color)
                })
            end)
        elseif obj.Type == 'Custom' then
            pcall(function() obj.Inst(color, alpha) end)
        end
    end
end
function Library:RegisterTheme(inst, themeType, propType)
    table.insert(Library.ThemeObjects[themeType], {Inst = inst, Type = propType})
    local color = Library.Theme[themeType]
    local h, s, v = Color3.toHSV(color)
    local colorPlus1 = Color3.fromHSV(h, s, math.clamp(v + 0.02, 0, 1))
    local colorPlus2 = Color3.fromHSV(h, s, math.clamp(v + 0.04, 0, 1))

    if propType == 'BackgroundColor3' then pcall(function() inst.BackgroundColor3 = color end)
    elseif propType == 'BackgroundColor3+1' then pcall(function() inst.BackgroundColor3 = colorPlus1 end)
    elseif propType == 'BackgroundColor3+2' then pcall(function() inst.BackgroundColor3 = colorPlus2 end)
    elseif propType == 'TextColor3' then pcall(function() inst.TextColor3 = color end)
    elseif propType == 'BorderColor3' then pcall(function() inst.BorderColor3 = color end)
    elseif propType == 'Gradient' then
        pcall(function()
            local shiftedColor = Color3.fromHSV((h + 0.08) % 1, math.clamp(s + 0.1, 0, 1), v)
            inst.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, color),
                ColorSequenceKeypoint.new(0.25, shiftedColor),
                ColorSequenceKeypoint.new(0.5, color),
                ColorSequenceKeypoint.new(0.75, shiftedColor),
                ColorSequenceKeypoint.new(1, color)
            })
        end)
    elseif propType == 'Custom' then
        pcall(function() inst(color, 1) end)
    end
end


-- ========================
-- DRAG SYSTEM
-- ========================
local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPosition = false, nil, nil, nil
    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        TweenService:Create(object, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {Position = pos}):Play()
    end
    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then Update(input) end
    end)
end

-- ========================
-- GRADIENT HELPER
-- ========================
local function CreateAnimatedGradientBar(parent)
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.Position = UDim2.new(0, 0, 0, 0)
    AccentLine.BorderSizePixel = 0
    AccentLine.ClipsDescendants = true
    AccentLine.Parent = parent

    local GradientFrame = Instance.new("Frame")
    GradientFrame.Size = UDim2.new(2, 0, 1, 0)
    GradientFrame.Position = UDim2.new(0, 0, 0, 0)
    GradientFrame.BorderSizePixel = 0
    GradientFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GradientFrame.Parent = AccentLine

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 180)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(167, 76, 219)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(167, 76, 219)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 180))
    })
    Gradient.Parent = GradientFrame

    local tween = TweenService:Create(GradientFrame, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(-1, 0, 0, 0)})
    tween:Play()

    return AccentLine, Gradient
end

-- ========================
-- CREATE WINDOW
-- ========================
function Library:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "UI Library"

    -- Destroy old UI
    if CoreGui:FindFirstChild("KittyUI") then CoreGui.KittyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = ""
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Library.GUI = ScreenGui
    ScreenGui.IgnoreGuiInset = true

    local OuterFrame = Instance.new("Frame")
    OuterFrame.Name = "OuterFrame"
    OuterFrame.Size = UDim2.new(0, 600, 0, 500)
    OuterFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    OuterFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    OuterFrame.BorderSizePixel = 1
    OuterFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
    OuterFrame.Parent = ScreenGui

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Size = UDim2.new(1, -2, 1, -2)
    InnerFrame.Position = UDim2.new(0, 1, 0, 1)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    InnerFrame.BorderSizePixel = 1
    InnerFrame.BorderColor3 = Color3.fromRGB(35, 35, 35)
    InnerFrame.Parent = OuterFrame

    local OuterBorder = Instance.new("Frame")
    OuterBorder.Name = "OuterBorder"
    OuterBorder.Size = UDim2.new(1, -12, 1, -12)
    OuterBorder.Position = UDim2.new(0, 6, 0, 6)
    OuterBorder.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    OuterBorder.BorderSizePixel = 1
    OuterBorder.BorderColor3 = Color3.fromRGB(30, 30, 30)
    OuterBorder.Parent = InnerFrame

    local MainBg = Instance.new("Frame")
    MainBg.Name = "MainBg"
    MainBg.Size = UDim2.new(1, -2, 1, -2)
    MainBg.Position = UDim2.new(0, 1, 0, 1)
    MainBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainBg.BorderSizePixel = 0
    MainBg.Parent = OuterBorder

    -- Top gradient bar (Skeet style 1px line)
    local accentLine, gradient = CreateAnimatedGradientBar(MainBg)
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    Library:RegisterTheme(gradient, "Accent", "Gradient")

    -- Topbar (draggable)
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = MainBg
    Topbar.BackgroundTransparency = 1
    Topbar.Position = UDim2.new(0, 0, 0, 1)
    Topbar.Size = UDim2.new(1, 0, 0, 20)
    Topbar.BorderSizePixel = 0
    MakeDraggable(Topbar, OuterFrame)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Topbar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 5, 0, 0)
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 12
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ApplyFont(TitleLabel)

    Library:RegisterTheme(MainBg, "Background", "BackgroundColor3")
    Library:RegisterTheme(TitleLabel, "Text", "TextColor3")

    -- TabBar (Top Tabs, Skeet style)
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = MainBg
    TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TabBar.BackgroundTransparency = 1
    TabBar.Position = UDim2.new(0, 6, 0, 22)
    TabBar.Size = UDim2.new(1, -12, 0, 20)
    TabBar.BorderSizePixel = 0

    local TabBarList = Instance.new("UIListLayout")
    TabBarList.Parent = TabBar
    TabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabBarList.FillDirection = Enum.FillDirection.Horizontal
    TabBarList.SortOrder = Enum.SortOrder.LayoutOrder
    TabBarList.Padding = UDim.new(0, 2)

    -- Tab container background line
    local TabBarLine = Instance.new("Frame")
    TabBarLine.Name = "TabBarLine"
    TabBarLine.Parent = MainBg
    TabBarLine.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TabBarLine.Position = UDim2.new(0, 6, 0, 42)
    TabBarLine.Size = UDim2.new(1, -12, 0, 1)
    TabBarLine.BorderSizePixel = 0

    -- Main container (holds left and right columns)
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Parent = MainBg
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0, 6, 0, 50)
    Container.Size = UDim2.new(1, -12, 1, -56)
    Container.BorderSizePixel = 0
    -- Resize Handle
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Parent = OuterFrame
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Position = UDim2.new(1, -22, 1, -22)
    ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
    ResizeHandle.Text = "◢"
    ResizeHandle.TextColor3 = Color3.fromRGB(150, 150, 150)
    ResizeHandle.TextSize = 18
    ResizeHandle.ZIndex = 100
    ApplyFont(ResizeHandle)

    ResizeHandle.MouseEnter:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.2), {TextColor3 = Library.Theme.Accent}):Play()
    end)
    ResizeHandle.MouseLeave:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end)
    
    local draggingResize = false
    local dragStartPos = nil
    local startSize = nil

    ResizeHandle.MouseButton1Down:Connect(function()
        draggingResize = true
        dragStartPos = UserInputService:GetMouseLocation()
        startSize = OuterFrame.AbsoluteSize
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingResize and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mp = UserInputService:GetMouseLocation()
            local delta = mp - dragStartPos
            local newWidth = math.max(600, startSize.X + delta.X)
            local newHeight = math.max(500, startSize.Y + delta.Y)
            OuterFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingResize = false
        end
    end)

    -- Insert toggle
    Library.ToggleKey = Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Toggled = not Library.Toggled
            OuterFrame.Visible = Library.Toggled
        end
    end)

    -- ========================
    -- KEYBINDS LIST (draggable side panel)
    -- ========================
    local KeybindList = Instance.new("Frame")
    KeybindList.Name = "KeybindList"
    KeybindList.Parent = ScreenGui
    KeybindList.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    KeybindList.Position = UDim2.new(0, 20, 0.5, 0)
    KeybindList.Size = UDim2.new(0, 180, 0, 25)
    KeybindList.BorderSizePixel = 1
    KeybindList.BorderColor3 = Color3.fromRGB(40, 40, 40)
    KeybindList.ClipsDescendants = true
    KeybindList.Visible = false
    MakeDraggable(KeybindList, KeybindList)
    Library.KeybindList = KeybindList
    
    local keybindLine, keybindGradient = CreateAnimatedGradientBar(KeybindList)
    Library:RegisterTheme(keybindGradient, "Accent", "Gradient")

    local KeybindListTitle = Instance.new("TextLabel")
    KeybindListTitle.Parent = KeybindList
    KeybindListTitle.BackgroundTransparency = 1
    KeybindListTitle.Position = UDim2.new(0, 0, 0, 2)
    KeybindListTitle.Size = UDim2.new(1, 0, 0, 23)
    KeybindListTitle.Text = "Keybinds"
    KeybindListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindListTitle.TextSize = 13
    ApplyFont(KeybindListTitle)
    
    Library:RegisterTheme(KeybindList, "Background", "BackgroundColor3")
    Library:RegisterTheme(KeybindListTitle, "Text", "TextColor3")

    local KeybindContainer = Instance.new("Frame")
    KeybindContainer.Parent = KeybindList
    KeybindContainer.BackgroundTransparency = 1
    KeybindContainer.Position = UDim2.new(0, 0, 0, 25)
    KeybindContainer.Size = UDim2.new(1, 0, 1, -25)
    KeybindContainer.ZIndex = 3

    local KeybindLayout = Instance.new("UIListLayout")
    KeybindLayout.Parent = KeybindContainer
    KeybindLayout.SortOrder = Enum.SortOrder.LayoutOrder
    KeybindLayout.Padding = UDim.new(0, 2)

    -- ========================
    -- CONTEXT MENU (Fatality-style keybind) - Uses backdrop approach
    -- ========================
    local Backdrop = Instance.new("TextButton")
    Backdrop.Name = ""
    Backdrop.Parent = ScreenGui
    Backdrop.BackgroundTransparency = 1
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.Text = ""
    Backdrop.ZIndex = 90
    Backdrop.Visible = false
    Backdrop.AutoButtonColor = false

    local ContextMenu = Instance.new("Frame")
    ContextMenu.Name = "ContextMenu"
    ContextMenu.Parent = Backdrop
    ContextMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ContextMenu.Size = UDim2.new(0, 200, 0, 55)
    ContextMenu.Position = UDim2.new(0, 0, 0, 0)
    ContextMenu.BorderSizePixel = 1
    ContextMenu.BorderColor3 = Color3.fromRGB(40, 40, 40)
    ContextMenu.ZIndex = 100

    local function CloseContextMenu()
        Backdrop.Visible = false
    end

    Backdrop.MouseButton1Click:Connect(CloseContextMenu)

    local function ShowContextMenu(pos, elementData)
        -- Clear old children
        for _, v in ipairs(ContextMenu:GetChildren()) do
            v:Destroy()
        end

        ContextMenu.Position = UDim2.new(0, pos.X, 0, pos.Y)
        ContextMenu.Size = UDim2.new(0, 200, 0, 55)
        Backdrop.Visible = true

        -- Title row
        local TitleRow = Instance.new("TextLabel")
        TitleRow.Parent = ContextMenu
        TitleRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        TitleRow.Size = UDim2.new(1, 0, 0, 20)
        TitleRow.Position = UDim2.new(0, 0, 0, 0)
        TitleRow.Text = "  " .. elementData.Name
        TitleRow.TextColor3 = Color3.fromRGB(167, 76, 219)
        TitleRow.TextSize = 12
        TitleRow.TextXAlignment = Enum.TextXAlignment.Left
        TitleRow.BorderSizePixel = 0
        TitleRow.ZIndex = 101
        ApplyFont(TitleRow)

        -- Keybind row: [+ button] [key box] [mode dropdown]
        local BindRow = Instance.new("Frame")
        BindRow.Parent = ContextMenu
        BindRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        BindRow.Size = UDim2.new(1, 0, 0, 30)
        BindRow.Position = UDim2.new(0, 0, 0, 22)
        BindRow.BorderSizePixel = 0
        BindRow.ZIndex = 101

        -- Check if keybind already exists
        local existingBind = Library.Keybinds[elementData.Id]

        -- The "+" / "-" button on the left
        local PlusBtn = Instance.new("TextButton")
        PlusBtn.Parent = BindRow
        PlusBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        PlusBtn.Size = UDim2.new(0, 25, 0, 22)
        PlusBtn.Position = UDim2.new(0, 5, 0, 4)
        PlusBtn.Text = existingBind and "-" or "+"
        PlusBtn.TextColor3 = Color3.fromRGB(167, 76, 219)
        PlusBtn.TextSize = 16
        PlusBtn.BorderSizePixel = 1
        PlusBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
        PlusBtn.ZIndex = 102
        PlusBtn.AutoButtonColor = false
        ApplyFont(PlusBtn)

        -- Key display box
        local KeyBox = Instance.new("TextButton")
        KeyBox.Parent = BindRow
        KeyBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        KeyBox.Size = UDim2.new(0, 60, 0, 22)
        KeyBox.Position = UDim2.new(0, 35, 0, 4)
        KeyBox.Text = existingBind and existingBind.Key.Name or "..."
        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyBox.TextSize = 12
        KeyBox.BorderSizePixel = 1
        KeyBox.BorderColor3 = Color3.fromRGB(40, 40, 40)
        KeyBox.ZIndex = 102
        KeyBox.AutoButtonColor = false
        KeyBox.Visible = existingBind ~= nil
        ApplyFont(KeyBox)

        -- Mode dropdown button
        local ModeBtn = Instance.new("TextButton")
        ModeBtn.Parent = BindRow
        ModeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        ModeBtn.Size = UDim2.new(0, 90, 0, 22)
        ModeBtn.Position = UDim2.new(0, 100, 0, 4)
        ModeBtn.Text = existingBind and existingBind.Mode or "Toggle"
        ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ModeBtn.TextSize = 12
        ModeBtn.BorderSizePixel = 1
        ModeBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
        ModeBtn.ZIndex = 102
        ModeBtn.AutoButtonColor = false
        ModeBtn.Visible = existingBind ~= nil
        ApplyFont(ModeBtn)

        local selectedKey = existingBind and existingBind.Key or nil
        local selectedMode = existingBind and existingBind.Mode or "Toggle"

        local function SaveKeybind()
            if selectedKey then
                Library.Keybinds[elementData.Id] = {Key = selectedKey, Mode = selectedMode, Data = elementData}
            end
        end

        -- Plus button: create or remove keybind
        PlusBtn.MouseButton1Click:Connect(function()
            if KeyBox.Visible then
                -- Remove keybind
                Library.Keybinds[elementData.Id] = nil
                KeyBox.Visible = false
                ModeBtn.Visible = false
                PlusBtn.Text = "+"
                selectedKey = nil
            else
                -- Show keybind creation
                KeyBox.Visible = true
                ModeBtn.Visible = true
                PlusBtn.Text = "-"
                KeyBox.Text = "..."
                KeyBox.TextColor3 = Color3.fromRGB(167, 76, 219)

                -- Wait for key press
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            conn:Disconnect()
                            KeyBox.Text = "..."
                            KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                            return
                        end
                        conn:Disconnect()
                        selectedKey = input.KeyCode
                        KeyBox.Text = input.KeyCode.Name
                        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                        SaveKeybind()
                    end
                end)
            end
        end)

        -- Click key box to rebind
        KeyBox.MouseButton1Click:Connect(function()
            KeyBox.Text = "..."
            KeyBox.TextColor3 = Color3.fromRGB(167, 76, 219)

            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        conn:Disconnect()
                        KeyBox.Text = selectedKey and selectedKey.Name or "..."
                        KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                        return
                    end
                    conn:Disconnect()
                    selectedKey = input.KeyCode
                    KeyBox.Text = input.KeyCode.Name
                    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SaveKeybind()
                end
            end)
        end)

        -- Mode dropdown: expands to show Toggle/Hold/Always
        local modes = {"Toggle", "Hold", "Always"}
        local modeDropOpen = false

        -- Mode items container (sits below ModeBtn)
        local ModeItemsFrame = Instance.new("Frame")
        ModeItemsFrame.Parent = ContextMenu
        ModeItemsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        ModeItemsFrame.Size = UDim2.new(0, 90, 0, #modes * 20)
        ModeItemsFrame.Position = UDim2.new(0, 100, 0, 52)
        ModeItemsFrame.BorderSizePixel = 1
        ModeItemsFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
        ModeItemsFrame.ZIndex = 110
        ModeItemsFrame.Visible = false

        local ModeItemList = Instance.new("UIListLayout")
        ModeItemList.Parent = ModeItemsFrame
        ModeItemList.SortOrder = Enum.SortOrder.LayoutOrder

        for _, m in ipairs(modes) do
            local mItem = Instance.new("TextButton")
            mItem.Parent = ModeItemsFrame
            mItem.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            mItem.Size = UDim2.new(1, 0, 0, 20)
            mItem.Text = m
            mItem.TextColor3 = Color3.fromRGB(255, 255, 255)
            mItem.TextSize = 12
            mItem.BorderSizePixel = 0
            mItem.ZIndex = 111
            mItem.AutoButtonColor = false
            mItem.Font = Enum.Font.Code
            ApplyFont(mItem)

            mItem.MouseEnter:Connect(function()
                mItem.TextColor3 = Color3.fromRGB(167, 76, 219)
            end)
            mItem.MouseLeave:Connect(function()
                mItem.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)

            mItem.MouseButton1Click:Connect(function()
                selectedMode = m
                ModeBtn.Text = m
                ModeItemsFrame.Visible = false
                modeDropOpen = false
                ContextMenu.Size = UDim2.new(0, 200, 0, 55)
                SaveKeybind()
            end)
        end

        ModeBtn.MouseButton1Click:Connect(function()
            modeDropOpen = not modeDropOpen
            ModeItemsFrame.Visible = modeDropOpen
            if modeDropOpen then
                ContextMenu.Size = UDim2.new(0, 200, 0, 55 + (#modes * 20))
            else
                ContextMenu.Size = UDim2.new(0, 200, 0, 55)
            end
        end)
    end

    -- Global keybind handler
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for id, bind in pairs(Library.Keybinds) do
                if input.KeyCode == bind.Key then
                    if bind.Mode == "Toggle" then
                        bind.Data.Callback("toggle")
                    elseif bind.Mode == "Hold" then
                        Library.ActiveKeybinds[id] = true
                        bind.Data.Callback("hold_start")
                    end
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for id, bind in pairs(Library.Keybinds) do
                if input.KeyCode == bind.Key and bind.Mode == "Hold" then
                    Library.ActiveKeybinds[id] = nil
                    bind.Data.Callback("hold_end")
                end
            end
        end
    end)

    -- Keybind list updater + Always mode
    local lastActiveCount = -1
    RunService.RenderStepped:Connect(function()
        for id, bind in pairs(Library.Keybinds) do
            if bind.Mode == "Always" then
                bind.Data.Callback("always")
            end
        end

        local activeBinds = {}
        for id, bind in pairs(Library.Keybinds) do
            table.insert(activeBinds, {Id = id, Bind = bind})
        end

        if #activeBinds ~= lastActiveCount then
            lastActiveCount = #activeBinds
            -- Rebuild keybind list UI
            for _, v in ipairs(KeybindContainer:GetChildren()) do
                if v:IsA("TextLabel") then v:Destroy() end
            end

            for _, item in ipairs(activeBinds) do
                local bind = item.Bind
                local lbl = Instance.new("TextLabel")
                lbl.Parent = KeybindContainer
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.Text = "  " .. tostring(bind.Data.Name) .. " [" .. tostring(bind.Key.Name) .. "]"
                lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 3
                lbl.Font = Enum.Font.Code
                pcall(function() ApplyFont(lbl) end)
            end
            KeybindList.Size = UDim2.new(0, 180, 0, 25 + (#activeBinds * 20))
        else
            -- Just update text to avoid font reloading bugs
            local idx = 1
            for _, v in ipairs(KeybindContainer:GetChildren()) do
                if v:IsA("TextLabel") and activeBinds[idx] then
                    local item = activeBinds[idx]
                    local bind = item.Bind
                    
                    local isActive = false
                    if bind.Mode == "Always" then
                        isActive = true
                    elseif bind.Mode == "Hold" then
                        isActive = Library.ActiveKeybinds[item.Id]
                    elseif bind.Mode == "Toggle" then
                        if bind.Data.GetState then
                            isActive = bind.Data.GetState()
                        end
                    end
                    
                    v.Text = "  " .. tostring(bind.Data.Name) .. " [" .. tostring(bind.Key.Name) .. "]"
                    v.TextColor3 = isActive and Library.Theme.Accent or Library.Theme.Text
                    idx = idx + 1
                end
            end
        end
    end)

    -- ========================
    -- WINDOW OBJECT
    -- ========================
    local WindowObj = {
        CurrentTab = nil,
        Tabs = {}
    }

    function WindowObj:CreateTab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name.."_Btn"
        TabBtn.Parent = TabBar
        TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        TabBtn.BackgroundTransparency = 0
        TabBtn.Size = UDim2.new(0, 70, 1, 0)
        TabBtn.Text = name
        TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabBtn.TextSize = 12
        TabBtn.BorderSizePixel = 1
        TabBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
        TabBtn.AutoButtonColor = false
        ApplyFont(TabBtn)
        
        -- The Accent line at the top of the tab
        local TabAccent = Instance.new("Frame")
        TabAccent.Name = "TabAccent"
        TabAccent.Parent = TabBtn
        TabAccent.Size = UDim2.new(1, 0, 0, 1)
        TabAccent.Position = UDim2.new(0, 0, 0, 0)
        TabAccent.BorderSizePixel = 0
        TabAccent.Visible = false
        Library:RegisterTheme(TabAccent, "Accent", "BackgroundColor3")

        -- To hide the bottom border when active (creates the illusion of merging with the container)
        local BottomCover = Instance.new("Frame")
        BottomCover.Name = "BottomCover"
        BottomCover.Parent = TabBtn
        BottomCover.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        BottomCover.Size = UDim2.new(1, 0, 0, 2)
        BottomCover.Position = UDim2.new(0, 0, 1, 0)
        BottomCover.BorderSizePixel = 0
        BottomCover.Visible = false

        -- Tab page is a frame that holds LEFT and RIGHT columns
        local TabPage = Instance.new("Frame")
        TabPage.Name = name.."_Page"
        TabPage.Parent = Container
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.Visible = false

        -- Left column
        local LeftColumn = Instance.new("ScrollingFrame")
        LeftColumn.Name = "LeftColumn"
        LeftColumn.Parent = TabPage
        LeftColumn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        LeftColumn.Position = UDim2.new(0, 0, 0, 0)
        LeftColumn.Size = UDim2.new(0.5, -3, 1, 0)
        LeftColumn.BorderSizePixel = 1
        LeftColumn.BorderColor3 = Color3.fromRGB(30, 30, 30)
        LeftColumn.ScrollBarThickness = 2
        LeftColumn.ScrollBarImageColor3 = Color3.fromRGB(167, 76, 219)
        LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftColumn.Active = true

        local LeftList = Instance.new("UIListLayout")
        LeftList.Parent = LeftColumn
        LeftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        LeftList.SortOrder = Enum.SortOrder.LayoutOrder
        LeftList.Padding = UDim.new(0, 5)

        local LeftPadding = Instance.new("UIPadding")
        LeftPadding.Parent = LeftColumn
        LeftPadding.PaddingTop = UDim.new(0, 5)
        LeftPadding.PaddingBottom = UDim.new(0, 5)

        LeftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            LeftColumn.CanvasSize = UDim2.new(0, 0, 0, LeftList.AbsoluteContentSize.Y + 10)
        end)
        Library:RegisterTheme(LeftColumn, "Background", "BackgroundColor3+1")

        -- Right column
        local RightColumn = Instance.new("ScrollingFrame")
        RightColumn.Name = "RightColumn"
        RightColumn.Parent = TabPage
        RightColumn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        RightColumn.Position = UDim2.new(0.5, 3, 0, 0)
        RightColumn.Size = UDim2.new(0.5, -3, 1, 0)
        RightColumn.BorderSizePixel = 1
        RightColumn.BorderColor3 = Color3.fromRGB(30, 30, 30)
        RightColumn.ScrollBarThickness = 2
        RightColumn.ScrollBarImageColor3 = Color3.fromRGB(167, 76, 219)
        RightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightColumn.Active = true

        local RightList = Instance.new("UIListLayout")
        RightList.Parent = RightColumn
        RightList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Padding = UDim.new(0, 5)

        local RightPadding = Instance.new("UIPadding")
        RightPadding.Parent = RightColumn
        RightPadding.PaddingTop = UDim.new(0, 5)
        RightPadding.PaddingBottom = UDim.new(0, 5)

        RightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            RightColumn.CanvasSize = UDim2.new(0, 0, 0, RightList.AbsoluteContentSize.Y + 10)
        end)
        Library:RegisterTheme(RightColumn, "Background", "BackgroundColor3+1")

        -- Sub-tabs bar at the top of the tab page
        local SubTabBar = Instance.new("Frame")
        SubTabBar.Name = "SubTabBar"
        SubTabBar.Parent = TabPage
        SubTabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        SubTabBar.Position = UDim2.new(0, 0, 0, 0)
        SubTabBar.Size = UDim2.new(1, 0, 0, 0) -- starts hidden, grows when subtabs are added
        SubTabBar.BorderSizePixel = 1
        SubTabBar.BorderColor3 = Color3.fromRGB(30, 30, 30)
        SubTabBar.Visible = false

        local SubTabBarList = Instance.new("UIListLayout")
        SubTabBarList.Parent = SubTabBar
        SubTabBarList.FillDirection = Enum.FillDirection.Horizontal
        SubTabBarList.SortOrder = Enum.SortOrder.LayoutOrder
        SubTabBarList.Padding = UDim.new(0, 0)

        table.insert(WindowObj.Tabs, {Btn = TabBtn, Page = TabPage})
        
        -- Tab switching
        Library.OnTabChange.Event:Connect(function()
            if WindowObj.CurrentTab ~= name then
                TabPage.Visible = false
                TabBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                TabAccent.Visible = false
                BottomCover.Visible = false
            end
        end)

        TabBtn.MouseButton1Click:Connect(function()
            WindowObj.CurrentTab = name
            Library.OnTabChange:Fire()
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            TabBtn.TextColor3 = Library.Theme.Accent
            TabAccent.Visible = true
            BottomCover.Visible = true
        end)

        if #WindowObj.Tabs == 1 then
            WindowObj.CurrentTab = name
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            TabBtn.TextColor3 = Library.Theme.Accent
            TabAccent.Visible = true
            BottomCover.Visible = true
        end
        
        Library:RegisterTheme(function(color)
            if WindowObj.CurrentTab == name then
                TabBtn.TextColor3 = color
            end
        end, "Accent", "Custom")

        -- ========================
        -- TAB API
        -- ========================
        local Tab = {}
        local subTabs = {}
        local currentSubTab = nil

        local currentGroupboxLeft = LeftColumn
        local currentGroupboxRight = RightColumn

        local function GetParent(side)
            if side == "right" then return currentGroupboxRight end
            return currentGroupboxLeft
        end

        function Tab:CreateSubTab(name)
            -- Show the sub-tab bar
            if not SubTabBar.Visible then
                SubTabBar.Visible = true
                SubTabBar.Size = UDim2.new(1, 0, 0, 22)
                LeftColumn.Position = UDim2.new(0, 0, 0, 25)
                LeftColumn.Size = UDim2.new(0.5, -3, 1, -25)
                RightColumn.Position = UDim2.new(0.5, 3, 0, 25)
                RightColumn.Size = UDim2.new(0.5, -3, 1, -25)
            end

            local subTabBtn = Instance.new("TextButton")
            subTabBtn.Parent = SubTabBar
            subTabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            subTabBtn.BackgroundTransparency = 0
            subTabBtn.Size = UDim2.new(0, 80, 1, 0)
            subTabBtn.Text = name
            subTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
            subTabBtn.TextSize = 12
            subTabBtn.AutoButtonColor = false
            subTabBtn.BorderSizePixel = 0
            ApplyFont(subTabBtn)

            local subTabData = {Btn = subTabBtn, Elements = {}}
            table.insert(subTabs, subTabData)

            subTabBtn.MouseButton1Click:Connect(function()
                -- Hide all subtab elements
                for _, st in ipairs(subTabs) do
                    for _, el in ipairs(st.Elements) do
                        el.Visible = false
                    end
                    st.Btn.TextColor3 = Color3.fromRGB(120, 120, 120)
                end
                -- Show this subtab elements
                for _, el in ipairs(subTabData.Elements) do
                    el.Visible = true
                end
                subTabBtn.TextColor3 = Library.Theme.Accent
                currentSubTab = subTabData
            end)

            -- Auto-select first subtab
            if #subTabs == 1 then
                subTabBtn.TextColor3 = Library.Theme.Accent
                currentSubTab = subTabData
            end
            
            Library:RegisterTheme(function(color)
                if currentSubTab == subTabData then
                    subTabBtn.TextColor3 = color
                end
            end, "Accent", "Custom")

            return subTabData
        end

        local function TrackElement(element)
            if currentSubTab then
                table.insert(currentSubTab.Elements, element)
                -- If this is not the first subtab, hide it
                if subTabs[1] ~= currentSubTab then
                    element.Visible = false
                end
            end
        end

        function Tab:CreateSection(name, side)
            local column = side == "right" and RightColumn or LeftColumn
            
            local GroupboxOuter = Instance.new("Frame")
            GroupboxOuter.Parent = column
            GroupboxOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            GroupboxOuter.BorderSizePixel = 1
            GroupboxOuter.BorderColor3 = Color3.fromRGB(35, 35, 35)
            GroupboxOuter.Size = UDim2.new(1, -8, 0, 20)
            
            local GroupboxInner = Instance.new("Frame")
            GroupboxInner.Parent = GroupboxOuter
            GroupboxInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            GroupboxInner.BorderSizePixel = 0
            GroupboxInner.Size = UDim2.new(1, -2, 1, -2)
            GroupboxInner.Position = UDim2.new(0, 1, 0, 1)

            local AccentLine = Instance.new("Frame")
            AccentLine.Parent = GroupboxInner
            AccentLine.Size = UDim2.new(1, 0, 0, 1)
            AccentLine.Position = UDim2.new(0, 0, 0, 0)
            AccentLine.BorderSizePixel = 0
            Library:RegisterTheme(AccentLine, "Accent", "BackgroundColor3")

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Parent = GroupboxInner
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Size = UDim2.new(1, -10, 0, 16)
            TitleLabel.Position = UDim2.new(0, 6, 0, 4)
            TitleLabel.Text = name
            TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TitleLabel.TextSize = 12
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(TitleLabel)

            local Layout = Instance.new("UIListLayout")
            Layout.Parent = GroupboxInner
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 4)

            local Padding = Instance.new("UIPadding")
            Padding.Parent = GroupboxInner
            Padding.PaddingTop = UDim.new(0, 22)
            Padding.PaddingLeft = UDim.new(0, 6)
            Padding.PaddingRight = UDim.new(0, 6)
            Padding.PaddingBottom = UDim.new(0, 6)

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                GroupboxOuter.Size = UDim2.new(1, -8, 0, Layout.AbsoluteContentSize.Y + 30)
            end)

            if side == "right" then
                currentGroupboxRight = GroupboxInner
            else
                currentGroupboxLeft = GroupboxInner
            end
            
            Library:RegisterTheme(GroupboxOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(GroupboxInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(TitleLabel, "Text", "TextColor3")

            TrackElement(GroupboxOuter)
        end

        function Tab:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local parent = GetParent(side)

            local Btn = Instance.new("TextButton")
            Btn.Parent = parent
            Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Btn.Size = UDim2.new(1, 0, 0, 20)
            Btn.Text = btnName
            Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            Btn.TextSize = 12
            Btn.BorderSizePixel = 1
            Btn.BorderColor3 = Color3.fromRGB(40, 40, 40)
            Btn.AutoButtonColor = false
            ApplyFont(Btn)

            Library:RegisterTheme(Btn, "Text", "TextColor3")

            Btn.MouseEnter:Connect(function() 
                Btn.BorderColor3 = Library.Theme.Accent 
            end)
            Btn.MouseLeave:Connect(function() 
                Btn.BorderColor3 = Color3.fromRGB(40, 40, 40) 
            end)
            Btn.MouseButton1Click:Connect(callback)
            TrackElement(Btn)
            
            return {
                SetText = function(self, text) Btn.Text = text end,
                SetColor = function(self, color) Btn.TextColor3 = color end,
                Show = function(self) Btn.Visible = true end,
                Hide = function(self) Btn.Visible = false end
            }
        end

        function Tab:CreateTextBox(options)
            local tName = options.Name or "TextBox"
            local default = options.Default or ""
            local clearOnFocus = options.ClearOnFocus
            if clearOnFocus == nil then clearOnFocus = true end
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)

            local TBox = Instance.new("TextBox")
            TBox.Size = UDim2.new(1, 0, 0, 25)
            TBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            TBox.Text = default ~= "" and default or tName
            TBox.PlaceholderText = tName
            TBox.TextColor3 = Color3.fromRGB(200, 200, 200)
            TBox.TextSize = 12
            TBox.BorderSizePixel = 1
            TBox.BorderColor3 = Color3.fromRGB(40, 40, 40)
            TBox.ClearTextOnFocus = clearOnFocus
            TBox.Parent = parent
            ApplyFont(TBox)

            Library:RegisterTheme(TBox, "Text", "TextColor3")

            TBox.MouseEnter:Connect(function() 
                TBox.BorderColor3 = Library.Theme.Accent 
            end)
            TBox.MouseLeave:Connect(function() 
                TBox.BorderColor3 = Color3.fromRGB(40, 40, 40) 
            end)

            TBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    callback(TBox.Text)
                end
            end)

            TrackElement(TBox)
            
            local tboxObj = {
                SetText = function(self, text) TBox.Text = text end,
                SetColor = function(self, color) TBox.TextColor3 = color end,
                Show = function(self) TBox.Visible = true end,
                Hide = function(self) TBox.Visible = false end,
                CaptureFocus = function(self) TBox:CaptureFocus() end,
                Inst = TBox
            }

            if flag then
                Library.Options[flag] = tboxObj
                Library.Flags[flag] = default
            end

            return tboxObj
        end

        function Tab:CreateToggle(options)
            local tName = options.Name or "Toggle"
            local default = options.Default or false
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)
            local state = default
            local id = HttpService:GenerateGUID(false)
            
            if flag then
                if Library.Flags[flag] ~= nil then
                    state = Library.Flags[flag]
                else
                    Library.Flags[flag] = state
                end
            end

            local ToggleContainer = Instance.new("Frame")
            ToggleContainer.Parent = parent
            ToggleContainer.BackgroundTransparency = 1
            ToggleContainer.Size = UDim2.new(1, 0, 0, 16)
            
            local CheckBox = Instance.new("Frame")
            CheckBox.Parent = ToggleContainer
            CheckBox.BackgroundColor3 = state and Color3.fromRGB(167, 76, 219) or Color3.fromRGB(30, 30, 30)
            CheckBox.Position = UDim2.new(0, 2, 0.5, -6)
            CheckBox.Size = UDim2.new(0, 12, 0, 12)
            CheckBox.BorderSizePixel = 1
            CheckBox.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local TTitle = Instance.new("TextLabel")
            TTitle.Parent = ToggleContainer
            TTitle.BackgroundTransparency = 1
            TTitle.Position = UDim2.new(0, 20, 0, 0)
            TTitle.Size = UDim2.new(1, -20, 1, 0)
            TTitle.Text = tName
            TTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
            TTitle.TextSize = 12
            TTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(TTitle)

            local Btn = Instance.new("TextButton")
            Btn.Parent = ToggleContainer
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = ""

            local function SetState(newState)
                state = newState
                if flag then Library.Flags[flag] = state end
                TweenService:Create(CheckBox, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(30, 30, 30)}):Play()
                callback(state)
            end

            Library:RegisterTheme(TTitle, "Text", "TextColor3")
            
            Btn.MouseButton1Click:Connect(function() SetState(not state) end)

            Btn.MouseButton2Click:Connect(function()
                ShowContextMenu(UserInputService:GetMouseLocation(), {
                    Id = id,
                    Name = tName,
                    Callback = function(action)
                        if action == "toggle" then
                            SetState(not state)
                        elseif action == "hold_start" then
                            SetState(true)
                        elseif action == "hold_end" then
                            SetState(false)
                        elseif action == "always" then
                            if not state then SetState(true) end
                        end
                    end,
                    GetState = function() return state end
                })
            end)

            Library:RegisterTheme(function(color)
                if state then
                    TweenService:Create(CheckBox, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {BackgroundColor3 = color}):Play()
                end
            end, "Accent", "Custom")

            if state then callback(state) end
            TrackElement(ToggleContainer)

            local toggleObj = {
                Set = function(self, val)
                    SetState(val)
                end,
                Show = function(self) ToggleContainer.Visible = true end,
                Hide = function(self) ToggleContainer.Visible = false end
            }
            if flag then Library.Options[flag] = toggleObj end
            return toggleObj
        end

        function Tab:CreateSlider(options)
            local sName = options.Name or "Slider"
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or min
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)

            if flag then
                if Library.Flags[flag] ~= nil then
                    default = Library.Flags[flag]
                else
                    Library.Flags[flag] = default
                end
            end

            local SliderContainer = Instance.new("Frame")
            SliderContainer.Parent = parent
            SliderContainer.BackgroundTransparency = 1
            SliderContainer.Size = UDim2.new(1, 0, 0, 32)

            local STitle = Instance.new("TextLabel")
            STitle.Parent = SliderContainer
            STitle.BackgroundTransparency = 1
            STitle.Size = UDim2.new(1, 0, 0, 14)
            STitle.Text = sName
            STitle.TextColor3 = Color3.fromRGB(200, 200, 200)
            STitle.TextSize = 12
            STitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(STitle)

            local TrackOuter = Instance.new("Frame")
            TrackOuter.Parent = SliderContainer
            TrackOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            TrackOuter.Position = UDim2.new(0, 0, 0, 18)
            TrackOuter.Size = UDim2.new(1, 0, 0, 14)
            TrackOuter.BorderSizePixel = 1
            TrackOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local TrackInner = Instance.new("Frame")
            TrackInner.Parent = TrackOuter
            TrackInner.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            TrackInner.Size = UDim2.new(1, -2, 1, -2)
            TrackInner.Position = UDim2.new(0, 1, 0, 1)
            TrackInner.BorderSizePixel = 0

            local Fill = Instance.new("Frame")
            Fill.Parent = TrackInner
            Fill.BackgroundColor3 = Color3.fromRGB(167, 76, 219)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BorderSizePixel = 0

            local ValueLabel = Instance.new("TextBox")
            ValueLabel.Parent = TrackOuter
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Size = UDim2.new(1, 0, 1, 0)
            ValueLabel.Text = tostring(default) .. "/" .. tostring(max)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValueLabel.TextSize = 11
            ValueLabel.TextStrokeTransparency = 0
            ValueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            ValueLabel.ClearTextOnFocus = false
            ApplyFont(ValueLabel)

            local SliderBtn = Instance.new("TextButton")
            SliderBtn.Parent = TrackOuter
            SliderBtn.BackgroundTransparency = 1
            SliderBtn.Size = UDim2.new(1, 0, 1, 0)
            SliderBtn.Text = ""

            local dragging = false

            local function setSlider(value)
                value = math.clamp(math.floor(tonumber(value) or min), min, max)
                local pct = (value - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(value) .. "/" .. tostring(max)
                if flag then Library.Flags[flag] = value end
                callback(value)
            end

            ValueLabel.FocusLost:Connect(function()
                local rawText = ValueLabel.Text:gsub("/.*", "")
                setSlider(rawText)
            end)

            local function update(input)
                local pos = math.clamp(input.Position.X - TrackInner.AbsolutePosition.X, 0, TrackInner.AbsoluteSize.X)
                local pct = pos / TrackInner.AbsoluteSize.X
                local value = math.floor(min + (max - min) * pct)
                setSlider(value)
            end

            SliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)

            Library:RegisterTheme(STitle, "Text", "TextColor3")
            Library:RegisterTheme(Fill, "Accent", "BackgroundColor3")
            
            if default ~= min then
                setSlider(default)
            else
                callback(default)
            end
            TrackElement(SliderContainer)
            
            local sliderObj = {
                Set = function(self, val)
                    setSlider(val)
                end,
                Show = function(self) SliderContainer.Visible = true end,
                Hide = function(self) SliderContainer.Visible = false end
            }
            if flag then Library.Options[flag] = sliderObj end
            return sliderObj
        end

        function Tab:CreateTextBox(options)
            local tName = options.Name or "TextBox"
            local default = options.Default or ""
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)
            
            if flag then
                if Library.Flags[flag] ~= nil then
                    default = Library.Flags[flag]
                else
                    Library.Flags[flag] = default
                end
            end

            local TBOuter = Instance.new("Frame")
            TBOuter.Parent = parent
            TBOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            TBOuter.Size = UDim2.new(1, -10, 0, 46)
            TBOuter.BorderSizePixel = 1
            TBOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local TBInner = Instance.new("Frame")
            TBInner.Parent = TBOuter
            TBInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            TBInner.Size = UDim2.new(1, -2, 1, -2)
            TBInner.Position = UDim2.new(0, 1, 0, 1)
            TBInner.BorderSizePixel = 1
            TBInner.BorderColor3 = Color3.fromRGB(30, 30, 30)

            local Title = Instance.new("TextLabel")
            Title.Parent = TBInner
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(1, -20, 0, 20)
            Title.Text = tName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(Title)

            local BoxOuter = Instance.new("Frame")
            BoxOuter.Parent = TBInner
            BoxOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            BoxOuter.Position = UDim2.new(0, 10, 0, 22)
            BoxOuter.Size = UDim2.new(1, -20, 0, 18)
            BoxOuter.BorderSizePixel = 1
            BoxOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local Box = Instance.new("TextBox")
            Box.Parent = BoxOuter
            Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Box.Size = UDim2.new(1, -2, 1, -2)
            Box.Position = UDim2.new(0, 1, 0, 1)
            Box.BorderSizePixel = 0
            Box.Text = default
            Box.TextColor3 = Color3.fromRGB(255, 255, 255)
            Box.TextSize = 12
            Box.ClearTextOnFocus = false
            ApplyFont(Box)

            Box.FocusLost:Connect(function()
                if flag then Library.Flags[flag] = Box.Text end
                callback(Box.Text)
            end)
            
            Library:RegisterTheme(Title, "Text", "TextColor3")
            Library:RegisterTheme(Box, "Text", "TextColor3")
            Library:RegisterTheme(TBOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(TBInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(BoxOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(Box, "Main", "BackgroundColor3+2")
            TrackElement(TBOuter)
            
            local tbObj = {
                Set = function(self, val)
                    Box.Text = tostring(val)
                    if flag then Library.Flags[flag] = Box.Text end
                    callback(Box.Text)
                end,
                Get = function(self) return Box.Text end,
                Show = function(self) TBOuter.Visible = true end,
                Hide = function(self) TBOuter.Visible = false end
            }
            if flag then Library.Options[flag] = tbObj end
            return tbObj
        end

        function Tab:CreateDropdown(options)
            local dName = options.Name or "Dropdown"
            local items = options.Items or {}
            local multi = options.Multi or false
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)
            local selected = multi and {} or nil
            
            if flag then
                if Library.Flags[flag] ~= nil then
                    selected = Library.Flags[flag]
                else
                    Library.Flags[flag] = selected
                end
            end

            local DropdownContainer = Instance.new("Frame")
            DropdownContainer.Parent = parent
            DropdownContainer.BackgroundTransparency = 1
            DropdownContainer.Size = UDim2.new(1, 0, 0, 42)
            DropdownContainer.ClipsDescendants = false

            local DTitle = Instance.new("TextLabel")
            DTitle.Parent = DropdownContainer
            DTitle.BackgroundTransparency = 1
            DTitle.Size = UDim2.new(1, 0, 0, 14)
            DTitle.Text = dName
            DTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
            DTitle.TextSize = 12
            DTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(DTitle)

            local DropdownOuter = Instance.new("Frame")
            DropdownOuter.Parent = DropdownContainer
            DropdownOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            DropdownOuter.Position = UDim2.new(0, 0, 0, 18)
            DropdownOuter.Size = UDim2.new(1, 0, 0, 20)
            DropdownOuter.BorderSizePixel = 1
            DropdownOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
            DropdownOuter.ZIndex = 5

            local DropdownInner = Instance.new("Frame")
            DropdownInner.Parent = DropdownOuter
            DropdownInner.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            DropdownInner.Size = UDim2.new(1, -2, 1, -2)
            DropdownInner.Position = UDim2.new(0, 1, 0, 1)
            DropdownInner.BorderSizePixel = 0
            DropdownInner.ZIndex = 5

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Parent = DropdownInner
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Size = UDim2.new(1, 0, 1, 0)
            HeaderBtn.Text = ""
            HeaderBtn.ZIndex = 6

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = DropdownInner
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0, 5, 0, 0)
            SelectedText.Size = UDim2.new(1, -25, 1, 0)
            SelectedText.Text = "None"
            SelectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
            SelectedText.TextSize = 12
            SelectedText.TextXAlignment = Enum.TextXAlignment.Left
            SelectedText.ZIndex = 6
            ApplyFont(SelectedText)

            local Icon = Instance.new("TextLabel")
            Icon.Parent = DropdownInner
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(1, -15, 0, 0)
            Icon.Size = UDim2.new(0, 15, 1, 0)
            Icon.Text = "+"
            Icon.TextColor3 = Color3.fromRGB(200, 200, 200)
            Icon.TextSize = 12
            Icon.ZIndex = 6
            ApplyFont(Icon)

            local ItemContainerOuter = Instance.new("Frame")
            ItemContainerOuter.Parent = DropdownContainer
            ItemContainerOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            ItemContainerOuter.Position = UDim2.new(0, 0, 0, 39)
            ItemContainerOuter.Size = UDim2.new(1, 0, 0, 0)
            ItemContainerOuter.BorderSizePixel = 1
            ItemContainerOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
            ItemContainerOuter.ClipsDescendants = true
            ItemContainerOuter.Visible = false
            ItemContainerOuter.ZIndex = 10

            local ItemContainerInner = Instance.new("Frame")
            ItemContainerInner.Parent = ItemContainerOuter
            ItemContainerInner.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            ItemContainerInner.Size = UDim2.new(1, -2, 1, -2)
            ItemContainerInner.Position = UDim2.new(0, 1, 0, 1)
            ItemContainerInner.BorderSizePixel = 0
            ItemContainerInner.ZIndex = 10

            local ItemList = Instance.new("UIListLayout")
            ItemList.Parent = ItemContainerInner
            ItemList.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    ItemContainerOuter.Visible = true
                    ItemContainerOuter.Size = UDim2.new(1, 0, 0, 0)
                    TweenService:Create(ItemContainerOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, (#items * 20) + 2)}):Play()
                else
                    local tween = TweenService:Create(ItemContainerOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)})
                    tween.Completed:Connect(function()
                        if not isOpen then ItemContainerOuter.Visible = false end
                    end)
                    tween:Play()
                end
                Icon.Text = isOpen and "-" or "+"
            end)
            
            Library.OnTabChange.Event:Connect(function()
                if isOpen then
                    isOpen = false
                    ItemContainerOuter.Visible = false
                    ItemContainerOuter.Size = UDim2.new(1, 0, 0, 0)
                    Icon.Text = "+"
                end
            end)

            local function updateSelectedText()
                if multi then
                    if #selected > 0 then
                        SelectedText.Text = table.concat(selected, ", ")
                    else
                        SelectedText.Text = "None"
                    end
                else
                    SelectedText.Text = selected and tostring(selected) or "None"
                end
            end

            local setValue -- Forward declaration

            local function createItemBtn(item)
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = ItemContainerInner
                ItemBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                ItemBtn.Size = UDim2.new(1, 0, 0, 20)
                ItemBtn.Text = tostring(item)
                ItemBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                ItemBtn.TextSize = 12
                ItemBtn.AutoButtonColor = false
                ItemBtn.BorderSizePixel = 0
                ItemBtn.ZIndex = 11
                ApplyFont(ItemBtn)

                local itemSelected = false

                ItemBtn.MouseButton1Click:Connect(function()
                    if multi then
                        itemSelected = not itemSelected
                        if itemSelected then
                            table.insert(selected, item)
                            TweenService:Create(ItemBtn, TweenInfo.new(0.1), {TextColor3 = Library.Theme.Accent}):Play()
                        else
                            for i, v in ipairs(selected) do
                                if v == item then table.remove(selected, i) break end
                            end
                            TweenService:Create(ItemBtn, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                        end
                        updateSelectedText()
                        if flag then Library.Flags[flag] = selected end
                        callback(selected)
                    else
                        setValue(item)
                        isOpen = false
                        local tween = TweenService:Create(ItemContainerOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)})
                        tween.Completed:Connect(function()
                            if not isOpen then ItemContainerOuter.Visible = false end
                        end)
                        tween:Play()
                        Icon.Text = "+"
                    end
                end)
            end

            for _, item in ipairs(items) do
                createItemBtn(item)
            end
            
            setValue = function(val)
                selected = val
                for _, btn in ipairs(ItemContainerInner:GetChildren()) do
                    if btn:IsA("TextButton") then
                        if multi then
                            local found = false
                            for _, v in ipairs(val) do
                                if v == btn.Text then found = true break end
                            end
                            btn.TextColor3 = found and Library.Theme.Accent or Color3.fromRGB(200, 200, 200)
                        else
                            btn.TextColor3 = (val == btn.Text) and Library.Theme.Accent or Color3.fromRGB(200, 200, 200)
                        end
                    end
                end
                updateSelectedText()
                if flag then Library.Flags[flag] = selected end
                callback(selected)
            end

            if selected ~= nil and (type(selected) ~= "table" or #selected > 0) then
                setValue(selected)
            end

            Library:RegisterTheme(DTitle, "Text", "TextColor3")
            Library:RegisterTheme(SelectedText, "Text", "TextColor3")
            Library:RegisterTheme(Icon, "Text", "TextColor3")
            Library:RegisterTheme(DropdownOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(DropdownInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(ItemContainerOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(ItemContainerInner, "Main", "BackgroundColor3+1")
            
            Library:RegisterTheme(function(color)
                for _, btn in ipairs(ItemContainerInner:GetChildren()) do
                    if btn:IsA("TextButton") then
                        if multi then
                            local found = false
                            for _, v in ipairs(selected or {}) do
                                if v == btn.Text then found = true break end
                            end
                            if found then btn.TextColor3 = color end
                        else
                            if selected == btn.Text then btn.TextColor3 = color end
                        end
                    end
                end
            end, "Accent", "Custom")

            TrackElement(DropdownContainer)
            local dropObj = {
                Set = function(self, val) setValue(val) end,
                Get = function(self) return selected end,
                Refresh = function(self, newItems)
                    items = newItems
                    for _, child in ipairs(ItemContainerInner:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in ipairs(items) do
                        createItemBtn(item)
                    end
                    if isOpen then
                        ItemContainerOuter.Size = UDim2.new(1, 0, 0, (#items * 20) + 2)
                    end
                end,
                Show = function(self) DropdownContainer.Visible = true end,
                Hide = function(self) DropdownContainer.Visible = false end
            }
            if flag then Library.Options[flag] = dropObj end
            return dropObj
        end

        function Tab:CreateColorPicker(options)
            local cName = options.Name or "Color Picker"
            local defaultColor = options.Default or Color3.fromRGB(255, 255, 255)
            local callback = options.Callback or function() end
            local useAlpha = options.UseAlpha or false
            local side = options.Side or "left"
            local flag = options.Flag
            local parent = GetParent(side)
            
            if flag then
                if Library.Flags[flag] ~= nil then
                    local stored = Library.Flags[flag]
                    if type(stored) == "table" and stored.R then
                        defaultColor = Color3.new(stored.R, stored.G, stored.B)
                    end
                else
                    Library.Flags[flag] = {R = defaultColor.R, G = defaultColor.G, B = defaultColor.B, A = 1}
                end
            end

            local h, s, v = Color3.toHSV(defaultColor)
            local a = (flag and type(Library.Flags[flag]) == "table" and Library.Flags[flag].A) or 1

            local CPOuter = Instance.new("Frame")
            CPOuter.Parent = parent
            CPOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            CPOuter.Size = UDim2.new(1, -10, 0, 24) -- Collapsed by default
            CPOuter.BorderSizePixel = 1
            CPOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
            CPOuter.ClipsDescendants = true

            local CPInner = Instance.new("Frame")
            CPInner.Parent = CPOuter
            CPInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            CPInner.Size = UDim2.new(1, -2, 1, -2)
            CPInner.Position = UDim2.new(0, 1, 0, 1)
            CPInner.BorderSizePixel = 1
            CPInner.BorderColor3 = Color3.fromRGB(30, 30, 30)

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Parent = CPInner
            ToggleBtn.BackgroundTransparency = 1
            ToggleBtn.Size = UDim2.new(1, 0, 0, 22)
            ToggleBtn.Text = ""

            local CPTitle = Instance.new("TextLabel")
            CPTitle.Parent = ToggleBtn
            CPTitle.BackgroundTransparency = 1
            CPTitle.Position = UDim2.new(0, 10, 0, 0)
            CPTitle.Size = UDim2.new(1, -20, 1, 0)
            CPTitle.Text = cName
            CPTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            CPTitle.TextSize = 13
            CPTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(CPTitle)

            -- Preview
            local PreviewOuter = Instance.new("Frame")
            PreviewOuter.Parent = ToggleBtn
            PreviewOuter.Position = UDim2.new(1, -30, 0, 4)
            PreviewOuter.Size = UDim2.new(0, 20, 0, 14)
            PreviewOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            PreviewOuter.BorderSizePixel = 1
            PreviewOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local Preview = Instance.new("Frame")
            Preview.Parent = PreviewOuter
            Preview.Size = UDim2.new(1, -2, 1, -2)
            Preview.Position = UDim2.new(0, 1, 0, 1)
            Preview.BackgroundColor3 = defaultColor
            Preview.BorderSizePixel = 0

            local isOpen = false
            ToggleBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local height = useAlpha and 180 or 160
                local targetSize = isOpen and UDim2.new(1, -10, 0, height) or UDim2.new(1, -10, 0, 24)
                TweenService:Create(CPOuter, TweenInfo.new(0.2), {Size = targetSize}):Play()
            end)
            
            Library.OnTabChange.Event:Connect(function()
                if isOpen then
                    isOpen = false
                    TweenService:Create(CPOuter, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 24)}):Play()
                end
            end)

            -- SV Map
            local SVOuter = Instance.new("Frame")
            SVOuter.Parent = CPInner
            SVOuter.Position = UDim2.new(0, 10, 0, 25)
            SVOuter.Size = UDim2.new(1, -40, 0, 120)
            SVOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            SVOuter.BorderSizePixel = 1
            SVOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local SVMap = Instance.new("ImageLabel")
            SVMap.Parent = SVOuter
            SVMap.Size = UDim2.new(1, -2, 1, -2)
            SVMap.Position = UDim2.new(0, 1, 0, 1)
            SVMap.Image = "rbxassetid://4155801252"
            SVMap.BorderSizePixel = 0

            local SVSelector = Instance.new("Frame")
            SVSelector.Parent = SVMap
            SVSelector.Size = UDim2.new(0, 6, 0, 6)
            SVSelector.AnchorPoint = Vector2.new(0.5, 0.5)
            SVSelector.Position = UDim2.new(s, 0, 1 - v, 0)
            SVSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SVSelector.BorderSizePixel = 1
            SVSelector.BorderColor3 = Color3.fromRGB(0, 0, 0)

            -- Hue Slider
            local HueOuter = Instance.new("Frame")
            HueOuter.Parent = CPInner
            HueOuter.Position = UDim2.new(1, -25, 0, 25)
            HueOuter.Size = UDim2.new(0, 15, 0, 120)
            HueOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            HueOuter.BorderSizePixel = 1
            HueOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local HueMap = Instance.new("Frame")
            HueMap.Parent = HueOuter
            HueMap.Size = UDim2.new(1, -2, 1, -2)
            HueMap.Position = UDim2.new(0, 1, 0, 1)
            HueMap.BorderSizePixel = 0

            local HueGradient = Instance.new("UIGradient")
            HueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            HueGradient.Rotation = 90
            HueGradient.Parent = HueMap

            local HueSelector = Instance.new("Frame")
            HueSelector.Parent = HueMap
            HueSelector.Size = UDim2.new(1, 0, 0, 2)
            HueSelector.Position = UDim2.new(0, 0, h, 0)
            HueSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueSelector.BorderSizePixel = 1
            HueSelector.BorderColor3 = Color3.fromRGB(0, 0, 0)

            -- Alpha Slider
            local AlphaOuter = Instance.new("Frame")
            AlphaOuter.Parent = CPInner
            AlphaOuter.Position = UDim2.new(0, 10, 0, 155)
            AlphaOuter.Size = UDim2.new(1, -20, 0, 15)
            AlphaOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            AlphaOuter.BorderSizePixel = 1
            AlphaOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
            AlphaOuter.Visible = useAlpha

            local AlphaMap = Instance.new("Frame")
            AlphaMap.Parent = AlphaOuter
            AlphaMap.Size = UDim2.new(1, -2, 1, -2)
            AlphaMap.Position = UDim2.new(0, 1, 0, 1)
            AlphaMap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            AlphaMap.BorderSizePixel = 0

            local AlphaGradient = Instance.new("UIGradient")
            AlphaGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            })
            AlphaGradient.Parent = AlphaMap

            local AlphaSelector = Instance.new("Frame")
            AlphaSelector.Parent = AlphaMap
            AlphaSelector.Size = UDim2.new(0, 2, 1, 0)
            AlphaSelector.Position = UDim2.new(a, 0, 0, 0)
            AlphaSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            AlphaSelector.BorderSizePixel = 1
            AlphaSelector.BorderColor3 = Color3.fromRGB(0, 0, 0)

            local function UpdateColor()
                local realColor = Color3.fromHSV(h, s, v)
                SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Preview.BackgroundColor3 = realColor
                Preview.BackgroundTransparency = 1 - a
                if flag then Library.Flags[flag] = {R = realColor.R, G = realColor.G, B = realColor.B, A = a} end
                callback(realColor, a)
            end

            local draggingSV, draggingHue, draggingAlpha = false, false, false

            UserInputService.InputBegan:Connect(function(input)
                if not isOpen then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = input.Position

                    local abPos, abSize = SVMap.AbsolutePosition, SVMap.AbsoluteSize
                    if mp.X >= abPos.X and mp.X <= abPos.X + abSize.X and mp.Y >= abPos.Y and mp.Y <= abPos.Y + abSize.Y then
                        draggingSV = true
                        s = math.clamp((mp.X - abPos.X) / abSize.X, 0, 1)
                        v = 1 - math.clamp((mp.Y - abPos.Y) / abSize.Y, 0, 1)
                        SVSelector.Position = UDim2.new(s, 0, 1 - v, 0)
                        UpdateColor()
                    end

                    abPos, abSize = HueMap.AbsolutePosition, HueMap.AbsoluteSize
                    if mp.X >= abPos.X and mp.X <= abPos.X + abSize.X and mp.Y >= abPos.Y and mp.Y <= abPos.Y + abSize.Y then
                        draggingHue = true
                        h = math.clamp((mp.Y - abPos.Y) / abSize.Y, 0, 1)
                        HueSelector.Position = UDim2.new(0, 0, h, 0)
                        UpdateColor()
                    end

                    abPos, abSize = AlphaMap.AbsolutePosition, AlphaMap.AbsoluteSize
                    if useAlpha and mp.X >= abPos.X and mp.X <= abPos.X + abSize.X and mp.Y >= abPos.Y and mp.Y <= abPos.Y + abSize.Y then
                        draggingAlpha = true
                        a = math.clamp((mp.X - abPos.X) / abSize.X, 0, 1)
                        AlphaSelector.Position = UDim2.new(a, 0, 0, 0)
                        UpdateColor()
                    end
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mp = input.Position
                    if draggingSV then
                        local abPos, abSize = SVMap.AbsolutePosition, SVMap.AbsoluteSize
                        s = math.clamp((mp.X - abPos.X) / abSize.X, 0, 1)
                        v = 1 - math.clamp((mp.Y - abPos.Y) / abSize.Y, 0, 1)
                        SVSelector.Position = UDim2.new(s, 0, 1 - v, 0)
                        UpdateColor()
                    elseif draggingHue then
                        local abPos, abSize = HueMap.AbsolutePosition, HueMap.AbsoluteSize
                        h = math.clamp((mp.Y - abPos.Y) / abSize.Y, 0, 1)
                        HueSelector.Position = UDim2.new(0, 0, h, 0)
                        UpdateColor()
                    elseif draggingAlpha then
                        local abPos, abSize = AlphaMap.AbsolutePosition, AlphaMap.AbsoluteSize
                        a = math.clamp((mp.X - abPos.X) / abSize.X, 0, 1)
                        AlphaSelector.Position = UDim2.new(a, 0, 0, 0)
                        UpdateColor()
                    end
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = false
                    draggingHue = false
                    draggingAlpha = false
                end
            end)

            UpdateColor()
            Library:RegisterTheme(CPTitle, "Text", "TextColor3")
            Library:RegisterTheme(CPOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(CPInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(PreviewOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(SVOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(HueOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(AlphaOuter, "Main", "BackgroundColor3")
            TrackElement(CPOuter)
            
            local cpObj = {
                Set = function(self, newColor, newAlpha)
                    h, s, v = Color3.toHSV(newColor)
                    a = newAlpha or a
                    SVSelector.Position = UDim2.new(s, 0, 1 - v, 0)
                    HueSelector.Position = UDim2.new(0, 0, h, 0)
                    AlphaSelector.Position = UDim2.new(a, 0, 0, 0)
                    UpdateColor()
                end,
                Show = function(self) CPOuter.Visible = true end,
                Hide = function(self) CPOuter.Visible = false end
            }
            if flag then Library.Options[flag] = cpObj end
            return cpObj
        end

        function Tab:CreateViewport(options)
            local vName = options.Name or "Viewport"
            local height = options.Height or 200
            local side = options.Side or "right"
            local parent = GetParent(side)

            local VOuter = Instance.new("Frame")
            VOuter.Parent = parent
            VOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            VOuter.Size = UDim2.new(1, -10, 0, height)
            VOuter.BorderSizePixel = 1
            VOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local VTitle = Instance.new("TextLabel")
            VTitle.Parent = VOuter
            VTitle.BackgroundTransparency = 1
            VTitle.Position = UDim2.new(0, 5, 0, 0)
            VTitle.Size = UDim2.new(1, -10, 0, 20)
            VTitle.Text = vName
            VTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            VTitle.TextSize = 12
            VTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(VTitle)

            local Viewport = Instance.new("ViewportFrame")
            Viewport.Parent = VOuter
            Viewport.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            Viewport.BorderSizePixel = 1
            Viewport.BorderColor3 = Color3.fromRGB(40, 40, 40)
            Viewport.Position = UDim2.new(0, 5, 0, 20)
            Viewport.Size = UDim2.new(1, -10, 1, -25)
            Viewport.LightColor = Color3.fromRGB(255, 255, 255)
            Viewport.LightDirection = Vector3.new(0, -1, 0)
            Viewport.Ambient = Color3.fromRGB(150, 150, 150)

            local Camera = Instance.new("Camera")
            Viewport.CurrentCamera = Camera
            Camera.Parent = Viewport

            Library:RegisterTheme(VOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(Viewport, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(VTitle, "Text", "TextColor3")

            TrackElement(VOuter)

            local vpObj = {
                Viewport = Viewport,
                Camera = Camera,
                Show = function(self) VOuter.Visible = true end,
                Hide = function(self) VOuter.Visible = false end
            }
            return vpObj
        end

        return Tab
    end

    return WindowObj
end

Library.ConfigManager = {}
function Library.ConfigManager:Save(name)
    local FolderLocation = 'KittyAuth'
    if not isfolder(FolderLocation) then makefolder(FolderLocation) end
    if not isfolder(FolderLocation..'\\Configs') then makefolder(FolderLocation..'\\Configs') end
    
    local path = FolderLocation..'\\Configs\\'..name..'.json'
    local HttpService = game:GetService('HttpService')
    
    local saveData = {
        Flags = Library.Flags,
        Keybinds = {}
    }
    
    for id, bind in pairs(Library.Keybinds) do
        saveData.Keybinds[id] = { Key = bind.Key.Name, Mode = bind.Mode }
    end
    
    writefile(path, HttpService:JSONEncode(saveData))
end

function Library.ConfigManager:Load(name)
    local FolderLocation = 'KittyAuth'
    local path = FolderLocation..'\\Configs\\'..name..'.json'
    local HttpService = game:GetService('HttpService')
    
    if isfile(path) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success and decoded then
            if decoded.Flags then
                for flag, val in pairs(decoded.Flags) do
                    if Library.Options[flag] then
                        if type(val) == 'table' and val.R then
                            Library.Options[flag]:Set(Color3.new(val.R, val.G, val.B), val.A)
                        else
                            Library.Options[flag]:Set(val)
                        end
                    end
                end
            end
            -- Note: Keybind loading omitted for brevity, can be added later
        end
    end
end

function Library.ConfigManager:Rename(oldName, newName)
    local FolderLocation = 'KittyAuth'
    local oldPath = FolderLocation..'\\Configs\\'..oldName..'.json'
    local newPath = FolderLocation..'\\Configs\\'..newName..'.json'
    
    if isfile(oldPath) then
        writefile(newPath, readfile(oldPath))
        delfile(oldPath)
    end
end

function Library:Unload()
    if Library.GUI then
        Library.GUI:Destroy()
        Library.GUI = nil
    end
end

return Library
