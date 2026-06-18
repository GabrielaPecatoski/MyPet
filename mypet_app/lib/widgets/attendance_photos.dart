import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../services/booking_service.dart';
import 'app_image.dart';

/// Grade somente-leitura das fotos do atendimento. Toca pra abrir em tela cheia.
class AttendancePhotosGrid extends StatelessWidget {
  final List<String> photos;
  const AttendancePhotosGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: photos
          .map((p) => GestureDetector(
                onTap: () => _openFullScreen(context, p),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppImage(
                    url: p,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.grey),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

void _openFullScreen(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Center(
              child: AppImage(
                url: url,
                fit: BoxFit.contain,
                fallback: const Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Abre o sheet de gerenciamento das fotos do atendimento (câmera/galeria,
/// várias fotos). Persiste cada alteração via [BookingService.setAttendancePhotos]
/// e retorna a lista final de fotos (ou `null` se nada mudou).
Future<List<String>?> showAttendancePhotosSheet(
  BuildContext context, {
  required String token,
  required String bookingId,
  required List<String> initial,
  Color accent = AppColors.estab,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _AttendancePhotosSheet(
      token: token,
      bookingId: bookingId,
      initial: initial,
      accent: accent,
    ),
  );
}

class _AttendancePhotosSheet extends StatefulWidget {
  final String token;
  final String bookingId;
  final List<String> initial;
  final Color accent;
  const _AttendancePhotosSheet({
    required this.token,
    required this.bookingId,
    required this.initial,
    required this.accent,
  });

  @override
  State<_AttendancePhotosSheet> createState() => _AttendancePhotosSheetState();
}

class _AttendancePhotosSheetState extends State<_AttendancePhotosSheet> {
  late List<String> _photos;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.initial);
  }

  Future<void> _save(List<String> next) async {
    setState(() => _busy = true);
    try {
      final updated = await BookingService.setAttendancePhotos(
        token: widget.token,
        bookingId: widget.bookingId,
        photos: next,
      );
      if (!mounted) return;
      setState(() {
        _photos = updated.attendancePhotos;
        _changed = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _add(ImageSource source) async {
    if (kIsWeb) return;
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 70, maxWidth: 1280, maxHeight: 1280);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    await _save([..._photos, url]);
  }

  Future<void> _remove(int index) async {
    final next = [..._photos]..removeAt(index);
    await _save(next);
  }

  void _pickSource() {
    if (kIsWeb) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: widget.accent),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: widget.accent),
              title: const Text('Galeria de fotos'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Fotos do atendimento',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 4),
            const Text('Registre o atendimento para o cliente acompanhar.',
                style: TextStyle(fontSize: 13, color: AppColors.grey)),
            const SizedBox(height: 16),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                    'A captura de fotos está disponível apenas no app (celular).',
                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
              ),
            if (_photos.isEmpty && !_busy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.photo_camera_back_outlined,
                        color: AppColors.grey, size: 32),
                    SizedBox(height: 8),
                    Text('Nenhuma foto ainda',
                        style: TextStyle(color: AppColors.grey, fontSize: 13)),
                  ],
                ),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImage(
                            url: _photos[i],
                            fit: BoxFit.cover,
                            fallback: Container(color: AppColors.background),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _busy ? null : () => _remove(i),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_busy || kIsWeb) ? null : _pickSource,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_a_photo_outlined,
                        color: Colors.white, size: 18),
                label: Text(_busy ? 'Salvando...' : 'Adicionar foto',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.pop(context, _changed ? _photos : null),
                child: const Text('Concluído',
                    style: TextStyle(color: AppColors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
