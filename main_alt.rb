#!/usr/bin/env ruby

hasura_cli_version = ENV['INPUT_HASURA_CLI_VERSION']
hasura_cli_download_url = if hasura_cli_version
  "https://github.com/hasura/graphql-engine/releases/download/#{hasura_cli_version}/cli-hasura-linux-amd64"
else
  "https://github.com/hasura/graphql-engine/releases/latest/download/cli-hasura-linux-amd64"
end

# Download and configure Hasura CLI
successfully_downloaded_cli = system "wget --quiet --output-document /usr/local/bin/hasura #{hasura_cli_download_url}"
abort 'Failed downloading Hasura CLI' unless successfully_downloaded_cli

successfully_made_executable = system 'chmod +x /usr/local/bin/hasura'
abort 'Failed making CLI executable' unless successfully_made_executable

admin_secret = ENV['INPUT_HASURA_ADMIN_SECRET']
path_to_project_root = ENV['INPUT_PATH_TO_HASURA_PROJECT_ROOT']

# 'cd' into project path if PATH_TO_HASURA_PROJECT_ROOT is given
Dir.chdir(path_to_project_root) if path_to_project_root

# Attempt to apply migrations
successfully_applied_migrations = system "hasura migrate apply --admin-secret #{admin_secret}"
abort 'Failed applying migrations' unless successfully_applied_migrations

# Stop the script here unless regression tests are enabled
return unless ENV['INPUT_HASURA_REGRESSION_TESTS_ENABLED'] == 'true'

# Configure Hasura Pro personal access token
hasura_pro_access_token = ENV.fetch('INPUT_HASURA_PERSONAL_ACCESS_TOKEN')
successfully_wrote_access_token = system "echo 'pat: #{hasura_pro_access_token}' >> ~/.hasura/pro_config.yaml"
abort 'Failed writing Pro personal access token to ~/.hasura/config.yaml' unless successfully_wrote_access_token

# Install Pro CLI plugin
successfully_installed_pro_plugin = system 'hasura plugins install pro'
abort 'Failed installing Pro CLI plugin' unless successfully_installed_pro_plugin

# Attempt to run regression tests
hasura_endpoint = ENV.fetch('INPUT_HASURA_ENDPOINT')
hasura_pro_project_id = ENV.fetch('INPUT_HASURA_PROJECT_ID')
hasura_pro_testsuite_id = ENV.fetch('INPUT_HASURA_REGRESSION_TESTSUITE_ID')

successfully_ran_regression_tests = system <<-EOF
  hasura pro regression-tests run \
    --endpoint #{hasura_endpoint} \
    --admin-secret #{admin_secret} \
    --project-id #{hasura_pro_project_id} \
    --testsuite-id #{hasura_pro_testsuite_id}
EOF

abort 'Failed regression tests' unless successfully_ran_regression_tests

