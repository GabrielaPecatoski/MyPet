import '../models/conversation_model.dart';
import '../services/api_service.dart';

class ChatRepository {
  static Future<ConversationModel> getOrCreate({
    required String bookingId,
    required String clientId,
    required String establishmentId,
    required String token,
  }) async {
    final data = await ApiService.post(
      '/conversations',
      {
        'bookingId': bookingId,
        'clientId': clientId,
        'establishmentId': establishmentId,
      },
      token: token,
    );
    final json = data as Map<String, dynamic>;
    return ConversationModel.fromJson(
        json['conversation'] as Map<String, dynamic>);
  }

  static Future<List<ConversationModel>> listMine({
    required String token,
  }) async {
    final data = await ApiService.get('/conversations/me', token: token);
    final list = data as List<dynamic>;
    return list
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
