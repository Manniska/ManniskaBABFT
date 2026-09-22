-- =====================================================================
--  MANNISKABABFT - BUILD A BOAT FOR TREASURE AUTOFARM SUITE V2
-- =====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer

-- Anti-AFK Setup
localPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Safe GUI Parent Setup
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ManniskaBABFTGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Window Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(42, 50, 70)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Title Bar
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
titleLabel.BorderSizePixel = 0
titleLabel.Text = " Manniska BABFT Autofarm"
titleLabel.TextColor3 = Color3.fromRGB(245, 246, 250)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 30)
statusLabel.Position = UDim2.new(0, 15, 0, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(140, 148, 170)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -30, 0, 45)
toggleButton.Position = UDim2.new(0, 15, 0, 95)
toggleButton.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Autofarm: OFF"
toggleButton.TextColor3 = Color3.fromRGB(245, 246, 250)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(46, 204, 113)
btnStroke.Thickness = 1
btnStroke.Parent = toggleButton

-- Autofarm State & Logic
local autofarmActive = false

local function getCharacter()
    local char = localPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if root then
            return char, root, char.Humanoid
        end
    end
    return nil, nil, nil
end

local function findEndChest()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "GoldenChest" or obj.Name == "Chest" or (obj:IsA("Model") and obj.Name:lower():find("chest")) then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return part
            end
        end
    end
    return nil
end

-- Kinematic navigation / stage traversal inspired by robust movement loops
local function navigateToPoint(targetCFrame, speed)
    local char, root, humanoid = getCharacter()
    if not root then return end
    
    speed = speed or 300
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / speed
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    return tween
end

-- Find all actual stage checkpoint parts in Workspace by searching for DarknessPart or stage components
local function getStageCheckpoints()
    local checkpoints = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            -- BABFT stage transition walls are named DarknessPart
            if name == "DarknessPart" or name:lower():find("darknesspart") then
                table.insert(checkpoints, obj)
            end
        end
    end
    
    -- Sort checkpoints in order along the Z axis from start to end
    table.sort(checkpoints, function(a, b)
        return a.Position.Z < b.Position.Z
    end)
    
    return checkpoints
end

-- Autofarm main coroutine
task.spawn(function()
    while true do
        if autofarmActive then
            statusLabel.Text = "Status: Traversing stage checkpoints..."
            
            local char, root, humanoid = getCharacter()
            if root and humanoid then
                -- Anti-gravity / anti-fall lock
                local connection
                connection = RunService.Stepped:Connect(function()
                    local _, r = getCharacter()
                    if r and autofarmActive then
                        r.Velocity = Vector3.new(0, 0, 0)
                        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        if r.Position.Y < 35 then
                            r.CFrame = CFrame.new(r.Position.X, 40, r.Position.Z)
                        end
                    else
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end)
                
                -- Collect all actual stage checkpoints in the game
                local checkpoints = getStageCheckpoints()
                
                if #checkpoints > 0 then
                    statusLabel.Text = "Status: Touching " .. #checkpoints .. " checkpoints..."
                    for _, cp in ipairs(checkpoints) do
                        if not autofarmActive then break end
                        local _, r = getCharacter()
                        if r then
                            -- Teleport directly onto/through each checkpoint wall
                            r.CFrame = cp.CFrame + Vector3.new(0, 2, 0)
                            pcall(function()
                                firetouchinterest(r, cp, 0)
                                firetouchinterest(r, cp, 1)
                            end)
                        end
                        task.wait(0.25) -- Small delay to ensure stage reward/gold registers
                    end
                else
                    -- Fallback: Step through Z coordinates incrementally if checkpoints aren't indexed yet
                    for z = 0, 9400, 300 do
                        if not autofarmActive then break end
                        local _, r = getCharacter()
                        if r then
                            r.CFrame = CFrame.new(0, 40, z)
                        end
                        task.wait(0.2)
                    end
                end
                
                statusLabel.Text = "Status: Reaching end chest..."
                
                -- Find and move to end chest
                local targetPos = Vector3.new(0, 300, 9550)
                local chestPart = findEndChest()
                if chestPart then
                    targetPos = chestPart.Position + Vector3.new(0, 5, 0)
                end
                
                local startTime = tick()
                while autofarmActive and tick() - startTime < 6 do
                    local _, r = getCharacter()
                    if r then
                        r.CFrame = CFrame.new(targetPos)
                        r.Velocity = Vector3.new(0, 0, 0)
                        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        if chestPart then
                            pcall(function()
                                firetouchinterest(r, chestPart, 0)
                                firetouchinterest(r, chestPart, 1)
                            end)
                        end
                    end
                    task.wait(0.2)
                end
                
                if connection then
                    connection:Disconnect()
                end
                
                statusLabel.Text = "Status: Waiting for round reset..."
                
                local waitStart = tick()
                while autofarmActive and tick() - waitStart < 12 do
                    task.wait(0.5)
                end
            else
                statusLabel.Text = "Status: Waiting for character spawn..."
                task.wait(1)
            end
        else
            statusLabel.Text = "Status: Idle"
            task.wait(0.5)
        end
    end
end)

-- Toggle Button Interaction
toggleButton.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    if autofarmActive then
        toggleButton.Text = "Autofarm: ON"
        btnStroke.Color = Color3.fromRGB(240, 70, 70)
        statusLabel.Text = "Status: Starting..."
    else
        toggleButton.Text = "Autofarm: OFF"
        btnStroke.Color = Color3.fromRGB(46, 204, 113)
        statusLabel.Text = "Status: Paused"
    end
end)

print("[ManniskaBABFT] Professional Suite v2 Loaded successfully!")
