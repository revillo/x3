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

local loadObj = function(uri)

    local positions = newArray();
    local normals = newArray();
    local uvs = newArray();

    local indices = newArray();

    local parseLine = function(line)

        local first = true;
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
                    return;
                elseif (each == "s") then
                    return;
                end

                if (not first) then
                    entry = {};
                    push(array, entry);
                end
            else

                if (array == indices) then
                    --push(entry, splitSlash(each));
                    entryI = entryI + 1;
                    entry[entryI] = splitSlash(each);

                    if (entryI > 3) then
                        error("Please triangulate .OBJ model faces.")
                    end
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
    --[[
    print("np", positions.size);

    for i = 1,  do
        print (i);
        for k, v in ipairs(positions[i]) do
            print(k, v);
        end
    end
    l]]

    local verts = newArray();


    local defaultUV = {0,0};
    local defaultNormal = {0,1,0};

    for f = 1,indices.size do
        local face = indices[f];
        for v = 1, 3 do
            local is = face[v];
            local p = positions[is[1]];
            
            local uv = uvs[is[2]] or defaultUV;
            local n = normals[is[3]] or defaultNormal;
            push(verts, {p[1], p[2], p[3], n[1], n[2], n[3], uv[1], uv[2]});
        end
    end

    local mesh = love.graphics.newMesh(
        x3mesh.BASIC_ATTRIBUTES, verts, "triangles", "static"
    );

    return {
        mesh = mesh
    };

end


return loadObj;


