# 服务器nginx配置

正常来讲，只需要调整.env的变量值即可

如果有ssl配置，别忘了将证书放在 `./nginx/volumes/cert` 目录下

1. 资源代理：在 `./volumes/templates/ssl.conf.template` 下
  一般情况下不需要增加 `location` 配置，直接将资源丢到服务器 `env.SERVICE_PROJECT_ROOT` 目录下就能访问

2. 接口代理： 在 `./volumes/templates/api.conf.template` 下
  如果有多和项目，可以按照模版增加一条 `location`

3. http： 在 `./volumes/templates/default.conf.template` 下
  默认是重定向到 `https` 下的

## 使用

适当修改.env中的配置，或者增加 `templates` 文件夹下的配置文件

将当前文件夹 `nginx` 整个复制到服务器上，路径随便，推荐放到到根目录下 `/my-docker-compose`

```shell
scp -r ./nginx root@123.123.123.123/my-docker-compose
```

进入服务器，启动 `docker compose`

```shell
cd /nginx
docker compose up -d
```

## .env字段介绍
1. SERVICE_PROJECT_ROOT

服务器上的项目根目录，前端项目直接丢到该目录下即可，例如 web1 => /projects/web1

docker-compose会将 `SERVICE_PROJECT_ROOT` 映射到 docker nginx 中的 `/projects` 下，而该nginx的配置都是以 `/projects` 为基础的

nginx配置会自动将 your-domain.com/web1 映射到 /projects/web1/index.html上

其次，为了适应前端路由，会将完整路由的第一个路由作为项目位置，例如 your-domain.com/web1/a/b/c 会映射到 /projects/web1/index.html上

在测试或本地环境下，可以将`SERVICE_PROJECT_ROOT`赋值为`./projects`

2. APP1_API_PORT

服务器中接口服务的端口，需要保证接口服务也是使用docker启动的

因为在 `./volumes/templates/*.conf.template` 中可以使用到 `http://host.docker.internal:${APP1_API_PORT}/`

这样在 `nginx` 启动时，会自动生成一个配置文件在 `./volumes/conf.d/*.conf`


3. CERT_PEM & CERT_KEY

这个是域名ssl证书的名字，存放在 `./volumes/cert/` 下的，将对应的文件名填上即可。

如果有其他的二级域名ssl配置，可以在 `./volumes/templates/*.conf.template` 文件中直接填写

4. DOMAIN

定义主域名，作用于 `default.conf` 和 `ssl.conf` 配置下。

如果需要给二级域名设置服务器块，直接在对应的templates中配置即可。例如 `./volumes/templates/api.conf.template` 中配置的是 `api.yinpo.com`
