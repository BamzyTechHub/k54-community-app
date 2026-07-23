<?php
/**
 * K54 Live Video Bridge
 *
 * PURPOSE
 * The mobile app authenticates every request with a JWT bearer token, not
 * a browser cookie session. WPStream's own "what's live / give me the
 * playback URL" logic only exists behind admin-ajax.php actions
 * (wpstream_give_me_live_uri, wpstream_check_event_status, etc.), which
 * only trust a real WordPress cookie session - a JWT request can never
 * satisfy that check from outside.
 *
 * This snippet exposes new REST routes (which JWT auth already works
 * with, same as every other endpoint this app calls) that internally
 * trigger those same WPStream ajax actions in PHP, for the current
 * logged-in user - no browser cookie needed, because it's happening
 * server-side in the same request.
 *
 * HOW TO INSTALL
 * Paste this whole file into Code Snippets (already active on this site)
 * as a new snippet, set "Run snippet everywhere", and activate it.
 *
 * CAVEATS - please read before relying on this
 * 1. WordPress ajax handlers almost always end by calling wp_die() (or
 *    wp_send_json_success/error, which call wp_die() internally) - which
 *    would normally kill this whole PHP request. The k54_live_call_ajax
 *    helper below temporarily swaps out wp_die's behavior so it can catch
 *    that and recover the real output instead of the app just getting a
 *    dead connection - but this is exactly the kind of thing that
 *    benefits from a real test against the live site.
 * 2. The `nonce`/`security` value WPStream's own handlers check for is
 *    generated here as wp_create_nonce($action) - i.e. guessing the
 *    action's own name is the nonce action string, a common WordPress
 *    convention but not a universal one. If the /current-channel or
 *    /event-status routes below return an error mentioning "nonce" or
 *    "security check failed", that's the first thing to adjust - check
 *    the WPStream plugin's own PHP source (search for
 *    `check_ajax_referer` or `wp_verify_nonce`) for the exact string it
 *    expects.
 * 3. Test with the /debug route first (returns the raw, undecoded output)
 *    before trusting the cleaner /current-channel and /event-status
 *    routes - if WPStream's handler returns HTML/an error page instead of
 *    JSON, this will show you exactly what came back instead of a
 *    confusing empty response.
 */

add_action('rest_api_init', function () {
    register_rest_route('k54-live/v1', '/current-channel', [
        'methods' => 'GET',
        'callback' => 'k54_live_get_current_channel',
        'permission_callback' => function () {
            return is_user_logged_in();
        },
    ]);

    register_rest_route('k54-live/v1', '/event-status', [
        'methods' => 'GET',
        'callback' => 'k54_live_get_event_status',
        'permission_callback' => function () {
            return is_user_logged_in();
        },
        'args' => [
            'channel_id' => ['required' => true],
        ],
    ]);

    // Confirmed live 2026-07-22: WPStream stores each user's channel as a
    // `wpstream_product` post in wp_posts, with post_author = that user's
    // WordPress user id (e.g. Ezekiel's is post #1472). No ajax call or
    // user-meta lookup needed - a direct, ordinary post query resolves a
    // user's own channel id.
    register_rest_route('k54-live/v1', '/my-channel', [
        'methods' => 'GET',
        'callback' => function () {
            global $wpdb;
            $user_id = get_current_user_id();
            $channel = $wpdb->get_row(
                $wpdb->prepare(
                    "SELECT ID, post_title, post_status FROM {$wpdb->posts} WHERE post_type = 'wpstream_product' AND post_author = %d AND post_status = 'publish' LIMIT 1",
                    $user_id
                ),
                ARRAY_A
            );
            return rest_ensure_response([
                'user_id' => $user_id,
                'channel_id' => $channel ? $channel['ID'] : null,
                'channel' => $channel,
            ]);
        },
        'permission_callback' => function () {
            return is_user_logged_in();
        },
    ]);

    // Same lookup as /my-channel, but for any user id - needed when a
    // viewer (not the broadcaster themselves) opens someone else's live
    // activity post and needs to resolve that OTHER person's channel id
    // before it can call /event-status.
    register_rest_route('k54-live/v1', '/channel-for-user', [
        'methods' => 'GET',
        'callback' => function ($request) {
            global $wpdb;
            $user_id = (int) $request->get_param('user_id');
            $channel = $wpdb->get_row(
                $wpdb->prepare(
                    "SELECT ID, post_title, post_status FROM {$wpdb->posts} WHERE post_type = 'wpstream_product' AND post_author = %d AND post_status = 'publish' LIMIT 1",
                    $user_id
                ),
                ARRAY_A
            );
            return rest_ensure_response([
                'user_id' => $user_id,
                'channel_id' => $channel ? $channel['ID'] : null,
                'channel' => $channel,
            ]);
        },
        'permission_callback' => function () {
            return is_user_logged_in();
        },
        'args' => [
            'user_id' => ['required' => true],
        ],
    ]);

    // Confirmed real live 2026-07-23 via a captured browser network
    // request + a live before/after test on the real site: this is
    // wpstream_give_me_live_uri (same action as /current-channel) but with
    // one extra param, `start_onboarding` (empty string) - THAT'S what
    // actually flips the channel to ON, not just fetching the broadcast
    // URL. /current-channel (without this param) does not turn the
    // channel on - confirmed both ways live.
    register_rest_route('k54-live/v1', '/turn-on-channel', [
        'methods' => 'POST',
        'callback' => function ($request) {
            $show_id = $request->get_param('show_id') ?: '';
            $result = k54_live_call_ajax_action('wpstream_give_me_live_uri', [
                'show_id' => $show_id,
                'is_record' => 'false',
                'is_encrypt' => 'false',
                'start_onboarding' => '',
            ]);
            return rest_ensure_response($result);
        },
        'permission_callback' => function () {
            return is_user_logged_in();
        },
        'args' => [
            'show_id' => ['required' => true],
        ],
    ]);

    // Confirmed real live 2026-07-23 via a captured browser network
    // request: clicking "TURN OFF" on the real site's Live Video page
    // fires this exact ajax action (yes, "turn_of" - a real typo in
    // WPStream's own plugin code, not ours) with a `show_id` param.
    register_rest_route('k54-live/v1', '/turn-off-channel', [
        'methods' => 'POST',
        'callback' => 'k54_live_turn_off_channel',
        'permission_callback' => function () {
            return is_user_logged_in();
        },
        'args' => [
            'show_id' => ['required' => true],
        ],
    ]);

    // Test this one first - shows the raw response from WPStream's own
    // handler, undecoded, so you can see exactly what came back.
    register_rest_route('k54-live/v1', '/debug', [
        'methods' => 'GET',
        'callback' => 'k54_live_debug',
        'permission_callback' => function () {
            return current_user_can('manage_options'); // admins only
        },
        'args' => [
            'action_name' => ['required' => true],
            'channel_id' => ['required' => false],
            'show_id' => ['required' => false],
        ],
    ]);
});

/**
 * Internally simulates a logged-in ajax call to $action, for the current
 * REST request's authenticated user - without needing a browser cookie
 * session, since this runs server-side in the same PHP process.
 */
function k54_live_call_ajax_action($action, $extra_args = []) {
    if (!defined('DOING_AJAX')) {
        define('DOING_AJAX', true);
    }

    $_REQUEST['action'] = $action;
    $_POST['action'] = $action;
    foreach ($extra_args as $key => $value) {
        $_REQUEST[$key] = $value;
        $_POST[$key] = $value;
    }

    // Best-effort nonce - see caveat #2 above if this doesn't work.
    $nonce = wp_create_nonce($action);
    foreach (['nonce', 'security', '_wpnonce'] as $nonce_key) {
        $_REQUEST[$nonce_key] = $nonce;
        $_POST[$nonce_key] = $nonce;
    }

    // wp_die() would normally terminate this whole request - catch it
    // instead so we can return the buffered output cleanly. This filter
    // is removed again in the `finally` block below no matter what
    // happens, so it never leaks into any other request.
    $die_handler = function () {
        return function ($message = '', $title = '', $args = []) {
            throw new Exception(is_string($message) ? $message : 'wp_die called');
        };
    };
    add_filter('wp_die_ajax_handler', $die_handler);

    ob_start();
    $caught = null;
    try {
        do_action('wp_ajax_' . $action);
    } catch (\Throwable $e) {
        $caught = $e;
    } finally {
        remove_filter('wp_die_ajax_handler', $die_handler);
    }
    $output = ob_get_clean();

    if (empty($output) && $caught !== null) {
        // wp_die was called with no prior echo - nothing useful came
        // back, likely a permission/nonce failure inside WPStream's own
        // handler.
        return ['error' => true, 'message' => $caught->getMessage(), 'raw_output' => ''];
    }

    $decoded = json_decode($output, true);
    return $decoded !== null ? $decoded : ['raw_output' => $output];
}

function k54_live_get_current_channel($request) {
    $show_id = $request->get_param('show_id') ?: '';
    $result = k54_live_call_ajax_action('wpstream_give_me_live_uri', [
        'show_id' => $show_id,
        'is_record' => 'false',
        'is_encrypt' => 'false',
    ]);
    return rest_ensure_response($result);
}

function k54_live_turn_off_channel($request) {
    $show_id = $request->get_param('show_id');
    // Confirmed real action name + param live 2026-07-23 via a captured
    // browser network request (the real site's own "TURN OFF" button).
    $result = k54_live_call_ajax_action('wpstream_turn_of_channel', [
        'show_id' => $show_id,
    ]);
    return rest_ensure_response($result);
}

function k54_live_get_event_status($request) {
    $channel_id = $request->get_param('channel_id');
    // wpstream_check_event_status died silently (wrong nonce convention) -
    // wpstream_player_check_status is the one confirmed live to return the
    // real playback payload (started, event_uri/HLS url, chat_url, poster,
    // channel_title, etc.) for a given channel_id.
    $result = k54_live_call_ajax_action('wpstream_player_check_status', [
        'channel_id' => $channel_id,
    ]);
    return rest_ensure_response($result);
}

function k54_live_debug($request) {
    $action = $request->get_param('action_name');
    $extra = [];
    if ($request->get_param('channel_id')) {
        $extra['channel_id'] = $request->get_param('channel_id');
    }
    if ($request->get_param('show_id')) {
        $extra['show_id'] = $request->get_param('show_id');
    }
    $result = k54_live_call_ajax_action($action, $extra);
    return rest_ensure_response($result);
}
