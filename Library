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
            pcall(function() 
                obj.Inst.BackgroundColor3 = color 
                if themeType == "Main" or themeType == "Background" then obj.Inst.BackgroundTransparency = trans end
            end)
        elseif obj.Type == 'BackgroundColor3+1' then 
            pcall(function() 
                obj.Inst.BackgroundColor3 = colorPlus1 
                if themeType == "Main" or themeType == "Background" then obj.Inst.BackgroundTransparency = trans end
            end)
        elseif obj.Type == 'BackgroundColor3+2' then 
            pcall(function() 
                obj.Inst.BackgroundColor3 = colorPlus2 
                if themeType == "Main" or themeType == "Background" then obj.Inst.BackgroundTransparency = trans end
            end)
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
    ScreenGui.Name = "KittyUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    local OuterFrame = Instance.new("CanvasGroup")
    OuterFrame.Name = "OuterFrame"
    OuterFrame.Size = UDim2.new(0, 750, 0, 550)
    OuterFrame.Position = UDim2.new(0.5, -375, 0.5, -275)
    OuterFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    OuterFrame.BorderSizePixel = 1
    OuterFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    OuterFrame.Parent = ScreenGui

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Size = UDim2.new(1, -6, 1, -6)
    InnerFrame.Position = UDim2.new(0, 3, 0, 3)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    InnerFrame.BorderSizePixel = 1
    InnerFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
    InnerFrame.Parent = OuterFrame

    -- Top gradient bar
    local accentLine, gradient = CreateAnimatedGradientBar(InnerFrame)
    Library:RegisterTheme(gradient, "Accent", "Gradient")

    -- Topbar (draggable)
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = InnerFrame
    Topbar.BackgroundTransparency = 1
    Topbar.Position = UDim2.new(0, 0, 0, 2)
    Topbar.Size = UDim2.new(1, 0, 0, 25)
    Topbar.BorderSizePixel = 0
    MakeDraggable(Topbar, OuterFrame)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Topbar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 5, 0, 0)
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextStrokeTransparency = 0.8
    ApplyFont(TitleLabel)

    Library:RegisterTheme(OuterFrame, "Background", "BackgroundColor3")
    Library:RegisterTheme(TitleLabel, "Text", "TextColor3")

    -- TabBar (Top Tabs)
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = InnerFrame
    TabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TabBar.Position = UDim2.new(0, 0, 0, 27)
    TabBar.Size = UDim2.new(1, 0, 0, 35)
    TabBar.BorderSizePixel = 1
    TabBar.BorderColor3 = Color3.fromRGB(30, 30, 30)

    local TabBarList = Instance.new("UIListLayout")
    TabBarList.Parent = TabBar
    TabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabBarList.FillDirection = Enum.FillDirection.Horizontal
    TabBarList.SortOrder = Enum.SortOrder.LayoutOrder
    TabBarList.Padding = UDim.new(0, 5)

    local TabBarPadding = Instance.new("UIPadding")
    TabBarPadding.Parent = TabBar
    TabBarPadding.PaddingLeft = UDim.new(0, 5)
    TabBarPadding.PaddingTop = UDim.new(0, 5)
    TabBarPadding.PaddingBottom = UDim.new(0, 5)

    -- Main container (holds left and right columns)
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Parent = InnerFrame
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0, 5, 0, 67)
    Container.Size = UDim2.new(1, -10, 1, -72)
    Container.BorderSizePixel = 0
    
    Library:RegisterTheme(InnerFrame, "Background", "BackgroundColor3")
    Library:RegisterTheme(TabBar, "Background", "BackgroundColor3")

    -- Insert toggle
    Library.ToggleKey = Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Toggled = not Library.Toggled
            if Library.Toggled then
                OuterFrame.Visible = true
                TweenService:Create(OuterFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {GroupTransparency = 0}):Play()
            else
                local t = TweenService:Create(OuterFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {GroupTransparency = 1})
                t:Play()
                t.Completed:Connect(function()
                    if not Library.Toggled then OuterFrame.Visible = false end
                end)
            end
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
    MakeDraggable(KeybindList, KeybindList)

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

    local KeybindLayout = Instance.new("UIListLayout")
    KeybindLayout.Parent = KeybindContainer
    KeybindLayout.SortOrder = Enum.SortOrder.LayoutOrder
    KeybindLayout.Padding = UDim.new(0, 2)

    -- ========================
    -- CONTEXT MENU (Fatality-style keybind) - Uses backdrop approach
    -- ========================
    local Backdrop = Instance.new("TextButton")
    Backdrop.Name = "Backdrop"
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
        TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        TabBtn.BackgroundTransparency = 1.0
        TabBtn.Size = UDim2.new(0, 120, 1, 0)
        TabBtn.Text = name
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.TextSize = 14
        TabBtn.AutoButtonColor = false
        ApplyFont(TabBtn)
        
        Library:RegisterTheme(TabBtn, "Text", "TextColor3")

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
        TabBtn.MouseButton1Click:Connect(function()
            for _, tab in ipairs(WindowObj.Tabs) do
                tab.Page.Visible = false
                TweenService:Create(tab.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1.0, TextColor3 = Library.Theme.Text}):Play()
            end
            TabPage.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, TextColor3 = Library.Theme.Accent}):Play()
            Library.OnTabChange:Fire()
            WindowObj.CurrentTab = {Btn = TabBtn, Page = TabPage}
        end)

        if #WindowObj.Tabs == 1 then
            WindowObj.CurrentTab = {Btn = TabBtn, Page = TabPage}
            TabBtn.BackgroundTransparency = 0.8
            TabBtn.TextColor3 = Library.Theme.Accent
            TabPage.Visible = true
        end

        -- ========================
        -- TAB API
        -- ========================
        local Tab = {}
        local subTabs = {}
        local currentSubTab = nil

        -- side = "left" or "right", defaults to "left"
        local function GetParent(side)
            if side == "right" then return RightColumn end
            return LeftColumn
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
                subTabBtn.TextColor3 = Color3.fromRGB(167, 76, 219)
                currentSubTab = subTabData
            end)

            -- Auto-select first subtab
            if #subTabs == 1 then
                subTabBtn.TextColor3 = Color3.fromRGB(167, 76, 219)
                currentSubTab = subTabData
            end

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
            local parent = GetParent(side)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Parent = parent
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Size = UDim2.new(1, -10, 0, 20)

            local STitle = Instance.new("TextLabel")
            STitle.Parent = SectionFrame
            STitle.BackgroundTransparency = 1
            STitle.Size = UDim2.new(1, 0, 1, 0)
            STitle.Text = name
            STitle.TextColor3 = Color3.fromRGB(167, 76, 219)
            STitle.TextSize = 13
            STitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(STitle)

            local Line = Instance.new("Frame")
            Line.Parent = SectionFrame
            Line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Line.Position = UDim2.new(0, 0, 1, -1)
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.BorderSizePixel = 0

            TrackElement(SectionFrame)
        end

        function Tab:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local parent = GetParent(side)

            local ButtonOuter = Instance.new("Frame")
            ButtonOuter.Parent = parent
            ButtonOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            ButtonOuter.Size = UDim2.new(1, -10, 0, 26)
            ButtonOuter.BorderSizePixel = 1
            ButtonOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local ButtonInner = Instance.new("Frame")
            ButtonInner.Parent = ButtonOuter
            ButtonInner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            ButtonInner.Size = UDim2.new(1, -2, 1, -2)
            ButtonInner.Position = UDim2.new(0, 1, 0, 1)
            ButtonInner.BorderSizePixel = 1
            ButtonInner.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local Btn = Instance.new("TextButton")
            Btn.Parent = ButtonInner
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = btnName
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.TextSize = 13
            Btn.AutoButtonColor = false
            ApplyFont(Btn)

            Library:RegisterTheme(ButtonOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(ButtonInner, "Main", "BackgroundColor3+1")

            Btn.MouseEnter:Connect(function() TweenService:Create(ButtonInner, TweenInfo.new(0.1), {BackgroundColor3 = Library:GetColorPlus(Library.Theme.Main, 2)}):Play() end)
            Btn.MouseLeave:Connect(function() TweenService:Create(ButtonInner, TweenInfo.new(0.1), {BackgroundColor3 = Library:GetColorPlus(Library.Theme.Main, 1)}):Play() end)
            Btn.MouseButton1Down:Connect(function()
                TweenService:Create(ButtonInner, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Main}):Play()
            end)
            Btn.MouseButton1Up:Connect(function()
                TweenService:Create(ButtonInner, TweenInfo.new(0.1), {BackgroundColor3 = Library:GetColorPlus(Library.Theme.Main, 1)}):Play()
            end)
            Btn.MouseButton1Click:Connect(callback)
            TrackElement(ButtonOuter)
            
            return {
                SetText = function(self, text)
                    Btn.Text = text
                end,
                SetColor = function(self, color)
                    Btn.TextColor3 = color
                end
            }
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

            local ToggleOuter = Instance.new("Frame")
            ToggleOuter.Parent = parent
            ToggleOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            ToggleOuter.Size = UDim2.new(1, -10, 0, 26)
            ToggleOuter.BorderSizePixel = 1
            ToggleOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local ToggleInner = Instance.new("Frame")
            ToggleInner.Parent = ToggleOuter
            ToggleInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            ToggleInner.Size = UDim2.new(1, -2, 1, -2)
            ToggleInner.Position = UDim2.new(0, 1, 0, 1)
            ToggleInner.BorderSizePixel = 1
            ToggleInner.BorderColor3 = Color3.fromRGB(30, 30, 30)

            local TTitle = Instance.new("TextLabel")
            TTitle.Parent = ToggleInner
            TTitle.BackgroundTransparency = 1
            TTitle.Position = UDim2.new(0, 10, 0, 0)
            TTitle.Size = UDim2.new(1, -50, 1, 0)
            TTitle.Text = tName
            TTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            TTitle.TextSize = 13
            TTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(TTitle)

            local CheckBoxOuter = Instance.new("Frame")
            CheckBoxOuter.Parent = ToggleInner
            CheckBoxOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            CheckBoxOuter.Position = UDim2.new(1, -20, 0.5, -6)
            CheckBoxOuter.Size = UDim2.new(0, 12, 0, 12)
            CheckBoxOuter.BorderSizePixel = 1
            CheckBoxOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local CheckBoxInner = Instance.new("Frame")
            CheckBoxInner.Parent = CheckBoxOuter
            CheckBoxInner.BackgroundColor3 = state and Color3.fromRGB(167, 76, 219) or Color3.fromRGB(30, 30, 30)
            CheckBoxInner.Size = UDim2.new(1, -2, 1, -2)
            CheckBoxInner.Position = UDim2.new(0, 1, 0, 1)
            CheckBoxInner.BorderSizePixel = 0

            local Btn = Instance.new("TextButton")
            Btn.Parent = ToggleInner
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = ""

            local function SetState(newState)
                state = newState
                if flag then Library.Flags[flag] = state end
                TweenService:Create(CheckBoxInner, TweenInfo.new(0.15), {BackgroundColor3 = state and Library.Theme.Accent or Library:GetColorPlus(Library.Theme.Main, 1)}):Play()
                callback(state)
            end

            Library:RegisterTheme(TTitle, "Text", "TextColor3")
            Library:RegisterTheme(ToggleOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(ToggleInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(CheckBoxOuter, "Main", "BackgroundColor3")
            
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

            Library:RegisterTheme(CheckBoxInner, "Accent", "BackgroundColor3")
            if state then callback(state) end
            TrackElement(ToggleOuter)

            local toggleObj = {
                Set = function(self, val)
                    SetState(val)
                end
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

            local SliderOuter = Instance.new("Frame")
            SliderOuter.Parent = parent
            SliderOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            SliderOuter.Size = UDim2.new(1, -10, 0, 40)
            SliderOuter.BorderSizePixel = 1
            SliderOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local SliderInner = Instance.new("Frame")
            SliderInner.Parent = SliderOuter
            SliderInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            SliderInner.Size = UDim2.new(1, -2, 1, -2)
            SliderInner.Position = UDim2.new(0, 1, 0, 1)
            SliderInner.BorderSizePixel = 1
            SliderInner.BorderColor3 = Color3.fromRGB(30, 30, 30)

            local STitle = Instance.new("TextLabel")
            STitle.Parent = SliderInner
            STitle.BackgroundTransparency = 1
            STitle.Position = UDim2.new(0, 10, 0, 0)
            STitle.Size = UDim2.new(1, -60, 0, 20)
            STitle.Text = sName
            STitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            STitle.TextSize = 13
            STitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(STitle)

            local ValueLabel = Instance.new("TextBox")
            ValueLabel.Parent = SliderInner
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(1, -60, 0, 0)
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.ClearTextOnFocus = false
            ApplyFont(ValueLabel)

            local TrackOuter = Instance.new("Frame")
            TrackOuter.Parent = SliderInner
            TrackOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            TrackOuter.Position = UDim2.new(0, 10, 0, 22)
            TrackOuter.Size = UDim2.new(1, -20, 0, 8)
            TrackOuter.BorderSizePixel = 1
            TrackOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)

            local TrackInner = Instance.new("Frame")
            TrackInner.Parent = TrackOuter
            TrackInner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            TrackInner.Size = UDim2.new(1, -2, 1, -2)
            TrackInner.Position = UDim2.new(0, 1, 0, 1)
            TrackInner.BorderSizePixel = 0

            local Fill = Instance.new("Frame")
            Fill.Parent = TrackInner
            Fill.BackgroundColor3 = Color3.fromRGB(167, 76, 219)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BorderSizePixel = 0

            local SliderBtn = Instance.new("TextButton")
            SliderBtn.Parent = TrackOuter
            SliderBtn.BackgroundTransparency = 1
            SliderBtn.Size = UDim2.new(1, 0, 1, 0)
            SliderBtn.Text = ""

            local dragging = false

            local function setSlider(value)
                value = math.clamp(math.floor(tonumber(value) or min), min, max)
                local pct = (value - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(value)
                if flag then Library.Flags[flag] = value end
                callback(value)
            end

            ValueLabel.FocusLost:Connect(function()
                setSlider(ValueLabel.Text)
            end)

            ValueLabel:GetPropertyChangedSignal("Text"):Connect(function()
                if ValueLabel:IsFocused() then
                    local num = tonumber(ValueLabel.Text)
                    if num then
                        local clamped = math.clamp(math.floor(num), min, max)
                        local pct = (clamped - min) / (max - min)
                        TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                        callback(clamped)
                    end
                end
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
            Library:RegisterTheme(SValue, "Text", "TextColor3")
            Library:RegisterTheme(TrackOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(TrackInner, "Main", "BackgroundColor3+1")
            Library:RegisterTheme(Fill, "Accent", "BackgroundColor3")
            if default ~= min then
                setSlider(default)
            else
                callback(default)
            end
            TrackElement(SliderOuter)
            
            local sliderObj = {
                Set = function(self, val)
                    setSlider(val)
                end
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
                Get = function(self) return Box.Text end
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

            local DropdownOuter = Instance.new("Frame")
            DropdownOuter.Parent = parent
            DropdownOuter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            DropdownOuter.Size = UDim2.new(1, -10, 0, 26)
            DropdownOuter.BorderSizePixel = 1
            DropdownOuter.BorderColor3 = Color3.fromRGB(40, 40, 40)
            DropdownOuter.ClipsDescendants = true

            local DropdownInner = Instance.new("Frame")
            DropdownInner.Parent = DropdownOuter
            DropdownInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            DropdownInner.Size = UDim2.new(1, -2, 0, 9999) -- tall so items are visible
            DropdownInner.Position = UDim2.new(0, 1, 0, 1)
            DropdownInner.BorderSizePixel = 1
            DropdownInner.BorderColor3 = Color3.fromRGB(30, 30, 30)

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Parent = DropdownInner
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Size = UDim2.new(1, 0, 0, 24)
            HeaderBtn.Text = ""

            local DTitle = Instance.new("TextLabel")
            DTitle.Parent = HeaderBtn
            DTitle.BackgroundTransparency = 1
            DTitle.Position = UDim2.new(0, 10, 0, 0)
            DTitle.Size = UDim2.new(1, -20, 1, 0)
            DTitle.Text = dName .. (multi and " [Multi]" or "")
            DTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            DTitle.TextSize = 13
            DTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(DTitle)

            local Icon = Instance.new("TextLabel")
            Icon.Parent = HeaderBtn
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(1, -20, 0, 0)
            Icon.Size = UDim2.new(0, 20, 1, 0)
            Icon.Text = "+"
            Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
            Icon.TextSize = 14
            ApplyFont(Icon)

            local ItemContainer = Instance.new("Frame")
            ItemContainer.Parent = DropdownInner
            ItemContainer.BackgroundTransparency = 1
            ItemContainer.Position = UDim2.new(0, 0, 0, 24)
            ItemContainer.Size = UDim2.new(1, 0, 0, #items * 22)

            local ItemList = Instance.new("UIListLayout")
            ItemList.Parent = ItemContainer
            ItemList.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetSize = isOpen and UDim2.new(1, -10, 0, 26 + (#items * 22)) or UDim2.new(1, -10, 0, 26)
                TweenService:Create(DropdownOuter, TweenInfo.new(0.2), {Size = targetSize}):Play()
                Icon.Text = isOpen and "-" or "+"
            end)
            
            Library.OnTabChange.Event:Connect(function()
                if isOpen then
                    isOpen = false
                    TweenService:Create(DropdownOuter, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 26)}):Play()
                    Icon.Text = "+"
                end
            end)

            local function createItemBtn(item)
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = ItemContainer
                ItemBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                ItemBtn.Size = UDim2.new(1, 0, 0, 22)
                ItemBtn.Text = tostring(item)
                ItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                ItemBtn.TextSize = 12
                ItemBtn.AutoButtonColor = false
                ItemBtn.BorderSizePixel = 0
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
                            TweenService:Create(ItemBtn, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                        end
                        if flag then Library.Flags[flag] = selected end
                        callback(selected)
                    else
                        DTitle.Text = dName .. " : " .. tostring(item)
                        isOpen = false
                        TweenService:Create(DropdownOuter, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 26)}):Play()
                        Icon.Text = "+"
                        selected = item
                        if flag then Library.Flags[flag] = selected end
                        callback(item)
                    end
                end)
            end

            for _, item in ipairs(items) do
                createItemBtn(item)
            end
            
            local function setValue(val)
                selected = val
                if multi then
                    for _, btn in ipairs(ItemContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local found = false
                            for _, v in ipairs(val) do
                                if v == btn.Text then found = true break end
                            end
                            btn.TextColor3 = found and Color3.fromRGB(167, 76, 219) or Color3.fromRGB(255, 255, 255)
                        end
                    end
                else
                    DTitle.Text = dName .. " : " .. tostring(val)
                end
                if flag then Library.Flags[flag] = selected end
                callback(selected)
            end

            if selected ~= nil and (type(selected) ~= "table" or #selected > 0) then
                setValue(selected)
            end

            Library:RegisterTheme(DTitle, "Text", "TextColor3")
            Library:RegisterTheme(Icon, "Text", "TextColor3")
            Library:RegisterTheme(DropdownOuter, "Main", "BackgroundColor3")
            Library:RegisterTheme(DropdownInner, "Main", "BackgroundColor3+1")
            TrackElement(DropdownOuter)
            local dropObj = {
                Get = function(self) return selected end,
                Set = function(self, val)
                    setValue(val)
                end,
                Refresh = function(self, newItems)
                    items = newItems
                    for _, child in ipairs(ItemContainer:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in ipairs(items) do
                        createItemBtn(item)
                    end
                    ItemContainer.Size = UDim2.new(1, 0, 0, #items * 22)
                    if isOpen then
                        TweenService:Create(DropdownOuter, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 26 + (#items * 22))}):Play()
                    end
                end
            }
            if flag then Library.Options[flag] = dropObj end
            return dropObj
        end

        function Tab:CreateColorPicker(options)
            local cName = options.Name or "Color Picker"
            local defaultColor = options.Default or Color3.fromRGB(255, 255, 255)
            local callback = options.Callback or function() end
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
                local targetSize = isOpen and UDim2.new(1, -10, 0, 180) or UDim2.new(1, -10, 0, 24)
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
                    if mp.X >= abPos.X and mp.X <= abPos.X + abSize.X and mp.Y >= abPos.Y and mp.Y <= abPos.Y + abSize.Y then
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
                end
            }
            if flag then Library.Options[flag] = cpObj end
            return cpObj
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

return Library
