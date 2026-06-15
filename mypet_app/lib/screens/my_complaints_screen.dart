import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaints_provider.dart';
import '../widgets/mypet_app_bar.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});
  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    await context.read<ComplaintsProvider>().load(token: auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComplaintsProvider>();
    final complaints = provider.complaints;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: complaints.isEmpty
                  ? _emptyState(provider.error)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: complaints.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              'Minhas Reclamações',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.dark),
                            ),
                          );
                        }
                        return _ComplaintCard(complaint: complaints[i - 1]);
                      },
                    ),
            ),
    );
  }

  Widget _emptyState(String? error) => ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.report_outlined,
                      size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  error ?? 'Nenhuma reclamação aberta',
                  style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Abra uma reclamação pelo seu histórico de serviços',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});

  Color get _statusColor {
    if (complaint.isResolvida) return AppColors.success;
    if (complaint.isRejeitada) return AppColors.danger;
    if (complaint.isEmAnalise) return AppColors.primary;
    return AppColors.warning;
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.dark),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  complaint.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor),
                ),
              ),
            ],
          ),
          if (complaint.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.label_outline,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(complaint.category,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            complaint.description,
            style: const TextStyle(fontSize: 13, color: AppColors.dark),
          ),
          if (complaint.response != null &&
              complaint.response!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Resposta da equipe',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(complaint.response!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.dark)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.grey),
              const SizedBox(width: 4),
              Text('Aberta em ${_date(complaint.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
