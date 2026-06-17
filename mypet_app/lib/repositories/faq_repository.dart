import '../models/faq.dart';
import '../services/faq_service.dart';

abstract class IFaqRepository {
  Future<List<String>> categories();
  Future<List<FaqItem>> faqs();
  Future<List<UserQuestion>> userQuestions(String userId, {String? token});
  Future<UserQuestion?> submit({required String question, String? token});
}

class FaqRepository implements IFaqRepository {
  @override
  Future<List<String>> categories() => FaqService.getCategories();

  @override
  Future<List<FaqItem>> faqs() => FaqService.getFaqs();

  @override
  Future<List<UserQuestion>> userQuestions(String userId, {String? token}) =>
      FaqService.getUserQuestions(userId, token: token);

  @override
  Future<UserQuestion?> submit({required String question, String? token}) =>
      FaqService.submitQuestion(question: question, token: token);
}
