local espLibrary = {
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, 
    blacklist = {},
    options = {
        enabled = true,
        
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        scaleFactorX = 5,
        scaleFactorY = 6,

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
  
  -- Add object pooling system at the top
  local drawingPool = {
    Square = {},
    Text = {},
    Triangle = {},
    Line = {},
    Circle = {}
  }

  local function getFromPool(type)
    local pool = drawingPool[type]
    if pool and #pool > 0 then
        return table.remove(pool)
    end
    return drawingNew(type)
  end

  local function returnToPool(object)
    if isDrawing(object.ClassName) then
        object.Visible = false
        table.insert(drawingPool[object.ClassName], object)
    end
  end
  
  -- Optimize create function
  local function create(type, properties)
    local drawing = isDrawing(type)
    local object = drawing and getFromPool(type) or instanceNew(type)

    if properties then
        for i,v in next, properties do
            object[i] = v
        end
    end

    if not drawing then
        insert(espLibrary.instances, object)
    end

    return object
  end
  
  local function worldToViewportPoint(position)
    local screenPosition, onScreen = wtvp(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
  end
  
  local function round(number)
    return typeof(number) == "Vector2" and vector2New(round(number.X), round(number.Y)) or floor(number);
  end
  
  -- Main Functions
  function espLibrary.getTeam(player)
    local team = player.Team;
    return team, player.TeamColor.Color;
  end
  
  -- Cache frequently accessed values
  local cachedPlayers = {}
  local cachedCharacters = {}
  local updateTick = 0
  
  -- Optimize getCharacter with caching
  function espLibrary.getCharacter(player)
    -- Only update cache every 10 frames
    if updateTick % 10 == 0 then
        local character = player.Character
        if character then
            cachedCharacters[player] = {
                character = character,
                torso = character:FindFirstChild("HumanoidRootPart") or 
                        character:FindFirstChild("UpperTorso") or
                        character:FindFirstChild("Torso")
            }
        else
            cachedCharacters[player] = nil
        end
    end
    
    local cached = cachedCharacters[player]
    return cached and cached.character, cached and cached.torso
  end

  function espLibrary.getTool(player)
    local character = player.Character;
    return findFirstChildOfClass(character, "Tool") ~= nil and tostring(findFirstChildOfClass(character, "Tool")) or findFirstChildOfClass(character, "Tool") == nil and "None"
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
  
  function espLibrary.visibleCheck(character, position)
    local origin = currentCamera.CFrame.Position;
    local params = raycastParamsNew();
  
    params.FilterDescendantsInstances = { espLibrary.getCharacter(localPlayer), currentCamera, character };
    params.FilterType = Enum.RaycastFilterType.Blacklist;
    params.IgnoreWater = true;
  
    return (not raycast(workspace, origin, position - origin, params));
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
  
  -- Optimize removeEsp to use object pooling
  function espLibrary.removeEsp(player)
    local espCache = espLibrary.espCache[player]

    if espCache then
        espLibrary.espCache[player] = nil

        for _, object in next, espCache do
            if isDrawing(object.ClassName) then
                returnToPool(object)
            else
                object:Remove()
            end
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
  
  -- Optimize render loop
  local function updateESP()
    updateTick = updateTick + 1
    
    -- Cache viewport size
    local viewportSize = currentCamera.ViewportSize
    local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2)

    -- Update ESP
    for player, objects in next, espLibrary.espCache do
        local character, torso = espLibrary.getCharacter(player)
        
        if not (character and torso) then
            -- Hide all objects if character invalid
            for _, object in next, objects do
                object.Visible = false
            end
            continue
        end

        local onScreen, size, position, torsoPosition = espLibrary.getBoxData(torso.Position, Vector3.new(5, 6.5));
        local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
        local canShow, enabled = onScreen and (size and position), espLibrary.options.enabled;
        local team, teamColor = espLibrary.getTeam(player);
        local color = espLibrary.options.teamColor and teamColor or nil;
        local tool = espLibrary.getTool(player)

        if espLibrary.options.useCustomTeamColor and espLibrary.options.teamColor then
            color = espLibrary.options.customteamColor
        end

        if (espLibrary.options.fillColor ~= nil) then
            color = espLibrary.options.fillColor;
        end

        if (find(espLibrary.whitelist, player.Name)) then
            color = espLibrary.options.whitelistColor;
        end

        if (find(espLibrary.blacklist, player.Name)) then
            enabled = false;
        end

        if (espLibrary.options.limitDistance and distance > espLibrary.options.maxDistance) then
            enabled = false;
        end

        if (espLibrary.options.visibleOnly and not espLibrary.visibleCheck(character, torso.Position)) then
            enabled = false;
        end

        if (espLibrary.options.teamCheck and (team == espLibrary.getTeam(localPlayer))) then
            enabled = false;
        end

        local viewportSize = currentCamera.ViewportSize;

        local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2);
        local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit;
        local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
        local rightVector = vector2New(crossVector.X, crossVector.Z);

        local health, maxHealth = espLibrary.getHealth(player, character);
        local healthBarSize = round(vector2New(espLibrary.options.healthBarsSize, -(size.Y * (health / maxHealth))));
        local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y));

        local origin = espLibrary.options.tracerOrigin;
        local show = canShow and enabled;

        objects.top.Visible = show and espLibrary.options.names;
        objects.top.Font = espLibrary.options.font;
        objects.top.Size = espLibrary.options.fontSize;
        objects.top.Transparency = espLibrary.options.nameTransparency;
        objects.top.Color = color or espLibrary.options.nameColor;
        objects.top.Text = player.Name;
        objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)));

        objects.side.Visible = show and espLibrary.options.healthText;
        objects.side.Font = espLibrary.options.font;
        objects.side.Size = espLibrary.options.fontSize;
        objects.side.Transparency = espLibrary.options.healthTextTransparency;
        objects.side.Color = color or espLibrary.options.healthTextColor;
        objects.side.Text = health .. espLibrary.options.healthTextSuffix;
        objects.side.Position = round(position + vector2New(size.X + 3, -3));

        objects.tool.Visible = show and espLibrary.options.tool and tool ~= "None";
        objects.tool.Font = espLibrary.options.font;
        objects.tool.Size = espLibrary.options.fontSize;
        objects.tool.Transparency = espLibrary.options.toolTransparency;
        objects.tool.Color = color or espLibrary.options.toolColor;
        objects.tool.Text = tostring(tool);
        objects.tool.Position = round(position + vector2New(size.X * 0.5, size.Y + 1));

        local Distance_Offset = objects.tool.Visible and 13 or 2

        objects.bottom.Visible = show and espLibrary.options.distance;
        objects.bottom.Font = espLibrary.options.font;
        objects.bottom.Size = espLibrary.options.fontSize;
        objects.bottom.Transparency = espLibrary.options.distanceTransparency;
        objects.bottom.Color = color or espLibrary.options.distanceColor;
        objects.bottom.Text = tostring(round(distance)) .. espLibrary.options.distanceSuffix;
        objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + Distance_Offset));

        objects.box.Visible = show and espLibrary.options.boxes;
        objects.box.Color = color or espLibrary.options.boxesColor;
        objects.box.Transparency = espLibrary.options.boxesTransparency;
        objects.box.Size = size;
        objects.box.Position = position;

        objects.boxOutline.Visible = show and espLibrary.options.boxes;
        objects.boxOutline.Transparency = espLibrary.options.boxesTransparency;
        objects.boxOutline.Size = size;
        objects.boxOutline.Position = position;

        objects.boxFill.Visible = show and espLibrary.options.boxFill;
        objects.boxFill.Color = color or espLibrary.options.boxFillColor;
        objects.boxFill.Transparency = espLibrary.options.boxFillTransparency;
        objects.boxFill.Size = size;
        objects.boxFill.Position = position;

        objects.healthBar.Visible = show and espLibrary.options.healthBars;
        objects.healthBar.Color = espLibrary.options.healthBarsColor;
        objects.healthBar.Transparency = espLibrary.options.healthBarsTransparency;
        objects.healthBar.Size = healthBarSize;
        objects.healthBar.Position = healthBarPosition;

        objects.healthBarOutline.Visible = show and espLibrary.options.healthBars;
        objects.healthBarOutline.Transparency = espLibrary.options.healthBarsTransparency;
        objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2));
        objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1);

        objects.line.Visible = show and espLibrary.options.tracers;
        objects.line.Color = color or espLibrary.options.tracerColor;
        objects.line.Transparency = espLibrary.options.tracerTransparency;
        objects.line.From =
            origin == "Mouse" and userInputService:GetMouseLocation() or
            origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
            origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
        objects.line.To = torsoPosition;
        objects.lineoutline.Visible = show and espLibrary.options.tracers;
        objects.lineoutline.Color = Color3.new(0,0,0)
        objects.lineoutline.Transparency = espLibrary.options.tracerTransparency;
        objects.lineoutline.From =
            origin == "Mouse" and userInputService:GetMouseLocation() or
            origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
            origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
            objects.lineoutline.To = torsoPosition;
    end

    for player, highlight in next, espLibrary.chamsCache do
        local character, torso = espLibrary.getCharacter(player);
  
        if (character and torso) then
            local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
            local canShow = espLibrary.options.enabled and espLibrary.options.chams;
            local team, teamColor = espLibrary.getTeam(player);
            local color = espLibrary.options.teamColor and teamColor or nil;

            if espLibrary.options.useCustomTeamColor and espLibrary.options.teamColor then
                color = espLibrary.options.customteamColor
            end
  
            if (espLibrary.options.fillColor ~= nil) then
                color = espLibrary.options.fillColor;
            end
  
            if (find(espLibrary.whitelist, player.Name)) then
                color = espLibrary.options.whitelistColor;
            end
  
            if (find(espLibrary.blacklist, player.Name)) then
                canShow = false;
            end
  
            if (espLibrary.options.limitDistance and distance > espLibrary.options.maxDistance) then
                canShow = false;
            end
  
            if (espLibrary.options.teamCheck and (team == espLibrary.getTeam(localPlayer))) then
                canShow = false;
            end
  
            highlight.Enabled = canShow;
            highlight.DepthMode = espLibrary.options.visibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop;
            highlight.Adornee = character;
            highlight.FillColor = color or espLibrary.options.chamsFillColor;
            highlight.FillTransparency = espLibrary.options.chamsFillTransparency;
            highlight.OutlineColor = color or espLibrary.options.chamsOutlineColor;
            highlight.OutlineTransparency = espLibrary.options.chamsOutlineTransparency;
        end
    end
  
    for object, cache in next, espLibrary.objectCache do
        local partPosition = vector3New();
  
        if (object:IsA("BasePart")) then
            partPosition = object.Position;
        end
  
        local distance = (currentCamera.CFrame.Position - partPosition).Magnitude;
        local screenPosition, onScreen = worldToViewportPoint(partPosition);
        local canShow = cache.options.enabled and onScreen;
  
        if (espLibrary.options.limitDistance and distance > espLibrary.options.maxDistance) then
            canShow = false;
        end
  
        if (espLibrary.options.visibleOnly and not espLibrary.visibleCheck(object, partPosition)) then
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
  end

  -- Optimize Load function
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
  
    -- Use more efficient render step
    runService:BindToRenderStep("esp_rendering", 
        renderValue or (Enum.RenderPriority.Camera.Value + 1),
        updateESP
    )
  end

  -- Optimize Unload to clean up pools
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

    -- Clear object pools
    for _, pool in next, drawingPool do
        for _, object in next, pool do
            object:Remove()
        end
        table.clear(pool)
    end
  end

  return espLibrary;
