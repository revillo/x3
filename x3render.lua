local x3m = require('x3math');
local vec3 = x3m.vec3;
local mat4 = x3m.mat4;
local quat = x3m.quat;


local x3r = {};

x3r.createCanvas3D = function(...)

  local colorCanvas = love.graphics.newCanvas(...);

  colorCanvas:setFilter("linear", "linear");

  return {
    color = colorCanvas;
  }

end

local function sendShaderMatrix(shader, name, m)
  if (shader:hasUniform(name)) then
    
    --switch to row major
    shader:send(name, {
      m[0], m[4], m[8], m[12],
      m[1], m[5], m[9], m[13],
      m[2], m[6], m[10], m[14],
      m[3], m[7], m[11], m[15]
    });
  end
end

local viewProjection = mat4();
local mvp = mat4();

local renderEntity;

renderEntity = function(entity, vp)

  entity:updateTransform();

  if (entity.mesh and entity.material) then
    --Setup MVP matrix
    local mat = entity.material;
    mvp:copy(vp);
    mvp:mult(entity.transform);

    love.graphics.setShader(mat.shader);

    --Send uniforms
    for name, val in pairs(mat.uniforms) do
      if (mat.shader:hasUniform(name)) then
        mat.shader:send(name, val)
      end
    end

    sendShaderMatrix(mat.shader, "mvp", mvp);
    --draw
    love.graphics.draw(entity.mesh);
  end

  entity:eachChild(renderEntity, vp);

end

x3r.render = function(camera, scene, canvas3D, options)

  options = options or {};
  
  if(options.clear == nil) then
    options.clear = true;
  end

  options.clearColor = options.clearColor or {0,0,0,1};

  love.graphics.setCanvas({
    {canvas3D.color},
    depth = true,
    stencil = true
});

  love.graphics.setMeshCullMode("back");
  
  --Todo fix depth buffer
  love.graphics.setDepthMode("lequal", true);

  local cc = options.clearColor;
  love.graphics.clear(cc[1],cc[2],cc[3],cc[4], true, true);
  love.graphics.setColor(1,1,1,1);
  
  camera:updateView();

  local projection = camera.projection;
  local view = camera.view;

  viewProjection:copy(projection);
  viewProjection:mult(view);

  renderEntity(scene, viewProjection);

  love.graphics.setShader();
  love.graphics.setCanvas();

end


return x3r;


