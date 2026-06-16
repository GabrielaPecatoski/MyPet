import 'package:flutter/material.dart';
import '../core/colors.dart';

class VetPacientesScreen extends StatefulWidget {
  const VetPacientesScreen({super.key});

  @override
  State<VetPacientesScreen> createState() => _VetPacientesScreenState();
}

class _VetPacientesScreenState extends State<VetPacientesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _statsBar(),
            _searchBar(),
            const Expanded(child: _EmptyState()),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_outlined,
                  color: AppColors.vet, size: 20),
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
                Text('Pacientes',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark)),
              ],
            ),
          ],
        ),
      );

  Widget _statsBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('0', 'Total'),
              _divider(),
              _stat('0', 'Ativos'),
              _divider(),
              _stat('0', 'Novos'),
            ],
          ),
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.dark)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      );

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.greyLight);

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.dark),
                  decoration: const InputDecoration(
                    hintText: 'Buscar paciente ou tutor',
                    hintStyle:
                        TextStyle(color: AppColors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 56, color: AppColors.greyLight),
            SizedBox(height: 16),
            Text('Nenhum paciente ainda',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.dark)),
            SizedBox(height: 6),
            Text(
              'Atendidos recentemente aparecerão aqui.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
