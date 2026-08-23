import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/root/root_view.dart';

class FloatingBottomNavWidget extends StatelessWidget {
  const FloatingBottomNavWidget({super.key, required this.controller});

  final RootViewModel controller;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(
      left: Dimensions.twentyFour,
      right: Dimensions.twentyFour,
      bottom: Dimensions.twenty,
    ),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Main navigation bar
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FloatingNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  isActive: controller.currentIndex.value == 0,
                  onTap: () => controller.changePage(0),
                ),
                _FloatingNavItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book_rounded,
                  isActive: controller.currentIndex.value == 1,
                  onTap: () => controller.changePage(1),
                ),
                const SizedBox(width: 56), // Space for elevated button
                _FloatingNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  isActive: controller.currentIndex.value == 3,
                  onTap: () => controller.changePage(3),
                ),
                _FloatingNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  isActive: controller.currentIndex.value == 4,
                  onTap: () => controller.changePage(4),
                ),
              ],
            ),
          ),
        ),

        // Elevated SOS button
        Positioned(
          top: -25,
          child: GestureDetector(
            onTap: () => controller.changePage(2),
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: Offset(0, 8))],
              ),
              child: Icon(Icons.emergency, color: Colors.white, size: 32),
            ),
          ),
        ),

        // Active indicator dot
        Obx(() {
          double? dotPosition;
          if (controller.currentIndex.value == 2) {
            dotPosition = null; // Center (elevated button)
          }

          if (dotPosition == null && controller.currentIndex.value == 2) {
            return Positioned(
              bottom: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              ),
            );
          }
          return SizedBox.shrink();
        }),
      ],
    ),
  );
}

/// Floating Navigation Item
class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingNavItem({required this.icon, required this.activeIcon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(Dimensions.twelve),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: isActive ? Colors.black : Colors.black38, size: 26),
            SizedBox(height: Dimensions.four),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: isActive ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
