--[[
    YTDEVS - CINEMATIC HUB PRO MAX (REVISÃO ANTIBUG MOBILE)
    - Fix de Renderização: Transferido de CoreGui para PlayerGui (Zero Telas Pretas)
    - Engine Segura: Propriedades carregadas antes do Parentesco para evitar sumiço de UI
    - Correções: Removidas propriedades inválidas e ajustado o Arraste Mobile Estável
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==========================================
-- [1] LIMPEZA TOTAL DE VERSÕES ANTERIORES
-- ==========================================
pcall(function()
    if PlayerGui:FindFirstChild("YtDevsProMax") then PlayerGui.YtDevsProMax:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("YtDevsProMax") then game:GetService("CoreGui").YtDevsProMax:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("YtDevsMobileCtrl") then game:GetService("CoreGui").YtDevsMobileCtrl:Destroy() end
    if PlayerGui:FindFirstChild("YtDevsMobileCtrl") then PlayerGui.YtDevsMobileCtrl:Destroy() end
end)

local state = {
    freecam = false,
    camLock = false,
    lockedCFrame = nil,
    speed = 25,
    fov = 70,
    yaw = 0,
    pitch = 0,
    flyUp = false,
    flyDown = false,
    moveVector = Vector3.new(0,0,0),
    dragInput = nil,
    dragStart = nil,
    greenScreen = nil,
    playersHidden = false,
    clone = nil,
    cinematicLight = false
}

local origLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness
}

-- Instanciação limpa dos filtros gráficos máximos
local colorCorrection = Instance.new("ColorCorrectionEffect")
local depthOfField = Instance.new("DepthOfFieldEffect")
local bloom = Instance.new("BloomEffect")
colorCorrection.Enabled = false
depthOfField.Enabled = false
bloom.Enabled = false
colorCorrection.Parent = Lighting
depthOfField.Parent = Lighting
bloom.Parent = Lighting

local targetCFrame = Camera.CFrame

-- ==========================================
-- [2] HELPER DE CONSTRUÇÃO SEGURA (ANTI-BUG)
-- ==========================================
local function create(className, properties)
    local instance = Instance.new(className)
    for prop, val in pairs(properties) do
        instance[prop] = val
    end
    return instance
end

-- ==========================================
-- [3] SISTEMA DE ARRASTE ROBUSTO PARA CELULAR
-- ==========================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==========================================
-- [4] INTERFACE DO USUÁRIO PRINCIPAL (GUI)
-- ==========================================
local Screen = create("ScreenGui", {
    Name = "YtDevsProMax",
    ResetOnSpawn = false,
    Parent = PlayerGui
})

local Main = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 280, 0, 440),
    Position = UDim2.new(0.5, -140, 0.25, 0),
    BackgroundColor3 = Color3.fromRGB(15, 15, 18),
    ZIndex = 1,
    Parent = Screen
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Main })
local MainStroke = create("UIStroke", { Color = Color3.fromRGB(255, 0, 60), Width = 2, Parent = Main })

local Title = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Text = "YTDEVS CINEMATIC PRO MAX",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    ZIndex = 2,
    Parent = Main
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Title })
makeDraggable(Main, Title)

-- Controles superiores (Minimizar e Fechar)
local MinBtn = create("TextButton", {
    Size = UDim2.new(0, 35, 0, 40),
    Position = UDim2.new(1, -75, 0, 0),
    Text = "—",
    TextColor3 = Color3.fromRGB(220, 220, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = Main
})

local CloseBtn = create("TextButton", {
    Size = UDim2.new(0, 35, 0, 40),
    Position = UDim2.new(1, -40, 0, 0),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 60, 60),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = Main
})
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() pcall(function() PlayerGui.YtDevsMobileCtrl:Destroy() end) end)

local FloatingBtn = create("TextButton", {
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0.05, 0, 0.3, 0),
    BackgroundColor3 = Color3.fromRGB(15, 15, 18),
    Text = "YT",
    TextColor3 = Color3.fromRGB(255, 0, 60),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    Visible = false,
    ZIndex = 10,
    Parent = Screen
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingBtn })
local FloatStroke = create("UIStroke", { Color = Color3.fromRGB(255, 0, 60), Width = 2, Parent = FloatingBtn })
makeDraggable(FloatingBtn)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingBtn.Position = Main.Position
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    FloatingBtn.Visible = false
    Main.Position = FloatingBtn.Position
    Main.Visible = true
end)

-- Container com alinhamento manual pré-renderizado
local Container = create("Frame", {
    Size = UDim2.new(1, 0, 1, -45),
    Position = UDim2.new(0, 0, 0, 45),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = Main
})

local Layout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = Container
})

-- Construtores Dinâmicos com ZIndex Fixo
local function createAdjuster(name, initialVal, onMinus, onPlus)
    local frame = create("Frame", {
        Size = UDim2.new(1, -24, 0, 36),
        BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        ZIndex = 3,
        Parent = Container
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })

    local lbl = create("TextLabel", {
        Size = UDim2.new(0, 140, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Text = name .. ": " .. initialVal,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = frame
    })

    local minus = create("TextButton", {
        Size = UDim2.new(0, 32, 0, 26),
        Position = UDim2.new(1, -74, 0, 5),
        Text = "◀",
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        TextColor3 = Color3.fromRGB(255, 0, 60),
        ZIndex = 4,
        Parent = frame
    })
    create("UICorner", { Parent = minus })
    minus.MouseButton1Click:Connect(function() onMinus(lbl) end)

    local plus = create("TextButton", {
        Size = UDim2.new(0, 32, 0, 26),
        Position = UDim2.new(1, -38, 0, 5),
        Text = "▶",
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        TextColor3 = Color3.fromRGB(255, 0, 60),
        ZIndex = 4,
        Parent = frame
    })
    create("UICorner", { Parent = plus })
    plus.MouseButton1Click:Connect(function() onPlus(lbl) end)
end

createAdjuster("Velocidade Drone", state.speed, 
    function(lbl) state.speed = math.max(2, state.speed - 5); lbl.Text = "Velocidade Drone: " .. state.speed end,
    function(lbl) state.speed = math.min(180, state.speed + 5); lbl.Text = "Velocidade Drone: " .. state.speed end
)

createAdjuster("Lente Lupa (FOV)", state.fov, 
    function(lbl) state.fov = math.max(15, state.fov - 5); Camera.FieldOfView = state.fov; lbl.Text = "Lente Lupa (FOV): " .. state.fov end,
    function(lbl) state.fov = math.min(120, state.fov + 5); Camera.FieldOfView = state.fov; lbl.Text = "Lente Lupa (FOV): " .. state.fov end
)

local function createBtn(text, color)
    local btn = create("TextButton", {
        Size = UDim2.new(1, -24, 0, 38),
        Text = text,
        BackgroundColor3 = color,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11.5,
        ZIndex = 3,
        Parent = Container
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    return btn
end

local BtnFreeCam = createBtn("ATIVAR DRONE FREECAM", Color3.fromRGB(32, 32, 38))
local BtnCamLock = createBtn("CAM LOCK (CONGELAR CÂMERA)", Color3.fromRGB(32, 32, 38))
local BtnGreen = createBtn("SPAWNAR CHROMA KEY (TELA VERDE)", Color3.fromRGB(0, 140, 60))
local BtnHide = createBtn("OCULTAR TODOS JOGADORES", Color3.fromRGB(160, 0, 40))
local BtnClone = createBtn("GERAR CLONE DE ATOR", Color3.fromRGB(100, 20, 160))
local BtnUltra = createBtn("FILTRO CINEMATIC ULTRA (OFF)", Color3.fromRGB(45, 45, 50))

-- ==========================================
-- [5] CONTROLES JOCKSTICK EM CAMADA SEPARADA
-- ==========================================
local MobileGui = create("ScreenGui", {
    Name = "YtDevsMobileCtrl",
    ResetOnSpawn = false,
    Enabled = false,
    Parent = PlayerGui
})

local JoyBase = create("Frame", {
    Size = UDim2.new(0, 110, 0, 110),
    Position = UDim2.new(0.06, 0, 0.60, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.6,
    Parent = MobileGui
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = JoyBase })

local JoyStick = create("Frame", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(0.5, -21, 0.5, -21),
    BackgroundColor3 = Color3.fromRGB(255, 0, 60),
    Parent = JoyBase
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = JoyStick })

local function createAltBtn(txt, pos)
    local b = create("TextButton", {
        Size = UDim2.new(0, 55, 0, 55),
        Position = pos,
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        BackgroundTransparency = 0.2,
        TextColor3 = Color3.new(1, 1, 1),
        Text = txt,
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        Parent = MobileGui
    })
    create("UICorner", { Parent = b })
    create("UIStroke", { Color = Color3.fromRGB(255, 0, 60), Parent = b })
    return b
end

local BtnUp = createAltBtn("▲", UDim2.new(0.85, 0, 0.52, -65))
local BtnDown = createAltBtn("▼", UDim2.new(0.85, 0, 0.52, 10))

BtnUp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = true end end)
BtnUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = false end end)
BtnDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = false ; state.flyDown = true end end)
BtnDown.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyDown = false end end)

JoyBase.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        state.dragInput = input
        state.dragStart = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == state.dragInput then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - state.dragStart
        if delta.Magnitude > 45 then delta = delta.Unit * 45 end
        JoyStick.Position = UDim2.new(0.5, -21 + delta.X, 0.5, -21 + delta.Y)
        state.moveVector = Vector3.new(delta.X / 45, 0, delta.Y / 45)
    elseif state.freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= state.dragInput then
        state.yaw = state.yaw - (input.Delta.X * 0.0075)
        state.pitch = math.clamp(state.pitch - (input.Delta.Y * 0.0075), -math.rad(88), math.rad(88))
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == state.dragInput then
        state.dragInput = nil
        JoyStick.Position = UDim2.new(0.5, -21, 0.5, -21)
        state.moveVector = Vector3.new(0,0,0)
    end
end)

-- ==========================================
-- [6] SISTEMAS DA MESA DE EFEITOS E EVENTOS
-- ==========================================
local function hideCharacterParts(char, shouldHide)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if not part:GetAttribute("OrigTrans") then 
                part:SetAttribute("OrigTrans", part.Transparency) 
            end
            part.Transparency = shouldHide and 1 or part:GetAttribute("OrigTrans")
        end
    end
end

local function applyGlobalVisibility()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            hideCharacterParts(p.Character, state.playersHidden)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if state.playersHidden then task.wait(0.2) hideCharacterParts(char, true) end
    end)
end)

BtnFreeCam.MouseButton1Click:Connect(function()
    state.freecam = not state.freecam
    MobileGui.Enabled = state.freecam
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then 
        char.HumanoidRootPart.Anchored = state.freecam 
    end
    
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not state.freecam) end)
    
    if state.freecam then
        state.camLock = false
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
        BtnFreeCam.Text = "DESATIVAR DRONE FREECAM"
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        state.yaw, state.pitch = y, x
        targetCFrame = Camera.CFrame
    else
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnCamLock.MouseButton1Click:Connect(function()
    state.camLock = not state.camLock
    if state.camLock then
        if state.freecam then
            state.freecam = false
            BtnFreeCam.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
            BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
            MobileGui.Enabled = false
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
        end
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
        state.lockedCFrame = Camera.CFrame
    else
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        state.lockedCFrame = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnGreen.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.greenScreen then state.greenScreen:Destroy() end
        state.greenScreen = create("Part", {
            Size = Vector3.new(50, 32, 1),
            Color = Color3.fromRGB(0, 255, 0),
            Material = Enum.Material.SmoothPlastic,
            CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 6, -13),
            Anchored = true,
            CanCollide = false,
            Parent = workspace
        })
    end
end)

BtnHide.MouseButton1Click:Connect(function()
    state.playersHidden = not state.playersHidden
    BtnHide.BackgroundColor3 = state.playersHidden and Color3.fromRGB(255, 0, 60) or Color3.fromRGB(160, 0, 40)
    applyGlobalVisibility()
end)

BtnClone.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.clone then state.clone:Destroy() end
        char.Archivable = true
        state.clone = char:Clone()
        char.Archivable = false
        state.clone.Parent = workspace
        state.clone:PivotTo(char.HumanoidRootPart.CFrame)
        
        for _, part in ipairs(state.clone:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = true part.CanCollide = false end
            if part:IsA("Script") or part:IsA("LocalScript") then part:Destroy() end
        end
        BtnClone.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
        BtnClone.Text = "CLONE ATIVO (CLIQUE P/ LIMPAR)"
    else
        if state.clone then state.clone:Destroy(); state.clone = nil end
        BtnClone.BackgroundColor3 = Color3.fromRGB(100, 20, 160)
        BtnClone.Text = "GERAR CLONE DE ATOR"
    end
end)

BtnUltra.MouseButton1Click:Connect(function()
    state.cinematicLight = not state.cinematicLight
    if state.cinematicLight then
        BtnUltra.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
        BtnUltra.Text = "FILTRO CINEMATIC ULTRA (ON)"
        Lighting.Ambient = Color3.fromRGB(135, 135, 145)
        Lighting.Brightness = 2.8
        colorCorrection.Saturation = 0.35
        colorCorrection.Contrast = 0.2
        colorCorrection.Enabled = true
        depthOfField.FarIntensity = 0.85
        depthOfField.FocusDistance = 14
        depthOfField.InFocusRadius = 22
        depthOfField.Enabled = true
        bloom.Intensity = 0.65
        bloom.Size = 24
        bloom.Enabled = true
    else
        BtnUltra.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        BtnUltra.Text = "FILTRO CINEMATIC ULTRA (OFF)"
        Lighting.Ambient = origLighting.Ambient
        Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        Lighting.Brightness = origLighting.Brightness
        colorCorrection.Enabled = false
        depthOfField.Enabled = false
        bloom.Enabled = false
    end
end)

-- ==========================================
-- [7] CINEMA GLIDE LERP LOOP (FLUIDEZ MAX)
-- ==========================================
RS.RenderStepped:Connect(function(dt)
    if state.freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = state.fov
        
        local lookCF = CFrame.Angles(0, state.yaw, 0) * CFrame.Angles(state.pitch, 0, 0)
        local moveDir = Vector3.new(0,0,0)
        
        if state.moveVector.Magnitude > 0 then
            local camRot = Camera.CFrame - Camera.CFrame.Position
            moveDir = camRot:VectorToWorldSpace(Vector3.new(state.moveVector.X, 0, state.moveVector.Z))
        end
        
        local vert = 0
        if state.flyUp then vert = 1 elseif state.flyDown then vert = -1 end
        
        local finalMove = Vector3.new(moveDir.X, moveDir.Y + vert, moveDir.Z)
        if finalMove.Magnitude > 0 then finalMove = finalMove.Unit * state.speed * dt end
        
        local nextCFrame = CFrame.new(targetCFrame.Position + finalMove) * lookCF
        local smoothWeight = 1 - math.exp(-14 * dt)
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, math.clamp(smoothWeight, 0, 1))
        targetCFrame = nextCFrame
        
    elseif state.camLock then
        Camera.CameraType = Enum.CameraType.Scriptable
        if state.lockedCFrame then Camera.CFrame = state.lockedCFrame end
    end
end)
