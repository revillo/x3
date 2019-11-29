local x3mesh = require("x3mesh");

local splitSpaceRegex = ("([^%s]+)"):format(" ");
local splitSlashRegex = ("([^%s]+)"):format("/");

local function splitSlash(str)
    local result = {}
    local regex = splitSlashRegex

    local i = 1;

    for each in str:gmatch(regex) do
       result[i] = tonumber(each);
       i = i + 1;
    end

    result[2] = result[2] or result[1];
    result[3] = result[3] or result[1];
    return result
 end


local newArray = function()
    return {size = 0;}
end

local push = function(array, elem)
    array.size = array.size + 1;
    array[array.size] = elem;
end

local nilOr = function(value, default)
    if (value == nil) then return default else return value end;
end

local loadObj = function(uri, opts)

    local opts = opts or {};
    opts.swapVertexOrder = nilOr(opts.swapVertexOrder, true); 

    local positions = newArray();
    local normals = newArray();
    local uvs = newArray();
    local indices = newArray();

    local meshByName = {};
    local meshName = "";
    
    local createMesh = function(name)

        local verts = newArray();
        local defaultUV = {0,0};
        local defaultNormal = {0,1,0};

        local function addVert(is)            
            local p = positions[is[1]];  

            local uv = uvs[is[2]] or defaultUV;
            local n = normals[is[3]] or defaultNormal;
            push(verts, {p[1], p[2], p[3], n[1], n[2], n[3], uv[1], uv[2]});
        end
    
        local loadTriangle, loadQuad;
        
        if (opts.swapVertexOrder) then
            loadTriangle = function(face)
                addVert(face[1]);
                addVert(face[3]);
                addVert(face[2]);
            end
        else
            loadTriangle = function(face)
                addVert(face[1]);
                addVert(face[2]);
                addVert(face[3]);
            end
        end
    
        if (opts.swapVertexOrder) then
            loadQuad = function(face)
                addVert(face[1]);
                addVert(face[3]);
                addVert(face[2]);
    
                addVert(face[1]);
                addVert(face[4]);
                addVert(face[3]);
            end
    
        else
            loadQuad = function(face)
                addVert(face[1]);
                addVert(face[2]);
                addVert(face[3]);
    
                addVert(face[1]);
                addVert(face[3]);
                addVert(face[4]);
            end
        end
    
        for f = 1,indices.size do
            local face = indices[f];
            if (face[4]) then
                loadQuad(face);
            else
                loadTriangle(face);
            end
        end
    
        local mesh = love.graphics.newMesh(
            x3mesh.BASIC_ATTRIBUTES, verts, "triangles", "static"
        );

        meshByName[name] = mesh;
        
        indices = newArray();
    end


    local parseLine = function(line)

        local first = true;
        local nameLine = false;
        local array;
        local entry;
        local entryI = 0;

        for each in line:gmatch(splitSpaceRegex) do

            if (first) then
                if (each == "#") then 
                    return
                elseif (each == "vn") then
                    array = normals;
                    first = false;
                elseif (each == "v") then
                    array = positions;
                    first = false;
                elseif (each == "vt") then
                    array = uvs; 
                    first = false;
                elseif (each == "f") then
                    array = indices;
                    first = false;
                elseif (each == "o") then
                    nameLine = true;
                    first = false;
                    array = {size = 0};
                elseif (each == "s") then
                    return;
                end

                if (not first) then
                    entry = {};
                    push(array, entry);
                end
            else

                --New mesh name or first mesh name
                if (nameLine) then
                    if (positions.size > 0) then
                        createMesh(meshName);
                    end

                    meshName = each;
                    return;
                end

                if (array == indices) then
                    entryI = entryI + 1;
                    entry[entryI] = splitSlash(each);
                else
                    entryI = entryI + 1;
                    entry[entryI] = tonumber(each);
                end
            end
        end
    end

    -- Works over network on castle
    for line in love.filesystem.lines(uri) do
        parseLine(line);
    end

    --Create the last mesh
    createMesh(meshName);


    return {
        --All meshes
        meshesByName = meshByName,
        
        --Last mesh
        mesh = meshByName[meshName]
    };

end


return {
    loadObj = loadObj
}


