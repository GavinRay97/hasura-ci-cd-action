# Use alpine-glibc because Hasura CLI ext is not compatible with muslc. Needs glibc and libstdc++.
FROM hasura/graphql-engine:latest.cli-migrations-v3

ENV HASURA_GRAPHQL_CLI_ENVIRONMENT=
RUN hasura-cli update-cli
RUN hasura-cli plugins list
RUN hasura-cli plugins install pro
RUN hasura-cli plugins list
RUN hasura-cli help

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
