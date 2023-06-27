-------------------------------------------------
-- pay route

local default_proxy = "127.0.0.1:3002"

local route_proxy_config = {
    ["1012"] = "127.0.0.1:3000",
    ["1016"] = "127.0.0.1:3001",
    ["1018"] = "127.0.0.1:3002",

    -- ["1012"] = "192.168.28.246:13345",
    -- ["1016"] = "192.168.29.0:13345",
    -- ["1018"] = "192.168.29.6:13345",
};

local area_args_key = "ext"
local area_index = 2

-- route_proxy
local route_proxy = default_proxy

ngx.req.read_body()

local args, err = ngx.req.get_post_args()
if args[area_args_key] then
    local index = 1
    for area in string.gmatch(args[area_args_key], "[^|]+") do
        if index == area_index then
            if route_proxy_config[area] ~= nil then
                route_proxy = route_proxy_config[area]
                break
            end
        end
        index = index + 1
    end
end

ngx.var.proxy = route_proxy
