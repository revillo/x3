--file://c:/castle/x3/x3test.lua

local x3 = require('x3');

CASTLE_PREFETCH({
    "x3math.lua",
    "x3render.lua",
    "x3scene.lua",
    "x3mesh.lua",
    "x3material.lua",
    "loaders/x3obj.lua"
});

local scene = x3.newEntity();
local camera = x3.newCamera();
local canvas3D;

local resizeCamera = function()
    local w, h = love.graphics.getDimensions();
    local aspect = h/w;

    camera:setPerspective(90, h/w, 0.5, 100.0);
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

local floor, ball, cube, model;

love.load = function()
    resizeCamera();

    camera.position:set(0, 0, 6);
    
    --camera.target:set(0,0,0);
    --camera.up:set(0,1,0);

    
    floor = x3.newEntity(
        x3.mesh.newPlaneY(5, 5),
        x3.material.newUnlit({
            emissiveColor = {0.5, 0.5, 0.5}
        })
    );
    floor.position:set(0,0,0);
    scene:add(floor);


    ball = x3.newEntity(
        x3.mesh.newSphere(1, 16, 16),
        x3.material.newLit({
            baseColor = {1,0,0}
        })
    );
    ball.position:set(0, 0.5, 1);
    scene:add(ball);
    --[[

    cube = x3.newEntity(
        x3.mesh.newBox(1, 1, 1),
        x3.material.newDebugNormals()
    );
    cube.position:set(1.5, 0.5, 0.0)
    scene:add(cube);
    ]]

    scene:add(x3.newPointLight({
        position = x3.vec3(0, 5, 0),
        intensity = 10,
        color = {0.9, 0.9, 0.7}
    }));

    local mesh = x3.loadObj("models/monkey.obj").mesh;

    model = x3.newEntity(
        mesh,

        x3.material.newLit({
            diffuseColor = {1,0,1}
        })
        --x3.material.newDebugNormalsInstanced(1000)
    );

    scene:add(model);
    model:setPosition(0.0, 0.0, 0.0);

    model:setNumInstances(5);

    for i = 1,5 do
        local t = i;
        model:getInstance(i):setPosition(math.sin(t), math.cos(t) + 2, t)
        model:getInstance(i):setScale(0.3);
    end

end

local cameraTarget = x3.vec3(0,0,0);
local cameraUp = x3.vec3(0,1,0);

love.update = function()   

    local t = love.timer.getTime();
    camera:setPosition(math.cos(t) * 5, 5, math.sin(t) * 5);
    --camera.target:set(0,0,0);
    camera:lookAt(cameraTarget, cameraUp);
    
end

love.draw = function()
    local w, h = love.graphics.getDimensions();
    x3.render(camera, scene, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);
end