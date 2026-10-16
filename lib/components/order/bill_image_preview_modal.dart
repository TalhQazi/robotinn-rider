import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BillImagePreviewModal extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final Uint8List? imageBytes;
  final String title;

  const BillImagePreviewModal({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.title = 'Receipt Preview',
  });

  /// Helper to decode base64 if source is a data URI or raw base64 string
  static Uint8List? tryExtractBase64(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    try {
      String clean = source.trim();
      if (clean.contains('base64,')) {
        clean = clean.split('base64,').last.trim();
      } else if (clean.startsWith('data:image')) {
        clean = clean.split(',').last.trim();
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      if (clean.isNotEmpty && !clean.startsWith('http')) {
        return base64Decode(clean);
      }
    } catch (_) {}
    return null;
  }

  /// Helper to extract File from string or File object
  static File? tryExtractFile(dynamic source) {
    if (source is File) return source;
    if (source is String && source.trim().isNotEmpty) {
      String p = source.trim();
      if (p.startsWith('file://')) {
        p = p.replaceFirst('file://', '');
      }
      if (p.startsWith('/') || p.contains(':\\') || p.contains(':/')) {
        final f = File(p);
        if (f.existsSync()) return f;
      }
    }
    return null;
  }

  /// Helper to test if string is an HTTP/HTTPS URL
  static bool isHttpUrl(String? source) {
    if (source == null) return false;
    final s = source.trim().toLowerCase();
    return s.startsWith('http://') || s.startsWith('https://');
  }

  /// Reusable thumbnail builder for list views and cards
  static Widget buildThumbnail(
    dynamic source, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final fallback = errorWidget ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFF1E293B),
          alignment: Alignment.center,
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 28),
        );

    if (source == null) return fallback;

    if (source is File) {
      if (!source.existsSync()) return fallback;
      return Image.file(source, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => fallback);
    }

    if (source is Uint8List) {
      return Image.memory(source, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => fallback);
    }

    if (source is String && source.trim().isNotEmpty) {
      final s = source.trim();
      final bytes = tryExtractBase64(s);
      if (bytes != null) {
        return Image.memory(bytes, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => fallback);
      }
      final file = tryExtractFile(s);
      if (file != null) {
        return Image.file(file, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => fallback);
      }
      if (isHttpUrl(s)) {
        return Image.network(
          s,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, prog) {
            if (prog == null) return child;
            return Container(
              width: width,
              height: height,
              color: const Color(0xFF0F172A),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          },
        );
      }
    }

    return fallback;
  }

  Widget _buildImageContent() {
    // 1. Direct bytes
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, error, __) => _buildErrorState('Could not display image bytes: $error'),
      );
    }

    // 2. Direct File
    if (imageFile != null) {
      if (!imageFile!.existsSync()) {
        return _buildErrorState('Receipt file not found on local storage.');
      }
      return Image.file(
        imageFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, error, __) => _buildErrorState('Could not decode receipt file.'),
      );
    }

    // 3. String imageUrl (could be base64 data uri, local path, or http URL)
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final cleanUrl = imageUrl!.trim();

      // Check base64
      final bytes = tryExtractBase64(cleanUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, error, __) => _buildErrorState('Corrupted or invalid base64 image data.'),
        );
      }

      // Check local file path
      final localFile = tryExtractFile(cleanUrl);
      if (localFile != null) {
        return Image.file(
          localFile,
          fit: BoxFit.contain,
          errorBuilder: (_, error, __) => _buildErrorState('Could not read local receipt file.'),
        );
      }

      // Check HTTP / HTTPS
      if (isHttpUrl(cleanUrl)) {
        return Image.network(
          cleanUrl,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            final total = progress.expectedTotalBytes;
            final loaded = progress.cumulativeBytesLoaded;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  if (total != null && total > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${(loaded / total * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          },
          errorBuilder: (_, error, __) => _buildErrorState('Failed to load receipt from server.\nPlease verify internet connection.'),
        );
      }
    }

    return _buildErrorState('No receipt photo available.');
  }

  Widget _buildErrorState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'Receipt Preview Unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Interactive viewer for pinch-to-zoom & pan
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 70, bottom: 20),
                  child: _buildImageContent(),
                ),
              ),
            ),

            // Top Header Overlay with SafeArea
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
