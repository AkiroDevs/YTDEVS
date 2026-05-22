--[[
    YTDEVS - CINEMATIC CLASSIC (MOBILE BULLETPROOF)
    - Recriado do zero SEM ScrollingFrame para garantir 100% de compatibilidade Mobile
    - Funções Clássicas: Freecam, Cam Lock, Velocidade, FOV, Chroma Key, Ocultar, Clone, Ultra Gráficos
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
-- 1. LIMPEZA E VARIÁVEIS GLOBAIS
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("YtDevsClassic") then CoreGui.YtDevsClassic:Destroy() end
    if CoreGui:FindFirstChild("YtDevsMobileCtrl") then CoreGui.YtDevsMobileCtrl:Destroy() end
end)

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

local colorCorrection = Instance.new("ColorCorrectionEffect")
local depthOfField = Instance.new("DepthOfFieldEffect")
colorCorrection.Enabled = false
depthOfField.Enabled = false
colorCorrection.Parent = Lighting
depthOfField.Parent = Lighting

local targetCFrame = Camera.CFrame

-- ==========================================
-- 2. FUNÇÕES AUXILIARES
-- ==========================================
local function freezeChar(frozen)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then 
        char.HumanoidRootPart.Anchored = frozen 
    end
end

local function toggleUI(enabled)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not enabled)
    end)
end

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
-- 3. INTERFACE PRINCIPAL (FIXA, SEM ROLAGEM)
-- ==========================================
local Screen = Instance.new("ScreenGui", CoreGui)
Screen.Name = "YtDevsClassic"
Screen.ResetOnSpawn = false

local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.new(0, 260, 0, 420)
Main.Position = UDim2.new(0.5, -130, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(100, 100, 100)
makeDraggable(Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "YTDEVS CLASSIC"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, 0, 1, -40)
Container.Position = UDim2.new(0, 0, 0, 40)
Container.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Container)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Pad = Instance.new("UIPadding", Container)
Pad.PaddingTop = UDim.new(0, 5)

local function createAdjuster(name, valPrefix, onMinus, onPlus)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Text = name .. ": " .. valPrefix
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local minus = Instance.new("TextButton", frame)
    minus.Size = UDim2.new(0, 30, 0, 25)
    minus.Position = UDim2.new(1, -70, 0, 5)
    minus.Text = "-"
    minus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    minus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", minus)
    minus.MouseButton1Click:Connect(function() onMinus(lbl) end)

    local plus = Instance.new("TextButton", frame)
    plus.Size = UDim2.new(0, 30, 0, 25)
    plus.Position = UDim2.new(1, -35, 0, 5)
    plus.Text = "+"
    plus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    plus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", plus)
    plus.MouseButton1Click:Connect(function() onPlus(lbl) end)
end

createAdjuster("Speed", state.speed, 
    function(lbl) state.speed = math.max(2, state.speed - 5); lbl.Text = "Speed: " .. state.speed end,
    function(lbl) state.speed = math.min(150, state.speed + 5); lbl.Text = "Speed: " .. state.speed end
)

createAdjuster("FOV", state.fov, 
    function(lbl) state.fov = math.max(20, state.fov - 5); Camera.FieldOfView = state.fov; lbl.Text = "FOV: " .. state.fov end,
    function(lbl) state.fov = math.min(120, state.fov + 5); Camera.FieldOfView = state.fov; lbl.Text = "FOV: " .. state.fov end
)

local function createBtn(text, color)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local BtnFreeCam = createBtn("ATIVAR FREECAM", Color3.fromRGB(50, 50, 55))
local BtnCamLock = createBtn("CAM LOCK (FREEZE)", Color3.fromRGB(50, 50, 55))
local BtnGreen = createBtn("GERAR CHROMA KEY", Color3.fromRGB(0, 120, 0))
local BtnHide = createBtn("OCULTAR JOGADORES", Color3.fromRGB(120, 0, 0))
local BtnClone = createBtn("GERAR CLONE", Color3.fromRGB(80, 0, 120))
local BtnUltra = createBtn("FILTRO ULTRA", Color3.fromRGB(40, 40, 45))

-- ==========================================
-- 4. CONTROLES MOBILE
-- ==========================================
local MobileGui = Instance.new("ScreenGui", CoreGui)
MobileGui.Name = "YtDevsMobileCtrl"
MobileGui.Enabled = false

local JoyBase = Instance.new("Frame", MobileGui)
JoyBase.Size = UDim2.new(0, 100, 0, 100)
JoyBase.Position = UDim2.new(0.05, 0, 0.65, 0)
JoyBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JoyBase.BackgroundTransparency = 0.5
Instance.new("UICorner", JoyBase).CornerRadius = UDim.new(1, 0)

local JoyStick = Instance.new("Frame", JoyBase)
JoyStick.Size = UDim2.new(0, 40, 0, 40)
JoyStick.Position = UDim2.new(0.5, -20, 0.5, -20)
JoyStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", JoyStick).CornerRadius = UDim.new(1, 0)

local function createAltBtn(txt, pos)
    local b = Instance.new("TextButton", MobileGui)
    b.Size = UDim2.new(0, 50, 0, 50)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(0,0,0)
    b.BackgroundTransparency = 0.5
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = txt
    b.TextSize = 20
    Instance.new("UICorner", b)
    return b
end

local BtnUp = createAltBtn("▲", UDim2.new(0.85, 0, 0.55, -60))
local BtnDown = createAltBtn("▼", UDim2.new(0.85, 0, 0.55, 10))

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
        if delta.Magnitude > 40 then delta = delta.Unit * 40 end
        JoyStick.Position = UDim2.new(0.5, -20 + delta.X, 0.5, -20 + delta.Y)
        state.moveVector = Vector3.new(delta.X / 40, 0, delta.Y / 40)
    elseif state.freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= state.dragInput then
        state.yaw = state.yaw - (input.Delta.X * 0.007)
        state.pitch = math.clamp(state.pitch - (input.Delta.Y * 0.007), -math.rad(88), math.rad(88))
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == state.dragInput then
        state.dragInput = nil
        JoyStick.Position = UDim2.new(0.5, -20, 0.5, -20)
        state.moveVector = Vector3.new(0,0,0)
    end
end)

-- ==========================================
-- 5. LÓGICA DOS BOTÕES
-- ==========================================
BtnFreeCam.MouseButton1Click:Connect(function()
    state.freecam = not state.freecam
    MobileGui.Enabled = state.freecam
    freezeChar(state.freecam)
    toggleUI(state.freecam)
    
    if state.freecam then
        state.camLock = false
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        BtnFreeCam.Text = "DESATIVAR FREECAM"
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        state.yaw, state.pitch = y, x
        targetCFrame = Camera.CFrame
    else
        BtnFreeCam.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        BtnFreeCam.Text = "ATIVAR FREECAM"
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnCamLock.MouseButton1Click:Connect(function()
    state.camLock = not state.camLock
    if state.camLock then
        if state.freecam then
            state.freecam = false
            BtnFreeCam.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            BtnFreeCam.Text = "ATIVAR FREECAM"
            MobileGui.Enabled = false
        end
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        state.lockedCFrame = Camera.CFrame
    else
        BtnCamLock.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        state.lockedCFrame = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

BtnGreen.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if state.greenScreen then state.greenScreen:Destroy() end
        state.greenScreen = Instance.new("Part", workspace)
        state.greenScreen.Size = Vector3.new(35, 25, 1)
        state.greenScreen.Color = Color3.fromRGB(0, 255, 0)
        state.greenScreen.Material = Enum.Material.SmoothPlastic
        state.greenScreen.Anchored = true
        state.greenScreen.CanCollide = false
        state.greenScreen.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 3, -10)
    end
end)

BtnHide.MouseButton1Click:Connect(function()
    state.playersHidden = not state.playersHidden
    BtnHide.BackgroundColor3 = state.playersHidden and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(120, 0, 0)
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
            if p:IsA("BasePart") then p.Anchored = true end
            if p:IsA("Script") or p:IsA("LocalScript") then p:Destroy() end
        end
        BtnClone.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        BtnClone.Text = "CLONE GERADO (CLIQUE P/ LIMPAR)"
    else
        if state.clone then state.clone:Destroy(); state.clone = nil end
        BtnClone.BackgroundColor3 = Color3.fromRGB(80, 0, 120)
        BtnClone.Text = "GERAR CLONE"
    end
end)

BtnUltra.MouseButton1Click:Connect(function()
    state.cinematicLight = not state.cinematicLight
    if state.cinematicLight then
        BtnUltra.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        Lighting.Ambient = Color3.fromRGB(120, 120, 130)
        Lighting.Brightness = 2.5
        colorCorrection.Saturation = 0.3
        colorCorrection.Contrast = 0.15
        colorCorrection.Enabled = true
        depthOfField.FarIntensity = 0.8
        depthOfField.FocusDistance = 15
        depthOfField.InFocusRadius = 20
        depthOfField.Enabled = true
    else
        BtnUltra.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        Lighting.Ambient = origLighting.Ambient
        Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        Lighting.Brightness = origLighting.Brightness
        colorCorrection.Enabled = false
        depthOfField.Enabled = false
    end
end)

-- ==========================================
-- 6. LOOP DE CÂMERA (RENDER STEPPED)
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
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, 0.2)
        targetCFrame = nextCFrame
        
    elseif state.camLock then
        Camera.CameraType = Enum.CameraType.Scriptable
        if state.lockedCFrame then Camera.CFrame = state.lockedCFrame end
    end
end)
