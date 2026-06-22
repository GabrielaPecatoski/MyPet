import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/attendance_photos.dart';
import '../widgets/mypet_app_bar.dart';

/// Tela de detalhes de um agendamento (lado do cliente).
/// Recebe um [AppointmentModel] via `Navigator.pushNamed` arguments.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];

  String _formatDate(DateTime d) =>
      '${d.day} de ${_months[d.month - 1]} de ${d.year}';

  Color _statusColor(AppointmentModel ap) {
    switch (ap.status) {
      case 'AGUARDANDO_PAGAMENTO': return AppColors.primary;
      case 'CONFIRMADO':           return AppColors.success;
      case 'PENDENTE':             return AppColors.warning;
      case 'CANCELADO':
      case 'RECUSADO':             return AppColors.danger;
      case 'CONCLUIDO':            return AppColors.grey;
      default:                     return AppColors.grey;
    }
  }

  Future<void> _cancel(BuildContext context, AppointmentModel ap) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar agendamento?'),
        content: Text('Deseja cancelar ${ap.serviceName} com ${ap.petName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final ok = await booking.cancelBooking(token: auth.token!, bookingId: ap.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Agendamento cancelado' : (booking.error ?? 'Erro')),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
    if (ok) Navigator.pop(context);
  }

  Future<void> _openChat(BuildContext context, AppointmentModel ap) async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    if (auth.token == null) return;
    try {
      final conv = await chat.openOrCreateConversation(
        bookingId: ap.id,
        clientId: auth.user?.id ?? ap.userId,
        clientName: auth.user?.name ?? ap.userName,
        establishmentId: ap.establishmentId,
        establishmentName: ap.establishmentName,
        token: auth.token!,
      );
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/chat', arguments: conv);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível abrir o chat'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap =
        ModalRoute.of(context)!.settings.arguments as AppointmentModel;
    final color = _statusColor(ap);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Cabeçalho: pet + status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: appImageProvider(ap.petPhotoUrl),
                  child: (ap.petPhotoUrl == null || ap.petPhotoUrl!.isEmpty)
                      ? const Icon(Icons.pets, color: AppColors.primary, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ap.petName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.dark)),
                      if (ap.petBreed.isNotEmpty)
                        Text(
                          '${ap.petBreed}${ap.petAge > 0 ? ' • ${ap.petAge} anos' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(ap.statusLabel,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detalhes do serviço
          _section('Serviço', [
            _row(Icons.content_cut_outlined, ap.serviceName),
            _row(Icons.location_on_outlined, ap.establishmentName),
            if (ap.establishmentAddress.isNotEmpty)
              _row(Icons.map_outlined, ap.establishmentAddress),
            _row(Icons.calendar_today_outlined, _formatDate(ap.date)),
            _row(Icons.access_time_outlined, ap.time),
          ]),
          const SizedBox(height: 16),

          // Pagamento
          _section('Pagamento', [
            _row(
              Icons.attach_money,
              ap.priceVariable
                  ? 'Sob consulta'
                  : 'R\$ ${ap.price.toStringAsFixed(2)}',
            ),
            if (ap.pagamentoLabel != null)
              _row(Icons.receipt_long_outlined, ap.pagamentoLabel!),
            if (ap.isRetido && (ap.isPendente || ap.isConfirmado))
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'O valor está retido e só será repassado ao estabelecimento após a conclusão do serviço.',
                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ),
          ]),

          // Transporte / motorista
          if (ap.driverName != null && ap.driverName!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section('Transporte', [
              Row(
                children: [
                  PhotoBox(
                    url: ap.driverPhotoUrl,
                    size: 42,
                    radius: 21,
                    background: AppColors.primaryLight,
                    fallback: const Icon(Icons.local_shipping_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Motorista do transporte',
                            style: TextStyle(fontSize: 11, color: AppColors.grey)),
                        Text(ap.driverName!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark)),
                      ],
                    ),
                  ),
                ],
              ),
            ]),
          ],

          // Fotos do atendimento
          if (ap.attendancePhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section('Fotos do atendimento (${ap.attendancePhotos.length})', [
              AttendancePhotosGrid(photos: ap.attendancePhotos),
            ]),
          ],

          const SizedBox(height: 24),

          // Ações
          if (ap.isAguardandoPagamento)
            _primaryButton(
              context,
              icon: Icons.payment,
              label: 'Pagar Agora',
              onTap: () => Navigator.pushNamed(
                  context, '/pagamento-agendamento', arguments: ap),
            ),
          if (ap.isConfirmado) ...[
            _primaryButton(
              context,
              icon: Icons.location_on_outlined,
              label: 'Acompanhar serviço',
              onTap: () =>
                  Navigator.pushNamed(context, '/tracking', arguments: ap),
            ),
            const SizedBox(height: 10),
            _outlinedButton(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'Mensagem',
              onTap: () => _openChat(context, ap),
            ),
          ],
          if (ap.canCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancel(context, ap),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar agendamento',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 14, color: AppColors.dark))),
          ],
        ),
      );

  Widget _primaryButton(BuildContext context,
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  Widget _outlinedButton(BuildContext context,
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: AppColors.primary),
          label: Text(label, style: const TextStyle(color: AppColors.primary)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
}
