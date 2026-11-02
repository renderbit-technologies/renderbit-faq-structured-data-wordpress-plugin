# Renderbit FAQ Structured Data

[![WordPress Plugin](https://img.shields.io/badge/WordPress-Plugin-21759B?logo=wordpress&logoColor=fff)](https://wordpress.org/plugins/renderbit-faq-structured-data/)
![PHP](https://img.shields.io/badge/PHP-%E2%89%A5%207.2-777BB4?logo=php&logoColor=fff)
![MySQL](https://img.shields.io/badge/MySQL-Mapping%20Table-4479A1?logo=mysql&logoColor=fff)
![WP-Cron](https://img.shields.io/badge/Background-WP--Cron%20Queue-orange)
![WP-CLI](https://img.shields.io/badge/CLI-WP--CLI-21759B?logo=wordpress&logoColor=fff)
![Select2](https://img.shields.io/badge/Admin-Select2-e535ab)
[![Tests](https://github.com/renderbit-technologies/renderbit-faq-structured-data-wordpress-plugin/actions/workflows/tests.yml/badge.svg)](https://github.com/renderbit-technologies/renderbit-faq-structured-data-wordpress-plugin/actions/workflows/tests.yml)
[![License: GPL v2+](https://img.shields.io/badge/License-GPL%20v2%2B-blue.svg)](LICENSE.md)

A WordPress plugin to manage FAQ items as a custom post type (CPT) and inject FAQ JSON-LD into posts/pages. Designed for performance and scalability with advanced cache management, background queueing, and admin/CLI tools.

## Features

- **Custom Post Type:** Manage FAQ items via the `rfsd_faq` CPT (the old FAQ JSON-LD Manager plugin used `faq_item`; its FAQs are imported on activation).
- **Mapping Table:** Fast MySQL table (`rfsd_mappings`) links FAQ items to posts, post types, terms, URLs, or global context.
- **JSON-LD Output:** Injects FAQ schema on the frontend, with per-post transient caching.
- **Cache Invalidation:** Background queue (WP-Cron or WP-CLI) for efficient cache purging.
- **Admin UI:** Meta boxes and settings for mapping, output, and diagnostics.
- **Health & Diagnostics:** Admin page for queue/logs and manual actions.
- **WP-CLI Integration:** Commands for cache and queue management.

## Installation

The plugin is available on WordPress.org: <https://wordpress.org/plugins/renderbit-faq-structured-data/>

**From the WordPress admin (recommended):** go to Plugins > Add New, search for "Renderbit FAQ Structured Data", then install and activate it.

**Manually:**

1. Download the plugin from [WordPress.org](https://wordpress.org/plugins/renderbit-faq-structured-data/) (or build a zip with `composer build-zip`) and copy the folder to your WordPress `wp-content/plugins/` directory.
2. Activate via the WordPress admin Plugins page.
3. On activation, the mapping table is created automatically.

## Usage

- **Add FAQ Items:** Use the `FAQ Items` CPT in the admin menu.
- **Associate FAQs:** Use meta boxes to link FAQs to posts, post types, terms, URLs, or globally.
- **Singular content only:** JSON-LD is printed on singular views (posts, pages, custom post types). Blog home, archives and search results never output FAQ markup, so URL mappings apply to singular content only (archive URLs are not matched).
- **Output:** Markup is schema.org `FAQPage`. Question and answer text is plain text: tags stripped, entities decoded, whitespace collapsed. Answers run through blocks and shortcodes but not the `the_content` filter.
- **Settings:** Configure cache TTL and invalidation batch size (10-5000) under the FAQ Items > Settings menu.
- **Translations:** Strings use the `renderbit-faq-structured-data` text domain (loaded just-in-time by WordPress 4.6+); admin JS strings are localized through `wp_localize_script`.
- **Requirements:** WordPress 6.5+, PHP 7.2+.
- **Health:** Monitor queue/logs and run manual actions under FAQ Items > Health.
- **WP-CLI:**
  - `wp rfsd purge-transients` — Purge all FAQ JSON-LD transients.
  - `wp rfsd process-queue [--limit=N]` — Process the invalidation queue.
  - `wp rfsd queue-info` — Show the number of pending queue items.

## Developer Notes

### Filters

- `rfsd_question_text( $text, $faq_post )` — filter the plain-text question for a FAQ item.
- `rfsd_answer_text( $text, $faq_post )` — filter the plain-text answer. Return plain text; the JSON encoder escapes `<`, `>` and `&`. Cached output is cleared on settings changes or with `wp rfsd purge-transients`.

- **Key Files:**
  - `renderbit-faq-structured-data.php`: Main loader and CPT registration
  - `includes/indexer.php`: Mapping table logic
  - `includes/queue.php`: Invalidation queue
  - `includes/frontend.php`: JSON-LD output/caching
  - `includes/admin.php`: Admin UI/meta boxes
  - `includes/settings.php`: Settings page
  - `includes/health.php`: Health/diagnostics UI
  - `includes/class-rfsd-cli.php`: WP-CLI commands
  - `assets/js/rfsd-admin.js`, `assets/js/rfsd-health.js`: Admin JS (Select2 is bundled in `assets/vendor/select2`)
- **Mapping Types:** All associations are stored in a single table for fast lookups.
- **Transient Keys:** `rfsd_faq_json_{generation}_{post_id}` (build with `rfsd_cache_key( $post_id )`). "Purge all" bumps the `rfsd_cache_gen` option, which works with persistent object caches too.
- **Uninstall:** Deleting the plugin removes its options, transients, cron events, post meta and mapping table (on every site of a multisite network). FAQ posts are kept by default; to delete them as well, add `add_filter( 'rfsd_uninstall_delete_faqs', '__return_true' );` (e.g. in a mu-plugin) before deleting the plugin.
- **Admin JS:** Uses Select2 for post selectors, AJAX for search (`rfsd_search_posts` action; all public post types except attachments and FAQs). Switching the association type keeps each type's in-progress selection until you save; only the selected type is stored.
- **Background Processing:** The invalidation queue lives in a database table and is processed every 5 minutes by WP-Cron (up to the batch size per run), or on demand from the Health page or WP-CLI.
- **Asset versions:** The plugin's own JS is versioned with `RFSD_VERSION`; keep it in sync with the `Version` header when releasing.

## Testing

- **PHP:** PHPUnit integration tests against a real WordPress install (`tests/php`). Run with `composer test`; needs a MySQL database.
- **JavaScript:** Jest tests for the admin scripts (`tests/js`). Run with `npm test`.
- **Coding standards:** `composer lint`.

See [CONTRIBUTING.md](CONTRIBUTING.md#running-tests) for setup.

## Contributing

Pull requests and issues are welcome. Please follow project conventions and review inline comments in each file for guidance.

## License

This project is licensed under the GNU General Public License v2.0 or later — see the [LICENSE.md](LICENSE.md) file for details.

SPDX-License-Identifier: `GPL-2.0-or-later`

---

For more details, see the inline comments in each file or the `.github/copilot-instructions.md` for AI agent guidance.
