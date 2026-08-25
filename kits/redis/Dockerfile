# redis API + bittorrent-tracker 合一运行时（alpine 精简）
# compose 模式入口：node server.js（行为不变）
# k8s 模式入口：node /app/entry.js（tracker + API 同进程，省一个 node 运行时）
FROM node:24-alpine
WORKDIR /app
RUN npm install redis bittorrent-tracker
COPY kits/redis/entry.js /app/entry.js
EXPOSE 5800 8000
ENTRYPOINT ["node"]
CMD ["server.js"]
