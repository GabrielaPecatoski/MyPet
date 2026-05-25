import 'package:flutter/material.dart';
import '../repositories/payment_repository.dart';

enum PagamentoStatus { idle, loading, success, error }

class PagamentoProvider extends ChangeNotifier {
  final IPaymentRepository _repository;

  PagamentoProvider(this._repository);

  PagamentoStatus _status = PagamentoStatus.idle;
  Map<String, dynamic>? paymentResult;
  String? errorMessage;

  PagamentoStatus get status => _status;
  bool get isLoading => _status == PagamentoStatus.loading;

  Future<void> confirmar({
    required String userId,
    required double amount,
    required String method,
    required String deliveryMethod,
    String? deliveryAddress,
    String? cardNumber,
    int? installments,
  }) async {
    _status = PagamentoStatus.loading;
    paymentResult = null;
    errorMessage = null;
    notifyListeners();

    try {
      final orderId = await _repository.createOrder(userId);
      final result = await _repository.processPayment({
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'method': method,
        'deliveryMethod': deliveryMethod,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        if (cardNumber != null) 'cardNumber': cardNumber,
        if (installments != null) 'installments': installments,
      });
      paymentResult = result;
      _status = PagamentoStatus.success;
    } catch (_) {
      errorMessage = 'Erro ao processar pedido. Tente novamente.';
      _status = PagamentoStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = PagamentoStatus.idle;
    paymentResult = null;
    errorMessage = null;
    notifyListeners();
  }
}
