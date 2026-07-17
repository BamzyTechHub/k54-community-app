import 'package:flutter/material.dart';

import 'package:k54_mobile/core/widgets/filter_popover.dart';

/// The filter popover from the Members Figma screenshot (two stacked
/// cards: "Search filter" and "Members view filter"), anchored below the
/// header's filter icon via [layerLink] - built on the shared
/// [showFilterPopover].
///
/// "Members view filter" is real, working functionality - it drives the
/// same confirmed `type` sort param (active/newest/alphabetical) the
/// toolbar's own sort dropdown already uses via [onSortSelected].
///
/// "Search filter" (Field/Industry, Professional Status, User Name, Last
/// (Sur)Name) is shown exactly as designed but not wired to a live
/// filter: BuddyBoss's members endpoint does have an `xprofile` query
/// param (confirmed via a live OPTIONS request 2026-07-18), but its
/// expected value shape ("Limit results set to a certain xProfile
/// field.") isn't documented beyond that one line, and guessing at the
/// format risks silently returning wrong or empty results - a hidden
/// failure, not a visible "coming soon". Tapping an entry here says so
/// instead of pretending to filter.
void showMembersFilterPopover({
  required BuildContext context,
  required LayerLink layerLink,
  required String currentSort,
  required void Function(String sortKey) onSortSelected,
  required void Function(String fieldLabel) onSearchFilterTapped,
}) {
  const sortOptions = {
    "active": "Recently Active",
    "newest": "Newest Members",
    "alphabetical": "Alphabetical",
  };
  const searchFilterLabels = ["Field / Industry", "Professional Status", "User Name", "Last (Sur)Name"];

  showFilterPopover(
    context: context,
    layerLink: layerLink,
    sections: [
      FilterSection(
        label: "Search filter",
        options: searchFilterLabels
            .map((label) => FilterOption(
                  label: label,
                  selected: false,
                  onTap: () => onSearchFilterTapped(label),
                ))
            .toList(),
      ),
      FilterSection(
        label: "Members view filter",
        options: sortOptions.entries
            .map((e) => FilterOption(
                  label: e.value,
                  selected: currentSort == e.key,
                  onTap: () => onSortSelected(e.key),
                ))
            .toList(),
      ),
    ],
  );
}
