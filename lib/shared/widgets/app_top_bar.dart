import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar._({
    super.key,
    required this.isDashboard,
    this.avatarInitial = 'M',
    this.hasNotifications = false,
    this.onBellTap,
    this.onAvatarTap,
    this.title,
    this.onBack,
  });

  factory AppTopBar.dashboard({
    Key? key,
    String avatarInitial = 'M',
    bool hasNotifications = false,
    VoidCallback? onBellTap,
    VoidCallback? onAvatarTap,
  }) =>
      AppTopBar._(
        key: key,
        isDashboard: true,
        avatarInitial: avatarInitial,
        hasNotifications: hasNotifications,
        onBellTap: onBellTap,
        onAvatarTap: onAvatarTap,
      );

  factory AppTopBar.inner({
    Key? key,
    required String title,
    VoidCallback? onBack,
  }) =>
      AppTopBar._(
        key: key,
        isDashboard: false,
        title: title,
        onBack: onBack,
      );

  final bool isDashboard;
  final String avatarInitial;
  final bool hasNotifications;
  final VoidCallback? onBellTap;
  final VoidCallback? onAvatarTap;
  final String? title;
  final VoidCallback? onBack;

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isDashboard
                ? _DashboardRow(
                    avatarInitial: avatarInitial,
                    hasNotifications: hasNotifications,
                    onBellTap: onBellTap,
                    onAvatarTap: onAvatarTap,
                  )
                : _InnerRow(
                    title: title ?? '',
                    onBack: onBack ?? () => context.go('/inicio'),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.avatarInitial,
    required this.hasNotifications,
    required this.onBellTap,
    required this.onAvatarTap,
  });

  final String avatarInitial;
  final bool hasNotifications;
  final VoidCallback? onBellTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.rocket_launch,
            color: Colors.black,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'RocketId',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _BellButton(
          hasNotifications: hasNotifications,
          onTap: onBellTap,
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarInitial,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasNotifications, required this.onTap});

  final bool hasNotifications;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          if (hasNotifications)
            const Positioned(
              top: 8,
              right: 8,
              child: _NotificationDot(),
            ),
        ],
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.notificationDot,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _InnerRow extends StatelessWidget {
  const _InnerRow({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderChip),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
