import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../constants/app_constants.dart';
import '../../providers/rider_auth_provider.dart';
import '../../services/location_tracker_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _autoNavigation = true;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    LocationTrackerService.getLocationSharingEnabled().then((val) {
      if (mounted) setState(() => _locationEnabled = val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Preferences'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Order Notifications', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Receive instant alerts for new orders', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    value: _pushEnabled,
                    onChanged: (val) => setState(() => _pushEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sound & Alerts', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Play sound on order claim and chat', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto Maps Navigation', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Prompt maps on order delivery stage', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    value: _autoNavigation,
                    onChanged: (val) => setState(() => _autoNavigation = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader('Privacy & Location'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: SwitchListTile(
                title: const Text('Live location sharing', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text(
                  _locationEnabled
                      ? 'Customers can see your position on active orders'
                      : 'Off — enable to share live delivery location',
                  style: const TextStyle(fontSize: 12),
                ),
                activeColor: AppColors.primary,
                value: _locationEnabled,
                onChanged: (val) async {
                  setState(() => _locationEnabled = val);
                  await LocationTrackerService.setLocationSharingEnabled(val);
                  if (val && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live location sharing enabled for active orders.')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader('Account & Security'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: const Text('Edit Profile Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
                    onTap: () => Navigator.of(context).pushNamed('/profile_edit'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                    title: const Text('Reset Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
                    onTap: () => Navigator.of(context).pushNamed('/forgot_password'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader('About'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('App Name', style: TextStyle(fontSize: 14)),
                      const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Version', style: TextStyle(fontSize: 14)),
                      const Text(AppConstants.appVersion, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
      ),
    );
  }
}
