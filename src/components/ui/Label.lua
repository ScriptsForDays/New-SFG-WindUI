local Label = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween


function Label.New(Text, Icon, Parent, IsPlaceholder, Radius)
    local Radius = Radius or 10
    local IconLabelFrame
    if Icon and Icon ~= "" then
        IconLabelFrame = New("ImageLabel", {
            Image = Creator.Icon(Icon)[1],
            ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
            ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
            Size = UDim2.new(0,24-3,0,24-3),
            BackgroundTransparency = 1,
            ThemeTag = {
                ImageColor3 = "Icon",
            }
        })
    end
    
    local TextLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        TextSize = 17,
        FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
        Size = UDim2.new(1,IconLabelFrame and -29 or 0,1,0),
        TextXAlignment = "Left",
        ThemeTag = {
            TextColor3 = IsPlaceholder and "Placeholder" or "Text",
        },
        Text = Text,
    })
    
    local LabelFrame = New("TextButton", {
        Size = UDim2.new(1,0,0,42),
        Parent = Parent,
        BackgroundTransparency = 1,
        Text = "",
    }, {
        New("Frame", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
        }, {
            Creator.NewRoundFrame(Radius, "Squircle", {
                ThemeTag = {
                    ImageColor3 = "Accent",
                },
                Size = UDim2.new(1,0,1,0),
                ImageTransparency = .97,
            }),
            Creator.NewRoundFrame(Radius, "Glass-1.4", {
                ThemeTag = {
                    ImageColor3 = "Outline",
                },
                Size = UDim2.new(1,0,1,0),
                ImageTransparency = .75,
            }, {
                -- New("UIGradient", {
                --     Rotation = 70,
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
                -- })
            }),
            Creator.NewRoundFrame(Radius, "Squircle", {
                Size = UDim2.new(1,0,1,0),
                Name = "Frame",
                ImageColor3 = Color3.new(1,1,1),
                ImageTransparency = .95
            }, {
                New("UIPadding", {
                    PaddingLeft = UDim.new(0,12),
                    PaddingRight = UDim.new(0,12),
                }),
                New("UIListLayout", {
                    FillDirection = "Horizontal",
                    Padding = UDim.new(0,8),
                    VerticalAlignment = "Center",
                    HorizontalAlignment = "Left",
                }),
                IconLabelFrame,
                TextLabel,
            })
        })
    })
    
    -- Store references for Set method
    LabelFrame._TextLabel = TextLabel
    LabelFrame._IconLabelFrame = IconLabelFrame
    
    -- Add Set method for dynamic updates
    function LabelFrame:Set(options)
        local textLabel = self._TextLabel
        local iconLabelFrame = self._IconLabelFrame
        
        if typeof(options) ~= "table" then
            -- If options is a string, treat it as text
            if typeof(options) == "string" then
                textLabel.Text = options
                return
            end
            warn("Label:Set() expects a table with Text or Icon properties, or a string for text")
            return
        end
        
        if options.Text ~= nil then
            textLabel.Text = options.Text
        end
        
        if options.Icon ~= nil then
            -- Destroy old icon if it exists
            if iconLabelFrame then
                iconLabelFrame:Destroy()
                iconLabelFrame = nil
                self._IconLabelFrame = nil
            end
            
            -- Create new icon if provided
            if options.Icon ~= "" then
                iconLabelFrame = New("ImageLabel", {
                    Image = Creator.Icon(options.Icon)[1],
                    ImageRectSize = Creator.Icon(options.Icon)[2].ImageRectSize,
                    ImageRectOffset = Creator.Icon(options.Icon)[2].ImageRectPosition,
                    Size = UDim2.new(0,24-3,0,24-3),
                    BackgroundTransparency = 1,
                    ThemeTag = {
                        ImageColor3 = "Icon",
                    }
                })
                
                -- Update TextLabel size to account for icon
                textLabel.Size = UDim2.new(1, -29, 1, 0)
                
                -- Insert icon into the frame
                iconLabelFrame.Parent = self.Frame.Frame
                self._IconLabelFrame = iconLabelFrame
            else
                -- No icon, update TextLabel size
                textLabel.Size = UDim2.new(1, 0, 1, 0)
            end
        end
    end
    
    return LabelFrame
end


return Label