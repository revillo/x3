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

local v3tmp = x3m.vec3();

local transformMeta = {

    updateTransform = function(n)
        n.transform:compose(n.position, n.rotation, n.scale);
    end,

    markClean = function(n)
        n.dirty = false;
        if (n.parent) then
            n.parent.dirtyChildren[n.uuid] = nil;
        end
    end,

    markDirty = function(n)
        n.dirty = true;
        if (n.parent) then
            n.parent.dirtyChildren[n.uuid] = n;
        end
    end,

    getLocalXAxis = function(n, out)
        n:updateTransform();
        local v = out or v3tmp;
        v:set(n.transform[0], n.transform[1], n.transform[2]);
        v:normalize();
        return v;
    end,

    getLocalYAxis = function(n, out)
        n:updateTransform();
        local v = out or v3tmp;
        v:set(n.transform[4], n.transform[5], n.transform[6]);
        v:normalize();
        return v;
    end,

    getLocalZAxis = function(n, out)
        n:updateTransform();
        local v = out or v3tmp;
        v:set(n.transform[8], n.transform[9], n.transform[10]);
        v:normalize();
        return v;
    end,

    getPosition = function(n, out)
        if (out) then
            out:copy(n.position);
            return out;
        else
            return n.position;
        end
    end,

    getRotation = function(n, out)
        if (out) then
            out:copy(n.rotation);
            return out;
        else
            return n.rotation;
        end
    end,

    getScale = function(n, out)
        if (out) then
            out:copy(n.position);
            return out;
        else
            return n.position;
        end
    end,

    rotateAxis = function(n, axis, angle)
        n.rotation:rotateAxisAngle(axis, angle);
        n:markDirty();
    end,

    resetRotation = function(n)
        n.rotation:setIdentity();
        n:markDirty();
    end,

    rotateLocalX = function(n, angle)
        n:rotateAxis(n:getLocalXAxis(), angle);
    end,

    rotateLocalY = function(n, angle)
        n:rotateAxis(n:getLocalYAxis(), angle);
    end,

    rotateLocalZ = function(n, angle)
        n:rotateAxis(n:getLocalZAxis(), angle);
    end,

    setRotation = function(n, q, y, z, w)
        if (y) then
            n.quat:set(q,y,z,w);
        else
            n.quat:copy(q);
        end
        n:markDirty();
    end,

    setPosition = function(n, v, y, z)
        if (y) then
            n.position:set(v, y, z);
        else
            n.position:copy(v);
        end
        n:markDirty();
    end,

    copyPosition = function(n, n2)
        n:setPosition(n2:getPosition());
    end,

    copyRotation = function(n, n2)
        n:setRotation(n2:getRotation());
    end,

    copyScale = function(n, n2)
        n:setScale(n2:getScale());
    end,

    move = function(n, v, y, z)
        if (y) then
            v3tmp:set(v, y, z);
            n.position:add(v3tmp);
        else
            n.position:add(v);
        end
        n:markDirty();
    end,

    moveLocalX = function(n, dist)
        n:getLocalXAxis(v3tmp);
        v3tmp:scale(dist);
        n:move(v3tmp);
    end,

    moveLocalY = function(n, dist)
        n:getLocalYAxis(v3tmp);
        v3tmp:scale(dist);
        n:move(v3tmp);
    end,

    moveLocalZ = function(n, dist)
        n:getLocalZAxis(v3tmp);
        v3tmp:scale(dist);
        n:move(v3tmp);
    end,

    setScale = function(n, v, y, z)
        if (y) then
            n.scale:set(v, y, z);
        else
            if (type(v) == "number") then
                n.scale:set(v,v,v);
            else
                n.scale:copy(v);
            end
        end
        n:markDirty();
    end
}

local nodeMeta = {
    add = function(n, child)
        n.children[child.uuid] = child;
        
        if (child.parent) then
            child.parent:remove(child);
        end
        
        child.parent = n;

        if (child.dirty) then
            child:markDirty();
        end
        return n;
    end,

    remove = function(n, child)
        child.parent = nil;
        n.children[child.uuid] = nil;
        n.dirtyChildren[child.uuid] = nil;
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
    n.dirtyChildren = {};
    n.dirty = true;

    return n;
end

local camera = {};

camera.__index = {
    
    lookAt = function(c, target, up)
        --c.position:copy(eye);
        c.transform:setLookAt(c.position, target, up);
        c.rotation:fromMat4(c.transform);
    end,

    updateView = function(c)
        --c:lookAt(c.position, c.target, c.up);
        c:updateTransform();
        c.view:copy(c.transform);
        c.view:invert();
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

extend(camera.__index, transformMeta);
extend(camera.__index, nodeMeta);

camera.new = function()
    local c = {};
    initNode(c);

    c.position = vec3(0,0,-1);
    
    --c.target = vec3(0);
    --c.up = vec3(0, 1, 0);
    
    c.view = mat4();
    
    c.projection = mat4();
    --c.transform = mat4();

    local s = 0.5;
    c.projection:setPerspective(-s, s, -s, s, 0.5, 100);
    setmetatable(c, camera);
    return c;
end


local instance = {};

instance.__index = {
    
};

extend(instance.__index, transformMeta);


local entity = {};

entity.__index = {

    setNumInstances = function(e, numInstances)

        if (not e.mesh) then
            error("Cannot instance entity without mesh.")
        end

        if (e.numInstances == numInstances) then
            return;
        end

        e.numInstances = numInstances;
        local instances = {};
        
        for i = 1,e.numInstances do
            instances[i] = {
                position = x3m.vec3(),
                rotation = x3m.quat(),
                scale = x3m.vec3(1.0),
                transform = x3m.mat4(),
                parent = e,
                uuid = i
            };
            setmetatable(instances[i], instance);
        end

        e.instanceMesh, e.instanceData = x3mesh.newInstanceMesh(instances);
        e.instances = instances;

    end,

    getNumInstances = function(e)
        return e.numInstances;
    end,

    getInstance = function(e, index)
        return e.instances[index];
    end,

    --[[
    setInstanceTransform = function(e, instanceIndex, transform)
        e.instancesDirty = true;
        e.instanceTransforms[instanceIndex]:copy(transform);
    end,

    setInstance = function(e, instanceIndex, position, rotation, scale)
        e.instancesDirty = true;
        e.instanceTransforms[instanceIndex]:compose(position, rotation, scale);
    end,
    ]]

    updateInstances = function(e)

        if (e.numInstances == 0) then
            return;
        end

        for i, n in pairs(e.dirtyChildren) do
            n:updateTransform();
            n:markClean();
        end

        x3mesh.updateInstanceMesh(e.instances, e.instanceMesh, e.instanceData);

        for i = 1, e.numInstances do
            --print(i);
            --print(e.instances[i].transform:__tostring());
        end

    end,

    instancesNeedUpdate = function(e)

        if (e.numInstances == 0) then
            return false;
        end

        for k, v in pairs(e.dirtyChildren) do
            return true;
        end
    end,

    render = function(e)
        
        --e:updateTransform();

        if (not e.mesh) then
            return;
        end

        --todo
        if (e.numInstances == 0) then
            e:setNumInstances(1);
        end

        if (e:instancesNeedUpdate()) then
            e:updateInstances();
        end

        local shader = e.material.shader;

        --shader:setActive();

        local modelMesh = e.mesh;
        local instanceMesh = e.instanceMesh;

        --todo world transform
        shader:sendMat4("u_Model", e.worldTransform);
        --shader:sendMatrix("u_ViewProjection", vp);

        --todo move
        for name, val in pairs(e.material.uniforms) do
            shader:send(name, val);
        end

        local opts = e.material.options or {};
        love.graphics.setMeshCullMode(opts.cullMode or "back");

        modelMesh:attachAttribute("InstanceTransform1", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform2", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform3", instanceMesh, "perinstance");
        modelMesh:attachAttribute("InstanceTransform4", instanceMesh, "perinstance");

        love.graphics.drawInstanced(modelMesh, e.numInstances);
    end


}

extend(entity.__index, transformMeta);
extend(entity.__index, nodeMeta);

entity.new = function(mesh, material)

    local e;
    if (material) then
        e = {
            mesh = mesh,
            material = material,
            numInstances = 0
        };
        initNode(e);
    else
        e = {};
        mesh =  mesh or {};
        initNode(e, mesh);
        e.mesh = mesh.mesh;
        e.material = mesh.material;
    end

    setmetatable(e, entity);
    return e;
end

--[[
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
]]

local light = {}

light.__index = {

}

extend(light.__index, transformMeta);
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

local updateWorldTransforms;

--Updates local and world transforms for all descendants
function updateWorldTransforms(node, parentDirty)

    local dirty = not not node.dirty;

    if (dirty) then
        node:updateTransform();
    end

    if (parentDirty == nil and dirty) then
        node.worldTransform:copy(node.transform);
    elseif (parentDirty or dirty) then
        node.worldTransform:copy(node.parent.worldTransform);
        node.worldTransform:mul(node.transform);
    end

    node:markClean();

    node:eachChild(updateWorldTransforms, dirty or parentDirty);
end

return {
    newCamera = camera.new,
    --newScene = scene.new,
    newEntity = entity.new,
    newPointLight = newPointLight,
    updateWorldTransforms = updateWorldTransforms
}

