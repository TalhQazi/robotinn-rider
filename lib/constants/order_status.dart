import 'package:flutter/material.dart';

class OrderStatusConstants {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String shopping = 'processing'; 
  static const String billSubmitted = 'bill_submitted';
  static const String billRejected = 'bill_rejected';
  static const String adjustmentPending = 'adjustment_pending';
  static const String adjustmentRejected = 'adjustment_rejected';
  static const String billApproved = 'bill_approved';
  static const String outForDelivery = 'picked';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static const List<String> activeStatuses = [
    accepted,
    shopping,
    billSubmitted,
    billRejected,
    adjustmentPending,
    adjustmentRejected,
    billApproved,
    outForDelivery,
  ];

  static String normalize(dynamic status) {
    final raw = (status ?? '').toString().trim().toLowerCase();
    if (raw.isEmpty) return pending;

   
    switch (raw) {
      case 'in progress':
      case 'arrived_at_store':
        return shopping;
      case 'picked up':
      case 'picked_up':
      case 'out_for_delivery':
        return outForDelivery;
      case 'completed':
        return delivered;
      case 'bill_pending':
      case 'pending_admin_validation':
        return billSubmitted;
      case 'admin_confirmed':
      case 'admin_receipt_validated':
        return billApproved;
      default:
        return raw;
    }
  }

  static bool isActive(dynamic status) {
    return activeStatuses.contains(normalize(status));
  }

  static String getLabel(dynamic status) {
    final s = normalize(status);
    switch (s) {
      case pending:
        return 'Pending';
      case accepted:
        return 'Accepted';
      case shopping:
        return 'Rider at store';
      case billSubmitted:
        return 'Awaiting admin approval';
      case billRejected:
        return 'Bill rejected';
      case adjustmentPending:
        return 'Price approval needed';
      case adjustmentRejected:
        return 'Price declined';
      case billApproved:
        return 'Bill approved';
      case outForDelivery:
        return 'Out for delivery';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  static Color getColor(dynamic status) {
    final s = normalize(status);
    switch (s) {
      case delivered:
        return const Color(0xFF4CAF50);
      case pending:
        return const Color(0xFFFF6B6B);
      case billRejected:
      case adjustmentRejected:
      case cancelled:
        return const Color(0xFFE63946);
      case accepted:
      case shopping:
      case billSubmitted:
      case adjustmentPending:
      case billApproved:
      case outForDelivery:
        return const Color(0xFFFFA500);
      default:
        return const Color(0xFF9BA1A6);
    }
  }

  static IconData getIcon(dynamic status) {
    final s = normalize(status);
    switch (s) {
      case delivered:
        return Icons.check_circle_outline;
      case pending:
        return Icons.timelapse;
      case billRejected:
      case adjustmentRejected:
      case cancelled:
        return Icons.warning_amber_rounded;
      default:
        return Icons.access_time;
    }
  }
}
