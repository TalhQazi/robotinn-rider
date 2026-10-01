import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../components/common/rider_header.dart';
import '../../models/chat_model.dart';
import '../../services/rider_api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final list = await RiderApiService.getConversations();
      if (mounted) setState(() => _conversations = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RiderHeader(
        title: 'Messages',
        showAvatar: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadConversations(),
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _conversations.isEmpty
                ? ListView(
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
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final isSupport = conv.participantId == 'support_admin';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: isSupport ? AppColors.secondary : AppColors.primary,
                          child: Icon(
                            isSupport ? Icons.headset_mic : Icons.person,
                            color: AppColors.white,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              conv.participantName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
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
                          ).then((_) => _loadConversations());
                        },
                      );
                    },
                  ),
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
