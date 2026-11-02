#!/bin/bash
# Prepares a Claude Code cloud session so linters and tests can run:
# Composer + npm dependencies, plus a local MariaDB for the WordPress PHPUnit suite.
#
# Runs ASYNC: the session's first turn starts immediately while this installs in
# the background. A cold run takes ~10 minutes, almost all of it Composer: the
# session's GitHub proxy refuses archive (zipball/codeload) downloads for repos
# that aren't attached to the session, so every package is git-cloned instead.
# Progress goes to $LOG; $DONE is written when everything finished successfully.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Tell Claude Code to run the rest of this hook in the background (30 min cap).
echo '{"async": true, "asyncTimeout": 1800000}'

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 1

LOG=/tmp/rfsd-session-setup.log
DONE=/tmp/rfsd-session-setup.done
rm -f "$DONE"
exec >>"$LOG" 2>&1
echo "=== session setup started $(date -u +%FT%TZ)"

# Database settings read by tests/php/wp-tests-config.php (must match session-env.sh).
DB_NAME="wordpress_test"
DB_USER="root"
DB_PASS="root"

failed=()

# Runs a step, logging its duration; a failed step is recorded and the rest continue.
step() {
  local name=$1
  shift
  local start=$SECONDS
  echo "--- $name"
  if "$@"; then
    echo "--- $name ok ($((SECONDS - start))s)"
  else
    echo "--- $name FAILED ($((SECONDS - start))s)"
    failed+=("$name")
  fi
}

# Skips an install when the files that decide it are unchanged since it last succeeded.
# The hash file lives in the git-ignored directory the install fills.
up_to_date() {
  sha256sum --check --status "$1" 2>/dev/null
}

composer_install() {
  local hashes=vendor/.session-start.sha256
  up_to_date "$hashes" && { echo "vendor/ up to date"; return 0; }
  rm -f "$hashes"
  # Cloud sessions run as root; without this Composer disables plugins, so the
  # phpcs installer plugin never registers the WordPress coding standard.
  # --prefer-source: dist archives from GitHub are always refused by the session
  # proxy (403), so skip straight to git clones instead of failing 43 downloads.
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction --no-progress --prefer-source &&
    sha256sum composer.json composer.lock .claude/hooks/session-start.sh > "$hashes"
}

npm_install() {
  local hashes=node_modules/.session-start.sha256
  up_to_date "$hashes" && { echo "node_modules/ up to date"; return 0; }
  rm -f "$hashes"
  npm install --no-audit --no-fund &&
    sha256sum package.json package-lock.json > "$hashes"
}

mariadb_setup() {
  if ! command -v mariadbd >/dev/null 2>&1 && ! command -v mysqld >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq &&
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server || return 1
  fi

  if ! mysqladmin ping --silent >/dev/null 2>&1; then
    service mariadb start 2>/dev/null || service mysql start || return 1
    for _ in $(seq 1 30); do
      mysqladmin ping --silent >/dev/null 2>&1 && break
      sleep 1
    done
  fi

  # Idempotent: password-authenticated root over TCP and a fresh test database.
  # The check must use TCP (-h 127.0.0.1) like PHPUnit does: over the Unix socket,
  # MariaDB's unix_socket auth lets OS root in with any password, so the check
  # would pass without the password ever being set.
  mysql -h127.0.0.1 -P3306 -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME" >/dev/null 2>&1 && return 0
  mysql -uroot <<SQL
ALTER USER '$DB_USER'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$DB_PASS');
CREATE DATABASE IF NOT EXISTS $DB_NAME;
FLUSH PRIVILEGES;
SQL
}

# Quick steps first (seconds each), so Jest and the database are ready long
# before the slow Composer step finishes.
step "npm install" npm_install
step "mariadb" mariadb_setup
step "composer install" composer_install

if [ ${#failed[@]} -eq 0 ]; then
  date -u +%FT%TZ > "$DONE"
  echo "=== session setup finished OK $(date -u +%FT%TZ)"
else
  echo "=== session setup finished with failures: ${failed[*]} $(date -u +%FT%TZ)"
  exit 1
fi
