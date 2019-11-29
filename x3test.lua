--file://c:/castle/x3/x3test.lua

local x3 = {
    math = require('x3math'),
    graphics = require('x3render'),
    scene = require('x3scene'),
    mesh = require('x3mesh'),
    material = require('x3material'),
    loadObj = require("loaders/x3obj")
}

local root = x3.scene.entity();
local camera = x3.scene.camera();
local canvas3D;

local resizeCamera = function()
    local w, h = love.graphics.getDimensions();
    local aspect = h/w;

    camera:setPerspective(90, h/w, 0.5, 10.0);
    
    --local s = 10;
    --camera:setOrthographic(-s, s, -s * aspect, s * aspect, 0, 5);
    canvas3D = x3.graphics.createCanvas3D(w, h);

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
local mat4 = x3.math.mat4;
local vec3 = x3.math.vec3;
local quat = x3.math.quat;

love.load = function()
    resizeCamera();

    camera.position:set(0, 0, 6);
    camera.target:set(0,0,0);
    camera.up:set(0,1,0);

    floor = x3.scene.entity(
        x3.mesh.planeY(5, 5),
        x3.material.unlitColor({0.5, 0.5, 0.5,1})
    );

    floor.position:set(0,0,0);
    root:add(floor);

    ball = x3.scene.entity(
        x3.mesh.sphere(1, 16, 16),
        x3.material.debugTexCoords()
    );

    ball.position:set(0, 0.5, 1);
    root:add(ball);

    cube = x3.scene.entity(
        x3.mesh.box(1, 1, 1),
        x3.material.debugNormals()
    );

    cube.position:set(1.5, 0.5, 0.0)
    root:add(cube);

    model = x3.scene.entity(
        x3.loadObj("models/monkey.obj").mesh,
        x3.material.debugNormals()
    );
    root:add(model);

    model.position:set(0.0, 1.0, 0.0)

end

love.update = function()
    
    local t = love.timer.getTime();
    camera.position:set(math.cos(t) * 5, 5, math.sin(t) * 5);
    camera.target:set(0,0,0);
    
end

love.draw = function()
    local w, h = love.graphics.getDimensions();
    x3.graphics.render(camera, root, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);
end