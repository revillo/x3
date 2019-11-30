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

    camera:setPerspective(90, h/w, 0.5, 10.0);
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
    camera.target:set(0,0,0);
    camera.up:set(0,1,0);

    floor = x3.newEntity(
        x3.mesh.newPlaneY(5, 5),
        x3.material.newUnlitColor({0.5, 0.5, 0.5,1})
    );
    floor.position:set(0,0,0);
    scene:add(floor);

    ball = x3.newEntity(
        x3.mesh.newSphere(1, 16, 16),
        x3.material.newDebugTexCoords()
    );
    ball.position:set(0, 0.5, 1);
    scene:add(ball);

    cube = x3.newEntity(
        x3.mesh.newBox(1, 1, 1),
        x3.material.newDebugNormals()
    );
    cube.position:set(1.5, 0.5, 0.0)
    scene:add(cube);

    local mesh = x3.loadObj("models/monkey.obj").mesh;

    --[[
    local transforms = {};
    local pos = x3.vec3();

    for i = 1, 1000 do
        local t = i * 0.2;
        pos:set(math.sin(t), math.cos(t), t);
        local mat = x3.mat4();
        mat:setTranslate(pos);
        transforms[i] = mat;
    end
  
    local instanceMesh = x3.mesh.newInstanceMesh(transforms);

    mesh:attachAttribute("InstanceTransform1", instanceMesh, "perinstance");
    mesh:attachAttribute("InstanceTransform2", instanceMesh, "perinstance");
    mesh:attachAttribute("InstanceTransform3", instanceMesh, "perinstance");
    mesh:attachAttribute("InstanceTransform4", instanceMesh, "perinstance");
]]

    model = x3.newEntity(
        mesh,
        x3.material.newDebugNormals()
        --x3.material.newDebugNormalsInstanced(1000)
    );

    scene:add(model);
    model.position:set(-2.0, 1.0, 0.0)

end

love.update = function()   

    local t = love.timer.getTime();
    camera.position:set(math.cos(t) * 5, 5, math.sin(t) * 5);
    camera.target:set(0,0,0);
    
end

love.draw = function()
    local w, h = love.graphics.getDimensions();
    x3.render(camera, scene, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);
end