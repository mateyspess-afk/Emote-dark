t sameUDim2(resizeUndo.pos, element.Position) or not sameUDim2(resizeUndo.size, element.Size)) then
                         pushUndo(resizeUndo)
                     end
                     local rPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                     local pXs = element.Position.X.Scale + (element.Position.X.Offset / rPs.X)
                     local pYs = element.Position.Y.Scale + (element.Position.Y.Offset / rPs.Y)
                     Config.HUDPositions[name] = {pXs, 0, pYs, 0}
                     if not Config.HUDSizes then Config.HUDSizes = {} end
                     local sXs = element.Size.X.Scale + (element.Size.X.Offset / rPs.X)
                     local sYs = element.Size.Y.Scale + (element.Size.Y.Offset / rPs.Y)
                     Config.HUDSizes[name] = {sXs, 0, sYs, 0}
                 end
             end
        end))
    end
end

function setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
    element.Visible = true
    local stroke = Instance.new("UIStroke")
    stroke.Name = "HUDEditorStroke"
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 2
    stroke.Parent = element
    table.insert(HUD.Strokes, stroke)

    local isChild = false
    for _, friendly in pairs(HUD.FriendlyNames) do
        if name == friendly then
            isChild = true
            break
        end
    end

    local inputTarget = Instance.new("TextButton")
    inputTarget.Name = "HUDDragHandle_" .. name
    inputTarget.BackgroundTransparency = 1
    inputTarget.Text = ""
    inputTarget.ZIndex = isChild and 10 or 5
    inputTarget.Active = true
    inputTarget.Parent = HUD.SelectionGui

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if element and element.Parent then
            inputTarget.Size = UDim2.fromOffset(element.AbsoluteSize.X, element.AbsoluteSize.Y)
            inputTarget.Position = UDim2.fromOffset(element.AbsolutePosition.X, element.AbsolutePosition.Y)
        end
    end))

    local dragging = false
    local dragStart, startPos
    local dragUndo
    table.insert(HUD.Connections, inputTarget.InputBegan:Connect(function(input)
        if not State.hudEditorActive then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragUndo = captureHUDState(name, element)
            dragStart = input.Position
            startPos = element.Position
            stroke.Color = Color3.fromRGB(255, 255, 255)
            selectHUDElement(name, element)
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if not dragStart then return end
            local delta = input.Position - dragStart
            local ps = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
            local rawPos = UDim2.new(
                startPos.X.Scale + delta.X / ps.X, startPos.X.Offset,
                startPos.Y.Scale + delta.Y / ps.Y, startPos.Y.Offset
            )
            local snapped, gx, gy = calculateSnap(element, rawPos, name, allMovable)
            element.Position = snapped
            local ovP = HUD.Overlay and HUD.Overlay.AbsolutePosition or Vector2.new(0, 0)
            if snapGuideV then snapGuideV.Visible = (gx ~= nil); if gx then snapGuideV.Position = UDim2.fromOffset(gx - ovP.X, 0) end end
            if snapGuideH then snapGuideH.Visible = (gy ~= nil); if gy then snapGuideH.Position = UDim2.fromOffset(0, gy - ovP.Y) end end
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                stroke.Color = Color3.fromRGB(0, 255, 100)
                if snapGuideV then snapGuideV.Visible = false end
                if snapGuideH then snapGuideH.Visible = false end
                if dragUndo and not sameUDim2(dragUndo.pos, element.Position) then
                    pushUndo(dragUndo)
                end
                    local dPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                    local dpXs = element.Position.X.Scale + (element.Position.X.Offset / dPs.X)
                    local dpYs = element.Position.Y.Scale + (element.Position.Y.Offset / dPs.Y)
                    element.Position = UDim2.new(dpXs, 0, dpYs, 0)
                    Config.HUDPositions[name] = {dpXs, 0, dpYs, 0}
                end
        end
    end))
end

applySavedPositions = function()
    local elems = getAllHUDObjects()
    for name, el in pairs(elems) do
        local customPos = Config.HUDPositions and Config.HUDPositions[name]
        if customPos and type(customPos) == "table" and #customPos == 4 then
            el.Position = UDim2.new(customPos[1], customPos[2], customPos[3], customPos[4])
        elseif HUD.DefaultPositions and HUD.DefaultPositions[name] then
             el.Position = HUD.DefaultPositions[name]
        end

        local customSz = Config.HUDSizes and Config.HUDSizes[name]
        if customSz and type(customSz) == "table" and #customSz == 4 then
            el.Size = UDim2.new(customSz[1], customSz[2], customSz[3], customSz[4])
        elseif HUD.DefaultSizes and HUD.DefaultSizes[name] then
             el.Size = HUD.DefaultSizes[name]
        end

        local props = Config.HUDProperties and Config.HUDProperties[name]
        if props then
            for k, v in pairs(props) do
                pcall(function()
                    if k == "Radius" or k == "CornerRadius" then
                        local cR = el:FindFirstChildWhichIsA("UICorner")
                        if cR and type(v) == "table" then
                             cR.CornerRadius = UDim.new(tonumber(v[1]) or 0, tonumber(v[2]) or 0)
                        end
                    elseif k == "RadiusString" or k == "PlaceholderTransparency" then
                    else
                        el[k] = v
                    end
                end)
            end
        end
    end
end

exitHUDEditor = function()
    if not State.hudEditorActive then return end
    State.hudEditorActive = false
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") and HUD.SettingsDisplayOrderPrev ~= nil then
        pcall(function()
            SettingsLib.UI.DisplayOrder = HUD.SettingsDisplayOrderPrev
        end)
        HUD.SettingsDisplayOrderPrev = nil
    end
    for _, conn in pairs(HUD.Connections) do pcall(function() conn:Disconnect() end) end
    HUD.Connections = {}
    for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
    HUD.ResizeConnections = {}
    for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
    HUD.ResizeHandles = {}
    HUD.SelectedElement = nil
    for _, stroke in pairs(HUD.Strokes) do
        pcall(function() if stroke and stroke.Parent then stroke:Destroy() end end)
    end
    HUD.Strokes = {}

    if HUD.SelectionGui then
        pcall(function() HUD.SelectionGui:Destroy() end)
        HUD.SelectionGui = nil
    end
    for _, el in pairs(getMovableElements()) do
        local h = el:FindFirstChild("HUDDragHandle")
        if h then h:Destroy() end
        if el:FindFirstChildOfClass("UIListLayout") then
            for _, child in pairs(el:GetChildren()) do
                if child:IsA("GuiButton") or child:IsA("TextBox") then
                    child.Active = true
                end
            end
        end
    end
    if HUD.Overlay then
        for _, g in pairs(HUD.Overlay:GetChildren()) do
            if g.Name == "SnapGuide" then g:Destroy() end
        end
    end
    if HUD.Overlay and HUD.Overlay.Parent then HUD.Overlay:Destroy() end
    HUD.Overlay = nil
    if HUD.ForceVisibleConn then HUD.ForceVisibleConn:Disconnect(); HUD.ForceVisibleConn = nil end
    if UI.Search then UI.Search.TextEditable = true; UI.Search.Active = true end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = true; UI.SpeedBox.Active = true end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = true; UI._2Routenumber.Active = true end
    pcall(function() game:GetService("GuiService"):SetEmotesMenuOpen(false) end)
    pcall(function() game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false end)
end

enterHUDEditor = function()
    if State.hudEditorActive then return end
    State.hudEditorActive = true
    HUD.UndoStack = {}

    GuiService:SetEmotesMenuOpen(false)
    task.wait(0.15)

    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then State.hudEditorActive = false; return end
    emotesWheel.Visible = true

    HUD.ForceVisibleConn = RunService.Heartbeat:Connect(function()
        if not State.hudEditorActive then return end
        pcall(function()
            local _, ew = checkEmotesMenuExists()
            if ew then ew.Visible = true end
        end)
    end)

    local main = getSettingsMainFrame()
    if main then main.Visible = false end
    syncToggleVisibility()
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") then
        if HUD.SettingsDisplayOrderPrev == nil then
            HUD.SettingsDisplayOrderPrev = SettingsLib.UI.DisplayOrder
        end
        pcall(function() SettingsLib.UI.DisplayOrder = 99998 end)
    end
    ApplyUIVisibility()

    local selectionGui = game:GetService("CoreGui"):FindFirstChild("7yd7_HUDSelection")
    if not selectionGui then
        selectionGui = Instance.new("ScreenGui")
        selectionGui.Name = "7yd7_HUDSelection"
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
        selectionGui.Parent = game:GetService("CoreGui")
    else
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
    end
    HUD.SelectionGui = selectionGui

    local overlay = Instance.new("Frame")
    overlay.Name = "HUDEditorOverlay"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 6000
    overlay.Active = false
    HUD.Overlay = overlay
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not State.hudEditorActive then return end
        if input.KeyCode == Enum.KeyCode.Z then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                undoLastHUD()
            end
        end
    end))
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local p = input.Position
            if HUD.SelectedElement then
                local e = HUD.SelectedElement
                local pos = e.AbsolutePosition
                local sz = e.AbsoluteSize
                if p.X < pos.X - 25 or p.X > pos.X + sz.X + 25 or p.Y < pos.Y - 25 or p.Y > pos.Y + sz.Y + 25 then
                    task.delay(0.1, function()
                        if HUD.SelectedElement == e then
                            HUD.SelectedElement = nil
                            for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
                            HUD.ResizeHandles = {}
                            for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
                            HUD.ResizeConnections = {}
                        end
                    end)
                end
            end
        end
    end))

    local bc = Instance.new("Frame")
    bc.Parent = overlay
    bc.BackgroundTransparency = 1
    bc.AnchorPoint = Vector2.new(1, 0)
    bc.Position = UDim2.new(1, -10, 0, 10)
    bc.Size = UDim2.fromOffset(360, 42)
    bc.ZIndex = 6000

    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 8)
    bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    bl.VerticalAlignment = Enum.VerticalAlignment.Center
    bl.Parent = bc

    local propertiesBtn = Instance.new("ImageButton")
    propertiesBtn.Parent = bc
    propertiesBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesBtn.BackgroundTransparency = 0.4
    propertiesBtn.Size = UDim2.fromOffset(42, 42)
    propertiesBtn.Image = "rbxassetid://111026029750357"
    propertiesBtn.ZIndex = 6001
    local propCorner = Instance.new("UICorner")
    propCorner.CornerRadius = UDim.new(0, 10)
    propCorner.Parent = propertiesBtn

    local exportBtn = Instance.new("ImageButton")
    exportBtn.Parent = bc
    exportBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    exportBtn.BackgroundTransparency = 0.4
    exportBtn.Size = UDim2.fromOffset(42, 42)
    exportBtn.Image = "rbxassetid://107588515524752"
    exportBtn.ZIndex = 6001
    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 10)
    exportCorner.Parent = exportBtn

    local importBtn = Instance.new("ImageButton")
    importBtn.Parent = bc
    importBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    importBtn.BackgroundTransparency = 0.4
    importBtn.Size = UDim2.fromOffset(42, 42)
    importBtn.Image = "rbxassetid://78317476576895"
    importBtn.ZIndex = 6001
    local importCorner = Instance.new("UICorner")
    importCorner.CornerRadius = UDim.new(0, 10)
    importCorner.Parent = importBtn

    local resetBtn = Instance.new("ImageButton")
    resetBtn.Parent = bc
    resetBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    resetBtn.BackgroundTransparency = 0.4
    resetBtn.Size = UDim2.fromOffset(42, 42)
    resetBtn.Image = "rbxassetid://123088523596870"
    resetBtn.ZIndex = 6001
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 10)
    resetCorner.Parent = resetBtn

    local lockBtn = Instance.new("ImageButton")
    lockBtn.Parent = bc
    lockBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lockBtn.BackgroundTransparency = 0.4
    lockBtn.Size = UDim2.fromOffset(42, 42)
    lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
    lockBtn.ZIndex = 6001
    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 10)
    lockCorner.Parent = lockBtn

    local addBtn = Instance.new("ImageButton")
    addBtn.Parent = bc
    addBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    addBtn.BackgroundTransparency = 0.4
    addBtn.Size = UDim2.fromOffset(42, 42)
    addBtn.Image = "rbxassetid://108445456753346"
    addBtn.ZIndex = 6001
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 10)
    addCorner.Parent = addBtn

    local backBtn = Instance.new("ImageButton")
    backBtn.Parent = bc
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backBtn.BackgroundTransparency = 0.4
    backBtn.Size = UDim2.fromOffset(42, 42)
    backBtn.Image = "rbxassetid://79024388644722"
    backBtn.ZIndex = 6001
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 10)
    backCorner.Parent = backBtn



    local function rebuildHUDOverlays()
        for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
        HUD.ResizeConnections = {}
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, stroke in pairs(HUD.Strokes) do pcall(function() stroke:Destroy() end) end
        HUD.Strokes = {}
        if selectionGui then selectionGui:ClearAllChildren() end
        HUD.SelectedElement = nil
        
        local allMovable = getMovableElements()
        
        local snapGuideH = Instance.new("Frame")
        snapGuideH.Name = "SnapGuide"
        snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideH.BorderSizePixel = 0
        snapGuideH.Size = UDim2.new(1, 0, 0, 1)
        snapGuideH.ZIndex = 6002
        snapGuideH.Visible = false
        snapGuideH.Parent = selectionGui

        local snapGuideV = Instance.new("Frame")
        snapGuideV.Name = "SnapGuide"
        snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideV.BorderSizePixel = 0
        snapGuideV.Size = UDim2.new(0, 1, 1, 0)
        snapGuideV.ZIndex = 6002
        snapGuideV.Visible = false
        snapGuideV.Parent = selectionGui

        for name, element in pairs(allMovable) do
            setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
        end
        
        updateHUDLayouts()
        
        applySavedPositions()
    end

    local function rebuildCustomFramesFromConfig()
        if UI.CustomFrames then
            for _, frame in pairs(UI.CustomFrames) do
                if frame and frame.Parent then frame:Destroy() end
            end
        end
        UI.CustomFrames = {}

        if not Config.CustomFrames then return end
        local _, emotesWheel = checkEmotesMenuExists()
        if not emotesWheel then return end

        for name, data in pairs(Config.CustomFrames) do
            local cf = Instance.new("Frame")
            cf.Name = name
            cf.Parent = emotesWheel
            cf.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            cf.BackgroundTransparency = 0.4
            cf.ZIndex = data and data.ZIndex or 3
            cf.BorderSizePixel = 0
            cf.Active = true

            local pos = Config.HUDPositions and Config.HUDPositions[name]
            local size = Config.HUDSizes and Config.HUDSizes[name]
            if pos and type(pos) == "table" and #pos == 4 then
                cf.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
            else
                cf.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
            if size and type(size) == "table" and #size == 4 then
                cf.Size = UDim2.new(size[1], size[2], size[3], size[4])
            else
                cf.Size = UDim2.new(0.3, 0, 0.3, 0)
            end

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = cf

            UI.CustomFrames[name] = cf
            HUD.DefaultPositions[name] = cf.Position
            HUD.DefaultSizes[name] = cf.Size
        end
    end

    local function applyHUDSettingsReplace(settings)
        local function normalizeImportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            tbl[eName] = {sx + (ox / ps.X), 0, sy + (oy / ps.Y), 0}
                        end
                    end
                end
            end
            return tbl
        end
        Config.HUDPositions = normalizeImportTable(settings.HUDPositions or {})
        Config.HUDSizes = normalizeImportTable(settings.HUDSizes or {})
        Config.HUDProperties = settings.HUDProperties or {}
        Config.CustomFrames = settings.CustomFrames or {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        rebuildCustomFramesFromConfig()
        applySavedPositions()

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
    end

    table.insert(HUD.Connections, lockBtn.MouseButton1Click:Connect(function()
        HUD.IsUnlocked = not HUD.IsUnlocked
        lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
        rebuildHUDOverlays()
        pcall(function() updateGUIColors() end)
        emotesDarkExecutorEnv().Notify({ 
            Title = "Dark | HUD Editor", 
            Content = HUD.IsUnlocked and "🔓 Interior Unlocked! Children are now editable." or "🔒 Interior Locked! Top-level only.", 
            Duration = 2 
        })
    end))

    rebuildHUDOverlays()

    table.insert(HUD.Connections, exportBtn.MouseButton1Click:Connect(function()
        local function normalizeExportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            sx = sx + (ox / ps.X)
                            sy = sy + (oy / ps.Y)
                        end
                    end
                    out[eName] = {sx, 0, sy, 0}
                else
                    out[eName] = v
                end
            end
            return out
        end
        local function normalizeExportProps(props)
            if type(props) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, p in pairs(props) do
                local ep = {}
                for k, v in pairs(p) do
                    if (k == "CornerRadius" or k == "Radius") and type(v) == "table" and #v == 2 then
                        local rs, ro = v[1], v[2]
                        if ro ~= 0 and rs == 0 then
                            local el = allElems[eName]
                            if el then
                                local minDim = math.min(el.AbsoluteSize.X, el.AbsoluteSize.Y)
                                if minDim > 0 then
                                    rs = ro / minDim
                                    ro = 0
                                end
                            end
                        end
                        ep[k] = {rs, ro}
                    else
                        ep[k] = v
                    end
                end
                out[eName] = ep
            end
            return out
        end
        local data = {
            Type = "HUD",
            Settings = {
                HUDPositions = normalizeExportTable(Config.HUDPositions or {}),
                HUDSizes = normalizeExportTable(Config.HUDSizes or {}),
                HUDProperties = normalizeExportProps(Config.HUDProperties or {}),
                CustomFrames = Config.CustomFrames or {}
            }
        }
        setclipboard(HttpService:JSONEncode(data))
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✅ HUD settings copied", Duration = 2 })
    end))

    table.insert(HUD.Connections, importBtn.MouseButton1Click:Connect(function()
        local popup, content = CreatePopup("Import HUD", UDim2.fromOffset(320, 240))
        local popupRoot = HUD.SelectionGui or SettingsLib.UI
        if popupRoot and popup.Parent ~= popupRoot then
            popup.Parent = popupRoot
        end

        local baseZ = 7000
        popup.ZIndex = baseZ

        local backdrop = Instance.new("TextButton")
        backdrop.Name = "HUDImportBackdrop"
        backdrop.Parent = popup.Parent
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundTransparency = 1
        backdrop.Text = ""
        backdrop.AutoButtonColor = false
        backdrop.ZIndex = baseZ - 1
        backdrop.Active = true

        local scroll = Instance.new("ScrollingFrame")
        scroll.Parent = content
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Position = UDim2.new(0.05, 0, 0, 5)
        scroll.Size = UDim2.new(0.9, 0, 0, 130)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 4
        scroll.Active = true
        scroll.ScrollingEnabled = true
        scroll.ScrollingDirection = Enum.ScrollingDirection.Y
        scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

        local box = CreateInput(scroll, "Paste HUD JSON here...", "", true)
        box.Size = UDim2.new(1, -8, 0, 130)
        box.Position = UDim2.new(0, 0, 0, 0)
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.ClearTextOnFocus = false

        local function updateCanvas()
            local padding = 8
            local h = math.max(130, (box.TextBounds.Y or 0) + padding)
            scroll.CanvasSize = UDim2.new(0, 0, 0, h)
        end
        box:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
        box:GetPropertyChangedSignal("TextBounds"):Connect(updateCanvas)
        updateCanvas()

        local imp = CreateButton(content, "IMPORT HUD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

        imp.MouseButton1Click:Connect(function()
            local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
            if s and type(d) == "table" then
                local settings = d.Settings or d
                if d.Type and d.Type ~= "HUD" then
                    emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "HUD import type mismatch!", Duration = 3 })
                    return
                end
                if type(settings) ~= "table" then
                    emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
                    return
                end
                applyHUDSettingsReplace(settings)
                HUD.UndoStack = {}
                if backdrop then backdrop:Destroy() end
                popup:Destroy()
                emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✅ HUD settings imported", Duration = 2 })
            else
                emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
            end
        end)

        local close = Instance.new("TextButton")
        close.Size = UDim2.fromOffset(24, 24)
        close.Position = UDim2.new(1, -30, 0, 5)
        close.Text = "×"
        close.Font = Enum.Font.GothamBold
        close.TextSize = 20
        close.BackgroundTransparency = 1
        close.TextColor3 = Color3.new(1,1,1)
        close.ZIndex = baseZ + 2
        close.Active = true
        close.AutoButtonColor = false
        close.Parent = popup
        close.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)
        backdrop.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)

        local function bumpPopupZIndex(panel, z)
            if not panel then return end
            panel.ZIndex = z
            for _, d in ipairs(panel:GetDescendants()) do
                if d:IsA("GuiObject") then
                    d.ZIndex = z + 1
                end
            end
        end
        bumpPopupZIndex(popup, baseZ)
        close.ZIndex = baseZ + 2
    end))

    table.insert(HUD.Connections, backBtn.MouseButton1Click:Connect(function()
        exitHUDEditor()
    end))

    table.insert(HUD.Connections, resetBtn.MouseButton1Click:Connect(function()
        Config.HUDPositions = {}
        Config.HUDSizes = {}
        Config.CustomFrames = {}
        Config.HUDProperties = {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        
        local allElements = getAllHUDObjects()
        for name, el in pairs(allElements) do
            if name:match("^CustomFrame_") then
                el:Destroy()
                if UI.CustomFrames then UI.CustomFrames[name] = nil end
            else
                if HUD.DefaultPositions[name] then el.Position = HUD.DefaultPositions[name] end
                if HUD.DefaultSizes[name] then el.Size = HUD.DefaultSizes[name] end
                
                for internal, friendly in pairs(HUD.FriendlyNames) do
                    if name == friendly then
                        if internal:match("^Under%.") then
                            el.Parent = UI.Under
                        elseif internal:match("^Top%.") then
                            el.Parent = UI.Top
                        end
                        break
                    end
                end

                el.ZIndex = (name == "Top" or name == "Under") and 3 or (el:IsA("ImageButton") and 4 or 3)
                if name == "Under" then
                    el.BackgroundTransparency = 1
                else
                    el.BackgroundTransparency = (name == "Top" or name == "Reload" or name == "Changepage" or name == "EmoteWalkButton" or name == "SpeedBox" or name == "SpeedEmote" or name == "Favorite") and 0.4 or 1
                end
                
                if el:IsA("ImageButton") or el:IsA("ImageLabel") then
                    el.ImageTransparency = 0
                end
                
                if el:IsA("TextLabel") or el:IsA("TextBox") then
                    el.TextTransparency = 0.4
                    if HUD.DefaultTexts and HUD.DefaultTexts[name] then
                        el.Text = HUD.DefaultTexts[name]
                    end
                    if el:IsA("TextBox") and HUD.DefaultPlaceholders and HUD.DefaultPlaceholders[name] then
                        el.PlaceholderText = HUD.DefaultPlaceholders[name]
                    end
                end

                local cR = el:FindFirstChildWhichIsA("UICorner")
                if cR then
                    cR.CornerRadius = UDim.new(0, 10)
                end
            end
        end

        pcall(function() updateGUIColors() end)
        
        HUD.SelectedElement = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}
        
        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        State.totalPages = calculateTotalPages()
        if State.currentPage > State.totalPages then
            State.currentPage = State.totalPages
        end
        updatePageDisplay()
        
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "🔄 All designs and frames have been fully reset", Duration = 3 })
    end))

    local propertiesPanel = Instance.new("Frame")
    propertiesPanel.Name = "HUDPropertiesPanel"
    propertiesPanel.Parent = overlay
    propertiesPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesPanel.BackgroundTransparency = 0.4
    propertiesPanel.Size = UDim2.fromOffset(260, 150)
    propertiesPanel.AnchorPoint = Vector2.new(1, 0)
    propertiesPanel.Position = UDim2.new(1, -10, 0, 60)
    propertiesPanel.Visible = false
    propertiesPanel.ZIndex = 6005
    propertiesPanel.ClipsDescendants = true
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = propertiesPanel
    
    local title = Instance.new("TextLabel")
    title.Parent = propertiesPanel
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 26)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.Font = Enum.Font.SourceSansBold
    title.Text = "No Element"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.TextScaled = true
    title.ZIndex = 6006

    local propContent = Instance.new("ScrollingFrame")
    propContent.Parent = propertiesPanel
    propContent.BackgroundTransparency = 1
    propContent.Position = UDim2.new(0, 0, 0, 28)
    propContent.Size = UDim2.new(1, 0, 1, -32)
    propContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    propContent.ScrollBarThickness = 2
    propContent.Active = true
    propContent.ScrollingEnabled = true
    propContent.ZIndex = 6006

    local propLayout = Instance.new("UIListLayout")
    propLayout.Parent = propContent
    propLayout.SortOrder = Enum.SortOrder.LayoutOrder
    propLayout.Padding = UDim.new(0, 6)
    propLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    HUD.LastTouchedElement = nil
    HUD.LastTouchedName = nil

    local function createPropRow(label, lOrder, isLarge)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(0.92, 0, 0, isLarge and 50 or 26)
        row.LayoutOrder = lOrder
        row.ZIndex = 6006
        row.Parent = propContent

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row
        lbl.Size = UDim2.new(0, 70, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = 12
        lbl.ZIndex = 6007

        local tbox = Instance.new("TextBox")
        tbox.Parent = row
        tbox.Size = UDim2.new(1, -75, 1, -4)
        tbox.Position = UDim2.new(0, 75, 0, 2)
        tbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tbox.BackgroundTransparency = 0.3
        tbox.TextColor3 = Color3.fromRGB(255, 255, 255)
        tbox.Font = Enum.Font.Code
        tbox.TextSize = 12
        tbox.TextXAlignment = isLarge and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        tbox.TextYAlignment = isLarge and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        tbox.ClearTextOnFocus = false
        tbox.TextWrapped = isLarge
        tbox.PlaceholderText = ""
        tbox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        tbox.ZIndex = 6007
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 6); tc.Parent = tbox

        return row, tbox
    end

    local _, posBox = createPropRow("Position", 1)
    local _, sizeBox = createPropRow("Size", 2)
    local zRow, zBox = createPropRow("ZIndex", 3)
    local bgRow, bgBox = createPropRow("BgTrans", 4)
    local bgcRow, bgcBox = createPropRow("BgColor", 5)
    local imgRow, imgBox = createPropRow("ImgTrans", 6)
    local imgcRow, imgcBox = createPropRow("ImgColor", 7)
    local radRow, radBox = createPropRow("Radius", 8)
    local txtRow, txtBox = createPropRow("Text", 9, true)
    local phRow, phBox = createPropRow("Placeholder", 10, true)
    local ttrRow, ttrBox = createPropRow("TxtTrans", 11)
    local txtcRow, txtcBox = createPropRow("TxtColor", 12)

    local deleteRow = Instance.new("Frame")
    deleteRow.BackgroundTransparency = 1
    deleteRow.Size = UDim2.new(0.92, 0, 0, 28)
    deleteRow.LayoutOrder = 13
    deleteRow.ZIndex = 6006
    deleteRow.Parent = propContent

    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Parent = deleteRow
    deleteBtn.Size = UDim2.new(1, 0, 1, 0)
    deleteBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    deleteBtn.BackgroundTransparency = 0.1
    deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteBtn.Font = Enum.Font.GothamBold
    deleteBtn.TextSize = 12
    deleteBtn.Text = "Delete Custom Frame"
    deleteBtn.ZIndex = 6007
    local delCorner = Instance.new("UICorner"); delCorner.CornerRadius = UDim.new(0, 6); delCorner.Parent = deleteBtn



    local function parseUDim2(text)
        local s1, o1, s2, o2 = text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}%s*,%s*{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if s1 and o1 and s2 and o2 then
            return tonumber(s1), tonumber(o1), tonumber(s2), tonumber(o2)
        end
        local a, b = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                return 0, va, 0, vb
            end
        end
        return nil
    end

    local function formatUDim2(udim)
        return string.format("{%g, %g},{%g, %g}", udim.X.Scale, udim.X.Offset, udim.Y.Scale, udim.Y.Offset)
    end

    table.insert(HUD.Connections, propertiesBtn.MouseButton1Click:Connect(function()
        propertiesPanel.Visible = not propertiesPanel.Visible
    end))

    local function formatUDim(udim)
        return string.format("{%g, %g}", udim.Scale, udim.Offset)
    end

    local function formatRGB(c)
        return string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end

    local function parseRGB(text)
        local a, b, c = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if not a then return nil end
        local r, g, b2 = tonumber(a), tonumber(b), tonumber(c)
        if not r or not g or not b2 then return nil end
        local maxv = math.max(r, g, b2)
        if maxv <= 1 then
            r, g, b2 = r * 255, g * 255, b2 * 255
        end
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b2 = math.clamp(b2, 0, 255)
        return r, g, b2
    end

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if not propertiesPanel.Visible then return end
        local e = HUD.LastTouchedElement
        local eName = HUD.LastTouchedName
        if e and e.Parent then
            title.Text = string.format("[%s] %s", e.ClassName, eName or "Unknown")
            if not posBox:IsFocused() then posBox.Text = formatUDim2(e.Position) end
            if not sizeBox:IsFocused() then sizeBox.Text = formatUDim2(e.Size) end
            
            zRow.Visible = true
            if not zBox:IsFocused() then zBox.Text = tostring(e.ZIndex) end

            bgRow.Visible = true
            if not bgBox:IsFocused() then bgBox.Text = tostring(math.floor(e.BackgroundTransparency * 100) / 100) end

            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgRow.Visible = true
                if not imgBox:IsFocused() then imgBox.Text = tostring(math.floor(e.ImageTransparency * 100) / 100) end
            else
                imgRow.Visible = false
            end
            
            bgcRow.Visible = true
            if not bgcBox:IsFocused() then bgcBox.Text = formatRGB(e.BackgroundColor3) end
            
            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgcRow.Visible = true
                if not imgcBox:IsFocused() then imgcBox.Text = formatRGB(e.ImageColor3) end
            else
                imgcRow.Visible = false
            end
            
            if e:IsA("TextLabel") or e:IsA("TextBox") then
                ttrRow.Visible = true
                if not ttrBox:IsFocused() then ttrBox.Text = tostring(math.floor(e.TextTransparency * 100) / 100) end
                
                txtRow.Visible = true
                if not txtBox:IsFocused() then txtBox.Text = e.Text end

                txtcRow.Visible = true
                if not txtcBox:IsFocused() then txtcBox.Text = formatRGB(e.TextColor3) end
                
                if e:IsA("TextBox") then
                    phRow.Visible = true
                    if not phBox:IsFocused() then phBox.Text = e.PlaceholderText end
                else
                    phRow.Visible = false
                end
            else
                ttrRow.Visible = false
                txtRow.Visible = false
                phRow.Visible = false
                txtcRow.Visible = false
            end

            deleteRow.Visible = (eName and eName:match("^CustomFrame_")) and true or false


            local cR = e:FindFirstChildWhichIsA("UICorner")
            if cR then
                radRow.Visible = true
                if not radBox:IsFocused() then radBox.Text = formatUDim(cR.CornerRadius) end
            else
                radRow.Visible = false
            end
        else
            title.Text = "No Element Selected"
            zRow.Visible = false
            bgRow.Visible = false
            imgRow.Visible = false
            bgcRow.Visible = false
            imgcRow.Visible = false
            radRow.Visible = false
            ttrRow.Visible = false
            txtRow.Visible = false
            phRow.Visible = false
            txtcRow.Visible = false
            deleteRow.Visible = false
            if not posBox:IsFocused() then posBox.Text = "" end
            if not sizeBox:IsFocused() then sizeBox.Text = "" end
        end
        
        local totalH = propLayout.AbsoluteContentSize.Y + 10
        propContent.CanvasSize = UDim2.new(0, 0, 0, totalH)
        local vpY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
        local maxH = math.floor(vpY * 0.55)
        propertiesPanel.Size = UDim2.fromOffset(260, math.min(maxH, totalH + 40))
    end))

    local function saveHUDProp(eName, propKey, val)
        if not Config.HUDProperties then Config.HUDProperties = {} end
        if not Config.HUDProperties[eName] then Config.HUDProperties[eName] = {} end
        Config.HUDProperties[eName][propKey] = val
        SaveConfig()
    end

    table.insert(HUD.Connections, deleteBtn.MouseButton1Click:Connect(function()
        local eName = HUD.LastTouchedName
        if not eName or not eName:match("^CustomFrame_") then return end
        local frame = UI.CustomFrames and UI.CustomFrames[eName]
        if frame and frame.Parent then frame:Destroy() end
        if UI.CustomFrames then UI.CustomFrames[eName] = nil end
        if Config.CustomFrames then Config.CustomFrames[eName] = nil end
        if Config.HUDPositions then Config.HUDPositions[eName] = nil end
        if Config.HUDSizes then Config.HUDSizes[eName] = nil end
        if Config.HUDProperties then Config.HUDProperties[eName] = nil end
        if HUD.DefaultPositions then HUD.DefaultPositions[eName] = nil end
        if HUD.DefaultSizes then HUD.DefaultSizes[eName] = nil end
        if HUD.DefaultTexts then HUD.DefaultTexts[eName] = nil end
        if HUD.DefaultPlaceholders then HUD.DefaultPlaceholders[eName] = nil end
        SaveConfig()

        HUD.SelectedElement = nil
        HUD.LastTouchedElement = nil
        HUD.LastTouchedName = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "🗑️ Custom Frame deleted", Duration = 2 })
    end))



    table.insert(HUD.Connections, posBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(posBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Position = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.pos, e.Position) then
                pushUndo(prev)
            end
            Config.HUDPositions[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, sizeBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(sizeBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Size = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.size, e.Size) then
                pushUndo(prev)
            end
            if not Config.HUDSizes then Config.HUDSizes = {} end
            Config.HUDSizes[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, zBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(zBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.ZIndex = v
            if prev and prev.z ~= e.ZIndex then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ZIndex", v)
        end
    end))

    table.insert(HUD.Connections, bgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(bgBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.BackgroundTransparency = math.clamp(v, 0, 1)
            if prev and prev.bgTrans ~= e.BackgroundTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgTrans", e.BackgroundTransparency)
        end
    end))

    table.insert(HUD.Connections, imgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(imgBox.Text)
        if v and (e:IsA("ImageLabel") or e:IsA("ImageButton")) then
            local prev = captureHUDState(eName, e)
            e.ImageTransparency = math.clamp(v, 0, 1)
            if prev and prev.imgTrans ~= e.ImageTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgTrans", e.ImageTransparency)
        end
    end))
    
    table.insert(HUD.Connections, bgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local r, g, b = parseRGB(bgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].BgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.BackgroundColor3 = c end)
            if prev and not sameColor(prev.bgColor, e.BackgroundColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgColor", {r, g, b})
        end
    end))
    
    table.insert(HUD.Connections, imgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("ImageLabel") or e:IsA("ImageButton")) then return end
        local r, g, b = parseRGB(imgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].ImgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.ImageColor3 = c end)
            if prev and prev.imgColor and not sameColor(prev.imgColor, e.ImageColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgColor", {r, g, b})
        end
    end))

    table.insert(HUD.Connections, radBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local a, b = radBox.Text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if not a and not b then a, b = radBox.Text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)") end
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                local cR = e:FindFirstChildWhichIsA("UICorner")
                if cR then
                    local prev = captureHUDState(eName, e)
                    if vb ~= 0 and va == 0 then
                        local minDim = math.min(e.AbsoluteSize.X, e.AbsoluteSize.Y)
                        if minDim > 0 then
                            va = vb / minDim
                            vb = 0
                        end
                    end
                    cR.CornerRadius = UDim.new(va, vb)
                    if prev and prev.radius and not sameUDim(prev.radius, cR.CornerRadius) then
                        pushUndo(prev)
                    end
                    saveHUDProp(eName, "CornerRadius", {va, vb})
                end
            end
        end
    end))

    table.insert(HUD.Connections, txtBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextLabel") or e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.Text = txtBox.Text
            if prev and prev.text ~= e.Text then
                pushUndo(prev)
            end
            saveHUDProp(eName, "Text", txtBox.Text)
        end
    end))

    table.insert(HUD.Connections, phBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.PlaceholderText = phBox.Text
            if prev and prev.placeholder ~= e.PlaceholderText then
                pushUndo(prev)
            end
            saveHUDProp(eName, "PlaceholderText", phBox.Text)
        end
    end))

    table.insert(HUD.Connections, ttrBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(ttrBox.Text)
        if v and (e:IsA("TextLabel") or e:IsA("TextBox")) then
            local prev = captureHUDState(eName, e)
            e.TextTransparency = math.clamp(v, 0, 1)
            if prev and prev.textTrans ~= e.TextTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TextTransparency", e.TextTransparency)
        end
    end))

    table.insert(HUD.Connections, txtcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("TextLabel") or e:IsA("TextBox")) then return end
        local r, g, b = parseRGB(txtcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].TxtColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.TextColor3 = c end)
            if prev and prev.textColor and not sameColor(prev.textColor, e.TextColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TxtColor", {r, g, b})
        end
    end))




    if UI.Search then UI.Search.TextEditable = false; UI.Search.Active = false; pcall(function() UI.Search:ReleaseFocus() end) end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = false; UI.SpeedBox.Active = false; pcall(function() UI.SpeedBox:ReleaseFocus() end) end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = false; UI._2Routenumber.Active = false; pcall(function() UI._2Routenumber:ReleaseFocus() end) end

    local allMovable = getMovableElements()
    local snapGuideH = Instance.new("Frame")
    snapGuideH.Name = "SnapGuide"
    snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideH.BorderSizePixel = 0
    snapGuideH.Size = UDim2.new(1, 0, 0, 1)
    snapGuideH.ZIndex = 6002
    snapGuideH.Visible = false
    snapGuideH.Parent = overlay

    local snapGuideV = Instance.new("Frame")
    snapGuideV.Name = "SnapGuide"
    snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideV.BorderSizePixel = 0
    snapGuideV.Size = UDim2.new(0, 1, 1, 0)
    snapGuideV.ZIndex = 6002
    snapGuideV.Visible = false
    snapGuideV.Parent = overlay

    for name, element in pairs(allMovable) do
        setupElementDragging(name, element, getMovableElements(), snapGuideV, snapGuideH)
    end

    table.insert(HUD.Connections, addBtn.MouseButton1Click:Connect(function()
        local nameIndex = 1
        while UI.CustomFrames and UI.CustomFrames["CustomFrame_"..nameIndex] do
            nameIndex = nameIndex + 1
        end
        local newName = "CustomFrame_"..nameIndex
        
        local _, emotesWheel = checkEmotesMenuExists()
        local cf = Instance.new("Frame")
        cf.Name = newName
        cf.Parent = emotesWheel
        cf.BackgroundTransparency = 0.4
        cf.ZIndex = 3
        cf.BorderSizePixel = 0
        cf.Active = true
        cf.Size = UDim2.new(0.3, 0, 0.3, 0)
        cf.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = cf

        if not UI.CustomFrames then UI.CustomFrames = {} end
        UI.CustomFrames[newName] = cf

        HUD.DefaultSizes[newName] = UDim2.new(0.3, 0, 0.3, 0)
        HUD.DefaultPositions[newName] = UDim2.new(0.5, 0, 0.5, 0)

        Config.HUDPositions[newName] = {0.5, 0, 0.5, 0}
        if not Config.HUDSizes then Config.HUDSizes = {} end
        Config.HUDSizes[newName] = {0.3, 0, 0.3, 0}
        if not Config.CustomFrames then Config.CustomFrames = {} end
        Config.CustomFrames[newName] = {ZIndex = 3}

        pcall(function() updateGUIColors() end)

        setupElementDragging(newName, cf, getMovableElements(), snapGuideV, snapGuideH)
        selectHUDElement(newName, cf)
        
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "➕ Custom Frame added!", Duration = 2 })
    end))

    emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✏️ Drag elements to reposition", Duration = 5 })
end

State.RefreshUI = function()
    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    if State.currentMode == "animation" then
        updateAnimations()
    else
        updateEmotes()
    end
end

State.RefreshSettingsUI = function()
    if TogglesUI then
        for key, toggle in pairs(TogglesUI) do
            if Config[key] ~= nil and toggle.SetState then
                toggle.SetState(Config[key])
            end
        end
    end
end

function checkAndRecreateGUI()
    if State.scriptKicked then return end
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        State.isGUICreated = false
        return
    end

    if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") or
        not emotesWheel:FindFirstChild("EmoteWalkButton") or not emotesWheel:FindFirstChild("Favorite") or
        not emotesWheel:FindFirstChild("FavoritesTab") or
        not emotesWheel:FindFirstChild("SpeedEmote") or not emotesWheel:FindFirstChild("SpeedBox") or
        not emotesWheel:FindFirstChild("Changepage") or not emotesWheel:FindFirstChild("Reload") then
        State.isGUICreated = false
        if createGUIElements() then
            updatePageDisplay()
            updateEmotes()
            loadSpeedEmoteConfig()
        end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    onCharacterAdded(char)
    
    task.spawn(function()
        local attempts = 0
        while attempts < 20 do
            if checkEmotesMenuExists() then
                task.wait(0.2)
                if createGUIElements() then
                    updatePageDisplay()
                    updateEmotes()
                    updateGUIColors()
                    loadSpeedEmoteConfig()
                end
                break
            end
            attempts = attempts + 1
            task.wait(0.1)
        end
    end)
end)


local lastHudVisualRefresh = 0
local HUD_VISUAL_REFRESH_INTERVAL = 0.15
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastHudVisualRefresh < HUD_VISUAL_REFRESH_INTERVAL then return end
    lastHudVisualRefresh = now

    if not State.isGUICreated then
        checkAndRecreateGUI()
    else
        updateGUIColors()
        enforceImages()
    end
end)

RunService.Stepped:Connect(function()
    if humanoid and State.currentEmoteTrack and typeof(State.currentEmoteTrack) == "Instance" and State.currentEmoteTrack:IsA("AnimationTrack") and State.currentEmoteTrack.IsPlaying then
        if humanoid.MoveDirection.Magnitude > 0 then
            if State.toolEquipped or (State.speedEmoteEnabled and not State.emotesWalkEnabled) then
                State.currentEmoteTrack:Stop()
                State.currentEmoteTrack = nil
            end
        end
    end
end)

task.spawn(function()
    loadFavoritesAnimations()
    fetchAllEmotes()
    fetchAllAnimations()
    loadSpeedEmoteConfig()
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
task.spawn(function()
    while true do
        local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        local emotesMenu = robloxGui and robloxGui:FindFirstChild("EmotesMenu")
        if emotesMenu then
            emotesDarkAttachAutoTranslationRoot(emotesMenu)
            local children = emotesMenu:FindFirstChild("Children")
            local main = children and children:FindFirstChild("Main")
            local wheel = main and main:FindFirstChild("EmotesWheel")
            if wheel then
                local front = wheel:FindFirstChild("Front")
                local back = wheel:FindFirstChild("Back")
                bindDarkEmoteClickSounds(front and front:FindFirstChild("EmotesButtons"))
                bindDarkEmoteClickSounds(back and back:FindFirstChild("EmotesButtons"))
            end
        end

        if not emotesMenu then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)

        else
            local exists = emotesMenu:FindFirstChild("Children") and emotesMenu.Children:FindFirstChild("Main") and
                               emotesMenu.Children.Main:FindFirstChild("EmotesWheel")

            if exists and not State.scriptKicked then
                local emotesWheel = emotesMenu.Children.Main.EmotesWheel
                if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") then
                    if createGUIElements then
                        createGUIElements()
                        loadSpeedEmoteConfig()
                    end
                    updateGUIColors()
                    updatePageDisplay()
                end
            end
        end

        task.wait(0.3)
    end
end)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    SafeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/OpenEmote.lua", "Open Emote")
    emotesDarkExecutorEnv().Notify({
        Title = 'Dark | Emote Mobile',
        Content = '📱 Added emote open button for ease of use',
        Duration = 10
    })
end

if UserInputService.KeyboardEnabled then
    emotesDarkExecutorEnv().Notify({
        Title = 'Dark | Emote PC',
        Content = '💻 Open menu press button "."',
        Duration = 10
    })
end
