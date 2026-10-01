class ConversationModel {
  final String id;
  final List<String> participants;
  final String participantId;
  final String participantName;
  final String lastMessage;
  final String? lastMessageTime;
  final String? orderId;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantId,
    required this.participantName,
    required this.lastMessage,
    this.lastMessageTime,
    this.orderId,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String currentUid, [String? id]) {
    final parts = (map['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final otherId = parts.firstWhere((p) => p != currentUid, orElse: () => 'support_admin');

    String lastMsg = '';
    String? lastTime;
    if (map['lastMessage'] is Map) {
      lastMsg = map['lastMessage']['text']?.toString() ?? '';
      lastTime = map['lastMessage']['createdAt']?.toString();
    } else if (map['lastMessage'] is String) {
      lastMsg = map['lastMessage'];
    }

    return ConversationModel(
      id: id ?? map['id']?.toString() ?? '',
      participants: parts,
      participantId: otherId,
      participantName: otherId == 'support_admin' ? 'RobotInn Support' : (map['participantName']?.toString() ?? 'Customer'),
      lastMessage: lastMsg,
      lastMessageTime: lastTime ?? map['createdAt']?.toString(),
      orderId: map['orderId']?.toString(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final String createdAt;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;
  final bool read;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
    this.read = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ChatMessageModel(
      id: id ?? map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      mediaUrl: map['mediaUrl']?.toString(),
      mediaType: map['mediaType']?.toString(),
      mediaName: map['mediaName']?.toString(),
      read: map['read'] == true || map['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'mediaName': mediaName,
      'read': read,
    };
  }
}
