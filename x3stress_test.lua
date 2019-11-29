--file://c:/castle/x3/x3stress_test.lua


local lastTick = love.timer.getTime();

local tickMsgs = {};

local tick = function(msg)
    local now = love.timer.getTime();
    tickMsgs[msg] = math.floor((now - lastTick) * 1000);
    print(msg, ""..tickMsgs[msg].."ms");
    lastTick = now;
end;

tick("Starting ")

local models = {};
local modelCount = 1000;

local x3 = require('x3');

local scene = x3.newEntity();
local camera = x3.newCamera();
local canvas3D;

local resizeCamera = function()
    local w, h = love.graphics.getDimensions();
    local aspect = h/w;
    camera:setPerspective(90, aspect, 0.5, 100.0);
    canvas3D = x3.newCanvas3D(w, h);
end

love.resize = function()
    resizeCamera();
end


love.load = function()

    tick("Love.load called");

    resizeCamera();

    camera.position:set(0, 0, 0);
    camera.target:set(0, 0, 1);
    camera.up:set(0,1,0);


    local monkeyMesh = x3.loadObj("models/monkey.obj").meshesByName["Suzanne"];
    local material = x3.material.newDebugNormals();

    tick("Mesh Loaded")

    for i = 1, modelCount do
        models[i] = x3.newEntity(
            monkeyMesh,
            material
        );

        models[i].scale:set(0.1, 0.1, 0.1);

        scene:add(models[i]);
    end

    tick("Scene Initialized");

end

local FORWARD = x3.vec3(0,0,1);
local fps = 1/60;

love.update = function(dt)   
    
    local t = love.timer.getTime();

    for i = 1,modelCount do
        local theta = t * 0.1 + i * 0.1;
        models[i].position:set(math.sin(theta), math.cos(theta), i / 100.0 + 1);
        models[i].rotation:rotateAxisAngle(FORWARD, dt);
    end

    fps = fps * 0.9 + (1/dt) * 0.1;
    
end

love.draw = function()
    local w, h = love.graphics.getDimensions();
    x3.render(camera, scene, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);

    love.graphics.setColor(0,0,0,0.5);
    love.graphics.rectangle("fill", 0, 0, 250, 150);
    
    love.graphics.setColor(1,1,1,1);
    love.graphics.print("fps:"..math.floor(fps), 0, 0);

    love.graphics.setColor(1, 0.5, 0.5, 1.0);
    local i = 1;
    for msg, ms in pairs(tickMsgs) do
        love.graphics.print(msg.." : "..ms.."ms", 0, i * 20);
        i = i + 1;
    end
end