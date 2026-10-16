import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_text_field.dart';
import '../../services/rider_api_service.dart';
import '../../utils/auth_error_helper.dart';

enum PhotoFieldType {
  drivingLicense,
  registration,
  bikePhoto,
  selfie,
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _picker = ImagePicker();

  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedArea = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Step 2 Controllers
  final _licenseNumCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();

  File? _licensePhoto;
  File? _regPhoto;
  File? _bikePhoto;
  File? _selfiePhoto;

  List<String> _areas = RiderApiService.staticAreas;
  String _areaSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final fetched = await RiderApiService.getAreas();
      if (mounted && fetched.isNotEmpty) {
        setState(() => _areas = fetched);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _licenseNumCtrl.dispose();
    _regNumCtrl.dispose();
    super.dispose();
  }

  // --- Step 1 Validation ---
  bool _validateStep1() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty || _selectedArea.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields and select area.');
      return false;
    }

    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return false;
    }

    if (phone.length < 5 || phone.length > 20) {
      setState(() => _errorMessage = 'Phone number must be between 5 and 20 characters.');
      return false;
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    if (password.length < 8 || !hasLetter || !hasNumber) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long and contain at least 1 letter and 1 number.');
      return false;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }

  // --- Step 2 Validation ---
  bool _validateStep2() {
    if (_licensePhoto == null) {
      setState(() => _errorMessage = 'Please upload driving license photo.');
      return false;
    }
    if (_licenseNumCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter driving license number.');
      return false;
    }
    if (_regPhoto == null) {
      setState(() => _errorMessage = 'Please upload bike registration photo.');
      return false;
    }
    if (_regNumCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter bike registration number.');
      return false;
    }
    if (_bikePhoto == null) {
      setState(() => _errorMessage = 'Please upload bike photo with number plate.');
      return false;
    }
    if (_selfiePhoto == null) {
      setState(() => _errorMessage = 'Please upload your selfie.');
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }

  void _handleNextStep() {
    if (_validateStep1()) {
      setState(() {
        _errorMessage = null;
        _currentStep = 2;
      });
    }
  }

  void _handleSignup() async {
    if (!_validateStep2()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await RiderApiService.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        area: _selectedArea,
        photoNumber: _licenseNumCtrl.text.trim(),
        registrationNumber: _regNumCtrl.text.trim(),
        vehicleNumber: _regNumCtrl.text.trim(),
        vehicleType: 'Motorbike',
        licenseFile: _licensePhoto,
        registrationFile: _regPhoto,
        bikePhotoFile: _bikePhoto,
        selfieFile: _selfiePhoto,
      );

      if (res['success'] == true && mounted) {
        _showSuccessDialog();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = res['message']?.toString() ?? 'Registration failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthErrorHelper.parse(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                'Account Created! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account request has been sent to admin for approval.\n\nYou will be able to login once the admin approves your documents.\n\nThank you for joining RobotInn!',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Ok',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Photo Picker Sheet ---
  void _openPhotoSourcePicker(PhotoFieldType field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Spacer(),
                const Text(
                  'Choose Photo Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo with Camera',
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(field, ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _buildPhotoOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(field, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(PhotoFieldType field, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (picked != null) {
        setState(() {
          final file = File(picked.path);
          switch (field) {
            case PhotoFieldType.drivingLicense:
              _licensePhoto = file;
              break;
            case PhotoFieldType.registration:
              _regPhoto = file;
              break;
            case PhotoFieldType.bikePhoto:
              _bikePhoto = file;
              break;
            case PhotoFieldType.selfie:
              _selfiePhoto = file;
              break;
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  // --- Area Picker Modal ---
  void _openAreaPicker() {
    _areaSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _areas.where((a) {
            return a.toLowerCase().contains(_areaSearchQuery.toLowerCase());
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Your Area',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.gray),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: (val) {
                      setModalState(() => _areaSearchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Islamabad area...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No areas found', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F2F5)),
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            final isSelected = _selectedArea == item;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              title: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedArea = item;
                                  _errorMessage = null;
                                });
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Photo Upload Card Widget ---
  Widget _buildPhotoUploadField({
    required PhotoFieldType field,
    required String label,
    required String description,
    required File? photo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        if (photo != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  photo,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      switch (field) {
                        case PhotoFieldType.drivingLicense:
                          _licensePhoto = null;
                          break;
                        case PhotoFieldType.registration:
                          _regPhoto = null;
                          break;
                        case PhotoFieldType.bikePhoto:
                          _bikePhoto = null;
                          break;
                        case PhotoFieldType.selfie:
                          _selfiePhoto = null;
                          break;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => _openPhotoSourcePicker(field),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Step 1 View ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.delivery_dining, size: 50, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Join RobotInn 🚀',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your rider account (Step 1/2)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // White Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Full Name',
                hintText: 'John Doe',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Email Address',
                hintText: 'rider@robotinn.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Phone Number',
                hintText: '03123456789',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              // Area Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Area (Islamabad)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _openAreaPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedArea.isEmpty ? 'Choose your working area' : _selectedArea,
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedArea.isEmpty ? AppColors.gray : AppColors.textPrimary,
                                fontWeight: _selectedArea.isEmpty ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Password',
                hintText: '••••••••',
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Text(
                    _showPassword ? 'HIDE' : 'SHOW',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Confirm Password',
                hintText: '••••••••',
                controller: _confirmPassCtrl,
                obscureText: !_showConfirmPassword,
                prefixIcon: Icons.shield_outlined,
                suffixIcon: IconButton(
                  icon: Text(
                    _showConfirmPassword ? 'HIDE' : 'SHOW',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                _buildErrorBox(_errorMessage!),
                const SizedBox(height: 14),
              ],

              CustomButton(
                text: 'Next: Upload Documents →',
                onPressed: _handleNextStep,
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 2 View ---
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Center(
          child: Column(
            children: [
              Text(
                'Upload Documents 📄',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Complete your profile (Step 2/2)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // White Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoUploadField(
                field: PhotoFieldType.drivingLicense,
                label: 'Driving License Photo',
                description: 'Please upload a clear photo of your driving license',
                photo: _licensePhoto,
              ),
              CustomTextField(
                label: 'Driving License Number',
                hintText: 'Enter your license number',
                controller: _licenseNumCtrl,
                prefixIcon: Icons.tag_rounded,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 18),

              _buildPhotoUploadField(
                field: PhotoFieldType.registration,
                label: 'Bike Registration Certificate',
                description: 'Upload a photo of your bike registration',
                photo: _regPhoto,
              ),
              CustomTextField(
                label: 'Bike Registration Number',
                hintText: 'Enter your registration number (e.g. LE-2024-4567)',
                controller: _regNumCtrl,
                prefixIcon: Icons.tag_rounded,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 18),

              _buildPhotoUploadField(
                field: PhotoFieldType.bikePhoto,
                label: 'Bike Photo with Number Plate',
                description: 'Full bike photo showing the number plate clearly',
                photo: _bikePhoto,
              ),

              _buildPhotoUploadField(
                field: PhotoFieldType.selfie,
                label: 'Your Selfie',
                description: 'Take a live photo of yourself with your phone camera',
                photo: _selfiePhoto,
              ),

              if (_errorMessage != null) ...[
                _buildErrorBox(_errorMessage!),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _errorMessage = null;
                              _currentStep = 1;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      side: const BorderSide(color: AppColors.lightGray, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '← Back',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Submit & Sign Up',
                      isLoading: _isLoading,
                      onPressed: _handleSignup,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }
}
