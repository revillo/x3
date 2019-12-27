
local now = love.timer.getTime

local Timer = {

}

Timer.__index = {

    addCooldown = function(t, name, duration)
        t.cooldowns[name] = {now(), duration};
    end,

    resetCooldown = function(t, name)
        t.cooldowns[name][1] = now()
    end,

    clearCooldowns = function(t)
        t.cooldowns = {};
    end,

    timeLeft = function(t, name)
        local cd = t.cooldowns[name];

        local elapsed = now() - cd[1];
        local remaining = cd[2] - elapsed;

        return remaining, remaining / cd[2];
    end,

    ezCooldown = function(t, name, duration)
        if (not t.cooldowns[name]) then
            t:addCooldown(name, duration);
        end

        local timeLeft, timeLeftPct = t:timeLeft(name);

        if (t:timeLeft(name) <= 0.0) then
            t:resetCooldown(name);
            return true
        else
            return false, timeLeft, timeLeftPct;
        end
    end

}

Timer.new = function()
    local t = {
        cooldowns = {};
    }

    setmetatable(t, Timer);
    return t;
end

local Automap = {};

Automap.__index = {
    add = function(m, val)
        m.idCounter = m.idCounter + 1;
        m.data[m.idCounter] = val;
        m.size = m.size + 1;
    end,

    filter = function(m, fn, ...)
        for id, val in pairs(m.data) do
            if (fn(val, ...)) then
                m.data[id] = nil;
                m.size = m.size - 1;
            end
        end
    end
}

Automap.new = function()
    local m = {
        data = {},
        idCounter = 0,
        size = 0
    };

    setmetatable(m, Automap);
    return m;
end

return {
    now = now,
    newTimer = Timer.new,
    newAutomap = Automap.new
}