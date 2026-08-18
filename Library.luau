local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

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

local function AddCorner(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = typeof(radius) == "number" and UDim.new(0, radius) or (radius or UDim.new(0, 4))
    corner.Parent = inst
    return corner
end

local Library = {}
Library.Toggled = true
Library.Keybinds = {}
Library.ActiveKeybinds = {}
Library.Flags = {}
Library.Options = {}
Library.SearchableElements = {}
Library.OnTabChange = Instance.new("BindableEvent")
Library.Theme = {
    Accent = Color3.fromRGB(0, 150, 255),
    Main = Color3.fromRGB(10, 13, 20),
    Background = Color3.fromRGB(6, 8, 12),
    Text = Color3.fromRGB(240, 245, 255)
}
Library.ThemeObjects = {Accent = {}, Main = {}, Background = {}, Text = {}}

function Library:GetColorPlus(color, mult)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.clamp(v + (0.03 * (mult or 1)), 0, 1))
end

function Library:SetTheme(themeType, color, alpha)
    alpha = alpha or 1
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
    local colorPlus1 = Color3.fromHSV(h, s, math.clamp(v + 0.03, 0, 1))
    local colorPlus2 = Color3.fromHSV(h, s, math.clamp(v + 0.06, 0, 1))

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

local function CreateAnimatedGradientBar(parent)
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.Position = UDim2.new(0, 0, 0, 0)
    AccentLine.BorderSizePixel = 0
    AccentLine.ClipsDescendants = true
    AccentLine.Parent = parent
    AddCorner(AccentLine, 2)

    local GradientFrame = Instance.new("Frame")
    GradientFrame.Size = UDim2.new(2, 0, 1, 0)
    GradientFrame.Position = UDim2.new(0, 0, 0, 0)
    GradientFrame.BorderSizePixel = 0
    GradientFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GradientFrame.Parent = AccentLine

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0, 140, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 80, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 220, 255))
    })
    Gradient.Parent = GradientFrame

    local tween = TweenService:Create(GradientFrame, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(-1, 0, 0, 0)})
    tween:Play()

    return AccentLine, Gradient
end

function Library:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "UI Library"

    if CoreGui:FindFirstChild("KittyUI") then CoreGui.KittyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KittyUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Library.GUI = ScreenGui
    ScreenGui.IgnoreGuiInset = true

    local OuterFrame = Instance.new("Frame")
    OuterFrame.Name = "OuterFrame"
    OuterFrame.Size = UDim2.new(0, 680, 0, 540)
    OuterFrame.Position = UDim2.new(0.5, -340, 0.5, -270)
    OuterFrame.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
    OuterFrame.BorderSizePixel = 1
    OuterFrame.BorderColor3 = Color3.fromRGB(18, 26, 38)
    OuterFrame.Parent = ScreenGui
    AddCorner(OuterFrame, 8)

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Size = UDim2.new(1, -2, 1, -2)
    InnerFrame.Position = UDim2.new(0, 1, 0, 1)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
    InnerFrame.BorderSizePixel = 1
    InnerFrame.BorderColor3 = Color3.fromRGB(22, 32, 48)
    InnerFrame.Parent = OuterFrame
    AddCorner(InnerFrame, 7)

    local OuterBorder = Instance.new("Frame")
    OuterBorder.Name = "OuterBorder"
    OuterBorder.Size = UDim2.new(1, -12, 1, -12)
    OuterBorder.Position = UDim2.new(0, 6, 0, 6)
    OuterBorder.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
    OuterBorder.BorderSizePixel = 1
    OuterBorder.BorderColor3 = Color3.fromRGB(18, 26, 38)
    OuterBorder.Parent = InnerFrame
    AddCorner(OuterBorder, 6)

    local MainBg = Instance.new("Frame")
    MainBg.Name = "MainBg"
    MainBg.Size = UDim2.new(1, -2, 1, -2)
    MainBg.Position = UDim2.new(0, 1, 0, 1)
    MainBg.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
    MainBg.BorderSizePixel = 0
    MainBg.Parent = OuterBorder
    AddCorner(MainBg, 6)

    local accentLine, gradient = CreateAnimatedGradientBar(MainBg)
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    Library:RegisterTheme(gradient, "Accent", "Gradient")

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = MainBg
    Topbar.BackgroundTransparency = 1
    Topbar.Position = UDim2.new(0, 0, 0, 2)
    Topbar.Size = UDim2.new(1, 0, 0, 42)
    Topbar.BorderSizePixel = 0
    Topbar.ZIndex = 10
    MakeDraggable(Topbar, OuterFrame)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Topbar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.Size = UDim2.new(0.45, 0, 1, 0)
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 11
    ApplyFont(TitleLabel)

    local SearchBtn = Instance.new("TextButton")
    SearchBtn.Name = "SearchBtn"
    SearchBtn.Parent = Topbar
    SearchBtn.BackgroundColor3 = Color3.fromRGB(16, 24, 38)
    SearchBtn.BorderColor3 = Color3.fromRGB(28, 40, 60)
    SearchBtn.BorderSizePixel = 1
    SearchBtn.Position = UDim2.new(1, -44, 0.5, -15)
    SearchBtn.Size = UDim2.new(0, 30, 0, 30)
    SearchBtn.Text = ""
    SearchBtn.ZIndex = 25
    SearchBtn.AutoButtonColor = false
    AddCorner(SearchBtn, 5)

    local SearchIconFrame = Instance.new("Frame")
    SearchIconFrame.Name = "SearchIconFrame"
    SearchIconFrame.Parent = SearchBtn
    SearchIconFrame.BackgroundTransparency = 1
    SearchIconFrame.Size = UDim2.new(0, 18, 0, 18)
    SearchIconFrame.Position = UDim2.new(0.5, -9, 0.5, -9)
    SearchIconFrame.ZIndex = 26

    local GlassCircle = Instance.new("Frame")
    GlassCircle.Name = "GlassCircle"
    GlassCircle.Parent = SearchIconFrame
    GlassCircle.BackgroundTransparency = 1
    GlassCircle.Position = UDim2.new(0, 1, 0, 1)
    GlassCircle.Size = UDim2.new(0, 10, 0, 10)
    GlassCircle.BorderSizePixel = 0
    GlassCircle.ZIndex = 27
    AddCorner(GlassCircle, 10)

    local GlassStroke = Instance.new("UIStroke")
    GlassStroke.Parent = GlassCircle
    GlassStroke.Thickness = 2
    GlassStroke.Color = Color3.fromRGB(140, 180, 230)
    GlassStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local GlassHandle = Instance.new("Frame")
    GlassHandle.Name = "GlassHandle"
    GlassHandle.Parent = SearchIconFrame
    GlassHandle.BackgroundColor3 = Color3.fromRGB(140, 180, 230)
    GlassHandle.BorderSizePixel = 0
    GlassHandle.Position = UDim2.new(0, 9, 0, 9)
    GlassHandle.Size = UDim2.new(0, 6, 0, 2)
    GlassHandle.Rotation = 45
    GlassHandle.ZIndex = 27
    AddCorner(GlassHandle, 1)

    local SearchBarFrame = Instance.new("Frame")
    SearchBarFrame.Name = "SearchBarFrame"
    SearchBarFrame.Parent = Topbar
    SearchBarFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    SearchBarFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    SearchBarFrame.BorderSizePixel = 1
    SearchBarFrame.Position = UDim2.new(1, -315, 0.5, -15)
    SearchBarFrame.Size = UDim2.new(0, 265, 0, 30)
    SearchBarFrame.ZIndex = 30
    SearchBarFrame.Visible = false
    AddCorner(SearchBarFrame, 5)

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "SearchInput"
    SearchInput.Parent = SearchBarFrame
    SearchInput.BackgroundTransparency = 1
    SearchInput.Position = UDim2.new(0, 10, 0, 0)
    SearchInput.Size = UDim2.new(1, -36, 1, 0)
    SearchInput.PlaceholderText = "Search toggles & features..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(90, 120, 160)
    SearchInput.Text = ""
    SearchInput.TextColor3 = Color3.fromRGB(240, 245, 255)
    SearchInput.TextSize = 13
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 31
    ApplyFont(SearchInput)

    local SearchClear = Instance.new("TextButton")
    SearchClear.Name = "SearchClear"
    SearchClear.Parent = SearchBarFrame
    SearchClear.BackgroundTransparency = 1
    SearchClear.Position = UDim2.new(1, -26, 0.5, -9)
    SearchClear.Size = UDim2.new(0, 18, 0, 18)
    SearchClear.Text = ""
    SearchClear.ZIndex = 32
    SearchClear.Visible = false

    local XLine1 = Instance.new("Frame")
    XLine1.Name = "XLine1"
    XLine1.Parent = SearchClear
    XLine1.BackgroundColor3 = Color3.fromRGB(130, 155, 185)
    XLine1.BorderSizePixel = 0
    XLine1.Size = UDim2.new(0, 10, 0, 2)
    XLine1.Position = UDim2.new(0.5, -5, 0.5, -1)
    XLine1.Rotation = 45
    XLine1.ZIndex = 33
    AddCorner(XLine1, 1)

    local XLine2 = Instance.new("Frame")
    XLine2.Name = "XLine2"
    XLine2.Parent = SearchClear
    XLine2.BackgroundColor3 = Color3.fromRGB(130, 155, 185)
    XLine2.BorderSizePixel = 0
    XLine2.Size = UDim2.new(0, 10, 0, 2)
    XLine2.Position = UDim2.new(0.5, -5, 0.5, -1)
    XLine2.Rotation = -45
    XLine2.ZIndex = 33
    AddCorner(XLine2, 1)

    SearchClear.MouseEnter:Connect(function()
        XLine1.BackgroundColor3 = Library.Theme.Accent
        XLine2.BackgroundColor3 = Library.Theme.Accent
    end)
    SearchClear.MouseLeave:Connect(function()
        XLine1.BackgroundColor3 = Color3.fromRGB(130, 155, 185)
        XLine2.BackgroundColor3 = Color3.fromRGB(130, 155, 185)
    end)

    local SearchResultsFrame = Instance.new("Frame")
    SearchResultsFrame.Name = "SearchResultsFrame"
    SearchResultsFrame.Parent = MainBg
    SearchResultsFrame.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    SearchResultsFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    SearchResultsFrame.BorderSizePixel = 1
    SearchResultsFrame.Position = UDim2.new(1, -320, 0, 48)
    SearchResultsFrame.Size = UDim2.new(0, 310, 0, 0)
    SearchResultsFrame.ZIndex = 150
    SearchResultsFrame.ClipsDescendants = true
    SearchResultsFrame.Visible = false
    AddCorner(SearchResultsFrame, 6)

    local SearchScroll = Instance.new("ScrollingFrame")
    SearchScroll.Name = "SearchScroll"
    SearchScroll.Parent = SearchResultsFrame
    SearchScroll.BackgroundTransparency = 1
    SearchScroll.Size = UDim2.new(1, 0, 1, 0)
    SearchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SearchScroll.ScrollBarThickness = 3
    SearchScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
    SearchScroll.ZIndex = 151

    local SearchList = Instance.new("UIListLayout")
    SearchList.Parent = SearchScroll
    SearchList.SortOrder = Enum.SortOrder.LayoutOrder
    SearchList.Padding = UDim.new(0, 4)

    local SearchPadding = Instance.new("UIPadding")
    SearchPadding.Parent = SearchScroll
    SearchPadding.PaddingTop = UDim.new(0, 5)
    SearchPadding.PaddingBottom = UDim.new(0, 5)
    SearchPadding.PaddingLeft = UDim.new(0, 5)
    SearchPadding.PaddingRight = UDim.new(0, 5)

    SearchList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SearchScroll.CanvasSize = UDim2.new(0, 0, 0, SearchList.AbsoluteContentSize.Y + 10)
    end)

    local isSearchOpen = false
    local function ToggleSearch(open)
        if open == nil then isSearchOpen = not isSearchOpen else isSearchOpen = open end
        SearchBarFrame.Visible = isSearchOpen
        if isSearchOpen then
            SearchBtn.BackgroundColor3 = Color3.fromRGB(22, 34, 52)
            SearchBtn.BorderColor3 = Library.Theme.Accent
            GlassStroke.Color = Library.Theme.Accent
            GlassHandle.BackgroundColor3 = Library.Theme.Accent
            SearchInput:CaptureFocus()
        else
            SearchBtn.BackgroundColor3 = Color3.fromRGB(16, 24, 38)
            SearchBtn.BorderColor3 = Color3.fromRGB(28, 40, 60)
            GlassStroke.Color = Color3.fromRGB(140, 180, 230)
            GlassHandle.BackgroundColor3 = Color3.fromRGB(140, 180, 230)
            SearchInput.Text = ""
            SearchClear.Visible = false
            SearchResultsFrame.Visible = false
        end
    end

    SearchBtn.MouseEnter:Connect(function()
        TweenService:Create(GlassStroke, TweenInfo.new(0.15), {Color = Library.Theme.Accent}):Play()
        TweenService:Create(GlassHandle, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Accent}):Play()
        TweenService:Create(SearchBtn, TweenInfo.new(0.15), {BorderColor3 = Library.Theme.Accent, BackgroundColor3 = Color3.fromRGB(22, 34, 52)}):Play()
    end)
    SearchBtn.MouseLeave:Connect(function()
        if not isSearchOpen then
            TweenService:Create(GlassStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(140, 180, 230)}):Play()
            TweenService:Create(GlassHandle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(140, 180, 230)}):Play()
            TweenService:Create(SearchBtn, TweenInfo.new(0.15), {BorderColor3 = Color3.fromRGB(28, 40, 60), BackgroundColor3 = Color3.fromRGB(16, 24, 38)}):Play()
        end
    end)

    SearchBtn.MouseButton1Click:Connect(function()
        ToggleSearch()
    end)

    SearchClear.MouseButton1Click:Connect(function()
        SearchInput.Text = ""
        SearchResultsFrame.Visible = false
        SearchClear.Visible = false
    end)

    local function RenderSearchResults(query)
        for _, child in ipairs(SearchScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        if not query or query == "" then
            SearchResultsFrame.Visible = false
            return
        end

        local lowerQ = string.lower(query)
        local matches = {}
        for _, item in ipairs(Library.SearchableElements) do
            if string.find(string.lower(item.Name), lowerQ, 1, true) or string.find(string.lower(item.TabName), lowerQ, 1, true) then
                table.insert(matches, item)
            end
        end

        if #matches == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Parent = SearchScroll
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Size = UDim2.new(1, 0, 0, 28)
            emptyLabel.Text = "No matching toggles found"
            emptyLabel.TextColor3 = Color3.fromRGB(120, 140, 170)
            emptyLabel.TextSize = 13
            emptyLabel.ZIndex = 152
            ApplyFont(emptyLabel)
            SearchResultsFrame.Visible = true
            SearchResultsFrame.Size = UDim2.new(0, 310, 0, 38)
            return
        end

        SearchResultsFrame.Visible = true
        local frameHeight = math.min(260, (#matches * 36) + 12)
        SearchResultsFrame.Size = UDim2.new(0, 310, 0, frameHeight)

        for _, item in ipairs(matches) do
            local row = Instance.new("Frame")
            row.Parent = SearchScroll
            row.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BorderSizePixel = 1
            row.BorderColor3 = Color3.fromRGB(24, 34, 50)
            row.ZIndex = 152
            AddCorner(row, 4)

            local rowBtn = Instance.new("TextButton")
            rowBtn.Parent = row
            rowBtn.BackgroundTransparency = 1
            rowBtn.Position = UDim2.new(0, 8, 0, 0)
            rowBtn.Size = UDim2.new(1, -40, 1, 0)
            rowBtn.Text = item.Name .. "  [" .. item.TabName .. "]"
            rowBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
            rowBtn.TextSize = 12
            rowBtn.TextXAlignment = Enum.TextXAlignment.Left
            rowBtn.TextTruncate = Enum.TextTruncate.AtEnd
            rowBtn.ZIndex = 153
            ApplyFont(rowBtn)

            rowBtn.MouseEnter:Connect(function()
                rowBtn.TextColor3 = Library.Theme.Accent
            end)
            rowBtn.MouseLeave:Connect(function()
                rowBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
            end)
            rowBtn.MouseButton1Click:Connect(function()
                if item.SwitchToTab then item.SwitchToTab() end
            end)

            if item.Type == "Toggle" then
                local chk = Instance.new("TextButton")
                chk.Parent = row
                chk.BackgroundColor3 = item.GetState() and Library.Theme.Accent or Color3.fromRGB(18, 24, 36)
                chk.BorderSizePixel = 1
                chk.BorderColor3 = Color3.fromRGB(28, 40, 60)
                chk.Position = UDim2.new(1, -26, 0.5, -8)
                chk.Size = UDim2.new(0, 16, 0, 16)
                chk.Text = ""
                chk.ZIndex = 154
                AddCorner(chk, 3)

                chk.MouseButton1Click:Connect(function()
                    local cur = item.GetState()
                    item.SetState(not cur)
                    chk.BackgroundColor3 = (not cur) and Library.Theme.Accent or Color3.fromRGB(18, 24, 36)
                end)
            end
        end
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        SearchClear.Visible = (SearchInput.Text ~= "")
        RenderSearchResults(SearchInput.Text)
    end)

    Library:RegisterTheme(MainBg, "Background", "BackgroundColor3")
    Library:RegisterTheme(TitleLabel, "Text", "TextColor3")

    local TabBar = Instance.new("ScrollingFrame")
    TabBar.Name = "TabBar"
    TabBar.Parent = MainBg
    TabBar.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    TabBar.Position = UDim2.new(0, 8, 0, 48)
    TabBar.Size = UDim2.new(0.24, -8, 1, -56)
    TabBar.BorderSizePixel = 1
    TabBar.BorderColor3 = Color3.fromRGB(18, 26, 38)
    TabBar.ScrollBarThickness = 3
    TabBar.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.Active = true
    AddCorner(TabBar, 5)
    Library:RegisterTheme(TabBar, "Background", "BackgroundColor3+1")

    local TabBarList = Instance.new("UIListLayout")
    TabBarList.Parent = TabBar
    TabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabBarList.FillDirection = Enum.FillDirection.Vertical
    TabBarList.SortOrder = Enum.SortOrder.LayoutOrder
    TabBarList.Padding = UDim.new(0, 5)

    local TabBarPadding = Instance.new("UIPadding")
    TabBarPadding.Parent = TabBar
    TabBarPadding.PaddingTop = UDim.new(0, 6)
    TabBarPadding.PaddingBottom = UDim.new(0, 6)
    TabBarPadding.PaddingLeft = UDim.new(0, 5)
    TabBarPadding.PaddingRight = UDim.new(0, 5)

    TabBarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabBar.CanvasSize = UDim2.new(0, 0, 0, TabBarList.AbsoluteContentSize.Y + 12)
    end)

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Parent = MainBg
    Container.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0.24, 6, 0, 48)
    Container.Size = UDim2.new(0.76, -14, 1, -56)
    Container.BorderSizePixel = 0

    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Parent = OuterFrame
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Position = UDim2.new(1, -24, 1, -24)
    ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
    ResizeHandle.Text = "◢"
    ResizeHandle.TextColor3 = Color3.fromRGB(100, 130, 170)
    ResizeHandle.TextSize = 18
    ResizeHandle.Font = Enum.Font.SourceSansBold
    ResizeHandle.ZIndex = 100

    ResizeHandle.MouseEnter:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.2), {TextColor3 = Library.Theme.Accent}):Play()
    end)
    ResizeHandle.MouseLeave:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(100, 130, 170)}):Play()
    end)
    
    local DraggingResize, ResizeInput, ResizeStart, StartSize = false, nil, nil, nil
    local function UpdateResize(input)
        local Delta = input.Position - ResizeStart
        local newWidth = math.max(540, StartSize.X + Delta.X)
        local newHeight = math.max(420, StartSize.Y + Delta.Y)
        OuterFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            DraggingResize = true
            ResizeStart = input.Position
            StartSize = OuterFrame.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then DraggingResize = false end
            end)
        end
    end)
    ResizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            ResizeInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == ResizeInput and DraggingResize then UpdateResize(input) end
    end)

    Library.ToggleKey = Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Toggled = not Library.Toggled
            OuterFrame.Visible = Library.Toggled
        end
    end)

    local KeybindList = Instance.new("Frame")
    KeybindList.Name = "KeybindList"
    KeybindList.Parent = ScreenGui
    KeybindList.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    KeybindList.Position = UDim2.new(0, 20, 0.5, 0)
    KeybindList.Size = UDim2.new(0, 180, 0, 25)
    KeybindList.BorderSizePixel = 1
    KeybindList.BorderColor3 = Color3.fromRGB(22, 32, 48)
    KeybindList.ClipsDescendants = true
    KeybindList.Visible = false
    MakeDraggable(KeybindList, KeybindList)
    Library.KeybindList = KeybindList
    AddCorner(KeybindList, 5)
    
    local keybindLine, keybindGradient = CreateAnimatedGradientBar(KeybindList)
    Library:RegisterTheme(keybindGradient, "Accent", "Gradient")

    local KeybindListTitle = Instance.new("TextLabel")
    KeybindListTitle.Parent = KeybindList
    KeybindListTitle.BackgroundTransparency = 1
    KeybindListTitle.Position = UDim2.new(0, 0, 0, 2)
    KeybindListTitle.Size = UDim2.new(1, 0, 0, 23)
    KeybindListTitle.Text = "Keybinds"
    KeybindListTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
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
    ContextMenu.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    ContextMenu.Size = UDim2.new(0, 200, 0, 55)
    ContextMenu.Position = UDim2.new(0, 0, 0, 0)
    ContextMenu.BorderSizePixel = 1
    ContextMenu.BorderColor3 = Color3.fromRGB(28, 40, 60)
    ContextMenu.ZIndex = 100
    AddCorner(ContextMenu, 5)

    local function CloseContextMenu()
        Backdrop.Visible = false
    end

    Backdrop.MouseButton1Click:Connect(CloseContextMenu)

    local function ShowContextMenu(pos, elementData)
        for _, v in ipairs(ContextMenu:GetChildren()) do
            if not v:IsA("UICorner") then
                v:Destroy()
            end
        end

        ContextMenu.Position = UDim2.new(0, pos.X, 0, pos.Y)
        ContextMenu.Size = UDim2.new(0, 200, 0, 55)
        Backdrop.Visible = true

        local TitleRow = Instance.new("TextLabel")
        TitleRow.Parent = ContextMenu
        TitleRow.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
        TitleRow.Size = UDim2.new(1, 0, 0, 20)
        TitleRow.Position = UDim2.new(0, 0, 0, 0)
        TitleRow.Text = "  " .. elementData.Name
        TitleRow.TextColor3 = Color3.fromRGB(0, 170, 255)
        TitleRow.TextSize = 12
        TitleRow.TextXAlignment = Enum.TextXAlignment.Left
        TitleRow.BorderSizePixel = 0
        TitleRow.ZIndex = 101
        ApplyFont(TitleRow)
        AddCorner(TitleRow, 4)

        local BindRow = Instance.new("Frame")
        BindRow.Parent = ContextMenu
        BindRow.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
        BindRow.Size = UDim2.new(1, 0, 0, 30)
        BindRow.Position = UDim2.new(0, 0, 0, 22)
        BindRow.BorderSizePixel = 0
        BindRow.ZIndex = 101
        AddCorner(BindRow, 4)

        local existingBind = Library.Keybinds[elementData.Id]

        local PlusBtn = Instance.new("TextButton")
        PlusBtn.Parent = BindRow
        PlusBtn.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
        PlusBtn.Size = UDim2.new(0, 25, 0, 22)
        PlusBtn.Position = UDim2.new(0, 5, 0, 4)
        PlusBtn.Text = existingBind and "-" or "+"
        PlusBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
        PlusBtn.TextSize = 16
        PlusBtn.BorderSizePixel = 1
        PlusBtn.BorderColor3 = Color3.fromRGB(28, 40, 60)
        PlusBtn.ZIndex = 102
        PlusBtn.AutoButtonColor = false
        ApplyFont(PlusBtn)
        AddCorner(PlusBtn, 3)

        local KeyBox = Instance.new("TextButton")
        KeyBox.Parent = BindRow
        KeyBox.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
        KeyBox.Size = UDim2.new(0, 60, 0, 22)
        KeyBox.Position = UDim2.new(0, 35, 0, 4)
        KeyBox.Text = existingBind and existingBind.Key.Name or "..."
        KeyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
        KeyBox.TextSize = 12
        KeyBox.BorderSizePixel = 1
        KeyBox.BorderColor3 = Color3.fromRGB(28, 40, 60)
        KeyBox.ZIndex = 102
        KeyBox.AutoButtonColor = false
        KeyBox.Visible = existingBind ~= nil
        ApplyFont(KeyBox)
        AddCorner(KeyBox, 3)

        local ModeBtn = Instance.new("TextButton")
        ModeBtn.Parent = BindRow
        ModeBtn.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
        ModeBtn.Size = UDim2.new(0, 90, 0, 22)
        ModeBtn.Position = UDim2.new(0, 100, 0, 4)
        ModeBtn.Text = existingBind and existingBind.Mode or "Toggle"
        ModeBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
        ModeBtn.TextSize = 12
        ModeBtn.BorderSizePixel = 1
        ModeBtn.BorderColor3 = Color3.fromRGB(28, 40, 60)
        ModeBtn.ZIndex = 102
        ModeBtn.AutoButtonColor = false
        ModeBtn.Visible = existingBind ~= nil
        ApplyFont(ModeBtn)
        AddCorner(ModeBtn, 3)

        local selectedKey = existingBind and existingBind.Key or nil
        local selectedMode = existingBind and existingBind.Mode or "Toggle"

        local function SaveKeybind()
            if selectedKey then
                Library.Keybinds[elementData.Id] = {Key = selectedKey, Mode = selectedMode, Data = elementData}
            end
        end

        PlusBtn.MouseButton1Click:Connect(function()
            if KeyBox.Visible then
                Library.Keybinds[elementData.Id] = nil
                KeyBox.Visible = false
                ModeBtn.Visible = false
                PlusBtn.Text = "+"
                selectedKey = nil
            else
                KeyBox.Visible = true
                ModeBtn.Visible = true
                PlusBtn.Text = "-"
                KeyBox.Text = "..."
                KeyBox.TextColor3 = Color3.fromRGB(0, 170, 255)

                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            conn:Disconnect()
                            KeyBox.Text = "..."
                            KeyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
                            return
                        end
                        conn:Disconnect()
                        selectedKey = input.KeyCode
                        KeyBox.Text = input.KeyCode.Name
                        KeyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
                        SaveKeybind()
                    end
                end)
            end
        end)

        KeyBox.MouseButton1Click:Connect(function()
            KeyBox.Text = "..."
            KeyBox.TextColor3 = Color3.fromRGB(0, 170, 255)

            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        conn:Disconnect()
                        KeyBox.Text = selectedKey and selectedKey.Name or "..."
                        KeyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
                        return
                    end
                    conn:Disconnect()
                    selectedKey = input.KeyCode
                    KeyBox.Text = input.KeyCode.Name
                    KeyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
                    SaveKeybind()
                end
            end)
        end)

        local modes = {"Toggle", "Hold", "Always"}
        local modeDropOpen = false

        local ModeItemsFrame = Instance.new("Frame")
        ModeItemsFrame.Parent = ContextMenu
        ModeItemsFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
        ModeItemsFrame.Size = UDim2.new(0, 90, 0, #modes * 20)
        ModeItemsFrame.Position = UDim2.new(0, 100, 0, 52)
        ModeItemsFrame.BorderSizePixel = 1
        ModeItemsFrame.BorderColor3 = Color3.fromRGB(28, 40, 60)
        ModeItemsFrame.ZIndex = 110
        ModeItemsFrame.Visible = false
        AddCorner(ModeItemsFrame, 3)

        local ModeItemList = Instance.new("UIListLayout")
        ModeItemList.Parent = ModeItemsFrame
        ModeItemList.SortOrder = Enum.SortOrder.LayoutOrder

        for _, m in ipairs(modes) do
            local mItem = Instance.new("TextButton")
            mItem.Parent = ModeItemsFrame
            mItem.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            mItem.Size = UDim2.new(1, 0, 0, 20)
            mItem.Text = m
            mItem.TextColor3 = Color3.fromRGB(240, 245, 255)
            mItem.TextSize = 12
            mItem.BorderSizePixel = 0
            mItem.ZIndex = 111
            mItem.AutoButtonColor = false
            mItem.Font = Enum.Font.Code
            ApplyFont(mItem)
            AddCorner(mItem, 2)

            mItem.MouseEnter:Connect(function()
                mItem.TextColor3 = Color3.fromRGB(0, 170, 255)
            end)
            mItem.MouseLeave:Connect(function()
                mItem.TextColor3 = Color3.fromRGB(240, 245, 255)
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
                lbl.TextColor3 = Color3.fromRGB(240, 245, 255)
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 3
                lbl.Font = Enum.Font.Code
                pcall(function() ApplyFont(lbl) end)
            end
            KeybindList.Size = UDim2.new(0, 180, 0, 25 + (#activeBinds * 20))
        else
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

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {}
    }

    function WindowObj:CreateTab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name.."_Btn"
        TabBtn.Parent = TabBar
        TabBtn.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
        TabBtn.BackgroundTransparency = 0
        TabBtn.Size = UDim2.new(1, 0, 0, 42)
        TabBtn.Text = ""
        TabBtn.BorderSizePixel = 1
        TabBtn.BorderColor3 = Color3.fromRGB(24, 34, 50)
        TabBtn.AutoButtonColor = false
        AddCorner(TabBtn, 5)
        
        local TabAccent = Instance.new("Frame")
        TabAccent.Name = "TabAccent"
        TabAccent.Parent = TabBtn
        TabAccent.Size = UDim2.new(0, 4, 0.65, 0)
        TabAccent.Position = UDim2.new(0, 4, 0.175, 0)
        TabAccent.BorderSizePixel = 0
        TabAccent.Visible = false
        AddCorner(TabAccent, 2)
        Library:RegisterTheme(TabAccent, "Accent", "BackgroundColor3")

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TabLabel"
        TabLabel.Parent = TabBtn
        TabLabel.BackgroundTransparency = 1
        TabLabel.Position = UDim2.new(0, 20, 0, 0)
        TabLabel.Size = UDim2.new(1, -26, 1, 0)
        TabLabel.Text = name
        TabLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
        TabLabel.TextSize = 15
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.TextTruncate = Enum.TextTruncate.AtEnd
        ApplyFont(TabLabel)

        TabBtn.MouseEnter:Connect(function()
            if WindowObj.CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 24, 36)}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if WindowObj.CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 18, 26)}):Play()
            end
        end)

        local TabPage = Instance.new("Frame")
        TabPage.Name = name.."_Page"
        TabPage.Parent = Container
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.Visible = false

        local LeftColumn = Instance.new("ScrollingFrame")
        LeftColumn.Name = "LeftColumn"
        LeftColumn.Parent = TabPage
        LeftColumn.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
        LeftColumn.Position = UDim2.new(0, 0, 0, 0)
        LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
        LeftColumn.BorderSizePixel = 1
        LeftColumn.BorderColor3 = Color3.fromRGB(18, 26, 38)
        LeftColumn.ScrollBarThickness = 3
        LeftColumn.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
        LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftColumn.Active = true
        AddCorner(LeftColumn, 5)

        local LeftList = Instance.new("UIListLayout")
        LeftList.Parent = LeftColumn
        LeftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        LeftList.SortOrder = Enum.SortOrder.LayoutOrder
        LeftList.Padding = UDim.new(0, 6)

        local LeftPadding = Instance.new("UIPadding")
        LeftPadding.Parent = LeftColumn
        LeftPadding.PaddingTop = UDim.new(0, 6)
        LeftPadding.PaddingBottom = UDim.new(0, 6)

        LeftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            LeftColumn.CanvasSize = UDim2.new(0, 0, 0, LeftList.AbsoluteContentSize.Y + 12)
        end)
        Library:RegisterTheme(LeftColumn, "Background", "BackgroundColor3+1")

        local RightColumn = Instance.new("ScrollingFrame")
        RightColumn.Name = "RightColumn"
        RightColumn.Parent = TabPage
        RightColumn.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
        RightColumn.Position = UDim2.new(0.5, 4, 0, 0)
        RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
        RightColumn.BorderSizePixel = 1
        RightColumn.BorderColor3 = Color3.fromRGB(18, 26, 38)
        RightColumn.ScrollBarThickness = 3
        RightColumn.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
        RightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightColumn.Active = true
        AddCorner(RightColumn, 5)

        local RightList = Instance.new("UIListLayout")
        RightList.Parent = RightColumn
        RightList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Padding = UDim.new(0, 6)

        local RightPadding = Instance.new("UIPadding")
        RightPadding.Parent = RightColumn
        RightPadding.PaddingTop = UDim.new(0, 6)
        RightPadding.PaddingBottom = UDim.new(0, 6)

        RightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            RightColumn.CanvasSize = UDim2.new(0, 0, 0, RightList.AbsoluteContentSize.Y + 12)
        end)
        Library:RegisterTheme(RightColumn, "Background", "BackgroundColor3+1")

        local SubTabBar = Instance.new("Frame")
        SubTabBar.Name = "SubTabBar"
        SubTabBar.Parent = TabPage
        SubTabBar.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
        SubTabBar.Position = UDim2.new(0, 0, 0, 0)
        SubTabBar.Size = UDim2.new(1, 0, 0, 0)
        SubTabBar.BorderSizePixel = 1
        SubTabBar.BorderColor3 = Color3.fromRGB(18, 26, 38)
        SubTabBar.Visible = false
        AddCorner(SubTabBar, 4)

        local SubTabBarList = Instance.new("UIListLayout")
        SubTabBarList.Parent = SubTabBar
        SubTabBarList.FillDirection = Enum.FillDirection.Horizontal
        SubTabBarList.SortOrder = Enum.SortOrder.LayoutOrder
        SubTabBarList.Padding = UDim.new(0, 3)

        table.insert(WindowObj.Tabs, {Btn = TabBtn, Page = TabPage, Label = TabLabel})
        
        Library.OnTabChange.Event:Connect(function()
            if WindowObj.CurrentTab ~= name then
                TabPage.Visible = false
                TabBtn.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
                TabLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
                TabAccent.Visible = false
            end
        end)

        TabBtn.MouseButton1Click:Connect(function()
            WindowObj.CurrentTab = name
            Library.OnTabChange:Fire()
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 46)
            TabLabel.TextColor3 = Library.Theme.Accent
            TabAccent.Visible = true
        end)

        if #WindowObj.Tabs == 1 then
            WindowObj.CurrentTab = name
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 46)
            TabLabel.TextColor3 = Library.Theme.Accent
            TabAccent.Visible = true
        end
        
        Library:RegisterTheme(function(color)
            if WindowObj.CurrentTab == name then
                TabLabel.TextColor3 = color
            end
        end, "Accent", "Custom")

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
            if not SubTabBar.Visible then
                SubTabBar.Visible = true
                SubTabBar.Size = UDim2.new(1, 0, 0, 26)
                LeftColumn.Position = UDim2.new(0, 0, 0, 30)
                LeftColumn.Size = UDim2.new(0.5, -4, 1, -30)
                RightColumn.Position = UDim2.new(0.5, 4, 0, 30)
                RightColumn.Size = UDim2.new(0.5, -4, 1, -30)
            end

            local subTabBtn = Instance.new("TextButton")
            subTabBtn.Parent = SubTabBar
            subTabBtn.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
            subTabBtn.BackgroundTransparency = 0
            subTabBtn.Size = UDim2.new(0, 95, 1, 0)
            subTabBtn.Text = name
            subTabBtn.TextColor3 = Color3.fromRGB(130, 150, 180)
            subTabBtn.TextSize = 13
            subTabBtn.BorderSizePixel = 1
            subTabBtn.BorderColor3 = Color3.fromRGB(24, 34, 50)
            subTabBtn.AutoButtonColor = false
            ApplyFont(subTabBtn)
            AddCorner(subTabBtn, 4)

            local SubTabAccent = Instance.new("Frame")
            SubTabAccent.Parent = subTabBtn
            SubTabAccent.Size = UDim2.new(1, 0, 0, 2)
            SubTabAccent.Position = UDim2.new(0, 0, 1, -2)
            SubTabAccent.BorderSizePixel = 0
            SubTabAccent.Visible = false
            Library:RegisterTheme(SubTabAccent, "Accent", "BackgroundColor3")

            table.insert(subTabs, {Name = name, Btn = subTabBtn, Elements = {}})

            local function switchSubTab(targetName)
                currentSubTab = targetName
                for _, st in ipairs(subTabs) do
                    local isTarget = (st.Name == targetName)
                    st.Btn.TextColor3 = isTarget and Library.Theme.Accent or Color3.fromRGB(130, 150, 180)
                    st.Btn.BackgroundColor3 = isTarget and Color3.fromRGB(20, 30, 46) or Color3.fromRGB(14, 18, 26)
                    for _, elem in ipairs(st.Elements) do
                        elem.Visible = isTarget
                    end
                end
            end

            subTabBtn.MouseButton1Click:Connect(function()
                switchSubTab(name)
            end)

            if #subTabs == 1 then
                switchSubTab(name)
            end

            local SubTab = {}
            function SubTab:CreateSection(sName, side)
                return Tab:CreateSection(sName, side)
            end
            function SubTab:CreateButton(opts) return Tab:CreateButton(opts) end
            function SubTab:CreateInputButton(opts) return Tab:CreateInputButton(opts) end
            function SubTab:CreateTextBox(opts) return Tab:CreateTextBox(opts) end
            function SubTab:CreateToggle(opts) return Tab:CreateToggle(opts) end
            function SubTab:CreateSlider(opts) return Tab:CreateSlider(opts) end
            function SubTab:CreateDropdown(opts) return Tab:CreateDropdown(opts) end
            function SubTab:CreateColorPicker(opts) return Tab:CreateColorPicker(opts) end
            function SubTab:CreateViewport(opts) return Tab:CreateViewport(opts) end

            return SubTab
        end

        local function TrackElement(element)
            if #subTabs > 0 then
                local currentST = nil
                for _, st in ipairs(subTabs) do
                    if st.Name == currentSubTab then
                        currentST = st
                        break
                    end
                end
                if currentST then
                    table.insert(currentST.Elements, element)
                else
                    table.insert(subTabs[1].Elements, element)
                end
                if subTabs[1] ~= currentSubTab then
                    element.Visible = false
                end
            end
        end

        function Tab:CreateSection(name, side)
            local column = side == "right" and RightColumn or LeftColumn
            
            local GroupboxOuter = Instance.new("Frame")
            GroupboxOuter.Parent = column
            GroupboxOuter.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
            GroupboxOuter.BorderSizePixel = 1
            GroupboxOuter.BorderColor3 = Color3.fromRGB(20, 30, 45)
            GroupboxOuter.Size = UDim2.new(1, -10, 0, 26)
            AddCorner(GroupboxOuter, 5)
            
            local GroupboxInner = Instance.new("Frame")
            GroupboxInner.Parent = GroupboxOuter
            GroupboxInner.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
            GroupboxInner.BorderSizePixel = 0
            GroupboxInner.Size = UDim2.new(1, -2, 1, -2)
            GroupboxInner.Position = UDim2.new(0, 1, 0, 1)
            AddCorner(GroupboxInner, 4)

            local AccentLine = Instance.new("Frame")
            AccentLine.Parent = GroupboxInner
            AccentLine.Size = UDim2.new(1, 0, 0, 1)
            AccentLine.Position = UDim2.new(0, 0, 0, 0)
            AccentLine.BorderSizePixel = 0
            Library:RegisterTheme(AccentLine, "Accent", "BackgroundColor3")

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Parent = GroupboxInner
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Size = UDim2.new(1, -12, 0, 18)
            TitleLabel.Position = UDim2.new(0, 8, 0, 5)
            TitleLabel.Text = name
            TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(TitleLabel)

            local Layout = Instance.new("UIListLayout")
            Layout.Parent = GroupboxInner
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 6)

            local Padding = Instance.new("UIPadding")
            Padding.Parent = GroupboxInner
            Padding.PaddingTop = UDim.new(0, 26)
            Padding.PaddingLeft = UDim.new(0, 8)
            Padding.PaddingRight = UDim.new(0, 8)
            Padding.PaddingBottom = UDim.new(0, 8)

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                GroupboxOuter.Size = UDim2.new(1, -10, 0, Layout.AbsoluteContentSize.Y + 36)
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
            Btn.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            Btn.Size = UDim2.new(1, 0, 0, 28)
            Btn.Text = btnName
            Btn.TextColor3 = Color3.fromRGB(200, 215, 235)
            Btn.TextSize = 13
            Btn.BorderSizePixel = 1
            Btn.BorderColor3 = Color3.fromRGB(28, 40, 60)
            Btn.AutoButtonColor = false
            ApplyFont(Btn)
            AddCorner(Btn, 4)

            Library:RegisterTheme(Btn, "Text", "TextColor3")

            Btn.MouseEnter:Connect(function() 
                Btn.BorderColor3 = Library.Theme.Accent 
            end)
            Btn.MouseLeave:Connect(function() 
                Btn.BorderColor3 = Color3.fromRGB(28, 40, 60) 
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

        function Tab:CreateInputButton(options)
            local btnName = options.Name or "Input Button"
            local callback = options.Callback or function() end
            local side = options.Side or "left"
            local parent = GetParent(side)

            local BtnBox = Instance.new("TextBox")
            BtnBox.Parent = parent
            BtnBox.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            BtnBox.Size = UDim2.new(1, 0, 0, 28)
            BtnBox.Text = btnName
            BtnBox.TextColor3 = Color3.fromRGB(200, 215, 235)
            BtnBox.TextSize = 13
            BtnBox.BorderSizePixel = 1
            BtnBox.BorderColor3 = Color3.fromRGB(28, 40, 60)
            BtnBox.ClearTextOnFocus = true
            ApplyFont(BtnBox)
            AddCorner(BtnBox, 4)

            Library:RegisterTheme(BtnBox, "Text", "TextColor3")

            BtnBox.MouseEnter:Connect(function() 
                BtnBox.BorderColor3 = Library.Theme.Accent 
            end)
            BtnBox.MouseLeave:Connect(function() 
                BtnBox.BorderColor3 = Color3.fromRGB(28, 40, 60) 
            end)
            
            BtnBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and BtnBox.Text ~= "" and BtnBox.Text ~= btnName then
                    callback(BtnBox.Text)
                end
                BtnBox.Text = btnName
            end)

            TrackElement(BtnBox)
            
            return {
                SetText = function(self, text) BtnBox.Text = text end,
                SetColor = function(self, color) BtnBox.TextColor3 = color end,
                Show = function(self) BtnBox.Visible = true end,
                Hide = function(self) BtnBox.Visible = false end,
                CaptureFocus = function(self) BtnBox:CaptureFocus() end,
                Inst = BtnBox
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
            TBox.Size = UDim2.new(1, 0, 0, 28)
            TBox.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            TBox.Text = default ~= "" and default or tName
            TBox.PlaceholderText = tName
            TBox.TextColor3 = Color3.fromRGB(200, 215, 235)
            TBox.TextSize = 13
            TBox.BorderSizePixel = 1
            TBox.BorderColor3 = Color3.fromRGB(28, 40, 60)
            TBox.ClearTextOnFocus = clearOnFocus
            TBox.Parent = parent
            ApplyFont(TBox)
            AddCorner(TBox, 4)

            Library:RegisterTheme(TBox, "Text", "TextColor3")

            TBox.MouseEnter:Connect(function() 
                TBox.BorderColor3 = Library.Theme.Accent 
            end)
            TBox.MouseLeave:Connect(function() 
                TBox.BorderColor3 = Color3.fromRGB(28, 40, 60) 
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
            ToggleContainer.Size = UDim2.new(1, 0, 0, 22)
            
            local CheckBox = Instance.new("Frame")
            CheckBox.Parent = ToggleContainer
            CheckBox.BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(18, 24, 36)
            CheckBox.Position = UDim2.new(0, 2, 0.5, -8)
            CheckBox.Size = UDim2.new(0, 16, 0, 16)
            CheckBox.BorderSizePixel = 1
            CheckBox.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(CheckBox, 4)

            local TTitle = Instance.new("TextLabel")
            TTitle.Parent = ToggleContainer
            TTitle.BackgroundTransparency = 1
            TTitle.Position = UDim2.new(0, 26, 0, 0)
            TTitle.Size = UDim2.new(1, -26, 1, 0)
            TTitle.Text = tName
            TTitle.TextColor3 = Color3.fromRGB(200, 215, 235)
            TTitle.TextSize = 13
            TTitle.TextXAlignment = Enum.TextXAlignment.Left
            TTitle.TextTruncate = Enum.TextTruncate.AtEnd
            ApplyFont(TTitle)

            local Btn = Instance.new("TextButton")
            Btn.Parent = ToggleContainer
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = ""

            local function SetState(newState)
                state = newState
                if flag then Library.Flags[flag] = state end
                TweenService:Create(CheckBox, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(18, 24, 36)}):Play()
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

            table.insert(Library.SearchableElements, {
                Name = tName,
                Type = "Toggle",
                TabName = name,
                GetState = function() return state end,
                SetState = function(val) SetState(val) end,
                SwitchToTab = function()
                    WindowObj.CurrentTab = name
                    Library.OnTabChange:Fire()
                    TabPage.Visible = true
                    TabBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 46)
                    TabLabel.TextColor3 = Library.Theme.Accent
                    TabAccent.Visible = true
                end
            })

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
            local rounding = options.Rounding or 0
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
            SliderContainer.Size = UDim2.new(1, 0, 0, 38)

            local STitle = Instance.new("TextLabel")
            STitle.Parent = SliderContainer
            STitle.BackgroundTransparency = 1
            STitle.Size = UDim2.new(1, 0, 0, 16)
            STitle.Text = sName
            STitle.TextColor3 = Color3.fromRGB(200, 215, 235)
            STitle.TextSize = 13
            STitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(STitle)

            local TrackOuter = Instance.new("Frame")
            TrackOuter.Parent = SliderContainer
            TrackOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            TrackOuter.Position = UDim2.new(0, 0, 0, 20)
            TrackOuter.Size = UDim2.new(1, 0, 0, 16)
            TrackOuter.BorderSizePixel = 1
            TrackOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(TrackOuter, 4)

            local TrackInner = Instance.new("Frame")
            TrackInner.Parent = TrackOuter
            TrackInner.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            TrackInner.Size = UDim2.new(1, -2, 1, -2)
            TrackInner.Position = UDim2.new(0, 1, 0, 1)
            TrackInner.BorderSizePixel = 0
            AddCorner(TrackInner, 4)

            local Fill = Instance.new("Frame")
            Fill.Parent = TrackInner
            Fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BorderSizePixel = 0
            AddCorner(Fill, 3)

            local ValueLabel = Instance.new("TextBox")
            ValueLabel.Parent = TrackOuter
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Size = UDim2.new(1, 0, 1, 0)
            ValueLabel.Text = tostring(default) .. "/" .. tostring(max)
            ValueLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
            ValueLabel.TextSize = 12
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
                local num = tonumber(value) or min
                local power = 10 ^ rounding
                num = math.floor(num * power + 0.5) / power
                value = math.clamp(num, min, max)
                local pct = (value - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                
                local fmt = "%." .. rounding .. "f"
                ValueLabel.Text = string.format(fmt, value) .. "/" .. string.format(fmt, max)
                
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
                local value = min + (max - min) * pct
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
            DropdownContainer.Size = UDim2.new(1, 0, 0, 48)
            DropdownContainer.ClipsDescendants = false

            local DTitle = Instance.new("TextLabel")
            DTitle.Parent = DropdownContainer
            DTitle.BackgroundTransparency = 1
            DTitle.Size = UDim2.new(1, 0, 0, 16)
            DTitle.Text = dName
            DTitle.TextColor3 = Color3.fromRGB(200, 215, 235)
            DTitle.TextSize = 13
            DTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(DTitle)

            local DropdownOuter = Instance.new("Frame")
            DropdownOuter.Parent = DropdownContainer
            DropdownOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            DropdownOuter.Position = UDim2.new(0, 0, 0, 20)
            DropdownOuter.Size = UDim2.new(1, 0, 0, 24)
            DropdownOuter.BorderSizePixel = 1
            DropdownOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            DropdownOuter.ZIndex = 5
            AddCorner(DropdownOuter, 4)

            local DropdownInner = Instance.new("Frame")
            DropdownInner.Parent = DropdownOuter
            DropdownInner.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            DropdownInner.Size = UDim2.new(1, -2, 1, -2)
            DropdownInner.Position = UDim2.new(0, 1, 0, 1)
            DropdownInner.BorderSizePixel = 0
            DropdownInner.ZIndex = 5
            AddCorner(DropdownInner, 4)

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Parent = DropdownInner
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Size = UDim2.new(1, 0, 1, 0)
            HeaderBtn.Text = ""
            HeaderBtn.ZIndex = 6

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = DropdownInner
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0, 8, 0, 0)
            SelectedText.Size = UDim2.new(1, -30, 1, 0)
            SelectedText.Text = "None"
            SelectedText.TextColor3 = Color3.fromRGB(200, 215, 235)
            SelectedText.TextSize = 13
            SelectedText.TextXAlignment = Enum.TextXAlignment.Left
            SelectedText.ZIndex = 6
            ApplyFont(SelectedText)

            local Icon = Instance.new("TextLabel")
            Icon.Parent = DropdownInner
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(1, -18, 0, 0)
            Icon.Size = UDim2.new(0, 18, 1, 0)
            Icon.Text = "+"
            Icon.TextColor3 = Color3.fromRGB(200, 215, 235)
            Icon.TextSize = 13
            Icon.ZIndex = 6
            ApplyFont(Icon)

            local ItemContainerOuter = Instance.new("Frame")
            ItemContainerOuter.Parent = DropdownContainer
            ItemContainerOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            ItemContainerOuter.Position = UDim2.new(0, 0, 0, 46)
            ItemContainerOuter.Size = UDim2.new(1, 0, 0, 0)
            ItemContainerOuter.BorderSizePixel = 1
            ItemContainerOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            ItemContainerOuter.ClipsDescendants = true
            ItemContainerOuter.Visible = false
            ItemContainerOuter.ZIndex = 10
            AddCorner(ItemContainerOuter, 4)

            local ItemContainerInner = Instance.new("Frame")
            ItemContainerInner.Parent = ItemContainerOuter
            ItemContainerInner.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
            ItemContainerInner.Size = UDim2.new(1, -2, 1, -2)
            ItemContainerInner.Position = UDim2.new(0, 1, 0, 1)
            ItemContainerInner.BorderSizePixel = 0
            ItemContainerInner.ZIndex = 10
            AddCorner(ItemContainerInner, 4)

            local ItemList = Instance.new("UIListLayout")
            ItemList.Parent = ItemContainerInner
            ItemList.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    ItemContainerOuter.Visible = true
                    ItemContainerOuter.Size = UDim2.new(1, 0, 0, 0)
                    TweenService:Create(ItemContainerOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, (#items * 24) + 4)}):Play()
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

            local setValue

            local function createItemBtn(item)
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = ItemContainerInner
                ItemBtn.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
                ItemBtn.Size = UDim2.new(1, 0, 0, 24)
                ItemBtn.Text = tostring(item)
                ItemBtn.TextColor3 = Color3.fromRGB(200, 215, 235)
                ItemBtn.TextSize = 13
                ItemBtn.AutoButtonColor = false
                ItemBtn.BorderSizePixel = 0
                ItemBtn.ZIndex = 11
                ApplyFont(ItemBtn)
                AddCorner(ItemBtn, 3)

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
                            TweenService:Create(ItemBtn, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200, 215, 235)}):Play()
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
                            btn.TextColor3 = found and Library.Theme.Accent or Color3.fromRGB(200, 215, 235)
                        else
                            btn.TextColor3 = (val == btn.Text) and Library.Theme.Accent or Color3.fromRGB(200, 215, 235)
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
                        ItemContainerOuter.Size = UDim2.new(1, 0, 0, (#items * 24) + 4)
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
            CPOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            CPOuter.Size = UDim2.new(1, -10, 0, 28)
            CPOuter.BorderSizePixel = 1
            CPOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            CPOuter.ClipsDescendants = true
            AddCorner(CPOuter, 4)

            local CPInner = Instance.new("Frame")
            CPInner.Parent = CPOuter
            CPInner.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
            CPInner.Size = UDim2.new(1, -2, 1, -2)
            CPInner.Position = UDim2.new(0, 1, 0, 1)
            CPInner.BorderSizePixel = 1
            CPInner.BorderColor3 = Color3.fromRGB(22, 32, 48)
            AddCorner(CPInner, 4)

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Parent = CPInner
            ToggleBtn.BackgroundTransparency = 1
            ToggleBtn.Size = UDim2.new(1, 0, 0, 26)
            ToggleBtn.Text = ""

            local CPTitle = Instance.new("TextLabel")
            CPTitle.Parent = ToggleBtn
            CPTitle.BackgroundTransparency = 1
            CPTitle.Position = UDim2.new(0, 10, 0, 0)
            CPTitle.Size = UDim2.new(1, -36, 1, 0)
            CPTitle.Text = cName
            CPTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
            CPTitle.TextSize = 13
            CPTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(CPTitle)

            local PreviewOuter = Instance.new("Frame")
            PreviewOuter.Parent = ToggleBtn
            PreviewOuter.Position = UDim2.new(1, -34, 0, 5)
            PreviewOuter.Size = UDim2.new(0, 24, 0, 16)
            PreviewOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            PreviewOuter.BorderSizePixel = 1
            PreviewOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(PreviewOuter, 3)

            local Preview = Instance.new("Frame")
            Preview.Parent = PreviewOuter
            Preview.Size = UDim2.new(1, -2, 1, -2)
            Preview.Position = UDim2.new(0, 1, 0, 1)
            Preview.BackgroundColor3 = defaultColor
            Preview.BorderSizePixel = 0
            AddCorner(Preview, 2)

            local isOpen = false
            ToggleBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local height = useAlpha and 190 or 170
                local targetSize = isOpen and UDim2.new(1, -10, 0, height) or UDim2.new(1, -10, 0, 28)
                TweenService:Create(CPOuter, TweenInfo.new(0.2), {Size = targetSize}):Play()
            end)
            
            Library.OnTabChange.Event:Connect(function()
                if isOpen then
                    isOpen = false
                    TweenService:Create(CPOuter, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 28)}):Play()
                end
            end)

            local SVOuter = Instance.new("Frame")
            SVOuter.Parent = CPInner
            SVOuter.Position = UDim2.new(0, 10, 0, 30)
            SVOuter.Size = UDim2.new(1, -44, 0, 120)
            SVOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            SVOuter.BorderSizePixel = 1
            SVOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(SVOuter, 3)

            local SVMap = Instance.new("ImageLabel")
            SVMap.Parent = SVOuter
            SVMap.Size = UDim2.new(1, -2, 1, -2)
            SVMap.Position = UDim2.new(0, 1, 0, 1)
            SVMap.Image = "rbxassetid://4155801252"
            SVMap.BorderSizePixel = 0
            AddCorner(SVMap, 3)

            local SVSelector = Instance.new("Frame")
            SVSelector.Parent = SVMap
            SVSelector.Size = UDim2.new(0, 6, 0, 6)
            SVSelector.AnchorPoint = Vector2.new(0.5, 0.5)
            SVSelector.Position = UDim2.new(s, 0, 1 - v, 0)
            SVSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SVSelector.BorderSizePixel = 1
            SVSelector.BorderColor3 = Color3.fromRGB(0, 0, 0)

            local HueOuter = Instance.new("Frame")
            HueOuter.Parent = CPInner
            HueOuter.Position = UDim2.new(1, -28, 0, 30)
            HueOuter.Size = UDim2.new(0, 18, 0, 120)
            HueOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            HueOuter.BorderSizePixel = 1
            HueOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(HueOuter, 3)

            local HueMap = Instance.new("Frame")
            HueMap.Parent = HueOuter
            HueMap.Size = UDim2.new(1, -2, 1, -2)
            HueMap.Position = UDim2.new(0, 1, 0, 1)
            HueMap.BorderSizePixel = 0
            AddCorner(HueMap, 3)

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

            local AlphaOuter = Instance.new("Frame")
            AlphaOuter.Parent = CPInner
            AlphaOuter.Position = UDim2.new(0, 10, 0, 160)
            AlphaOuter.Size = UDim2.new(1, -20, 0, 16)
            AlphaOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            AlphaOuter.BorderSizePixel = 1
            AlphaOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AlphaOuter.Visible = useAlpha
            AddCorner(AlphaOuter, 3)

            local AlphaMap = Instance.new("Frame")
            AlphaMap.Parent = AlphaOuter
            AlphaMap.Size = UDim2.new(1, -2, 1, -2)
            AlphaMap.Position = UDim2.new(0, 1, 0, 1)
            AlphaMap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            AlphaMap.BorderSizePixel = 0
            AddCorner(AlphaMap, 3)

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
            local height = options.Height or 220
            local side = options.Side or "right"
            local parent = GetParent(side)

            local VOuter = Instance.new("Frame")
            VOuter.Parent = parent
            VOuter.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
            VOuter.Size = UDim2.new(1, -10, 0, height)
            VOuter.BorderSizePixel = 1
            VOuter.BorderColor3 = Color3.fromRGB(28, 40, 60)
            AddCorner(VOuter, 4)

            local VTitle = Instance.new("TextLabel")
            VTitle.Parent = VOuter
            VTitle.BackgroundTransparency = 1
            VTitle.Position = UDim2.new(0, 8, 0, 0)
            VTitle.Size = UDim2.new(1, -16, 0, 22)
            VTitle.Text = vName
            VTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
            VTitle.TextSize = 13
            VTitle.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(VTitle)

            local Viewport = Instance.new("ViewportFrame")
            Viewport.Parent = VOuter
            Viewport.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
            Viewport.BorderSizePixel = 1
            Viewport.BorderColor3 = Color3.fromRGB(22, 32, 48)
            Viewport.Position = UDim2.new(0, 6, 0, 24)
            Viewport.Size = UDim2.new(1, -12, 1, -30)
            Viewport.LightColor = Color3.fromRGB(255, 255, 255)
            Viewport.LightDirection = Vector3.new(0, -1, 0)
            Viewport.Ambient = Color3.fromRGB(150, 150, 150)
            AddCorner(Viewport, 4)

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

do
    return Library
end
