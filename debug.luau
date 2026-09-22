-- =====================================================================
--  MANNISKABABFT - DEBUG INSPECTOR SCRIPT
-- =====================================================================
-- Run this script in your executor console to inspect all relevant parts,
-- stage checkpoints, models, and chest names in Build A Boat For Treasure.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("========================================")
print("  MANNISKABABFT DEBUG INSPECTOR STARTED  ")
print("========================================")

-- 1. Inspect Workspace Descendants for Stages / Checkpoints / Chests
local foundStages = 0
local foundChests = 0

for _, obj in ipairs(Workspace:GetDescendants()) do
    local nameLower = obj.Name:lower()
    
    -- Check for Chests
    if nameLower:find("chest") or nameLower:find("gold") then
        foundChests = foundChests + 1
        print(string.format("[CHEST/GOLD] Name: %s | Class: %s | Path: %s", obj.Name, obj.ClassName, obj:GetFullName()))
    end
    
    -- Check for Stages or Checkpoints
    if nameLower:find("stage") or nameLower:find("checkpoint") or nameLower:find("wall") or nameLower:find("part") then
        if obj:IsA("BasePart") then
            -- Only print parts within stage zones (Z > 0 and Z < 9600)
            local pos = obj.Position
            if pos.Z > 0 and pos.Z < 9600 and obj.Size.Magnitude > 10 then
                foundStages = foundStages + 1
                -- Print every 10th or specific items to avoid spamming console
                if foundStages <= 30 then
                    print(string.format("[STAGE PART] Name: %s | Size: (%.1f, %.1f, %.1f) | Pos: (%.1f, %.1f, %.1f)", 
                        obj.Name, obj.Size.X, obj.Size.Y, obj.Size.Z, pos.X, pos.Y, pos.Z))
                end
            end
        end
    end
end

print(string.format("=== SUMMARY === Total Chests: %d | Total Stage Parts logged: %d", foundChests, foundStages))

-- 2. Inspect Character Position & State
local char = LocalPlayer.Character
if char then
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if root then
        print(string.format("[PLAYER] Position: (%.1f, %.1f, %.1f)", root.Position.X, root.Position.Y, root.Position.Z))
    end
else
    print("[PLAYER] Character not found.")
end

print("========================================")
print("  DEBUG INSPECTOR COMPLETED             ")
print("========================================")
