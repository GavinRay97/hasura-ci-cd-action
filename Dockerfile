# Use alpine-glibc because Hasura CLI ext is not compatible with muslc. Needs glibc and libstdc++.
FROM hasura/graphql-engine:latest.cli-migrations

RUN curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash
RUN hasura plugins list
RUN hasura plugins install pro

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
