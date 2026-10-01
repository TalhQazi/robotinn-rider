import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/rider_header.dart';
import '../../providers/rider_auth_provider.dart';
import '../../services/rider_api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  void _changeProfilePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 65,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final bytes = await File(picked.path).readAsBytes();
      final base64Url = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await RiderApiService.updateProfile({'avatar': base64Url});
      if (mounted) {
        final auth = context.read<RiderAuthProvider>();
        if (auth.rider != null) {
          final updated = auth.rider!.copyWith(profilePic: base64Url);
          await auth.setRider(updated);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();
    final rider = auth.rider;
    final displayName = rider?.name ?? 'Rider';
    final email = rider?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RiderHeader(
        title: 'My Profile',
        showAvatar: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        backgroundImage: (rider?.profilePic != null && rider!.profilePic!.isNotEmpty)
                            ? NetworkImage(rider.profilePic!)
                            : null,
                        child: _isUploadingPhoto
                            ? const CircularProgressIndicator(color: AppColors.white)
                            : (rider?.profilePic == null || rider!.profilePic!.isEmpty)
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.white),
                                  )
                                : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _changeProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.warning, size: 14),
                            const SizedBox(width: 4),
                            Text('${rider?.rating ?? 5.0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: auth.isShiftActive ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auth.isShiftActive ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: auth.isShiftActive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

          
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle & Zone Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 20),
                  _infoTile(Icons.directions_bike_outlined, 'Vehicle Type', rider?.vehicleType.isNotEmpty == true ? rider!.vehicleType : 'Motorbike'),
                  _infoTile(Icons.pin_outlined, 'Number Plate', rider?.vehicleNumber.isNotEmpty == true ? rider!.vehicleNumber : 'Not set'),
                  _infoTile(Icons.map_outlined, 'Working Area', rider?.area.isNotEmpty == true ? rider!.area : 'All Zones'),
                  _infoTile(Icons.phone_outlined, 'Phone', rider?.phone.isNotEmpty == true ? rider!.phone : 'Not set'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _actionTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () => Navigator.of(context).pushNamed('/profile_edit'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Earning History',
                    onTap: () => Navigator.of(context).pushNamed('/earnings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.history_toggle_off,
                    title: 'Shift History',
                    onTap: () => Navigator.of(context).pushNamed('/shifts'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.headset_mic_outlined,
                    title: 'Support & Helpline',
                    onTap: () => Navigator.of(context).pushNamed('/support'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.gray, size: 20),
      onTap: onTap,
    );
  }
}
