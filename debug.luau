-- =====================================================================
--  MANNISKABABFT - USEFUL SCRIPT & REMOTE SCANNER (FILE EXPORTER)
-- =====================================================================
-- Run this in your executor. It scans ReplicatedStorage, Players, and Workspace
-- for Scripts and Remotes, prints them, and saves the output to a text file!

print("==================================================")
print("  MANNISKABABFT SCRIPT & REMOTE SCANNER STARTED   ")
print("==================================================")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local foundScripts = 0
local foundRemotes = 0
local outputLines = {}

table.insert(outputLines, "==================================================")
table.insert(outputLines, "  MANNISKABABFT SCRIPT & REMOTE SCANNER REPORT  ")
table.insert(outputLines, "==================================================")

local function scanContainer(container)
    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                foundScripts = foundScripts + 1
                local info = string.format("[SCRIPT] Name: %s | Type: %s | Path: %s", obj.Name, obj.ClassName, obj:GetFullName())
                print(info)
                table.insert(outputLines, info)
            elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                foundRemotes = foundRemotes + 1
                local info = string.format("[REMOTE] Name: %s | Type: %s | Path: %s", obj.Name, obj.ClassName, obj:GetFullName())
                print(info)
                table.insert(outputLines, info)
            end
        end
    end)
end

table.insert(outputLines, "\n--- Scanning ReplicatedStorage ---")
scanContainer(ReplicatedStorage)

table.insert(outputLines, "\n--- Scanning Players.LocalPlayer ---")
if Players.LocalPlayer then
    scanContainer(Players.LocalPlayer)
end

table.insert(outputLines, "\n--- Scanning Workspace ---")
scanContainer(Workspace)

local summary = string.format("\n=== SUMMARY === Found %d Scripts & %d Remotes", foundScripts, foundRemotes)
print(summary)
table.insert(outputLines, summary)

-- Save to a text file using standard executor paths
pcall(function()
    if writefile then
        local filename = "ManniskaBABFT_ScanReport.txt"
        writefile(filename, table.concat(outputLines, "\n"))
        print("[SUCCESS] Report saved! Check your executor's workspace folder.")
        
        -- Also try absolute path if supported or print workspace notification
        if makefolder then
            pcall(function() makefolder("ManniskaReports") end)
            writefile("ManniskaReports/ScanReport.txt", table.concat(outputLines, "\n"))
            print("[SUCCESS] Also saved to 'ManniskaReports/ScanReport.txt'!")
        end
    else
        print("[NOTICE] writefile function not available in your executor. Please copy from console output.")
    end
end)
