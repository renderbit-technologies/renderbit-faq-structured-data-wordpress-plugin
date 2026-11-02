#!/bin/bash
# Synchronous and instant: only writes static session environment variables.
# The slow dependency installs live in session-start.sh, which runs async.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] || [ -z "${CLAUDE_ENV_FILE:-}" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Database settings read by tests/php/wp-tests-config.php (must match session-start.sh).
{
  echo 'export WP_TESTS_DB_HOST="127.0.0.1:3306"'
  echo 'export WP_TESTS_DB_USER="root"'
  echo 'export WP_TESTS_DB_PASSWORD="root"'
  echo 'export WP_TESTS_DB_NAME="wordpress_test"'
  echo "export PATH=\"$PWD/vendor/bin:\$PATH\""
} >> "$CLAUDE_ENV_FILE"
