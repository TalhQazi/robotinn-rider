import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_text_field.dart';
import '../../components/common/themed_alert.dart';
import '../../services/rider_api_service.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;

  const CreateNewPasswordScreen({super.key, required this.email});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _handleVerifyAndReset() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ThemedAlert.show(context, title: 'Invalid Code', message: 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await RiderApiService.verifyOTPAndResetPassword(widget.email, code);
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Code Verified!',
          message: 'A secure password reset link has been emailed to ${widget.email}. Please follow the link to complete your password update.',
          buttons: [
            AlertActionItem(
              text: 'Back to Login',
              onPress: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Verification Failed',
          message: e.toString().replaceAll('Exception:', '').trim(),
        );
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
        title: const Text('Verify Code'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.header),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Enter 6-Digit Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Code sent to: ${widget.email}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Verification Code',
              hintText: '123456',
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.pin_outlined,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify & Reset Password',
              isLoading: _isLoading,
              onPressed: _handleVerifyAndReset,
            ),
          ],
        ),
      ),
    );
  }
}
