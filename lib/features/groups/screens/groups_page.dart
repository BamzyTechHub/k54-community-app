import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';

/// Single source of truth for the Groups screen, reused from both places
/// it's reachable in the app: the main bottom nav (as its own pushed
/// destination, [embedded] = false) and the Messages/Friends/Groups tab
/// bar (as one tab's body, [embedded] = true). Previously these were two
/// separate, drifted implementations with different mock data - merged
/// per the requirement that both entry points show the same screen.
///
/// Data is still hardcoded mock content - no real API wiring yet, and no
/// Figma reference has been reviewed for this screen. This consolidation
/// is structural only; the visual design should be revisited against
/// Figma once that's available.
class GroupsPage extends StatefulWidget {
  final bool embedded;

  const GroupsPage({super.key, this.embedded = false});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int selectedTab = 0;

  final List<String> tabs = [
    "All Groups",
    "My Groups",
    "Create a Group",
  ];

  final List<Map<String, dynamic>> groups = [
    {
      "name": "Feast for Families, Inc",
      "type": "Public • Group",
      "active": "Active 3 days ago",
      "button": "Organizer",
      "isOwner": true,
      "cover": "assets/images/group_cover1.png",
      "logo": "assets/images/group_logo1.png",
    },
    {
      "name": "Fit23 Health & Wellness",
      "type": "Public • Group",
      "active": "Active 6 days ago",
      "button": "Join Group",
      "isOwner": false,
      "cover": "assets/images/group_cover2.png",
      "logo": "assets/images/group_logo2.png",
    },
    {
      "name": "Business Growth Network",
      "type": "Private • Group",
      "active": "Active today",
      "button": "Join Group",
      "isOwner": false,
      "cover": "assets/images/group_cover3.png",
      "logo": "assets/images/group_logo3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 28),
                ),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFD9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Search groups",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Filter options later
                },
                icon: const Icon(Icons.filter_alt_outlined, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = selectedTab == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedTab = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xFF008000)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF008000) : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                "${groups.length} Groups",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text("Recently Active", style: TextStyle(fontSize: 12)),
                    SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.grid_view, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFD9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                        child: Image.asset(
                          group["cover"],
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(group["logo"]),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group["name"],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${group["type"]} • ${group["active"]}",
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                const CircleAvatar(radius: 13, backgroundColor: Colors.blue),
                                const SizedBox(width: 5),
                                const CircleAvatar(radius: 13, backgroundColor: Colors.orange),
                                const SizedBox(width: 5),
                                const CircleAvatar(radius: 13, backgroundColor: Colors.purple),
                                const SizedBox(width: 5),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text("...", style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: group["isOwner"]
                                        ? const Color(0xFF008000)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF008000)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        group["isOwner"] ? Icons.check : Icons.add,
                                        size: 16,
                                        color: group["isOwner"]
                                            ? Colors.white
                                            : const Color(0xFF008000),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        group["button"],
                                        style: TextStyle(
                                          color: group["isOwner"]
                                              ? Colors.white
                                              : const Color(0xFF008000),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: content),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 3),
    );
  }
}
