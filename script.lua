here--[[
    YTDEVS - FREE CAM CINEMATIC PRO (FORCED CANVAS RESIZE)
    - Menu com área de Canvas pré-calculada para evitar colapso no Mobile
    - Drone Glide (Movimentação e Rotação 360° com Suavização Lerp)
    - Modo Cinema Automático e Gerador de Tela Verde (Chroma Key)
    - Ferramentas de Cenário: Ocultar Jogadores, Clone de Atores e Filtro Ultra
    - Módulos IA: Diretor de Corte, Drone Physics (Roll) e Enquadramento de Foco
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =============================================================================
-- [1] LIMPEZA DE INSTÂNCIAS E CONFIGURAÇÕES GLOBAIS
-- =============================================================================
if CoreGui:FindFirstChild("YtDevs") then CoreGui.YtDevs:Destroy() end
if CoreGui:FindFirstChild("YtDevsMobileControls") then CoreGui.YtDevsMobileControls:Destroy() end

shared.Screen = Instance.new("ScreenGui", CoreGui)
shared.Screen.Name = "YtDevs"
shared.Screen.ResetOnSpawn = false

shared.FreeCamActive = false
shared.CamLockActive = false
shared.LockedCameraCFrame = nil
shared.moveSpeed = 20
shared.cameraFOV = 70
shared.cameraYaw, shared.cameraPitch = 0, 0
shared.flyUp, shared.flyDown = false, false
shared.moveInputVector = Vector3.new(0, 0, 0)
shared.dragInput = nil
shared.dragStart = nil

local greenScreenPart = nil
local playersHidden = false
local originalLightingSettings = {}
local cinematicLightingActive = false
local currentClone = nil
local targetCameraCFrame = Camera.CFrame
local smoothSensitivity = 0.007
local glideWeight = 0.15

local aiDirectorActive = false
local aiDronePhysicsActive = false
local aiAutoFramingActive = false
local lastAction = "Idle"
local currentRoll = 0
local frameDistance = 14

-- =============================================================================
-- [2] FUNÇÕES AUXILIARES E ARRASTE DA INTERFACE
-- =============================================================================
function shared.setCharacterFrozen(frozen)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then 
        char.HumanoidRootPart.Anchored = frozen 
    end
end

function shared.setCinematicMode(enabled)
    local state = not enabled
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, state)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, state)
    end)
end

local function MakeDraggable(obj)
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

-- =============================================================================
-- [3] CONSTRUÇÃO DA INTERFACE VISUAL PRINCIPAL (GUI)
-- =============================================================================
local Main = Instance.new("Frame", shared.Screen)
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 320)
Main.Position = UDim2.new(0.5, -140, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.new(1, 1, 1)
MakeDraggable(Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "YTDEVS CINEMATIC HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)

local MinBtn = Instance.new("TextButton", Main)
MinBtn.Size = UDim2.new(0, 30, 0, 40)
MinBtn.Position = UDim2.new(1, -40, 0, 0)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BackgroundTransparency = 1

local MinCircle = Instance.new("Frame", shared.Screen)
MinCircle.Size = UDim2.new(0, 55, 0, 55)
MinCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
MinCircle.Visible = false
Instance.new("UICorner", MinCircle).CornerRadius = UDim.new(1, 0)
local MinLabel = Instance.new("TextLabel", MinCircle)
MinLabel.Size = UDim2.new(1,0,1,0)
MinLabel.Text = "YT"
MinLabel.TextColor3 = Color3.new(1,1,1)
MinLabel.Font = Enum.Font.GothamBlack
MinLabel.BackgroundTransparency = 1
MakeDraggable(MinCircle)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    MinCircle.Position = Main.Position
    MinCircle.Visible = true
end)

MinCircle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        task.wait(0.1)
        Main.Position = MinCircle.Position
        MinCircle.Visible = false
        Main.Visible = true
    end
end)

-- =============================================================================
-- [4] CONSTRUÇÃO FORÇADA DO PAINEL DE ROLAGEM
-- =============================================================================
local ScrollFrame = Instance.new("ScrollingFrame", Main)
ScrollFrame.Name = "Container"
ScrollFrame.Size = UDim2.new(1, 0, 1, -40)
ScrollFrame.Position = UDim2.new(0, 0, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 125)
-- Mudança crucial: Força uma altura de rolagem física de 600 pixels para evitar colapso mobile
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600) 

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local UIPadding = Instance.new("UIPadding", ScrollFrame)
UIPadding.PaddingTop = UDim.new(0, 8)
UIPadding.PaddingBottom = UDim.new(0, 15)

-- =============================================================================
-- [5] ADICIONANDO COMPONENTES
-- =============================================================================
local SpeedFrame = Instance.new("Frame", ScrollFrame)
SpeedFrame.Size = UDim2.new(1, -30, 0, 40)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", SpeedFrame)

local SpeedLabel = Instance.new("TextLabel", SpeedFrame)
SpeedLabel.Size = UDim2.new(0, 120, 1, 0)
SpeedLabel.Position = UDim2.new(0, 10, 0, 0)
SpeedLabel.Text = "Velocidade: 20"
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.BackgroundTransparency = 1

local SpeedMinus = Instance.new("TextButton", SpeedFrame)
SpeedMinus.Size = UDim2.new(0, 30, 0, 30)
SpeedMinus.Position = UDim2.new(1, -70, 0, 5)
SpeedMinus.Text = "-"
SpeedMinus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SpeedMinus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SpeedMinus)

local SpeedPlus = Instance.new("TextButton", SpeedFrame)
SpeedPlus.Size = UDim2.new(0, 30, 0, 30)
SpeedPlus.Position = UDim2.new(1, -35, 0, 5)
SpeedPlus.Text = "+"
SpeedPlus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
SpeedPlus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SpeedPlus)

SpeedMinus.MouseButton1Click:Connect(function()
    shared.moveSpeed = math.max(2, shared.moveSpeed - 3)
    SpeedLabel.Text = "Velocidade: " .. shared.moveSpeed
end)
SpeedPlus.MouseButton1Click:Connect(function()
    shared.moveSpeed = math.min(120, shared.moveSpeed + 3)
    SpeedLabel.Text = "Velocidade: " .. shared.moveSpeed
end)

local FOVFrame = Instance.new("Frame", ScrollFrame)
FOVFrame.Size = UDim2.new(1, -30, 0, 40)
FOVFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", FOVFrame)

local FOVLabel = Instance.new("TextLabel", FOVFrame)
FOVLabel.Size = UDim2.new(0, 120, 1, 0)
FOVLabel.Position = UDim2.new(0, 10, 0, 0)
FOVLabel.Text = "Zoom (FOV): 70"
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.Font = Enum.Font.GothamBold
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.BackgroundTransparency = 1

local FOVMinus = Instance.new("TextButton", FOVFrame)
FOVMinus.Size = UDim2.new(0, 30, 0, 30)
FOVMinus.Position = UDim2.new(1, -70, 0, 5)
FOVMinus.Text = "In"
FOVMinus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
FOVMinus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", FOVMinus)

local FOVPlus = Instance.new("TextButton", FOVFrame)
FOVPlus.Size = UDim2.new(0, 30, 0, 30)
FOVPlus.Position = UDim2.new(1, -35, 0, 5)
FOVPlus.Text = "Out"
FOVPlus.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
FOVPlus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", FOVPlus)

FOVMinus.MouseButton1Click:Connect(function()
    shared.cameraFOV = math.max(25, shared.cameraFOV - 5)
    FOVLabel.Text = "Zoom (FOV): " .. shared.cameraFOV
    Camera.FieldOfView = shared.cameraFOV
end)
FOVPlus.MouseButton1Click:Connect(function()
    shared.cameraFOV = math.min(100, shared.cameraFOV + 5)
    FOVLabel.Text = "Zoom (FOV): " .. shared.cameraFOV
    Camera.FieldOfView = shared.cameraFOV
end)

local function createScrollBtn(text, color)
    local btn = Instance.new("TextButton", ScrollFrame)
    btn.Size = UDim2.new(1, -30, 0, 45)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn)
    return btn
end

shared.FreeCamBtn = createScrollBtn("ATIVAR FREE CAM", Color3.fromRGB(55, 55, 60))
shared.CamLockBtn = createScrollBtn("CAM LOCK", Color3.fromRGB(55, 55, 60))
local GreenBtn = createScrollBtn("SPAWNAR TELA VERDE", Color3.fromRGB(0, 140, 0))
local AntiSnipeBtn = createScrollBtn("OCULTAR OUTROS JOGADORES", Color3.fromRGB(130, 0, 0))
local CloneBtn = createScrollBtn("GERAR CLONE (ATOR)", Color3.fromRGB(70, 0, 150))
local LightBtn = createScrollBtn("FILTRO: GRÁFICOS NO ULTRA", Color3.fromRGB(45, 45, 50))

local DirectorBtn = createScrollBtn("IA: DIRETOR DE CORTE (OFF)", Color3.fromRGB(0, 50, 120))
local DronePhysBtn = createScrollBtn("IA: DRONE PHYSICS (OFF)", Color3.fromRGB(0, 50, 120))
local FramingBtn = createScrollBtn("IA: ENQUADRAMENTO DE FOCO (OFF)", Color3.fromRGB(0, 50, 120))

-- =============================================================================
-- [6] RECURSOS EXTRAS
-- =============================================================================
GreenBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if greenScreenPart then greenScreenPart:Destroy() end
        greenScreenPart = Instance.new("Part", workspace)
        greenScreenPart.Size = Vector3.new(30, 22, 1)
        greenScreenPart.Color = Color3.fromRGB(0, 255, 0)
        greenScreenPart.Material = Enum.Material.SmoothPlastic
        greenScreenPart.Anchored = true
        greenScreenPart.CanCollide = false
        greenScreenPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 5, -7)
    end
end)

local function togglePlayersVisibility(hide)
    playersHidden = hide
    AntiSnipeBtn.BackgroundColor3 = hide and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(130, 0, 0)
    AntiSnipeBtn.Text = hide and "JOGADORES OCULTADOS" or "OCULTAR OUTROS JOGADORES"
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    if not part:GetAttribute("OriginalTransparency") then part:SetAttribute("OriginalTransparency", part.Transparency) end
                    part.Transparency = hide and 1 or part:GetAttribute("OriginalTransparency")
                end
            end
        end
    end
end
AntiSnipeBtn.MouseButton1Click:Connect(function() togglePlayersVisibility(not playersHidden) end)

CloneBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if currentClone then currentClone:Destroy() end
        char.Archivable = true
        currentClone = char:Clone()
        char.Archivable = false
        currentClone.Parent = workspace
        currentClone:MoveTo(char.HumanoidRootPart.Position)
        for _, part in pairs(currentClone:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = true end
            if part:IsA("LocalScript") or part:IsA("Script") then part:Destroy() end
        end
        CloneBtn.Text = "CLONE GERADO! (CLIQUE P/ LIMPAR)"
        CloneBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        if currentClone then
            currentClone:Destroy()
            currentClone = nil
            CloneBtn.Text = "GERAR CLONE (ATOR)"
            CloneBtn.BackgroundColor3 = Color3.fromRGB(70, 0, 150)
        end
    end
end)

originalLightingSettings.Ambient = Lighting.Ambient
originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient
originalLightingSettings.Brightness = Lighting.Brightness
local colorCorrection = Instance.new("ColorCorrectionEffect")
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.Enabled = false
colorCorrection.Enabled = false
colorCorrection.Parent = Lighting
depthOfField.Parent = Lighting

LightBtn.MouseButton1Click:Connect(function()
    cinematicLightingActive = not cinematicLightingActive
    if cinematicLightingActive then
        LightBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        LightBtn.Text = "FILTRO CINEMA: ATIVADO"
        Lighting.Ambient = Color3.fromRGB(140, 140, 150)
        Lighting.Brightness = 2.5
        colorCorrection.Saturation = 0.25
        colorCorrection.Contrast = 0.15
        colorCorrection.Enabled = true
        depthOfField.FarIntensity = 0.8
        depthOfField.FocusDistance = 15
        depthOfField.InFocusRadius = 20
        depthOfField.Enabled = true
    else
        LightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        LightBtn.Text = "FILTRO: GRÁFICOS NO ULTRA"
        Lighting.Ambient = originalLightingSettings.Ambient
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
        Lighting.Brightness = originalLightingSettings.Brightness
        colorCorrection.Enabled = false
        depthOfField.Enabled = false
    end
end)

-- =============================================================================
-- [7] CONTROLES MOBILE
-- =============================================================================
shared.MobileControls = Instance.new("ScreenGui", CoreGui)
shared.MobileControls.Name = "YtDevsMobileControls"
shared.MobileControls.Enabled = false

local JoystickBase = Instance.new("Frame", shared.MobileControls)
JoystickBase.Size = UDim2.new(0, 110, 0, 110)
JoystickBase.Position = UDim2.new(0.08, 0, 0.62, 0)
JoystickBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JoystickBase.BackgroundTransparency = 0.6
Instance.new("UICorner", JoystickBase).CornerRadius = UDim.new(1, 0)

local JoystickStick = Instance.new("Frame", JoystickBase)
JoystickStick.Size = UDim2.new(0, 45, 0, 45)
JoystickStick.Position = UDim2.new(0.5, -22, 0.5, -22)
JoystickStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", JoystickStick).CornerRadius = UDim.new(1, 0)

local function CreateAltitudeBtn(text, pos)
    local btn = Instance.new("TextButton", shared.MobileControls)
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.5
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.TextSize = 20
    Instance.new("UICorner", btn)
    return btn
end

local BtnUp = CreateAltitudeBtn("▲", UDim2.new(0.85, 0, 0.5, -65))
local BtnDown = CreateAltitudeBtn("▼", UDim2.new(0.85, 0, 0.5, 15))

BtnUp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then shared.flyUp = true end end)
BtnUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then shared.flyUp = false end end)
BtnDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then shared.flyDown = true end end)
BtnDown.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then shared.flyDown = false end end)

JoystickBase.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        shared.dragInput = input
        shared.dragStart = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == shared.dragInput then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - shared.dragStart
        local maxLength = 45
        if delta.Magnitude > maxLength then delta = delta.Unit * maxLength end
        JoystickStick.Position = UDim2.new(0.5, -22 + delta.X, 0.5, -22 + delta.Y)
        shared.moveInputVector = Vector3.new(delta.X / maxLength, 0, delta.Y / maxLength)
    elseif shared.FreeCamActive and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= shared.dragInput then
        shared.cameraYaw = shared.cameraYaw - (input.Delta.X * smoothSensitivity)
        shared.cameraPitch = shared.cameraPitch - (input.Delta.Y * smoothSensitivity)
        shared.cameraPitch = math.clamp(shared.cameraPitch, -math.rad(88), math.rad(88))
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == shared.dragInput then
        shared.dragInput = nil
        JoystickStick.Position = UDim2.new(0.5, -22, 0.5, -22)
        shared.moveInputVector = Vector3.new(0, 0, 0)
    end
end)

local DataHUD = Instance.new("Frame", shared.MobileControls)
DataHUD.Size = UDim2.new(0, 160, 0, 50)
DataHUD.Position = UDim2.new(0.02, 0, 0.02, 0)
DataHUD.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DataHUD.BackgroundTransparency = 0.6
Instance.new("UICorner", DataHUD)
Instance.new("UIStroke", DataHUD).Color = Color3.new(1, 1, 1)

local SpeedText = Instance.new("TextLabel", DataHUD)
SpeedText.Size = UDim2.new(1, -10, 0, 25)
SpeedText.Position = UDim2.new(0, 10, 0, 0)
SpeedText.Text = "VELOCIDADE: 20 ST/S"
SpeedText.TextColor3 = Color3.new(1, 1, 0)
SpeedText.Font = Enum.Font.Code
SpeedText.TextSize = 12
SpeedText.TextXAlignment = Enum.TextXAlignment.Left
SpeedText.BackgroundTransparency = 1

local FOVText = Instance.new("TextLabel", DataHUD)
FOVText.Size = UDim2.new(1, -10, 0, 25)
FOVText.Position = UDim2.new(0, 10, 0, 20)
FOVText.Text = "LENTE (FOV): 70°"
FOVText.TextColor3 = Color3.new(0, 1, 1)
FOVText.Font = Enum.Font.Code
FOVText.TextSize = 12
FOVText.TextXAlignment = Enum.TextXAlignment.Left
FOVText.BackgroundTransparency = 1

-- =============================================================================
-- [8] LOOP FÍSICO E RENDERSTEPPED
-- =============================================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if shared.FreeCamActive then shared.setCinematicMode(true) end
    end
end)

RS.RenderStepped:Connect(function(delta)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    
    if shared.FreeCamActive then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = shared.cameraFOV
        
        if aiDirectorActive and hrp and humanoid then
            local velocity = hrp.AssemblyLinearVelocity.Magnitude
            if velocity < 1 and lastAction ~= "Idle" then
                lastAction = "Idle"
                shared.cameraFOV = 45
                shared.moveSpeed = 8
                local targetAngle = hrp.CFrame * CFrame.new(8, 3, -8)
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(targetAngle.Position, hrp.Position), 0.05)
            elseif velocity >= 1 and lastAction ~= "Moving" then
                lastAction = "Moving"
                shared.cameraFOV = 75
                shared.moveSpeed = 25
            end
        end
        
        local lookCF = CFrame.Angles(0, shared.cameraYaw, 0) * CFrame.Angles(shared.cameraPitch, 0, 0)
        local moveDir = Vector3.new(0, 0, 0)
        if shared.moveInputVector.Magnitude > 0 then
            local camRot = Camera.CFrame - Camera.CFrame.Position
            moveDir = camRot:VectorToWorldSpace(Vector3.new(shared.moveInputVector.X, 0, shared.moveInputVector.Z))
        end
        
        local verticalMove = 0
        if shared.flyUp then verticalMove = 1 elseif shared.flyDown then verticalMove = -1 end
        
        local finalMove = Vector3.new(moveDir.X, moveDir.Y + verticalMove, moveDir.Z)
        if finalMove.Magnitude > 0 then finalMove = finalMove.Unit * shared.moveSpeed * delta end
        
        local nextPosition = targetCameraCFrame.Position + finalMove
        local nextCFrame = CFrame.new(nextPosition) * lookCF
        
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, glideWeight)
        targetCameraCFrame = nextCFrame
        
        if aiDronePhysicsActive then
            if shared.moveInputVector.X ~= 0 then
                local targetRoll = -math.rad(8) * shared.moveInputVector.X
                currentRoll = math.clamp(currentRoll + (targetRoll - currentRoll) * 0.05, -0.15, 0.15)
            else
                currentRoll = currentRoll * 0.9
            end
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, currentRoll)
        end
        
        DataHUD.Visible = true
        SpeedText.Text = "VELOCIDADE: " .. shared.moveSpeed .. " ST/S"
        FOVText.Text = "LENTE (FOV): " .. shared.cameraFOV .. "°"
        
    elseif aiAutoFramingActive and hrp then
        Camera.CameraType = Enum.CameraType.Scriptable
        local currentDist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if currentDist > frameDistance then
            shared.cameraFOV = math.clamp(shared.cameraFOV - 0.5, 30, 85)
        elseif currentDist < frameDistance - 2 then
            shared.cameraFOV = math.clamp(shared.cameraFOV + 0.5, 30, 85)
        end
        Camera.FieldOfView = shared.cameraFOV
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position + Vector3.new(0, 1, 0))
        
        DataHUD.Visible = true
        SpeedText.Text = "VELOCIDADE: IA ACTIVE"
        FOVText.Text = "LENTE (FOV): " .. shared.cameraFOV .. "°"
        
    elseif shared.CamLockActive then
        Camera.CameraType = Enum.CameraType.Scriptable
        if shared.LockedCameraCFrame then Camera.CFrame = shared.LockedCameraCFrame end
        DataHUD.Visible = false
    else
        Camera.CameraType = Enum.CameraType.Custom
        DataHUD.Visible = false
    end
end)

-- =============================================================================
-- [9] GATILHOS DE ATIVAÇÃO
-- =============================================================================
local function toggleFreeCam(on)
    shared.FreeCamActive = on
    shared.MobileControls.Enabled = on or aiAutoFramingActive
    shared.setCharacterFrozen(on)
    shared.setCinematicMode(on)
    if on then
        shared.CamLockActive = false
        aiAutoFramingActive = false
        FramingBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
        FramingBtn.Text = "IA: ENQUADRAMENTO DE FOCO (OFF)"
        shared.CamLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        shared.FreeCamBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        shared.FreeCamBtn.Text = "DESATIVAR FREE CAM"
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        shared.cameraYaw, shared.cameraPitch = y, x
        targetCameraCFrame = Camera.CFrame
    else
        shared.FreeCamBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        shared.FreeCamBtn.Text = "ATIVAR FREE CAM"
        shared.setCinematicMode(false)
    end
end

local function toggleCamLock(on)
    shared.CamLockActive = on
    if on then
        toggleFreeCam(false)
        shared.CamLockBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        shared.LockedCameraCFrame = Camera.CFrame
    else
        shared.CamLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        shared.LockedCameraCFrame = nil
    end
end

shared.FreeCamBtn.MouseButton1Click:Connect(function() toggleFreeCam(not shared.FreeCamActive) end)
shared.CamLockBtn.MouseButton1Click:Connect(function() toggleCamLock(not shared.CamLockActive) end)

DirectorBtn.MouseButton1Click:Connect(function()
    aiDirectorActive = not aiDirectorActive
    DirectorBtn.BackgroundColor3 = aiDirectorActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(0, 50, 120)
    DirectorBtn.Text = aiDirectorActive and "IA: DIRETOR DE CORTE (ATIVADO)" or "IA: DIRETOR DE CORTE (OFF)"
end)

DronePhysBtn.MouseButton1Click:Connect(function()
    aiDronePhysicsActive = not aiDronePhysicsActive
    DronePhysBtn.BackgroundColor3 = aiDronePhysicsActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(0, 50, 120)
    DronePhysBtn.Text = aiDronePhysicsActive and "IA: DRONE PHYSICS (ATIVADO)" or "IA: DRONE PHYSICS (OFF)"
    if not aiDronePhysicsActive then currentRoll = 0 end
end)

FramingBtn.MouseButton1Click:Connect(function()
    aiAutoFramingActive = not aiAutoFramingActive
    if aiAutoFramingActive then
        if shared.FreeCamActive then toggleFreeCam(false) end
        shared.CamLockActive = false
        shared.CamLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        FramingBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        FramingBtn.Text = "IA: ENQUADRAMENTO DE FOCO (ATIVADO)"
        shared.MobileControls.Enabled = true
        shared.setCharacterFrozen(false)
    else
        FramingBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
        FramingBtn.Text = "IA: ENQUADRAMENTO DE FOCO (OFF)"
        shared.MobileControls.Enabled = false
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

print("YTDEVS HUB: Inicializado com Canvas físico adaptativo!")
