POSITION_ATTRIBUTE = {"VertexPosition", "float", 3};
NORMAL_ATTRIBUTE = {"VertexNormal", "float", 3};
UV_ATTRIBUTE = {"VertexTexCoord", "float", 2};

--COLOR_ATTRIBUTE = {"VertexColor", "float", 4};

BASIC_ATTRIBUTES = {
  POSITION_ATTRIBUTE,
  UV_ATTRIBUTE
}


local mesh = {

    planeZ = function(w, h)
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES,
        {
            {
                w/2, -h/2, 0,
                0, 0, 1,
                1, 0
            },
            {
                -w/2, -h/2, 0,
                0, 0, 1,
                0, 0
            },
            {
                w/2, h/2, 0,
                0, 0, 1,
                1, 1
            },
            {
                -w/2,h/2, 0,
                0, 0, 1,
                0, 1
            }
            
        }, "strip", "static");

    end,

    planeY = function(w, h)
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES,
        {
            {
                w/2, 0, -h/2,
                0, 1, 0,
                1, 0
            },
            {
                -w/2, 0, -h/2,
                0, 1, 0,
                0, 0
            },
            {
                w/2, 0, h/2,
                0, 1, 0,
                1, 1
            },
            {
                -w/2, 0, h/2,
                0, 1, 0,
                0, 1
            }
            
        }, "strip", "static");

    end
}


return mesh;