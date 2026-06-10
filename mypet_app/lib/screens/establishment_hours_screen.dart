import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_hours_provider.dart';
import '../providers/establishment_provider.dart';
import '../repositories/establishment_hours_repository.dart';
import '../widgets/mypet_app_bar.dart';

class EstabHorariosScreen extends StatelessWidget {
  const EstabHorariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentHoursProvider(EstablishmentHoursRepository()),
      child: const _EstabHorariosView(),
    );
  }
}

class _EstabHorariosView extends StatefulWidget {
  const _EstabHorariosView();

  @override
  State<_EstabHorariosView> createState() => _EstabHorariosViewState();
}

class _EstabHorariosViewState extends State<_EstabHorariosView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1) {
        context.read<EstablishmentHoursProvider>().loadSlots();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EstablishmentHoursProvider>();
      provider.configure(
        estabId: context.read<EstablishmentProvider>().establishmentId,
        token: context.read<AuthProvider>().token,
      );
      provider.loadSchedule();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    final error =
        await context.read<EstablishmentHoursProvider>().saveSchedule();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Horários salvos com sucesso!'),
      backgroundColor: error == null ? AppColors.success : AppColors.danger,
    ));
  }

  Future<void> _toggleSlot(TimeSlotModel slot) async {
    final result =
        await context.read<EstablishmentHoursProvider>().toggleSlot(slot);
    if (!mounted) return;
    if (result.acted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.wasBlock ? 'Horário bloqueado!' : 'Horário liberado!'),
        backgroundColor: result.wasBlock ? AppColors.warning : AppColors.success,
      ));
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage!),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  String _formatDateDisplay(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${d.day} de ${months[d.month - 1]}';
  }

  Future<void> _pickTime(BuildContext context, String current,
      void Function(String) onPicked) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.estab,
              labelColor: AppColors.estab,
              unselectedLabelColor: AppColors.grey,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Horários'),
                Tab(text: 'Bloquear'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildScheduleTab(),
                _buildBlockTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final provider = context.watch<EstablishmentHoursProvider>();
    if (provider.loadingSchedule) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.estab));
    }
    final schedule = provider.schedule;
    if (schedule == null) {
      return Center(
        child: ElevatedButton(
          onPressed: provider.loadSchedule,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Duração de cada atendimento',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.dark)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [30, 45, 60, 90, 120].map((min) {
                  final selected = provider.slotDuration == min;
                  return GestureDetector(
                    onTap: () => provider.setSlotDuration(min),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.estab
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        min >= 60
                            ? '${min ~/ 60}h${min % 60 > 0 ? '${min % 60}m' : ''}'
                            : '${min}min',
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.estab,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Atendimentos simultâneos por horário',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.dark)),
              const SizedBox(height: 4),
              const Text(
                'Quantos clientes podem agendar no mesmo horário',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5].map((n) {
                  final selected = provider.capacity == n;
                  return GestureDetector(
                    onTap: () => provider.setCapacity(n),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.estab : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$n',
                          style: TextStyle(
                              color: selected ? Colors.white : AppColors.estab,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text('Dias e horários de funcionamento',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.dark)),
        const SizedBox(height: 10),

        ...List.generate(schedule.days.length, (i) {
          final day = schedule.days[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(_dayLabels[day.dayOfWeek],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.dark)),
                      const SizedBox(height: 4),
                      Switch(
                        value: day.isOpen,
                        onChanged: (v) =>
                            provider.updateDay(i, day.copyWith(isOpen: v)),
                        activeThumbColor: AppColors.estab,
                        activeTrackColor: AppColors.primaryLight,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (day.isOpen) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(
                          context, day.startTime,
                          (t) => provider.updateDay(i, day.copyWith(startTime: t))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(day.startTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.estab)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('até',
                        style:
                            TextStyle(color: AppColors.grey, fontSize: 12)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(
                          context, day.endTime,
                          (t) => provider.updateDay(i, day.copyWith(endTime: t))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(day.endTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.estab)),
                      ),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Text('Fechado',
                        style: TextStyle(
                            color: AppColors.grey, fontSize: 13)),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.savingSchedule ? null : _saveSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.estab,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: provider.savingSchedule
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Salvar Horários',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBlockTab() {
    final provider = context.watch<EstablishmentHoursProvider>();
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: AppColors.estab),
              const SizedBox(width: 8),
              Text(_formatDateDisplay(provider.selectedDay),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.dark)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedDay,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppColors.estab),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    await provider.setSelectedDay(picked);
                  }
                },
                icon: const Icon(Icons.edit_calendar,
                    size: 16, color: AppColors.estab),
                label: const Text('Mudar',
                    style: TextStyle(color: AppColors.estab)),
              ),
              ElevatedButton.icon(
                onPressed: provider.loadSlots,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.estab,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _legend(AppColors.success, 'Disponível'),
              const SizedBox(width: 16),
              _legend(AppColors.warning, 'Bloqueado'),
              const SizedBox(width: 16),
              _legend(AppColors.grey, 'Agendamento'),
            ],
          ),
        ),

        Expanded(
          child: provider.loadingSlots
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.estab))
              : provider.slots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.block,
                              size: 48, color: AppColors.greyLight),
                          const SizedBox(height: 12),
                          const Text('Estabelecimento fechado neste dia',
                              style: TextStyle(
                                  color: AppColors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _tabCtrl.animateTo(0),
                            child: const Text(
                                'Configurar horários na aba "Horários"'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: provider.slots.length,
                      itemBuilder: (_, i) {
                        final slot = provider.slots[i];
                        final hasBooking = slot.bookingId != null;
                        final isBlocked =
                            !slot.available && slot.blockId != null;
                        final isAvailable = slot.available;

                        Color bg;
                        Color textColor;
                        if (isAvailable) {
                          bg = AppColors.success.withValues(alpha: 0.1);
                          textColor = AppColors.success;
                        } else if (isBlocked) {
                          bg = AppColors.warning.withValues(alpha: 0.12);
                          textColor = AppColors.warning;
                        } else {
                          bg = AppColors.greyLight;
                          textColor = AppColors.grey;
                        }

                        return GestureDetector(
                          onTap: hasBooking ? null : () => _toggleSlot(slot),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isAvailable
                                    ? AppColors.success
                                    : isBlocked
                                        ? AppColors.warning
                                        : AppColors.greyLight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(slot.time,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: textColor)),
                                if (!isAvailable)
                                  Text(
                                    hasBooking ? 'Agendado' : 'Bloqueado',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color:
                                            textColor.withValues(alpha: 0.8)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      );
}
