# Contributing to Renderbit FAQ Structured Data

Thank you for your interest in contributing! We welcome pull requests, bug reports, and feature suggestions.

## How to Contribute

1. **Fork the repository** and create your branch from `main`.
2. **Describe your changes** clearly in your pull request. Reference related issues if applicable.
3. **Follow project conventions**:
   - Use clear, descriptive commit messages.
   - Match the code style and structure found in the codebase.
   - Add or update inline comments where necessary.
4. **Test your changes** before submitting:
   - Run the test suites and coding standards (see [Running tests](#running-tests)). Add tests for new behavior and bug fixes.
   - Ensure the plugin activates and runs without errors.
   - If you add new features, provide usage notes in the PR description.
   - For bug fixes, describe the problem and how your change resolves it.
5. **Do not commit build artifacts, vendor, or local config files** (see `.gitignore`).

## Running tests

CI runs all of these on every pull request (`.github/workflows/tests.yml`).

**PHP (PHPUnit + WordPress test suite).** Needs PHP 7.4+, Composer and a MySQL/MariaDB server. The suite installs WordPress into the database on each run, so point it at a database you can wipe:

```bash
composer install
cp .env.testing.example .env.testing   # then set your database credentials
composer test
```

The test bootstrap loads `WP_TESTS_DB_*` settings from `.env.testing`, which is gitignored. Variables already set in your shell or in CI take precedence. Without either, they default to `wordpress_test`, `root`, an empty password and `127.0.0.1`. Tests live in `tests/php`.

Run `composer test:multisite` to run the suite as a multisite network. Tests that need a network are in the `ms-required` group and are left out of the single-site run; single-site-only tests are in `ms-excluded`.

**JavaScript (Jest).** Needs Node 18+:

```bash
npm install
npm test
```

Tests live in `tests/js`.

**Coding standards:** `composer lint`.

## Releasing

The plugin is published on WordPress.org as `renderbit-faq-structured-data` (https://wordpress.org/plugins/renderbit-faq-structured-data/). The shipped files are whatever `git archive` produces, so `.gitattributes` decides what reaches both the release zip and WordPress.org SVN.

1. Run `composer bump-patch` (or `bump-minor`, `bump-major`). It runs `bin/bump-version.php`, which sets the new version in `composer.json`, the `Version` header and `RFSD_VERSION` in `renderbit-faq-structured-data.php`, and `Stable tag` in `readme.txt`, then refreshes the `composer.lock` hash. Add a `readme.txt` changelog entry and bump `Tested up to` when needed.
2. Merge to `main`, then push a `vX.Y.Z` tag. `draft-release.yml` builds the zip and creates a draft GitHub release.
3. Publish the draft. `deploy-wporg.yml` checks that the tag and all three version numbers match, then commits trunk, the version tag and the `.wordpress-org/` directory (banners, icons, screenshots) to SVN.

The deploy needs `SVN_USERNAME` and `SVN_PASSWORD` secrets on the `wordpress-org` environment in the GitHub repository settings.

## Reporting Issues

- Provide detailed steps to reproduce the problem.
- Include relevant error messages, logs, or screenshots.
- Suggest a possible solution if you have one.

## Code of Conduct

Please be respectful and constructive in all interactions.

## Resources

- See the `README.md` for project overview and key files.
- See `.github/copilot-instructions.md` for AI agent and automation guidance.
- Review inline comments in each file for implementation details.

---
Thank you for helping improve Renderbit FAQ Structured Data!
