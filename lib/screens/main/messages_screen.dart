import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../components/common/rider_header.dart';
import '../../models/chat_model.dart';
import '../../services/rider_api_service.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RiderHeader(
        title: 'Messages',
        showAvatar: true,
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: RiderApiService.streamConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.gray.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No Conversations Yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chats with customers and support will appear here.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final isSupport = conv.participantId == 'support_admin';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isSupport ? AppColors.secondary : AppColors.primary,
                  child: isSupport
                      ? const Icon(Icons.headset_mic, color: AppColors.white)
                      : Text(
                          conv.participantName.isNotEmpty ? conv.participantName[0].toUpperCase() : 'C',
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              conv.participantName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conv.orderId != null && conv.orderId!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${conv.orderId}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (conv.lastMessageTime != null)
                      Text(
                        _formatTime(conv.lastMessageTime!),
                        style: const TextStyle(fontSize: 11, color: AppColors.gray),
                      ),
                  ],
                ),
                subtitle: Text(
                  conv.lastMessage.isNotEmpty ? conv.lastMessage : 'Start conversation',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'conversationId': conv.id,
                      'title': conv.participantName,
                      'participantId': conv.participantId,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      return '${d.month}/${d.day}';
    } catch (_) {
      return '';
    }
  }
}
