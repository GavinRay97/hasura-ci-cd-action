#!/bin/bash

# If a CLI version was given to Github Action inputs, then use that, otherwise default to latest release
if [[ -z "$INPUT_HASURA_CLI_VERSION" ]]; then
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/latest/download/cli-hasura-linux-amd64"
else
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/download/$INPUT_HASURA_CLI_VERSION/cli-hasura-linux-amd64"
fi

# Download the Hasura CLI binary
wget --quiet --output-document /usr/local/bin/hasura "$hasura_cli_download_url" || {
  echo 'Failed downloading Hasura CLI'
  exit 1
}

# Make it executable
chmod +x /usr/local/bin/hasura || {
  echo 'Failed making CLI executable'
  exit 1
}

# CD into Hasura project root directory, if given and not current directory
if [[ -n "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" ]]; then
  cd "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" || {
    echo "Failed to cd into directory $INPUT_PATH_TO_HASURA_PROJECT_ROOT"
    exit 1
  }
fi

# If migrations are enabled
if [[ -n "$INPUT_HASURA_MIGRATIONS_ENABLED" ]]; then
  # If admin secret given in inputs, append it to migrate apply, else don't (use default from config.yaml)
  if [[ -n "$INPUT_HASURA_ENDPOINT" ]]; then
    hasura migrate apply --endpoint "$INPUT_HASURA_ENDPOINT" --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      echo "Failed applying migrations"
      exit 1
    }
  else
    hasura migrate apply --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      echo "Failed applying migrations"
      exit 1
    }
  fi
else
  echo "Migrations not enabled, skipping"
fi

# If regression tests not enabled, end things here
if [[ -z "$INPUT_HASURA_REGRESSION_TESTS_ENABLED" ]]; then
  echo "Regression tests not enabled, finished."
  exit 0
fi

# Write Personal Access Token to config file in home directory for Pro CLI plugin
echo "pat: $INPUT_HASURA_PERSONAL_ACCESS_TOKEN" >>~/.hasura/pro_config.yaml || {
  echo "Failed writing Pro personal access token to ~/.hasura/config.yaml"
  exit 1
}

# Install the Pro CLI plugin
hasura plugins install pro || {
  echo "Failed installing Pro CLI plugin"
  exit 1
}

# Run regression tests
hasura pro regression-tests run \
  --endpoint "$INPUT_HASURA_ENDPOINT" \
  --admin-secret "$INPUT_HASURA_ADMIN_SECRET" \
  --project-id "$INPUT_HASURA_PROJECT_ID" \
  --testsuite-id "$INPUT_HASURA_REGRESSION_TESTSUITE_ID" || {
  echo "Failed regression tests"
  exit 1
}
