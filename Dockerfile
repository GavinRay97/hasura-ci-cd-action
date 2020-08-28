# Use alpine-glibc because Hasura CLI ext is not compatible with muslc. Needs glibc and libstdc++.
FROM frolvlad/alpine-glibc:alpine-3.12

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apk update && apk add --no-cache wget libstdc++

ENTRYPOINT ["/entrypoint.sh"]