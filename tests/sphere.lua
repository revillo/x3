

local x3 = require('../x3', {root = true});

local scene = x3.newEntity();
local camera = x3.newCamera();
local width, height = love.graphics.getDimensions();

-- Create a canvas to render on
local canvas3D = x3.newCanvas3D(width, height);

for i = 1, 7 do
local ball = x3.newEntity(
	x3.mesh.newSphere(0.5, 32, 32),
    x3.material.newUnlit({
          hemiColors = {{i/7, i/7, i/7}, x3.COLOR.GRAY9}
        })
)

ball:setPosition(i * 1.5 - 6,0,0);
scene:add(ball);

end

-- Add a point light to the scene
local light = x3.newPointLight({
    color = {1,1,1},
    intensity = 6
})

light:setPosition(2, 7, 1);
scene:add(light);

--Configure the camera
camera:setPosition(0, 0, 5);
--camera:setPosition(2, 3, 5);
local cameraTarget, cameraUp = x3.vec3(0,0,0), x3.vec3(0,1,0);
camera:lookAt(cameraTarget, cameraUp);
-- FOV, Aspect Ratio, Near, Far
camera:setPerspective(90, height/width, 0.5, 100.0);

function love.draw()
    --Render 3D scene to canvas
    x3.render(camera, scene, canvas3D);
    --Display canvas on screen
	x3.displayCanvas3D(canvas3D, 0, 0);
end