--file://c:/castle/ast/x3/tests/transparency.lua

local x3 = require('../x3', {root = true});

local scene = x3.newEntity();
local camera = x3.newCamera();
local width, height = love.graphics.getDimensions();

-- Create a canvas to render on
local canvas3D = x3.newCanvas3D(width, height);

local customShaderOpts = {
    defines = {
        LIGHTS = 0,
        INSTANCES = 1 
    },

    fragShade = [[
        outColor = vec4(1.0, 0.0, 0.0, 0.3);
    ]]
};

local material = x3.material.newCustom(x3.shader.newCustom(customShaderOpts));

local ball = x3.newEntity(
    x3.mesh.newSphere(2.0),
    x3.material.newUnlit({
        hemiColors = {{0,0,0.2}, {0,1,1}}
    })
)
ball:setPosition(1, -1.5, 1.0);
scene:add(ball);

for i = 1, 4 do
    local plane = x3.newEntity(
        x3.mesh.newPlaneY(4.0, 4.0),
        material
    )

    plane:setPosition(0, i * 0.8, 0);
    plane:setRenderOrder(i);
    scene:add(plane);
end

--Configure the camera
camera:setPosition(3, 6, 3);
--camera:setPosition(2, 3, 5);
local cameraTarget, cameraUp = x3.vec3(0,0.4,0), x3.vec3(0,1,0);
camera:lookAt(cameraTarget, cameraUp);
-- FOV, Aspect Ratio, Near, Far
camera:setPerspective(120, height/width, 0.5, 100.0);

function love.draw()
    --Render 3D scene to canvas
    x3.render(camera, scene, canvas3D);
    --Display canvas on screen
	x3.displayCanvas3D(canvas3D, 0, 0);
end