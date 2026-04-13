import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../models/pet.dart';
import '../widgets/mypet_app_bar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  PetModel? _selectedPet;
  ServiceModel? _selectedService;
  DateTime? _selectedDate;

  final _mockPets = [
    PetModel(id: '1', name: 'Rex', type: 'Cachorro', breed: 'Golden Retriever', age: 3),
    PetModel(id: '2', name: 'Luna', type: 'Gato', breed: 'Siamês', age: 2),
  ];

  List<DateTime> get _availableDates {
    final now = DateTime.now();
    return List.generate(7, (i) => now.add(Duration(days: i + 1)));
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  void _confirmar() {
    if (_selectedPet == null || _selectedService == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o pet, serviço e data'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Agendamento Solicitado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Pet:', _selectedPet!.name),
            _confirmRow('Serviço:', _selectedService!.name),
            _confirmRow('Data:', _formatDate(_selectedDate!)),
            _confirmRow('Valor:', 'R\$ ${_selectedService!.price.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.grey)),
            const SizedBox(width: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.dark)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final establishment =
        ModalRoute.of(context)?.settings.arguments as EstablishmentModel?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selecionar pet
            _sectionTitle('Selecione o pet'),
            const SizedBox(height: 10),
            ...(_mockPets.map((pet) => _PetSelectCard(
                  pet: pet,
                  selected: _selectedPet?.id == pet.id,
                  onTap: () => setState(() => _selectedPet = pet),
                ))),

            const SizedBox(height: 20),

            // Selecionar serviço
            _sectionTitle('Selecione o serviço'),
            const SizedBox(height: 10),
            if (establishment != null)
              ...establishment.services.map((s) => _ServiceSelectCard(
                    service: s,
                    selected: _selectedService?.id == s.id,
                    onTap: () => setState(() => _selectedService = s),
                  )),

            const SizedBox(height: 20),

            // Selecionar data
            _sectionTitle('Selecione a data'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: _availableDates
                  .take(6)
                  .map((date) => _DateCard(
                        date: date,
                        label: _formatDate(date),
                        selected: _selectedDate == date,
                        onTap: () => setState(() => _selectedDate = date),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 28),

            // Botão confirmar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirmar Agendamento',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
      );
}

class _PetSelectCard extends StatelessWidget {
  final PetModel pet;
  final bool selected;
  final VoidCallback onTap;

  const _PetSelectCard(
      {required this.pet, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(pet.typeIcon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${pet.breed} • ${pet.age} anos',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ServiceSelectCard extends StatelessWidget {
  final ServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceSelectCard(
      {required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Duração: ${service.durationMinutes} min',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.grey)),
                ],
              ),
            ),
            Text(
              'R\$ ${service.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateCard(
      {required this.date,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today,
                size: 14, color: selected ? Colors.white : AppColors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
