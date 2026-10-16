import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../models/chat_model.dart';
import '../../services/rider_api_service.dart';
import '../../components/order/bill_image_preview_modal.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String participantId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    required this.participantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;
  late String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _resolveCustomerName();
  }

  void _resolveCustomerName() async {
    if (_title == 'Customer' || _title.isEmpty || _title == 'Chat') {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.participantId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final uName = userDoc.data()!['name']?.toString() ?? userDoc.data()!['displayName']?.toString();
          if (uName != null && uName.trim().isNotEmpty && uName.trim() != 'Customer') {
            if (mounted) setState(() => _title = uName.trim());
            return;
          }
        }

        final oSnap = await FirebaseFirestore.instance.collection('orders')
            .where('customer.id', isEqualTo: widget.participantId)
            .limit(1)
            .get();
        if (oSnap.docs.isNotEmpty) {
          final od = oSnap.docs.first.data();
          final cName = od['customer']?['name']?.toString() ?? od['customerName']?.toString();
          if (cName != null && cName.trim().isNotEmpty && cName.trim() != 'Customer') {
            if (mounted) setState(() => _title = cName.trim());
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    try {
      await RiderApiService.sendMessage(widget.conversationId, text);
      _scrollToBottom();
    } catch (_) {}
  }

  void _handleSendPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _isSending = true);
      try {
        await RiderApiService.sendMediaMessage(widget.conversationId, File(picked.path));
        _scrollToBottom();
      } catch (_) {}
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: RiderApiService.subscribeMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 48, color: AppColors.gray.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        const Text('Say hello to start the chat!', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUid;
                    return _chatBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                    onPressed: _isSending ? null : _handleSendPhoto,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14, color: AppColors.gray),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.white, size: 18),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => BillImagePreviewModal(imageUrl: msg.mediaUrl!),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BillImagePreviewModal.buildThumbnail(
                    msg.mediaUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (msg.text.isNotEmpty) const SizedBox(height: 6),
            ],
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? AppColors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
