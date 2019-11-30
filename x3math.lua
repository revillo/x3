------------
--- vec3 ---
------------

local vec3 = {};
local v3tmp = {};
local qtmp;

vec3.__index = {

    clone = function(a)
        return vec3.new(a.x, a.y, a.z);
    end,

    set = function(a, x, y, z)
        a.x, a.y, a.z = x, y, z;
    end,

    copy = function(a, b)
        a.x, a.y, a.z = b.x, b.y, b.z;
    end,

    fromArray = function(v, a)
        v.x = a[1];
        v.y = a[2];
        v.z = a[3];
    end,

    --Spherical to cartesian coordinates. Theta around z axis.
    --theta : (0, 2pi) ,  phi : (0, pi)
    fromSphere = function(v, theta, phi, radius)
        v.x = math.sin(theta) * math.sin(phi) * radius;
        v.y = math.cos(theta) * math.sin(phi) * radius;
        v.z = math.cos(phi) * radius;
    end,

    add = function(a, b)
        a.x = a.x + b.x;
        a.y = a.y + b.y;
        a.z = a.z + b.z;
    end,

    sub = function(a, b)
        a.x = a.x - b.x;
        a.y = a.y - b.y;
        a.z = a.z - b.z;
    end,

    mul = function(a, b)
        a.x = a.x * b.x;
        a.y = a.y * b.y;
        a.z = a.z * b.z;
    end,

    dot = function(a, b)
        return a.x * b.x + a.y * b.y + a.z * b.z;
    end,

    scale = function(a, s)
        a.x = a.x * s;
        a.y = a.y * s;
        a.z = a.z * s;
    end,

    lengthsq = function(a)
        return a:dot(a);
    end,

    length = function(a)
        return math.sqrt(a:lengthsq());
    end,

    normalize = function(a)
        local length = a:length();
        if (length > 0.0) then
            a:scale(1/length);
        end
    end,

    --Sets v to be v x b
    cross = function(v, b)
        v:setCross(v, b);
    end,

    --Sets v to be a x b
    setCross = function(v, a, b)
        local ax, ay, az = a.x, a.y, a.z;
        local bx, by, bz = b.x, b.y, b.z;

        v.x = ay * bz - az * by;
        v.y = az * bx - ax * bz;
        v.z = ax * by - ay * bx;
    end,

    --Sets v to be unit vector perpendicular to a and b
    setPerpendicular = function(v, a, b)
        local dot = a:dot(b);

        if (math.abs(dot) < 0.999) then
            v:setCross(a, b);
            v:normalize();
        else
            v:set(-a.z, a.x, a.y);
            v:setCross(v, b);
            v:normalize();
        end
    end,

    --Sets v to be unit direction from a to b
    setDirection = function(v, a, b)
        v:copy(b);
        v:sub(a);
        v:normalize();
    end,

    --Optionally supply w, a 4th vector component
    applyMat4 = function(v, m, w)
        w = w or 1;
        local x, y, z = v.x, v.y, v.z;

        v.x = m[0] * x + m[4] * y + m[8] * z + m[12] * w;
        v.y = m[1] * x + m[5] * y + m[9] * z + m[13] * w;
        v.z = m[2] * x + m[6] * y + m[10] * z + m[14] * w;
    end,

    applyQuat = function(v, q)
        local u, c = v3tmp[1], v3tmp[2];
        u.x, u.y, u.z = q.x, q.y, q.z;

        c:setCross(u, v);
        local uu = u:lengthsq();
        local uv = u:dot(v);
        
        v:scale(q.w * q.w - uu)
        u:scale(2 * uv)
        c:scale(2 * q.w)

        v:add(u);
        v:add(c);
    end,

    components = function(v)
        return v.x, v.y, v.z;
    end,

    __tostring = function(a)
        return "{"..a.x..","..a.y..","..a.z.."}";
    end
};

vec3.new = function(x, y, z)
    x = x or 0;
    y = y or x;
    z = z or x;

    local v = {x = x, y = y, z = z};
    setmetatable(v, vec3);
    return v;
end

for i = 1,3 do
    v3tmp[i] = vec3.new();
end

local FORWARD = vec3.new(0, 0, -1);
local UP = vec3.new(0, 1, 0);
local RIGHT = vec3.new(1, 0, 0);

------------
--- quat ---
------------

local quat = {};

quat.__index = {

    clone = function(q)
        return quat.new(q.x, q.y, q.z, q.w);
    end,

    set = function(q, x, y, z, w)
        q.x, q.y, q.z, q.w = x, y, z, w;
    end,

    setIdentity = function(q)
        q.x, q.y, q.z, q.w = 0, 0, 0, 1;
    end,

    reset = function(q)
        q:setIdentity();
    end,

    mul = function(q, r)
        local qx, qy, qz, qw = q:components();
        local rx, ry, rz, rw = r:components();

        q.x = qx * rw + qw * rx + qy * rz - qz * ry;
        q.y = qy * rw + qw * ry + qz * rx - qx * rz;
        q.z = qz * rw + qw * rz + qx * ry - qy * rx;
        q.w = qw * rw - qx * rx - qy * ry - qz * rz;
    end,

    copy = function(a, b)
        a.x = b.x;
        a.y = b.y;
        a.z = b.z;
        a.w = b.w;
    end,

    -- Sets quaternion to be axis/angle rotation
    -- axis : vec3, angle : radians
    setAxisAngle = function(q, axis, angle)
        local halfAngle = angle * 0.5;
        local s = math.sin(halfAngle);
        q.x = axis.x * s;
        q.y = axis.y * s;
        q.z = axis.z * s;
        q.w = math.cos(halfAngle);
    end,

    -- Rotate this quaternion by axis/angle
    -- axis : vec3, angle : radians
    rotateAxisAngle = function(q, axis, angle)
        qtmp:setAxisAngle(axis, angle);
        q:mul(qtmp);
    end,

    dot = function(a, b)
        return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    end,

    scale = function(q, s)
        q.x = q.x * s;
        q.y = q.y * s;
        q.z = q.z * s;
        q.w = q.w * s;
    end,

    invert = function(q)
        q:scale(-1);
    end,

    add = function(a, b)
        a.x = a.x + b.x;
        a.y = a.y + b.y;
        a.z = a.z + b.z;
        a.w = a.w + b.w;
    end,

    slerp = function(q, a, b, t)
        qtmp:copy(b);
        q:copy(a);

        local ct = a:dot(b);

        if (ct < 0) then
            ct = -ct;
            qtmp:invert();
        end

        if (ct > 0.999) then
            --todo lerp
        else
            local theta = math.acos(ct);

            local s1 = math.sin((1 - t) * theta);
            local s2 = math.sin(t * theta);
            local s3 = 1 / math.sin(theta);

            q:scale(s1);
            qtmp:scale(s2);
            q:add(qtmp);
            q:scale(s3);
        end
    end,

    components = function(q)
        return q.x, q.y, q.z, q.w;
    end,

    __tostring = function(a)
        return "{"..a.x..","..a.y..","..a.z..","..a.w"}";
    end

}

quat.new = function(x, y, z, w)
    x = x or 0;
    y = y or 0;
    z = z or 0;
    w = w or 1;

    local q = {x = x, y = y, z = z, w = w};
    setmetatable(q, quat);
    return q;
end

qtmp = quat.new();

-------------
--- mat4 ----
-------------

-- Column Major
--[[
    0 4 8 12
    1 5 9 13
    2 6 10 14
    3 7 11 15
]]

local mat4 = {};

local m4tmp = {};

local function btoi(b)
    if (b) then return 1 else return 0 end;
end

mat4.__index = {

    copy = function(a, b)
        for i = 0,15 do
            a[i] = b[i];
        end
    end,

    clone = function(m)
        local newm4 = mat4.new();
        newm4:copy(m);
        return newm4;
    end,

    setIdentity = function(m)
        for i = 0,15 do
            m[i] = btoi(i % 5 == 0);
        end
    end,

    -- v : vec3
    setTranslate = function(m, v)
        m:setIdentity();
        m[12] = v.x;
        m[13] = v.y;
        m[14] = v.z;
    end,

    -- v : vec3
    setScale = function(m, v)
        m:setIdentity();
        m[0] = v.x;
        m[5] = v.y;
        m[10] = v.z;
    end,

    -- q : quat
    setRotate = function(m, q)
        m:setIdentity();

        local x,y,z,w = q.x, q.y, q.z, q.w;

        m[0] = 1 - 2 * y * y - 2 * z * z;
        m[1] = 2 * x * y + 2 * z * w;
        m[2] = 2 * x * z - 2 * y * w;
        
        m[4] = 2 * x * y - 2 * z * w;
        m[5] = 1 - 2 * x * x - 2 * z * z; 
        m[6] = 2 * y * z + 2 * x * w;

        m[8] = 2 * x * z + 2 * y * w;
        m[9] = 2 * y * z - 2 * x * w;
        m[10] = 1 - 2 * x * x - 2 * y * y;
    end,

    -- b : mat4
    mul = function(m, b)

        local a11, a12, a13, a14 = m[0], m[4], m[8], m[12];
        local a21, a22, a23, a24 = m[1], m[5], m[9], m[13];
        local a31, a32, a33, a34 = m[2], m[6], m[10], m[14];
        local a41, a42, a43, a44 = m[3], m[7], m[11], m[15];

        local b11, b12, b13, b14 = b[0], b[4], b[8], b[12];
        local b21, b22, b23, b24 = b[1], b[5], b[9], b[13];
        local b31, b32, b33, b34 = b[2], b[6], b[10], b[14];
        local b41, b42, b43, b44 = b[3], b[7], b[11], b[15];

		m[ 0 ] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		m[ 4 ] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		m[ 8 ] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		m[ 12 ] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		m[ 1 ] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		m[ 5 ] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		m[ 9 ] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		m[ 13 ] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		m[ 2 ] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		m[ 6 ] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		m[ 10 ] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		m[ 14 ] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		m[ 3 ] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		m[ 7 ] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		m[ 11 ] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		m[ 15 ] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
    end,

    invert = function(m)
        local n11, n12, n13, n14 = m[0], m[4], m[8], m[12];
        local n21, n22, n23, n24 = m[1], m[5], m[9], m[13];
        local n31, n32, n33, n34 = m[2], m[6], m[10], m[14];
        local n41, n42, n43, n44 = m[3], m[7], m[11], m[15];

        local t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
        local t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
        local t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
        local t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

        local det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
        local detInv = 1 / det;

		m[ 0 ] = t11 * detInv;
		m[ 1 ] = ( n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44 ) * detInv;
		m[ 2 ] = ( n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44 ) * detInv;
		m[ 3 ] = ( n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43 ) * detInv;

		m[ 4 ] = t12 * detInv;
		m[ 5 ] = ( n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44 ) * detInv;
		m[ 6 ] = ( n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44 ) * detInv;
		m[ 7 ] = ( n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43 ) * detInv;

		m[ 8 ] = t13 * detInv;
		m[ 9 ] = ( n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44 ) * detInv;
		m[ 10 ] = ( n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44 ) * detInv;
		m[ 11 ] = ( n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43 ) * detInv;

		m[ 12 ] = t14 * detInv;
		m[ 13 ] = ( n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34 ) * detInv;
		m[ 14 ] = ( n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34 ) * detInv;
		m[ 15 ] = ( n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33 ) * detInv;

    end,

    setOrtho = function(m, left, right, bottom, top, near, far)
        local w = 1.0 / ( right - left );
		local h = 1.0 / ( top - bottom );
		local p = 1.0 / ( far - near );

		local x = ( right + left ) * w;
		local y = ( top + bottom ) * h;
		local z = ( far + near ) * p;

		m[ 0 ] = 2 * w;	m[ 4 ] = 0;	m[ 8 ] = 0;	m[ 12 ] = -x;
		m[ 1 ] = 0;	m[ 5 ] = 2 * h;	m[ 9 ] = 0;	m[ 13 ] = -y;
		m[ 2 ] = 0;	m[ 6 ] = 0;	m[ 10 ] = -2 * p;	m[ 14 ] = -z;
		m[ 3 ] = 0;	m[ 7 ] = 0;	m[ 11 ] = 0;	m[ 15 ] = 1;
    end,

    setPerspective = function(m, left, right, bottom, top, near, far)
        local x = 2 * near / ( right - left );
		local y = 2 * near / ( top - bottom );

		local a = ( right + left ) / ( right - left );
		local b = ( top + bottom ) / ( top - bottom );
		local c = - ( far + near ) / ( far - near );
		local d = - 2 * far * near / ( far - near );

		m[ 0 ] = x;	m[ 4 ] = 0;	m[ 8 ] = a;	m[ 12 ] = 0;
		m[ 1 ] = 0;	m[ 5 ] = y;	m[ 9 ] = b;	m[ 13 ] = 0;
		m[ 2 ] = 0;	m[ 6 ] = 0;	m[ 10 ] = c;	m[ 14 ] = d;
		m[ 3 ] = 0;	m[ 7 ] = 0;	m[ 11 ] = - 1;	m[ 15 ] = 0;
    end,

    setLookAt = function(m, eye, target, up)
        local zaxis = v3tmp[1];
        local xaxis = v3tmp[2];
        local yaxis = v3tmp[3];

        zaxis:setDirection(target, eye);
        xaxis:setPerpendicular(up, zaxis);
        yaxis:setPerpendicular(zaxis, xaxis);

        m[0], m[4], m[8] = xaxis.x, yaxis.x, zaxis.x;
        m[1], m[5], m[9] = xaxis.y, yaxis.y, zaxis.y;
        m[2], m[6], m[10] = xaxis.z, yaxis.z, zaxis.z;

        m[12] = eye.x;
        m[13] = eye.y;
        m[14] = eye.z;
    end,

    setView = function(m, eye, target, up)
        m:setLookAt(eye, target, up);
        m:invert();
    end,

    compose = function(m, position, rotation, scale)
        
        --[[
        m:setTranslate(position);
        m4tmp[1]:setRotate(rotation);
        m4tmp[2]:setScale(scale);

        m:mul(m4tmp[1]);
        m:mul(m4tmp[2]);
        ]]
        
        m:setRotate(rotation);

        m[0] = m[0] * scale.x;
        m[1] = m[1] * scale.x;
        m[2] = m[2] * scale.x;

        m[4] = m[4] * scale.y;
        m[5] = m[5] * scale.y;
        m[6] = m[6] * scale.y;

        m[8] = m[8] * scale.z;
        m[9] = m[9] * scale.z;
        m[10] = m[10] * scale.z;

        m[12] = position.x; 
        m[13] = position.y; 
        m[14] = position.z; 
    end,

    toRowMajorArray = function(m, a)
        a[1], a[2], a[3], a[4] = m[0], m[4], m[8], m[12];
        a[5], a[6], a[7], a[8] = m[1], m[5], m[9], m[13];
        a[9], a[10], a[11], a[12] = m[2], m[6], m[10], m[14];
        a[13], a[14], a[15], a[16] = m[3], m[7], m[11], m[15];
    end,

    toColMajorArray = function(m, a)
        for i = 1,16 do
            a[i] = m[i-1];
        end
    end,

    __tostring = function(m)
        local list = {"\n",m[0], m[4], m[8], m[12], 
            "\n",  m[1], m[5], m[9], m[13],
            "\n",  m[2], m[6], m[10], m[14],
            "\n",  m[3], m[7], m[11], m[15]};
        
        local string = "";
        for k, v in ipairs(list) do
            string = string.." "..v;
        end

        return string;
    end
}

mat4.new = function()
    local m = {};
    setmetatable(m, mat4);
    m:setIdentity();
    return m;
end

for i = 1,3 do
    m4tmp[i] = mat4.new();
end

return {
    vec3 = vec3.new,
    quat = quat.new,
    mat4 = mat4.new
}