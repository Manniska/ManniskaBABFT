-- =====================================================================
--  MANNISKABABFT - BUILD A BOAT FOR TREASURE AUTOFARM SUITE V2
-- =====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

-- =====================================================================
--  REMOTE INTEGRATION (From Scan Report)
-- =====================================================================
local inputLocalScript = ReplicatedStorage:WaitForChild("InputLocalScript")
local queueBlocksRequest = inputLocalScript:WaitForChild("QueueBlocksRequest")
local getSynchronizeInfo = inputLocalScript:WaitForChild("getSynchronizeInfo")

-- Synchronize with server using the game's own sync mechanism
local function syncWithServer()    
    pcall(function()
        local syncData = getSynchronizeInfo:InvokeServer()
        if syncData then
            -- Queue movement/input block to ensure server processes our position
            queueBlocksRequest:FireServer(syncData)
        end
    end)
end

-- Send periodic heartbeat to server (optimized - every 100ms instead of every frame)
local heartbeatConnection
local heartbeatTimer = 0
local function startHeartbeat()
    heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if autofarmActive then
            heartbeatTimer = heartbeatTimer + deltaTime
            if heartbeatTimer >= 0.1 then
                heartbeatTimer = 0
                pcall(function()
                    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    queueBlocksRequest:FireServer({
                        Type = "Heartbeat",
                        Timestamp = tick(),
                        Position = root and root.Position or Vector3.new()
                    })
                end)
            end
        end
    end)
end

local function stopHeartbeat()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

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

-- =====================================================================
--  QUEST AUTO-COMPLETE SYSTEM
-- =====================================================================
local QuestConditions = ReplicatedStorage.Scripts:FindFirstChild("QuestConditions")
local ChallengeConditions = ReplicatedStorage.Scripts:FindFirstChild("ChallengeConditions")

-- Find quest UI elements
local function findQuestUI()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil, nil end
    
    local shopGui = playerGui:FindFirstChild("ShopGui")
    if not shopGui then return nil, nil, nil end
    
    local mainFrame = shopGui:FindFirstChild("MainFrame")
    if not mainFrame then return nil, nil, nil end
    
    local tabFrame = mainFrame:FindFirstChild("TabFrame")
    if not tabFrame then return nil, nil, nil end
    
    local questFrame = tabFrame:FindFirstChild("QuestFrame")
    if not questFrame then return nil, nil, nil end
    
    local scrollingFrame = questFrame:FindFirstChild("ScrollingFrame")
    local selectedFrame = questFrame:FindFirstChild("SelectedFrame")
    
    return shopGui, questFrame, scrollingFrame, selectedFrame
end

-- Find quest objectives (like "touch the cloud", "touch the target")
local function findQuestObjectives()
    local objectives = {}
    
    -- Look for touch parts in the game world that might be quest objectives
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        -- Common quest objective names
        if name:find("cloud") or name:find("target") or name:find("checkpoint") or 
           name:find("flag") or name:find("finish") or name:find("goal") then
            if obj:IsA("BasePart") then
                table.insert(objectives, obj)
            end
        end
    end
    
    return objectives
end

-- Complete a quest objective by touching the required part
local function completeQuestObjective(objective)
    if not objective then return false end
    
    local _, root = getCharacter()
    if not root then return false end
    
    -- Move to the objective
    root.CFrame = CFrame.new(objective.Position.X, objective.Position.Y + 2, objective.Position.Z)
    
    -- Fire touch interest
    pcall(function()
        firetouchinterest(root, objective, 0)
        firetouchinterest(root, objective, 1)
    end)
    
    task.wait(0.3)
    return true
end

-- Auto complete quests
local function autoCompleteQuests()
    statusLabel.Text = "Status: Checking quests..."
    
    local shopGui, questFrame, scrollingFrame, selectedFrame = findQuestUI()
    if not shopGui or not selectedFrame then
        statusLabel.Text = "Status: No quest UI found, skipping..."
        return
    end
    
    -- Try to activate and complete available quests
    pcall(function()
        -- Check if there's an active quest to complete
        local buyButton = selectedFrame:FindFirstChild("BuyButton")
        
        if buyButton then
            local buttonName = buyButton.Text:lower()
            
            -- If button says "Start" or "Activate", start the quest
            if buttonName:find("start") or buttonName:find("activate") then
                statusLabel.Text = "Status: Starting quest..."
                pcall(function()
                    buyButton.MouseButton1Click:Fire()
                end)
                task.wait(1)
            -- If button says "Claim" or "Complete", claim the reward
            elseif buttonName:find("claim") or buttonName:find("complete") then
                statusLabel.Text = "Status: Claiming quest reward..."
                pcall(function()
                    buyButton.MouseButton1Click:Fire()
                end)
                task.wait(0.5)
                statusLabel.Text = "Status: Quest claimed!"
            end
        end
        
        -- Look for quest objectives in the world
        local objectives = findQuestObjectives()
        if #objectives > 0 then
            statusLabel.Text = "Status: Completing quest objectives..."
            for _, obj in ipairs(objectives) do
                if not autofarmActive then break end
                if completeQuestObjective(obj) then
                    statusLabel.Text = "Status: Objective completed!"
                    task.wait(0.5)
                end
            end
        end
    end)
    
    task.wait(1) -- Wait for quest UI to update
end

-- Find all actual stage checkpoint parts in Workspace by checking for DarknessPart inside CaveStage folders
local function getStageCheckpoints()
    local checkpoints = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "DarknessPart" then
            local parent = obj.Parent
            if parent and parent.Name:lower():find("cavestage") then
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

-- Fast stage traversal with essential sync only
local function traverseCheckpoints()
    local checkpoints = getStageCheckpoints()
    
    statusLabel.Text = "Status: Traversing stages..."
    
    local currentZ = 0
    while currentZ <= 9400 and autofarmActive do
        local _, r = getCharacter()
        if r then
            -- Direct teleport to checkpoint position
            r.CFrame = CFrame.new(0, 40, currentZ)
            
            -- Fire touch interest on nearby DarknessPart
            for _, cp in ipairs(checkpoints) do
                if cp and cp.Parent and math.abs(cp.Position.Z - currentZ) < 50 then
                    pcall(function()
                        firetouchinterest(r, cp, 0)
                        firetouchinterest(r, cp, 1)
                    end)
                end
            end
            
            -- Minimal sync call
            pcall(syncWithServer)
            
            task.wait(0.05) -- Very fast traversal
        end
        currentZ = currentZ + 100 -- Faster coverage
    end
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
                    else
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end)
                
                -- Collect all actual stage checkpoints (DarknessPart inside CaveStage)
                traverseCheckpoints()
                
                statusLabel.Text = "Status: Reaching end chest..."
                
                -- Find and move to end chest firmly without bouncing
                local targetPos = Vector3.new(0, 50, 9550)
                local chestPart = findEndChest()
                if chestPart then
                    targetPos = chestPart.Position + Vector3.new(0, 2, 0)
                end
                
                local startTime = tick()
                while autofarmActive and tick() - startTime < 4 do
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
                        -- Minimal sync
                        pcall(syncWithServer)
                    end
                    task.wait(0.1) -- Faster chest claim
                end
                
                if connection then
                    connection:Disconnect()
                end
                
                -- Auto-complete quests if available
                autoCompleteQuests()
                
                statusLabel.Text = "Status: Waiting for character reset..."
                
                -- Fast respawn wait
                local resetStart = tick()
                while autofarmActive and tick() - resetStart < 12 do
                    local char, root, hum = getCharacter()
                    if not char or not root or not hum or hum.Health <= 0 then
                        task.wait(1) -- Fast respawn wait
                        break
                    end
                    task.wait(0.2) -- Fast respawn check
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
        startHeartbeat()
    else
        toggleButton.Text = "Autofarm: OFF"
        btnStroke.Color = Color3.fromRGB(46, 204, 113)
        statusLabel.Text = "Status: Paused"
        stopHeartbeat()
    end
end)

print("[ManniskaBABFT] Professional Suite v2 Loaded successfully!")
