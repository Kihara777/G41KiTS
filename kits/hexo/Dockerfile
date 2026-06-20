FROM node
RUN npm install -g hexo-cli
RUN mkdir -p /blog /hexo-init
WORKDIR /hexo-init
RUN hexo init . --no-install 2>/dev/null || true
RUN npm install
COPY <<'ENTRY' /entry.sh
#!/bin/sh
if [ ! -f /blog/_config.yml ]; then
  cp -a /hexo-init/. /blog/
fi
cd /blog && npm install && exec hexo server -p 4000 -i 0.0.0.0
ENTRY
RUN chmod +x /entry.sh
EXPOSE 4000
ENTRYPOINT ["/entry.sh"]
