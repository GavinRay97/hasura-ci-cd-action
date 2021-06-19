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

# If a CLI version was given to Github Action inputs, then use that, otherwise default to latest release
if [ -z "$INPUT_HASURA_CLI_VERSION" ]; then
  warn "Hasura CLI version not provided, downloading latest release"
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/latest/download/cli-hasura-linux-amd64"
else
  debug "Downloading Hasura CLI $INPUT_HASURA_CLI_VERSION"
  hasura_cli_download_url="https://github.com/hasura/graphql-engine/releases/download/$INPUT_HASURA_CLI_VERSION/cli-hasura-linux-amd64"
fi

# Download the Hasura CLI binary
wget --quiet --output-document /usr/local/bin/hasura "$hasura_cli_download_url" || {
  error 'Failed downloading Hasura CLI'
  exit 1
}

debug "Making Hasura CLI executable"
# Make it executable
chmod +x /usr/local/bin/hasura || {
  error 'Failed making CLI executable'
  exit 1
}

# CD into Hasura project root directory, if given and not current directory
if [ -n "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" ]; then
  debug "cd'ing to Hasura project root at $INPUT_PATH_TO_HASURA_PROJECT_ROOT"
  cd "$INPUT_PATH_TO_HASURA_PROJECT_ROOT" || {
    error "Failed to cd into directory $INPUT_PATH_TO_HASURA_PROJECT_ROOT"
    exit 1
  }
else
  warn "No path to Hasura project root given, using top-level repo directory"
fi

# Oh man this is so ugly, but I'm not sure if adding --endpoint with no value would nullify and break it.
# If migrations are enabled
if [ -n "$INPUT_HASURA_MIGRATIONS_ENABLED" ]; then
  debug "Preparing to apply migrations and metadata"
  # If admin secret given in inputs, append it to migrate apply, else don't (use default from config.yaml)
  if [ -n "$INPUT_HASURA_ENDPOINT" ]; then
    debug "Applying migrations"
    hasura migrate apply --endpoint "$INPUT_HASURA_ENDPOINT" --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed applying migrations"
      exit 1
    }
    debug "Applying metadata"
    hasura metadata apply --endpoint "$INPUT_HASURA_ENDPOINT" --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed applying metadata"
      exit 1
    }
    debug "Reload metadata"
    hasura metadata reload --endpoint "$INPUT_HASURA_ENDPOINT" --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed reload metadata"
      exit 1
    }

  else
    debug "Applying migrations"
    hasura migrate apply --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed applying migrations"
      exit 1
    }
    debug "Applying metadata"
    hasura metadata apply --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed applying metadata"
      exit 1
    }
    debug "Reload metadata"
    hasura metadata reload --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed reload metadata"
      exit 1
    }
    
  fi
else
  warn "Migrations not enabled, skipping"
fi

if [ -n "$INPUT_HASURA_SEEDS_ENABLED" ]; then
  debug "Preparing to apply seeds"
  # If admin secret given in inputs, append it to migrate apply, else don't (use default from config.yaml)
  if [ -n "$INPUT_HASURA_ENDPOINT" ]; then
    debug "Applying seeds:"
    hasura seeds apply --endpoint "$INPUT_HASURA_ENDPOINT" --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed getting migration status"
      exit 1
    }
  else
    debug "Applying seeds:"
    hasura seeds apply --admin-secret "$INPUT_HASURA_ADMIN_SECRET" || {
      error "Failed getting migration status"
      exit 1
    }
  fi
else
  warn "Seeds not enabled, skipping"
fi

# If regression tests not enabled, end things here
if [ -z "$INPUT_HASURA_REGRESSION_TESTS_ENABLED" ]; then
  debug "Regression tests not enabled, finished."
  exit 0
fi

debug "Writing personal access token to config file"
# Write Personal Access Token to config file in home directory for Pro CLI plugin
echo "pat: $INPUT_HASURA_PERSONAL_ACCESS_TOKEN" >>~/.hasura/pro_config.yaml || {
  error "Failed writing Pro personal access token to ~/.hasura/config.yaml"
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
