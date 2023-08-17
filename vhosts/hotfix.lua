local whiteid = {'1000','1001','1002','1003'}
local whiteip = {'192.168.','192.167.','1.1.1.1','2.2.2.2'}

function iswhiteid(whiteid, val)
    for _, v in ipairs(whiteid) do
        if v == val then
            return 1
        end
    end
    return 0
end

function iswhiteip(whiteip, val)
    for _, v in ipairs(whiteip) do
        if string.find(val, v) ~= nil then
            return 1
        end
    end
    return 0
end

local headers_tab = ngx.req.get_headers()
local ip=headers_tab["X-REAL-IP"] or headers_tab["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
if headers_tab["acountid"] ~= nil then
    id = headers_tab["acountid"]
    if iswhiteid(whiteid,id) == 1 then
        ngx.exec("@hotfix-white");
    else
        if iswhiteip(whiteip,ip) == 1 then
            ngx.exec("@hotfix-white")
            --ngx.say(ip)
        else
            ngx.exec("@hotfix-common")
            --ngx.say(ip)
        end
    end
else
    if iswhiteip(whiteip,ip) == 1 then
        ngx.exec("@hotfix-white")
    --ngx.say("head is null")
    --ngx.exec("@hotfix-common");
    --ngx.say("xip: ",headers_tab["X-REAL-IP"])
    --ngx.say("fip: ",headers_tab["X_FORWARDED_FOR"])
    --ngx.say("rip: ",ngx.var.remote_addr)
    --ngx.say(ip)
    else
        ngx.exec("@hotfix-common")
    end
end