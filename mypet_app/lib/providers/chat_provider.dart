import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  io.Socket? _socket;
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  String? _currentConversationId;
  bool _isTyping = false;
  String? _typingUserId;
  bool _connected = false;
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _totalMessages = 0;
  DateTime? _lastTypingSent;
  String? _error;

  // userId → online status (populated via partnerStatus events)
  final Map<String, bool> _partnerOnline = {};

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  String? get currentConversationId => _currentConversationId;
  bool get isTyping => _isTyping;
  String? get typingUserId => _typingUserId;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get isConnected => _connected;
  String? get error => _error;

  bool isPartnerOnline(String userId) => _partnerOnline[userId] ?? false;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateAuth(String? token) {
    if (token != null && _socket == null) {
      connect(token);
    } else if (token == null && _socket != null) {
      disconnect();
    }
  }

  void connect(String token) {
    _socket?.disconnect();
    _socket = io.io(
      '${ApiConstants.baseUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    _socket!.on('connect', (_) {
      _connected = true;
      // Status anterior pode estar desatualizado; limpa até receber novos eventos
      _partnerOnline.clear();
      notifyListeners();
      if (_currentConversationId != null) {
        _socket?.emit('joinRoom', {'conversationId': _currentConversationId});
      }
    });

    _socket!.on('disconnect', (_) {
      _connected = false;
      notifyListeners();
    });

    _socket!.on('newMessage', (data) {
      final msg = MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
      if (msg.conversationId == _currentConversationId) {
        _messages = [..._messages, msg];
        notifyListeners();
      }
      _updateConversationLastMessage(msg, isNew: msg.conversationId != _currentConversationId);
    });

    _socket!.on('history', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final list = (map['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _totalMessages = (map['total'] as num?)?.toInt() ?? list.length;
      _currentPage = 1;
      _hasMore = list.length < _totalMessages;
      _messages = list;
      _loadingMessages = false;
      notifyListeners();
      if (_currentConversationId != null) {
        _socket?.emit('markRead', {'conversationId': _currentConversationId});
      }
    });

    _socket!.on('messagesRead', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final readerId = map['readerId'] as String?;
      final readAtStr = map['readAt'] as String?;
      final readAt = readAtStr != null ? DateTime.tryParse(readAtStr) : null;
      if (readerId != null && readAt != null) {
        _messages = _messages.map((m) {
          // Mark messages sent by the current user (not by the reader) as read
          if (m.senderId != readerId && !m.isRead) {
            return m.copyWith(readAt: readAt);
          }
          return m;
        }).toList();
      }
      notifyListeners();
    });

    _socket!.on('userTyping', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      _typingUserId = map['userId'] as String?;
      _isTyping = true;
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        _isTyping = false;
        _typingUserId = null;
        notifyListeners();
      });
    });

    _socket!.on('partnerStatus', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final userId = map['userId'] as String?;
      final online = map['online'] as bool? ?? false;
      if (userId != null) {
        _partnerOnline[userId] = online;
        notifyListeners();
      }
    });

    _socket!.on('error', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      _error = map['message'] as String? ?? 'Erro desconhecido';
      notifyListeners();
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _messages = [];
    _currentConversationId = null;
    _isTyping = false;
    _partnerOnline.clear();
    notifyListeners();
  }

  Future<void> loadConversations(String token) async {
    _loadingConversations = true;
    notifyListeners();
    try {
      final list = await ChatRepository.listMine(token: token);
      // Sort by most recent last message
      list.sort((a, b) {
        final ta = a.lastMessageAt ?? a.createdAt;
        final tb = b.lastMessageAt ?? b.createdAt;
        return tb.compareTo(ta);
      });
      _conversations = list;
    } catch (e) {
      debugPrint('loadConversations error: $e');
    }
    _loadingConversations = false;
    notifyListeners();
  }

  void joinRoom(String conversationId) {
    _currentConversationId = conversationId;
    _messages = [];
    _loadingMessages = true;
    _hasMore = false;
    _currentPage = 1;
    notifyListeners();
    _socket?.emit('joinRoom', {'conversationId': conversationId});
    // Reset unread count for this conversation
    _resetUnread(conversationId);
  }

  void leaveRoom() {
    if (_currentConversationId != null) {
      _socket?.emit('leaveRoom', {'conversationId': _currentConversationId});
    }
    _currentConversationId = null;
    _messages = [];
    _hasMore = false;
    notifyListeners();
  }

  Future<void> loadMoreMessages(String conversationId, String token) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final nextPage = _currentPage + 1;
      final data = await ApiService.get(
        '/conversations/$conversationId/messages?page=$nextPage&limit=50',
        token: token,
      );
      final map = data as Map<String, dynamic>;
      final list = (map['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _currentPage = nextPage;
      _messages = [...list, ..._messages];
      _hasMore = _messages.length < _totalMessages;
    } catch (e) {
      debugPrint('loadMoreMessages error: $e');
    }
    _loadingMore = false;
    notifyListeners();
  }

  void sendMessage(String conversationId, String content) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void markRead(String conversationId) {
    _socket?.emit('markRead', {'conversationId': conversationId});
  }

  void sendTyping(String conversationId) {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!).inMilliseconds < 1000) {
      return;
    }
    _lastTypingSent = now;
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  Future<ConversationModel> openOrCreateConversation({
    required String bookingId,
    required String clientId,
    required String establishmentId,
    String? clientName,
    String? establishmentName,
    required String token,
  }) async {
    final conv = await ChatRepository.getOrCreate(
      bookingId: bookingId,
      clientId: clientId,
      establishmentId: establishmentId,
      clientName: clientName,
      establishmentName: establishmentName,
      token: token,
    );
    if (!_conversations.any((c) => c.id == conv.id)) {
      _conversations = [conv, ..._conversations];
      notifyListeners();
    }
    return conv;
  }

  void _resetUnread(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1 || _conversations[idx].unreadCount == 0) return;
    _conversations = List.from(_conversations)
      ..[idx] = _conversations[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void _updateConversationLastMessage(MessageModel msg, {bool isNew = false}) {
    final idx = _conversations.indexWhere((c) => c.id == msg.conversationId);
    if (idx == -1) return;
    final old = _conversations[idx];
    final newUnread = isNew ? old.unreadCount + 1 : old.unreadCount;
    _conversations = List.from(_conversations)
      ..[idx] = old.copyWith(
        lastMessageAt: msg.createdAt,
        lastMessage: msg,
        unreadCount: newUnread,
      );
    // Re-sort so most recent conversation floats to top
    _conversations.sort((a, b) {
      final ta = a.lastMessageAt ?? a.createdAt;
      final tb = b.lastMessageAt ?? b.createdAt;
      return tb.compareTo(ta);
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
