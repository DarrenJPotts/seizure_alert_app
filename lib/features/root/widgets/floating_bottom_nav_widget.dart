import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/root/root_view.dart';

class FloatingBottomNavWidget extends StatelessWidget {
  const FloatingBottomNavWidget({
    super.key,
    required this.controller,
    this.caregiver = false,
  });

  final RootViewModel controller;

  final bool caregiver;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.only(bottom: Dimensions.twenty),
    child: caregiver
        ? _buildCaregiverNav(context)
        : Padding(
            padding: const EdgeInsets.only(top: Dimensions.thirtyTwo),
            child: _buildPatientNav(context),
          ),
  );

  Widget _buildCaregiverNav(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
    height: 70,
    decoration: BoxDecoration(
      color: context.paper,
      borderRadius: BorderRadius.circular(context.design.navRadius),
      border: context.designBorder,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FloatingNavItem(
            icon: Icons.visibility_outlined,
            activeIcon: Icons.visibility,
            isActive: controller.currentIndex.value == 0,
            onTap: () => controller.changePage(0),
            semanticLabel: 'Watch list',
          ),
          _FloatingNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            isActive: controller.currentIndex.value == 1,
            onTap: () => controller.changePage(1),
            semanticLabel: 'Alerts',
          ),
          _FloatingNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isActive: controller.currentIndex.value == 2,
            onTap: () => controller.changePage(2),
            semanticLabel: 'Profile',
          ),
        ],
      ),
    ),
  );

  Widget _buildPatientNav(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Container(
      margin: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth < 296
            ? Dimensions.sixteen
            : Dimensions.twentyFour,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: context.paper,
              borderRadius: BorderRadius.circular(context.design.navRadius),
              border: context.designBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
                    semanticLabel: 'Home',
                  ),
                  _FloatingNavItem(
                    icon: Icons.book_outlined,
                    activeIcon: Icons.book_rounded,
                    isActive: controller.currentIndex.value == 1,
                    onTap: () => controller.changePage(1),
                    semanticLabel: 'Daily log',
                  ),
                  const SizedBox(width: Dimensions.fortyEight),
                  _FloatingNavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    isActive: controller.currentIndex.value == 3,
                    onTap: () => controller.changePage(3),
                    semanticLabel: 'My circle',
                  ),
                  _FloatingNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    isActive: controller.currentIndex.value == 4,
                    onTap: () => controller.changePage(4),
                    semanticLabel: 'Profile',
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: -25,
            child: Semantics(
              button: true,
              label: 'SOS',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.changePage(2);
                },
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.heroSurface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: context.heroInk,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          Obx(() {
            double? dotPosition;
            if (controller.currentIndex.value == 2) {
              dotPosition = null;
            }

            if (dotPosition == null && controller.currentIndex.value == 2) {
              return Positioned(
                bottom: 8,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.ink,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    ),
  );
}

class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final String semanticLabel;

  const _FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: Dimensions.fortyEight,
            minHeight: Dimensions.fortyEight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.eight,
            vertical: Dimensions.twelve,
          ),
          decoration: BoxDecoration(
            color: isActive && context.design.filledSelection
                ? context.ink
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.design.cardRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? (context.design.filledSelection
                          ? context.paper
                          : context.ink)
                    : context.secondaryInk,
                size: 26,
              ),
              const SizedBox(height: Dimensions.four),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 6 : 0,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.design.filledSelection
                      ? context.paper
                      : context.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
