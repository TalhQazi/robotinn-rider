import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../constants/app_constants.dart';
import '../../services/rider_api_service.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _callHelpline() async {
    final uri = Uri.parse('tel:${AppConstants.helpline.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openSupportChat(BuildContext context) async {
    try {
      final convId = await RiderApiService.startConversation('support_admin');
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/chat',
          arguments: {
            'conversationId': convId,
            'title': 'RobotInn Support',
            'participantId': 'support_admin',
          },
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: _contactCard(
                    icon: Icons.phone_in_talk,
                    title: 'Rider Helpline',
                    subtitle: AppConstants.helpline,
                    color: AppColors.primary,
                    onTap: _callHelpline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _contactCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    subtitle: 'Instant auto-help',
                    color: AppColors.secondary,
                    onTap: () => _openSupportChat(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            _faqTile(
              question: 'How do I start and end my shift?',
              answer: 'Go to the Dashboard and toggle the "Shift On" switch. Make sure your location permissions are granted. To end your shift, toggle it off to calculate duration and earnings.',
            ),
            _faqTile(
              question: 'How are my rider delivery earnings calculated?',
              answer: 'Earnings are credited for each delivered order based on the delivery charge. You can review your active shift earnings on the Dashboard or full records in Earning History.',
            ),
            _faqTile(
              question: 'Why do I need to photograph store receipts?',
              answer: 'Store receipt photos verify actual purchase amounts for the admin. Attach clear photos on the Active Order screen before submitting the bill.',
            ),
            _faqTile(
              question: 'What if an item is not available at the store?',
              answer: 'Contact the customer via in-app chat or phone. If they wish to cancel, select "Item not available" in the Cancel Order options on the Order Details screen.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _faqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
