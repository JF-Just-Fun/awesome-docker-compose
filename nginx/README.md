# 服务器 nginx 配置

## 目的

简化重新部署 nginx 的操作

只需要调整.env 的变量值,输入一条指令即可完美运行

如果有 ssl 配置，别忘了将证书放在 `./nginx/volumes/cert` 目录下，然后配置.env 变量

1. 静态资源代理：在 `./volumes/templates/ssl.conf.template` 下
   一般情况下不需要增加 `location` 配置，直接将资源丢到服务器 `env.SERVICE_PROJECT_ROOT` 目录下就能访问

2. 接口服务代理： 在 `./volumes/templates/api.conf.template` 下
   如果有多个项目，可以按照模版增加一条 `location` 或 这自定义一个 `*.conf.template` 文件

3. http： 在 `./volumes/templates/default.conf.template` 下

## 使用

### 下载当前仓库模版

将当前项目整个复制到服务器上，路径随便，推荐放到到根目录下 `/my-docker-compose`

```bash
git clone https://github.com/JF-Just-Fun/awesome-docker-compose.git /my-docker-compose
```

### 进入 nginx 文件夹

```bash
cd /my-docker-compose/nginx
```

> 或者 clone 到本地之后，使用 scp 直接传到远程服务器上

```shell
scp -r ./nginx root@123.123.123.123/my-docker-compose/nginx
```

### 执行 start.sh 脚本

适当修改.env 中的配置，执行指令，会自定启动 `docker compose`

```bash
./start.sh

# 或者传入参数, 与.env中的 shell env 配置对应, 优先级更高
./start.sh --ssl-only false --api-port-list 3000 --api-location-list /new-api
```

## .env 字段介绍

### 项目环境变量

1. SERVICE_PROJECT_ROOT

服务器上的项目根目录，前端项目直接丢到该目录下即可，例如 web1 => /projects/web1

docker-compose 会将 `SERVICE_PROJECT_ROOT` 映射到 docker nginx 中的 `/projects` 下，而该 nginx 的配置都是以 `/projects` 为基础的

nginx 配置会自动将 your-domain.com/web1 映射到 /projects/web1/index.html 上

其次，为了适应前端路由，会将完整路由的第一个路由作为项目位置，例如 your-domain.com/web1/a/b/c 会映射到 /projects/web1/index.html 上

在测试或本地环境下，可以将`SERVICE_PROJECT_ROOT`赋值为`./projects`

2. `CERT_PEM_MAIN` & `CERT_KEY_MAIN` & `CERT_PEM_API` & `CERT_KEY_API`

这个是主域名与 api 域名 ssl 证书的名字，存放在 `./volumes/cert/` 下的，将对应的文件名填上即可。

> 如果有其他的二级域名 ssl 配置，直接在对应的 templates 中配置即可。
> 例如 `./volumes/templates/*.conf.template` 文件中直接填写

3. `DOMAIN_MAIN` & `DOMAIN_API`

定义主域名，分别作用于 `default.conf`、`ssl.conf` 和 `api.conf` 配置。

> 如果需要给二级域名设置服务器块，直接在对应的 templates 中配置即可。
> 例如 `./volumes/templates/second.conf.template` 中配置的是 `second.yinpo.com`

### 脚本环境变量

脚本环境变量支持直接输入指令选项,例如：--ssl-only --api-port-list --api-location-list 等
选项名字与.env 文件中的相对应。

1. SSL_ONLY
   是否强制跳转 https 域名，值为：`false` or `true`

2. API_PORT_LIST
   配置 api 服务的端口列表，支持多个 api 服务，使用`,`进行分割
   例如： "5753,5754"

3. API_LOCATION_LIST
   配置 api 服务的路径列表，支持多个 api 服务，使用英文逗号`,`进行分割
   例如： "/api,/api2"
