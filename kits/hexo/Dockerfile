# hexo 镜像（alpine 精简）：compose 模式 hexo server；k8s 模式仅作静态构建 Job 的镜像
FROM node:24-alpine
RUN npm install -g hexo-cli
RUN mkdir -p /blog /hexo-init
WORKDIR /hexo-init
RUN hexo init . --no-install 2>/dev/null || true
RUN npm install --no-audit --no-fund
COPY kits/hexo/entry.sh /entry.sh
RUN chmod +x /entry.sh
EXPOSE 4000
ENTRYPOINT ["/entry.sh"]
