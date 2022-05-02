--[[
    Menu Library for Lmaobox
    Author: LNX (github.com/lnx00)
]]

MenuOpen = true

local MenuManager = {
    CurrentID = 1,
    Menus = {},
    Font = draw.CreateFont("Tahoma", 14, 510, FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW),
    FontOther = draw.CreateFont("Tahoma Bold",  14, 700 , FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW),
    Version = 1.36,
    DebugInfo = false
}

MenuFlags = {
    None = 0,
    NoTitle = 1 << 0, -- No title bar
    NoBackground = 1 << 1, -- No window background
    NoDrag = 1 << 2, -- Disable dragging
    AutoSize = 1 << 3 -- Auto size height to contents
}

ItemFlags = {
    None = 0,
    FullWidth = 1 << 0, -- Fill width of menu
}

local lastMouseState = false
local mouseUp = false
local dragID = 0
local dragOffset = {0, 0}

local inputMap = {}
for i = 0, 9 do inputMap[i + 1] = tostring(i) end
for i = 65, 90 do inputMap[i - 54] = string.char(i) end

local function ButtonReleased(button) -- https://github.com/lnx00/Lmaobox-LUA/blob/7f0c6296f6a0aba8a1c04e5b43cf956bf2b994d7/FreeMenu.lua#L55
    if input.IsButtonDown(button) and button ~= LastButton then
        LastButton = button
        AnyButtonDown = true
    end

    if input.IsButtonDown(button) == false and button == LastButton then
        LastButton = 0
        AnyButtonDown = false
        return true
    end

    if AnyButtonDown == false then
        LastButton = 0
    end

    return false
end

local function GetCurrentKey()
    for i, keyText in ipairs(inputMap) do
        if input.IsButtonDown(i) then
            return keyText
        end
    end

    if input.IsButtonDown(KEY_SPACE) then return "SPACE" end
    if input.IsButtonDown(KEY_BACKSPACE) then return "BACKSPACE" end
    if input.IsButtonDown(KEY_COMMA) then return "," end
    if input.IsButtonDown(KEY_PERIOD) then return "." end
    if input.IsButtonDown(KEY_MINUS) then return "-" end
    return nil
end

local function MouseInBounds(pX, pY, pX2, pY2)
    local mX = input.GetMousePos()[1]
    local mY = input.GetMousePos()[2]
    return (mX > pX and mX < pX2 and mY > pY and mY < pY2)
end

local function UpdateMouseState()
    local mouseState = input.IsButtonDown(MOUSE_LEFT)
    mouseUp = (mouseState == false and lastMouseState == true)
    lastMouseState = mouseState
end

local function Clamp(n, low, high) return math.min(math.max(n, low), high) end

--[[ Component Class ]]
local Component = {
    ID = 0,
    Visible = true,
    Flags = ItemFlags.None
}
Component.__index = Component

function Component.New()
    local self = setmetatable({}, Component)
    self.Visible = true
    self.Flags = ItemFlags.None

    return self
end

function Component:SetVisible(state)
    self.Visible = state
end

--[[ Label Component ]]
local Label = {
    Text = "New Label"
}
Label.__index = Label
setmetatable(Label, Component)

function Label.New(label, flags)
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Label)
    self.ID = MenuManager.CurrentID
    self.Text = label
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Label:Render(menu)
    draw.Color(255, 255, 255, 255)
    draw.SetFont(MenuManager.Font)
    draw.Text(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, self.Text)
    local textWidth, textHeight = draw.GetTextSize(self.Text)

    menu.Cursor.Y = menu.Cursor.Y + textHeight + menu.Space
end

--[[ Checkbox Component ]]
local Checkbox = {
    Label = "New Checkbox",
    Value = false
}
Checkbox.__index = Checkbox
setmetatable(Checkbox, Component)

function Checkbox.New(label, value, flags)
    assert(type(value) == "boolean", "Checkbox value must be a boolean")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Checkbox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Checkbox:GetValue()
    return self.Value
end

function Checkbox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local chkSize = math.floor(lblHeight * 1.4)

    -- Interaction
    if mouseUp and MouseInBounds(menu.X + menu.Cursor.X + 335, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize + 335 + menu.Space + lblWidth, menu.Y + menu.Cursor.Y + chkSize) then
        self.Value = not self.Value
    end

    draw.Color(255, 255, 255, 165)

    -- Drawing
    draw.OutlinedRect(menu.X + menu.Cursor.X + 335, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize + 335, menu.Y + menu.Cursor.Y + chkSize)
    draw.SetFont(MenuManager.FontOther)
    draw.Color(255, 255, 255, 255)
    draw.Text(menu.X + menu.Cursor.X + 4 + menu.Space, math.floor(menu.Y + menu.Cursor.Y + (chkSize / 2) - (lblHeight / 2)), self.Label)

    if self.Value == true then
        draw.Color(68, 189, 50, 120)
        draw.FilledRect(menu.X + menu.Cursor.X + 335, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + chkSize + 335, menu.Y + menu.Cursor.Y + chkSize)
    end

    menu.Cursor.Y = menu.Cursor.Y + chkSize + menu.Space
end

--[[ Button Component ]]
local Button = {
    Label = "New Button",
    Callback = nil
}
Button.__index = Button
setmetatable(Button, Component)

function Button.New(label, callback, flags)
    assert(type(callback) == "function", "Button callback must be a function")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Button)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Callback = callback
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Button:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local btnWidth = lblWidth + (menu.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        btnWidth = menu.Width - (menu.Space * 2)
    end

    local btnHeight = lblHeight + (menu.Space * 2)
    
    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self:Callback()
        end
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + btnWidth, menu.Y + menu.Cursor.Y + btnHeight)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (btnWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (btnHeight / 2) - (lblHeight / 2)), self.Label)

    menu.Cursor.Y = menu.Cursor.Y + btnHeight + menu.Space
end

--[[ Slider Component ]]
local Slider = {
    Label = "New Slider",
    Min = 0,
    Max = 100,
    Value = 0
}
Slider.__index = Slider
setmetatable(Slider, Component)

function Slider.New(label, min, max, value, flags)
    assert(max > min, "Slider max must be greater than min")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Slider)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Min = min
    self.Max = max
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Slider:GetValue()
    return self.Value
end

function Slider:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label .. ": " .. self.Value)
    local sliderWidth = menu.Width - (menu.Space * 2)
    local sliderHeight = lblHeight + (menu.Space * 2)
    local dragX = math.floor(((self.Value - self.Min) / math.abs(self.Max - self.Min)) * sliderWidth)

    -- Interaction
    if dragID == 0 and MouseInBounds(menu.X + menu.Cursor.X - 5, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + sliderWidth + 10, menu.Y + menu.Cursor.Y + sliderHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            dragX = Clamp(input.GetMousePos()[1] - (menu.X + menu.Cursor.X), 0, sliderWidth)
            self.Value = (math.floor((dragX / sliderWidth) * math.abs(self.Max - self.Min))) + self.Min
        end
    end

    -- Drawing
    draw.Color(80, 80, 80, 255)
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + sliderWidth, menu.Y + menu.Cursor.Y + sliderHeight)
    draw.Color(150, 150, 150, 150)
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + dragX, menu.Y + menu.Cursor.Y + sliderHeight)

    draw.SetFont(MenuManager.FontOther)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (sliderWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (sliderHeight / 2) - (lblHeight / 2)), self.Label .. ": " .. self.Value)

    menu.Cursor.Y = menu.Cursor.Y + sliderHeight + menu.Space
end

--[[ Textbox Component ]]
local Textbox = {
    Label = "New Textbox",
    Value = "",
    _LastKey = nil
}
Textbox.__index = Textbox
setmetatable(Textbox, Component)

function Textbox.New(label, value, flags)
    flags = flags or ItemFlags.None
    
    local self = setmetatable({}, Textbox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Value = value
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Textbox:GetValue()
    return self.Value
end

function Textbox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Value)
    local boxWidth = menu.Width - (menu.Space * 2)
    local boxHeight = 20

    -- Interaction
    if dragID == 0 and MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + boxWidth, menu.Y + menu.Cursor.Y + boxHeight) then
        local key = GetCurrentKey()
        if not key and self._LastKey then
            if self._LastKey == "SPACE" then
                self.Value = self.Value .. " "
            elseif self._LastKey == "BACKSPACE" then
                self.Value = self.Value:sub(1, -2)
            else
                if input.IsButtonDown(KEY_LSHIFT) then
                    self.Value = self.Value .. string.upper(self._LastKey)
                else
                    self.Value = self.Value .. string.lower(self._LastKey)
                end
            end
            self._LastKey = nil
        end
        self._LastKey = key
    end

    -- Drawing
    draw.Color(60, 60, 60, 255)
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + boxWidth, menu.Y + menu.Cursor.Y + boxHeight)

    draw.SetFont(MenuManager.FontOther)
    if self.Value == "" then
        draw.Color(180, 180, 180, 255)
        draw.Text(menu.X + menu.Cursor.X + menu.Space, math.floor(menu.Y + menu.Cursor.Y + (boxHeight / 2) - (lblHeight / 2)), self.Label)
    else
        draw.Color(255, 255, 255, 255)
        draw.Text(menu.X + menu.Cursor.X + menu.Space, math.floor(menu.Y + menu.Cursor.Y + (boxHeight / 2) - (lblHeight / 2)), self.Value)
    end

    menu.Cursor.Y = menu.Cursor.Y + boxHeight + menu.Space
end

--[[ Combobox Compnent ]]
local Combobox = {
    Label = "New Combobox",
    Options = nil,
    Selected = nil,
    SelectedIndex = 1,
    Open = false,
    _MaxSize = 0
}
Combobox.__index = Combobox
setmetatable(Combobox, Component)

function Combobox.New(label, options, flags)
    assert(type(options) == "table", "Combobox options must be a table")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, Combobox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Options = options
    self.Selected = options[1]
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Combobox:GetSelectedIndex()
    return self.SelectedIndex
end

function Combobox:Select(index)
    self.SelectedIndex = index
    self.Selected = self.Options[index]
end

function Combobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local selWidth, selHeight = draw.GetTextSize(self.Selected)
    local cmbWidth = selWidth + (menu.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        cmbWidth = menu.Width - (menu.Space * 2)
    end

    local lblcmbWidth = lblWidth + (menu.Space * 4)


    local cmbHeight = selHeight + (menu.Space * 2) - 4

    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X + 315, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + 315 + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self.Open = not self.Open
        end
    end

    if self.Open then
        draw.Color(75, 75, 75, 255)
    end

    -- Drawing

    draw.FilledRect(menu.X + menu.Cursor.X + 315, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + 315 + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)

    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (lblcmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (selWidth / 2)) + 315, math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (selHeight / 2)), self.Selected)

    if self.Open then
        menu.Cursor.Y = menu.Cursor.Y + cmbHeight
        for i, vOption in ipairs(self.Options) do
            local olWidth, olHeight = draw.GetTextSize(vOption)
            if self._MaxSize > olWidth then
                olWidth = self._MaxSize
            end
            local optActive = (i == self.SelectedIndex)

            -- Interaction
            if optActive then
                draw.Color(90, 100, 90, 255)
            else
                draw.Color(65, 65, 65, 250)
            end
            if MouseInBounds(menu.X + menu.Cursor.X + 315, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + 315 + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2)) then
                if input.IsButtonDown(MOUSE_LEFT) then
                    draw.Color(70, 70, 70, 255)
                end
                if mouseUp then
                    self.Selected = vOption
                    self.SelectedIndex = i
                    self.Open = false
                end
            end

            -- Drawing
            draw.FilledRect(menu.X + menu.Cursor.X + 315, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + 315 + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2))
            draw.Color(255, 255, 255, 255)
            draw.Text(menu.X + menu.Cursor.X + 315 + menu.Space, menu.Y + menu.Cursor.Y + menu.Space, vOption)
            
            if olWidth > self._MaxSize then
                self._MaxSize = olWidth
            elseif cmbWidth > self._MaxSize then
                self._MaxSize = cmbWidth
            end

            menu.Cursor.Y = menu.Cursor.Y + olHeight + (menu.Space * 2)
        end
    end

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Space
end

--[[ Multi Combobox Component ]]
local MultiCombobox = {
    Label = "New Multibox",
    Options = nil,
    Open = false,
    _MaxSize = 0
}
MultiCombobox.__index = MultiCombobox
setmetatable(MultiCombobox, Component)

function MultiCombobox.New(label, options, flags)
    assert(type(options) == "table", "Combobox options must be a table")
    flags = flags or ItemFlags.None

    local self = setmetatable({}, MultiCombobox)
    self.ID = MenuManager.CurrentID
    self.Label = label
    self.Options = options
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function MultiCombobox:Select(index)
    self.Options[index][2] = true
end

function MultiCombobox:Render(menu)
    local lblWidth, lblHeight = draw.GetTextSize(self.Label)
    local cmbWidth = lblWidth + (menu.Space * 4)
    if self.Flags & ItemFlags.FullWidth ~= 0 then
        cmbWidth = menu.Width - (menu.Space * 2)
    end

    local cmbHeight = lblHeight + (menu.Space * 2)

    -- Interaction
    draw.Color(55, 55, 55, 255)
    if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight) then
        if input.IsButtonDown(MOUSE_LEFT) then
            draw.Color(70, 70, 70, 255)
        end
        if mouseUp then
            self.Open = not self.Open
        end
    end

    if self.Open then
        draw.Color(75, 75, 75, 255)
    end

    -- Drawing
    draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + cmbWidth, menu.Y + menu.Cursor.Y + cmbHeight)
    draw.Color(255, 255, 255, 255)
    draw.Text(math.floor(menu.X + menu.Cursor.X + (cmbWidth / 2) - (lblWidth / 2)), math.floor(menu.Y + menu.Cursor.Y + (cmbHeight / 2) - (lblHeight / 2)), self.Label)

    if self.Open then
        menu.Cursor.Y = menu.Cursor.Y + cmbHeight
        for i, vOption in ipairs(self.Options) do
            local olWidth, olHeight = draw.GetTextSize(vOption[1])
            if self._MaxSize > olWidth then
                olWidth = self._MaxSize
            end

            -- Interaction
            if vOption[2] == true then
                draw.Color(90, 100, 90, 255)
            else
                draw.Color(65, 65, 65, 250)
            end
            if MouseInBounds(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2)) then
                if vOption[2] == true == false and input.IsButtonDown(MOUSE_LEFT) then
                    draw.Color(70, 70, 70, 255)
                end
                if mouseUp then
                    self.Options[i][2] = not self.Options[i][2]
                end
            end

            -- Drawing
            draw.FilledRect(menu.X + menu.Cursor.X, menu.Y + menu.Cursor.Y, menu.X + menu.Cursor.X + olWidth + (menu.Space * 2), menu.Y + menu.Cursor.Y + olHeight + (menu.Space * 2))
            draw.Color(255, 255, 255, 255)
            draw.Text(menu.X + menu.Cursor.X + menu.Space, menu.Y + menu.Cursor.Y + menu.Space, vOption[1])
            
            if olWidth > self._MaxSize then
                self._MaxSize = olWidth
            elseif cmbWidth > self._MaxSize then
                self._MaxSize = cmbWidth
            end

            menu.Cursor.Y = menu.Cursor.Y + olHeight + (menu.Space * 2)
        end
    end

    menu.Cursor.Y = menu.Cursor.Y + cmbHeight + menu.Space
end

--[[ Menu Class ]]
local Menu = {
    ID = 0,
    Title = "Menu",
    Components = nil,
    Visible = true,
    X = 100, Y = 100,
    Width = 400, Height = 400,
    Cursor = { X = 0, Y = 0 },
    Space = 4,
    Flags = 0,
    _AutoH = 0
}

local MetaMenu = {}
MetaMenu.__index = Menu

function Menu.New(title, flags)
    local self = setmetatable({}, MetaMenu)
    self.ID = MenuManager.CurrentID
    self.Title = title
    self.Components = {}
    self.Flags = flags

    MenuManager.CurrentID = MenuManager.CurrentID + 1
    return self
end

function Menu:SetVisible(visible)
    self.Visible = visible
end

function Menu:Toggle()
    self.Visible = not self.Visible
end

function Menu:SetTitle(title)
    self.Title = title
end

function Menu:SetPosition(x, y)
    self.X = x
    self.Y = y
end

function Menu:SetSize(width, height)
    self.Width = width
    self.Height = height
end

function Menu:AddComponent(component)
    table.insert(self.Components, component)
    return component
end

function Menu:RemoveComponent(component)
    for k, vComp in pairs(self.Components) do
        if vComp.ID == component.ID then
            table.remove(self.Components, k)
            return
        end
    end
end

function Menu:Remove()
    MenuManager.RemoveMenu(self)
end

--[[ Menu Manager ]]
function MenuManager.Create(title, flags)
    assert(#MenuManager.Menus < 30, "Are you sure that you want to create more than 30 menus?")
    flags = flags or MenuFlags.None

    local menu = Menu.New(title, flags)
    MenuManager.AddMenu(menu)
    return menu
end

function MenuManager.AddMenu(menu)
    table.insert(MenuManager.Menus, menu)
end

function MenuManager.RemoveMenu(menu)
    for k, vMenu in pairs(MenuManager.Menus) do
        if vMenu.ID == menu.ID then
            vMenu.Components = {}
            table.remove(MenuManager.Menus, k)
            return
        end
    end
end

function MenuManager.Label(text, flags)
    return Label.New(text, flags)
end

function MenuManager.Checkbox(label, value, flags)
    return Checkbox.New(label, value, flags)
end

function MenuManager.Button(label, callback, flags)
    return Button.New(label, callback, flags)
end

function MenuManager.Slider(label, min, max, value, flags)
    value = value or min
    return Slider.New(label, min, max, value, flags)
end

function MenuManager.Textbox(label, value, flags)
    value = value or ""
    return Textbox.New(label, value, flags)
end

function MenuManager.Combo(label, options, flags)
    return Combobox.New(label, options, flags)
end

function MenuManager.MultiCombo(label, options, flags)
    return MultiCombobox.New(label, options, flags)
end

function MenuManager.Seperator(flags)
    return Label.New("", flags)
end

-- Renders the menus and components
function MenuManager.Draw()
    local MenuKey = gui.GetValue("hack menu key")
    if ButtonReleased(KEY_INSERT) or (MenuKey ~= 0 and ButtonReleased(MenuKey)) then
        MenuOpen = not(MenuOpen)
    end

    -- Don't draw if we should ignore screenshots
    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    draw.Color(255, 255, 255, 255)
    draw.SetFont(MenuManager.FontOther)

    if MenuManager.DebugInfo then
        MenuManager.DrawDebug()
    end
    UpdateMouseState()

    for k, vMenu in pairs(MenuManager.Menus) do
        if not vMenu.Visible then
            goto continue
        end

        if not(MenuOpen) then
            return
        end

        local tbHeight = 20

        -- Auto Size
        if vMenu.Flags & MenuFlags.AutoSize ~= 0 then
            vMenu.Height = vMenu._AutoH
        end

        -- Window drag
        if vMenu.Flags & MenuFlags.NoDrag == 0 then
            local mX = input.GetMousePos()[1]
            local mY = input.GetMousePos()[2]
            if dragID == vMenu.ID then
                if input.IsButtonDown(MOUSE_LEFT) then
                    vMenu.X = mX - dragOffset[1]
                    vMenu.Y = mY - dragOffset[2]
                else
                    dragID = 0
                end
            elseif dragID == 0 then
                if input.IsButtonDown(MOUSE_LEFT) and MouseInBounds(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight) then
                    dragOffset = { mX - vMenu.X, mY - vMenu.Y }
                    dragID = vMenu.ID
                end
            end
        end

        -- Background
        if vMenu.Flags & MenuFlags.NoBackground == 0 then
            draw.Color(30, 30, 30, 250)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + vMenu.Height)
        end

        -- Menu Title
        if vMenu.Flags & MenuFlags.NoTitle == 0 then
            draw.Color(56, 103, 214, 255)
            draw.FilledRect(vMenu.X, vMenu.Y, vMenu.X + vMenu.Width, vMenu.Y + tbHeight)
            draw.Color(255, 255, 255, 255)
            local titleWidth, titleHeight = draw.GetTextSize(vMenu.Title)
            draw.Text(math.floor(vMenu.X + (vMenu.Width / 2) - (titleWidth / 2)), vMenu.Y + math.floor((tbHeight / 2) - (titleHeight / 2)), vMenu.Title)
            vMenu.Cursor.Y = vMenu.Cursor.Y + tbHeight
        end

        -- Draw Components
        vMenu.Cursor.Y = vMenu.Cursor.Y + vMenu.Space
        vMenu.Cursor.X = vMenu.Cursor.X + vMenu.Space
        for k, vComponent in pairs(vMenu.Components) do
            if vComponent.Visible == true and vMenu.Cursor.Y < vMenu.Height then
                vComponent:Render(vMenu)
            end
        end

        -- Reset Cursor
        vMenu._AutoH = vMenu.Cursor.Y + vMenu.Space
        vMenu.Cursor = { X = 0, Y = 0 }
        ::continue::
    end
end

-- Prints debug info about menus and components
function MenuManager.DrawDebug()
    draw.Text(50, 50, "## DEBUG INFO ##")

    local currentY = 70
    local currentX = 50
    for k, vMenu in pairs(MenuManager.Menus) do
        draw.Text(currentX, currentY, "Menu: " .. vMenu.Title .. ", Flags: " .. vMenu.Flags)
        currentY = currentY + 20
        currentX = currentX + 20
        for k, vComponent in pairs(vMenu.Components) do
            draw.Text(currentX, currentY, "Component-ID: " .. vComponent.ID .. ", Visible: " .. tostring(vComponent.Visible))
            currentY = currentY + 20
        end
        currentX = currentX - 20
        currentY = currentY + 10
    end
end

-- Register Callbacks
callbacks.Unregister("Draw", "Draw_MenuManager")
callbacks.Register("Draw", "Draw_MenuManager", MenuManager.Draw)

print("Loaded Menu Module by LNX (Modified by callie)" .. MenuManager.Version)

return MenuManager