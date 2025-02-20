local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Only initialize PlayersFolder if it exists in workspace
local PlayersFolder = workspace:FindFirstChild("Players")
local UseCustomCharacters = PlayersFolder ~= nil

local ESP = {
    Enabled = true,
    Sleepers = true,
    BoxEnabled = false,
    Skeleton = true,
    ShowViewAngle = true,
    TeamCheck = false,  
    HealthBar = true,  
    ShowDistance = true,
    ShowStatus = true,
    ShowHealth = true,
    ShowName = true,
    ShowTool = true,
    Box3D = false,
    BoxCorners = false,   
    CornerSize = 15,      
    
    BoxThickness = 0.7,
    BoxTransparency = 1,  
    ViewAngleThickness = 1,
    ViewAngleLength = 5,
    TextSize = 14,  
    MovementThreshold = 0.1, 

    BoxColor = Color3.fromRGB(255, 255, 255),  
    HealthBarColor = Color3.fromRGB(0, 255, 0), 
    OutlineColor = Color3.fromRGB(0, 0, 0), 
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1,
    HeadCircleRadius = 8,  
    HeadCirclePoints = 16,  
    TextColor = Color3.fromRGB(255, 255, 255),
    ViewAngleColor = Color3.fromRGB(255, 255, 255),

    StatusIdleText = "Idle",
    StatusMovingText = "Moving",

    ["World"] = 
    {
        MaxDistance = false,
        MaxDistanceNum = 10,
        
        ["Resources"] = 
        {
            ClothPlant = false,
            IronOre = false,
            StoneOre = false,
            BrimstoneOre = false,
            Wood = false,
            Cactus = false,
        },
        ["Items"] = 
        {
            DroppedItems = false,
            Barrels = false,
            Recyclers = false,
            Backpacks = false,
        }

    },
}

local ESPObjects = {}

local function CreateESPBox(player)
    local boxOutline = Drawing.new("Square")
    boxOutline.Visible = false
    boxOutline.Color = ESP.OutlineColor
    boxOutline.Thickness = ESP.BoxThickness + 2
    boxOutline.Transparency = 1
    boxOutline.Filled = false
    
    local espBox = Drawing.new("Square")
    espBox.Visible = false
    espBox.Color = ESP.BoxColor
    espBox.Thickness = ESP.BoxThickness
    espBox.Transparency = ESP.BoxTransparency
    espBox.Filled = false
    
    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Visible = false
    healthBarOutline.Color = ESP.OutlineColor
    healthBarOutline.Thickness = 1
    healthBarOutline.Transparency = 1
    healthBarOutline.Filled = false
    
    local healthBarBG = Drawing.new("Square")
    healthBarBG.Visible = false
    healthBarBG.Color = Color3.fromRGB(0, 0, 0)
    healthBarBG.Thickness = 0
    healthBarBG.Transparency = 1
    healthBarBG.Filled = true
    
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color = ESP.HealthBarColor
    healthBar.Thickness = 1
    healthBar.Transparency = 1
    healthBar.Filled = true
    
    local skeletonLines = {}
    for i = 1, 15 do  
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESP.SkeletonColor
        line.Thickness = ESP.SkeletonThickness
        line.Transparency = 1
        table.insert(skeletonLines, line)
    end
    
    local headCircle = {}
    for i = 1, ESP.HeadCirclePoints do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESP.SkeletonColor
        line.Thickness = ESP.SkeletonThickness
        line.Transparency = 1
        table.insert(headCircle, line)
    end
    
    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Center = true
    distanceText.Outline = true
    distanceText.TextSize = ESP.TextSize
    distanceText.Color = ESP.TextColor
    
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Center = true
    healthText.Outline = true
    healthText.TextSize = ESP.TextSize
    healthText.Color = ESP.TextColor
    
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Center = true
    nameText.Outline = true
    nameText.TextSize = ESP.TextSize
    nameText.Color = ESP.TextColor
    
    local toolText = Drawing.new("Text")
    toolText.Visible = false
    toolText.Center = true
    toolText.Outline = true
    toolText.TextSize = ESP.TextSize
    toolText.Color = ESP.TextColor
    
    local statusText = Drawing.new("Text")
    statusText.Visible = false
    statusText.Center = true
    statusText.Outline = true
    statusText.TextSize = ESP.TextSize
    statusText.Color = ESP.TextColor
    
    local viewAngleLine = Drawing.new("Line")
    viewAngleLine.Visible = false
    viewAngleLine.Color = ESP.ViewAngleColor
    viewAngleLine.Thickness = ESP.ViewAngleThickness
    viewAngleLine.Transparency = 1
    
    -- Add 12 lines for 3D box
    local box3DLines = {}
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESP.BoxColor
        line.Thickness = ESP.BoxThickness
        line.Transparency = 1
        table.insert(box3DLines, line)
    end
    
    -- Add 12 lines for corners (3 lines per corner, 4 corners)
    local cornerLines = {}
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESP.BoxColor
        line.Thickness = ESP.BoxThickness
        line.Transparency = 1
        table.insert(cornerLines, line)
    end
    
    ESPObjects[player] = {
        boxOutline = boxOutline,
        box = espBox,
        healthBarOutline = healthBarOutline,
        healthBarBG = healthBarBG,
        healthBar = healthBar,
        skeletonLines = skeletonLines,
        headCircle = headCircle,
        distanceText = distanceText,
        healthText = healthText,
        nameText = nameText,
        toolText = toolText,
        viewAngleLine = viewAngleLine,
        statusText = statusText,
        box3DLines = box3DLines,
        cornerLines = cornerLines,  -- Add the new lines
    }
end

local function UpdateESPBox(player, espObjects)
    local boxOutline = espObjects.boxOutline
    local espBox = espObjects.box
    local healthBarOutline = espObjects.healthBarOutline
    local healthBarBG = espObjects.healthBarBG
    local healthBar = espObjects.healthBar
    local distanceText = espObjects.distanceText
    local healthText = espObjects.healthText
    local nameText = espObjects.nameText
    local toolText = espObjects.toolText
    local viewAngleLine = espObjects.viewAngleLine
    local statusText = espObjects.statusText
    
    local character = typeof(player) == "Instance" and 
        (player:IsA("Model") and player or player.Character) or 
        (player.Character or false)
    
    -- Check if this is the local player's character
    if (typeof(player) == "Instance" and player:IsA("Player") and player == LocalPlayer) or
       (typeof(player) == "Instance" and player:IsA("Model") and player == LocalPlayer.Character) then
        return
    end
    
    if not character or 
       not character:FindFirstChild("HumanoidRootPart") or 
       not character:FindFirstChild("Humanoid") or
       character:FindFirstChild("Humanoid").Health <= 0 then 
        boxOutline.Visible = false
        espBox.Visible = false
        healthBarOutline.Visible = false
        healthBarBG.Visible = false
        healthBar.Visible = false
        distanceText.Visible = false
        healthText.Visible = false
        nameText.Visible = false
        toolText.Visible = false
        viewAngleLine.Visible = false
        statusText.Visible = false
        for _, line in ipairs(espObjects.skeletonLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.headCircle) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.box3DLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.cornerLines) do
            line.Visible = false
        end
        return
    end
    
    if ESP.TeamCheck and typeof(player) == "Instance" and player:IsA("Player") and player.Team == LocalPlayer.Team then
        boxOutline.Visible = false
        espBox.Visible = false
        healthBarOutline.Visible = false
        healthBarBG.Visible = false
        healthBar.Visible = false
        distanceText.Visible = false
        healthText.Visible = false
        nameText.Visible = false
        toolText.Visible = false
        viewAngleLine.Visible = false
        statusText.Visible = false
        for _, line in ipairs(espObjects.skeletonLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.headCircle) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.box3DLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.cornerLines) do
            line.Visible = false
        end
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid
    local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    
    if onScreen and ESP.Enabled then
        local rootPosition = character.HumanoidRootPart.Position
        
        local distance = (Camera.CFrame.Position - rootPosition).Magnitude
        
        -- Adjust scale factor calculation for better distance scaling
        local scaleFactor = math.clamp(1 / (distance * 0.15), 0.4, 1.2) -- Increased minimum scale and adjusted multiplier
        
        local topPosition = rootPosition + Vector3.new(0, 3, 0)
        local bottomPosition = rootPosition - Vector3.new(0, 3, 0)
        
        local topPoint = Camera:WorldToViewportPoint(topPosition)
        local bottomPoint = Camera:WorldToViewportPoint(bottomPosition)
        
        local boxSize = math.abs(topPoint.Y - bottomPoint.Y)
        
        -- Set minimum box size to prevent tiny boxes at distance
        boxSize = math.max(boxSize, 20) -- Minimum box size of 20 pixels
        
        boxOutline.Size = Vector2.new(boxSize * 0.75, boxSize)
        boxOutline.Position = Vector2.new(vector.X - boxOutline.Size.X / 2, vector.Y - boxOutline.Size.Y / 2)
        boxOutline.Thickness = math.max(1, ESP.BoxThickness * scaleFactor + 2)
        boxOutline.Visible = ESP.BoxEnabled
        
        espBox.Size = boxOutline.Size
        espBox.Position = boxOutline.Position
        espBox.Thickness = math.max(1, ESP.BoxThickness * scaleFactor)
        espBox.Visible = ESP.BoxEnabled and not ESP.BoxCorners
        
        if ESP.HealthBar then
            -- Adjust health bar scaling with smaller width
            local healthBarWidth = math.max(2, 3 * scaleFactor) -- Reduced width and minimum size
            local healthPercentage = humanoid.Health / humanoid.MaxHealth
            local padding = math.max(1, 1.5 * scaleFactor) -- Reduced padding
            local spacing = math.max(3, 6 * scaleFactor) -- Reduced spacing
            
            healthBarOutline.Size = Vector2.new(healthBarWidth + padding, boxSize + padding)
            healthBarOutline.Position = Vector2.new(espBox.Position.X - healthBarWidth - spacing - padding/2, espBox.Position.Y - padding/2)
            healthBarOutline.Thickness = math.max(1, 1.5 * scaleFactor) -- Reduced outline thickness
            healthBarOutline.Visible = true
            
            healthBarBG.Size = Vector2.new(healthBarWidth, boxSize)
            healthBarBG.Position = Vector2.new(espBox.Position.X - healthBarWidth - spacing, espBox.Position.Y)
            healthBarBG.Visible = true
            
            healthBar.Size = Vector2.new(healthBarWidth, boxSize * healthPercentage)
            healthBar.Position = Vector2.new(espBox.Position.X - healthBarWidth - spacing, espBox.Position.Y + boxSize * (1 - healthPercentage))
            healthBar.Visible = true
            
            local healthColor = Color3.fromRGB(
                255 * (1 - healthPercentage),
                255 * healthPercentage,
                0
            )
            healthBar.Color = healthColor
        else
            healthBarOutline.Visible = false
            healthBarBG.Visible = false
            healthBar.Visible = false
        end
        
        if ESP.Skeleton then
            local skeletonLines = espObjects.skeletonLines
            local headCircle = espObjects.headCircle
            
            local function worldToScreen(part)
                local pos = Camera:WorldToViewportPoint(part.Position)
                return Vector2.new(pos.X, pos.Y), pos.Z
            end
            
            local isR15 = character:FindFirstChild("UpperTorso") ~= nil
            local lineIndex = 1
            
            if isR15 then
                local head = character:FindFirstChild("Head")
                local upperTorso = character:FindFirstChild("UpperTorso")
                local lowerTorso = character:FindFirstChild("LowerTorso")
                local leftUpperArm = character:FindFirstChild("LeftUpperArm")
                local leftLowerArm = character:FindFirstChild("LeftLowerArm")
                local leftHand = character:FindFirstChild("LeftHand")
                local rightUpperArm = character:FindFirstChild("RightUpperArm")
                local rightLowerArm = character:FindFirstChild("RightLowerArm")
                local rightHand = character:FindFirstChild("RightHand")
                local leftUpperLeg = character:FindFirstChild("LeftUpperLeg")
                local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
                local leftFoot = character:FindFirstChild("LeftFoot")
                local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
                local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
                local rightFoot = character:FindFirstChild("RightFoot")
                
                if head and upperTorso then
                    local headPos, headZ = worldToScreen(head)
                    local upperTorsoPos = worldToScreen(upperTorso)
                    local lowerTorsoPos = worldToScreen(lowerTorso)
                    
                    if headZ > 0 then
                        local scaledRadius = math.max(4, ESP.HeadCircleRadius * scaleFactor) -- Minimum radius of 4 pixels
                        for i = 1, ESP.HeadCirclePoints do
                            local angle = (i - 1) * (2 * math.pi / ESP.HeadCirclePoints)
                            local nextAngle = i * (2 * math.pi / ESP.HeadCirclePoints)
                            
                            local point1 = Vector2.new(
                                headPos.X + math.cos(angle) * scaledRadius,
                                headPos.Y + math.sin(angle) * scaledRadius
                            )
                            local point2 = Vector2.new(
                                headPos.X + math.cos(nextAngle) * scaledRadius,
                                headPos.Y + math.sin(nextAngle) * scaledRadius
                            )
                            
                            headCircle[i].From = point1
                            headCircle[i].To = point2
                            headCircle[i].Visible = true
                        end
                    end
                    
                    skeletonLines[lineIndex].From = headPos
                    skeletonLines[lineIndex].To = upperTorsoPos
                    skeletonLines[lineIndex].Visible = true
                    lineIndex = lineIndex + 1
                    
                    skeletonLines[lineIndex].From = upperTorsoPos
                    skeletonLines[lineIndex].To = lowerTorsoPos
                    skeletonLines[lineIndex].Visible = true
                    lineIndex = lineIndex + 1
                    
                    if leftUpperArm and leftLowerArm and leftHand then
                        local leftUpperArmPos = worldToScreen(leftUpperArm)
                        local leftLowerArmPos = worldToScreen(leftLowerArm)
                        local leftHandPos = worldToScreen(leftHand)
                        
                        skeletonLines[lineIndex].From = upperTorsoPos
                        skeletonLines[lineIndex].To = leftUpperArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = leftUpperArmPos
                        skeletonLines[lineIndex].To = leftLowerArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = leftLowerArmPos
                        skeletonLines[lineIndex].To = leftHandPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if rightUpperArm and rightLowerArm and rightHand then
                        local rightUpperArmPos = worldToScreen(rightUpperArm)
                        local rightLowerArmPos = worldToScreen(rightLowerArm)
                        local rightHandPos = worldToScreen(rightHand)
                        
                        skeletonLines[lineIndex].From = upperTorsoPos
                        skeletonLines[lineIndex].To = rightUpperArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = rightUpperArmPos
                        skeletonLines[lineIndex].To = rightLowerArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = rightLowerArmPos
                        skeletonLines[lineIndex].To = rightHandPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if leftUpperLeg and leftLowerLeg and leftFoot then
                        local leftUpperLegPos = worldToScreen(leftUpperLeg)
                        local leftLowerLegPos = worldToScreen(leftLowerLeg)
                        local leftFootPos = worldToScreen(leftFoot)
                        
                        skeletonLines[lineIndex].From = lowerTorsoPos
                        skeletonLines[lineIndex].To = leftUpperLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = leftUpperLegPos
                        skeletonLines[lineIndex].To = leftLowerLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = leftLowerLegPos
                        skeletonLines[lineIndex].To = leftFootPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if rightUpperLeg and rightLowerLeg and rightFoot then
                        local rightUpperLegPos = worldToScreen(rightUpperLeg)
                        local rightLowerLegPos = worldToScreen(rightLowerLeg)
                        local rightFootPos = worldToScreen(rightFoot)
                        
                        skeletonLines[lineIndex].From = lowerTorsoPos
                        skeletonLines[lineIndex].To = rightUpperLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = rightUpperLegPos
                        skeletonLines[lineIndex].To = rightLowerLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                        
                        skeletonLines[lineIndex].From = rightLowerLegPos
                        skeletonLines[lineIndex].To = rightFootPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                end
            else
                local head = character:FindFirstChild("Head")
                local torso = character:FindFirstChild("Torso")
                local leftArm = character:FindFirstChild("Left Arm")
                local rightArm = character:FindFirstChild("Right Arm")
                local leftLeg = character:FindFirstChild("Left Leg")
                local rightLeg = character:FindFirstChild("Right Leg")
                
                if head and torso then
                    local headPos, headZ = worldToScreen(head)
                    local torsoPos = worldToScreen(torso)
                    
                    if headZ > 0 then
                        local scaledRadius = math.max(4, ESP.HeadCircleRadius * scaleFactor) -- Minimum radius of 4 pixels
                        for i = 1, ESP.HeadCirclePoints do
                            local angle = (i - 1) * (2 * math.pi / ESP.HeadCirclePoints)
                            local nextAngle = i * (2 * math.pi / ESP.HeadCirclePoints)
                            
                            local point1 = Vector2.new(
                                headPos.X + math.cos(angle) * scaledRadius,
                                headPos.Y + math.sin(angle) * scaledRadius
                            )
                            local point2 = Vector2.new(
                                headPos.X + math.cos(nextAngle) * scaledRadius,
                                headPos.Y + math.sin(nextAngle) * scaledRadius
                            )
                            
                            headCircle[i].From = point1
                            headCircle[i].To = point2
                            headCircle[i].Visible = true
                        end
                    end
                    
                    skeletonLines[lineIndex].From = headPos
                    skeletonLines[lineIndex].To = torsoPos
                    skeletonLines[lineIndex].Visible = true
                    lineIndex = lineIndex + 1
                    
                    if leftArm then
                        local leftArmPos = worldToScreen(leftArm)
                        skeletonLines[lineIndex].From = torsoPos
                        skeletonLines[lineIndex].To = leftArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if rightArm then
                        local rightArmPos = worldToScreen(rightArm)
                        skeletonLines[lineIndex].From = torsoPos
                        skeletonLines[lineIndex].To = rightArmPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if leftLeg then
                        local leftLegPos = worldToScreen(leftLeg)
                        skeletonLines[lineIndex].From = torsoPos
                        skeletonLines[lineIndex].To = leftLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                    
                    if rightLeg then
                        local rightLegPos = worldToScreen(rightLeg)
                        skeletonLines[lineIndex].From = torsoPos
                        skeletonLines[lineIndex].To = rightLegPos
                        skeletonLines[lineIndex].Visible = true
                        lineIndex = lineIndex + 1
                    end
                end
            end
            
            for i = lineIndex, #skeletonLines do
                skeletonLines[i].Visible = false
            end
            
            if not (head and headZ > 0) then
                for i = 1, ESP.HeadCirclePoints do
                    headCircle[i].Visible = false
                end
            end
        else
            for _, line in ipairs(espObjects.skeletonLines) do
                line.Visible = false
            end
            for _, line in ipairs(espObjects.headCircle) do
                line.Visible = false
            end
        end
        
        if ESP.Box3D then
            local character = typeof(player) == "Instance" and 
                (player:IsA("Model") and player or player.Character) or 
                (player.Character or false)
            
            if character then
                local cframe = character.HumanoidRootPart.CFrame
                local size = Vector3.new(4, 5, 3)  -- Adjust size as needed
                
                local corners = {
                    cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                    cframe * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                    cframe * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                    cframe * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                    cframe * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                    cframe * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                    cframe * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                    cframe * CFrame.new(size.X/2, size.Y/2, size.Z/2)
                }
                
                local points = {}
                for _, corner in ipairs(corners) do
                    local point = Camera:WorldToViewportPoint(corner.Position)
                    table.insert(points, Vector2.new(point.X, point.Y))
                end
                
                -- Bottom square
                espObjects.box3DLines[1].From = points[1]
                espObjects.box3DLines[1].To = points[2]
                espObjects.box3DLines[2].From = points[2]
                espObjects.box3DLines[2].To = points[6]
                espObjects.box3DLines[3].From = points[6]
                espObjects.box3DLines[3].To = points[5]
                espObjects.box3DLines[4].From = points[5]
                espObjects.box3DLines[4].To = points[1]
                
                -- Top square
                espObjects.box3DLines[5].From = points[3]
                espObjects.box3DLines[5].To = points[4]
                espObjects.box3DLines[6].From = points[4]
                espObjects.box3DLines[6].To = points[8]
                espObjects.box3DLines[7].From = points[8]
                espObjects.box3DLines[7].To = points[7]
                espObjects.box3DLines[8].From = points[7]
                espObjects.box3DLines[8].To = points[3]
                
                -- Vertical lines
                espObjects.box3DLines[9].From = points[1]
                espObjects.box3DLines[9].To = points[3]
                espObjects.box3DLines[10].From = points[2]
                espObjects.box3DLines[10].To = points[4]
                espObjects.box3DLines[11].From = points[6]
                espObjects.box3DLines[11].To = points[8]
                espObjects.box3DLines[12].From = points[5]
                espObjects.box3DLines[12].To = points[7]
                
                for i = 1, 12 do
                    espObjects.box3DLines[i].Visible = true
                    espObjects.box3DLines[i].Color = ESP.BoxColor
                    espObjects.box3DLines[i].Thickness = math.max(1, ESP.BoxThickness * scaleFactor)
                end
            end
        else
            for _, line in ipairs(espObjects.box3DLines) do
                line.Visible = false
            end
        end
        
        if ESP.BoxCorners then
            local cornerSize = ESP.CornerSize * scaleFactor
            local box = espBox
            local pos = box.Position
            local size = box.Size
            
            -- Top Left
            espObjects.cornerLines[1].From = pos
            espObjects.cornerLines[1].To = pos + Vector2.new(cornerSize, 0)
            espObjects.cornerLines[2].From = pos
            espObjects.cornerLines[2].To = pos + Vector2.new(0, cornerSize)
            
            -- Top Right
            espObjects.cornerLines[3].From = pos + Vector2.new(size.X, 0)
            espObjects.cornerLines[3].To = pos + Vector2.new(size.X - cornerSize, 0)
            espObjects.cornerLines[4].From = pos + Vector2.new(size.X, 0)
            espObjects.cornerLines[4].To = pos + Vector2.new(size.X, cornerSize)
            
            -- Bottom Left
            espObjects.cornerLines[5].From = pos + Vector2.new(0, size.Y)
            espObjects.cornerLines[5].To = pos + Vector2.new(cornerSize, size.Y)
            espObjects.cornerLines[6].From = pos + Vector2.new(0, size.Y)
            espObjects.cornerLines[6].To = pos + Vector2.new(0, size.Y - cornerSize)
            
            -- Bottom Right
            espObjects.cornerLines[7].From = pos + size
            espObjects.cornerLines[7].To = pos + size - Vector2.new(cornerSize, 0)
            espObjects.cornerLines[8].From = pos + size
            espObjects.cornerLines[8].To = pos + size - Vector2.new(0, cornerSize)
            
            -- Make all corner lines visible and set properties
            for i = 1, 8 do
                espObjects.cornerLines[i].Visible = true
                espObjects.cornerLines[i].Color = ESP.BoxColor
                espObjects.cornerLines[i].Thickness = math.max(1, ESP.BoxThickness * scaleFactor)
            end
            
            -- Hide the regular box if corners are enabled
            espBox.Visible = false
            boxOutline.Visible = false
        else
            -- Hide corner lines and show regular box
            for _, line in ipairs(espObjects.cornerLines) do
                line.Visible = false
            end
            espBox.Visible = true
            boxOutline.Visible = true
        end
        
        -- Adjust text scaling
        local textScale = math.max(
            ESP.TextSize * 0.6, -- Minimum text size
            math.min(ESP.TextSize, ESP.TextSize * scaleFactor) -- Maximum text size
        )
        
        -- Adjust spacing between text elements
        local textSpacing = math.max(12, 15 * scaleFactor) -- Minimum spacing of 12 pixels
        
        if ESP.ShowDistance then
            local distance = math.floor((Camera.CFrame.Position - rootPosition).Magnitude)
            distanceText.Text = tostring(distance) .. " studs"
            distanceText.Position = Vector2.new(
                boxOutline.Position.X + boxOutline.Size.X/2, 
                boxOutline.Position.Y + boxOutline.Size.Y + textSpacing
            )
            distanceText.Size = textScale
            distanceText.Visible = true
        else
            distanceText.Visible = false
        end
        
        if ESP.ShowHealth then
            local health = math.floor(humanoid.Health)
            local maxHealth = math.floor(humanoid.MaxHealth)
            healthText.Text = tostring(health) .. "/" .. tostring(maxHealth)
            healthText.Position = Vector2.new(
                boxOutline.Position.X + boxOutline.Size.X/2, 
                boxOutline.Position.Y - textSpacing - textSpacing
            )
            healthText.Size = textScale
            healthText.Visible = true
        else
            healthText.Visible = false
        end
        
        if ESP.ShowName then
            nameText.Text = player.Name
            nameText.Position = Vector2.new(
                boxOutline.Position.X + boxOutline.Size.X/2, 
                boxOutline.Position.Y - textSpacing * 3
            )
            nameText.Size = textScale
            nameText.Visible = true
        else
            nameText.Visible = false
        end
        
        if ESP.ShowTool then
            local tool = character:FindFirstChildOfClass("Tool")
            toolText.Text = tool and tool.Name or "None"
            toolText.Position = Vector2.new(
                boxOutline.Position.X + boxOutline.Size.X/2, 
                boxOutline.Position.Y + boxOutline.Size.Y + textSpacing * 2
            )
            toolText.Size = textScale
            toolText.Visible = true
        else
            toolText.Visible = false
        end
        
        if ESP.ShowViewAngle then
            local head = character:FindFirstChild("Head")
            if head then
                local headCFrame = head.CFrame
                local forwardVector = headCFrame.LookVector * ESP.ViewAngleLength
                local endPoint = headCFrame.Position + forwardVector
                local startPoint = Camera:WorldToViewportPoint(headCFrame.Position)
                local endPoint = Camera:WorldToViewportPoint(endPoint)
                
                viewAngleLine.From = Vector2.new(startPoint.X, startPoint.Y)
                viewAngleLine.To = Vector2.new(endPoint.X, endPoint.Y)
                viewAngleLine.Visible = true
            else
                viewAngleLine.Visible = false
            end
        else
            viewAngleLine.Visible = false
        end
        
        if ESP.ShowStatus then
            local velocity = humanoidRootPart.Velocity
            local speed = (velocity * Vector3.new(1, 0, 1)).Magnitude
            
            local status = speed > ESP.MovementThreshold and ESP.StatusMovingText or ESP.StatusIdleText
            statusText.Text = status
            statusText.Position = Vector2.new(
                boxOutline.Position.X + boxOutline.Size.X/2, 
                boxOutline.Position.Y + boxOutline.Size.Y + textSpacing * 3
            )
            statusText.Size = textScale
            statusText.Visible = true
        else
            statusText.Visible = false
        end
    else
        boxOutline.Visible = false
        espBox.Visible = false
        healthBarOutline.Visible = false
        healthBarBG.Visible = false
        healthBar.Visible = false
        distanceText.Visible = false
        healthText.Visible = false
        nameText.Visible = false
        toolText.Visible = false
        viewAngleLine.Visible = false
        statusText.Visible = false
        for _, line in ipairs(espObjects.skeletonLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.headCircle) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.box3DLines) do
            line.Visible = false
        end
        for _, line in ipairs(espObjects.cornerLines) do
            line.Visible = false
        end
    end
end

-- Clear existing ESPs
for player, objects in pairs(ESPObjects) do
    for _, object in pairs(objects) do
        if typeof(object) == "table" then
            for _, line in ipairs(object) do
                line:Remove()
            end
        else
            object:Remove()
        end
    end
    ESPObjects[player] = nil
end

-- Modify the initialization section to only handle PlayersFolder if it exists
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPBox(player)
    end
end

if UseCustomCharacters then
    for _, model in ipairs(PlayersFolder:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            CreateESPBox(model)
        end
    end
    
    -- Handle custom players folder events
    PlayersFolder.ChildAdded:Connect(function(model)
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            CreateESPBox(model)
        end
    end)
    
    PlayersFolder.ChildRemoved:Connect(function(model)
        if ESPObjects[model] then
            for _, object in pairs(ESPObjects[model]) do
                if typeof(object) == "table" then
                    for _, line in ipairs(object) do
                        line:Remove()
                    end
                else
                    object:Remove()
                end
            end
            ESPObjects[model] = nil
        end
    end)
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESPBox(player)
    end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, object in pairs(ESPObjects[player]) do
            if typeof(object) == "table" then
                for _, line in ipairs(object) do
                    line:Remove()
                end
            else
                object:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end)

-- Handle character changes (respawning)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if player ~= LocalPlayer and ESPObjects[player] then
            character:WaitForChild("Humanoid")
            character:WaitForChild("HumanoidRootPart")
        end
    end)
end)

-- Handle existing players' character changes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            if ESPObjects[player] then
                character:WaitForChild("Humanoid")
                character:WaitForChild("HumanoidRootPart")
            end
        end)
    end
end

RunService.RenderStepped:Connect(function()
    for player, espObjects in pairs(ESPObjects) do
        UpdateESPBox(player, espObjects)
    end
end)
