local shaderSource = {

    defaultVertex = [[
        uniform mat4 mvp; 
        //uniform mat4 model;
        
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vec4 p = mvp * vec4(vertex_position.xyz, 1.0);

            /*
            vec4 position;
            position.w = 1.0;
            
            position.x = vertex_position.x;
            position.y = vertex_position.z;
            position.z = 0.1;
            */

            return p;
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

local shaders = {
    unlitColor = love.graphics.newShader(shaderSource.defaultVertex, shaderSource.unlitColorFrag)
}


local material = {

    unlitColor = function(color)
        return {
            shader = shaders.unlitColor,
            uniforms = {
                unlitColor = color
            }
        };
    end

}

return material;