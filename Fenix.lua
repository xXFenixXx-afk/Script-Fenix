-- Elerium v2 UI Library Implementation
local library = loadstring(game:HttpGet("https://github.com/xXFenixXx-afk/Script-Fenix/blob/main/Biblioteca", true))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local startTime = os.time()
local startRebirths = player.leaderstats.Rebirths.Value
local displayName = player.DisplayName

-- Anti-AFK System
local VirtualUser = game:GetService("VirtualUser")
local antiAFKConnection

local function setupAntiAFK()
    -- Disconnect previous connection if it exists
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
    end
    
    -- Connect to PlayerIdleEvent to prevent AFK kicks
    antiAFKConnection = player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK")
    end)
    
    print("Anti-AFK Activado")
end

-- Initialize Anti-AFK system
setupAntiAFK()

-- Create Main Window
local window = library:AddWindow("Private Script", {
    main_color = Color3.fromRGB(19, 112, 103),
    min_size = Vector2.new(800, 900),
    can_resize = true,
})

-- Main Tab
local mainTab = window:AddTab("Menu")
local farmPlusTab = window:AddTab("Farmeo")
mainTab:Show() -- Show this tab by default

mainTab:AddLabel("Fenix Script")

-- Add Anti-AFK toggle
local antiAFKEnabled = true
mainTab:AddSwitch("Anti-AFK System", function(bool)
    antiAFKEnabled = bool
    
    if bool then
        setupAntiAFK()
    else
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
            print("Anti-AFK system disabled")
        end
    end
end, true) -- Default to enabled

-- Auto Brawls Folder
local autoBrawlsFolder = mainTab:AddFolder("Auto Peleas")

-- Variables
local Players = game:GetService("Players")
local whitelist = {} -- Add any whitelisted player IDs here

-- Auto Win Brawl Toggle
local autoWinBrawlSwitch = autoBrawlsFolder:AddSwitch("Ganar Peleas", function(bool)
    getgenv().autoWinBrawl = bool
    
    -- Equip Punch Tool function - will be called repeatedly
    local function equipPunch()
        if not getgenv().autoWinBrawl then return end
        
        local character = game.Players.LocalPlayer.Character
        if not character then return false end
        
        -- Check if already equipped
        if character:FindFirstChild("Punch") then return true end
        
        -- Try to equip from backpack
        local backpack = game.Players.LocalPlayer.Backpack
        if not backpack then return false end
        
        for _, tool in pairs(backpack:GetChildren()) do
            if tool.ClassName == "Tool" and tool.Name == "Punch" then
                tool.Parent = character
                return true
            end
        end
        return false
    end
    
    -- Safe player check function
    local function isValidTarget(player)
        if not player or not player.Parent then return false end
        if player == Players.LocalPlayer then return false end
        if whitelist[player.UserId] then return false end
        
        local character = player.Character
        if not character or not character.Parent then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return false end
        
        -- Multiple health checks to be absolutely certain
        if not humanoid.Health or humanoid.Health <= 0 then return false end
        if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not rootPart.Parent then return false end
        
        return true
    end
    
    -- Safe local player check function
    local function isLocalPlayerReady()
        local player = game.Players.LocalPlayer
        if not player then return false end
        
        local character = player.Character
        if not character or not character.Parent then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        
        local leftHand = character:FindFirstChild("LeftHand")
        local rightHand = character:FindFirstChild("RightHand")
        
        return (leftHand ~= nil or rightHand ~= nil)
    end
    
    -- Safe firetouchinterest function
    local function safeTouchInterest(targetPart, localPart)
        if not targetPart or not targetPart.Parent then return false end
        if not localPart or not localPart.Parent then return false end
        
        local success, err = pcall(function()
            firetouchinterest(targetPart, localPart, 0)
            task.wait(0.01)
            firetouchinterest(targetPart, localPart, 1)
        end)
        
        return success
    end
    
    -- Join Brawl Loop
    task.spawn(function()
        while getgenv().autoWinBrawl and task.wait(0.5) do
            if not getgenv().autoWinBrawl then break end
            
            if game.Players.LocalPlayer.PlayerGui.gameGui.brawlJoinLabel.Visible then
                game.ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl")
                game.Players.LocalPlayer.PlayerGui.gameGui.brawlJoinLabel.Visible = false
            end
        end
    end)
    
    -- Equipment loop - keeps trying to equip the punch
    task.spawn(function()
        while getgenv().autoWinBrawl and task.wait(0.5) do
            if not getgenv().autoWinBrawl then break end
            equipPunch()
        end
    end)
    
    -- Auto Punch Loop - keeps punching
    task.spawn(function()
        while getgenv().autoWinBrawl and task.wait(0.1) do
            if not getgenv().autoWinBrawl then break end
            
            if isLocalPlayerReady() and game.ReplicatedStorage.brawlInProgress.Value then
                local player = game.Players.LocalPlayer
                pcall(function() player.muscleEvent:FireServer("punch", "rightHand") end)
                pcall(function() player.muscleEvent:FireServer("punch", "leftHand") end)
            end
        end
    end)
    
    -- Main Kill Loop - extremely resilient
    task.spawn(function()
        while getgenv().autoWinBrawl and task.wait(0.05) do
            if not getgenv().autoWinBrawl then break end
            
            -- Only proceed if local player is ready and brawl is in progress
            if isLocalPlayerReady() and game.ReplicatedStorage.brawlInProgress.Value then
                local character = game.Players.LocalPlayer.Character
                local leftHand = character:FindFirstChild("LeftHand")
                local rightHand = character:FindFirstChild("RightHand")
                
                -- Process each player individually with error handling
                for _, player in pairs(Players:GetPlayers()) do
                    -- Skip if toggle was turned off mid-loop
                    if not getgenv().autoWinBrawl then break end
                    
                    -- Use pcall for the entire player processing to prevent any errors from breaking the loop
                    pcall(function()
                        if isValidTarget(player) then
                            local targetRoot = player.Character.HumanoidRootPart
                            
                            -- Try left hand
                            if leftHand then
                                safeTouchInterest(targetRoot, leftHand)
                            end
                            
                            -- Try right hand
                            if rightHand then
                                safeTouchInterest(targetRoot, rightHand)
                            end
                        end
                    end)
                    
                    -- Small delay between players to prevent overwhelming
                    task.wait(0.01)
                end
            end
        end
    end)
    
    -- Recovery system - if the main loop somehow breaks, this will restart it
    task.spawn(function()
        local lastPlayerCount = 0
        local stuckCounter = 0
        
        while getgenv().autoWinBrawl and task.wait(1) do
            if not getgenv().autoWinBrawl then break end
            
            -- Check if we're processing players
            local currentPlayerCount = #Players:GetPlayers()
            
            -- If player count changed but we're not seeing any activity, restart the kill loop
            if currentPlayerCount ~= lastPlayerCount then
                stuckCounter = 0
                lastPlayerCount = currentPlayerCount
            else
                stuckCounter = stuckCounter + 1
                
                -- If we seem stuck for too long, force re-equip the tool
                if stuckCounter > 5 then
                    stuckCounter = 0
                    
                    -- Force re-equip
                    pcall(function()
                        local character = game.Players.LocalPlayer.Character
                        if character and character:FindFirstChild("Punch") then
                            character.Punch.Parent = game.Players.LocalPlayer.Backpack
                            task.wait(0.1)
                            equipPunch()
                        else
                            equipPunch()
                        end
                    end)
                end
            end
        end
    end)
end)

-- Auto Join Brawl Only - FIXED to join only once and properly turn off
autoBrawlsFolder:AddSwitch("Auto Brawls", function(bool)
    getgenv().autoJoinBrawl = bool
    
    task.spawn(function()
        while getgenv().autoJoinBrawl and task.wait(0.5) do
            if not getgenv().autoJoinBrawl then break end
            
            if game.Players.LocalPlayer.PlayerGui.gameGui.brawlJoinLabel.Visible then
                game.ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl")
                -- Set the label to not visible to prevent multiple joins
                game.Players.LocalPlayer.PlayerGui.gameGui.brawlJoinLabel.Visible = false
            end
        end
    end)
end)

local jungleGymFolder = mainTab:AddFolder("Jungle Gym")

-- Cache services for faster access
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Helper functions for Jungle Gym
local function pressE()
    VIM:SendKeyEvent(true, "E", false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, "E", false, game)
end

local function autoLift()
    while getgenv().working do
        LocalPlayer.muscleEvent:FireServer("rep")
        task.wait() -- More efficient than task.wait(0) or task.wait(small number)
    end
end

local function teleportAndStart(machineName, position)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = position
        task.wait(0.1)
        pressE()
        task.spawn(autoLift) -- Use task.spawn to prevent UI freezing
    end
end

-- Jungle Gym Bench Press
jungleGymFolder:AddSwitch("Jungle Bench Press", function(bool)
    if getgenv().working and not bool then
        getgenv().working = false
        return
    end
    
    getgenv().working = bool
    if bool then
        teleportAndStart("Bench Press", CFrame.new(-8173, 64, 1898))
    end
end)

-- Jungle Gym Squat
jungleGymFolder:AddSwitch("Jungle Squat", function(bool)
    if getgenv().working and not bool then
        getgenv().working = false
        return
    end
    
    getgenv().working = bool
    if bool then
        teleportAndStart("Squat", CFrame.new(-8352, 34, 2878))
    end
end)

-- Jungle Gym Pull Up
jungleGymFolder:AddSwitch("Jungle Pull Ups", function(bool)
    if getgenv().working and not bool then
        getgenv().working = false
        return
    end
    
    getgenv().working = bool
    if bool then
        teleportAndStart("Pull Up", CFrame.new(-8666, 34, 2070))
    end
end)

-- Jungle Gym Boulder
jungleGymFolder:AddSwitch("Jungle Boulder", function(bool)
    if getgenv().working and not bool then
        getgenv().working = false
        return
    end
    
    getgenv().working = bool
    if bool then
        teleportAndStart("Boulder", CFrame.new(-8621, 34, 2684))
    end
end)

-- NEW: Farm Gyms Folder
local farmGymsFolder = mainTab:AddFolder("Entrenar Gimnasios")

-- Workout positions data
local workoutPositions = {
    ["Bench Press"] = {
        ["Eternal Gym"] = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        ["Legend Gym"] = CFrame.new(4111.91748, 1020.46674, -3799.97217),
        ["Muscle King Gym"] = CFrame.new(-8590.06152, 46.0167427, -6043.34717)
    },
    ["Squat"] = {
        ["Eternal Gym"] = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        ["Legend Gym"] = CFrame.new(4304.99023, 987.829956, -4124.2334),
        ["Muscle King Gym"] = CFrame.new(-8940.12402, 13.1642084, -5699.13477)
    },
    ["Deadlift"] = {
        ["Eternal Gym"] = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        ["Legend Gym"] = CFrame.new(4304.99023, 987.829956, -4124.2334),
        ["Muscle King Gym"] = CFrame.new(-8940.12402, 13.1642084, -5699.13477)
    },
    ["Pull Up"] = {
        ["Eternal Gym"] = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        ["Legend Gym"] = CFrame.new(4304.99023, 987.829956, -4124.2334),
        ["Muscle King Gym"] = CFrame.new(-8940.12402, 13.1642084, -5699.13477)
    }
}

-- Workout types
local workoutTypes = {
    "Bench Press",
    "Squat",
    "Deadlift",
    "Pull Up"
}

-- Gym locations (only the three requested)
local gymLocations = {
    "Eternal Gym",
    "Legend Gym",
    "Muscle King Gym"
}

-- Spanish translations for workout types
local workoutTranslations = {
    ["Bench Press"] = "Bench Press",
    ["Squat"] = "Squat",
    ["Deadlift"] = "Dead Lift",
    ["Pull Up"] = "Pull Up"
}

-- Store references to toggle objects
local gymToggles = {}

-- Create dropdowns and toggles for each workout type
for _, workoutType in ipairs(workoutTypes) do
    -- Create dropdown for gym selection
    local dropdownName = workoutType .. "GymDropdown"
    local spanishWorkoutName = workoutTranslations[workoutType]
    
    -- Create the dropdown with the correct format
    local dropdown = farmGymsFolder:AddDropdown(spanishWorkoutName .. " - Gimnasio", function(selected)
        _G["selected" .. string.gsub(workoutType, " ", "") .. "Gym"] = selected
    end)
    
    -- Add gym locations to the dropdown
    for _, gymName in ipairs(gymLocations) do
        dropdown:Add(gymName)
    end
    
    -- Create toggle for workout
    local toggleName = workoutType .. "GymToggle"
    local toggle = farmGymsFolder:AddSwitch(spanishWorkoutName, function(bool)
        getgenv().workingGym = bool
        getgenv().currentWorkoutType = workoutType
        
        if bool then
            local selectedGym = _G["selected" .. string.gsub(workoutType, " ", "") .. "Gym"] or gymLocations[1]
            
            -- Make sure we have a valid position
            if workoutPositions[workoutType] and workoutPositions[workoutType][selectedGym] then
                -- Stop any other workout that might be running
                for otherType, otherToggle in pairs(gymToggles) do
                    if otherType ~= workoutType and otherToggle then
                        otherToggle:Set(false)
                    end
                end
                
                -- Start the workout
                teleportAndStart(workoutType, workoutPositions[workoutType][selectedGym])
            else
                -- Notify user if position is not found
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Position not found for " .. workoutType .. " in " .. selectedGym,
                    Duration = 5
                })
            end
        end
    end)
    
    -- Store reference to toggle
    gymToggles[workoutType] = toggle
end

-- OP Things/Farms Folder
local opThingsFolder = mainTab:AddFolder("Menu")

-- Anti Knockback Toggle
opThingsFolder:AddSwitch("Anti Knockback", function(Value)
    if Value then
        local playerName = game.Players.LocalPlayer.Name
        local rootPart = game.Workspace:FindFirstChild(playerName):FindFirstChild("HumanoidRootPart")
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.P = 1250
        bodyVelocity.Parent = rootPart
    else
        local playerName = game.Players.LocalPlayer.Name
        local rootPart = game.Workspace:FindFirstChild(playerName):FindFirstChild("HumanoidRootPart")
        local existingVelocity = rootPart:FindFirstChild("BodyVelocity")
        if existingVelocity and existingVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
            existingVelocity:Destroy()
        end
    end
end)

-- Anti AFK Button
opThingsFolder:AddButton("Anti AFK", function()
    -- Anti AFK implementation
    local GC = getconnections or get_signal_cons
    if GC then
        for i, v in pairs(GC(game.Players.LocalPlayer.Idled)) do
            if v["Disable"] then
                v["Disable"](v)
            elseif v["Disconnect"] then
                v["Disconnect"](v)
            end
        end
    else
        -- Fallback method if getconnections isn't available
        local VirtualUser = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
    
    -- Notify user
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Anti AFK",
        Text = "Anti AFK has been enabled!",
        Duration = 5
    })
    
    -- Additional periodic movement to prevent AFK
    spawn(function()
        while wait(30) do
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

local autoRockFolder = farmPlusTab:AddFolder("Auto Rock")

-- Define the gettool function first
function gettool()
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v.Name == "Punch" and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
        end
    end
    game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
    game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
end

-- Add all rock farming toggles to the Auto Rock folder
autoRockFolder:AddSwitch("Tiny Rock", function(Value)
    selectrock = "Tiny Island Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 0 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 0 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Starter Rock", function(Value)
    selectrock = "Starter Island Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 100 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 100 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Legend Beach Rock", function(Value)
    selectrock = "Legend Beach Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 5000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 5000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Frozen Rock", function(Value)
    selectrock = "Frost Gym Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 150000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 150000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Mythical Rock", function(Value)
    selectrock = "Mythical Gym Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 400000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 400000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Eternal Rock", function(Value)
    selectrock = "Eternal Gym Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 750000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 750000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Legend Rock", function(Value)
    selectrock = "Legend Gym Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 1000000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 1000000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Muscle King Rock", function(Value)
    selectrock = "Muscle King Gym Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 5000000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 5000000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

autoRockFolder:AddSwitch("Jungle Rock", function(Value)
    selectrock = "Ancient Jungle Rock"
    getgenv().autoFarm = Value
    
    task.spawn(function()
        while getgenv().autoFarm do
            task.wait()
            if not getgenv().autoFarm then break end
            
            if game:GetService("Players").LocalPlayer.Durability.Value >= 10000000 then
                for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                    if v.Name == "neededDurability" and v.Value == 10000000 and game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                        firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                        gettool()
                    end
                end
            end
        end
    end)
end)

local rebirthsFolder = farmPlusTab:AddFolder("Rebirths")

-- Target rebirth input - direct text input
rebirthsFolder:AddTextBox("Rebirth Target", function(text)
    local newValue = tonumber(text)
    if newValue and newValue > 0 then
        targetRebirthValue = newValue
        updateStats() -- Call the stats update function
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Objetivo Actualizado",
            Text = "Nuevo objetivo: " .. tostring(targetRebirthValue) .. " renacimientos",
            Duration = 0
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Entrada Inválida",
            Text = "Por favor ingresa un número válido mayor que 0",
            Duration = 0
        })
    end
end)

-- Create toggle switches
local infiniteSwitch -- Forward declaration

local targetSwitch = rebirthsFolder:AddSwitch("Auto Rebirth Target", function(bool)
    _G.targetRebirthActive = bool
    
    if bool then
        -- Turn off infinite rebirth if it's on
        if _G.infiniteRebirthActive and infiniteSwitch then
            infiniteSwitch:Set(false)
            _G.infiniteRebirthActive = false
        end
        
        -- Start target rebirth loop
        spawn(function()
            while _G.targetRebirthActive and wait(0.1) do
                local currentRebirths = game.Players.LocalPlayer.leaderstats.Rebirths.Value
                
                if currentRebirths >= targetRebirthValue then
                    targetSwitch:Set(false)
                    _G.targetRebirthActive = false
                    
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "¡Objetivo Alcanzado!",
                        Text = "Has alcanzado " .. tostring(targetRebirthValue) .. " renacimientos",
                        Duration = 5
                    })
                    
                    break
                end
                
                game:GetService("ReplicatedStorage").rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            end
        end)
    end
end, "Renacimiento automático hasta alcanzar el objetivo")

infiniteSwitch = rebirthsFolder:AddSwitch("Auto Rebirth (Infinite)", function(bool)
    _G.infiniteRebirthActive = bool
    
    if bool then
        -- Turn off target rebirth if it's on
        if _G.targetRebirthActive and targetSwitch then
            targetSwitch:Set(false)
            _G.targetRebirthActive = false
        end
        
        -- Start infinite rebirth loop
        spawn(function()
            while _G.infiniteRebirthActive and wait(0.1) do
                game:GetService("ReplicatedStorage").rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            end
        end)
    end
end, "Renacimiento continuo sin parar")

local sizeSwitch = rebirthsFolder:AddSwitch("Auto Size 1", function(bool)
    _G.autoSizeActive = bool
    
    if bool then
        spawn(function()
            while _G.autoSizeActive and wait() do
                game:GetService("ReplicatedStorage").rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1)
            end
        end)
    end
end, "Establece el tamaño del personaje a 1 continuamente")

local teleportSwitch = rebirthsFolder:AddSwitch("Auto Teleport to Muscle King", function(bool)
    _G.teleportActive = bool
    
    if bool then
        spawn(function()
            while _G.teleportActive and wait() do
                if game.Players.LocalPlayer.Character then
                    game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-8646, 17, -5738))
                end
            end
        end)
    end
end, "Teletransporte continuo al Rey Músculo")

local autoEquipToolsFolder = farmPlusTab:AddFolder("Auto Equip Tools")

-- Free AutoLift Gamepass Button
autoEquipToolsFolder:AddButton("Gamepass AutoLift", function()
    local gamepassFolder = game:GetService("ReplicatedStorage").gamepassIds
    local player = game:GetService("Players").LocalPlayer
    for _, gamepass in pairs(gamepassFolder:GetChildren()) do
        local value = Instance.new("IntValue")
        value.Name = gamepass.Name
        value.Value = gamepass.Value
        value.Parent = player.ownedGamepasses
    end
end, "Desbloquea el gamepass de AutoLift gratis")

-- Auto Weight Toggle
autoEquipToolsFolder:AddSwitch("Auto Weight", function(Value)
    _G.AutoWeight = Value
    
    if Value then
        local weightTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Weight")
        if weightTool then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(weightTool)
        end
    else
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Weight")
        if equipped then
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
    end
    
    task.spawn(function()
        while _G.AutoWeight do
            if not _G.AutoWeight then break end
            game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
            task.wait(0.1)
        end
    end)
end, "Levanta pesas automáticamente")

-- Auto Pushups Toggle
autoEquipToolsFolder:AddSwitch("Auto Pushups", function(Value)
    _G.AutoPushups = Value
    
    if Value then
        local pushupsTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Pushups")
        if pushupsTool then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(pushupsTool)
        end
    else
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Pushups")
        if equipped then
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
    end
    
    task.spawn(function()
        while _G.AutoPushups do
            if not _G.AutoPushups then break end
            game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
            task.wait(0.1)
        end
    end)
end, "Haz flexiones automáticamente")

-- Auto Handstands Toggle
autoEquipToolsFolder:AddSwitch("Auto Handstands", function(Value)
    _G.AutoHandstands = Value
    
    if Value then
        local handstandsTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Handstands")
        if handstandsTool then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(handstandsTool)
        end
    else
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Handstands")
        if equipped then
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
    end
    
    task.spawn(function()
        while _G.AutoHandstands do
            if not _G.AutoHandstands then break end
            game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
            task.wait(0.1)
        end
    end)
end, "Haz paradas de manos automáticamente")

-- Auto Situps Toggle
autoEquipToolsFolder:AddSwitch("Auto Situps", function(Value)
    _G.AutoSitups = Value
    
    if Value then
        local situpsTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Situps")
        if situpsTool then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(situpsTool)
        end
    else
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Situps")
        if equipped then
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
    end
    
    task.spawn(function()
        while _G.AutoSitups do
            if not _G.AutoSitups then break end
            game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
            task.wait(0.1)
        end
    end)
end, "Haz abdominales automáticamente")

-- Auto Punch Toggle
autoEquipToolsFolder:AddSwitch("Auto Punch", function(Value)
    _G.fastHitActive = Value
    
    if Value then
        -- Function to equip and modify punch
        task.spawn(function()
            while _G.fastHitActive do
                if not _G.fastHitActive then break end
                
                local player = game.Players.LocalPlayer
                local punch = player.Backpack:FindFirstChild("Punch")
                if punch then
                    punch.Parent = player.Character
                    if punch:FindFirstChild("attackTime") then
                        punch.attackTime.Value = 0
                    end
                end
                task.wait(0.1)
            end
        end)
        
        -- Function for rapid punching
        task.spawn(function()
            while _G.fastHitActive do
                if not _G.fastHitActive then break end
                
                local player = game.Players.LocalPlayer
                player.muscleEvent:FireServer("punch", "rightHand")
                player.muscleEvent:FireServer("punch", "leftHand")
                
                local character = player.Character
                if character then
                    local punchTool = character:FindFirstChild("Punch")
                    if punchTool then
                        punchTool:Activate()
                    end
                end
                task.wait(0)
            end
        end)
    else
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Punch")
        if equipped then
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
    end
end, "Golpea automáticamente")

-- Fast Tools Toggle
autoEquipToolsFolder:AddSwitch("Fast Tools", function(Value)
    _G.FastTools = Value
    
    local defaultSpeeds = {
        {
            "Punch",
            "attackTime",
            Value and 0 or 0.1
        },
        {
            "Ground Slam",
            "attackTime",
            Value and 0 or 6
        },
        {
            "Stomp",
            "attackTime",
            Value and 0 or 7
        },
        {
            "Handstands",
            "repTime",
            Value and 0 or 1
        },
        {
            "Pushups",
            "repTime",
            Value and 0 or 1
        },
        {
            "Weight",
            "repTime",
            Value and 0 or 1
        },
        {
            "Situps",
            "repTime",
            Value and 0 or 1
        }
    }
    
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    
    for _, toolInfo in ipairs(defaultSpeeds) do
        local tool = backpack:FindFirstChild(toolInfo[1])
        if tool and tool:FindFirstChild(toolInfo[2]) then
            tool[toolInfo[2]].Value = toolInfo[3]
        end
        
        local equippedTool = player.Character and player.Character:FindFirstChild(toolInfo[1])
        if equippedTool and equippedTool:FindFirstChild(toolInfo[2]) then
            equippedTool[toolInfo[2]].Value = toolInfo[3]
        end
    end
end, "Acelera todas las herramientas")

-- Inicializar variables de seguimiento
local sessionStartTime = os.time()
local sessionStartStrength = 0
local sessionStartDurability = 0
local sessionStartKills = 0
local sessionStartRebirths = 0
local sessionStartBrawls = 0
local hasStartedTracking = false

-- Crear una carpeta en farmPlusTab para estadísticas
local statsFolder = farmPlusTab:AddFolder("Estadisticas")

-- Crear etiquetas para las estadísticas solicitadas
statsFolder:AddLabel("Fuerza")
local strengthStatsLabel = statsFolder:AddLabel("Actual: Cargando...")
local strengthGainLabel = statsFolder:AddLabel("Ganado: 0")

statsFolder:AddLabel("Durabilidad")
local durabilityStatsLabel = statsFolder:AddLabel("Actual: Cargando...")
local durabilityGainLabel = statsFolder:AddLabel("Ganado: 0")

statsFolder:AddLabel("Renacimientos")
local rebirthsStatsLabel = statsFolder:AddLabel("Actual: Cargando...")
local rebirthsGainLabel = statsFolder:AddLabel("Ganado: 0")

statsFolder:AddLabel("Kills")
local killsStatsLabel = statsFolder:AddLabel("Actual: Cargando...")
local killsGainLabel = statsFolder:AddLabel("Ganado: 0")

statsFolder:AddLabel("Peleas")
local brawlsStatsLabel = statsFolder:AddLabel("Actual: Cargando...")
local brawlsGainLabel = statsFolder:AddLabel("Ganado: 0")

statsFolder:AddLabel("Tiempo de Juego")
local sessionTimeLabel = statsFolder:AddLabel("Tiempo: 00:00:00")

-- Función para formatear números
local function formatNumber(number)
    if number >= 1e15 then return string.format("%.2fQ", number/1e15)
    elseif number >= 1e12 then return string.format("%.2fT", number/1e12)
    elseif number >= 1e9 then return string.format("%.2fB", number/1e9)
    elseif number >= 1e6 then return string.format("%.2fM", number/1e6)
    elseif number >= 1e3 then return string.format("%.2fK", number/1e3)
    end
    return tostring(math.floor(number))
end

local function formatNumberWithCommas(number)
    local formatted = tostring(math.floor(number))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function formatTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if days > 0 then
        return string.format("%dd %02dh %02dm %02ds", days, hours, minutes, secs)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
end

-- Inicializar seguimiento
local function startTracking()
    if not hasStartedTracking then
        local player = game.Players.LocalPlayer
        sessionStartStrength = player.leaderstats.Strength.Value
        sessionStartDurability = player.Durability.Value
        sessionStartKills = player.leaderstats.Kills.Value
        sessionStartRebirths = player.leaderstats.Rebirths.Value
        sessionStartBrawls = player.leaderstats.Brawls.Value
        sessionStartTime = os.time()
        hasStartedTracking = true
    end
end

-- Función para actualizar estadísticas
local function updateStats()
    local player = game.Players.LocalPlayer
    
    -- Iniciar seguimiento si aún no ha comenzado
    if not hasStartedTracking then
        startTracking()
    end
    
    -- Calcular valores actuales y ganancias
    local currentStrength = player.leaderstats.Strength.Value
    local currentDurability = player.Durability.Value
    local currentKills = player.leaderstats.Kills.Value
    local currentRebirths = player.leaderstats.Rebirths.Value
    local currentBrawls = player.leaderstats.Brawls.Value
    
    local strengthGain = currentStrength - sessionStartStrength
    local durabilityGain = currentDurability - sessionStartDurability
    local killsGain = currentKills - sessionStartKills
    local rebirthsGain = currentRebirths - sessionStartRebirths
    local brawlsGain = currentBrawls - sessionStartBrawls
    
    -- Actualizar valores de estadísticas actuales
    strengthStatsLabel.Text = string.format("Actual: %s", formatNumber(currentStrength))
    durabilityStatsLabel.Text = string.format("Actual: %s", formatNumber(currentDurability))
    rebirthsStatsLabel.Text = string.format("Actual: %s", formatNumber(currentRebirths))
    killsStatsLabel.Text = string.format("Actual: %s", formatNumber(currentKills))
    brawlsStatsLabel.Text = string.format("Actual: %s", formatNumber(currentBrawls))
    
    -- Actualizar valores de ganancias
    strengthGainLabel.Text = string.format("Ganado: %s", formatNumber(strengthGain))
    durabilityGainLabel.Text = string.format("Ganado: %s", formatNumber(durabilityGain))
    rebirthsGainLabel.Text = string.format("Ganado: %s", formatNumber(rebirthsGain))
    killsGainLabel.Text = string.format("Ganado: %s", formatNumber(killsGain))
    brawlsGainLabel.Text = string.format("Ganado: %s", formatNumber(brawlsGain))
    
    -- Actualizar tiempo de sesión
    local elapsedTime = os.time() - sessionStartTime
    local timeString = formatTime(elapsedTime)
    sessionTimeLabel.Text = string.format("Time: %s", timeString)
end

-- Actualizar estadísticas inicialmente
updateStats()

-- Actualizar estadísticas cada 1 segundo
spawn(function()
    while wait(1) do
        updateStats()
    end
end)

-- Agregar botones para funcionalidades adicionales
statsFolder:AddButton("Reset Stats", function()
    local player = game.Players.LocalPlayer
    sessionStartStrength = player.leaderstats.Strength.Value
    sessionStartDurability = player.Durability.Value
    sessionStartKills = player.leaderstats.Kills.Value
    sessionStartRebirths = player.leaderstats.Rebirths.Value
    sessionStartBrawls = player.leaderstats.Brawls.Value
    sessionStartTime = os.time()
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Seguimiento de Estadísticas",
        Text = "¡El seguimiento de progreso de la sesión ha sido reiniciado!",
        Duration = 0
    })
end)

statsFolder:AddButton("Copiar Estadísticas", function()
    local player = game.Players.LocalPlayer
    local statsText = "Estadísticas de Muscle Legends:\n\n"
    
    statsText = statsText .. "Fuerza: " .. formatNumberWithCommas(player.leaderstats.Strength.Value) .. "\n"
    statsText = statsText .. "Durabilidad: " .. formatNumberWithCommas(player.Durability.Value) .. "\n"
    statsText = statsText .. "Renacimientos: " .. formatNumberWithCommas(player.leaderstats.Rebirths.Value) .. "\n"
    statsText = statsText .. "Kills: " .. formatNumberWithCommas(player.leaderstats.Kills.Value) .. "\n"
    statsText = statsText .. "Peleas: " .. formatNumberWithCommas(player.leaderstats.Brawls.Value) .. "\n\n"
    
    -- Agregar estadísticas de sesión si el seguimiento ha comenzado
    if hasStartedTracking then
        local elapsedTime = os.time() - sessionStartTime
        local strengthGain = player.leaderstats.Strength.Value - sessionStartStrength
        local durabilityGain = player.Durability.Value - sessionStartDurability
        local killsGain = player.leaderstats.Kills.Value - sessionStartKills
        local rebirthsGain = player.leaderstats.Rebirths.Value - sessionStartRebirths
        local brawlsGain = player.leaderstats.Brawls.Value - sessionStartBrawls
        
        statsText = statsText .. "--- Estadísticas ---\n"
        statsText = statsText .. "Tiempo Jugado: " .. formatTime(elapsedTime) .. "\n"
        statsText = statsText .. "Fuerza Ganada: " .. formatNumberWithCommas(strengthGain) .. "\n"
        statsText = statsText .. "Durabilidad Ganada: " .. formatNumberWithCommas(durabilityGain) .. "\n"
        statsText = statsText .. "Renacimientos Ganados: " .. formatNumberWithCommas(rebirthsGain) .. "\n"
        statsText = statsText .. "Kills Hechas: " .. formatNumberWithCommas(killsGain) .. "\n"
        statsText = statsText .. "Peleas Ganadas: " .. formatNumberWithCommas(brawlsGain) .. "\n"
    end
    
    setclipboard(statsText)
end)

local pets = window:AddTab("Pets")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pet section
pets:AddLabel("Pets")

-- Create pet dropdown with the correct format
local selectedPet = "Neon Guardian" -- Default selection
local petDropdown = pets:AddDropdown("Seleccionar Mascota", function(text)
    selectedPet = text
    print("Mascota seleccionada: " .. text)
end)

-- Add pet options
petDropdown:Add("Neon Guardian")
petDropdown:Add("Blue Birdie")
petDropdown:Add("Blue Bunny")
petDropdown:Add("Blue Firecaster")
petDropdown:Add("Blue Pheonix")
petDropdown:Add("Crimson Falcon")
petDropdown:Add("Cybernetic Showdown Dragon")
petDropdown:Add("Dark Golem")
petDropdown:Add("Dark Legends Manticore")
petDropdown:Add("Dark Vampy")
petDropdown:Add("Darkstar Hunter")
petDropdown:Add("Eternal Strike Leviathan")
petDropdown:Add("Frostwave Legends Penguin")
petDropdown:Add("Gold Warrior")
petDropdown:Add("Golden Pheonix")
petDropdown:Add("Golden Viking")
petDropdown:Add("Green Butterfly")
petDropdown:Add("Green Firecaster")
petDropdown:Add("Infernal Dragon")
petDropdown:Add("Lightning Strike Phantom")
petDropdown:Add("Magic Butterfly")
petDropdown:Add("Muscle Sensei")
petDropdown:Add("Orange Hedgehog")
petDropdown:Add("Orange Pegasus")
petDropdown:Add("Phantom Genesis Dragon")
petDropdown:Add("Purple Dragon")
petDropdown:Add("Purple Falcon")
petDropdown:Add("Red Dragon")
petDropdown:Add("Red Firecaster")
petDropdown:Add("Red Kitty")
petDropdown:Add("Silver Dog")
petDropdown:Add("Ultimate Supernova Pegasus")
petDropdown:Add("Ultra Birdie")
petDropdown:Add("White Pegasus")
petDropdown:Add("White Pheonix")
petDropdown:Add("Yellow Butterfly")

-- Auto open pet toggle
pets:AddSwitch("Auto Open Pet", function(bool)
    _G.AutoHatchPet = bool
    
    if bool then
        spawn(function()
            while _G.AutoHatchPet and selectedPet ~= "" do
                local petToOpen = ReplicatedStorage.cPetShopFolder:FindFirstChild(selectedPet)
                if petToOpen then
                    ReplicatedStorage.cPetShopRemote:InvokeServer(petToOpen)
                end
                task.wait(1)
            end
        end)
    end
end)

-- Aura section
pets:AddLabel("AURAS")

-- Create aura dropdown with the correct format
local selectedAura = "Blue Aura" -- Default selection
local auraDropdown = pets:AddDropdown("Select Aura", function(text)
    selectedAura = text
    print("Aura seleccionada: " .. text)
end)

-- Add aura options
auraDropdown:Add("Astral Electro")
auraDropdown:Add("Azure Tundra")
auraDropdown:Add("Blue Aura")
auraDropdown:Add("Dark Electro")
auraDropdown:Add("Dark Lightning")
auraDropdown:Add("Dark Storm")
auraDropdown:Add("Electro")
auraDropdown:Add("Enchanted Mirage")
auraDropdown:Add("Entropic Blast")
auraDropdown:Add("Eternal Megastrike")
auraDropdown:Add("Grand Supernova")
auraDropdown:Add("Green Aura")
auraDropdown:Add("Inferno")
auraDropdown:Add("Lightning")
auraDropdown:Add("Muscle King")
auraDropdown:Add("Power Lightning")
auraDropdown:Add("Purple Aura")
auraDropdown:Add("Purple Nova")
auraDropdown:Add("Red Aura")
auraDropdown:Add("Supernova")
auraDropdown:Add("Ultra Inferno")
auraDropdown:Add("Ultra Mirage")
auraDropdown:Add("Unstable Mirage")
auraDropdown:Add("Yellow Aura")

-- Auto open aura toggle
pets:AddSwitch("Auto Open Auras", function(bool)
    _G.AutoHatchAura = bool
    
    if bool then
        spawn(function()
            while _G.AutoHatchAura and selectedAura ~= "" do
                local auraToOpen = ReplicatedStorage.cPetShopFolder:FindFirstChild(selectedAura)
                if auraToOpen then
                    ReplicatedStorage.cPetShopRemote:InvokeServer(auraToOpen)
                end
                task.wait(1)
            end
        end)
    end
end)

-- Create the Misc tab
local miscTab = window:AddTab("Misc")

-- Create the first folder
local misc1Folder = miscTab:AddFolder("Misc 1")

-- Add ad removal button to Misc 1
misc1Folder:AddButton("Remove Portals", function()
    -- Remove existing ad portals
    for _, portal in pairs(game:GetDescendants()) do
        if portal.Name == "RobloxForwardPortals" then
            portal:Destroy()
        end
    end
    
    -- Set up connection to remove future ad portals
    if _G.AdRemovalConnection then
        _G.AdRemovalConnection:Disconnect()
    end
    
    _G.AdRemovalConnection = game.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "RobloxForwardPortals" then
            descendant:Destroy()
        end
    end)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Anuncios Eliminados",
        Text = "Los anuncios de Roblox han sido eliminados",
        Duration = 0
    })
end)

-- Walk on Water feature
local parts = {}
local partSize = 2048
local totalDistance = 50000
local startPosition = Vector3.new(-2, -9.5, -2)
local numberOfParts = math.ceil(totalDistance / partSize)

local function createParts()
    for x = 0, numberOfParts - 1 do
        for z = 0, numberOfParts - 1 do
            local newPartSide = Instance.new("Part")
            newPartSide.Size = Vector3.new(partSize, 1, partSize)
            newPartSide.Position = startPosition + Vector3.new(x * partSize, 0, z * partSize)
            newPartSide.Anchored = true
            newPartSide.Transparency = 1
            newPartSide.CanCollide = true
            newPartSide.Name = "Part_Side_" .. x .. "_" .. z
            newPartSide.Parent = workspace
            table.insert(parts, newPartSide)
            
            local newPartLeftRight = Instance.new("Part")
            newPartLeftRight.Size = Vector3.new(partSize, 1, partSize)
            newPartLeftRight.Position = startPosition + Vector3.new(-x * partSize, 0, z * partSize)
            newPartLeftRight.Anchored = true
            newPartLeftRight.Transparency = 1
            newPartLeftRight.CanCollide = true
            newPartLeftRight.Name = "Part_LeftRight_" .. x .. "_" .. z
            newPartLeftRight.Parent = workspace
            table.insert(parts, newPartLeftRight)
            
            local newPartUpLeft = Instance.new("Part")
            newPartUpLeft.Size = Vector3.new(partSize, 1, partSize)
            newPartUpLeft.Position = startPosition + Vector3.new(-x * partSize, 0, -z * partSize)
            newPartUpLeft.Anchored = true
            newPartUpLeft.Transparency = 1
            newPartUpLeft.CanCollide = true
            newPartUpLeft.Name = "Part_UpLeft_" .. x .. "_" .. z
            newPartUpLeft.Parent = workspace
            table.insert(parts, newPartUpLeft)
            
            local newPartUpRight = Instance.new("Part")
            newPartUpRight.Size = Vector3.new(partSize, 1, partSize)
            newPartUpRight.Position = startPosition + Vector3.new(x * partSize, 0, -z * partSize)
            newPartUpRight.Anchored = true
            newPartUpRight.Transparency = 1
            newPartUpRight.CanCollide = true
            newPartUpRight.Name = "Part_UpRight_" .. x .. "_" .. z
            newPartUpRight.Parent = workspace
            table.insert(parts, newPartUpRight)
        end
    end
end

local function makePartsWalkthrough()
    for _, part in ipairs(parts) do
        if part and part.Parent then
            part.CanCollide = false
        end
    end
end

local function makePartsSolid()
    for _, part in ipairs(parts) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end
end

-- Add Walk on Water toggle
misc1Folder:AddSwitch("Walk on Water", function(bool)
    if bool then
        createParts()
    else
        makePartsWalkthrough()
    end
end)

-- Add Auto Spin Wheel toggle
misc1Folder:AddSwitch("Auto Spin Wheel", function(bool)
    _G.AutoSpinWheel = bool
    
    if bool then
        spawn(function()
            while _G.AutoSpinWheel and wait(1) do
                game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", game:GetService("ReplicatedStorage").fortuneWheelChances["Fortune Wheel"])
            end
        end)
    end
end)

-- Add Auto Claim Gifts toggle
misc1Folder:AddSwitch("Auto Claim Gifts", function(bool)
    _G.AutoClaimGifts = bool
    
    if bool then
        spawn(function()
            while _G.AutoClaimGifts and wait(1) do
                for i = 1, 8 do
                    game:GetService("ReplicatedStorage").rEvents.freeGiftClaimRemote:InvokeServer("claimGift", i)
                end
            end
        end)
    end
end)

-- Create the second folder


local misc2Folder = miscTab:AddFolder("Misc 2")

-- Fast Punch toggle with auto-punch functionality and persistent equipping
misc2Folder:AddSwitch("Auto Punch", function(bool)
    _G.FastPunch = bool
    
    if bool then
        -- Function to continuously equip and modify punch
        spawn(function()
            while _G.FastPunch do
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- Check if tool is not equipped
                if character and not character:FindFirstChild("Punch") then
                    local punch = player.Backpack:FindFirstChild("Punch")
                    if punch then
                        if punch:FindFirstChild("attackTime") then
                            punch.attackTime.Value = 0.1
                        end
                        character.Humanoid:EquipTool(punch)
                    end
                elseif character and character:FindFirstChild("Punch") then
                    -- Make sure equipped tool is modified
                    local equipped = character:FindFirstChild("Punch")
                    if equipped:FindFirstChild("attackTime") then
                        equipped.attackTime.Value = 0.1
                    end
                end
                
                wait(0.1)
            end
        end)
        
        -- Function to rapidly punch
        spawn(function()
            while _G.FastPunch do
                local player = game.Players.LocalPlayer
                player.muscleEvent:FireServer("punch", "rightHand")
                player.muscleEvent:FireServer("punch", "leftHand")
                local character = player.Character
                if character then
                    local punchTool = character:FindFirstChild("Punch")
                    if punchTool then
                        punchTool:Activate()
                    end
                end
                wait(0)
            end
        end)
    else
        -- Unequip and reset tool
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Punch")
        if equipped then
            if equipped:FindFirstChild("attackTime") then
                equipped.attackTime.Value = 0.2
            end
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
        
        -- Also reset the backpack tool
        local backpackTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
        if backpackTool and backpackTool:FindFirstChild("attackTime") then
            backpackTool.attackTime.Value = 0.1
        end
    end
end)

-- Fast Situps toggle with auto-situps functionality and persistent equipping
misc2Folder:AddSwitch("Auto Situps", function(bool)
    _G.FastSitups = bool
    
    if bool then
        -- Continuously equip and modify situps tool
        spawn(function()
            while _G.FastSitups do
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- Check if tool is not equipped
                if character and not character:FindFirstChild("Situps") then
                    local situpsTool = player.Backpack:FindFirstChild("Situps")
                    if situpsTool then
                        if situpsTool:FindFirstChild("repTime") then
                            situpsTool.repTime.Value = 0
                        end
                        character.Humanoid:EquipTool(situpsTool)
                    end
                elseif character and character:FindFirstChild("Situps") then
                    -- Make sure equipped tool is modified
                    local equipped = character:FindFirstChild("Situps")
                    if equipped:FindFirstChild("repTime") then
                        equipped.repTime.Value = 0
                    end
                end
                
                wait(0.1)
            end
        end)
        
        -- Auto do situps
        spawn(function()
            while _G.FastSitups do
                game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
                task.wait(0)
            end
        end)
    else
        -- Unequip and reset tool
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Situps")
        if equipped then
            if equipped:FindFirstChild("repTime") then
                equipped.repTime.Value = 1
            end
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
        
        -- Also reset the backpack tool
        local backpackTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Situps")
        if backpackTool and backpackTool:FindFirstChild("repTime") then
            backpackTool.repTime.Value = 1
        end
    end
end)

-- Fast Weight toggle with auto-weight functionality and persistent equipping
misc2Folder:AddSwitch("Auto Weight", function(bool)
    _G.FastWeight = bool
    
    if bool then
        -- Continuously equip and modify weight tool
        spawn(function()
            while _G.FastWeight do
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- Check if tool is not equipped
                if character and not character:FindFirstChild("Weight") then
                    local weightTool = player.Backpack:FindFirstChild("Weight")
                    if weightTool then
                        if weightTool:FindFirstChild("repTime") then
                            weightTool.repTime.Value = 0
                        end
                        character.Humanoid:EquipTool(weightTool)
                    end
                elseif character and character:FindFirstChild("Weight") then
                    -- Make sure equipped tool is modified
                    local equipped = character:FindFirstChild("Weight")
                    if equipped:FindFirstChild("repTime") then
                        equipped.repTime.Value = 0
                    end
                end
                
                wait(0.1)
            end
        end)
        
        -- Auto do weight lifting
        spawn(function()
            while _G.FastWeight do
                game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
                task.wait(0)
            end
        end)
    else
        -- Unequip and reset tool
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Weight")
        if equipped then
            if equipped:FindFirstChild("repTime") then
                equipped.repTime.Value = 1
            end
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
        
        -- Also reset the backpack tool
        local backpackTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Weight")
        if backpackTool and backpackTool:FindFirstChild("repTime") then
            backpackTool.repTime.Value = 1
        end
    end
end)

-- Fast Pushups toggle with auto-pushups functionality and persistent equipping
misc2Folder:AddSwitch("Auto Pushups", function(bool)
    _G.FastPushups = bool
    
    if bool then
        -- Continuously equip and modify pushups tool
        spawn(function()
            while _G.FastPushups do
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- Check if tool is not equipped
                if character and not character:FindFirstChild("Pushups") then
                    local pushupsTool = player.Backpack:FindFirstChild("Pushups")
                    if pushupsTool then
                        if pushupsTool:FindFirstChild("repTime") then
                            pushupsTool.repTime.Value = 0
                        end
                        character.Humanoid:EquipTool(pushupsTool)
                    end
                elseif character and character:FindFirstChild("Pushups") then
                    -- Make sure equipped tool is modified
                    local equipped = character:FindFirstChild("Pushups")
                    if equipped:FindFirstChild("repTime") then
                        equipped.repTime.Value = 0
                    end
                end
                
                wait(0.1)
            end
        end)
        
        -- Auto do pushups
        spawn(function()
            while _G.FastPushups do
                game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
                task.wait(0)
            end
        end)
    else
        -- Unequip and reset tool
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Pushups")
        if equipped then
            if equipped:FindFirstChild("repTime") then
                equipped.repTime.Value = 1
            end
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
        
        -- Also reset the backpack tool
        local backpackTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Pushups")
        if backpackTool and backpackTool:FindFirstChild("repTime") then
            backpackTool.repTime.Value = 1
        end
    end
end)

-- Fast Handstands toggle with auto-handstands functionality and persistent equipping
misc2Folder:AddSwitch("Auto Handstands", function(bool)
    _G.FastHandstands = bool
    
    if bool then
        -- Continuously equip and modify handstands tool
        spawn(function()
            while _G.FastHandstands do
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- Check if tool is not equipped
                if character and not character:FindFirstChild("Handstands") then
                    local handstandsTool = player.Backpack:FindFirstChild("Handstands")
                    if handstandsTool then
                        if handstandsTool:FindFirstChild("repTime") then
                            handstandsTool.repTime.Value = 0
                        end
                        character.Humanoid:EquipTool(handstandsTool)
                    end
                elseif character and character:FindFirstChild("Handstands") then
                    -- Make sure equipped tool is modified
                    local equipped = character:FindFirstChild("Handstands")
                    if equipped:FindFirstChild("repTime") then
                        equipped.repTime.Value = 0
                    end
                end
                
                wait(0.1)
            end
        end)
        
        -- Auto do handstands
        spawn(function()
            while _G.FastHandstands do
                game:GetService("Players").LocalPlayer.muscleEvent:FireServer("rep")
                task.wait(0)
            end
        end)
    else
        -- Unequip and reset tool
        local character = game.Players.LocalPlayer.Character
        local equipped = character:FindFirstChild("Handstands")
        if equipped then
            if equipped:FindFirstChild("repTime") then
                equipped.repTime.Value = 1
            end
            equipped.Parent = game.Players.LocalPlayer.Backpack
        end
        
        -- Also reset the backpack tool
        local backpackTool = game.Players.LocalPlayer.Backpack:FindFirstChild("Handstands")
        if backpackTool and backpackTool:FindFirstChild("repTime") then
            backpackTool.repTime.Value = 1
        end
    end
end)

-- Create the third folder
local misc3Folder = miscTab:AddFolder("Misc 3")

-- Add No-Clip toggle
misc3Folder:AddSwitch("No-Clip", function(bool)
    _G.NoClip = bool
    
    if bool then
        local noclipLoop
        noclipLoop = game:GetService("RunService").Stepped:Connect(function()
            if _G.NoClip then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            else
                noclipLoop:Disconnect()
            end
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "No-Clip Activado",
            Text = "Ahora puedes atravesar objetos",
            Duration = 0
        })
    end
end)

-- Add Infinite Jump toggle
misc3Folder:AddSwitch("Jumpy Infinite", function(bool)
    _G.InfiniteJump = bool
    
    if bool then
        local InfiniteJumpConnection
        InfiniteJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
            if _G.InfiniteJump then
                game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            else
                InfiniteJumpConnection:Disconnect()
            end
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Salto Infinito Activado",
            Text = "Ahora puedes saltar sin límites",
            Duration = 0
        })
    end
end)

local timeDropdown = misc3Folder:AddDropdown("Change Time", function(selection)
    local lighting = game:GetService("Lighting")
    
    if selection == "Night" then
        lighting.ClockTime = 0
    elseif selection == "Day" then
        lighting.ClockTime = 12
    elseif selection == "Midnight" then
        lighting.ClockTime = 6
    end
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Hora Cambiada",
        Text = "La hora del día ha sido cambiada a: " .. selection,
        Duration = 0
    })
end)

-- Add time options
timeDropdown:Add("Night")
timeDropdown:Add("Day")
timeDropdown:Add("Midnight")

-- Create the Rebirth Farm folder in Spanish
local rebirthFarmFolder = miscTab:AddFolder("Premium Farm")

local function unequipAllPets()
    local petsFolder = player.petsFolder
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

local function equipUniquePet(petName)
    unequipAllPets()
    task.wait(0.01)
    for _, pet in pairs(player.petsFolder.Unique:GetChildren()) do
        if pet.Name == petName then
            ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

local function findMachine(machineName)
    local machine = workspace.machinesFolder:FindFirstChild(machineName)
    if not machine then
        for _, folder in pairs(workspace:GetChildren()) do
            if folder:IsA("Folder") and folder.Name:find("machines") then
                machine = folder:FindFirstChild(machineName)
                if machine then break end
            end
        end
    end
    return machine
end

local function pressE()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, "E", false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, "E", false, game)
end

local function useOneEgg()
    ReplicatedStorage.rEvents.proteinEggEvent:FireServer("useEgg")
end

rebirthFarmFolder:AddLabel("OP Rebirth Farm (From HAVOC)")

rebirthFarmFolder:AddTextBox("Target Rebirth", function(text)
    targetRebirth = tonumber(text) or math.huge
end)

-- Variable to store the position lock connection
local positionLockConnection = nil

-- Function to lock player position
local function lockPlayerPosition(position)
    if positionLockConnection then
        positionLockConnection:Disconnect()
    end
    
    positionLockConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = position
        end
    end)
end

-- Function to unlock player position
local function unlockPlayerPosition()
    if positionLockConnection then
        positionLockConnection:Disconnect()
        positionLockConnection = nil
    end
end

-- Add position lock toggle
rebirthFarmFolder:AddSwitch("Lock Position", function(bool)
    if bool then
        -- Get current position and lock it
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local currentPosition = player.Character.HumanoidRootPart.CFrame
            lockPlayerPosition(currentPosition)
        end
    else
        -- Unlock position
        unlockPlayerPosition()
    end
end)

local packFarm = rebirthFarmFolder:AddSwitch("Rebirth Farm", function(bool)
    isRunning = bool
    
    task.spawn(function()
        while isRunning do
            local currentRebirths = player.leaderstats.Rebirths.Value
            local rebirthCost = 10000 + (5000 * currentRebirths)
            
            if player.ultimatesFolder:FindFirstChild("Golden Rebirth") then
                local goldenRebirths = player.ultimatesFolder["Golden Rebirth"].Value
                rebirthCost = math.floor(rebirthCost * (1 - (goldenRebirths * 0.1)))
            end
            unequipAllPets()
            task.wait(0.1)
            equipUniquePet("Swift Samurai")
            
            while isRunning and player.leaderstats.Strength.Value < rebirthCost do
                for i = 1, 10 do
                    player.muscleEvent:FireServer("rep")
                end
                task.wait()
            end
            unequipAllPets()
            task.wait(0.1)
            equipUniquePet("Tribal Overlord")
            local machine = findMachine("Jungle Bar Lift")
            if machine and machine:FindFirstChild("interactSeat") then
                player.Character.HumanoidRootPart.CFrame = machine.interactSeat.CFrame * CFrame.new(0, 3, 0)
                repeat
                    task.wait(0.1)
                    pressE()
                until player.Character.Humanoid.Sit
            end
            local initialRebirths = player.leaderstats.Rebirths.Value
            repeat
                ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                task.wait(0.1)
            until player.leaderstats.Rebirths.Value > initialRebirths
            if not isRunning then break end
            task.wait()
        end
    end)
end)

local frameToggle = rebirthFarmFolder:AddSwitch("Hide Frames", function(bool)
    local rSto = game:GetService("ReplicatedStorage")
    for _, obj in pairs(rSto:GetChildren()) do
        if obj.Name:match("Frame$") then
            obj.Visible = not bool
        end
    end
end)

local speedGrind = rebirthFarmFolder:AddSwitch("Fast Strength", function(bool)
    local isGrinding = bool
    
    if not bool then
        unequipAllPets()
        return
    end
    
    equipUniquePet("Swift Samurai")
    
    for i = 1, 14 do
        task.spawn(function()
            while isGrinding do
                player.muscleEvent:FireServer("rep")
                task.wait()
            end
        end)
    end
end)


local killerTab = window:AddTab("Killer")


_G.whitelistedPlayers = _G.whitelistedPlayers or {}
_G.targetPlayer = _G.targetPlayer or ""

-- Improved character checking function with timeout
local function checkCharacter()
    local player = game.Players.LocalPlayer
    
    if not player then
        return nil
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        -- Wait for character to load, but with a timeout
        local startTime = tick()
        repeat
            task.wait(0.1)
            -- If waiting too long (5 seconds), give up
            if tick() - startTime > 5 then
                return nil
            end
        until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    end
    
    return player.Character
end

-- Improved tool equipping function with error handling
local function gettool()
    pcall(function()
        -- Check if we have a character and humanoid
        if not game.Players.LocalPlayer.Character or 
           not game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            return
        end
        
        -- Try to equip the punch tool
        for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            if v.Name == "Punch" then
                game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                break
            end
        end
        
        -- Fire the punch events
        game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
        game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
    end)
end

-- Improved kill player function with better error handling
local function killPlayer(target)
    -- Make sure we have our own character
    local character = checkCharacter()
    if not character then return end
    
    -- Make sure target has a character
    if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- Make sure we have the necessary parts
    if not character:FindFirstChild("LeftHand") then
        return
    end
    
    -- Try to kill the player
    pcall(function()
        firetouchinterest(target.Character.HumanoidRootPart, character.LeftHand, 0)
        task.wait(0.01) -- Small wait to ensure the touch registers
        firetouchinterest(target.Character.HumanoidRootPart, character.LeftHand, 1)
        gettool()
    end)
end

-- Player finding function with improved matching
local function findClosestPlayer(input)
    if not input or input == "" then return nil end
    
    input = input:lower()
    local bestMatch = nil
    local bestScore = 0
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local username = player.Name:lower()
            local displayName = player.DisplayName:lower()
            
            local usernameMatch = username:find(input, 1, true) ~= nil
            local displayMatch = displayName:find(input, 1, true) ~= nil
            
            local usernameScore = 0
            local displayScore = 0
            
            if usernameMatch then
                usernameScore = (#input / #username) * 100
                if username:sub(1, #input) == input then
                    usernameScore = usernameScore + 50
                end
            end
            
            if displayMatch then
                displayScore = (#input / #displayName) * 100
                if displayName:sub(1, #input) == input then
                    displayScore = displayScore + 50
                end
            end
            
            local score = math.max(usernameScore, displayScore)
            
            if score > bestScore then
                bestScore = score
                bestMatch = player
            end
        end
    end
    
    if bestScore > 20 then
        return bestMatch
    end
    
    return nil
end

local whitelistedPlayersLabel = killerTab:AddLabel("Whitelisted Players: None")
local targetPlayerLabel = killerTab:AddLabel("Target Player: None")

-- Update UI functions
local function updateWhitelistedPlayersLabel()
    if #_G.whitelistedPlayers == 0 then
        whitelistedPlayersLabel.Text = "Whitelisted Players: None"
    else
        local displayText = "Players on the White List: "
        for i, playerInfo in ipairs(_G.whitelistedPlayers) do
            if i > 1 then displayText = displayText .. ", " end
            displayText = displayText .. playerInfo
        end
        whitelistedPlayersLabel.Text = displayText
    end
end

local function updateTargetPlayerLabel()
    if _G.targetPlayer == "" then
        targetPlayerLabel.Text = "Jugador Objetivo: Ninguno"
    else
        targetPlayerLabel.Text = "Jugador Objetivo: " .. _G.targetPlayer
    end
end

-- Auto-whitelist friends feature
local autoWhitelistFriendsSwitch = killerTab:AddSwitch("Add Friends to Whitelist Automatically", function(bool)
    _G.autoWhitelistFriends = bool
    
    if bool then
        pcall(function()
            for _, player in pairs(game.Players:GetPlayers()) do
                if player:IsFriendsWith(game.Players.LocalPlayer.UserId) then
                    local playerInfo = player.Name .. " (" .. player.DisplayName .. ")"
                    if not table.find(_G.whitelistedPlayers, playerInfo) then
                        table.insert(_G.whitelistedPlayers, playerInfo)
                    end
                end
            end
            updateWhitelistedPlayersLabel()
        end)
    end
end)

-- Handle new players joining
game.Players.PlayerAdded:Connect(function(player)
    if _G.autoWhitelistFriends then
        pcall(function()
            if player:IsFriendsWith(game.Players.LocalPlayer.UserId) then
                local playerInfo = player.Name .. " (" .. player.DisplayName .. ")"
                if not table.find(_G.whitelistedPlayers, playerInfo) then
                    table.insert(_G.whitelistedPlayers, playerInfo)
                    updateWhitelistedPlayersLabel()
                end
            end
        end)
    end
end)

-- Whitelist management UI
killerTab:AddTextBox("Add Player to Whitelist (Name/Nickname)", function(text)
    if text and text ~= "" then
        local player = findClosestPlayer(text)
        if player then
            local playerInfo = player.Name .. " (" .. player.DisplayName .. ")"
            
            local alreadyWhitelisted = false
            for _, info in ipairs(_G.whitelistedPlayers) do
                if info:find(player.Name, 1, true) then
                    alreadyWhitelisted = true
                    break
                end
            end
            
            if not alreadyWhitelisted then
                table.insert(_G.whitelistedPlayers, playerInfo)
                updateWhitelistedPlayersLabel()
            end
        end
    end
end)

killerTab:AddTextBox("Remove Player from Whitelist (Name/Nickname)", function(text)
    if text and text ~= "" then
        local textLower = text:lower()
        for i, playerInfo in ipairs(_G.whitelistedPlayers) do
            if playerInfo:lower():find(textLower, 1, true) then
                table.remove(_G.whitelistedPlayers, i)
                updateWhitelistedPlayersLabel()
                return
            end
        end
        
        local player = findClosestPlayer(text)
        if player then
            for i, playerInfo in ipairs(_G.whitelistedPlayers) do
                if playerInfo:find(player.Name, 1, true) then
                    table.remove(_G.whitelistedPlayers, i)
                    updateWhitelistedPlayersLabel()
                    break
                end
            end
        end
    end
end)

killerTab:AddButton("Clear WhiteList", function()
    _G.whitelistedPlayers = {}
    updateWhitelistedPlayersLabel()
end)

-- Improved auto-kill all feature with better error handling and reliability
local autoKillAllSwitch = killerTab:AddSwitch("Automatically Remove Everyone (Except Whitelist)", function(bool)
    _G.autoKillAll = bool
    
    if bool then
        spawn(function()
            while _G.autoKillAll do
                pcall(function()
                    local players = game:GetService("Players"):GetPlayers()
                    
                    for _, player in ipairs(players) do
                        if player == game.Players.LocalPlayer or not _G.autoKillAll then
                            continue
                        end
                        
                        -- Check if player is whitelisted
                        local isWhitelisted = false
                        for _, whitelistedInfo in ipairs(_G.whitelistedPlayers) do
                            if whitelistedInfo:find(player.Name, 1, true) then
                                isWhitelisted = true
                                break
                            end
                        end
                        
                        -- Only kill if not whitelisted and has a character
                        if not isWhitelisted and player.Character and 
                           player.Character:FindFirstChild("HumanoidRootPart") and
                           player.Character:FindFirstChild("Humanoid") and
                           player.Character.Humanoid.Health > 0 then
                            
                            -- Try to kill the player with error handling
                            pcall(function()
                                killPlayer(player)
                            end)
                            
                            -- Small wait between kills to prevent overload
                            task.wait(0.05)
                        end
                    end
                end)
                
                -- Wait a bit before the next cycle, but not too long
                task.wait(0.2)
            end
        end)
    end
end)

-- Target player management
killerTab:AddTextBox("Select Target Player (Name/Nickname)", function(text)
    if text and text ~= "" then
        local player = findClosestPlayer(text)
        if player then
            _G.targetPlayer = player.Name .. " (" .. player.DisplayName .. ")"
            updateTargetPlayerLabel()
        end
    end
end)

killerTab:AddButton("Remove Target", function()
    _G.targetPlayer = ""
    updateTargetPlayerLabel()
end)

-- Improved auto-kill target feature
local autoKillTargetSwitch = killerTab:AddSwitch("Delete Target Automatically", function(bool)
    _G.autoKillTarget = bool
    
    if bool and _G.targetPlayer ~= "" then
        spawn(function()
            while _G.autoKillTarget and _G.targetPlayer ~= "" do
                pcall(function()
                    local targetName = _G.targetPlayer:match("^([^%(]+)")
                    if targetName then
                        targetName = targetName:gsub("%s+$", "")
                        local targetPlayer = game.Players:FindFirstChild(targetName)
                        if targetPlayer and targetPlayer.Character and 
                           targetPlayer.Character:FindFirstChild("HumanoidRootPart") and
                           targetPlayer.Character:FindFirstChild("Humanoid") and
                           targetPlayer.Character.Humanoid.Health > 0 then
                            
                            killPlayer(targetPlayer)
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

-- Manual kill buttons
killerTab:AddButton("Remove Everyone (Except Whitelist)", function()
    pcall(function()
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                local isWhitelisted = false
                for _, whitelistedInfo in ipairs(_G.whitelistedPlayers) do
                    if whitelistedInfo:find(player.Name, 3, true) then
                        isWhitelisted = true
                        break
                    end
                end
                
                if not isWhitelisted and player.Character and 
                   player.Character:FindFirstChild("HumanoidRootPart") then
                    killPlayer(player)
                    task.wait(0.05)
                end
            end
        end
    end)
end)

killerTab:AddButton("Delete Target", function()
    if _G.targetPlayer ~= "" then
        pcall(function()
            local targetName = _G.targetPlayer:match("^([^%(]+)")
            if targetName then
                targetName = targetName:gsub("%s+$", "")
                local targetPlayer = game.Players:FindFirstChild(targetName)
                if targetPlayer then
                    killPlayer(targetPlayer)
                end
            end
        end)
    end
end)

-- Initialize UI
updateWhitelistedPlayersLabel()
updateTargetPlayerLabel()



local teleportTab = window:AddTab("Teleport")

teleportTab:AddButton("Spawn", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(2, 8, 115)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Inicio",
        Duration = 0
    })
end)

teleportTab:AddButton("Secret Area", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(1947, 2, 6191)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Área Secreta",
        Duration = 0
    })
end)

teleportTab:AddButton("Tiny Island", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(-34, 7, 1903)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Área Diminuta",
        Duration = 0
    })
end)

teleportTab:AddButton("Teleport Frozen", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(- 2600.00244, 3.67686558, - 403.884369, 0.0873617008, 1.0482899e-09, 0.99617666, 3.07204253e-08, 1, - 3.7464023e-09, - 0.99617666, 3.09302628e-08, 0.0873617008)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Área Congelada",
        Duration = 0
    })
end)

teleportTab:AddButton("Mythical", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(2255, 7, 1071)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Área Mítica",
        Duration = 0
    })
end)

teleportTab:AddButton("Inferno", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(-6768, 7, -1287)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Infierno",
        Duration = 0
    })
end)

teleportTab:AddButton("Legend", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(4604, 991, -3887)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado a Leyenda",
        Duration = 0
    })
end)

teleportTab:AddButton("Muscle King Gym", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(-8646, 17, -5738)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Rey Musculoso",
        Duration = 0
    })
end)

teleportTab:AddButton("Jungle", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(-8659, 6, 2384)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado a la Jungla",
        Duration = 0
    })
end)

teleportTab:AddButton("Brawl Lava", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(4471, 119, -8836)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Combate de Lava",
        Duration = 0
    })
end)

teleportTab:AddButton("Brawl Desert", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(960, 17, -7398)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Combate del Desierto",
        Duration = 0
    })
end)

teleportTab:AddButton("Brawl Regular", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(-1849, 20, -6335)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teletransporte",
        Text = "Teletransportado al Combate de Playa",
        Duration = 0
    })
end)

local noteTab = window:AddTab("Nota")

-- Add a decorative header with centered text
noteTab:AddLabel("Fenix Script")

-- Add spacers for better layout
noteTab:AddLabel("")
-- Instead of one large text block, let's add each paragraph separately
-- This gives better control over formatting
noteTab:AddLabel("criado por: Fenix")
noteTab:AddLabel("Este es un script de prueba")