import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String id;
  final String shiftId;
  final String riderId;
  final String startTime;
  final String? endTime;
  final bool active;
  final int ordersCompleted;
  final double earnings;
  final int durationMinutes;
  final GeoPoint? startLocation;
  final GeoPoint? endLocation;

  ShiftModel({
    required this.id,
    required this.shiftId,
    required this.riderId,
    required this.startTime,
    this.endTime,
    this.active = true,
    this.ordersCompleted = 0,
    this.earnings = 0.0,
    this.durationMinutes = 0,
    this.startLocation,
    this.endLocation,
  });

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShiftModel.fromMap(data, doc.id);
  }

  factory ShiftModel.fromMap(Map<String, dynamic> data, [String? id]) {
    final start = data['startTime']?.toString() ?? data['startedAt']?.toString() ?? '';
    final end = data['endTime']?.toString() ?? data['endedAt']?.toString();
    
    int dur = (data['duration'] is num) ? (data['duration'] as num).toInt() : 0;
    if (dur == 0 && start.isNotEmpty) {
      try {
        final st = DateTime.parse(start);
        final en = end != null ? DateTime.parse(end) : DateTime.now();
        dur = en.difference(st).inMinutes;
      } catch (_) {}
    }

    return ShiftModel(
      id: id ?? data['id']?.toString() ?? '',
      shiftId: data['shiftId']?.toString() ?? id ?? '',
      riderId: data['riderId']?.toString() ?? '',
      startTime: start,
      endTime: end,
      active: data['active'] == true,
      ordersCompleted: (data['ordersCompleted'] is num)
          ? (data['ordersCompleted'] as num).toInt()
          : (int.tryParse(data['ordersCompleted']?.toString() ?? '0') ?? 0),
      earnings: (data['earnings'] is num)
          ? (data['earnings'] as num).toDouble()
          : (double.tryParse(data['earnings']?.toString() ?? '0') ?? 0.0),
      durationMinutes: dur > 0 ? dur : 0,
      startLocation: data['startLocation'] is GeoPoint ? data['startLocation'] as GeoPoint : null,
      endLocation: data['endLocation'] is GeoPoint ? data['endLocation'] as GeoPoint : null,
    );
  }
}
