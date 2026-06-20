FROM node
WORKDIR /app
RUN npm init -y && npm install redis
EXPOSE 5800
ENTRYPOINT ["node","server.js"]
