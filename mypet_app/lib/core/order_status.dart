import 'package:flutter/material.dart';
import 'colors.dart';

class OrderTracking {
  static const flow = ['AGUARDANDO_PAGAMENTO', 'ENVIANDO', 'A_CAMINHO', 'FINALIZADO'];

  static int indexOf(String status) => flow.indexOf(status);

  static bool isCancelled(String status) => status == 'CANCELLED';

  static String label(String status, {bool pickup = false}) {
    switch (status) {
      case 'AGUARDANDO_PAGAMENTO':
        return 'Aguardando pagamento';
      case 'ENVIANDO':
        return pickup ? 'Preparando' : 'Enviando já';
      case 'A_CAMINHO':
        return pickup ? 'Pronto p/ retirada' : 'Indo até o endereço';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case 'AGUARDANDO_PAGAMENTO':
        return AppColors.warning;
      case 'ENVIANDO':
        return const Color(0xFF6366F1);
      case 'A_CAMINHO':
        return AppColors.primary;
      case 'FINALIZADO':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.grey;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case 'AGUARDANDO_PAGAMENTO':
        return Icons.hourglass_empty;
      case 'ENVIANDO':
        return Icons.inventory_2_outlined;
      case 'A_CAMINHO':
        return Icons.local_shipping_outlined;
      case 'FINALIZADO':
        return Icons.verified_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static List<String> stepLabels({bool pickup = false}) =>
      flow.map((s) => label(s, pickup: pickup)).toList();

  static String? nextActionLabel(String status, {bool pickup = false}) {
    switch (status) {
      case 'ENVIANDO':
        return pickup ? 'Marcar como pronto' : 'Saiu para entrega';
      case 'A_CAMINHO':
        return 'Finalizar pedido';
      default:
        return null;
    }
  }
}
