import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemCount = items.length;
    final itemWidth = screenWidth / itemCount;
    final indicatorWidth = itemWidth * 0.6;
    final horizontalPadding = (itemWidth - indicatorWidth) / 2;

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: (itemWidth * currentIndex) + horizontalPadding,
            top: 10,
            child: Container(
              width: indicatorWidth,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1F4ED8).withAlpha((255 * 0.15).toInt()),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Icons and Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _buildNavItem(item.icon, item.label, index, itemWidth);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double itemWidth) {
    final bool isSelected = currentIndex == index;
    final Color activeColor = const Color(0xFF1F4ED8);
    final Color inactiveColor = const Color(0xFF333333);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: itemWidth,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
