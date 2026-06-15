FROM node:24.16.0-alpine
WORKDIR /app
RUN npm init -y && npm install redis@4
EXPOSE 5800
ENTRYPOINT ["node","server.js"]
