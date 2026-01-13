local DropdownMenu = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse = cloneref(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = cloneref(game:GetService("Workspace")).CurrentCamera

local CurrentCamera = workspace.CurrentCamera

local CreateInput = require("./Input").New

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

function DropdownMenu.New(Config, Dropdown, Element, CanCallback, Type)
    local DropdownModule = {}
    
    if not Dropdown.Callback then
        Type = "Menu"
    end
    
    Dropdown.UIElements.UIListLayout = New("UIListLayout", {
        Padding = UDim.new(0,Element.MenuPadding/1.5),
        FillDirection = "Vertical",
        HorizontalAlignment = "Center",
    })

    Dropdown.UIElements.Menu = Creator.NewRoundFrame(Element.MenuCorner, "Squircle", {
        ThemeTag = {
            ImageColor3 = "Background",
        },
        ImageTransparency = 1, -- 0.05
        Size = UDim2.new(1,0,1,0),
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1,0,0,0),
    }, {
        New("UIPadding", {
            PaddingTop = UDim.new(0, Element.MenuPadding),
            PaddingLeft = UDim.new(0, Element.MenuPadding),
            PaddingRight = UDim.new(0, Element.MenuPadding),
            PaddingBottom = UDim.new(0, Element.MenuPadding),
        }),
        New("UIListLayout", {
            FillDirection = "Vertical",
            Padding = UDim.new(0,Element.MenuPadding)
        }),
		New("Frame", {
		    BackgroundTransparency = 1,
		    Size = UDim2.new(1,0,1,Dropdown.SearchBarEnabled and -Element.MenuPadding-Element.SearchBarHeight ),
		    --Name = "CanvasGroup",
		    ClipsDescendants = true,
		    LayoutOrder = 999,
		}, {
		    New("UICorner", {
		        CornerRadius = UDim.new(0,Element.MenuCorner - Element.MenuPadding),
		    }),
            New("ScrollingFrame", {
                Size = UDim2.new(1,0,1,0),
                ScrollBarThickness = 0,
                ScrollingDirection = "Y",
                AutomaticCanvasSize = "Y",
                CanvasSize = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                ScrollBarImageTransparency = 1,
            }, {
                Dropdown.UIElements.UIListLayout,
            })
		})
    })

    Dropdown.UIElements.MenuCanvas = New("Frame", {
        Size = UDim2.new(0,Dropdown.MenuWidth,0,300),
        BackgroundTransparency = 1,
        Position = UDim2.new(-10,0,-10,0),
        Visible = false,
        Active = false,
        --GroupTransparency = 1, -- 0
        Parent = Config.WindUI.DropdownGui,
        AnchorPoint = Vector2.new(1,0),
    }, {
        Dropdown.UIElements.Menu,
        New("UISizeConstraint", {
            MinSize = Vector2.new(170,0),
            MaxSize = Vector2.new(300,400),
        })
    })
    
    local function RecalculateCanvasSize()
		Dropdown.UIElements.Menu.Frame.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y)
    end

    local function RecalculateListSize()
        local MaxHeight = CurrentCamera.ViewportSize.Y * 0.6
            
        local ContentY = Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y 
        local SearchBarOffset = Dropdown.SearchBarEnabled and (Element.SearchBarHeight + (Element.MenuPadding*3)) or (Element.MenuPadding*2)
        local TotalY = (ContentY) + SearchBarOffset
            
        if TotalY > MaxHeight then
            Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(
                Dropdown.UIElements.MenuCanvas.AbsoluteSize.X,
                MaxHeight
            )
        else
            Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(
                Dropdown.UIElements.MenuCanvas.AbsoluteSize.X,
                TotalY
            )
        end
    end
    
    function UpdatePosition()
        local button = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
        local menu = Dropdown.UIElements.MenuCanvas
        
        local availableSpaceBelow = Camera.ViewportSize.Y - (button.AbsolutePosition.Y + button.AbsoluteSize.Y) - Element.MenuPadding - 54
        local requiredSpace = menu.AbsoluteSize.Y + Element.MenuPadding
        
        local offset = -54 -- topbar offset
            if availableSpaceBelow < requiredSpace then
            offset = requiredSpace - availableSpaceBelow - 54
        end
        
        menu.Position = UDim2.new(
            0, 
            button.AbsolutePosition.X + button.AbsoluteSize.X,
            0, 
            button.AbsolutePosition.Y + button.AbsoluteSize.Y - offset + (Element.MenuPadding*2) 
        )
    end
    
    local SearchLabel
    
    function DropdownModule:Display()
        local Values = Dropdown.Values
        local Str = ""
    
        if Dropdown.Multi then
            local selected = {}
            if typeof(Dropdown.Value) == "table" then
                for _, item in ipairs(Dropdown.Value) do
                    local title = typeof(item) == "table" and item.Title or item
                    selected[title] = true
                end
            end
    
            for _, value in ipairs(Values) do
                local title = typeof(value) == "table" and value.Title or value
                if selected[title] then
                    Str = Str .. title .. ", "
                end
            end
            
            if #Str > 0 then
                Str = Str:sub(1, #Str - 2)
            end
        else
            Str = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value or ""
        end
    
        if Dropdown.UIElements.Dropdown then
            Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text = (Str == "" and "--" or Str)
        end
    end
    
    function DropdownModule:UpdateSelection()
        -- Update visual selection state of all tabs based on current Dropdown.Value
        if not Dropdown.Tabs then return end
        
        for _, tab in next, Dropdown.Tabs do
            if tab and tab.UIElements and tab.UIElements.TabItem then
                local shouldBeSelected = false
                
                if Dropdown.Multi then
                    if typeof(Dropdown.Value) == "table" then
                        for _, item in ipairs(Dropdown.Value) do
                            local itemName = typeof(item) == "table" and item.Title or item
                            if itemName == tab.Name then
                                shouldBeSelected = true
                                break
                            end
                        end
                    end
                else
                    local currentValue = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value
                    shouldBeSelected = (currentValue == tab.Name)
                end
                
                tab.Selected = shouldBeSelected
                
                -- Update visual state
                if shouldBeSelected and not tab.Locked then
                    Tween(tab.UIElements.TabItem, 0.1, {ImageTransparency = .95}):Play()
                    Tween(tab.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = .75}):Play()
                    Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = 0}):Play()
                    if tab.UIElements.TabIcon then
                        Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = 0}):Play()
                    end
                else
                    Tween(tab.UIElements.TabItem, 0.1, {ImageTransparency = 1}):Play()
                    Tween(tab.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 1}):Play()
                    local isDropdown = (Dropdown.Callback ~= nil)
                    Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = isDropdown and .4 or .05}):Play()
                    if tab.UIElements.TabIcon then
                        Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = isDropdown and .2 or 0}):Play()
                    end
                end
            end
        end
    end
    
    local function Callback(customCallback)
        DropdownModule:Display()
        if Dropdown.Callback then
            task.spawn(function()
                Creator.SafeCallback(Dropdown.Callback, Dropdown.Value)
            end)
        else
            task.spawn(function()
                Creator.SafeCallback(customCallback)
            end)
        end
    end
    
    function DropdownModule:LockValues(lockedItems)
        if not lockedItems then return end
        
        for _, tab in next, Dropdown.Tabs do
            if tab and tab.UIElements and tab.UIElements.TabItem then
                local itemName = tab.Name
                local isLocked = false
                
                for _, lockedItem in next, lockedItems do
                    if itemName == lockedItem then
                        isLocked = true
                        break
                    end
                end
                
                if isLocked then
                    Tween(tab.UIElements.TabItem, 0.1, {ImageTransparency = 1}):Play()
                    Tween(tab.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 1}):Play()
                    Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = 0.6}):Play()
                    if tab.UIElements.TabIcon then
                        Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = 0.6}):Play()
                    end
                    
                    tab.UIElements.TabItem.Active = false
                    tab.Locked = true
                else
                    if tab.Selected then
                        Tween(tab.UIElements.TabItem, 0.1, {ImageTransparency = 0.95}):Play()
                        Tween(tab.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 0.75}):Play()
                        Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = 0}):Play()
                        if tab.UIElements.TabIcon then
                            Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = 0}):Play()
                        end
                    else
                        Tween(tab.UIElements.TabItem, 0.1, {ImageTransparency = 1}):Play()
                        Tween(tab.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 1}):Play()
                        Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = Type == "Dropdown" and 0.4 or 0.05}):Play()
                        if tab.UIElements.TabIcon then
                            Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = Type == "Dropdown" and 0.2 or 0}):Play()
                        end
                    end
                    
                    tab.UIElements.TabItem.Active = true
                    tab.Locked = false
                end
            end
        end
    end
    
    function DropdownModule:Refresh(Values)
        -- Clear existing tabs but preserve UIListLayout
        local preservedUIListLayout = nil
        for _, Elementt in next, Dropdown.UIElements.Menu.Frame.ScrollingFrame:GetChildren() do
            if Elementt:IsA("UIListLayout") then
                preservedUIListLayout = Elementt
            else
                Elementt:Destroy()
            end
        end
        
        -- Ensure UIListLayout reference is correct
        if preservedUIListLayout then
            Dropdown.UIElements.UIListLayout = preservedUIListLayout
        elseif not Dropdown.UIElements.UIListLayout or not Dropdown.UIElements.UIListLayout.Parent then
            Dropdown.UIElements.UIListLayout = New("UIListLayout", {
                Padding = UDim.new(0,Element.MenuPadding/1.5),
                FillDirection = "Vertical",
                HorizontalAlignment = "Center",
                Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame,
            })
        end
        
        Dropdown.Tabs = {}
        
        if Dropdown.SearchBarEnabled then
            if not SearchLabel then
                SearchLabel = CreateInput("Search...", "search", Dropdown.UIElements.Menu, nil, function(val)
                    for _, tab in next, Dropdown.Tabs do
                        if string.find(string.lower(tab.Name), string.lower(val), 1, true) then
                            tab.UIElements.TabItem.Visible = true
                        else
                            tab.UIElements.TabItem.Visible = false
                        end
                        RecalculateListSize()
                        RecalculateCanvasSize()
                    end
                end, true)
                SearchLabel.Size = UDim2.new(1,0,0,Element.SearchBarHeight)
                SearchLabel.Position = UDim2.new(0,0,0,0)
                SearchLabel.Name = "SearchBar"
            end
        end
        
        -- Use ipairs for array iteration to ensure proper order
        local valuesArray = Values
        if typeof(Values) ~= "table" then
            valuesArray = {}
            warn("Dropdown:Refresh() - Values must be a table, got: " .. typeof(Values))
        end
        
        -- Ensure ScrollingFrame exists and is ready
        if not Dropdown.UIElements.Menu or not Dropdown.UIElements.Menu.Frame or not Dropdown.UIElements.Menu.Frame.ScrollingFrame then
            warn("Dropdown:Refresh() - ScrollingFrame not found!")
            return
        end
        
        -- Ensure ScrollingFrame is visible
        Dropdown.UIElements.Menu.Frame.ScrollingFrame.Visible = true
        
        -- Iterate through values - use ipairs for arrays, but handle edge cases
        local tabCount = 0
        for Index, Tab in ipairs(valuesArray) do
            tabCount = tabCount + 1
            -- Check if Tab is a divider (only tables can have Type property)
            local isDivider = typeof(Tab) == "table" and Tab.Type == "Divider"
            
            if isDivider then
                require("../../elements/Divider"):New({ Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame })
            else
                local TabMain = {
                    Name = typeof(Tab) == "table" and Tab.Title or Tab,
                    Desc = typeof(Tab) == "table" and Tab.Desc or nil,
                    Icon = typeof(Tab) == "table" and Tab.Icon or nil,
                    IconSize = typeof(Tab) == "table" and Tab.IconSize or nil,
                    Original = Tab,
                    Selected = false,
                    Locked = typeof(Tab) == "table" and Tab.Locked or false,
                    UIElements = {},
                }
                local TabIcon
                if TabMain.Icon then
                    TabIcon = Creator.Image(
                        TabMain.Icon,
                        TabMain.Icon,
                        0,
                        Config.Window.Folder,
                        "Dropdown",
                        true
                    )
                    TabIcon.Size = UDim2.new(0,TabMain.IconSize or Element.TabIcon,0,TabMain.IconSize or Element.TabIcon)
                    TabIcon.ImageLabel.ImageTransparency = Type == "Dropdown" and .2 or 0
                    TabMain.UIElements.TabIcon = TabIcon
                end
                TabMain.UIElements.TabItem = Creator.NewRoundFrame(Element.MenuCorner - Element.MenuPadding, "Squircle", {
                    Size = UDim2.new(1,0,0,36),
                    AutomaticSize = TabMain.Desc and "Y",
                    ImageTransparency = 1, -- .95
                    Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame,
                    ImageColor3 = Color3.new(1,1,1),
                    Active = not TabMain.Locked,
                    Visible = true,
                }, {
                    Creator.NewRoundFrame(Element.MenuCorner - Element.MenuPadding, "Glass-1.4", {
                        Size = UDim2.new(1,0,1,0),
                        ThemeTag = {
                            ImageColor3 = "DropdownTabBorder",
                        },
                        ImageTransparency = 1, -- .75
                        Name = "Highlight",
                    }, {
                        -- New("UIGradient", {
                        --     Rotation = 80,
                        --     Color = ColorSequence.new({
                        --         ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
                        --         ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        --         ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
                        --     }),
                        --     Transparency = NumberSequence.new({
                        --         NumberSequenceKeypoint.new(0.0, 0.1),
                        --         NumberSequenceKeypoint.new(0.5, 1),
                        --         NumberSequenceKeypoint.new(1.0, 0.1),
                        --     })
                        -- }),
                    }),
                    New("Frame", {
                        Size = UDim2.new(1,0,1,0),
                        BackgroundTransparency = 1,
                    }, {
                        New("UIListLayout", {
                            Padding = UDim.new(0, Element.TabPadding),
                            FillDirection = "Horizontal",
                            VerticalAlignment = "Center",
                        }),
                        New("UIPadding", {
                            PaddingTop = UDim.new(0,Element.TabPadding),
                            PaddingLeft = UDim.new(0,Element.TabPadding),
                            PaddingRight = UDim.new(0,Element.TabPadding),
                            PaddingBottom = UDim.new(0,Element.TabPadding),
                        }),
                        New("UICorner", {
                            CornerRadius = UDim.new(0,Element.MenuCorner - Element.MenuPadding)
                        }),
                        TabIcon,
                        New("Frame", {
                            Size = UDim2.new(1,TabIcon and -Element.TabPadding-Element.TabIcon or 0,0,0),
                            BackgroundTransparency = 1,
                            AutomaticSize = "Y",
                            Name = "Title",
                        }, {
                            New("TextLabel", {
                                Text = TabMain.Name,
                                TextXAlignment = "Left",
                                FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
                                ThemeTag = {
                                    TextColor3 = "Text",
                                    BackgroundColor3 = "Text"
                                },
                                TextSize = 15,
                                BackgroundTransparency = 1,
                                TextTransparency = Type == "Dropdown" and .4 or .05,
                                LayoutOrder = 999,
                                AutomaticSize = "Y",
                                Size = UDim2.new(1,0,0,0),
                            }),
                            New("TextLabel", {
                                Text = TabMain.Desc or "",
                                TextXAlignment = "Left",
                                FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
                                ThemeTag = {
                                    TextColor3 = "Text",
                                    BackgroundColor3 = "Text"
                                },
                                TextSize = 15,
                                BackgroundTransparency = 1,
                                TextTransparency = Type == "Dropdown" and .6 or .35,
                                LayoutOrder = 999,
                                AutomaticSize = "Y",
                                TextWrapped = true,
                                Size = UDim2.new(1,0,0,0),
                                Visible = TabMain.Desc and true or false,
                                Name = "Desc",
                            }),
                            New("UIListLayout", {
                                Padding = UDim.new(0, Element.TabPadding/3),
                                FillDirection = "Vertical",
                            }), 
                        })
                    })
                }, true)
                
                if TabMain.Locked then
                    TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0.6
                    if TabMain.UIElements.TabIcon then
                        TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0.6
                    end
                end

                if Dropdown.Multi and typeof(Dropdown.Value) == "string" then
                    for _, i in next, Dropdown.Values do
                        if typeof(i) == "table" then
                            if i.Title == Dropdown.Value then Dropdown.Value = { i } end
                        else
                            if i == Dropdown.Value then Dropdown.Value = { Dropdown.Value } end
                        end
                    end
                end
                
                if Dropdown.Multi then
                    local found = false
                    if typeof(Dropdown.Value) == "table" then
                        for _, item in ipairs(Dropdown.Value) do
                            local itemName = typeof(item) == "table" and item.Title or item
                            if itemName == TabMain.Name then
                                found = true
                                break
                            end
                        end
                    end
                    TabMain.Selected = found
                else
                    local currentValue = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value
                    TabMain.Selected = currentValue == TabMain.Name
                end
                
                if TabMain.Selected and not TabMain.Locked then
                    TabMain.UIElements.TabItem.ImageTransparency = .95
                    TabMain.UIElements.TabItem.Highlight.ImageTransparency = .75
                    TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0
                    if TabMain.UIElements.TabIcon then
                        TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0
                    end
                end
                
                Dropdown.Tabs[Index] = TabMain
                
                if Type == "Dropdown" then
                    Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
                        if TabMain.Locked then return end 
                        
                        if Dropdown.Multi then
                            if not TabMain.Selected then
                                TabMain.Selected = true
                                Tween(TabMain.UIElements.TabItem, 0.1, {ImageTransparency = .95}):Play()
                                Tween(TabMain.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = .75}):Play()
                                Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = 0}):Play()
                                if TabMain.UIElements.TabIcon then
                                    Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = 0}):Play()
                                end
                                table.insert(Dropdown.Value, TabMain.Original)
                            else
                                if not Dropdown.AllowNone and #Dropdown.Value == 1 then
                                    return
                                end
                                TabMain.Selected = false
                                Tween(TabMain.UIElements.TabItem, 0.1, {ImageTransparency = 1}):Play()
                                Tween(TabMain.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 1}):Play()
                                Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = .4}):Play()
                                if TabMain.UIElements.TabIcon then
                                    Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = .2}):Play()
                                end
                                
                                for i, v in next, Dropdown.Value do
                                    if typeof(v) == "table" and (v.Title == TabMain.Name) or (v == TabMain.Name) then
                                        table.remove(Dropdown.Value, i)
                                        break
                                    end
                                end
                            end
                        else
                            for Index, TabPisun in next, Dropdown.Tabs do
                                Tween(TabPisun.UIElements.TabItem, 0.1, {ImageTransparency = 1}):Play()
                                Tween(TabPisun.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = 1}):Play()
                                Tween(TabPisun.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = .4}):Play()
                                if TabPisun.UIElements.TabIcon then
                                    Tween(TabPisun.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = .2}):Play()
                                end
                                TabPisun.Selected = false
                            end
                            TabMain.Selected = true
                            Tween(TabMain.UIElements.TabItem, 0.1, {ImageTransparency = .95}):Play()
                            Tween(TabMain.UIElements.TabItem.Highlight, 0.1, {ImageTransparency = .75}):Play()
                            Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, {TextTransparency = 0}):Play()
                            if TabMain.UIElements.TabIcon then
                                Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, {ImageTransparency = 0}):Play()
                            end
                            Dropdown.Value = TabMain.Original
                        end
                        Callback()
                    end)
                elseif Type == "Menu" then
                    if not TabMain.Locked then
                        Creator.AddSignal(TabMain.UIElements.TabItem.MouseEnter, function()
                            Tween(TabMain.UIElements.TabItem, 0.08, {ImageTransparency = .95}):Play()
                        end)
                        Creator.AddSignal(TabMain.UIElements.TabItem.InputEnded, function()
                            Tween(TabMain.UIElements.TabItem, 0.08, {ImageTransparency = 1}):Play()
                        end)
                    end
                    Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
                        if TabMain.Locked then return end 
                        Callback(Tab.Callback or function() end)
                    end)
                end
            end
        end
        
        -- Ensure at least some tabs were created
        if tabCount == 0 and typeof(Values) == "table" then
            warn("Dropdown:Refresh() - No tabs created from Values table. Values count: " .. tostring(#Values) .. ", type: " .. typeof(Values))
        end
        
        -- Recalculate sizes after all items are added
        -- Use RunService to wait for UI to update
        local RunService = cloneref(game:GetService("RunService"))
        RunService.Heartbeat:Wait()
        
        RecalculateCanvasSize()
        RecalculateListSize()
            
        local maxWidth = Dropdown.MenuWidth or 0
        if maxWidth == 0 then
            for _, tabmain in next, Dropdown.Tabs do
                if tabmain.UIElements and tabmain.UIElements.TabItem and tabmain.UIElements.TabItem.Frame and tabmain.UIElements.TabItem.Frame.UIListLayout then
                    maxWidth = math.max(maxWidth, tabmain.UIElements.TabItem.Frame.UIListLayout.AbsoluteContentSize.X)
                end
            end
        end
        
        Dropdown.UIElements.MenuCanvas.Size = UDim2.new(0, maxWidth + 6 + 6 + 5 + 5 + 18 + 6 + 6, Dropdown.UIElements.MenuCanvas.Size.Y.Scale, Dropdown.UIElements.MenuCanvas.Size.Y.Offset)
        
        Dropdown.Values = Values
        
        -- Validate current value exists in new values, reset if not
        if not Dropdown.Multi then
            local currentValueStr = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value
            local valueExists = false
            for _, value in ipairs(Values) do
                local valueStr = typeof(value) == "table" and value.Title or value
                if valueStr == currentValueStr then
                    valueExists = true
                    break
                end
            end
            if not valueExists and currentValueStr then
                -- Current value doesn't exist in new values, reset to first value or nil
                Dropdown.Value = nil
            end
        else
            -- For multi dropdown, filter out values that don't exist in new values
            if typeof(Dropdown.Value) == "table" then
                local validValues = {}
                for _, selectedValue in ipairs(Dropdown.Value) do
                    local selectedStr = typeof(selectedValue) == "table" and selectedValue.Title or selectedValue
                    for _, value in ipairs(Values) do
                        local valueStr = typeof(value) == "table" and value.Title or value
                        if valueStr == selectedStr then
                            table.insert(validValues, selectedValue)
                            break
                        end
                    end
                end
                Dropdown.Value = validValues
            end
        end
        
        -- Update selection state and display after refresh
        DropdownModule:UpdateSelection()
        DropdownModule:Display()
        
        -- Recalculate sizes again after display update
        RecalculateCanvasSize()
        RecalculateListSize()
        
        Callback()
    end
      
    DropdownModule:Refresh(Dropdown.Values)
    
    function DropdownModule:Select(Items)
        if Items then
            Dropdown.Value = Items
        else
            if Dropdown.Multi then
                Dropdown.Value = {}
            else
                Dropdown.Value = nil
            end
        end
        DropdownModule:Refresh(Dropdown.Values)
    end

    -- Auto-refresh functionality for dynamic data fetching
    function DropdownModule:AutoRefresh(fetchFunction, ...)
        if typeof(fetchFunction) ~= "function" then
            warn("AutoRefresh: fetchFunction must be a function")
            return
        end

        local args = {...}

        task.spawn(function()
            local success, newValues = pcall(function()
                return fetchFunction(unpack(args))
            end)
            if success and newValues then
                -- Validate that newValues is a table/array
                if typeof(newValues) == "table" then
                    DropdownModule:Refresh(newValues)
                else
                    warn("AutoRefresh: fetchFunction must return a table/array of values")
                end
            else
                warn("AutoRefresh: Failed to fetch new values - " .. tostring(newValues))
            end
        end)
    end

    -- Auto-refresh from ModuleScript
    function DropdownModule:RefreshFromModule(modulePath, functionName, ...)
        if typeof(modulePath) ~= "string" then
            warn("RefreshFromModule: modulePath must be a string")
            return
        end

        local success, module = pcall(require, modulePath)
        if not success then
            warn("RefreshFromModule: Failed to require module - " .. tostring(module))
            return
        end

        if functionName and typeof(module[functionName]) == "function" then
            DropdownModule:AutoRefresh(module[functionName], ...)
        elseif not functionName then
            -- If no function name provided, assume module returns data directly
            if typeof(module) == "table" then
                DropdownModule:Refresh(module)
            else
                warn("RefreshFromModule: Module must return a table when no functionName is provided")
            end
        else
            warn("RefreshFromModule: Function '" .. functionName .. "' not found in module")
        end
    end

    -- Auto-refresh from game objects (e.g., workspace, replicatedstorage)
    function DropdownModule:RefreshFromGame(path, property, filterFunction)
        if typeof(path) ~= "string" then
            warn("RefreshFromGame: path must be a string")
            return
        end

        local success, object = pcall(function()
            local parts = string.split(path, ".")
            local current = game
            for _, part in ipairs(parts) do
                current = current[part]
                if not current then break end
            end
            return current
        end)

        if not success or not object then
            warn("RefreshFromGame: Invalid path - " .. path)
            return
        end

        if property and typeof(object[property]) == "function" then
            -- If property is a function, call it
            DropdownModule:AutoRefresh(object[property])
        elseif property then
            -- If property exists, use its value
            local value = object[property]
            if typeof(value) == "table" then
                DropdownModule:Refresh(value)
            else
                warn("RefreshFromGame: Property '" .. property .. "' must be a table or function")
            end
        else
            -- If no property specified, get children or descendants
            local items = {}
            local getItems = object:GetChildren()

            if filterFunction and typeof(filterFunction) == "function" then
                getItems = {}
                for _, child in ipairs(object:GetChildren()) do
                    if filterFunction(child) then
                        table.insert(getItems, child.Name)
                    end
                end
            else
                for _, child in ipairs(getItems) do
                    table.insert(items, child.Name)
                end
            end

            DropdownModule:Refresh(items)
        end
    end
    
    RecalculateListSize()
    RecalculateCanvasSize()
    
    function DropdownModule:Open()
        if CanCallback then
            Dropdown.UIElements.Menu.Visible = true
            Dropdown.UIElements.MenuCanvas.Visible = true
            Dropdown.UIElements.MenuCanvas.Active = true
            Dropdown.UIElements.Menu.Size = UDim2.new(
                1, 0,
                0, 0
            )
            Tween(Dropdown.UIElements.Menu, 0.1, {
                Size = UDim2.new(
                    1, 0,
                    1, 0
                ),
                ImageTransparency = 0.05
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
            
            task.spawn(function()
                task.wait(.1)
                Dropdown.Opened = true
            end)
            
            UpdatePosition()
        end
    end
    
    function DropdownModule:Close()
        Dropdown.Opened = false
        
        Tween(Dropdown.UIElements.Menu, 0.25, {
            Size = UDim2.new(
                1, 0,
                0, 0
            ),
            ImageTransparency = 1,
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
        
        task.spawn(function()
            task.wait(.1)
            Dropdown.UIElements.Menu.Visible = false
        end)
        
        task.spawn(function()
            task.wait(.25)
            Dropdown.UIElements.MenuCanvas.Visible = false
            Dropdown.UIElements.MenuCanvas.Active = false
        end)
    end
    
    Creator.AddSignal((Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown.MouseButton1Click or Dropdown.DropdownFrame.UIElements.Main.MouseButton1Click), function()
        DropdownModule:Open()
    end)
    
    Creator.AddSignal(UserInputService.InputBegan, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local menuCanvas = Dropdown.UIElements.MenuCanvas
            local AbsPos, AbsSize = menuCanvas.AbsolutePosition, menuCanvas.AbsoluteSize
            
            local DropdownButton = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
            local ButtonAbsPos = DropdownButton.AbsolutePosition
            local ButtonAbsSize = DropdownButton.AbsoluteSize
            
            local isClickOnDropdown = 
                Mouse.X >= ButtonAbsPos.X and 
                Mouse.X <= ButtonAbsPos.X + ButtonAbsSize.X and 
                Mouse.Y >= ButtonAbsPos.Y and 
                Mouse.Y <= ButtonAbsPos.Y + ButtonAbsSize.Y
            
            local isClickOnMenu = 
                Mouse.X >= AbsPos.X and 
                Mouse.X <= AbsPos.X + AbsSize.X and 
                Mouse.Y >= AbsPos.Y and 
                Mouse.Y <= AbsPos.Y + AbsSize.Y
            
            if Config.Window.CanDropdown and Dropdown.Opened and not isClickOnDropdown and not isClickOnMenu then
                DropdownModule:Close()
            end
        end
    end)
    
    Creator.AddSignal(
        Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition") or
        Dropdown.DropdownFrame.UIElements.Main:GetPropertyChangedSignal("AbsolutePosition"), 
        UpdatePosition
    )
    
    return DropdownModule
end

return DropdownMenu
