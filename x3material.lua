local shaderBank = {

    a_instanceTransform = [[
        #if INSTANCES
            attribute vec4 InstanceTransform1;
            attribute vec4 InstanceTransform2;
            attribute vec4 InstanceTransform3;
            attribute vec4 InstanceTransform4;

            attribute vec4 InstanceColor;
        #endif
    ]],

    com_varying = [[
        varying vec3 v_WorldNormal;
        varying vec3 v_WorldPosition;
        varying vec2 v_TexCoord0;
        varying vec2 v_TexCoord1;

        #if INSTANCES
            varying vec4 v_InstanceColor;
        #endif
    ]],

    vert_init = [[
        extern mat4 u_ViewProjection;
        extern mat4 u_Model;

        attribute vec3 VertexNormal;
        //attribute vec2 VertexTexCoord2;
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
            v_WorldNormal = normalize((model * vec4(VertexNormal, 0.0))).xyz;

            v_TexCoord0 = VertexTexCoord.rg;
            //v_TexCoord1 = VertexTexCoord2.rg;

            #if INSTANCES
                v_InstanceColor = InstanceColor;
            #endif

            v_TexCoord0.y = 1.0 - v_TexCoord0.y;
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

        struct FragLighting {
            vec3 diffuseLighting;
            vec3 specularLighting;
        };

        extern vec3 u_WorldCameraPosition;

        extern vec3 u_BaseColor;
        extern bool u_UseBaseTexture;
        extern Image u_BaseTexture;

        extern vec3 u_EmissiveColor;
        extern bool u_UseEmissiveTexture;
        extern Image u_EmissiveTexture;

        extern vec3 u_HemiLowColor;
        extern vec3 u_HemiHighColor;
        extern vec3 u_HemiDirection;

        extern bool u_UseLightmap;
        extern Image u_LightmapTexture;

        vec3 getBaseColor() {
            vec3 baseColor = u_BaseColor;
            
            if (u_UseBaseTexture) {
                baseColor = Texel(u_BaseTexture, v_TexCoord0).rgb;
            }

            #if INSTANCES
                baseColor.rgb *= v_InstanceColor.rgb;
            #endif

            return baseColor;
        }

        vec3 getEmissiveColor() {
            vec3 emissiveColor = u_EmissiveColor;
            
            if (u_UseEmissiveTexture) {
                emissiveColor = Texel(u_EmissiveTexture, v_TexCoord0).rgb;
            }

            #if INSTANCES
                emissiveColor.rgb *= v_InstanceColor.rgb;
            #endif

            return emissiveColor;
        }

        vec3 getLightmapColor() {
            vec3 lightmapColor = vec3(1.0);
            
            if (u_UseLightmap) {
                lightmapColor = Texel(u_LightmapTexture, v_TexCoord0).rgb;
            }

            return lightmapColor;
        }

        vec3 getNormal() {
            return normalize(v_WorldNormal);
        }

        #if LIGHTS
        extern int u_NumPointLights;
        extern vec3 u_PointLightPositions[4];
        extern vec3 u_PointLightColors[4];
        extern float u_PointLightIntensities[4];

        extern vec3 u_SpecularColor;
        extern float u_Shininess;
        extern bool u_UseSpecularTexture;
        extern Image u_SpecularTexture;

        vec3 getSpecularColor() {
            vec3 color = u_SpecularColor;
            
            if (u_UseSpecularTexture) {
                color = Texel(u_SpecularTexture, v_TexCoord0).rgb;
            }

            return color;
        }
        #endif
    ]],

    frag_getLighting = [[


        FragLighting getLighting() {
            vec3 diffuseLighting = vec3(0.0);
            vec3 specularLighting = vec3(0.0);
            vec3 normal = getNormal();

        #if LIGHTS

            vec3 eyeRay = normalize(v_WorldPosition - u_WorldCameraPosition);
            vec3 outRay = reflect(eyeRay, normal);

            //base Lighting
            for (int i = 0; i < u_NumPointLights; i++) {
                vec3 toLight = u_PointLightPositions[i] - v_WorldPosition;
                float distance = length(toLight);
                toLight *= 1.0/distance;
                float cosFactor = max(0.0, dot(normal, toLight));
                float atten = u_PointLightIntensities[i] * clamp(1.0/(distance), 0.0, 1.0);
                float intensity = cosFactor * atten;
                diffuseLighting += u_PointLightColors[i] * intensity;

                float specFactor = pow(max(0.0, dot(outRay, toLight)), u_Shininess);
                specularLighting += u_PointLightColors[i] * atten * specFactor;
            } 
        #endif

            float skyDot = dot(normal, u_HemiDirection);
            diffuseLighting += mix( u_HemiLowColor, u_HemiHighColor, skyDot);
        
            diffuseLighting += (getLightmapColor() - vec3(1.0));

            return FragLighting(
                diffuseLighting,
                specularLighting
            );
        }
    ]],

    frag_shadeFragmentBegin = [[
        vec4 shadeFragment() {
            vec4 outColor = vec4(0,0,0,1);
    ]],

    frag_shadeFragmentStandard = [[
        vec3 baseColor = getBaseColor();
        
        /*
        #if LIGHTS

        #else
            outColor.rgb = baseColor;
        #endif
        */

        FragLighting lighting = getLighting();

        outColor.rgb += baseColor * lighting.diffuseLighting; 
        outColor.rgb += getEmissiveColor();

        #if LIGHTS
            outColor.rgb += getSpecularColor() * lighting.specularLighting;
        #endif
    ]],

    frag_shadeFragmentEnd = [[
            return outColor;
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

local ShaderBuilder = {

    buildStandardVertex = function(options)

        local defines = shaderBank.makeDefines(options.defines or {
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

    buildStandardFragment = function(options)

        local defines = shaderBank.makeDefines(options.defines or {
            INSTANCES = 1,
            LIGHTS = 1
        });

        local result = {
            defines,
            shaderBank.com_varying,
            shaderBank.frag_init,
            shaderBank.frag_getLighting,
            shaderBank.frag_shadeFragmentBegin,
            shaderBank.frag_shadeFragmentStandard,
            shaderBank.frag_shadeFragmentEnd,
            shaderBank.frag_main
        };

        return table.concat(result);

    end,

    buildCustomFragment = function(options)
        local defines = shaderBank.makeDefines(options.defines or {
            INSTANCES = 1,
            LIGHTS = 0
        });

        local result = {
            defines,
            shaderBank.com_varying,
            shaderBank.frag_init,
            shaderBank.frag_shadeFragmentBegin,
            options.shadeFragment or "",
            shaderBank.frag_shadeFragmentEnd,
            shaderBank.frag_main
        };

        return table.concat(result);
    end

}

local makeShader = love.graphics.newShader;



local shader = {};

local shaderMatArray = {};

shader.__index = {

    send = function(s, name, ...)
        local loveShader = s.loveShader;
        if (loveShader:hasUniform(name)) then
            loveShader:send(name, ...);
        else
            --print(name);
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

shader.newCustom = function(options)
    options.defines = options.defines or {
        INSTANCES = 1,
        LIGHTS = 1
    }

    local s = {
        loveShader = makeShader(
            ShaderBuilder.buildStandardVertex(options), 
            ShaderBuilder.buildCustomFragment(options)
        ),

        options = options
    };

    setmetatable(s, shader);
    return s;
end

shader.newStandard = function(options)

    options.defines = options.defines or {
        INSTANCES = 1,
        LIGHTS = 1
    }

    local s = {
        loveShader = makeShader(
            ShaderBuilder.buildStandardVertex(options), 
            ShaderBuilder.buildStandardFragment(options)
        ),

        options = options
    };

    setmetatable(s, shader);
    return s;
end

local Shaders = {

    standardShader = shader.newStandard({
        defines = {
            INSTANCES = 1,
            LIGHTS = 1
        }
    }),

    unlitShader = shader.newStandard({
        defines = {
            INSTANCES = 1,
            LIGHTS = 0
        }
    })
}

local function materialDefaultUniforms(options)

    options.hemiColors = options.hemiColors or {{0,0,0}, {0,0,0}};

    return {
        u_BaseColor = options.baseColor or {1,1,1},
        u_UseBaseTexture = not not options.baseTexture,
        u_BaseTexture = options.baseTexture,

        u_HemiLowColor = options.hemiColors[1] or {0,0,0},
        u_HemiHighColor = options.hemiColors[2] or {0,0,0},
        u_HemiDirection = options.hemiDirection or {0, 1, 0},

        u_EmissiveColor = options.emissiveColor or {0,0,0},
        u_UseEmissiveTexture = not not options.emissiveTexture,
        u_EmissiveTexture = options.emissiveTexture
    }

end

local material = {

    newLit = function(options)
        options = options or {};

        local uniforms = materialDefaultUniforms(options);

        uniforms.u_LightmapTexture = options.lightmapTexture;
        uniforms.u_UseLightmap = not not options.lightmapTexture;
        
        uniforms.u_SpecularColor = options.specularColor or {0,0,0};
        uniforms.u_UseSpecularTexture = not not options.specularTexture;
        uniforms.u_SpecularTexture = options.specularTexture;
        uniforms.u_Shininess = options.shininess or 1.0;

        return {
            shader = Shaders.standardShader,
            uniforms = uniforms,
            options = options
        }
    end,

    
    newUnlit = function(options)
        options = options or {};

        local uniforms = materialDefaultUniforms(options);

        return {
            shader = Shaders.unlitShader,
            uniforms = uniforms,
            options = options or {}
        }

    end,

    newCustom = function(shader, uniforms)

        return {
            shader = shader,
            uniforms = uniforms or {},
            options = shader.options
        }

    end
}

return {
    material = material,
    shader = shader,
    ShaderBuilder = ShaderBuilder
}