local x3m = require('x3math');
local x3s = require('x3scene');

local vec3 = x3m.vec3;
local mat4 = x3m.mat4;
local quat = x3m.quat;


local x3r = {};

x3r.newCanvas3D = function(...)

  local colorCanvas = love.graphics.newCanvas(...);

  colorCanvas:setFilter("linear", "linear");

  return {
    color = colorCanvas,
    width = colorCanvas:getWidth(),
    height = colorCanvas:getHeight()
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

binEntity = function(entity, bins, renderIndex)

  if (entity.mesh and entity.material) then

    if (entity.renderOrder and entity.renderOrder > 0) then
      bins.ordered.size = bins.ordered.size + 1;
      bins.ordered.entities[bins.ordered.size] = entity;
    else

      local x3shader = entity.material.shader;
      local bin = bins.shaders[x3shader] or {entities = {}, renderIndex = 0, size = 0}; 

      bin.renderIndex = renderIndex;
      bin.size = bin.size + 1;
      bin.entities[bin.size] = entity;

      bins.shaders[x3shader] = bin;

    end
  end

  if (entity.isLight) then
    local bin = bins.lights[entity.type];-- or {entities = {}, renderIndex = 0, size = 0};

    bin.renderIndex = renderIndex;
    bin.size = bin.size + 1;
    bin.entities[bin.size] = entity;

    bins.lights[entity.type] = bin;
  end

  entity:eachChild(binEntity, bins, renderIndex);

end

local CLEAR_COLOR = {0,0,0,1}
local renderIndex = 0;

local binsForScene = {};


local resetBins = function(scene)

  binsForScene[scene] = binsForScene[scene] or {
    shaders = {},
    ordered = {
      size = 0,
      entities = {}
    },
    lights = {
      Point = {entities = {}, renderIndex = 0, size = 0}
    };
  };

  local bins = binsForScene[scene];

  for _, bin in pairs(bins.shaders) do
    bin.size = 0;
  end
  
  for _, bin in pairs(bins.lights) do
    bin.size = 0;
  end

  bins.ordered.size = 0;


  return bins;

end

local function roCompare(e1, e2)

  return e1.renderOrder < e2.renderOrder;

end


local fillLightUniforms = function(lightBins)
  local positions = {};
  local intensities = {};
  local colors = {};
  local pointLights = lightBins.Point;

  for i = 1, pointLights.size do
    local entity = pointLights.entities[i];
    local wt = entity.worldTransform;
    positions[i] = {wt[12], wt[13], wt[14]};
    intensities[i] = entity.intensity;
    colors[i] = entity.color;
  end

  return {
    Point = {
      positions = positions,
      intensities = intensities,
      colors = colors,
      count = pointLights.size
    }
  };

end



local sendLights = function(shader, lights)
  
  if (shader.options.defines.LIGHTS ~= 1) then
    return;
  end

  if (lights.Point.count > 0) then
    shader:sendArray("u_PointLightPositions", lights.Point.positions);
    shader:sendArray("u_PointLightIntensities", lights.Point.intensities);
    shader:sendArray("u_PointLightColors", lights.Point.colors);
  end

  shader:send("u_NumPointLights", lights.Point.count);

end

local CamPos = {0,0,0};

local prepareShader = function(shader, lightUniforms)
  shader:setActive();
  shader:sendMat4("u_ViewProjection", viewProjection);
  shader:send("u_WorldCameraPosition", CamPos);
  shader:send("u_Time", love.timer.getTime());
  
  sendLights(shader, lightUniforms);
end

local renderShaderBin = function(shader, bin, lightUniforms)
  if (bin.renderIndex == renderIndex) then
    
    prepareShader(shader, lightUniforms);

    local entities = bin.entities;
    for i = 1,bin.size do
      renderEntity(entities[i]);
    end
  end
end

x3r.render = function(camera, scene, canvas3D, options)
  renderIndex = renderIndex + 1;

  if (renderIndex == 100000) then
    renderIndex = 0;
    binsForScene = {};
  end

  options = options or {};  
 
  local bins = resetBins(scene);

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
  
  x3s.updateWorldTransforms(scene);

  camera:updateView();
  viewProjection:copy(camera.projection);
  viewProjection:mul(camera.view);

  CamPos[1], CamPos[2], CamPos[3] = camera.transform[12], camera.transform[13], camera.transform[14];

  binEntity(scene, bins, renderIndex);

  local lightUniforms = fillLightUniforms(bins.lights);

  for x3Shader, bin in pairs(bins.shaders) do
    --if (not x3Shader.options.transparent) then
      renderShaderBin(x3Shader, bin, lightUniforms);
    --end
  end

  if (bins.ordered.size > 0) then
    
    bins.ordered.entities[bins.ordered.size + 1] = nil;

    table.sort(bins.ordered.entities, roCompare);
    for i, entity in ipairs(bins.ordered.entities) do
      prepareShader(entity.material.shader, lightUniforms);
      renderEntity(entity);
    end

  end

  --[[
  for x3Shader, bin in pairs(bins.shaders) do
    if (x3Shader.options.transparent) then
      renderShaderBin(x3Shader, bin, lightUniforms);
    end
  end
  ]]
  --renderEntity(scene, viewProjection);

  love.graphics.setShader();
  love.graphics.setCanvas();

end

x3r.displayCanvas3D = function (canvas3D, x, y)
  
  love.graphics.setShader();
  love.graphics.setCanvas();

  love.graphics.draw(canvas3D.color, x, y + canvas3D.height, 0, 1, -1);
end

return x3r;


