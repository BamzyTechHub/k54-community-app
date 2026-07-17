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

}