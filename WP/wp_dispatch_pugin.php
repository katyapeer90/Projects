<?php
/**
 * Plugin Name: WP Core Dispatch to GitHub
 * Description: On successful WP core update, triggers GitHub Actions workflow to create a new branch for Dockerfile bump.
 */

error_log('[WP Core Dispatch] MU-plugin loaded');

if ( ! defined( 'ABSPATH' ) ) exit;

function wp_ci_site_key(): string {
    $k = getenv('WP_SITE_KEY');
    if (is_string($k) && $k !== '') return $k;
    if (defined('WP_SITE_KEY') && is_string(WP_SITE_KEY) && WP_SITE_KEY !== '') return WP_SITE_KEY;
    return 'unknown';
}

define('GH_OWNER', 'OrtMapa');
define('GH_REPO',  'github-shared-workflows');
define('GH_TOKEN', getenv('GH_DISPATCH_TOKEN'));
define('GH_EVENT_TYPE', 'wp_core_updated');


/* =========================
 * shared dispatch function
 * (so multiple hooks can call the same logic)
 * ========================= */
function wp_ci_read_code_wp_version(): string {
    $version_file = ABSPATH . 'wp-includes/version.php';

    if (is_readable($version_file)) {
        require $version_file;
        if (isset($wp_version) && is_string($wp_version) && $wp_version !== '') {
            return $wp_version;
        }
    }

    return get_bloginfo('version') ?: 'unknown';
}
function wp_ci_dispatch_to_github(string $wp_version): void {

    $site_key = wp_ci_site_key();
    if ($site_key === 'unknown') {
        error_log('[WP Core Dispatch] WP_SITE_KEY is unknown - skipping dispatch');
        return;
    }

    if (!GH_TOKEN) {
        error_log('[WP Core Dispatch] GH_DISPATCH_TOKEN is missing - skipping dispatch');
        return;
    }

    $payload = [
        'site_key'    => $site_key,
        'wp_version'  => (string)$wp_version,
        'site_url'    => get_site_url(),
        'environment' => getenv('ENVIRONMENT') ?: 'unknown',
        'timestamp'   => gmdate('c'),

        //helps you see which hook fired (useful for debugging)
        'source'      => 'upgrader_process_complete',
    ];

    $url = 'https://api.github.com/repos/' . GH_OWNER . '/' . GH_REPO . '/dispatches';

    //this log should appear when the trigger fires
    error_log('[WP Core Dispatch] Sending repository_dispatch: site_key=' . $site_key . ' wp_version=' . $wp_version . ' env=' . $payload['environment']);

    $res = wp_remote_post($url, [
        'timeout' => 10,
        'headers' => [
            'Authorization' => 'Bearer ' . GH_TOKEN,
            'Accept'        => 'application/vnd.github+json',
            'User-Agent'    => 'wp-core-dispatch',
            'Content-Type'  => 'application/json',
        ],
        'body' => wp_json_encode([
            'event_type'     => GH_EVENT_TYPE,
            'client_payload' => $payload,
        ]),
    ]);

    if (is_wp_error($res)) {
        error_log('[WP Core Dispatch] Failed: ' . $res->get_error_message());
        return;
    }

    // always log the GitHub response code (204 means success)
    $code = wp_remote_retrieve_response_code($res);
    $body = wp_remote_retrieve_body($res);
    error_log('[WP Core Dispatch] GitHub response code=' . $code . ' body=' . substr((string)$body, 0, 200));
}

/* =========================
 * upgrader_process_complete hook
 * This triggers for core updates even when done by tools like Umbrella,
 * and we filter to core only.
 * ========================= */
add_action('upgrader_process_complete', function($upgrader, $hook_extra) {

    // Only WordPress core updates
    if (empty($hook_extra['type']) || $hook_extra['type'] !== 'core') {
        return;
    }

    // Only update actions (optional but safe)
    if (!empty($hook_extra['action']) && $hook_extra['action'] !== 'update') {
        return;
    }

    // Get WP version after the upgrade completes
    $wp_version = wp_ci_read_code_wp_version();

    wp_ci_dispatch_to_github($wp_version);

}, 10, 2);