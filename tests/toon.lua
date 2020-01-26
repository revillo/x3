--file://C:/castle/x3/tests/toon.lua

local x3 = require('../x3', {root = true});

local scene = x3.newEntity();
local camera = x3.newCamera();
local width, height = love.graphics.getDimensions();

-- Create a canvas to render on
local canvas3D = x3.newCanvas3D(width, height);


local mesh = x3.mesh.newSphere(0.8, 32, 32);


local outlineShaderOpts = {

    defines = {
        LIGHTS = 0,
        INSTANCES = 1
    },


    vertMain = [[
        extern float u_OutlineThickness;

        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            #if INSTANCES
                mat4 model = u_Model * mat4(InstanceTransform1, InstanceTransform2, InstanceTransform3, InstanceTransform4);
            #else
                mat4 model = u_Model;
            #endif

            
    
            vec4 worldPosition = model * (VertexPosition);
            v_WorldPosition = worldPosition.xyz;
            v_WorldNormal = normalize((model * vec4(VertexNormal, 0.0))).xyz;

            float eyeDist = length(u_WorldCameraPosition - v_WorldPosition);
            float thickness = u_OutlineThickness * 0.1;

            thickness = clamp(thickness, eyeDist * 0.005, eyeDist * 0.02);

            worldPosition = model * (VertexPosition + vec4(normalize(VertexNormal) * thickness, 0.0));

            v_TexCoord0 = VertexTexCoord.rg;
            //v_TexCoord1 = VertexTexCoord2.rg;

            #if INSTANCES
                v_InstanceColor = InstanceColor;
            #endif

            v_TexCoord0.y = 1.0 - v_TexCoord0.y;
            return u_ViewProjection * worldPosition;
        }
    ]],

    fragHead = [[
        extern vec3 u_OutlineColor;
    ]],

    fragShade = [[
        outColor = vec4(u_OutlineColor,1.0);
    ]],

    cullMode = "front"

}

local outlineMaterial = x3.material.newCustom(
    x3.shader.newCustom(outlineShaderOpts),
    {
        u_OutlineColor = {0,0,0},
        u_OutlineThickness = 1
    }
);



local color = x3.vec3();

local ranLo = x3.vec3(0.1,0.1,0.1);
local ranHi = x3.vec3(1,1,1);

local hemiDir = x3.vec3(-1, 1, 2);
hemiDir:normalize();

for i = 1, 10 do

color:randomCube(ranLo, ranHi);

local ball = x3.newEntity(
	mesh,
    x3.material.newUnlit({
          hemiColors = {x3.COLOR.GRAY1, x3.COLOR.WHITE},
          hemiDirection = hemiDir,
          toonStep = 4,
          baseColor = color
          --emissiveColor = x3.COLOR.GRAY4
        })
)

local ballOutline = x3.newEntity(
	mesh,
    outlineMaterial
) 


ball:setPosition(i-4, math.sin(i * 0.5) * 2, 3-i*1.5);
ballOutline:copyPosition(ball);
scene:add(ballOutline);
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
camera:setPerspective(90, height/width, 0.5, 120.0);

function love.draw()
    --Render 3D scene to canvas
    x3.render(camera, scene, canvas3D, {
        clearColor = {1,1,1}
    });
    --Display canvas on screen
	x3.displayCanvas3D(canvas3D, 0, 0);
end