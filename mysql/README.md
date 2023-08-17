# mysql 数据库

一般来说，修改 `.env` 中的配置即可

## 使用

使用 scp 工具传输文件到服务器 推荐放到 `/my-docker-compose` 下

```shell
scp -r ../mysql root@123.123.123.123:/my-docker-compose
```

进入服务器，启动docker服务

```shell
cd /my-docker-compose/mysql

docker compose up -d
```

## 说明
在 `.env` 中定义了 `COMPOSE_PROJECT_NAME=database`，所以在docker compose启动时，会创建名为 `database_mysql` 的网络

在其他的docker项目中，如果需要连接该mysql，可以使用该网络，然后直接传该mysql的host，例如

```yaml
services:
  app:
    container_name: server
    restart: always
    ports:
      - ${APP_PORT}:${APP_PORT}
    environment:
      MYSQL_HOST: db_mysql
      MYSQL_PORT: 3306
    networks:
      - database-mysql

networks:
  database-mysql:
    external: true
    name: database_mysql

```

这里的db_mysql就是当前docker的服务名，在指定网络的情况下可以直接使用服务名
