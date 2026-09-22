-- =====================================================================
--  MANNISKABABFT - INTERACTIVE CLICK INSPECTOR DEBUG SCRIPT
-- =====================================================================
-- Run this in your executor. Click/tap any part in the game world 
-- to instantly print its Name, Class, Parent, Size, Position, and FullPath to the console!

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("==================================================")
print("  MANNISKABABFT CLICK INSPECTOR ACTIVATED         ")
print("  Click any part in the game world to inspect it! ")
print("==================================================")

local active = true

-- Listen for mouse / touch click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not active then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mouseLocation = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        
        if LocalPlayer.Character then
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        end
        
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        
        if result and result.Instance then
            local part = result.Instance
            print("--------------------------------------------------")
            print("[INSPECTED PART CLICKED]")
            print("  Name     : " .. tostring(part.Name))
            print("  Class    : " .. tostring(part.ClassName))
            print("  Parent   : " .. tostring(part.Parent and part.Parent.Name or "None"))
            print("  Position : " .. tostring(part.Position))
            print("  Size     : " .. tostring(part.Size))
            print("  FullName : " .. tostring(part:GetFullName()))
            print("--------------------------------------------------")
        end
    end
end)
