import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BillImagePreviewModal extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String title;

  const BillImagePreviewModal({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.title = 'Receipt Preview',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
        
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: imageFile != null
                  ? Image.file(imageFile!)
                  : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const CircularProgressIndicator(color: AppColors.primary);
                          },
                        )
                      : const Text('No image available', style: TextStyle(color: AppColors.white)),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
