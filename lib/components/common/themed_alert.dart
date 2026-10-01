import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AlertActionItem {
  final String text;
  final VoidCallback? onPress;
  final bool isDestructive;
  final bool isCancel;

  AlertActionItem({
    required this.text,
    this.onPress,
    this.isDestructive = false,
    this.isCancel = false,
  });
}

class ThemedAlert {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    List<AlertActionItem>? buttons,
  }) {
    final effectiveButtons = buttons ?? [AlertActionItem(text: 'OK')];

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        backgroundColor: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: effectiveButtons.map((btn) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        btn.onPress?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btn.isDestructive
                            ? AppColors.error
                            : (btn.isCancel ? AppColors.lightGray : AppColors.primary),
                        foregroundColor: btn.isCancel ? AppColors.textPrimary : AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      child: Text(
                        btn.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: btn.isCancel ? AppColors.textPrimary : AppColors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
