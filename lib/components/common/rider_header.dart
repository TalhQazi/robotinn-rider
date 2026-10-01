import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../providers/rider_auth_provider.dart';
import '../../providers/rider_shift_provider.dart';

class RiderHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final bool showLogo;
  final bool showAvatar;
  final IconData? rightIcon;
  final VoidCallback? onRightPress;
  final VoidCallback? onBackPress;

  const RiderHeader({
    super.key,
    this.title,
    this.showBack = false,
    this.showLogo = false,
    this.showAvatar = true,
    this.rightIcon,
    this.onRightPress,
    this.onBackPress,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  void _openDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _RiderSidebarDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();
    final rider = auth.rider;
    final unreadCount = auth.unreadCount;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.header,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
                  onPressed: onBackPress ?? () => Navigator.of(context).pop(),
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.white, size: 26),
                  onPressed: () => _openDrawer(context),
                ),

              
              Expanded(
                child: Center(
                  child: showLogo
                      ? Image.asset(
                          'assets/images/logo1.png',
                          height: 38,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'RobotInn Rider',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          title ?? '',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),

              
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAvatar)
                    GestureDetector(
                      onTap: () => _openDrawer(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white.withOpacity(0.6), width: 1.5),
                        ),
                        child: ClipOval(
                          child: (rider?.profilePic != null && rider!.profilePic!.isNotEmpty)
                              ? Image.network(
                                  rider.profilePic!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarFallback(rider.name),
                                )
                              : _avatarFallback(rider?.name ?? 'R'),
                        ),
                      ),
                    ),
                  if (rightIcon != null || unreadCount >= 0)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(rightIcon ?? Icons.notifications_none, color: AppColors.white, size: 24),
                          onPressed: onRightPress ??
                              () {
                                Navigator.of(context).pushNamed('/notifications');
                              },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    return Container(
      color: AppColors.primary.withOpacity(0.5),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}


class _RiderSidebarDrawer extends StatelessWidget {
  const _RiderSidebarDrawer();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();
    final shiftProv = context.watch<RiderShiftProvider>();
    final rider = auth.rider;
    final displayName = rider?.name ?? 'Rider';
    final email = rider?.email ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppGradients.header,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.white,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        backgroundImage: (rider?.profilePic != null && rider!.profilePic!.isNotEmpty)
                            ? NetworkImage(rider.profilePic!)
                            : null,
                        child: (rider?.profilePic == null || rider!.profilePic!.isEmpty)
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: auth.isShiftActive ? AppColors.success : AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auth.isShiftActive ? 'Online' : 'Offline',
                              style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

              
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCol('Rating', '${rider?.rating ?? 5.0} ★'),
                      _divider(),
                      _statCol('Deliveries', '${shiftProv.currentShift?.ordersCompleted ?? rider?.deliveries ?? 0}'),
                      _divider(),
                      _statCol('Shift Time', shiftProv.activeDurationFormatted),
                    ],
                  ),
                ),
              ],
            ),
          ),

          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _menuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Earning History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/earnings');
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.access_time_outlined,
                  title: 'Shift History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/shifts');
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  badge: auth.unreadCount > 0 ? auth.unreadCount.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/notifications');
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.headset_mic_outlined,
                  title: 'Support & Help',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/support');
                  },
                ),
                const Divider(),
                _menuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 24, color: AppColors.white.withOpacity(0.3));
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? badge,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontSize: 15,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : const Icon(Icons.chevron_right, color: AppColors.gray, size: 20),
      onTap: onTap,
    );
  }
}
