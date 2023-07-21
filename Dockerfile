# Use alpine-glibc because Hasura CLI ext is not compatible with muslc. Needs glibc and libstdc++.
FROM hasura/graphql-engine:latest.cli-migrations

RUN hasura-cli plugins install pro

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
