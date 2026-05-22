--[[
    YTDEVS - CINEMATIC HUB PRO MAX (ULTRA PERFORMANCE MOBILE)
    - Visual Moderno sem ScrollingFrame (Zero risco de tela preta)
    - Sistema de Minimizar Ativo (Botão Flutuante Inteligente)
    - Freecam Premium com Sistema Glide/Lerp de Alta Precisão
    - Correção de Bugs: Ocultação persistente e respiros do Joystick
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- [1] LIMPEZA RECURSIVA DE INSTÂNCIAS
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("YtDevsProMax") then CoreGui.YtDevsProMax:Destroy() end
    if CoreGui:FindFirstChild("YtDevsMobileCtrl") then CoreGui.YtDevsMobileCtrl:Destroy() end
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

-- Efeitos visuais no máximo
local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
local bloom = Instance.new("BloomEffect", Lighting)
colorCorrection.Enabled = false
depthOfField.Enabled = false
bloom.Enabled = false

local targetCFrame = Camera.CFrame

-- ==========================================
-- [2] SISTEMA DE ARRASTE E SUPORTE
-- ==========================================
local function makeDraggable(obj)
    local dragging, sPos, dStart
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dStart = input.Position
            sPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dStart
            obj.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================
-- [3] CONSTRUÇÃO DA INTERFACE VISUAL (GUI)
-- ==========================================
local Screen = Instance.new("ScreenGui", CoreGui)
Screen.Name = "YtDevsProMax"
Screen.ResetOnSpawn = false

local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.new(0, 280, 0, 440)
Main.Position = UDim2.new(0.5, -140, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(255, 0, 50)
MainStroke.Width = 2
makeDraggable(Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "YTDEVS CINEMATIC PRO MAX"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Botão Minimizar (—)
local MinBtn = Instance.new("TextButton", Main)
MinBtn.Size = UDim2.new(0, 35, 0, 40)
MinBtn.Position = UDim2.new(1, -75, 0, 0)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextSize = 14
MinBtn.BackgroundTransparency = 1

-- Botão Fechar (X)
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 35, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 14
CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() pcall(function() CoreGui.YtDevsMobileCtrl:Destroy() end) end)

-- Botão Flutuante (Abre o Menu)
local FloatingBtn = Instance.new("TextButton", Screen)
FloatingBtn.Size = UDim2.new(0, 55, 0, 55)
FloatingBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
FloatingBtn.Text = "YT"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 0, 50)
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.TextSize = 18
FloatingBtn.Visible = false
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Color3.fromRGB(255, 0, 50)
FloatStroke.Width = 2
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

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, 0, 1, -45)
Container.Position = UDim2.new(0, 0, 0, 45)
Container.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Container)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 7)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Slider/Ajustadores de Valores
local function createAdjuster(name, initialVal, onMinus, onPlus)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, -24, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 130, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Text = name .. ": " .. initialVal
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local minus = Instance.new("TextButton", frame)
    minus.Size = UDim2.new(0, 32, 0, 26)
    minus.Position = UDim2.new(1, -74, 0, 5)
    minus.Text = "◀"
    minus.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    minus.TextColor3 = Color3.fromRGB(255, 0, 50)
    Instance.new("UICorner", minus)
    minus.MouseButton1Click:Connect(function() onMinus(lbl) end)

    local plus = Instance.new("TextButton", frame)
    plus.Size = UDim2.new(0, 32, 0, 26)
    plus.Position = UDim2.new(1, -38, 0, 5)
    plus.Text = "▶"
    plus.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    plus.TextColor3 = Color3.fromRGB(255, 0, 50)
    Instance.new("UICorner", plus)
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

-- Construtor de Botões de Funções
local function createBtn(text, color)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, -24, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local BtnFreeCam = createBtn("ATIVAR DRONE FREECAM", Color3.fromRGB(35, 35, 40))
local BtnCamLock = createBtn("CAM LOCK (CONGELAR)", Color3.fromRGB(35, 35, 40))
local BtnGreen = createBtn("SPAWNAR CHROMA KEY (TELA VERDE)", Color3.fromRGB(0, 135, 50))
local BtnHide = createBtn("OCULTAR TODOS JOGADORES", Color3.fromRGB(150, 0, 30))
local BtnClone = createBtn("GERAR CLONE DE ATOR", Color3.fromRGB(90, 20, 150))
local BtnUltra = createBtn("FILTRO CINEMATIC ULTRA (OFF)", Color3.fromRGB(45, 45, 50))

-- ==========================================
-- [4] CONTROLES MOBILE SEM DROPS DE INPUT
-- ==========================================
local MobileGui = Instance.new("ScreenGui", CoreGui)
MobileGui.Name = "YtDevsMobileCtrl"
MobileGui.Enabled = false

local JoyBase = Instance.new("Frame", MobileGui)
JoyBase.Size = UDim2.new(0, 110, 0, 110)
JoyBase.Position = UDim2.new(0.06, 0, 0.62, 0)
JoyBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JoyBase.BackgroundTransparency = 0.55
Instance.new("UICorner", JoyBase).CornerRadius = UDim.new(1, 0)

local JoyStick = Instance.new("Frame", JoyBase)
JoyStick.Size = UDim2.new(0, 44, 0, 44)
JoyStick.Position = UDim2.new(0.5, -22, 0.5, -22)
JoyStick.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
Instance.new("UICorner", JoyStick).CornerRadius = UDim.new(1, 0)

local function createAltBtn(txt, pos)
    local b = Instance.new("TextButton", MobileGui)
    b.Size = UDim2.new(0, 55, 0, 55)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    b.BackgroundTransparency = 0.3
    b.TextColor3 = Color3.new(1, 1, 1)
Text = txt
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 22
    Instance.new("UICorner", b)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(255,0,50)
    return b
end

local BtnUp = createAltBtn("▲", UDim2.new(0.85, 0, 0.52, -65))
local BtnDown = createAltBtn("▼", UDim2.new(0.85, 0, 0.52, 10))

BtnUp.InputBegan:Connect(function(i) if i.UserInputTy--[[
    YTDEVS - CINEMATIC HUB PRO MAX (ULTRA PERFORMANCE MOBILE)
    - Visual Moderno sem ScrollingFrame (Zero risco de tela preta)
    - Sistema de Minimizar Ativo (Botão Flutuante Inteligente)
    - Freecam Premium com Sistema Glide/Lerp de Alta Precisão
    - Correção de Bugs: Ocultação persistente e respiros do Joystick
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- [1] LIMPEZA RECURSIVA DE INSTÂNCIAS
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("YtDevsProMax") then CoreGui.YtDevsProMax:Destroy() end
    if CoreGui:FindFirstChild("YtDevsMobileCtrl") then CoreGui.YtDevsMobileCtrl:Destroy() end
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

-- Efeitos visuais no máximo
local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
local bloom = Instance.new("BloomEffect", Lighting)
colorCorrection.Enabled = false
depthOfField.Enabled = false
bloom.Enabled = false

local targetCFrame = Camera.CFrame

-- ==========================================
-- [2] SISTEMA DE ARRASTE E SUPORTE
-- ==========================================
local function makeDraggable(obj)
    local dragging, sPos, dStart
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dStart = input.Position
            sPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dStart
            obj.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================
-- [3] CONSTRUÇÃO DA INTERFACE VISUAL (GUI)
-- ==========================================
local Screen = Instance.new("ScreenGui", CoreGui)
Screen.Name = "YtDevsProMax"
Screen.ResetOnSpawn = false

local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.new(0, 280, 0, 440)
Main.Position = UDim2.new(0.5, -140, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(255, 0, 50)
MainStroke.Width = 2
makeDraggable(Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "YTDEVS CINEMATIC PRO MAX"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Botão Minimizar (—)
local MinBtn = Instance.new("TextButton", Main)
MinBtn.Size = UDim2.new(0, 35, 0, 40)
MinBtn.Position = UDim2.new(1, -75, 0, 0)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextSize = 14
MinBtn.BackgroundTransparency = 1

-- Botão Fechar (X)
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 35, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 14
CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() pcall(function() CoreGui.YtDevsMobileCtrl:Destroy() end) end)

-- Botão Flutuante (Abre o Menu)
local FloatingBtn = Instance.new("TextButton", Screen)
FloatingBtn.Size = UDim2.new(0, 55, 0, 55)
FloatingBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
FloatingBtn.Text = "YT"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 0, 50)
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.TextSize = 18
FloatingBtn.Visible = false
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Color3.fromRGB(255, 0, 50)
FloatStroke.Width = 2
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

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, 0, 1, -45)
Container.Position = UDim2.new(0, 0, 0, 45)
Container.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Container)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 7)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Slider/Ajustadores de Valores
local function createAdjuster(name, initialVal, onMinus, onPlus)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, -24, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 130, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Text = name .. ": " .. initialVal
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local minus = Instance.new("TextButton", frame)
    minus.Size = UDim2.new(0, 32, 0, 26)
    minus.Position = UDim2.new(1, -74, 0, 5)
    minus.Text = "◀"
    minus.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    minus.TextColor3 = Color3.fromRGB(255, 0, 50)
    Instance.new("UICorner", minus)
    minus.MouseButton1Click:Connect(function() onMinus(lbl) end)

    local plus = Instance.new("TextButton", frame)
    plus.Size = UDim2.new(0, 32, 0, 26)
    plus.Position = UDim2.new(1, -38, 0, 5)
    plus.Text = "▶"
    plus.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    plus.TextColor3 = Color3.fromRGB(255, 0, 50)
    Instance.new("UICorner", plus)
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

-- Construtor de Botões de Funções
local function createBtn(text, color)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, -24, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local BtnFreeCam = createBtn("ATIVAR DRONE FREECAM", Color3.fromRGB(35, 35, 40))
local BtnCamLock = createBtn("CAM LOCK (CONGELAR)", Color3.fromRGB(35, 35, 40))
local BtnGreen = createBtn("SPAWNAR CHROMA KEY (TELA VERDE)", Color3.fromRGB(0, 135, 50))
local BtnHide = createBtn("OCULTAR TODOS JOGADORES", Color3.fromRGB(150, 0, 30))
local BtnClone = createBtn("GERAR CLONE DE ATOR", Color3.fromRGB(90, 20, 150))
local BtnUltra = createBtn("FILTRO CINEMATIC ULTRA (OFF)", Color3.fromRGB(45, 45, 50))

-- ==========================================
-- [4] CONTROLES MOBILE SEM DROPS DE INPUT
-- ==========================================
local MobileGui = Instance.new("ScreenGui", CoreGui)
MobileGui.Name = "YtDevsMobileCtrl"
MobileGui.Enabled = false

local JoyBase = Instance.new("Frame", MobileGui)
JoyBase.Size = UDim2.new(0, 110, 0, 110)
JoyBase.Position = UDim2.new(0.06, 0, 0.62, 0)
JoyBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JoyBase.BackgroundTransparency = 0.55
Instance.new("UICorner", JoyBase).CornerRadius = UDim.new(1, 0)

local JoyStick = Instance.new("Frame", JoyBase)
JoyStick.Size = UDim2.new(0, 44, 0, 44)
JoyStick.Position = UDim2.new(0.5, -22, 0.5, -22)
JoyStick.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
Instance.new("UICorner", JoyStick).CornerRadius = UDim.new(1, 0)

local function createAltBtn(txt, pos)
    local b = Instance.new("TextButton", MobileGui)
    b.Size = UDim2.new(0, 55, 0, 55)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    b.BackgroundTransparency = 0.3
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = txt
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 22
    Instance.new("UICorner", b)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(255,0,50)
    return b
end

local BtnUp = createAltBtn("▲", UDim2.new(0.85, 0, 0.52, -65))
local BtnDown = createAltBtn("▼", UDim2.new(0.85, 0, 0.52, 10))

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

UIS.InputChanged:Connect(function(input)
    if input == state.dragInput then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - state.dragStart
        if delta.Magnitude > 45 then delta = delta.Unit * 45 end
        JoyStick.Position = UDim2.new(0.5, -22 + delta.X, 0.5, -22 + delta.Y)
        state.moveVector = Vector3.new(delta.X / 45, 0, delta.Y / 45)
    elseif state.freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= state.dragInput then
        -- Controle de rotação via swipe extremamente responsivo
        state.yaw = state.yaw - (input.Delta.X * 0.0075)
        state.pitch = math.clamp(state.pitch - (input.Delta.Y * 0.0075), -math.rad(88), math.rad(88))
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
-- [5] LÓGICA E SISTEMAS DAS FUNÇÕES (MAX PRECISÃO)
-- ==========================================
local function enforcePlayersVisibility()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    if not part:GetAttribute("OrigTrans") then part:SetAttribute("OrigTrans", part.Transparency) end
                    part.Transparency = state.playersHidden and 1 or part:GetAttribute("OrigTrans")
                end
            end
        end
    end
end

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
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        BtnFreeCam.Text = "DESATIVAR DRONE FREECAM"
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        state.yaw, state.pitch = y, x
        targetCFrame = Camera.CFrame
    else
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnCamLock.MouseButton1Click:Connect(function()
    state.camLock = not state.camLock
    if state.camLock then
        if state.freecam then
            state.freecam = false
            BtnFreeCam.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
            MobileGui.Enabled = false
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
        end
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        state.lockedCFrame = Camera.CFrame
    else
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        state.lockedCFrame = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnGreen.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.greenScreen then state.greenScreen:Destroy() end
        state.greenScreen = Instance.new("Part", workspace)
        state.greenScreen.Size = Vector3.new(45, 30, 1)
        state.greenScreen.Color = Color3.fromRGB(0, 255, 0)
        state.greenScreen.Material = Enum.Material.SmoothPlastic
        state.greenScreen.Anchored = true
        state.greenScreen.CanCollide = false
        state.greenScreen.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 5, -12)
    end
end)

BtnHide.MouseButton1Click:Connect(function()
    state.playersHidden = not state.playersHidden
    BtnHide.BackgroundColor3 = state.playersHidden and Color3.fromRGB(255, 0, 50) or Color3.fromRGB(150, 0, 30)
    enforcePlayersVisibility()
end)

-- Mantém jogadores ocultados mesmo se renascerem
Players.PlayerCharacterBoundaryToFullChargeTime = 0
RS.Heartbeat:Connect(function()
    if state.playersHidden then enforcePlayersVisibility() end
end)

BtnClone.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.clone then state.clone:Destroy() end
        char.Archivable = true
        state.clone = char:Clone()
        char.Archivable = false
        state.clone.Parent = workspace
        state.clone:MoveTo(char.HumanoidRootPart.Position)
        for _, p in pairs(state.clone:GetDescendants()) do
            if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false end
            if p:IsA("Script") or p:IsA("LocalScript") then p:Destroy() end
        end
        BtnClone.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        BtnClone.Text = "CLONE ATIVO (CLIQUE P/ LIMPAR)"
    else
        if state.clone then state.clone:Destroy(); state.clone = nil end
        BtnClone.BackgroundColor3 = Color3.fromRGB(90, 20, 150)
        BtnClone.Text = "GERAR CLONE DE ATOR"
    end
end)

BtnUltra.MouseButton1Click:Connect(function()
    state.cinematicLight = not state.cinematicLight
    if state.cinematicLight then
        BtnUltra.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        BtnUltra.Text = "FILTRO CINEMATIC ULTRA (ON)"
        Lighting.Ambient = Color3.fromRGB(130, 130, 140)
        Lighting.Brightness = 2.8
        colorCorrection.Saturation = 0.35
        colorCorrection.Contrast = 0.2
        colorCorrection.Enabled = true
        depthOfField.FarIntensity = 0.85
        depthOfField.FocusDistance = 14
        depthOfField.InFocusRadius = 22
        depthOfField.Enabled = true
        bloom.Intensity = 0.6
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
-- [6] LOOP DE EXECUÇÃO DA CÂMERA (CINEMA LERP)
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
        
        -- Peso 0.15 garante o Glide macio de estabilizador profissional
        local nextCFrame = CFrame.new(targetCFrame.Position + finalMove) * lookCF
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, 0.15)
        targetCFrame = nextCFrame
        
    elseif state.camLock then
        Camera.CameraType = Enum.CameraType.Scriptable
        if state.lockedCFrame then Camera.CFrame = state.lockedCFrame end
    end
end)￼Enterpe == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = true end end)
BtnUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyUp = false end end)
BtnDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then state.flyDown = true end end)
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
        JoyStick.Position = UDim2.new(0.5, -22 + delta.X, 0.5, -22 + delta.Y)
        state.moveVector = Vector3.new(delta.X / 45, 0, delta.Y / 45)
    elseif state.freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= state.dragInput then
        -- Controle de rotação via swipe extremamente responsivo
        state.yaw = state.yaw - (input.Delta.X * 0.0075)
        state.pitch = math.clamp(state.pitch - (input.Delta.Y * 0.0075), -math.rad(88), math.rad(88))
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
-- [5] LÓGICA E SISTEMAS DAS FUNÇÕES (MAX PRECISÃO)
-- ==========================================
local function enforcePlayersVisibility()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    if not part:GetAttribute("OrigTrans") then part:SetAttribute("OrigTrans", part.Transparency) end
                    part.Transparency = state.playersHidden and 1 or part:GetAttribute("OrigTrans")
                end
            end
        end
    end
end

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
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        BtnFreeCam.Text = "DESATIVAR DRONE FREECAM"
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        state.yaw, state.pitch = y, x
        targetCFrame = Camera.CFrame
    else
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnCamLock.MouseButton1Click:Connect(function()
    state.camLock = not state.camLock
    if state.camLock then
        if state.freecam then
            state.freecam = false
            BtnFreeCam.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            BtnFreeCam.Text = "ATIVAR DRONE FREECAM"
            MobileGui.Enabled = false
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
        end
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
        state.lockedCFrame = Camera.CFrame
    else
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        state.lockedCFrame = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnGreen.MouseButton1Click:Connect(function()
