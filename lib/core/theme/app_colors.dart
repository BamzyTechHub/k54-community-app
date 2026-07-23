import 'package:flutter/material.dart';

class AppColors {

  // Basic colors
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Brand colors
  static const green = Color(0xFF008000);
  static const gold = Color(0xFFAB8000);
  static const brandGradient = LinearGradient(
    colors: [green, gold, green],
  );

  /// Primary CTA button color (Login, Sign Up, Save, Publish, Touch/Face
  /// ID "Proceed") - pulled verbatim from a Figma-to-Code export of the
  /// actual Login frame (figma.dart, 2026-07-14): a single named
  /// "Default-button-color" (#B4D69E) with white text appears on every
  /// primary button in that export, no separate pressed/active variant
  /// exists in the file. [buttonPressedBg] is therefore an
  /// implementation choice (a darker shade for tap feedback), not a
  /// literal Figma value - confirmed acceptable 2026-07-14. Supersedes
  /// both the 2026-07-10 sage/gold-from-live-site decision and the
  /// short-lived 2026-07-14 attempt to reuse the AI pill colors here;
  /// that pill scheme is real but belongs to [pillRegularBg]/
  /// [pillActiveBg] below instead, confirmed by this same export
  /// contradicting it for primary buttons specifically.
  static const buttonRegularBg = Color(0xFFB4D69E);
  static const buttonPressedBg = lightGreen;
  static const buttonRegularText = white;
  static const buttonPressedText = white;

  /// Secondary pill-button color scheme (Follow/Message/Connect, Groups'
  /// Join/Joined, AI Assistant's quick-action chips): light green at
  /// rest, a deeper green when active/pressed, dark text throughout
  /// (never swaps to white) - confirmed directly from the AI Assistant
  /// quick-action pills (screenshotted 2026-07-14, both states shown).
  /// Distinct from [buttonRegularBg] above - the two components use
  /// different colors and text treatments in Figma, confirmed by the
  /// figma.dart Login export not matching this scheme.
  // #B4D69E confirmed repeatedly across independent frame pulls
  // 2026-07-16 (AI Assistant quick-action chips, Chat's outgoing bubble,
  // Members' card border, primary buttons) as the app's actual light-
  // green brand tone - decoupled from tabSelectedFill (#A9C4A9), which
  // turned out to be a different, unrelated value.
  static const pillRegularBg = Color(0xFFB4D69E);
  static const pillActiveBg = lightGreen;
  static const pillText = jetBlack;

  // Text colors
  static const jetBlack = Color(0xFF1A1A1A);
  static const subHeading = Color(0xFF505050);
  static const subHeading2 = Color(0xFF7D7C7C);

  // Greens
  static const softGreen = Color(0xFF578C77);
  static const lightGreen = Color(0xFF6C9B6E);

  // Border
  static const border = Color(0xFFDAD7D7);

  // Transparent / opacity versions
  static const transparentBlack = Color(0x00000000);
  static const greenOverlay = Color(0x4C578C77);

  // Friends/Messages/Groups shared row (ContactRow). Background corrected
  // 2026-07-16 to #FCF8ED, measured directly off the current Messages
  // frame (node 43:104) via the REST API - the old #F8F6F8 came from a
  // 2026-07-08 read that's since turned out to be from a stale file key.
  // Border (#DBD8D8) re-confirmed unchanged by the same fresh pull.
  static const friendRowBackground = Color(0xFFFCF8ED);
  static const friendRowBorder = Color(0xFFDBD8D8);
  static const onlineIndicator = Color(0xFF46A046);
  static const iconButtonBackground = Color(0xFFD9D9D9);
  static const tabSelectedFill = Color(0xFFA9C4A9);
  static const tabSelectedBorder = Color(0xFF588D78);

  // Groups screens (measured directly from the K54 Figma file,
  // nodes 50:1523 "Groups" and 87:76 "GROUPS", 2026-07-08)
  static const groupCardBackground = Color(0xFFE3DAC1);
  static const groupCardAccent = Color(0xFF588D78);
  static const groupMutedText = Color(0xFF515050);

  /// Fully transparent - same value as Flutter's own `Colors.transparent`,
  /// added so call sites never need to reach for the stock Material
  /// `Colors` class at all, even for "no color."
  static const transparent = Color(0x00000000);

  /// Neutral/grey scale - same literal values as Flutter's Material grey
  /// swatch (`Colors.grey`/`Colors.grey.shadeXXX`), centralized here
  /// 2026-07-21 so every screen sources greys from the app's own palette
  /// instead of scattering direct `Colors.grey.shadeXXX` references.
  /// Values are unchanged from Material's own - this is a source-of-truth
  /// consolidation, not a redesign.
  static const grey = Color(0xFF9E9E9E);
  static const greyShade200 = Color(0xFFEEEEEE);
  static const greyShade300 = Color(0xFFE0E0E0);
  static const greyShade400 = Color(0xFFBDBDBD);
  static const greyShade500 = grey;
  static const greyShade600 = Color(0xFF757575);
  static const greyShade700 = Color(0xFF616161);

  /// Status colors - same literal values as Flutter's Material palette
  /// (`Colors.red`/`Colors.orange`/`Colors.blue`/`Colors.amber.shade700`),
  /// centralized here for the same reason as the grey scale above.
  static const error = Color(0xFFF44336);
  static const errorLight = Color(0xFFEF9A9A);
  static const errorMedium = Color(0xFFEF5350);
  static const errorDark = Color(0xFFD32F2F);
  static const warning = Color(0xFFFF9800);
  static const warningDark = Color(0xFFEF6C00);
  static const info = Color(0xFF2196F3);
  static const amber = Color(0xFFFFA000);

  /// Exact literal values from Flutter's own `Colors.black87`/`white70`/
  /// etc. (real compile-time constants, not `.withValues()` calls - those
  /// aren't usable in a `const` context, which several of this app's
  /// existing `const TextStyle(...)` call sites need).
  static const black87 = Color(0xDD000000);
  static const black54 = Color(0x8A000000);
  static const black38 = Color(0x61000000);
  static const white70 = Color(0xB3FFFFFF);
  static const white54 = Color(0x8AFFFFFF);
  static const white24 = Color(0x3DFFFFFF);

}