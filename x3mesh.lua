local POSITION_ATTRIBUTE = {"VertexPosition", "float", 3};
local NORMAL_ATTRIBUTE = {"VertexNormal", "float", 3};
local UV_ATTRIBUTE = {"VertexTexCoord", "float", 2};

--COLOR_ATTRIBUTE = {"VertexColor", "float", 4};

local BASIC_ATTRIBUTES = {
  POSITION_ATTRIBUTE,
  NORMAL_ATTRIBUTE,
  UV_ATTRIBUTE
}

local INSTANCE_ATTRIBUTES = {
    {"InstanceTransform1", "float", 4},
    {"InstanceTransform2", "float", 4},
    {"InstanceTransform3", "float", 4},
    {"InstanceTransform4", "float", 4},
    {"InstanceColor", "float", 4}
}

local x3m = require('x3math');
local vec3 = x3m.vec3;


local v3A = vec3();
local v3B = vec3();
local v3C = vec3();
local v3D = vec3();


local function getTriNormal(a, b, c)
    v3A:fromArray(a);
    v3B:fromArray(b);
    v3C:fromArray(c);

    v3B:sub(v3A);
    v3C:sub(v3A);

    v3A:setPerpendicular(v3B, v3C);
    return v3A:components();
end

--[[
    a b
    d c
]]
local function quadVerts(a, b, c, d, u, v, u2, v2)
      
    u = u or 0;
    v = v or 0;
    u2 = u2 or 1;
    v2 = v2 or 1;

    local nx, ny, nz = getTriNormal(a, b, d);

   return {
      {a[1], a[2], a[3], nx, ny, nz, u, v2},
      {c[1], c[2], c[3], nx, ny, nz,  u2, v},
      {b[1], b[2], b[3], nx, ny, nz,  u2, v2},
      
      {a[1], a[2], a[3], nx, ny, nz,  u, v2},
      {d[1], d[2], d[3], nx, ny, nz,  u,  v},
      {c[1], c[2], c[3], nx, ny, nz,  u2, v}
    };
end
  

local mesh = {

    newPlaneZ = function(w, h)
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES,
        {
            {
                -w/2,h/2, 0,
                0, 0, 1,
                0, 1
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
                w/2, -h/2, 0,
                0, 0, 1,
                1, 0
            }
        }, "strip", "static");
    end,

    newPlaneY = function(w, h)
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES,
        {
            {
                -w/2, 0, h/2,
                0, 1, 0,
                0, 1
            },
            {
                -w/2, 0, -h/2,
                0, 1, 0,
                0, 0
            },
            {
                w/2, 0, h/2,
                0, 1, 0,
                1, 0
            },
            {
                w/2, 0, -h/2,
                0, 1, 0,
                1, 1
            }

            
        }, "strip", "static");
    end,

    newSphere = function(radius, rings, slices, flipSides)
        rings = rings or 16;
        slices = slices or 16;

        local verts = {};
        local positions = {};
        local vIndex = 1;
        local index = 1;
        local pi = math.pi;
        local nr = rings - 1;
        local ns = slices - 1;

        local rd = pi / nr;
        local sd = pi * 2 / slices;

        local function addVertex(v)
            verts[vIndex] = {v[1] * radius, v[2] * radius, v[3] * radius, v[1], v[2], v[3], v[4], v[5]}
            vIndex = vIndex + 1;
        end

        local function addQuad(a, b, c, d)
            addVertex(a);
            addVertex(c);
            addVertex(b);

            addVertex(a);
            addVertex(d);
            addVertex(c);
        end

        if (flipSides) then

            addVertex = function(v)
                verts[vIndex] = {v[1] * radius, v[2] * radius, v[3] * radius, -v[1], -v[2], -v[3], v[4], v[5]}
                vIndex = vIndex + 1;
            end

            addQuad = function(a,b,c,d) 
                addVertex(a);
                addVertex(b);
                addVertex(c);

                addVertex(a);
                addVertex(c);
                addVertex(d);
            end
        end

        for r = 0, nr do
            positions[r] = {};
            for s = 0, slices do
                local theta = s * sd;
                local phi = r * rd;
                v3A:fromSphere(theta, phi, 1.0);
                positions[r][s] = {v3A.x, v3A.y, v3A.z, theta / (pi * 2), phi / pi};
                index = index + 1;
            end
        end

        for r = 0, nr-1 do
            for s = 0, ns do

                local s2 = (s+1);

                addQuad(
                    positions[r][s],
                    positions[r][s2],
                    positions[r + 1][s2],
                    positions[r + 1][s]
                );
            end
        end

        return love.graphics.newMesh(
            BASIC_ATTRIBUTES, verts, "triangles", "static"
        );

    end,

    newCylinder = function(radius, length, sides, segments)

        segments = segments or 1;
        sides = sides or 8;
        length = length or 1;
        radius = radius or 1;

        local faces = {};
        local fi = 0;


        local getPosition = function(i, j)
            local angle = (i / sides) * math.pi * 2;
            local dist = (j-1) / (segments);

            return {math.sin(angle) * radius, math.cos(angle) * radius, dist * length};
        end

        for seg = 1,segments do
            for side = 1, sides do
                fi = fi + 1;

                faces[fi] = quadVerts(
                    getPosition(side, seg + 1),
                    getPosition(side + 1, seg + 1),
                    getPosition(side + 1, seg),
                    getPosition(side, seg)
                );

            end
        end

        local verts = {};
        local index = 1;
        
        for face = 1, fi do
            for v = 1, 6 do
              verts[index] = faces[face][v]; 
              index = index + 1;
            end    
        end
        
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES, verts, "triangles", "static"
        );

    end,

    newBox = function(sx, sy, sz)

        sx = sx or 1;
        sy = sy or sx;
        sz = sz or sx;

        sx, sy, sz = sx * 0.5, sy * 0.5, sz * 0.5;

        local x0, x1 = sx, -sx;
        local y0, y1 = -sy, sy;
        local z0, z1 = -sz, sz;
        
        local a = {x0, y0, z0};
        local b = {x1, y0, z0};
        local c = {x1, y1, z0};
        local d = {x0, y1, z0};
        
        local e = {x0, y0, z1};
        local f = {x1, y0, z1};
        local g = {x1, y1, z1};
        local h = {x0, y1, z1};
    
        local faces;
        
        faces = {
            quadVerts(a, e, f, b),
            quadVerts(a, b, c, d),
            quadVerts(b, f, g, c),
            quadVerts(f, e, h, g),
            quadVerts(e, a, d, h),
            quadVerts(d, c, g, h)
        };
        
        local verts = {};
        local index = 1;
        
        for face = 1, 6 do
            for v = 1, 6 do
              verts[index] = faces[face][v]; 
              index = index + 1;
            end    
        end
        
        return love.graphics.newMesh(
            BASIC_ATTRIBUTES, verts, "triangles", "static"
        );
    end,

    newInstanceMesh = function(instances, count)

        local vs = {};

        for i = 1, count do
            local t = instances[i];
            vs[i] = {};
            t.transform:toColMajorArray(vs[i]);
            vs[i][17] = t.color.x;
            vs[i][18] = t.color.y;
            vs[i][19] = t.color.z;
            vs[i][20] = t.alpha;
        end

        local instanceMesh = love.graphics.newMesh(
            INSTANCE_ATTRIBUTES, vs
        );

        return instanceMesh, vs;

    end,

    updateInstanceMesh = function(instances, mesh, vs, count)
        vs = vs or {};
        --vs = {};

        for i = 1, count do
            local t = instances[i];
            vs[i] = vs[i] or {};
            t.transform:toColMajorArray(vs[i]);
            vs[i][17] = t.color.x;
            vs[i][18] = t.color.y;
            vs[i][19] = t.color.z;
            vs[i][20] = t.alpha;
        end

        vs[count + 1] = nil;

        mesh:setVertices(vs);
    end,

    BASIC_ATTRIBUTES = BASIC_ATTRIBUTES
}


return mesh;