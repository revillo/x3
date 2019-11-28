--file://c:/castle/c3/c3test.lua

local c3 = {
    math = require('c3math'),
    graphics = require('c3render'),
    scene = require('c3scene'),
    mesh = require('c3mesh'),
    material = require('c3material')
}

local root = c3.scene.entity();
local camera = c3.scene.camera();
local canvas3D;

local resizeCamera = function()
    local w, h = love.graphics.getDimensions();
    local aspect = h/w;

    camera:setPerspective(90, h/w, 0.5, 10.0);
    
    --local s = 10;
    --camera:setOrthographic(-s, s, -s * aspect, s * aspect, 0, 5);
    
    canvas3D = c3.graphics.createCanvas3D(w, h, {
        dpiscale = love.window.getDPIScale()
    });

end

love.resize = function()
    resizeCamera();
end

local floor;
local mat4 = c3.math.mat4;
local vec3 = c3.math.vec3;
local quat = c3.math.quat;

love.load = function()
    resizeCamera();

    camera.position:set(0, 0, 5);
    camera.target:set(0,0,0);
    camera.up:set(0,1,0);

    floor = c3.scene.entity(
        c3.mesh.planeZ(1, 1),
        c3.material.unlitColor({1,0,0,1})
    );

    floor.position:set(0,0.0,0);
    root:add(floor);

--[[
    floor:updateTransform();
    print("floor", floor.transform:__tostring());
    


    local m1 = mat4();
    local m2 = mat4();
    local m3 = mat4();

    m1:setTranslate(vec3(0,1,0));
    m3:setRotate(quat());
    m2:setScale(vec3(1,1,1));

    m1:mult(m3);
    m1:mult(m2);

    print("math", m1:__tostring());
    ]]
    
end

love.update = function()

    local t = love.timer.getTime();

    camera.position:set(0, 0, 5 + 2 * math.cos(t));
    camera.target:set(math.sin(t), 0, 0);
    floor.rotation:setAxisAngle(vec3(0,0,1), t);

end

love.draw = function()
    --return;
    local w, h = love.graphics.getDimensions();

    c3.graphics.render(camera, root, canvas3D);
    love.graphics.draw(canvas3D.color, 0, h, 0, 1, -1);
    love.graphics.rectangle("fill", 0, 0, 10, 10);
end