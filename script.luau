-- =====================================================================
--  MANNISKABABFT - BUILD A BOAT FOR TREASURE AUTOFARM SUITE
-- =====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Anti-AFK Setup
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- UI Setup (Safely parenting to PlayerGui or CoreGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ManniskaBABFTGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success or not screenGui.Parent then
    pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

-- Main Window Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Manniska BABFT Autofarm"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
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
statusLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 85)
toggleButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Start Autofarm [OFF]"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- Autofarm State & Logic
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

-- Autofarm thread
task.spawn(function()
    while true do
        if autofarmActive then
            statusLabel.Text = "Status: Traversing stages..."
            
            local rootPart = getRootPart()
            local character = LocalPlayer.Character
            
            if rootPart and character and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0 then
                
                -- Step through checkpoints along Z-axis (from 0 to 9400) to satisfy stage validation
                for z = 0, 9400, 350 do
                    if not autofarmActive then break end
                    local rp = getRootPart()
                    if rp then
                        rp.CFrame = CFrame.new(0, 30, z)
                    end
                    task.wait(0.2)
                end
                
                statusLabel.Text = "Status: Claiming chest..."
                
                -- Arrive at end chest
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

-- Button Toggle Event
toggleButton.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    if autofarmActive then
        toggleButton.Text = "Stop Autofarm [ON]"
        toggleButton.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    else
        toggleButton.Text = "Start Autofarm [OFF]"
        toggleButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    end
end)

print("[ManniskaBABFT] Loaded successfully!")
