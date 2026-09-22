-- =====================================================================
--  MANNISKABABFT - USEFUL SCRIPT & REMOTE SCANNER
-- =====================================================================
-- Run this script in your executor console to scan the game for useful
-- LocalScripts, ModuleScripts, RemoteEvents, and RemoteFunctions.

print("==================================================")
print("  MANNISKABABFT SCRIPT & REMOTE SCANNER STARTED   ")
print("==================================================")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local foundScripts = 0
local foundRemotes = 0

-- Function to inspect service/container
local function scanContainer(container)
    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                foundScripts = foundScripts + 1
                print(string.format("[SCRIPT] Name: %s | Type: %s | Path: %s", obj.Name, obj.ClassName, obj:GetFullName()))
            elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                foundRemotes = foundRemotes + 1
                print(string.format("[REMOTE] Name: %s | Type: %s | Path: %s", obj.Name, obj.ClassName, obj:GetFullName()))
            end
        end
    end)
end

print("\n--- Scanning ReplicatedStorage ---")
scanContainer(ReplicatedStorage)

print("\n--- Scanning Players.LocalPlayer ---")
if Players.LocalPlayer then
    scanContainer(Players.LocalPlayer)
end

print("\n--- Scanning Workspace ---")
scanContainer(Workspace)

print("\n==================================================")
print(string.format("  SCAN COMPLETE: Found %d Scripts & %d Remotes", foundScripts, foundRemotes))
print("==================================================")
