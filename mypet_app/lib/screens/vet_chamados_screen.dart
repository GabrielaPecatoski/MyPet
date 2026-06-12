import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/emergency_call.dart';
import '../providers/auth_provider.dart';
import '../providers/vet_profile_provider.dart';

class VetChamadosScreen extends StatelessWidget {
  const VetChamadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VetProfileProvider>();
    final calls = vm.pendingCalls;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emergency_outlined,
                        color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MY PET · VETERINÁRIO',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey,
                              letterSpacing: 0.8)),
                      Text('Chamados de emergência',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: calls.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_outlined,
                                size: 56, color: AppColors.greyLight),
                            SizedBox(height: 16),
                            Text('Nenhum chamado ativo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.dark)),
                            SizedBox(height: 6),
                            Text(
                              'Quando surgir um chamado de emergência próximo, ele aparecerá aqui.',
                              style:
                                  TextStyle(fontSize: 13, color: AppColors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: calls.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _ChamadoCard(call: calls[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChamadoCard extends StatelessWidget {
  final EmergencyCallModel call;
  const _ChamadoCard({required this.call});

  String get _hora {
    final d = call.createdAt.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolver(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    await context
        .read<VetProfileProvider>()
        .acknowledgeCall(token: auth.token!, callId: call.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chamado de ${call.callerName} resolvido.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(call.callerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.dark)),
              ),
              Text(_hora,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 15, color: AppColors.grey),
              const SizedBox(width: 6),
              Text(call.callerPhone,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.dark)),
            ],
          ),
          if (call.petDescription != null &&
              call.petDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.pets, size: 15, color: AppColors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(call.petDescription!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.dark)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _resolver(context),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Marcar como resolvido'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
