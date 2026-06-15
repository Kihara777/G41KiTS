FROM alpine:3.23.4
RUN apk add --no-cache transmission-daemon
WORKDIR /bt
RUN mv /usr/share/transmission/public_html /bt/web
RUN mv /bt/web/index.html /bt/web/index.original.html
ADD --checksum=sha256:e6f43fb69cad6424cdad5e1ac9230ca5d7f88a85b94c8364d51de965166560c7 \
    https://github.com/ronggang/transmission-web-control/archive/refs/tags/v1.6.1-update1.tar.gz /tmp/twc.tar.gz
RUN tar -xzf /tmp/twc.tar.gz -C /tmp/ && \
    cp -r /tmp/transmission-web-control-1.6.1-update1/src/* /bt/web/ && \
    rm -rf /tmp/twc.tar.gz /tmp/transmission-web-control-1.6.1-update1
RUN ln -sf /bt/web /usr/share/transmission/web
RUN ln -sf /bt/web /usr/share/transmission/public_html
ENTRYPOINT ["transmission-daemon"]
CMD ["-f", "-g", "/bt"]