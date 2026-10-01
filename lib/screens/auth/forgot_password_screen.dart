import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_text_field.dart';
import '../../components/common/themed_alert.dart';
import '../../services/rider_api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ThemedAlert.show(context, title: 'Invalid Email', message: 'Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await RiderApiService.sendOTPCode(email);
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/create_new_password',
          arguments: {'email': email},
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Error',
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
        title: const Text('Forgot Password'),
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
            const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email address to receive a 6-digit verification code.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Email Address',
              hintText: 'rider@example.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send Verification Code',
              isLoading: _isLoading,
              onPressed: _handleSendCode,
            ),
          ],
        ),
      ),
    );
  }
}
