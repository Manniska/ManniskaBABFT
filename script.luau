-- ManniskaBABFT Autofarm Script for Build A Boat For Treasure (BABFT)
-- Features:
-- 1. Clean Toggleable UI (GUI) with Status Display
-- 2. Stage-by-stage progression loop (passes through all stages/checkpoints to satisfy game validation)
-- 3. Automatic End Chest teleport & gold claim
-- 4. Anti-AFK protection

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ManniskaBABFTGui"
screenGui.ResetOnSpawn = false

-- Try parent to CoreGui, fallback to PlayerGui
local success, err = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success or not screenGui.Parent then
    pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Manniska BABFT Autofarm"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 85)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Start Autofarm [OFF]"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- Autofarm Logic State
local autofarmActive = false

local function getRootPart()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end
    return nil
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

-- Reliable stage checkpoint traversal by collecting actual Stage/Checkpoint parts in order
local function getStages()
    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            -- BABFT stage parts typically contain stage numbers or are named stage parts / team blocks
            if name:find("stage") or name:find("checkpoint") or (obj.Position.Z > 10 and obj.Position.Z < 9400 and obj.Size.Z > 5 and obj.Size.Magnitude > 10) then
                table.insert(stages, obj)
            end
        end
    end

    -- Sort unique stages along the Z axis from start to end
    table.sort(stages, function(a, b)
        return a.Position.Z < b.Position.Z
    end)

    return stages
end

-- Main loop task
task.spawn(function()
    while true do
        if autofarmActive then
            statusLabel.Text = "Status: Running run..."

            local rootPart = getRootPart()
            local character = LocalPlayer.Character

            if rootPart and character and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0 then
                -- Step 1: Traverse stages reliably
                -- Let's find stage folders or parts in workspace. Stages in BABFT are spaced out every ~400-500 studs.
                statusLabel.Text = "Status: Traversing stages..."

                -- We can teleport through key Z checkpoints from 0 to 9400
                for z = 0, 9400, 350 do
                    if not autofarmActive then break end
                    local rp = getRootPart()
                    if rp then
                        rp.CFrame = CFrame.new(0, 30, z)
                    end
                    task.wait(0.2)
                end

                statusLabel.Text = "Status: Reaching end chest..."

                -- Step 2: Arrive at end chest and claim gold
                local targetPos = Vector3.new(0, 300, 9550)
                local chestPart = findEndChest()
                if chestPart then
                    targetPos = chestPart.Position + Vector3.new(0, 5, 0)
                end

                local startTime = tick()
                while autofarmActive and tick() - startTime < 5 do
                    local rp = getRootPart()
                    if rp then
                        rp.CFrame = CFrame.new(targetPos)
                        if chestPart then
                            pcall(function()
                                firetouchinterest(rp, chestPart, 0)
                                firetouchinterest(rp, chestPart, 1)
                            end)
                        end
                    end
                    task.wait(0.2)
                end

                statusLabel.Text = "Status: Waiting for round reset..."

                -- Wait for round restart / respawn
                local waitStart = tick()
                while autofarmActive and tick() - waitStart < 12 do
                    task.wait(0.5)
                end
            else
                statusLabel.Text = "Status: Waiting for character..."
                task.wait(1)
            end
        else
            statusLabel.Text = "Status: Idle (Paused)"
            task.wait(0.5)
        end
    end
end)

-- Toggle Button Event
toggleButton.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    if autofarmActive then
        toggleButton.Text = "Stop Autofarm [ON]"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    else
        toggleButton.Text = "Start Autofarm [OFF]"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    end
end)

print("[ManniskaBABFT] Script loaded with GUI successfully.")
