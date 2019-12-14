local x3 = {};

local extend = function(module)
    for k, v in pairs(module) do
        x3[k] = v;
    end
end

local namespace = function(name, module)
    x3[name] = module;
end

extend(require("x3math"));
extend(require("x3render"));
extend(require("x3scene"));
extend(require("loaders/x3obj"));
extend(require("x3material"));
extend(require("x3util"));

namespace("mesh", require("x3mesh"));

return x3;