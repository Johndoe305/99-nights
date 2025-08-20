-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Referência ao HRP
local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")

-- Controle do loop
local loopActive = false
local processedLogs = {}
local speed = 0.5   -- valor inicial do slider (0.01–1)
local maxLogs = 10  -- valor inicial do slider (1–99)

-- GUI principal
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "LogCollectorGui"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 270, 0, 250)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0

-- Título (arrastável)
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "📦 Log Collector"
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BorderSizePixel = 0

-- Drag só pelo título
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Botão ativar/desativar
local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, -20, 0, 35)
button.Position = UDim2.new(0, 10, 0, 35)
button.Text = "Ativar Script"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
button.BorderSizePixel = 0

---------------- SLIDER FUNÇÃO ----------------
local function createSlider(parent, yPos, minVal, maxVal, defaultVal, textLabel, callback)
    local sliderFrame = Instance.new("Frame", parent)
    sliderFrame.Size = UDim2.new(1, -20, 0, 40)
    sliderFrame.Position = UDim2.new(0, 10, 0, yPos)
    sliderFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", sliderFrame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Text = textLabel .. ": " .. tostring(defaultVal)

    local bar = Instance.new("Frame", sliderFrame)
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 25)
    bar.BackgroundColor3 = Color3.fromRGB(100,100,100)

    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0, 10, 1, 0)
    knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
    knob.BorderSizePixel = 0
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal), -5, 0, 0)

    local draggingSlider = false

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            knob.Position = UDim2.new(relativeX, -5, 0, 0)
            local val = math.floor((minVal + (maxVal-minVal)*relativeX)*100)/100
            label.Text = textLabel .. ": " .. tostring(val)
            callback(val)
        end
    end)
end

-- Slider de velocidade
createSlider(frame, 80, 0.01, 1, speed, "Velocidade", function(val)
    speed = val
end)

-- Slider de quantidade de logs
createSlider(frame, 130, 1, 99, maxLogs, "Qtd Logs", function(val)
    maxLogs = math.floor(val)
end)

---------------- SCRIPT PRINCIPAL ----------------
local function monitorDroppedLogs()
    local inventory = player:WaitForChild("Inventory"):WaitForChild("Old Sack")
    local itemBag = player:WaitForChild("ItemBag")
    local originalPos = hrp.Position

    while loopActive do
        local pickedItems = {}

        for _, item in pairs(Workspace.Items:GetChildren()) do
            if not loopActive then break end
            if item.Name == "Log" and not processedLogs[item] then
                processedLogs[item] = true

                if item:FindFirstChild("Main") then
                    hrp.CFrame = CFrame.new(item.Main.Position + Vector3.new(0,3,0))
                else
                    hrp.CFrame = CFrame.new(item:GetModelCFrame().Position + Vector3.new(0,3,0))
                end

                task.wait(speed)

                local args = {inventory, item}
                local pickedItem = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))
                table.insert(pickedItems, pickedItem)

                if #pickedItems >= maxLogs then
                    break
                end
            end
        end

        if #pickedItems > 0 then
            hrp.CFrame = CFrame.new(originalPos)
            task.wait(speed)

            for _, logItem in ipairs(pickedItems) do
                local dropArgs = {inventory, logItem}
                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(dropArgs))
                task.wait(speed)
            end

            repeat task.wait(0.5) until #itemBag:GetChildren() == 0
        end

        task.wait(0.5)
    end
end

-- Conecta o botão
button.MouseButton1Click:Connect(function()
    loopActive = not loopActive
    if loopActive then
        button.Text = "Desativar Script"
        button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        task.spawn(monitorDroppedLogs)
    else
        button.Text = "Ativar Script"
        button.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
    end
end)
