-- [[
--    YTDEVS - CINEMATIC HUB PRO MAX v2 (EDIÇÃO ABSOLUTA UNIFICADA)
--    - Fix Total Mobile: Renderizado via PlayerGui para evitar bugs e telas pretas
--    - Rotação 360° Total: Olhar livre calibrado sem travas de ângulo esférico
--    - Fusão Completa: Inclusão de Chroma Key, Ocultar Players, Clone de Ator e Filtros Ultra
--    - Modo Cinema Agressivo: Background Loop garantindo ocultação de HUD/Chat
-- ]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==========================================
-- [1] LIMPEZA DE INSTÂNCIAS DE MEMÓRIA
-- ==========================================
pcall(function()
    if PlayerGui:FindFirstChild("YtDevsProMax") then PlayerGui.YtDevsProMax:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("YtDevsProMax") then game:GetService("CoreGui").YtDevsProMax:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("YtDevsMobileCtrl") then game:GetService("CoreGui").YtDevsMobileCtrl:Destroy() end
    if PlayerGui:FindFirstChild("YtDevsMobileCtrl") then PlayerGui.YtDevsMobileCtrl:Destroy() end
end)

-- Estados de Controle Globais
local state = {
    freecam = false,
    camLock = false,
    lockedCFrame = nil,
    speed = 20,
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

-- Efeitos Visuais Pré-Injetados
local colorCorrection = Instance.new("ColorCorrectionEffect")
local depthOfField = Instance.new("DepthOfFieldEffect")
local bloom = Instance.new("BloomEffect")
colorCorrection.Enabled = false; depthOfField.Enabled = false; bloom.Enabled = false
colorCorrection.Parent = Lighting; depthOfField.Parent = Lighting; bloom.Parent = Lighting

local targetCFrame = Camera.CFrame

-- ==========================================
-- [2] MOTOR DE CONSTRUÇÃO ANTI-FALHAS (UI)
-- ==========================================
local function create(className, properties)
    local instance = Instance.new(className)
    for prop, val in pairs(properties) do
        instance[prop] = val
    end
    return instance
end

-- Sistema de arrastar janelas otimizado para Touchscreen
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
-- [3] CRIAÇÃO DA INTERFACE DO USUÁRIO
-- ==========================================
local Screen = create("ScreenGui", {
    Name = "YtDevsProMax",
    ResetOnSpawn = false,
    Parent = PlayerGui
})

-- Frame Principal Dimensionado para Todas as Funções
local Main = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 290, 0, 490),
    Position = UDim2.new(0.5, -145, 0.2, 0),
    BackgroundColor3 = Color3.fromRGB(20, 20, 25),
    ZIndex = 1,
    Parent = Screen
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Main })
create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Width = 1.5, Parent = Main })

local Title = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Text = "YTDEVS CINEMATIC PRO MAX",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
    ZIndex = 2,
    Parent = Main
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Title })
makeDraggable(Main, Title)

-- Botões do Canto Superior
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
    TextColor3 = Color3.fromRGB(255, 70, 70),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = Main
})

-- Ícone Flutuante Compacto para Desminimização
local FloatingBtn = create("TextButton", {
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0.05, 0, 0.25, 0),
    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
    Text = "YT",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    Visible = false,
    ZIndex = 10,
    Parent = Screen
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingBtn })
create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Width = 1.5, Parent = FloatingBtn })
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

-- Container dos Botões
local Container = create("Frame", {
    Size = UDim2.new(1, 0, 1, -45),
    Position = UDim2.new(0, 0, 0, 45),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = Main
})

create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = Container
})

-- Helper de Controladores Numéricos (Velocidade / FOV)
local function createAdjuster(name, initialVal, minVal, maxVal, step, onUpdate)
    local current = initialVal
    local frame = create("Frame", {
        Size = UDim2.new(1, -24, 0, 38),
        BackgroundColor3 = Color3.fromRGB(28, 28, 33),
        ZIndex = 3,
        Parent = Container
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })

    local lbl = create("TextLabel", {
        Size = UDim2.new(0, 140, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Text = name .. ": " .. current,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = frame
    })

    local minus = create("TextButton", {
        Size = UDim2.new(0, 32, 0, 28),
        Position = UDim2.new(1, -74, 0, 5),
        Text = "◀",
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 4,
        Parent = frame
    })
    create("UICorner", { Parent = minus })

    local plus = create("TextButton", {
        Size = UDim2.new(0, 32, 0, 28),
        Position = UDim2.new(1, -38, 0, 5),
        Text = "▶",
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 4,
        Parent = frame
    })
    create("UICorner", { Parent = plus })

    minus.MouseButton1Click:Connect(function()
        current = math.max(minVal, current - step)
        lbl.Text = name .. ": " .. current
        onUpdate(current)
    end)

    plus.MouseButton1Click:Connect(function()
        current = math.min(maxVal, current + step)
        lbl.Text = name .. ": " .. current
        onUpdate(current)
    end)
end

-- Instanciando Ajustadores
createAdjuster("Velocidade Drone", state.speed, 5, 160, 5, function(v) state.speed = v end)
createAdjuster("Lente Lupa (FOV)", state.fov, 10, 120, 5, function(v) state.fov = v if state.freecam then Camera.FieldOfView = v end end)

-- Helper de Geração de Botões Simples
local function createBtn(text, color)
    local btn = create("TextButton", {
        Size = UDim2.new(1, -24, 0, 40),
        Text = text,
        BackgroundColor3 = color,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 3,
        Parent = Container
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    return btn
end

local BtnFreeCam = createBtn("FREE CAM (ATIVAR DRONE)", Color3.fromRGB(45, 45, 50))
local BtnCamLock = createBtn("CAM LOCK (TRAVAR CÂMERA)", Color3.fromRGB(45, 45, 50))
local BtnGreen   = createBtn("SPAWNAR TELA VERDE CHROMA", Color3.fromRGB(0, 135, 60))
local BtnHide    = createBtn("OCULTAR TODOS JOGADORES", Color3.fromRGB(150, 0, 35))
local BtnClone   = createBtn("GERAR CLONE DE ATOR", Color3.fromRGB(110, 30, 150))
local BtnUltra   = createBtn("FILTRO CINEMATIC ULTRA (OFF)", Color3.fromRGB(55, 55, 60))

-- ==========================================
-- [4] INTERFACE ISOLADA MOBILE CONTROLS
-- ==========================================
local MobileGui = create("ScreenGui", {
    Name = "YtDevsMobileCtrl",
    ResetOnSpawn = false,
    Enabled = false,
    Parent = PlayerGui
})

local JoyBase = create("Frame", {
    Size = UDim2.new(0, 110, 0, 110),
    Position = UDim2.new(0.08, 0, 0.62, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.5,
    Parent = MobileGui
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = JoyBase })
create("UIStroke", { Color = Color3.new(1, 1, 1), Width = 1, Parent = JoyBase })

local JoyStick = create("Frame", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(0.5, -22, 0.5, -22),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.3,
    Parent = JoyBase
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = JoyStick })

local function createAltBtn(txt, pos)
    local b = create("TextButton", {
        Size = UDim2.new(0, 58, 0, 58),
        Position = pos,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        TextColor3 = Color3.new(1, 1, 1),
        Text = txt,
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        Parent = MobileGui
    })
    create("UICorner", { Parent = b })
    create("UIStroke", { Color = Color3.new(1, 1, 1), Parent = b })
    return b
end

local BtnUp = createAltBtn("▲", UDim2.new(0.86, 0, 0.5, -70))
local BtnDown = createAltBtn("▼", UDim2.new(0.86, 0, 0.5, 10))

BtnUp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = true end end)
BtnUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = false end end)
BtnDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyDown = true end end)
BtnDown.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyDown = false end end)

JoyBase.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        state.dragInput = input
        state.dragStart = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

-- Processamento de Touchscreen (Analógico Esquerdo + Olhar Esférico 360 Direito)
UIS.InputChanged:Connect(function(input)
    if input == state.dragInput then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - state.dragStart
        if delta.Magnitude > 45 then delta = delta.Unit * 45 end
        JoyStick.Position = UDim2.new(0.5, -22 + delta.X, 0.5, -22 + delta.Y)
        state.moveVector = Vector3.new(delta.X / 45, 0, delta.Y / 45)
    elseif state.freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= state.dragInput then
        -- Permite giro 360 completo em qualquer eixo sem nós gráficos
        state.yaw = state.yaw - (input.Delta.X * 0.0075)
        state.pitch = state.pitch - (input.Delta.Y * 0.0075)
        
        -- Clamping seguro em 89.9 graus para evitar a inversão de tela e quebra da câmera do Roblox
        state.pitch = math.clamp(state.pitch, -math.rad(89.9), math.rad(89.9))
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == state.dragInput then
        state.dragInput = nil
        JoyStick.Position = UDim2.new(0.5, -22, 0.5, -22)
        state.moveVector = Vector3.new(0,0,0)
    end
end)

-- ==========================================
-- [5] LÓGICA DE GERENCIAMENTO CINEMATOGRÁFICO
-- ==========================================
local function setCinematicHUD(disabled)
    local visibility = not disabled
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, visibility)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, visibility)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visibility)
    end)
end

local function setCharacterFrozen(frozen)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then 
        char.HumanoidRootPart.Anchored = frozen 
    end
end

local function applyGlobalVisibility()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    if not part:GetAttribute("OrigTrans") then part:SetAttribute("OrigTrans", part.Transparency) end
                    part.Transparency = state.playersHidden and 1 or part:GetAttribute("OrigTrans")
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if state.playersHidden then task.wait(0.3) applyGlobalVisibility() end
    end)
end)

-- ==========================================
-- [6] ACIONADORES DOS BOTÕES (TRIGGERS)
-- ==========================================
BtnFreeCam.MouseButton1Click:Connect(function()
    state.freecam = not state.freecam
    MobileGui.Enabled = state.freecam
    setCharacterFrozen(state.freecam)
    setCinematicHUD(state.freecam)

    if state.freecam then
        state.camLock = false
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        state.yaw, state.pitch = y, x
        targetCFrame = Camera.CFrame
    else
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnCamLock.MouseButton1Click:Connect(function()
    state.camLock = not state.camLock
    if state.camLock then
        if state.freecam then
            state.freecam = false
            BtnFreeCam.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            MobileGui.Enabled = false
            setCharacterFrozen(false)
        end
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        state.lockedCFrame = Camera.CFrame
    else
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        state.lockedCFrame = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnGreen.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.greenScreen then state.greenScreen:Destroy() end
        state.greenScreen = create("Part", {
            Size = Vector3.new(65, 38, 1),
            Color = Color3.fromRGB(0, 255, 0),
            Material = Enum.Material.SmoothPlastic,
            CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 8, -15),
            Anchored = true,
            CanCollide = false,
            Parent = workspace
        })
    end
end)

BtnHide.MouseButton1Click:Connect(function()
    state.playersHidden = not state.playersHidden
    BtnHide.BackgroundColor3 = state.playersHidden and Color3.fromRGB(230, 0, 40) or Color3.fromRGB(150, 0, 35)
    applyGlobalVisibility()
end)

BtnClone.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.clone then 
            state.clone:Destroy()
            state.clone = nil
            BtnClone.BackgroundColor3 = Color3.fromRGB(110, 30, 150)
            BtnClone.Text = "GERAR CLONE DE ATOR"
        else
            char.Archivable = true
            state.clone = char:Clone()
            char.Archivable = false
            state.clone.Parent = workspace
            state.clone:PivotTo(char.HumanoidRootPart.CFrame)
            for _, part in ipairs(state.clone:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true part.CanCollide = false end
                if part:IsA("Script") or part:IsA("LocalScript") then part:Destroy() end
            end
            BtnClone.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            BtnClone.Text = "LIMPAR CLONE ATIVO"
        end
    end
end)

BtnUltra.MouseButton1Click:Connect(function()
    state.cinematicLight = not state.cinematicLight
    if state.cinematicLight then
        BtnUltra.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        BtnUltra.Text = "FILTRO CINEMATIC ULTRA (ON)"
        Lighting.Ambient = Color3.fromRGB(130, 130, 140)
        Lighting.Brightness = 2.6
        colorCorrection.Saturation = 0.35
        colorCorrection.Contrast = 0.15
        colorCorrection.Enabled = true
        depthOfField.FarIntensity = 0.8
        depthOfField.FocusDistance = 15
        depthOfField.InFocusRadius = 25
        depthOfField.Enabled = true
        bloom.Intensity = 0.6
        bloom.Size = 22
        bloom.Enabled = true
    else
        BtnUltra.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        BtnUltra.Text = "FILTRO CINEMATIC ULTRA (OFF)"
        Lighting.Ambient = origLighting.Ambient
        Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        Lighting.Brightness = origLighting.Brightness
        colorCorrection.Enabled = false
        depthOfField.Enabled = false
        bloom.Enabled = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    setCinematicHUD(false)
    setCharacterFrozen(false)
    if state.greenScreen then state.greenScreen:Destroy() end
    if state.clone then state.clone:Destroy() end
    Screen:Destroy()
    MobileGui:Destroy()
end)

-- Loop Secundário Assíncrono para Trancamento de HUD Cinema
task.spawn(function()
    while true do
        task.wait(0.3)
        if state.freecam then setCinematicHUD(true) end
    end
end)

-- ==========================================
-- [7] LOOP CRÍTICO DE RENDERIZAÇÃO DA CÂMERA
-- ==========================================
RS.RenderStepped:Connect(function(dt)
    if state.freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = state.fov
        
        local lookCF = CFrame.Angles(0, state.yaw, 0) * CFrame.Angles(state.pitch, 0, 0)
        local moveDir = Vector3.new(0, 0, 0)
        
        if state.moveVector.Magnitude > 0 then
            local camRot = Camera.CFrame - Camera.CFrame.Position
            moveDir = camRot:VectorToWorldSpace(Vector3.new(state.moveVector.X, 0, state.moveVector.Z))
        end
        
        local verticalMove = 0
        if state.flyUp then verticalMove = 1 elseif state.flyDown then verticalMove = -1 end
        
        local finalMove = Vector3.new(moveDir.X, moveDir.Y + verticalMove, moveDir.Z)
        if finalMove.Magnitude > 0 then finalMove = finalMove.Unit * state.speed * dt end
        
        local nextCFrame = CFrame.new(targetCFrame.Position + finalMove) * lookCF
        local smoothWeight = 1 - math.exp(-15 * dt)
        
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, math.clamp(smoothWeight, 0, 1))
        targetCFrame = nextCFrame
        
    elseif state.camLock then
        Camera.CameraType = Enum.CameraType.Scriptable
        if state.lockedCFrame then Camera.CFrame = state.lockedCFrame end
    end
end)
