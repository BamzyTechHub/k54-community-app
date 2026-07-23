<?php
/**
 * K54 Friends Remove-Friendship Bridge
 *
 * PURPOSE
 * `DELETE /buddyboss/v1/friends/{id}` reliably returns a 500
 * ("bp_rest_friends_cannot_delete_item" / "Could not delete friendship")
 * when removing an already-CONFIRMED friendship - confirmed live
 * 2026-07-24 to be a real bug in BuddyBoss's own REST controller, NOT in
 * BuddyPress core: calling the real underlying `friends_remove_friend()`
 * function directly (the same function their own REST controller is
 * supposed to call) succeeds cleanly every time - confirmed via a direct
 * diagnostic call that returned `true` and left the friendship row
 * actually deleted from the database. Canceling a still-PENDING
 * (unconfirmed) request through the official DELETE endpoint works fine
 * and is untouched - this bridge is only for the confirmed-friendship
 * case their endpoint can't handle.
 *
 * HOW TO INSTALL
 * Paste this whole file into Code Snippets as a new snippet (replacing
 * the earlier k54-friends-remove-debug diagnostic version), "Run snippet
 * everywhere", activate it.
 */

add_action('rest_api_init', function () {
    register_rest_route('k54-friends/v1', '/remove', [
        'methods' => 'POST',
        'callback' => function ($request) {
            global $wpdb;
            $friendship_id = (int) $request->get_param('friendship_id');
            $current_user_id = get_current_user_id();

            $row = $wpdb->get_row(
                $wpdb->prepare(
                    "SELECT initiator_user_id, friend_user_id FROM {$wpdb->prefix}bp_friends WHERE id = %d",
                    $friendship_id
                ),
                ARRAY_A
            );

            if (!$row) {
                return new WP_Error('k54_friendship_not_found', 'Friendship not found.', ['status' => 404]);
            }

            $initiator_id = (int) $row['initiator_user_id'];
            $friend_id = (int) $row['friend_user_id'];

            // Only either side of the friendship can remove it - same
            // access rule BuddyBoss's own (broken) endpoint is supposed
            // to enforce, just re-implemented here since we're bypassing
            // their controller entirely.
            if ($current_user_id !== $initiator_id && $current_user_id !== $friend_id) {
                return new WP_Error('k54_not_authorized', 'You are not part of this friendship.', ['status' => 403]);
            }

            if (!function_exists('friends_remove_friend')) {
                return new WP_Error('k54_bp_not_loaded', 'BuddyPress Friends component not available.', ['status' => 500]);
            }

            $result = friends_remove_friend($initiator_id, $friend_id);

            return rest_ensure_response(['deleted' => (bool) $result]);
        },
        'permission_callback' => function () {
            return is_user_logged_in();
        },
        'args' => [
            'friendship_id' => ['required' => true],
        ],
    ]);
});
