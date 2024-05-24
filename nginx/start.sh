#!/bin/bash

docker compose down

echo "executing start.sh!"

ENV_FILE="./.env"
TEMPLATE_FILE_API="./templates/api.conf.template"
TEMPLATE_FILE_DEFAULT="./templates/default.conf.template"
TEMPLATE_FILE_SSL="./templates/ssl.conf.template"

TAREGET_TEMPLATE_FILE_API="./volumes/templates/api.conf.template"
TAREGET_TEMPLATE_FILE_DEFAULT="./volumes/templates/default.conf.template"
TAREGET_TEMPLATE_FILE_SSL="./volumes/templates/ssl.conf.template"

# 读取.env文件的变量
source "$ENV_FILE"

read -r ssl_only <<<"$SSL_ONLY"
# 将列表变量转换为数组
IFS=',' read -r -a ports <<<"$API_PORT_LIST"
IFS=',' read -r -a locations <<<"$API_LOCATION_LIST"

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --ssl-only)
    ssl_only="$2"
    shift
    ;;
  --api-port-list)
    IFS=',' read -r -a ports <<<"$2"
    shift
    ;;
  --api-location-list)
    IFS=',' read -r -a locations <<<"$2"
    shift
    ;;
  *)
    echo "Unknown parameter passed: $1"
    exit 1
    ;;
  esac
  shift
done

# =========================== default 配置 ===========================
# 定位控制区域行号
start_line=$(grep -n "# SHELL_CONTROL_SSL_ONLY_START" "$TEMPLATE_FILE_DEFAULT" | cut -d : -f 1)
end_line=$(grep -n "# SHELL_CONTROL_SSL_ONLY_END" "$TEMPLATE_FILE_DEFAULT" | cut -d : -f 1)

# 提取模板的两部分内容
header_part=$(sed "${start_line}q" "$TEMPLATE_FILE_DEFAULT")
footer_part=$(sed "1,$((end_line - 1))d" "$TEMPLATE_FILE_DEFAULT")
output=$header_part$'\n'

if [ "$ssl_only" = "true" ]; then
  location_block="    rewrite ^(.*) https://\$server_name\$1 permanent;"
elif [ "$ssl_only" = "false" ]; then
  location_block="    location ~ ^/([^/]*)/((?!index\.html$).)*$ {
      try_files $uri $uri/ $uri/index.html /$1/index.html /404.html;
    }

    location / {
      try_files $uri $uri/ $uri/index.html =404;
    }"
else
  echo "env ssl_only is not set correctly. Please set it to either 'true' or 'false'."
  exit 1
fi
output+="$location_block"$'\n'
output+="$footer_part"

echo "$output" >"$TAREGET_TEMPLATE_FILE_DEFAULT"
echo "$TAREGET_TEMPLATE_FILE_DEFAULT has been updated."

# =========================== ssl 配置 ===========================
if [ "$ssl_only" = "true" ]; then
  cat "$TEMPLATE_FILE_SSL" >"$TAREGET_TEMPLATE_FILE_SSL"
elif [ "$ssl_only" = "false" ]; then
  echo "# SSL_ONLY is false" >"$TAREGET_TEMPLATE_FILE_SSL"
else
  echo "env ssl_only is not set correctly. Please set it to either 'true' or 'false'."
  exit 1
fi
echo "$TAREGET_TEMPLATE_FILE_SSL has been updated."

# =========================== api 配置 ===========================

# 定位控制区域行号
start_line=$(grep -n "# SHELL_CONTROL_LOCATION_START" "$TEMPLATE_FILE_API" | cut -d : -f 1)
end_line=$(grep -n "# SHELL_CONTROL_LOCATION_END" "$TEMPLATE_FILE_API" | cut -d : -f 1)

# 提取模板的两部分内容
header_part=$(sed "${start_line}q" "$TEMPLATE_FILE_API")
footer_part=$(sed "1,$((end_line - 1))d" "$TEMPLATE_FILE_API")
output=$header_part$'\n'

# 循环创建新的 location 配置
for i in "${!ports[@]}"; do
  port=${ports[$i]}
  location=${locations[$i]}
  location_block="    location $location {
      add_header 'Access-Control-Allow-Origin' \${DOMAIN_API} always;
      add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, PATCH, HEAD, OPTIONS, DELETE' always;
      add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type' always;
      add_header 'Access-Control-Allow-Credentials' 'true' always;

      if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain charset=UTF-8';
        add_header 'Content-Length' 0;
        return 204;
      }

      proxy_pass http://host.docker.internal:$port/;
      break;
    }"
  output+="$location_block"$'\n'
done

output+="$footer_part"

start_line=$(echo -e "$output" | grep -n "# SHELL_CONTROL_SSL_START" | cut -d : -f 1)
end_line=$(echo -e "$output" | grep -n "# SHELL_CONTROL_SSL_END" | cut -d : -f 1)
header_part=$(echo -e "$output" | sed "${start_line}q")
footer_part=$(echo -e "$output" | sed "1,$((end_line - 1))d")
output=$header_part$'\n'

if [ "$ssl_only" = "true" ]; then
  location_block="    listen 443 ssl http2;
    server_name \${DOMAIN_API};

    # 数字证书
    ssl_certificate cert/\${CERT_PEM_API};
    # 服务器私钥
    ssl_certificate_key cert/\${CERT_KEY_API};
    # 停止通信时，加密会话的有效期，在该时间段内不需要重新交换密钥
    ssl_session_timeout 5m;
    # TLS握手时，服务器采用的密码套件
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    #表示使用的加密套件的类型。
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3; #表示使用的TLS协议的类型，您需要自行评估是否配置TLSv1.1协议。
    # 开启由服务器决定采用的密码套件
    ssl_prefer_server_ciphers on;
  "
elif [ "$ssl_only" = "false" ]; then
  location_block="
    listen       80;
    server_name  \${DOMAIN_MAIN};"
else
  echo "env ssl_only is not set correctly. Please set it to either 'true' or 'false'."
  exit 1
fi
output+="$location_block"$'\n'
output+="$footer_part"

echo "$output" >"$TAREGET_TEMPLATE_FILE_API"

echo "$TAREGET_TEMPLATE_FILE_API has been updated."

# 执行dokcer compose指令
docker compose up -d
