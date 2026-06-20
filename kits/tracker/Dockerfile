FROM node
RUN npm install -g bittorrent-tracker
ENTRYPOINT ["bittorrent-tracker"]
CMD ["--trust-proxy", "--http", "--udp", "--ws"]