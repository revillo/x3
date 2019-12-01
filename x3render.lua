local x3m = require('x3math');
local vec3 = x3m.vec3;
local mat4 = x3m.mat4;
local quat = x3m.quat;


local x3r = {};

x3r.newCanvas3D = function(...)

  local colorCanvas = love.graphics.newCanvas(...);

  colorCanvas:setFilter("linear", "linear");

  return {
    color = colorCanvas;
  }

end

local viewProjection = mat4();

local renderEntity, binEntity;

renderEntity = function(entity, vp)

  if (entity.mesh and entity.material) then
    entity:render(vp);
  end

  --entity:eachChild(renderEntity, vp);

end

binEntity = function(entity, eByShader, renderIndex)

  if (entity.mesh and entity.material) then
    local x3shader = entity.material.shader;
    local bin = eByShader[x3shader] or {entities = {}, renderIndex = 0, size = 0}; 

    bin.renderIndex = renderIndex;
    bin.size = bin.size + 1;
    bin.entities[bin.size] = entity;

    eByShader[x3shader] = bin;
  end

  entity:eachChild(binEntity, eByShader, renderIndex);

end

local CLEAR_COLOR = {0,0,0,1}
local renderIndex = 0;

local binsForScene = {};

x3r.render = function(camera, scene, canvas3D, options)

  options = options or {};  
  
  binsForScene[scene] = binsForScene[scene] or {};

  for _, bin in pairs(binsForScene[scene]) do
    bin.size = 0;
  end

  renderIndex = renderIndex + 1;

  if (renderIndex == 100000) then
    renderIndex = 0;
    binsForScene = {};
  end

  options.cullMode = options.cullMode or "back";

  if(options.clear == nil) then
    options.clear = true;
  end

  options.clearColor = options.clearColor or CLEAR_COLOR;

  love.graphics.setCanvas({
    {canvas3D.color},
    depth = true,
    stencil = true
  });

  love.graphics.setMeshCullMode(options.cullMode);
  
  --Todo fix depth buffer
  love.graphics.setDepthMode("lequal", true);

  local cc = options.clearColor;
  love.graphics.clear(cc[1],cc[2],cc[3],cc[4], true, true);
  love.graphics.setColor(1,1,1,1);
  
  camera:updateView();
  viewProjection:copy(camera.projection);
  viewProjection:mul(camera.view);

  binEntity(scene, binsForScene[scene], renderIndex);

  for x3Shader, bin in pairs(binsForScene[scene]) do
    if (bin.renderIndex == renderIndex) then
      x3Shader:sendMat4("u_ViewProjection", viewProjection);
      x3Shader:setActive();
      local entities = bin.entities;
      for i = 1,bin.size do
        renderEntity(entities[i]);
      end
    end
  end

  --renderEntity(scene, viewProjection);

  love.graphics.setShader();
  love.graphics.setCanvas();

end


return x3r;


