#!/bin/sh
# compose 模式：hexo server 常驻（行为不变）；k8s 模式使用 build-job.yaml 静态构建
if [ ! -f /blog/_config.yml ]; then
  cp -a /hexo-init/. /blog/
fi
cd /blog && npm install && exec hexo server -p 4000 -i 0.0.0.0
