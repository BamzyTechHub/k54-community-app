import 'package:flutter/material.dart';

import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// A common-emoji grid for the chat composer - entirely local (no backend
/// dependency at all, unlike attachments/camera which need a confirmed
/// upload endpoint this app doesn't have yet), so this is real, working
/// functionality rather than a "coming soon" stub. Not the emoji-reaction
/// system Better Messages has on individual messages (meta.reactions) -
/// that's a separate, still-unbuilt feature - this is just inserting an
/// emoji character into the text being composed.
const _kCommonEmoji = [
  "😀", "😂", "🥰", "😍", "😊", "😉", "😎", "🤔",
  "😢", "😭", "😡", "😱", "🙏", "👍", "👎", "👏",
  "🙌", "💪", "🤝", "❤️", "💚", "💛", "🔥", "✨",
  "🎉", "🎊", "😴", "🤗", "😜", "🙄", "😅", "🤣",
  "👋", "✅", "❌", "⭐", "💯", "🥳", "😇", "🤩",
];

Future<void> showEmojiPickerSheet({
  required BuildContext context,
  required ValueChanged<String> onSelected,
}) {
  return showK54BottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _kCommonEmoji.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            final emoji = _kCommonEmoji[index];
            return TapScale(
              onTap: () {
                Navigator.pop(sheetContext);
                onSelected(emoji);
              },
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            );
          },
        ),
      ),
    ),
  );
}
