FROM alpine
RUN apk add --no-cache curl jq
COPY docker-entrypoint /
ENTRYPOINT ["/docker-entrypoint"]
CMD ["autoheal"]
HEALTHCHECK --interval=30s CMD pgrep -f autoheal || exit 1