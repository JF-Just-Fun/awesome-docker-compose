# redis 数据库

一般来说，修改 `.env` 中的配置即可

## 使用

使用 scp 工具传输文件到服务器 推荐放到 `/my-docker-compose` 下

```shell
scp -r ./redis root@123.123.123.123:/my-docker-compose
```

进入服务器，启动 `docker compose`

```shell
cd /my-docker-compose/redis

docker compose up -d
```
