-- ManniskaBABFT Autofarm Script for Build A Boat For Treasure (BABFT)
-- Features:
-- 1. Automatic teleport to the end chest / gold claim
-- 2. Anti-AFK protection
-- 3. Loop / Auto-farm mode with delay for replay
-- 4. Simple UI or toggle controls using standard Roblox exploiting functions (task.wait, firetouchinterest, etc.)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("[ManniskaBABFT] Loaded Anti-AFK & Autofarm base script.")

-- Function to get character root part
local function getRootPart()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end
    return nil
end

-- BABFT End Chest coordinates / End stage locator
-- In Build A Boat, the end gold chest is located around Z = 9550 (approximate depending on stage generation, or we can locate the chest model directly)
local function findEndChest()
    -- Look for the end chest or gold block in Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "GoldenChest" or obj.Name == "Chest" or (obj:IsA("Model") and obj.Name:lower():find("chest")) then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return part
            end
        end
    end
    
    -- Fallback default position if chest isn't streamed yet (End of map is roughly Z = 9550)
    return nil
end

-- Main Autofarm loop
local function autoFarm()
    while true do
        task.wait(1)
        
        local rootPart = getRootPart()
        local character = LocalPlayer.Character
        if rootPart and character and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0 then
            
            print("[ManniskaBABFT] Traversing stages sequentially to satisfy game validation checks...")
            
            -- BABFT validates stage progression by touching stage wall/checkpoints sequentially.
            -- We step through the map along the Z axis from spawn (Z = 0) to the end chest (Z ≈ 9550).
            for z = 0, 9500, 400 do
                if rootPart and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0 then
                    rootPart.CFrame = CFrame.new(0, 50, z)
                    task.wait(0.1)
                end
            end
            
            -- Arrive at the end chest
            local targetPos = Vector3.new(0, 300, 9550)
            local chestPart = findEndChest()
            if chestPart then
                targetPos = chestPart.Position + Vector3.new(0, 5, 0)
            end
            
            rootPart.CFrame = CFrame.new(targetPos)
            
            -- Hold at chest and fire touch interest to claim gold
            local startTime = tick()
            while tick() - startTime < 4 do
                if getRootPart() then
                    getRootPart().CFrame = CFrame.new(targetPos)
                    if chestPart then
                        pcall(function()
                            firetouchinterest(getRootPart(), chestPart, 0)
                            firetouchinterest(getRootPart(), chestPart, 1)
                        end)
                    end
                end
                task.wait(0.2)
            end
            
            print("[ManniskaBABFT] Gold claimed! Waiting for round reset...")
            task.wait(10)
        end
    end
end

-- Start auto farm in a separate coroutine
task.spawn(function()
    pcall(autoFarm)
end)
