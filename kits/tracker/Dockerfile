FROM node:24.16.0-alpine
RUN npm install -g bittorrent-tracker@11.2.2
ENTRYPOINT ["bittorrent-tracker"]
CMD ["--trust-proxy", "--http", "--udp", "--ws"]