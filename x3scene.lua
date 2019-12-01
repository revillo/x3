local x3m = require('x3math');

local vec3 = x3m.vec3;
local quat = x3m.quat;
local mat4 = x3m.mat4;


local x3mesh = require("x3mesh");

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

local initNode = function(n, props)

    props = props or {};

    n.position = vec3(0);
    if (props.position) then
        n.position:copy(props.position)
    end

    n.rotation = quat();  
    if (props.rotation) then
        n.rotation:copy(props.rotation)
    end

    n.scale = vec3(1);
    if (props.scale) then
        n.scale:copy(props.scale)
    end

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

    setNumInstances = function(e, numInstances)

        if (not e.mesh) then
            error("Cannot instance entity without mesh.")
        end

        e.numInstances = numInstances;
        local transforms = {};
        
        for i = 1,e.numInstances do
            transforms[i] = mat4();
        end

        e.instanceMesh, e.instanceData = x3mesh.newInstanceMesh(transforms);
        e.instanceTransforms = transforms;
        e.instancesDirty = false;

    end,

    setInstanceTransform = function(e, instanceIndex, transform)
        e.instancesDirty = true;
        e.instanceTransforms[instanceIndex]:copy(transform);
    end,

    updateInstances = function(e)
        x3mesh.updateInstanceMesh(e.instanceTransforms, e.instanceMesh, e.instanceData);
    end,

    render = function(e)
        
        e:updateTransform();

        if (not e.mesh) then
            return;
        end

        --todo
        if (e.numInstances == 0) then
            e:setNumInstances(1);
        end

        if (e.instancesDirty) then
            e:updateInstances();
            e.instancesDirty = false;
        end

        local shader = e.material.shader;

        --shader:setActive();

        local modelMesh = e.mesh;
        local instanceMesh = e.instanceMesh;

        --todo world transform
        shader:sendMat4("u_Model", e.transform);
        --shader:sendMatrix("u_ViewProjection", vp);

        --todo move
        for name, val in pairs(e.material.uniforms) do
            shader:send(name, val);
        end

        modelMesh:attachAttribute("InstanceTransform1", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform2", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform3", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform4", instanceMesh, "perinstance");

        love.graphics.drawInstanced(modelMesh, e.numInstances);
    end


}

extend(entity.__index, nodeMeta);

entity.new = function(mesh, material)
    local e = {
        mesh = mesh,
        material = material,
        numInstances = 0
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

local light = {}

light.__index = {

}

extend(light.__index, nodeMeta);

local function newPointLight(props)
    local l = {};

    l.intensity = props.intensity or 1;
    l.color = props.color or {1,1,1};
    l.type = "Point";
    l.isLight = true;

    initNode(l, props);
    setmetatable(l, light);
    return l;
end


return {
    newCamera = camera.new,
    newScene = scene.new,
    newEntity = entity.new,
    newPointLight = newPointLight
}

