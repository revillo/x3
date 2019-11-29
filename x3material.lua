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

local makeShader = love.graphics.newShader;

local shaders = {
    unlitColor = makeShader(shaderSource.defaultVertex, shaderSource.unlitColorFrag),
    debugNormals = makeShader(shaderSource.defaultVertex, shaderSource.debugNormalsFrag),
    debugTexCoords = makeShader(shaderSource.defaultVertex, shaderSource.debugTexCoords)
};

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

    newDebugTexCoords = function()
        return {
            shader = shaders.debugTexCoords,
            uniforms = {}
        }
    end

}

return material;