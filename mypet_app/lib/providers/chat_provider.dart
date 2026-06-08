import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

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
  DateTime? _lastTypingSent;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  String? get currentConversationId => _currentConversationId;
  bool get isTyping => _isTyping;
  String? get typingUserId => _typingUserId;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  bool get isConnected => _connected;

  void updateAuth(String? token) {
    if (token != null && !_connected) {
      connect(token);
    } else if (token == null && _connected) {
      disconnect();
    }
  }

  void connect(String token) {
    _socket?.disconnect();
    _connected = true;
    _socket = io.io(
      '${ApiConstants.baseUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('newMessage', (data) {
      final msg = MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
      if (msg.conversationId == _currentConversationId) {
        _messages = [..._messages, msg];
        notifyListeners();
      }
      _updateConversationLastMessage(msg);
    });

    _socket!.on('history', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final list = (map['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _messages = list;
      _loadingMessages = false;
      notifyListeners();
    });

    _socket!.on('messagesRead', (_) {
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

    _socket!.on('error', (data) {
      debugPrint('Chat WS error: $data');
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
    _messages = [];
    _currentConversationId = null;
    _isTyping = false;
    notifyListeners();
  }

  Future<void> loadConversations(String token) async {
    _loadingConversations = true;
    notifyListeners();
    try {
      _conversations = await ChatRepository.listMine(token: token);
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
    notifyListeners();
    _socket?.emit('joinRoom', {'conversationId': conversationId});
  }

  void leaveRoom() {
    _currentConversationId = null;
    _messages = [];
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
    required String token,
  }) async {
    final conv = await ChatRepository.getOrCreate(
      bookingId: bookingId,
      clientId: clientId,
      establishmentId: establishmentId,
      token: token,
    );
    if (!_conversations.any((c) => c.id == conv.id)) {
      _conversations = [conv, ..._conversations];
      notifyListeners();
    }
    return conv;
  }

  void _updateConversationLastMessage(MessageModel msg) {
    final idx = _conversations.indexWhere((c) => c.id == msg.conversationId);
    if (idx == -1) return;
    final old = _conversations[idx];
    _conversations = List.from(_conversations)..[idx] = ConversationModel(
      id: old.id,
      bookingId: old.bookingId,
      clientId: old.clientId,
      establishmentId: old.establishmentId,
      lastMessageAt: msg.createdAt,
      createdAt: old.createdAt,
      lastMessage: msg,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
