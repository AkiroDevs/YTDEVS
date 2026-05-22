--[[
    YTDEVS - FREE CAM CINEMATIC PRO (PARTE 1)
    - Menu Principal com Controle de Velocidade e FOV
    - Botão de Tela Verde (Chroma Key)
    - Analógico Virtual Independente e Botões de Altitude
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Limpa execuções anteriores para evitar sobreposição
if CoreGui:FindFirstChild("YtDevs") then CoreGui.YtDevs:Destroy() end
if CoreGui:FindFirstChild("YtDevsMobileControls") then CoreGui.YtDevsMobileControls:Destroy() end

shared.Screen = Instance.new("ScreenGui", CoreGui)
shared.Screen.Name = "YtDevs"
shared.Screen.ResetOnSpawn = false

-- Configurações Compartilhadas (Globais entre as partes)
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

-- Função para fixar o personagem
function shared.setCharacterFrozen(frozen)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then 
        char.HumanoidRootPart.Ancuted = frozen 
    end
end

-- Função Modo Cinema
function shared.setCinematicMode(enabled)
    local state = not enabled
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, state)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, state)
    end)
end

-- Função de Arrastar Janela
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

-- ================== JANELA PRINCIPAL ==================
local Main = Instance.new("Frame", shared.Screen)
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 360)
Main.Position = UDim2.new(0.5, -140, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.new(1, 1, 1)
MakeDraggable(Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "YTDEVS CINEMATIC V1"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)

local MinBtn = Instance.new("TextButton", Main)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -40, 0, 2)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BackgroundTransparency = 1

-- Círculo de Minimizar
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

-- CONTROLE DE VELOCIDADE
local SpeedFrame = Instance.new("Frame", Main)
SpeedFrame.Size = UDim2.new(1, -40, 0, 35)
SpeedFrame.Position = UDim2.new(0, 20, 0, 45)
SpeedFrame.BackgroundTransparency = 1

local SpeedLabel = Instance.new("TextLabel", SpeedFrame)
SpeedLabel.Size = UDim2.new(0, 120, 1, 0)
SpeedLabel.Text = "Velocidade: 20"
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.BackgroundTransparency = 1

local SpeedMinus = Instance.new("TextButton", SpeedFrame)
SpeedMinus.Size = UDim2.new(0, 30, 0, 30)
SpeedMinus.Position = UDim2.new(1, -65, 0, 2)
SpeedMinus.Text = "-"
SpeedMinus.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SpeedMinus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SpeedMinus)

local SpeedPlus = Instance.new("TextButton", SpeedFrame)
SpeedPlus.Size = UDim2.new(0, 30, 0, 30)
SpeedPlus.Position = UDim2.new(1, -30, 0, 2)
SpeedPlus.Text = "+"
SpeedPlus.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
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

-- CONTROLE DE FOV (ZOOM CINEMATOGRÁFICO)
local FOVFrame = Instance.new("Frame", Main)
FOVFrame.Size = UDim2.new(1, -40, 0, 35)
FOVFrame.Position = UDim2.new(0, 20, 0, 85)
FOVFrame.BackgroundTransparency = 1

local FOVLabel = Instance.new("TextLabel", FOVFrame)
FOVLabel.Size = UDim2.new(0, 120, 1, 0)
FOVLabel.Text = "Zoom (FOV): 70"
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.Font = Enum.Font.GothamBold
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.BackgroundTransparency = 1

local FOVMinus = Instance.new("TextButton", FOVFrame)
FOVMinus.Size = UDim2.new(0, 30, 0, 30)
FOVMinus.Position = UDim2.new(1, -65, 0, 2)
FOVMinus.Text = "In"
FOVMinus.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
FOVMinus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", FOVMinus)

local FOVPlus = Instance.new("TextButton", FOVFrame)
FOVPlus.Size = UDim2.new(0, 30, 0, 30)
FOVPlus.Position = UDim2.new(1, -30, 0, 2)
FOVPlus.Text = "Out"
FOVPlus.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
FOVPlus.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", FOVPlus)

local Camera = workspace.CurrentCamera
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

-- BOTÕES DE ATIVAÇÃO
shared.FreeCamBtn = Instance.new("TextButton", Main)
shared.FreeCamBtn.Size = UDim2.new(1, -40, 0, 45)
shared.FreeCamBtn.Position = UDim2.new(0, 20, 0, 130)
shared.FreeCamBtn.Text = "ATIVAR FREE CAM"
shared.FreeCamBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
shared.FreeCamBtn.TextColor3 = Color3.new(1, 1, 1)
shared.FreeCamBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", shared.FreeCamBtn)

shared.CamLockBtn = Instance.new("TextButton", Main)
shared.CamLockBtn.Size = UDim2.new(1, -40, 0, 45)
shared.CamLockBtn.Position = UDim2.new(0, 20, 0, 185)
shared.CamLockBtn.Text = "CAM LOCK"
shared.CamLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
shared.CamLockBtn.TextColor3 = Color3.new(1, 1, 1)
shared.CamLockBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", shared.CamLockBtn)

-- BOTÃO TELA VERDE (CHROMA KEY)
local GreenBtn = Instance.new("TextButton", Main)
GreenBtn.Size = UDim2.new(1, -40, 0, 45)
GreenBtn.Position = UDim2.new(0, 20, 0, 240)
GreenBtn.Text = "SPAWNAR TELA VERDE"
GreenBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
GreenBtn.TextColor3 = Color3.new(1, 1, 1)
GreenBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", GreenBtn)

GreenBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if greenScreenPart then greenScreenPart:Destroy() end
        greenScreenPart = Instance.new("Part", workspace)
        greenScreenPart.Size = Vector3.new(25, 20, 1)
        greenScreenPart.Color = Color3.fromRGB(0, 255, 0)
        greenScreenPart.Material = Enum.Material.SmoothPlastic
        greenScreenPart.Anchored = true
        greenScreenPart.CanCollide = false
        -- Posiciona ligeiramente atrás do personagem
        greenScreenPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 4, -6)
    end
end)

-- INTERFACE MOBILE (ANALÓGICO VIRTUAL EXCLUSIVO)
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
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == shared.dragInput then
        shared.dragInput = nil
        JoystickStick.Position = UDim2.new(0.5, -22, 0.5, -22)
        shared.moveInputVector = Vector3.new(0, 0, 0)
    end
end)

print("Parte 1 carregada com sucesso!")--[[
    YTDEVS - FREE CAM CINEMATIC PRO (PARTE 2)
    - Conexão com as variáveis da Parte 1
    - Suavização Drone Glide (Matriz Lerp aplicada na Câmera)
    - Rotação livre 360 graus pelo toque direito da tela
]]

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Alvos de suavização (Inércia/Glide)
local targetCameraCFrame = Camera.CFrame
local smoothSensitivity = 0.007
local glideWeight = 0.15 -- Quanto MENOR, mais suave e pesado fica o glide da câmera (0.15 é o perfeito)

UIS.InputChanged:Connect(function(input)
    if shared.FreeCamActive and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and input ~= shared.dragInput then
        -- Permite rotação fluida sem limites no eixo horizontal (esquerda/direita)
        shared.cameraYaw = shared.cameraYaw - (input.Delta.X * smoothSensitivity)
        shared.cameraPitch = shared.cameraPitch - (input.Delta.Y * smoothSensitivity)
        shared.cameraPitch = math.clamp(shared.cameraPitch, -math.rad(88), math.rad(88))
    end
end)

-- Loop que força a ocultação da interface no Modo Cinema
task.spawn(function()
    while true do
        task.wait(0.2)
        if shared.FreeCamActive then
            shared.setCinematicMode(true)
        end
    end
end)

-- ATUALIZAÇÃO FÍSICA SUAVE (RENDERSTEPPED)
RS.RenderStepped:Connect(function(delta)
    if shared.FreeCamActive then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = shared.cameraFOV
        
        local lookCF = CFrame.Angles(0, shared.cameraYaw, 0) * CFrame.Angles(shared.cameraPitch, 0, 0)
        local moveDir = Vector3.new(0, 0, 0)
        
        if shared.moveInputVector.Magnitude > 0 then
            local camRot = Camera.CFrame - Camera.CFrame.Position
            moveDir = camRot:VectorToWorldSpace(Vector3.new(shared.moveInputVector.X, 0, shared.moveInputVector.Z))
        end
        
        local verticalMove = 0
        if shared.flyUp then verticalMove = 1 elseif shared.flyDown then verticalMove = -1 end
        
        local finalMove = Vector3.new(moveDir.X, moveDir.Y + verticalMove, moveDir.Z)
        if finalMove.Magnitude > 0 then
            finalMove = finalMove.Unit * shared.moveSpeed * delta
        end
        
        -- DRONE GLIDE APLICADO: Em vez de mudar a posição bruscamente, usamos o Lerp
        local nextPosition = targetCameraCFrame.Position + finalMove
        local nextCFrame = CFrame.new(nextPosition) * lookCF
        
        -- Interpola suavemente da CFrame atual para a nova CFrame baseado no peso do glide
        Camera.CFrame = Camera.CFrame:Lerp(nextCFrame, glideWeight)
        targetCameraCFrame = nextCFrame
        
    elseif shared.CamLockActive then
        Camera.CameraType = Enum.CameraType.Scriptable
        if shared.LockedCameraCFrame then Camera.CFrame = shared.LockedCameraCFrame end
    else
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

-- Funções de Alternância dos Botões
local function toggleFreeCam(on)
    shared.FreeCamActive = on
    shared.MobileControls.Enabled = on
    shared.setCharacterFrozen(on)
    shared.setCinematicMode(on)
    
    if on then
        shared.CamLockActive = false
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

print("Parte 2 carregada! Ferramenta pronta para uso.")--[[
    YTDEVS - FREE CAM CINEMATIC PRO (PARTE 3)
    - Modo Anti-Penetras (Jogadores Invisíveis)
    - Clone de Ator Estático para Gravações
    - Filtro Gráfico "PC no Ultra" (Iluminação de Cinema)
    - HUD de Dados Cinematográficos (Velocidade e FOV na tela)
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Main = shared.Screen:FindFirstChild("Main")

if not Main then 
    warn("Erro: Execute a Parte 1 antes de carregar a Parte 3!")
    return 
end

-- Aumenta o tamanho da janela principal para caber os novos recursos
Main.Size = UDim2.new(0, 280, 0, 520)

-- Estados das novas funções
local playersHidden = false
local originalLightingSettings = {}
local cinematicLightingActive = false
local currentClone = nil

-- Função Auxiliar para Criar Botões Padronizados
local function createNewBtn(text, pos, color)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

-- ================== 1. BOTÃO ANTI-PENETRAS (OCULTAR JOGADORES) ==================
local AntiSnipeBtn = createNewBtn("OCULTAR OUTROS JOGADORES", UDim2.new(0, 20, 0, 295), Color3.fromRGB(130, 0, 0))

local function togglePlayersVisibility(hide)
    playersHidden = hide
    AntiSnipeBtn.BackgroundColor3 = hide and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(130, 0, 0)
    AntiSnipeBtn.Text = hide and "JOGADORES OCULTADOS" or "OCULTAR OUTROS JOGADORES"
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    if not part:GetAttribute("OriginalTransparency") then
                        part:SetAttribute("OriginalTransparency", part.Transparency)
                    end
                    part.Transparency = hide and 1 or part:GetAttribute("OriginalTransparency")
                end
            end
        end
    end
end

AntiSnipeBtn.MouseButton1Click:Connect(function()
    togglePlayersVisibility(not playersHidden)
end)

-- Garante que novos jogadores que entrarem também fiquem invisíveis se o modo estiver ativo
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if playersHidden then
            task.wait(0.5)
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = 1
                end
            end
        end
    end)
end)

-- ================== 2. BOTÃO CLONE DE ATOR ==================
local CloneBtn = createNewBtn("GERAR CLONE (ATOR)", UDim2.new(0, 20, 0, 345), Color3.fromRGB(70, 0, 150))

CloneBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if currentClone then currentClone:Destroy() end
        
        -- Configura o boneco clonado
        char.Archivable = true
        currentClone = char:Clone()
        char.Archivable = false
        
        currentClone.Parent = workspace
        currentClone:MoveTo(char.HumanoidRootPart.Position)
        
        -- Congela o clone para ele não cair ou sumir
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

-- ================== 3. BOTÃO ILUMINAÇÃO DE CINEMA ==================
local LightBtn = createNewBtn("FILTRO: GRÁFICOS NO ULTRA", UDim2.new(0, 20, 0, 395), Color3.fromRGB(45, 45, 50))

-- Salva os dados originais do mapa para não estragar o jogo original ao desligar
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
        
        -- Modificações visuais de atmosfera cinematográfica
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
        
        -- Restaura o padrão do mapa
        Lighting.Ambient = originalLightingSettings.Ambient
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
        Lighting.Brightness = originalLightingSettings.Brightness
        colorCorrection.Enabled = false
        depthOfField.Enabled = false
    end
end)

-- ================== 4. PAINEL DE DADOS CINEMATOGRÁFICOS ==================
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

-- Atualiza as informações do painel em tempo real
RS.RenderStepped:Connect(function()
    if shared.FreeCamActive then
        DataHUD.Visible = true
        SpeedText.Text = "VELOCIDADE: " .. shared.moveSpeed .. " ST/S"
        FOVText.Text = "LENTE (FOV): " .. shared.cameraFOV .. "°"
    else
        DataHUD.Visible = false
    end
end)

print("Parte 3 instalada com sucesso! O estúdio mobile de cinema está completo.")
