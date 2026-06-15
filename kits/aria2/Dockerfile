FROM alpine:3.23.4
RUN apk add --no-cache aria2
WORKDIR /aria2
ADD --checksum=sha256:f0658c944165265b6f5c10a05b4193d609a4c04d569c743f86928ba8b139d822 \
    https://github.com/mayswind/AriaNg/releases/download/1.3.13/AriaNg-1.3.13-AllInOne.zip /tmp/ariang.zip
RUN mkdir -p /webroot && unzip -q /tmp/ariang.zip -d /tmp/ariang && \
    sed -i "s/defaultSecureProtocol:\"https\"/defaultSecureProtocol:\"wss\"/g" /tmp/ariang/index.html && \
    sed -i "s/theme:\"light\"/theme:\"dark\"/g" /tmp/ariang/index.html && \
    sed -i "s/rpcPort:\"6800\"/rpcPort:\"443\"/g" /tmp/ariang/index.html && \
    sed -i "s/rpcInterface:\"jsonrpc\"/rpcInterface:\"aria2rpc\"/g" /tmp/ariang/index.html && \
    sed -i "s/protocol:\"http\"/protocol:\"ws\"/g" /tmp/ariang/index.html && \
    install -m 444 /tmp/ariang/index.html /webroot/aria2.html && \
    rm -rf /tmp/ariang.zip /tmp/ariang
ENTRYPOINT ["aria2c"]
CMD ["--conf-path=/aria2/rpc.daemon"]