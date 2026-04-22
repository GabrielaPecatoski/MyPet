import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/availability_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabHorariosScreen extends StatefulWidget {
  const EstabHorariosScreen({super.key});

  @override
  State<EstabHorariosScreen> createState() => _EstabHorariosScreenState();
}

class _EstabHorariosScreenState extends State<EstabHorariosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  ScheduleModel? _schedule;
  bool _loadingSchedule = false;
  bool _savingSchedule = false;
  int _slotDuration = 60;

  // For "Bloquear" tab
  DateTime _selectedDay = DateTime.now();
  List<TimeSlotModel> _slots = [];
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1) _loadSlots();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedule());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String? get _estabId =>
      context.read<EstablishmentProvider>().establishmentId;

  String? get _token => context.read<AuthProvider>().token;

  ScheduleModel _defaultSchedule(String estabId) => ScheduleModel(
        establishmentId: estabId,
        slotDurationMinutes: 60,
        days: [
          const WorkingDayModel(dayOfWeek: 0, startTime: '08:00', endTime: '12:00', isOpen: false),
          const WorkingDayModel(dayOfWeek: 1, startTime: '08:00', endTime: '18:00', isOpen: true),
          const WorkingDayModel(dayOfWeek: 2, startTime: '08:00', endTime: '18:00', isOpen: true),
          const WorkingDayModel(dayOfWeek: 3, startTime: '08:00', endTime: '18:00', isOpen: true),
          const WorkingDayModel(dayOfWeek: 4, startTime: '08:00', endTime: '18:00', isOpen: true),
          const WorkingDayModel(dayOfWeek: 5, startTime: '08:00', endTime: '18:00', isOpen: true),
          const WorkingDayModel(dayOfWeek: 6, startTime: '08:00', endTime: '14:00', isOpen: true),
        ],
      );

  Future<void> _loadSchedule() async {
    final id = _estabId;
    final token = _token;
    setState(() => _loadingSchedule = true);
    try {
      if (id == null || token == null) throw Exception('não autenticado');
      final s = await AvailabilityService.getSchedule(token: token, estabId: id);
      setState(() {
        _schedule = s;
        _slotDuration = s.slotDurationMinutes;
      });
    } catch (_) {
      setState(() => _schedule = _defaultSchedule(id ?? 'local'));
    } finally {
      setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _saveSchedule() async {
    final id = _estabId;
    final token = _token;
    final s = _schedule;
    if (id == null || token == null || s == null) return;
    setState(() => _savingSchedule = true);
    try {
      await AvailabilityService.saveSchedule(
        token: token,
        schedule: ScheduleModel(
          establishmentId: id,
          slotDurationMinutes: _slotDuration,
          days: s.days,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Horários salvos com sucesso!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      setState(() => _savingSchedule = false);
    }
  }

  Future<void> _loadSlots() async {
    final id = _estabId;
    final token = _token;
    if (id == null || token == null) return;
    setState(() => _loadingSlots = true);
    try {
      final dateStr = _formatDateKey(_selectedDay);
      final slots = await AvailabilityService.getAvailability(
        token: token,
        estabId: id,
        date: dateStr,
      );
      setState(() => _slots = slots);
    } catch (_) {
      setState(() => _slots = []);
    } finally {
      setState(() => _loadingSlots = false);
    }
  }

  Future<void> _toggleSlot(TimeSlotModel slot) async {
    final id = _estabId;
    final token = _token;
    if (id == null || token == null) return;

    try {
      if (!slot.available && slot.blockId != null) {
        await AvailabilityService.unblockSlot(token: token, blockId: slot.blockId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Horário liberado!'),
            backgroundColor: AppColors.success,
          ));
        }
      } else if (slot.available) {
        await AvailabilityService.blockSlot(
          token: token,
          estabId: id,
          date: _formatDateKey(_selectedDay),
          time: slot.time,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Horário bloqueado!'),
            backgroundColor: AppColors.warning,
          ));
        }
      }
      await _loadSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDateDisplay(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${d.day} de ${months[d.month - 1]}';
  }

  void _updateDay(int index, WorkingDayModel updated) {
    if (_schedule == null) return;
    final days = List<WorkingDayModel>.from(_schedule!.days);
    days[index] = updated;
    setState(() {
      _schedule = ScheduleModel(
        establishmentId: _schedule!.establishmentId,
        slotDurationMinutes: _slotDuration,
        days: days,
      );
    });
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
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
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

  // ── Tab 1: Configurar horários semanais ─────────────────────────
  Widget _buildScheduleTab() {
    if (_loadingSchedule) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final schedule = _schedule;
    if (schedule == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _loadSchedule,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Duração do slot
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
                  final selected = _slotDuration == min;
                  return GestureDetector(
                    onTap: () => setState(() => _slotDuration = min),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
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
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
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

        // Days of the week
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
                // Day toggle
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
                            _updateDay(i, day.copyWith(isOpen: v)),
                        activeThumbColor: AppColors.primary,
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
                          (t) => _updateDay(i, day.copyWith(startTime: t))),
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
                                color: AppColors.primary)),
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
                          (t) => _updateDay(i, day.copyWith(endTime: t))),
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
                                color: AppColors.primary)),
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
            onPressed: _savingSchedule ? null : _saveSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _savingSchedule
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

  // ── Tab 2: Bloquear/liberar slots de um dia ─────────────────────
  Widget _buildBlockTab() {
    return Column(
      children: [
        // Date picker row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(_formatDateDisplay(_selectedDay),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.dark)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDay,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _selectedDay = picked);
                    _loadSlots();
                  }
                },
                icon: const Icon(Icons.edit_calendar,
                    size: 16, color: AppColors.primary),
                label: const Text('Mudar',
                    style: TextStyle(color: AppColors.primary)),
              ),
              ElevatedButton.icon(
                onPressed: _loadSlots,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

        // Legend
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
          child: _loadingSlots
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : _slots.isEmpty
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
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
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
