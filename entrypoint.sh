#!/bin/sh

# If a CLI version was given to Github Action inputs, then use that, otherwise default to latest release
if [ -z "$INPUT_HASURA_CLI_VERSION" ]; then
  echo "Hasura CLI version not provided, downloading latest release"
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/latest/download/cli-hasura-linux-amd64"
else
  echo "Downloading Hasura CLI $INPUT_HASURA_CLI_VERSION"
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/download/$INPUT_HASURA_CLI_VERSION/cli-hasura-linux-amd64"
fi

# Download the Hasura CLI binary
wget --quiet --output-document /usr/local/bin/hasura "$hasura_cli_download_url" || {
  echo 'Failed downloading Hasura CLI'
  exit 1
}

echo "Making Hasura CLI executable"
# Make it executable
chmod +x /usr/local/bin/hasura || {
  echo 'Failed making CLI executable'
  exit 1
}

echo "No path to Hasura project root given, using top-level repo directory"
# CD into Hasura project root directory, if given and not current directory
if [ -n "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" ]; then
  echo "cd'ing to Hasura project root at $INPUT_PATH_TO_HASURA_PROJECT_ROOT"
  cd "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" || {
    echo "Failed to cd into directory $INPUT_PATH_TO_HASURA_PROJECT_ROOT"
    exit 1
  }
fi

# If migrations are enabled
if [ -n "$INPUT_HASURA_MIGRATIONS_ENABLED" ]; then
  echo "Running migrations"
  # If admin secret given in inputs, append it to migrate apply, else don't (use default from config.yaml)
  if [ -n "$INPUT_HASURA_ENDPOINT" ]; then
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
if [ -z "$INPUT_HASURA_REGRESSION_TESTS_ENABLED" ]; then
  echo "Regression tests not enabled, finished."
  exit 0
fi

echo "Writing personal access token to config file"
# Write Personal Access Token to config file in home directory for Pro CLI plugin
echo "pat: $INPUT_HASURA_PERSONAL_ACCESS_TOKEN" >>~/.hasura/pro_config.yaml || {
  echo "Failed writing Pro personal access token to ~/.hasura/config.yaml"
  exit 1
}

echo "Installing Hasura CLI Pro plugin"
# Install the Pro CLI plugin
hasura plugins install pro || {
  echo "Failed installing Pro CLI plugin"
  exit 1
}

echo "Running regression tests"
# Run regression tests
hasura pro regression-tests run \
  --endpoint "$INPUT_HASURA_ENDPOINT" \
  --admin-secret "$INPUT_HASURA_ADMIN_SECRET" \
  --project-id "$INPUT_HASURA_PROJECT_ID" \
  --testsuite-id "$INPUT_HASURA_REGRESSION_TESTSUITE_ID" || {
  echo "Failed regression tests"
  exit 1
}
