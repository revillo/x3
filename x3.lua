local x3 = {};

local extend = function(file)
    local module = require(file);
    for k, v in pairs(module) do
        x3[k] = v;
    end
end

local namespace = function(name, file)
    local module = require(file);
    x3[name] = module;
end

extend("x3math");
extend("x3render");
extend("x3scene");
extend("loaders/x3obj")

namespace("mesh", "x3mesh");
namespace("material", "x3material");

return x3;