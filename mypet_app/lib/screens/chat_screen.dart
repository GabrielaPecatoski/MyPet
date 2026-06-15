import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  ConversationModel? _conv;
  String? _userId;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    _scrollCtrl.addListener(_onScroll);
  }

  void _init() {
    _conv = ModalRoute.of(context)?.settings.arguments as ConversationModel?;
    if (_conv == null) return;
    _userId = context.read<AuthProvider>().user?.id;
    context.read<ChatProvider>().joinRoom(_conv!.id);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 80 && !context.read<ChatProvider>().loadingMore) {
      final token = context.read<AuthProvider>().token;
      if (token != null && _conv != null) {
        context.read<ChatProvider>().loadMoreMessages(_conv!.id, token);
      }
    }
  }

  @override
  void dispose() {
    context.read<ChatProvider>().leaveRoom();
    _ctrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _conv == null) return;
    context.read<ChatProvider>().sendMessage(_conv!.id, text);
    _ctrl.clear();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animated) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final messages = chat.messages;

    // Show error snackbar when chat emits an error
    if (chat.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chat.error!),
            backgroundColor: AppColors.danger,
          ),
        );
        chat.clearError();
      });
    }

    // Scroll to bottom only when new messages arrive
    if (messages.length > _prevMessageCount) {
      _prevMessageCount = messages.length;
      _scrollToBottom(animated: _prevMessageCount == messages.length);
    }

    final partnerId = _conv != null
        ? (_conv!.clientId == (_userId ?? '') ? _conv!.establishmentId : _conv!.clientId)
        : null;
    final partnerOnline = partnerId != null ? chat.isPartnerOnline(partnerId) : false;
    final partnerName = _conv != null
        ? _conv!.partnerName(auth.user?.id ?? '')
        : 'Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.pets, color: AppColors.primary, size: 18),
                ),
                if (partnerId != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: partnerOnline ? AppColors.success : AppColors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  partnerName.isNotEmpty ? partnerName : 'Chat',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  partnerOnline ? 'online' : 'offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: partnerOnline ? AppColors.success : AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (chat.loadingMore)
            const LinearProgressIndicator(
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
              minHeight: 2,
            ),
          Expanded(
            child: chat.loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma mensagem ainda.\nInicie a conversa!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          final isMine = msg.senderId == _userId;
                          final showDateSep = i == 0 ||
                              !_sameDay(messages[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDateSep) _DateSeparator(date: msg.createdAt),
                              _MessageBubble(
                                msg: msg,
                                isMine: isMine,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (chat.isTyping)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.grey),
                  ),
                  SizedBox(width: 6),
                  Text('digitando...',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: (_conv != null)
                  ? (_) => chat.sendTyping(_conv!.id)
                  : null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                hintStyle:
                    const TextStyle(fontSize: 14, color: AppColors.grey),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) {
      label = 'Hoje';
    } else if (diff == 1) {
      label = 'Ontem';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.greyLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.greyLight)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMine;

  const _MessageBubble({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time = msg.createdAt;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.grey,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: msg.isRead
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
