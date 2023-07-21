#!/bin/sh

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

debug() {
  printf "ℹ️ ${CYAN}%s${NC}\n", "$1"
}

warn() {
  printf "⚠️ ${YELLOW}%s${NC}\n", "$1"
}

error() {
  printf "❌ ${RED}%s${NC}\n", "$1"
}

# Download the Hasura CLI binary
(curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash) || {
  error 'Failed downloading Hasura CLI'
  exit 1
}

debug "Making Hasura CLI executable"
# Make it executable
chmod +x /usr/local/bin/hasura || {
  error 'Failed making CLI executable'
  exit 1
}

# If regression tests not enabled, end things here
if [ -z "$INPUT_HASURA_REGRESSION_TESTS_ENABLED" ]; then
  debug "Regression tests not enabled, finished."
  exit 0
fi

debug "Writing personal access token to config file"
# Write Personal Access Token to config file in home directory for Pro CLI plugin
mkdir -p ~/.hasura
echo "pat: $INPUT_HASURA_PERSONAL_ACCESS_TOKEN" >>~/.hasura/pro_config.yaml || {
  error "Failed writing Pro personal access token to ~/.hasura/pro_config.yaml"
  exit 1
}

debug "Installing Hasura CLI Pro plugin"
# Install the Pro CLI plugin
hasura plugins install pro || {
  error "Failed installing Pro CLI plugin"
  exit 1
}

debug "Running regression tests"
# Run regression tests
hasura pro regression-tests run \
  --endpoint "$INPUT_HASURA_ENDPOINT" \
  --admin-secret "$INPUT_HASURA_ADMIN_SECRET" \
  --project-id "$INPUT_HASURA_PROJECT_ID" \
  --testsuite-id "$INPUT_HASURA_REGRESSION_TESTSUITE_ID" || {
  error "Failed regression tests"
  exit 1
}
