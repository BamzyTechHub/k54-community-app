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

  /// The real button color scheme, pulled directly from k54global.com's
  /// own CSS custom properties (--bb-primary-button-background-regular/
  /// hover) - light sage green by default, gold when pressed, black/white
  /// text to match. Figma's static renders show the bold [brandGradient]
  /// above for the same buttons instead; per direct instruction
  /// (2026-07-10) the live site wins for button color specifically. See
  /// core/widgets/primary_button.dart for the shared button widget built
  /// around these.
  static const buttonRegularBg = Color(0xFFB9D6AD);
  static const buttonPressedBg = gold;
  static const buttonRegularText = black;
  static const buttonPressedText = white;

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

  // Friends screen (measured directly from the K54 Figma file,
  // node 50:1005 "Friends", 2026-07-08)
  static const friendRowBackground = Color(0xFFF8F6F8);
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