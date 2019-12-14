--file://c:/castle/x3/x3test_obj_scene.lua

local x3 = require('x3');

CASTLE_PREFETCH({
    "x3math.lua",
    "x3render.lua",
    "x3scene.lua",
    "x3mesh.lua",
    "x3material.lua",
    "loaders/x3obj.lua",
    "models/island/crownAO.png",
    "models/island/islandAO.png",
    "models/island/island.png",
    "models/island/grass.obj",
    "models/island/island.obj",
    "models/island/sky.png"
});

local scene = x3.newEntity();
local camera = x3.newCamera();
local canvas3D;

local resizeCamera = function()
    local w, h = love.graphics.getDimensions();
    local aspect = h/w;

    camera:setPerspective(90, aspect, 0.5, 100.0);
    canvas3D = x3.newCanvas3D(w, h);

    --[[
    canvas3D = x3.graphics.createCanvas3D(w, h, {
        dpiscale = love.window.getDPIScale()
    });
    ]]

end

love.resize = function()
    resizeCamera();
end


love.load = function()
    resizeCamera();

    --vec3(0.3, 0.5, 0.2), vec3(0.8, 0.8, 1.0)

    camera:setPosition(0, 0, 6);
    
    --Add sun
    scene:add(x3.newPointLight({
        position = x3.vec3(3, 8, 3),
        intensity = 5,
        color = {0.9, 0.9, 0.7}
    }));

    local loadImg = function(name)
        return love.graphics.newImage("models/island/"..name..".png");
    end

    local objScene = x3.loadObj("models/island/island.obj");

    local sky = x3.newEntity(
        objScene.meshesByName.sky_mesh4,

        x3.material.newUnlit({
            baseColor = {1.0,1.0,1.0},
            baseTexture = loadImg("sky"),
            hemiColors = {{1,1,1}, {1,1,1}}
        })
    );
    scene:add(sky);

    local function addModel(modelName, color, tex, aotex)
        local model = x3.newEntity(
            objScene.meshesByName[modelName],

            x3.material.newLit({
                baseColor = color,
                baseTexture = tex,
                lightmapTexture = aotex,
                hemiColors = {{ 0.3, 0.5, 0.2}, {0.8, 0.8, 1.0}},
                specularColor = {0.5, 0.5, 0.5},
                shininess = 20
            })
        );

        scene:add(model);
        return model;
    end



    addModel("island_mesh1", {0.7, 0.8, 0.5}, 
        loadImg("island"),
        loadImg("islandAO")
    );

    addModel("trunk_mesh5", {0.7, 0.4, 0.1}, nil, loadImg("trunkAO"));
    addModel("crown_mesh3", {0.1, 0.6, 0.3}, nil, loadImg("crownAO"));
    
    
    --local grass = addModel("grass_mesh2", {0.2, 0.9, 0.6});

    local grass = x3.newEntity(
        x3.loadObj("models/island/grass.obj").mesh,
        --x3.mesh.newBox(1, 1, 1),
        x3.material.newLit({
            baseColor = {0.3, 0.9, 0.6},
            emissiveColor = {0.07, 0.2, 0.0},
            hemiColors = {{ 0.3, 0.3, 0.3}, {0.9, 0.9, 0.8}},
            cullMode = "none",
            specularColor = {0.5, 0.5, 0.5},
            shininess = 20
        })
    );

    scene:add(grass);
    grass:setNumInstances(200);

    local grassPos = x3.vec3();
    local grassRot = x3.quat();
    local grassScale = x3.vec3(0.1);
    local up = x3.vec3(0,1,0);

    for i = 1, grass:getNumInstances() do
        local ptheta = math.random() * math.pi * 2;
        local prad = math.random() * 7.0;
        
        local gi = grass:getInstance(i);

        gi:setPosition(math.sin(ptheta) * prad * 0.9, 0, math.cos(ptheta) * prad * 1.1);
        gi:setScale(math.random() * 0.15 + 0.01);
        gi:rotateLocalY(math.random() * 10);
        gi:rotateLocalX(math.random() * 0.2);

        --[[
        grassRot:setAxisAngle(up, math.random() * 4);
        grassPos:set();
        grassScale:set(math.random() * 0.2 + 0.1,math.random() * 0.2 + 0.1,math.random() * 0.2 + 0.1);
        grassScale:scale(0.5);
        grass:setInstance(i, grassPos, grassRot, grassScale);
        ]]
    end
    

end

local cameraTarget = x3.vec3(0,0,0);
local cameraUp = x3.vec3(0,1,0);
local pause = false;
local stop = false;


love.update = function()   

    if (stop or pause) then
        return;
    end

    local t = love.timer.getTime() * 0.2;
    local x, y = love.mouse.getPosition();
    t = -x * 0.01;

    local radius = 20;
    camera:setPosition(math.cos(t) * radius, 3, math.sin(t) * radius);
    camera:lookAt(cameraTarget, cameraUp);
    
end

love.draw = function()

    if (stop) then
        return;
    end

    local w, h = love.graphics.getDimensions();
    x3.render(camera, scene, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);
end

function love.keypressed(key)
    if (key == "p") then
        pause = not pause;
    elseif (key == "space") then
        stop = not stop;
    end
end