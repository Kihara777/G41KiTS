FROM alpine
RUN apk add --no-cache transmission-daemon
WORKDIR /bt
RUN mv /usr/share/transmission/public_html /bt/web
RUN mv /bt/web/index.html /bt/web/index.original.html
ADD https://github.com/ronggang/transmission-web-control/archive/refs/tags/v1.6.1-update1.tar.gz /tmp/twc.tar.gz
RUN tar -xzf /tmp/twc.tar.gz -C /tmp/ && \
    cp -r /tmp/transmission-web-control-1.6.1-update1/src/* /bt/web/ && \
    rm -rf /tmp/twc.tar.gz /tmp/transmission-web-control-1.6.1-update1
RUN ln -sf /bt/web /usr/share/transmission/web
RUN ln -sf /bt/web /usr/share/transmission/public_html
ENTRYPOINT ["transmission-daemon"]
CMD ["-f", "-g", "/bt"]