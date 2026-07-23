import 'package:flutter/material.dart';

import 'package:k54_mobile/core/widgets/filter_popover.dart';

/// The filter popover from the Members Figma screenshot, anchored below
/// the header's filter icon via [layerLink] - built on the shared
/// [showFilterPopover].
///
/// Search-only now - the "Members view filter" section (Recently
/// Active/Newest/Alphabetical) was dropped per direct tester feedback:
/// it was a straight duplicate of the toolbar's own "Recently Active"
/// sort dropdown, and the funnel icon next to the search bar should only
/// control search, not the member-view sort. [onSortSelected] is kept as
/// a param so callers don't need changing, but nothing in this popover
/// calls it anymore.
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
    ],
  );
}
