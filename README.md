# Hasura CI/CD Github Action

This action allows automatically running migrations and regression tests against a Hasura instance on changes.

The functionality lives inside of `entrypoint.sh` as a single bash script and is well-commented for those curious.

Currently only works with a single database tagged as `default` in your metadata

## Inputs

```yaml
inputs:
  PATH_TO_HASURA_PROJECT_ROOT:
    required: false
    description: The relative path from the root of your repo to where the Hasura project (containing config.yaml and your migrations/metadata folders) is located. For example, if your top-level directory contains a "hasura" folder, then this value should be ./hasura
  HASURA_CLI_VERSION:
    required: false
    description: Version of Hasura CLI to download and use. Defaults to 'latest' if not set.
  HASURA_ENDPOINT:
    required: false
    description: Optional overriding URL for the Hasura endpoint to call migrate apply and/or regression tests on. Will default to config.yaml value (as the CLI is run from the directory containing config.yaml).
  HASURA_ADMIN_SECRET:
    required: false
    description: Optional overriding admin secret for the Hasura instance. Will default to config.yaml value (as the CLI is run from the directory containing config.yaml).
  HASURA_MIGRATIONS_ENABLED:
    required: false
    description: Whether or not migrations should be run during CI/CD.
  HASURA_REGRESSION_TESTS_ENABLED:
    required: false
    description: Whether or not the CI/CD should attempt to run regression tests. Only available for Hasura Cloud and Hasura Enterprise users.
  HASURA_REGRESSION_TESTSUITE_ID:
    required: false
    description: The ID for the regression testsuite to run, if enabled.
  HASURA_PERSONAL_ACCESS_TOKEN:
    required: false
    description: A Personal Access Token
  HASURA_PROJECT_ID:
    required: false
    description: ID for the Hasura Cloud or Hasura Enterprise project to run regression tests on, if enabled
```

## Example usage

```yaml
name: Hasura CI/CD

on:
  push:
    branches:
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Hasura CI/CD
        uses: GavinRay97/hasura-ci-cd-action@v1.3
        with:
          PATH_TO_HASURA_PROJECT_ROOT: ./hasura
          HASURA_CLI_VERSION: v2.0.0-alpha.2
          HASURA_ENDPOINT: https://my-url.hasura.app
          HASURA_ADMIN_SECRET: ${{ secrets.HASURA_ADMIN_SECRET }}
          # If you want to disable either migrations or regression tests, make sure to remove them completely
          # The script only checks for their presence, not their value
          HASURA_MIGRATIONS_ENABLED: true
          HASURA_SEEDS_ENABLED: true
          HASURA_REGRESSION_TESTS_ENABLED: true
          HASURA_REGRESSION_TESTSUITE_ID: xxxxxx-xxx-xxxx-xxxxx-xxxxxx
          HASURA_PERSONAL_ACCESS_TOKEN: ${{ secrets.HASURA_PERSONAL_ACCESS_TOKEN }}
          HASURA_PROJECT_ID: xxxxxx-xxxx-xxx-xxxx-xxxxxxx
```
