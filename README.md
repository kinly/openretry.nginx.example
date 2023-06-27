# nginx 相关备忘
## 安装 openresty nginx
``` bash
yum install pcre-devel openssl-devel gcc curl
wget https://openresty.org/download/openresty-1.21.4.1.tar.gz
tar -xvf openresty-1.21.4.1.tar.gz
cd openresty-1.21.4.1
./configure --prefix=/data/soft/openresty --with-luajit --with-http_iconv_module -j21
gmake -j 4
gmake install
```

## 配置service
``` bash
vim /usr/lib/systemd/system/openresty.service
```
``` service
[Unit]
Description=The OpenResty Application Platform
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/data/soft/openresty/nginx.pid
ExecStartPre=/data/soft/openresty/nginx/sbin/nginx -t
ExecStart=/data/soft/openresty/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

- 之后的操作命令：
``` bash
systemctl start|stop|restart|reload openresty
```
- 报错
  `systemd[1]: PID file /data/soft/openresty/nginx.pid not readable (yet?) after start. `
  可能是 service 配置的 PIDFile 和 nginx.conf 的不一样，或者是 nginx.conf 用的用户没有示例 /data/soft/openresty 的读写权限

## 配置
### nginx.conf
- 需要注意 user 配置，需要确认这个用户的权限
- 需要注意 pid 配置，需要和 service 配置一致
``` conf
user  root;
worker_processes auto;
worker_rlimit_nofile 102400;
error_log  logs/error.log ;
pid   /data/soft/openresty/nginx.pid;
```
### 示例：pay 路由
- pay.route.conf
`示例展示用 pay.route.lua 里的规则重置 ngx.proxy，然后代理到对应处理里面`
`需要用 rewrite_by_lua/rewrite_by_lua_file 重写 ngx.proxy `
`需要注意这里的相对路径是从 /data/soft/openresty/nginx 开始的`
``` conf
server {
    listen 8080;
    location / {
        limit_except POST { deny all; }

        set $proxy "";
        rewrite_by_lua_file conf/vhosts/pay.route.lua;
        proxy_pass http://$proxy$uri;
    }
}
server {
    listen 3000;
    location = /pay {
        client_max_body_size 50k;
        client_body_buffer_size 50k;

        content_by_lua_block {
            ngx.say("3000....")
            ngx.exit(200)
        }
    }
}
server {
    listen 3001;
    location = /pay {
        client_max_body_size 50k;
        client_body_buffer_size 50k;

        content_by_lua_block {
            ngx.say("3001....")
            ngx.exit(200)
        }
    }
}
server {
    listen 3002;
    location = / {
        client_max_body_size 50k;
        client_body_buffer_size 50k;

        content_by_lua_block {
            ngx.say("error")
            ngx.exit(400)
        }
    }
}

```
- pay.route.lua
``` lua-------------------------------------------------
-- pay route

local default_proxy = "127.0.0.1:3002"

local route_proxy_config = {
    ["1012"] = "127.0.0.1:3000",
    ["1016"] = "127.0.0.1:3001",
    ["1018"] = "127.0.0.1:3002",
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

```
