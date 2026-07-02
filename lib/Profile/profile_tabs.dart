import 'package:flutter/material.dart';
import 'profile_menu.dart';

class ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onMenuPressed;

  const ProfileTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onMenuPressed,
  });

  final List<String> tabs = const [
    "Timeline",
    "Connections",
    "Live Video",
    "Groups",
    "Messages",
    "Courses",
    "Invitations",
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),

            child: Row(
              children: List.generate(
                tabs.length,
                (index) => GestureDetector(
                  onTap: () => onTabChanged(index),

                  child: Container(
                    margin: const EdgeInsets.only(right: 20),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == index
                                ? const Color(0xFF008000)
                                : Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? const Color(0xFF008000)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

         ProfileMenu(
  onSelected: (value) {
    onMenuPressed(value);
  },
),

      ],
    );
  }
}