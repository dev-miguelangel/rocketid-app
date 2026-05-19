import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem('Inicio', Icons.home_outlined, Icons.home),
    _NavItem('Agenda', Icons.calendar_month_outlined, Icons.calendar_month),
    _NavItem('Actividad', Icons.directions_run, Icons.directions_run),
    _NavItem('Contactos', Icons.people_outlined, Icons.people),
    _NavItem('Perfil', Icons.person_outlined, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavSlot(
                  item: _items[i],
                  isActive: i == currentIndex,
                  isCenter: i == 2,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.iconInactive, this.iconActive);
  final String label;
  final IconData iconInactive;
  final IconData iconActive;
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.isActive,
    required this.isCenter,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final bool isCenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandGreen : AppColors.textMuted;
    final labelStyle = TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
    );

    return InkWell(
      onTap: onTap,
      child: isCenter
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: Center(child: _CenterTile(icon: item.iconActive)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? item.iconActive : item.iconInactive,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(item.label, style: labelStyle),
              ],
            ),
    );
  }
}

class _CenterTile extends StatelessWidget {
  const _CenterTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 32),
    );
  }
}
