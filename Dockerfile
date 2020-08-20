FROM alpine:3.12

COPY entrypoint.sh /entrypoint.sh
RUN apk update && apk add --no-cache wget

ENTRYPOINT ["/entrypoint.sh"]