local shaderBank = {

    a_instanceTransform = [[
        #if INSTANCES
            attribute vec4 InstanceTransform1;
            attribute vec4 InstanceTransform2;
            attribute vec4 InstanceTransform3;
            attribute vec4 InstanceTransform4;
        #endif
    ]],

    com_varying = [[
        varying vec3 v_WorldNormal;
        varying vec3 v_WorldPosition;
        varying vec2 v_TexCoord0;
        varying vec2 v_TexCoord1;
    ]],

    vert_init = [[
        extern mat4 u_ViewProjection;
        extern mat4 u_Model;

        attribute vec3 VertexNormal;
    ]],
    
    vert_initFragData = [[
        vec4 initFragmentData(vec4 vertexPosition)
        {
        #if INSTANCES
            mat4 model = u_Model * mat4(InstanceTransform1, InstanceTransform2, InstanceTransform3, InstanceTransform4);
        #else
            mat4 model = u_Model;
        #endif

            vec4 worldPosition = model * vertexPosition;
            v_WorldPosition = worldPosition.xyz;
            v_WorldNormal = (model * vec4(VertexNormal, 0.0)).xyz; 
            return u_ViewProjection * worldPosition;
        }
    ]],

    vert_main = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            return initFragmentData(vertex_position);
        }
    ]],

    frag_init = [[

        #if LIGHTS
            extern int u_NumPointLights;
            extern vec3 u_PointLightPositions[4];
            extern vec3 u_PointLightColors[4];
            extern float u_PointLightIntensities[4];
        #endif

        extern vec3 u_DiffuseColor;
        extern bool u_UseDiffuseTexture;
        extern Image u_DiffuseTexture;
    ]],

    frag_shadeFragment = [[
        vec4 shadeFragment() {

            vec3 diffuseColor = u_DiffuseColor;
            
            if (u_UseDiffuseTexture) {
                diffuseColor = Texel(u_DiffuseTexture, v_TexCoord0).rgb;
            }

            vec4 outColor = vec4(0,0,0,1);


        #if LIGHTS

            //Diffuse Lighting
            for (int i = 0; i < u_NumPointLights; i++) {
                vec3 toLight = u_PointLightPositions[i] - v_WorldPosition;
                float distance = length(toLight);
                float cosFactor = dot(v_WorldNormal, toLight/distance);
                float atten = clamp(1.0/(distance), 0.0, 1.0);
                float intensity = cosFactor * u_PointLightIntensities[i] * atten;
                outColor.rgb += diffuseColor * u_PointLightColors[i] * intensity;
            } 

            return outColor;
        #else
            outColor.rgb = diffuseColor;
            return outColor;
        #endif
        }
    ]],

    frag_main = [[
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
            return shadeFragment();
        }
    ]],

    makeDefines = function(defines)
        local result = "";
        for name, value in pairs(defines) do
            result = result.."#define "..name.." "..value.."\n";
        end
        return result;
    end
}

local shaderSource = {

    defaultVertex = [[
        attribute vec3 VertexNormal;

        extern mat4 mvp; 
        //extern mat4 model;
        
        varying vec3 normal;
        
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vec4 p = mvp * vec4(vertex_position.xyz, 1.0);
            normal = VertexNormal;
            return p;
        }
    ]],

    instanceVertex = [[        
        attribute vec4 InstanceTransform1;
        attribute vec4 InstanceTransform2;
        attribute vec4 InstanceTransform3;
        attribute vec4 InstanceTransform4;
        
        attribute vec3 VertexNormal;

        extern mat4 vp;
        varying vec3 normal;
        
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            mat4 model = mat4(InstanceTransform1, InstanceTransform2, InstanceTransform3, InstanceTransform4);
            vec4 p = vec4(vertex_position.xyz, 1.0);
            normal = VertexNormal;

            return vp * (model * p); 
        }


    ]],

    debugNormalsFrag = [[
        varying vec3 normal;

        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          return vec4(normal * 0.5 + vec3(0.5), 1.0);
        }
    ]],

    debugTexCoords = [[
        varying vec3 normal;

        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          return vec4(texture_coords, 0.0, 1.0);
        }
    ]],

    unlitColorFrag = [[

        extern vec4 unlitColor;

        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          return unlitColor;
        }
    
    ]]
}

local ShaderBuilder = {

    buildStandardVertex = function(options)

        local defines = shaderBank.makeDefines({
            INSTANCES = 1,
            LIGHTS = 1
        });

        local result = {
            defines,
            shaderBank.com_varying,
            shaderBank.a_instanceTransform,
            shaderBank.vert_init,
            shaderBank.vert_initFragData,
            shaderBank.vert_main
        };

        return table.concat(result);
    end,

    buildStandardFragment = function()

        local defines = shaderBank.makeDefines({
            INSTANCES = 1,
            LIGHTS = 1
        });

        local result = {
            defines,
            shaderBank.com_varying,
            shaderBank.frag_init,
            shaderBank.frag_shadeFragment,
            shaderBank.frag_main
        };

        return table.concat(result);

    end

}

local makeShader = love.graphics.newShader;

local shaders = {
    unlitColor = makeShader(shaderSource.defaultVertex, shaderSource.unlitColorFrag),
    debugNormals = makeShader(shaderSource.defaultVertex, shaderSource.debugNormalsFrag),
    debugNormalsInstanced = makeShader(shaderSource.instanceVertex, shaderSource.debugNormalsFrag),
    debugTexCoords = makeShader(shaderSource.defaultVertex, shaderSource.debugTexCoords)
};

local shader = {};

local shaderMatArray = {};

shader.__index = {

    send = function(s, name, ...)
        local loveShader = s.loveShader;
        if (loveShader:hasUniform(name)) then
            loveShader:send(name, ...);
        end
    end,

    sendArray = function(s, name, array) 
        local loveShader = s.loveShader;
        if (loveShader:hasUniform(name)) then
            loveShader:send(name, unpack(array));
        end
    end,

    sendMat4 = function(s, name, m)
        local loveShader = s.loveShader;
        if (loveShader:hasUniform(name)) then    
            m:toRowMajorArray(shaderMatArray);
            loveShader:send(name, shaderMatArray);
        end
    end,

    setActive = function(s)
        love.graphics.setShader(s.loveShader);
    end,
}

shader.newStandardShader = function(options)
    local s = {
        loveShader = makeShader(ShaderBuilder.buildStandardVertex(options), ShaderBuilder.buildStandardFragment(options));
    } 

    setmetatable(s, shader);
    return s;
end

local standardShader = shader.newStandardShader({});


local material = {

    newCustomMaterial = function(shader, uniforms)
        return {
            shader = shader,
            uniforms = uniforms
        };
    end,

    newUnlitColor = function(color)
        return {
            shader = shaders.unlitColor,
            uniforms = {
                unlitColor = color
            }
        };
    end,

    newDebugNormals = function()
        return {
            shader = shaders.debugNormals,
            uniforms = {}
        }
    end,

    newDebugNormalsInstanced = function(numInstances)
        return {
            shader = shaders.debugNormalsInstanced,

            uniforms = {

            },

            numInstances = numInstances
        }
    end,

    newDebugTexCoords = function()
        return {
            shader = shaders.debugTexCoords,
            uniforms = {}
        }
    end,

    newLitMesh = function(options)
        local uniforms = {
            --u_DiffuseColor = options.diffuseColor or {1,1,1},
            u_DiffuseColor = {1,1,1},
            u_UseDiffuseTexture = false
        }
        return {
            shader = standardShader,
            uniforms = uniforms
        }
    end

}

return {
    material = material,
    shader = shader
}