import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_text_field.dart';
import '../../components/common/themed_alert.dart';
import '../../providers/rider_auth_provider.dart';
import '../../services/rider_api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  String _vehicleType = 'Motorbike';
  final List<String> _vehicleTypes = ['Motorbike', 'Bicycle', 'Car', 'Van'];
  bool _isLoading = false;

  static const List<String> _fallbackAreas = [
    'F-6',
    'F-7',
    'F-8',
    'F-10',
    'F-11',
    'G-6',
    'G-7',
    'G-8',
    'G-9',
    'G-10',
    'G-11',
    'E-7',
    'E-8',
    'E-9',
    'E-11',
    'I-8',
    'I-9',
    'I-10',
    'DHA Phase 1',
    'DHA Phase 2',
    'Bahria Phase 7',
    'Bahria Phase 8',
    'Gulberg Residencia',
    'Bani Gala',
    'Other areas',
  ];

  @override
  void initState() {
    super.initState();
    final rider = context.read<RiderAuthProvider>().rider;
    if (rider != null) {
      _nameCtrl.text = rider.name;
      _phoneCtrl.text = rider.phone;
      _areaCtrl.text = rider.area;
      _vehicleNumberCtrl.text = rider.vehicleNumber;
      if (_vehicleTypes.contains(rider.vehicleType)) {
        _vehicleType = rider.vehicleType;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  void _showAreaPicker() async {
    List<String> areas = List.from(_fallbackAreas);
    try {
      final fetched = await RiderApiService.getAreas();
      if (fetched.isNotEmpty) {
        areas = fetched;
        if (!areas.contains('Other areas')) areas.add('Other areas');
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = areas
                .where((a) => a.toLowerCase().contains(filter.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Working Area (Islamabad)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                      hintText: 'Search area (e.g. F-10, G-9, Bahria)...',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setModalState(() => filter = val),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching areas found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (c, idx) {
                              final areaName = filtered[idx];
                              final isSelected = _areaCtrl.text == areaName;
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on_outlined,
                                  color: isSelected ? AppColors.primary : AppColors.gray,
                                ),
                                title: Text(
                                  areaName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _areaCtrl.text = areaName);
                                  Navigator.pop(modalCtx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleSave() async {
    final auth = context.read<RiderAuthProvider>();
    final currentRider = auth.rider;
    if (currentRider == null) return;

    if (_nameCtrl.text.trim().isEmpty) {
      ThemedAlert.show(context, title: 'Error', message: 'Please enter your name');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ThemedAlert.show(context, title: 'Error', message: 'Please enter your phone number');
      return;
    }
    if (_areaCtrl.text.trim().isEmpty) {
      ThemedAlert.show(context, title: 'Error', message: 'Please select your working area');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updateData = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'vehicleType': _vehicleType,
        'vehicleNumber': _vehicleNumberCtrl.text.trim(),
      };

      await RiderApiService.updateProfile(updateData);
      final updatedRider = currentRider.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
      );
      await auth.setRider(updatedRider);

      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Profile Updated',
          message: 'Your profile changes have been saved successfully.',
          buttons: [
            AlertActionItem(
              text: 'OK',
              onPress: () => Navigator.pop(context),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Full Name',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vehicle Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _vehicleType,
                  isExpanded: true,
                  items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _vehicleType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Vehicle Number Plate',
              controller: _vehicleNumberCtrl,
              prefixIcon: Icons.pin_outlined,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showAreaPicker,
              child: AbsorbPointer(
                child: CustomTextField(
                  label: 'Working Area / Zone (Islamabad)',
                  hintText: 'Tap to select area',
                  controller: _areaCtrl,
                  prefixIcon: Icons.map_outlined,
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Save Changes',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}

