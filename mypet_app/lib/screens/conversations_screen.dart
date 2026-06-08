import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/conversation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/mypet_app_bar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<ChatProvider>().loadConversations(token);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: chat.loadingConversations
            ? const Center(child: CircularProgressIndicator())
            : chat.conversations.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    itemCount: chat.conversations.length,
                    itemBuilder: (ctx, i) =>
                        _ConversationTile(conv: chat.conversations[i]),
                  ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 56, color: AppColors.greyLight),
                SizedBox(height: 12),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(fontSize: 16, color: AppColors.grey),
                ),
                SizedBox(height: 6),
                Text(
                  'Inicie uma conversa a partir de um agendamento confirmado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.greyLight),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final last = conv.lastMessage;
    final timeStr = conv.lastMessageAt != null
        ? _formatTime(conv.lastMessageAt!)
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      tileColor: Colors.white,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        child:
            const Icon(Icons.pets, color: AppColors.primary, size: 24),
      ),
      title: Text(
        'Agendamento • ${conv.bookingId.substring(0, 8)}',
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.dark),
      ),
      subtitle: Text(
        last?.content ?? 'Sem mensagens',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.grey),
      ),
      trailing: Text(
        timeStr,
        style: const TextStyle(fontSize: 11, color: AppColors.grey),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        '/chat',
        arguments: conv,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
