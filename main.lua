-- PG HUB - Steal an Egg v1.0

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Configurações
local VelocidadeRun    = 1e15
local DistanciaChegada = 4
local IgnorarY         = true
local WalkTemp         = 500
local JumpTemp         = 120

-- Cores
local COR_AMARELO  = Color3.fromRGB(255, 215, 0)
local COR_VERDE    = Color3.fromRGB(0, 220, 100)
local COR_LARANJA  = Color3.fromRGB(255, 140, 0)
local COR_VERMELHO = Color3.fromRGB(255, 60, 60)
local COR_CINZA    = Color3.fromRGB(58, 58, 66)
local COR_FUNDO    = Color3.fromRGB(20, 20, 26)
local COR_FUNDO2   = Color3.fromRGB(32, 32, 40)

-- Estado
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local RootPart  = Character:WaitForChild("HumanoidRootPart")

local alvo         = nil
local teleportando = false
local connRun      = nil
local walkOriginal = nil
local jumpOriginal = nil

-- GUI principal
local gui = Instance.new("ScreenGui")
gui.Name           = "PG_Hub"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 9999
gui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- Helpers

local function criarSombra(parent, tamanho, posicao, transparencia)
    local sombra = Instance.new("Frame")
    sombra.Size                   = tamanho
    sombra.Position               = posicao
    sombra.BackgroundColor3       = Color3.new(0, 0, 0)
    sombra.BackgroundTransparency = transparencia or 0.55
    sombra.BorderSizePixel        = 0
    sombra.ZIndex                 = 0
    sombra.Parent                 = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = sombra
    return sombra
end

local function criarLED(parent, tamanho, cor)
    local led = Instance.new("Frame")
    led.Size = UDim2.fromOffset(tamanho, tamanho)
    led.BackgroundColor3 = cor
    led.BorderSizePixel = 0
    led.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = led

    local glow = Instance.new("UIStroke")
    glow.Color = cor
    glow.Thickness = 2
    glow.Transparency = 0.4
    glow.Parent = led

    return led
end

local function addBounce(btn)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = btn

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.08), {Scale = 0.97}):Play()
    end)

    btn.MouseButton1Up:Connect(function()
        TweenService:Create(scale,
            TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(scale,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = 1}):Play()
    end)
end

local function decorarBotao(btn, corBarra)
    local barra = Instance.new("Frame")
    barra.Size = UDim2.new(0, 3, 0.55, 0)
    barra.Position = UDim2.new(0, 5, 0.5, 0)
    barra.AnchorPoint = Vector2.new(0, 0.5)
    barra.BackgroundColor3 = corBarra
    barra.BorderSizePixel = 0
    barra.ZIndex = 3
    barra.Parent = btn

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = barra

    local seta = Instance.new("TextLabel")
    seta.Size = UDim2.fromOffset(16, 16)
    seta.Position = UDim2.new(1, -22, 0.5, -8)
    seta.BackgroundTransparency = 1
    seta.Text = "›"
    seta.TextColor3 = Color3.fromRGB(255, 255, 255)
    seta.TextTransparency = 0.55
    seta.Font = Enum.Font.GothamBold
    seta.TextSize = 18
    seta.ZIndex = 3
    seta.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(seta, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
            {Position = UDim2.new(1, -16, 0.5, -8), TextTransparency = 0}):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(seta, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
            {Position = UDim2.new(1, -22, 0.5, -8), TextTransparency = 0.55}):Play()
    end)

    addBounce(btn)
    return barra
end

local function addFlashClicavel(btn, corOriginal, barra, corBarra)
    btn.BackgroundColor3 = COR_CINZA

    local function restaurar()
        TweenService:Create(btn, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = COR_CINZA}):Play()
        if barra then
            TweenService:Create(barra, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = corBarra}):Play()
        end
    end

    local function acender()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = corOriginal}):Play()
        if barra then
            TweenService:Create(barra, TweenInfo.new(0.08),
                {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
        end
    end

    btn.MouseButton1Down:Connect(acender)
    btn.MouseButton1Up:Connect(function()
        task.delay(0.1, restaurar)
    end)
    btn.MouseLeave:Connect(restaurar)
end

-- Botão flutuante

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.Size = UDim2.fromOffset(40, 40)
holder.Position = UDim2.new(0, 20, 0.5, -20)
holder.BackgroundTransparency = 1
holder.ZIndex = 1000
holder.Parent = gui

criarSombra(holder, UDim2.fromOffset(40, 40), UDim2.fromOffset(3, 5), 0.5)
criarSombra(holder, UDim2.fromOffset(40, 40), UDim2.fromOffset(1, 2), 0.75)

local botao = Instance.new("TextButton")
botao.Size = UDim2.fromOffset(40, 40)
botao.BackgroundColor3 = COR_AMARELO
botao.Text = "PG"
botao.TextColor3 = Color3.fromRGB(255, 255, 255)
botao.Font = Enum.Font.GothamBold
botao.TextSize = 14
botao.AutoButtonColor = false
botao.BorderSizePixel = 0
botao.ZIndex = 1000
botao.Parent = holder

local cornerBotao = Instance.new("UICorner")
cornerBotao.CornerRadius = UDim.new(1, 0)
cornerBotao.Parent = botao

local strokeBotao = Instance.new("UIStroke")
strokeBotao.Color = Color3.fromRGB(255, 255, 255)
strokeBotao.Thickness = 1.5
strokeBotao.Transparency = 0.6
strokeBotao.Parent = botao

addBounce(botao)

-- Painel

local painel = Instance.new("Frame")
painel.Name = "Painel"
painel.Size = UDim2.fromOffset(190, 168)
painel.Position = UDim2.fromOffset(80, 160)
painel.BackgroundColor3 = COR_FUNDO
painel.BorderSizePixel = 0
painel.Visible = false
painel.ClipsDescendants = false
painel.ZIndex = 5
painel.Parent = gui

local cornerPainel = Instance.new("UICorner")
cornerPainel.CornerRadius = UDim.new(0, 10)
cornerPainel.Parent = painel

local strokePainel = Instance.new("UIStroke")
strokePainel.Thickness = 2
strokePainel.Color = Color3.new(1, 1, 1)
strokePainel.Transparency = 0
strokePainel.Parent = painel

local gradStroke = Instance.new("UIGradient")
gradStroke.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 90, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 250, 220)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(120, 90, 0)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0)),
})
gradStroke.Parent = strokePainel

task.spawn(function()
    while strokePainel.Parent do
        gradStroke.Rotation = (gradStroke.Rotation + 3) % 360
        task.wait(0.03)
    end
end)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, -18, 0, 2)
topLine.Position = UDim2.new(0, 9, 0, 1)
topLine.BackgroundColor3 = Color3.new(1, 1, 1)
topLine.BorderSizePixel = 0
topLine.ZIndex = 6
topLine.Parent = painel

local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 250, 220)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0)),
})
topGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1.0, 1),
})
topGrad.Parent = topLine

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(1, 0)
topCorner.Parent = topLine

local padPainel = Instance.new("UIPadding")
padPainel.PaddingTop    = UDim.new(0, 6)
padPainel.PaddingBottom = UDim.new(0, 6)
padPainel.PaddingLeft   = UDim.new(0, 8)
padPainel.PaddingRight  = UDim.new(0, 8)
padPainel.Parent = painel

local layoutPainel = Instance.new("UIListLayout")
layoutPainel.Padding = UDim.new(0, 5)
layoutPainel.SortOrder = Enum.SortOrder.LayoutOrder
layoutPainel.HorizontalAlignment = Enum.HorizontalAlignment.Center
layoutPainel.Parent = painel

-- Cabeçalho

local header = Instance.new("TextButton")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundTransparency = 1
header.Text = ""
header.AutoButtonColor = false
header.LayoutOrder = 1
header.Parent = painel

local ledHeader = criarLED(header, 7, COR_VERMELHO)
ledHeader.Position = UDim2.new(0, 0, 0, 5)
ledHeader.ZIndex = 6

task.spawn(function()
    while ledHeader.Parent do
        local t1 = TweenService:Create(ledHeader, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.85})
        local t2 = TweenService:Create(ledHeader, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0})
        t1:Play(); t1.Completed:Wait()
        t2:Play(); t2.Completed:Wait()
    end
end)

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -28, 0, 14)
titulo.Position = UDim2.new(0, 14, 0, 1)
titulo.BackgroundTransparency = 1
titulo.Text = "PG HUB"
titulo.TextColor3 = COR_AMARELO
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 12
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.ZIndex = 6
titulo.Parent = header

local subtitulo = Instance.new("TextLabel")
subtitulo.Size = UDim2.new(1, -28, 0, 10)
subtitulo.Position = UDim2.new(0, 14, 0, 14)
subtitulo.BackgroundTransparency = 1
subtitulo.Text = "Steal an Egg v1.0"
subtitulo.TextColor3 = Color3.fromRGB(150, 150, 160)
subtitulo.Font = Enum.Font.Gotham
subtitulo.TextSize = 9
subtitulo.TextXAlignment = Enum.TextXAlignment.Left
subtitulo.ZIndex = 6
subtitulo.Parent = header

local botaoFechar = Instance.new("TextButton")
botaoFechar.Size = UDim2.fromOffset(18, 18)
botaoFechar.Position = UDim2.new(1, -18, 0, 3)
botaoFechar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
botaoFechar.Text = "✕"
botaoFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoFechar.Font = Enum.Font.GothamBold
botaoFechar.TextSize = 10
botaoFechar.AutoButtonColor = false
botaoFechar.BorderSizePixel = 0
botaoFechar.ZIndex = 7
botaoFechar.Parent = header

local cornerFechar = Instance.new("UICorner")
cornerFechar.CornerRadius = UDim.new(1, 0)
cornerFechar.Parent = botaoFechar

addBounce(botaoFechar)

-- Botão Definir Local

local btnLocal = Instance.new("TextButton")
btnLocal.Size = UDim2.new(1, 0, 0, 28)
btnLocal.BackgroundColor3 = COR_CINZA
btnLocal.Text = "📍DEFINIR LOCAL📍"
btnLocal.TextColor3 = Color3.fromRGB(255, 255, 255)
btnLocal.Font = Enum.Font.GothamBold
btnLocal.TextSize = 10
btnLocal.AutoButtonColor = false
btnLocal.BorderSizePixel = 0
btnLocal.LayoutOrder = 2
btnLocal.ZIndex = 5
btnLocal.Parent = painel

local cornerLocal = Instance.new("UICorner")
cornerLocal.CornerRadius = UDim.new(0, 7)
cornerLocal.Parent = btnLocal

local barraLocal = decorarBotao(btnLocal, Color3.fromRGB(80, 220, 130))
addFlashClicavel(btnLocal, COR_VERDE, barraLocal, Color3.fromRGB(80, 220, 130))

-- Botão Speed Fast

local btnSpeed = Instance.new("TextButton")
btnSpeed.Size = UDim2.new(1, 0, 0, 28)
btnSpeed.BackgroundColor3 = COR_CINZA
btnSpeed.Text = "⚡SPEED FAST⚡"
btnSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSpeed.Font = Enum.Font.GothamBold
btnSpeed.TextSize = 10
btnSpeed.AutoButtonColor = false
btnSpeed.BorderSizePixel = 0
btnSpeed.LayoutOrder = 3
btnSpeed.ZIndex = 5
btnSpeed.Parent = painel

local cornerSpeed = Instance.new("UICorner")
cornerSpeed.CornerRadius = UDim.new(0, 7)
cornerSpeed.Parent = btnSpeed

local barraSpeed = decorarBotao(btnSpeed, Color3.fromRGB(255, 190, 100))
addFlashClicavel(btnSpeed, COR_LARANJA, barraSpeed, Color3.fromRGB(255, 190, 100))

-- Área de status

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, 0, 0, 44)
statusFrame.BackgroundColor3 = COR_FUNDO2
statusFrame.BorderSizePixel = 0
statusFrame.LayoutOrder = 4
statusFrame.ZIndex = 5
statusFrame.Parent = painel

local cornerStatus = Instance.new("UICorner")
cornerStatus.CornerRadius = UDim.new(0, 7)
cornerStatus.Parent = statusFrame

local padStatus = Instance.new("UIPadding")
padStatus.PaddingTop    = UDim.new(0, 4)
padStatus.PaddingBottom = UDim.new(0, 4)
padStatus.PaddingLeft   = UDim.new(0, 6)
padStatus.PaddingRight  = UDim.new(0, 6)
padStatus.Parent = statusFrame

local ledStatus = criarLED(statusFrame, 5, COR_VERMELHO)
ledStatus.Position = UDim2.new(0, 0, 0, 4)
ledStatus.ZIndex = 6

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -10, 1, 0)
status.Position = UDim2.new(0, 10, 0, 0)
status.BackgroundTransparency = 1
status.RichText = true
status.Text = ""
status.TextColor3 = Color3.fromRGB(230, 230, 230)
status.Font = Enum.Font.Gotham
status.TextSize = 9
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.ZIndex = 6
status.Parent = statusFrame

-- Arraste

local function tornarArrastavel(frame, alca)
    local arrastando = false
    local moveu = false
    local posInicial, inputInicial

    alca.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            moveu = false
            inputInicial = Vector2.new(input.Position.X, input.Position.Y)
            posInicial = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not arrastando then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local atual = Vector2.new(input.Position.X, input.Position.Y)
            local delta = atual - inputInicial
            if delta.Magnitude > 5 then moveu = true end

            frame.Position = UDim2.new(
                posInicial.X.Scale, posInicial.X.Offset + delta.X,
                posInicial.Y.Scale, posInicial.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
        end
    end)

    return function() return moveu end
end

local foiArrastado = tornarArrastavel(holder, botao)
tornarArrastavel(painel, header)

-- Atualizar status

local function atualizarStatus()
    local corLED = COR_VERMELHO
    local corLocal = "rgb(255,80,80)"
    local corSpeed = "rgb(160,160,170)"

    if alvo then
        corLED = COR_LARANJA
        corLocal = "rgb(80,220,120)"
    end

    if teleportando then
        corLED = COR_VERDE
        corSpeed = "rgb(80,220,120)"
    end

    ledStatus.BackgroundColor3 = corLED
    local glow = ledStatus:FindFirstChildOfClass("UIStroke")
    if glow then glow.Color = corLED end

    local txtLocal
    if alvo then
        txtLocal = string.format("📍 Local: <b>DEFINIDO</b> (%.0f, %.0f, %.0f)", alvo.X, alvo.Y, alvo.Z)
    else
        txtLocal = "📍 Local: <b>não definido</b>"
    end

    local txtSpeed = teleportando
        and "⚡ Speed Fast: <b>ATIVO</b>"
        or  "⚡ Speed Fast: <i>inativo</i>"

    status.Text = string.format(
        '<font color="%s">%s</font><br/><font color="%s">%s</font>',
        corLocal, txtLocal, corSpeed, txtSpeed
    )
end

-- Teleporte

local function parar()
    if connRun then connRun:Disconnect(); connRun = nil end
    teleportando = false

    if Humanoid and Humanoid.Parent then
        if walkOriginal then Humanoid.WalkSpeed = walkOriginal end
        if jumpOriginal then
            pcall(function() Humanoid.JumpPower = jumpOriginal end)
            pcall(function() Humanoid.UseJumpPower = true end)
        end
    end

    atualizarStatus()
end

local function iniciar()
    if not alvo then atualizarStatus(); return end
    if teleportando then parar(); return end

    Character = LocalPlayer.Character
    if not Character then return end
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not RootPart then return end

    walkOriginal = Humanoid.WalkSpeed
    jumpOriginal = Humanoid.JumpPower

    Humanoid.WalkSpeed = WalkTemp
    pcall(function()
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = JumpTemp
    end)

    teleportando = true
    atualizarStatus()

    connRun = RunService.Heartbeat:Connect(function(dt)
        if not teleportando then return end
        if not RootPart or not RootPart.Parent or not Humanoid or Humanoid.Health <= 0 then
            parar(); return
        end

        local origem = RootPart.Position
        local delta  = alvo - origem

        if IgnorarY then
            delta = Vector3.new(delta.X, 0, delta.Z)
        end

        local dist = delta.Magnitude

        if dist <= DistanciaChegada then
            RootPart.CFrame = CFrame.new(alvo) * (RootPart.CFrame - RootPart.Position)
            parar(); return
        end

        local passo = math.min(VelocidadeRun * dt, dist)
        local direcao = delta.Unit
        local novaPos = origem + direcao * passo

        RootPart.CFrame = CFrame.lookAt(novaPos, novaPos + direcao)
    end)
end

-- Conexões da interface

botao.Activated:Connect(function()
    if foiArrastado() then return end
    painel.Visible = not painel.Visible
end)

botaoFechar.Activated:Connect(function()
    painel.Visible = false
end)

btnLocal.Activated:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    alvo = root.Position
    atualizarStatus()
end)

btnSpeed.Activated:Connect(function()
    iniciar()
end)

-- Respawn

LocalPlayer.CharacterAdded:Connect(function(char)
    if teleportando then parar() end
    task.wait(1)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    walkOriginal = nil
    jumpOriginal = nil
    atualizarStatus()
end)

atualizarStatus()
