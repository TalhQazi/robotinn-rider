class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String createdAt;
  final bool read;
  final String type;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.type = 'system',
    this.data = const {},
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return NotificationModel(
      id: id ?? map['id']?.toString() ?? map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? map['body']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      read: map['read'] == true,
      type: map['type']?.toString() ?? 'system',
      data: (map['data'] is Map<String, dynamic>) ? map['data'] as Map<String, dynamic> : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt,
      'read': read,
      'type': type,
      'data': data,
    };
  }
}
