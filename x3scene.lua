local x3m = require('x3math');
local vec3 = x3m.vec3;
local quat = x3m.quat;
local mat4 = x3m.mat4;


local extend = function(meta, props)
    for n, f in pairs(props) do
        meta[n] = f;
    end
end

local nodeMeta = {
    updateTransform = function(n)
        n.transform:compose(n.position, n.rotation, n.scale);
    end,

    add = function(n, child)
        n.children[child.uuid] = child;
        
        if (child.parent) then
            child.parent.children[child.uuid] = nil;
        end
        
        child.parent = n;
        return n;
    end,

    remove = function(n, child)
        child.parent = nil;
        n.children[child.uuid] = nil;
        return n;
    end,

    removeFromParent = function(n)
        if (n.parent) then
            n.parent:remove(n);
        end
    end,

    addToParent = function(n, parent)
        parent:add(n);
    end,

    eachChild = function(n, callback, ...)
        for uuid, child in pairs(n.children) do  
            callback(child, ...);
        end
    end
}


local nodeUUID = 0;

local initNode = function(n)
    n.position = vec3(0);
    n.rotation = quat();
    n.scale = vec3(1);
    n.transform = mat4();
    n.worldTransform = mat4();
    nodeUUID = nodeUUID + 1;
    n.uuid = nodeUUID;
    n.children = {};
end

local once = true;
local camera = {};

camera.__index = {
    
    lookAt = function(c, eye, target, up)
        c.position:copy(eye);
        c.transform:setLookAt(eye, target, up);
    end,

    updateView = function(c)
        c:lookAt(c.position, c.target, c.up);
        c.view:copy(c.transform);
        c.view:invert();

        --[[
        if (once) then
            print(c.view:__tostring());
            once = false;
        end

        --c.view:setIdentity();
        ]]

    end,

    -- fov : degrees, aspect : number (height / width), near : number, far : number 
    setPerspective = function(c, fov, aspect, near, far)
        
        local fovRadians = (fov / 180) * math.pi;
        local tanX = math.tan(fovRadians * 0.5);
        local tanY = tanX * aspect;

        local x = tanX * near;
        local y  = tanY * near;

        c.projection:setPerspective(-x, x, -y, y, near, far);
    end,

    setOrthographic = function(c, left, right, bottom, top, near, far)
        c.projection:setOrtho(left, right, bottom, top, near, far);
    end

}

extend(camera.__index, nodeMeta);

camera.new = function()
    local c = {};
    --initNode(c);

    c.position = vec3(0,0,-1);
    c.target = vec3(0);
    c.up = vec3(0, 1, 0);
    c.view = mat4();
    c.projection = mat4();
    c.transform = mat4();

    local s = 0.5;
    c.projection:setPerspective(-s, s, -s, s, 0.5, 100);
    setmetatable(c, camera);
    return c;
end


local entity = {};

entity.__index = {

}

extend(entity.__index, nodeMeta);

entity.new = function(mesh, material)
    local e = {
        mesh = mesh,
        material = material
    };

    initNode(e);
    setmetatable(e, entity);
    return e;
end


local scene = {};

scene.__index = {

}

extend(scene.__index, nodeMeta);

scene.new = function()
    local s = {};
    initNode(s);
    setmetatable(s, scene);
    return s;
end

return {
    newCamera = camera.new,
    newScene = scene.new,
    newEntity = entity.new
}