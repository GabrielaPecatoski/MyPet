import '../models/faq.dart';
import 'api_service.dart';

class FaqService {
  static Future<List<FaqItem>> getFaqs({String? category}) async {
    final path = category != null
        ? '/faq?category=${Uri.encodeComponent(category)}'
        : '/faq';
    final data = await ApiService.get(path);
    return (data as List).map((e) => FaqItem.fromJson(e)).toList();
  }

  static Future<List<String>> getCategories() async {
    final data = await ApiService.get('/faq/categories');
    return (data as List).map((e) => e.toString()).toList();
  }

  static Future<UserQuestion> submitQuestion({
    required String userId,
    required String userName,
    required String userRole,
    required String question,
    String? token,
  }) async {
    final data = await ApiService.post(
      '/faq/questions',
      {
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'question': question,
      },
      token: token,
    );
    return UserQuestion.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<UserQuestion>> getUserQuestions(
    String userId, {
    String? token,
  }) async {
    final data = await ApiService.get(
      '/faq/questions/user/$userId',
      token: token,
    );
    return (data as List).map((e) => UserQuestion.fromJson(e)).toList();
  }
}
