local espLibrary = {
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {
        enabled = true,
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        scaleFactorX = 5,
        scaleFactorY = 6,
        boundingBox = false, -- WARNING | Significant Performance Decrease when true
        boundingBoxDescending = true,
        excludedPartNames = {},
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        teamCheck = false,
        teamColor = false,
        useCustomTeamColor = false,
        customteamColor = Color3.new(1,1,1),
        fillColor = nil,
        whitelistColor = Color3.new(1, 0, 0),
        outOfViewArrows = true,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsColor = Color3.new(1, 1, 1),
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = true,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = true,
        nameTransparency = 1,
        nameColor = Color3.new(1, 1, 1),
        boxes = true,
        boxesTransparency = 1,
        boxesColor = Color3.new(1, 0, 0),
        boxFill = false,
        boxFillTransparency = 0.5,
        boxFillColor = Color3.new(1, 0, 0),
        healthBars = true,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.new(0, 1, 0),
        healthText = true,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        healthTextColor = Color3.new(1, 1, 1),
        distance = true,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        distanceColor = Color3.new(1, 1, 1),
        tool = false,
        toolTransparency = 1,
        toolColor = Color3.new(1,1,1),
        tracers = false,
        tracerTransparency = 1,
        tracerColor = Color3.new(1, 1, 1),
        tracerOrigin = "Bottom", -- Available [Mouse, Top, Bottom]
        chams = true,
        chamsFillColor = Color3.new(1, 0, 0),
        chamsFillTransparency = 0.5,
        chamsOutlineColor = Color3.new(),
        chamsOutlineTransparency = 0
    },
  };
  espLibrary.__index = espLibrary;
  
  -- variables
  local getService = game.GetService;
  local instanceNew = Instance.new;
  local drawingNew = Drawing.new;
  local vector2New = Vector2.new;
  local vector3New = Vector3.new;
  local cframeNew = CFrame.new;
  local color3New = Color3.new;
  local raycastParamsNew = RaycastParams.new;
  local abs = math.abs;
  local tan = math.tan;
  local rad = math.rad;
  local clamp = math.clamp;
  local floor = math.floor;
  local find = table.find;
  local insert = table.insert;
  local findFirstChild = game.FindFirstChild;
  local findFirstChildOfClass = game.FindFirstChildOfClass;
  local getChildren = game.GetChildren;
  local getDescendants = game.GetDescendants;
  local isA = workspace.IsA;
  local raycast = workspace.Raycast;
  local emptyCFrame = cframeNew();
  local pointToObjectSpace = emptyCFrame.PointToObjectSpace;
  local getComponents = emptyCFrame.GetComponents;
  local cross = vector3New().Cross;
  local inf = 1 / 0;
  
  -- services
  local workspace = getService(game, "Workspace");
  local runService = getService(game, "RunService");
  local players = getService(game, "Players");
  local coreGui = getService(game, "CoreGui");
  local userInputService = getService(game, "UserInputService");
  
  -- cache
  local currentCamera = workspace.CurrentCamera;
  local localPlayer = players.LocalPlayer;
  local screenGui = instanceNew("ScreenGui", coreGui);
  local lastFov, lastScale;
  
  -- instance functions
  local wtvp = currentCamera.WorldToViewportPoint;
  
  -- Support Functions
  local function isDrawing(type)
    return type == "Square" or type == "Text" or type == "Triangle" or type == "Image" or type == "Line" or type == "Circle";
  end
  
  -- Add cached functions and values at the top
  local lower = string.lower
  local find = string.find
  local remove = table.remove
  local create = Drawing.new
  local destroy = Drawing.remove
  local clear = table.clear
  local HUGE = math.huge
  local Vector2New = Vector2.new
  local Vector3New = Vector3.new
  local Color3New = Color3.new
  
  -- Add object pool
  local drawingPool = {
      Square = {},
      Text = {},
      Triangle = {},
      Line = {},
      Circle = {}
  }
  
  -- Add pooling functions
  local function getDrawing(type)
      local pool = drawingPool[type]
      return #pool > 0 and remove(pool) or create(type)
  end
  
  local function releaseDrawing(drawing, type)
      drawing.Visible = false
      insert(drawingPool[type], drawing)
  end
  
  -- Optimize create function
  function espLibrary.getCharacter(player)
    local cache = characterCache[player]
    if cache then
        if cache.character.Parent then
            return cache.character, cache.torso
        else
            characterCache[player] = nil
        end
    end
    
    local character = player.Character
    if not character then return nil, nil end
    
    local torso = character:FindFirstChild("HumanoidRootPart") or
                  character:FindFirstChild("UpperTorso") or
                  character:FindFirstChild("Torso")
                  
    if torso then
        characterCache[player] = {
            character = character,
            torso = torso
        }
        return character, torso
    end
    
    return nil, nil
  end
  
  -- Optimize visible check with ray caching
  local rayParams = raycastParamsNew()
  rayParams.FilterType = Enum.RaycastFilterType.Blacklist
  rayParams.IgnoreWater = true
  
  function espLibrary.visibleCheck(character, position)
    local origin = currentCamera.CFrame.Position
    local direction = (position - origin).Unit
    
    rayParams.FilterDescendantsInstances = {
        espLibrary.getCharacter(localPlayer),
        currentCamera,
        character
    }
    
    local result = raycast(workspace, origin, direction * 1000, rayParams)
    return not result
  end
  
  -- Optimize render loop
  local lastUpdate = 0
  local UPDATE_INTERVAL = 1/60 -- 60fps max
  
  -- Main Functions
  function espLibrary.getTeam(player)
    local team = player.Team;
    return team, player.TeamColor.Color;
  end
  
  function espLibrary.getTool(player)
    local character = player.Character;
    return findFirstChildOfClass(character, "Tool") ~= nil and tostring(findFirstChildOfClass(character, "Tool")) or findFirstChildOfClass(character, "Tool") == nil and "None"
  end
  
  function espLibrary.getBoundingBox(character, torso)
    if (espLibrary.options.boundingBox) then
        local minX, minY, minZ = inf, inf, inf;
        local maxX, maxY, maxZ = -inf, -inf, -inf;
  
        for _, part in next, espLibrary.options.boundingBoxDescending and getDescendants(character) or getChildren(character) do
            if (isA(part, "BasePart") and not find(espLibrary.options.excludedPartNames, part.Name)) then
                local size = part.Size;
                local sizeX, sizeY, sizeZ = size.X, size.Y, size.Z;
  
                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = getComponents(part.CFrame);
  
                local wiseX = 0.5 * (abs(r00) * sizeX + abs(r01) * sizeY + abs(r02) * sizeZ);
                local wiseY = 0.5 * (abs(r10) * sizeX + abs(r11) * sizeY + abs(r12) * sizeZ);
                local wiseZ = 0.5 * (abs(r20) * sizeX + abs(r21) * sizeY + abs(r22) * sizeZ);
  
                minX = minX > x - wiseX and x - wiseX or minX;
                minY = minY > y - wiseY and y - wiseY or minY;
                minZ = minZ > z - wiseZ and z - wiseZ or minZ;
  
                maxX = maxX < x + wiseX and x + wiseX or maxX;
                maxY = maxY < y + wiseY and y + wiseY or maxY;
                maxZ = maxZ < z + wiseZ and z + wiseZ or maxZ;
            end
        end
  
        local oMin, oMax = vector3New(minX, minY, minZ), vector3New(maxX, maxY, maxZ);
        return (oMax + oMin) * 0.5, oMax - oMin;
    else
        return torso.Position, vector2New(espLibrary.options.scaleFactorX, espLibrary.options.scaleFactorY);
    end
  end
  
  function espLibrary.getScaleFactor(fov, depth)
    if (fov ~= lastFov) then
        lastScale = tan(rad(fov * 0.5)) * 2;
        lastFov = fov;
    end
  
    return 1 / (depth * lastScale) * 1000;
  end
  
  function espLibrary.getBoxData(position, size)
    local torsoPosition, onScreen, depth = worldToViewportPoint(position);
    local scaleFactor = espLibrary.getScaleFactor(currentCamera.FieldOfView, depth);
  
    local clampX = clamp(size.X, espLibrary.options.minScaleFactorX, espLibrary.options.maxScaleFactorX);
    local clampY = clamp(size.Y, espLibrary.options.minScaleFactorY, espLibrary.options.maxScaleFactorY);
    local size = round(vector2New(clampX * scaleFactor, clampY * scaleFactor));
  
    return onScreen, size, round(vector2New(torsoPosition.X - (size.X * 0.5), torsoPosition.Y - (size.Y * 0.5))), torsoPosition;
  end
  
  function espLibrary.getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");
  
    if (humanoid) then
        return math.floor(humanoid.Health), humanoid.MaxHealth;
    end
  
    return 100, 100;
  end
  
  function espLibrary.addEsp(player)
    if (player == localPlayer) then
        return
    end
  
    local objects = {
        arrow = create("Triangle", {
            Thickness = 1,
        }),
        arrowOutline = create("Triangle", {
            Thickness = 1,
        }),
        bottom = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        tool = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        top = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        side = create("Text", {
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Color = color3New()
        }),
        box = create("Square", {
            Thickness = 1
        }),
        healthBarOutline = create("Square", {
            Thickness = 1,
            Color = color3New(),
            Filled = true
        }),
        healthBar = create("Square", {
            Thickness = 1,
            Filled = true
        }),
        lineoutline = create("Line", {Thickness = 3}),
        line = create("Line", {Thickness = 1})
    };
  
    espLibrary.espCache[player] = objects;
  end
  
  function espLibrary.removeEsp(player)
    local espCache = espLibrary.espCache[player];
  
    if (espCache) then
        espLibrary.espCache[player] = nil;
  
        for index, object in next, espCache do
            espCache[index] = nil;
            object:Remove();
        end
    end
  end
  
  function espLibrary.addChams(player)
    if (player == localPlayer) then
        return
    end
  
    espLibrary.chamsCache[player] = create("Highlight", {
        Parent = screenGui,
    });
  end
  
  function espLibrary.removeChams(player)
    local highlight = espLibrary.chamsCache[player];
  
    if (highlight) then
        espLibrary.chamsCache[player] = nil;
        highlight:Destroy();
    end
  end
  
  function espLibrary.addObject(object, options)
    espLibrary.objectCache[object] = {
        options = options,
        text = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        })
    };
  end
  
  function espLibrary.removeObject(object)
    local cache = espLibrary.objectCache[object];
  
    if (cache) then
        espLibrary.objectCache[object] = nil;
        cache.text:Remove();
    end
  end
  
  function espLibrary:AddObjectEsp(object, defaultOptions)
    assert(object and object.Parent, "invalid object passed");
  
    local options = defaultOptions or {};
  
    options.enabled = options.enabled or true;
    options.limitDistance = options.limitDistance or false;
    options.maxDistance = options.maxDistance or false;
    options.visibleOnly = options.visibleOnly or false;
    options.color = options.color or color3New(1, 1, 1);
    options.transparency = options.transparency or 1;
    options.text = options.text or object.Name;
    options.font = options.font or 2;
    options.fontSize = options.fontSize or 13;
  
    self.addObject(object, options);
  
    insert(self.conns, object.Parent.ChildRemoved:Connect(function(child)
        if (child == object) then
            self.removeObject(child);
        end
    end));
  
    return options;
  end
  
  function espLibrary:Unload()
    for _, connection in next, self.conns do
        connection:Disconnect();
    end
  
    for _, player in next, players:GetPlayers() do
        self.removeEsp(player);
        self.removeChams(player);
    end
  
    for object, _ in next, self.objectCache do
        self.removeObject(object);
    end
  
    for _, object in next, self.instances do
        object:Destroy();
    end
  
    screenGui:Destroy();
    runService:UnbindFromRenderStep("esp_rendering");
    
    -- Clear caches
    clear(characterCache)
    clear(drawingPool)
    
    for _, pool in next, drawingPool do
        for _, drawing in next, pool do
            drawing:Remove()
        end
        clear(pool)
    end
  end
  
  function espLibrary:Load(renderValue)
    insert(self.conns, players.PlayerAdded:Connect(function(player)
        self.addEsp(player);
        self.addChams(player);
    end));
  
    insert(self.conns, players.PlayerRemoving:Connect(function(player)
        self.removeEsp(player);
        self.removeChams(player);
    end));
  
    for _, player in next, players:GetPlayers() do
        self.addEsp(player);
        self.addChams(player);
    end
  
    runService:BindToRenderStep("esp_rendering", renderValue or (Enum.RenderPriority.Camera.Value + 1), function()
        local now = tick()
        if now - lastUpdate < UPDATE_INTERVAL then return end
        lastUpdate = now
        
        -- Cache viewport size
        local viewportSize = currentCamera.ViewportSize
        local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2)
        
        -- Update ESP
        for player, objects in next, self.espCache do
            local character, torso = self.getCharacter(player)
            if not (character and torso) then
                -- Hide all objects if character invalid
                for _, object in next, objects do
                    object.Visible = false
                end
                continue
            end
            
            local onScreen, size, position, torsoPosition = self.getBoxData(torso.Position, Vector3.new(5, 6.5));
            local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
            local canShow, enabled = onScreen and (size and position), self.options.enabled;
            local team, teamColor = self.getTeam(player);
            local color = self.options.teamColor and teamColor or nil;
            local tool = self.getTool(player)

            if self.options.useCustomTeamColor and self.options.teamColor then
                color = self.options.customteamColor
            end
    
            if (self.options.fillColor ~= nil) then
                color = self.options.fillColor;
            end
    
            if (find(self.whitelist, player.Name)) then
                color = self.options.whitelistColor;
            end
    
            if (find(self.blacklist, player.Name)) then
                enabled = false;
            end
    
            if (self.options.limitDistance and distance > self.options.maxDistance) then
                enabled = false;
            end
    
            if (self.options.visibleOnly and not self.visibleCheck(character, torso.Position)) then
                enabled = false;
            end
    
            if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                enabled = false;
            end
    
            local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit;
            local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
            local rightVector = vector2New(crossVector.X, crossVector.Z);
    
            local arrowRadius, arrowSize = self.options.outOfViewArrowsRadius, self.options.outOfViewArrowsSize;
            local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
            local arrowDirection = (arrowPosition - screenCenter).Unit;
    
            local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;
    
            local health, maxHealth = self.getHealth(player, character);
            local healthBarSize = round(vector2New(self.options.healthBarsSize, -(size.Y * (health / maxHealth))));
            local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y));
    
            local origin = self.options.tracerOrigin;
            local show = canShow and enabled;
    
            objects.arrow.Visible = (not canShow and enabled) and self.options.outOfViewArrows;
            objects.arrow.Filled = self.options.outOfViewArrowsFilled;
            objects.arrow.Transparency = self.options.outOfViewArrowsTransparency;
            objects.arrow.Color = color or self.options.outOfViewArrowsColor;
            objects.arrow.PointA = pointA;
            objects.arrow.PointB = pointB;
            objects.arrow.PointC = pointC;
    
            objects.arrowOutline.Visible = (not canShow and enabled) and self.options.outOfViewArrowsOutline;
            objects.arrowOutline.Filled = self.options.outOfViewArrowsOutlineFilled;
            objects.arrowOutline.Transparency = self.options.outOfViewArrowsOutlineTransparency;
            objects.arrowOutline.Color = color or self.options.outOfViewArrowsOutlineColor;
            objects.arrowOutline.PointA = pointA;
            objects.arrowOutline.PointB = pointB;
            objects.arrowOutline.PointC = pointC;
    
            objects.top.Visible = show and self.options.names;
            objects.top.Font = self.options.font;
            objects.top.Size = self.options.fontSize;
            objects.top.Transparency = self.options.nameTransparency;
            objects.top.Color = color or self.options.nameColor;
            objects.top.Text = player.Name;
            objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)));
    
            objects.side.Visible = show and self.options.healthText;
            objects.side.Font = self.options.font;
            objects.side.Size = self.options.fontSize;
            objects.side.Transparency = self.options.healthTextTransparency;
            objects.side.Color = color or self.options.healthTextColor;
            objects.side.Text = health .. self.options.healthTextSuffix;
            objects.side.Position = round(position + vector2New(size.X + 3, -3));

            objects.tool.Visible = show and self.options.tool and tool ~= "None";
            objects.tool.Font = self.options.font;
            objects.tool.Size = self.options.fontSize;
            objects.tool.Transparency = self.options.toolTransparency;
            objects.tool.Color = color or self.options.toolColor;
            objects.tool.Text = tostring(tool);
            objects.tool.Position = round(position + vector2New(size.X * 0.5, size.Y + 1));
    
            local Distance_Offset = objects.tool.Visible and 13 or 2

            objects.bottom.Visible = show and self.options.distance;
            objects.bottom.Font = self.options.font;
            objects.bottom.Size = self.options.fontSize;
            objects.bottom.Transparency = self.options.distanceTransparency;
            objects.bottom.Color = color or self.options.distanceColor;
            objects.bottom.Text = tostring(round(distance)) .. self.options.distanceSuffix;
            objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + Distance_Offset));
    
            objects.box.Visible = show and self.options.boxes;
            objects.box.Color = color or self.options.boxesColor;
            objects.box.Transparency = self.options.boxesTransparency;
            objects.box.Size = size;
            objects.box.Position = position;
    
            objects.boxOutline.Visible = show and self.options.boxes;
            objects.boxOutline.Transparency = self.options.boxesTransparency;
            objects.boxOutline.Size = size;
            objects.boxOutline.Position = position;
    
            objects.boxFill.Visible = show and self.options.boxFill;
            objects.boxFill.Color = color or self.options.boxFillColor;
            objects.boxFill.Transparency = self.options.boxFillTransparency;
            objects.boxFill.Size = size;
            objects.boxFill.Position = position;
    
            objects.healthBar.Visible = show and self.options.healthBars;
            objects.healthBar.Color = self.options.healthBarsColor;
            objects.healthBar.Transparency = self.options.healthBarsTransparency;
            objects.healthBar.Size = healthBarSize;
            objects.healthBar.Position = healthBarPosition;
    
            objects.healthBarOutline.Visible = show and self.options.healthBars;
            objects.healthBarOutline.Transparency = self.options.healthBarsTransparency;
            objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2));
            objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1);
    
            objects.line.Visible = show and self.options.tracers;
            objects.line.Color = color or self.options.tracerColor;
            objects.line.Transparency = self.options.tracerTransparency;
            objects.line.From =
                origin == "Mouse" and userInputService:GetMouseLocation() or
                origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
            objects.line.To = torsoPosition;
            objects.lineoutline.Visible = show and self.options.tracers;
            objects.lineoutline.Color = Color3.new(0,0,0)
            objects.lineoutline.Transparency = self.options.tracerTransparency;
            objects.lineoutline.From =
                origin == "Mouse" and userInputService:GetMouseLocation() or
                origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
                objects.lineoutline.To = torsoPosition;
        end
  
        for player, highlight in next, self.chamsCache do
            local character, torso = self.getCharacter(player);
  
            if (character and torso) then
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow = self.options.enabled and self.options.chams;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if self.options.useCustomTeamColor and self.options.teamColor then
                    color = self.options.customteamColor
                end
  
                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end
  
                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end
  
                if (find(self.blacklist, player.Name)) then
                    canShow = false;
                end
  
                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    canShow = false;
                end
  
                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    canShow = false;
                end
  
                highlight.Enabled = canShow;
                highlight.DepthMode = self.options.visibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop;
                highlight.Adornee = character;
                highlight.FillColor = color or self.options.chamsFillColor;
                highlight.FillTransparency = self.options.chamsFillTransparency;
                highlight.OutlineColor = color or self.options.chamsOutlineColor;
                highlight.OutlineTransparency = self.options.chamsOutlineTransparency;
            end
        end
  
        for object, cache in next, self.objectCache do
            local partPosition = vector3New();
  
            if (object:IsA("BasePart")) then
                partPosition = object.Position;
            elseif (object:IsA("Model")) then
                partPosition = self.getBoundingBox(object);
            end
  
            local distance = (currentCamera.CFrame.Position - partPosition).Magnitude;
            local screenPosition, onScreen = worldToViewportPoint(partPosition);
            local canShow = cache.options.enabled and onScreen;
  
            if (self.options.limitDistance and distance > self.options.maxDistance) then
                canShow = false;
            end
  
            if (self.options.visibleOnly and not self.visibleCheck(object, partPosition)) then
                canShow = false;
            end
  
            cache.text.Visible = canShow;
            cache.text.Font = cache.options.font;
            cache.text.Size = cache.options.fontSize;
            cache.text.Transparency = cache.options.transparency;
            cache.text.Color = cache.options.color;
            cache.text.Text = cache.options.text;
            cache.text.Position = round(screenPosition);
        end
    end);
  end

  return espLibrary;
