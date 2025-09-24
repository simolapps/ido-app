// === file: lib/pages/create_job/steps/details_step.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../models/job_draft.dart';
import '../../../theme/app_colors.dart';

class DetailsStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  const DetailsStep({super.key, required this.draft, required this.onNext});

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _LocalImage {
  _LocalImage({required this.path, required this.bytes});
  final String path;     // путь к сжатому временному файлу
  final Uint8List bytes; // превью
}

class _DetailsStepState extends State<DetailsStep> {
  final _desc = TextEditingController();
  final _private = TextEditingController();
  final _picker = ImagePicker();

  final List<_LocalImage> _images = [];
  static const _maxImages = 10;

  @override
  void initState() {
    super.initState();
    // подтягиваем уже набранные данные
    _desc.text = widget.draft.description;
    _private.text = widget.draft.privateNote;

    // подписываемся и сохраняем в draft по мере ввода
    _desc.addListener(() {
      widget.draft.description = _desc.text;
      setState(() {}); // чтобы обновлялась доступность кнопки "Далее"
    });
    _private.addListener(() {
      widget.draft.privateNote = _private.text;
    });

    // поднимаем превью из уже сохранённых путей (если есть)
    _warmupFromDraft();
  }

  Future<void> _warmupFromDraft() async {
    if (widget.draft.mediaPaths.isEmpty) return;
    final list = <_LocalImage>[];
    for (final path in widget.draft.mediaPaths) {
      final f = File(path);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        list.add(_LocalImage(path: path, bytes: bytes));
      }
    }
    if (mounted) setState(() => _images
      ..clear()
      ..addAll(list));
  }

  @override
  void dispose() {
    _desc.dispose();
    _private.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text);
    final label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text.withOpacity(.8));
    final hint = TextStyle(color: AppColors.text.withOpacity(.45), fontSize: 15, height: 1.35);
    final fieldText = const TextStyle(color: AppColors.text, fontSize: 16);

    final canNext = _desc.text.trim().isNotEmpty; // описание обязательно

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) =>
                    states.contains(MaterialState.disabled)
                        ? AppColors.freelance.withOpacity(.45)
                        : AppColors.freelance,
              ),
              foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(vertical: 14),
              ),
              shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            onPressed: canNext
                ? () {
                    // Тексты уже сидят в draft через listeners.
                    // Фото остаются в буфере draft.mediaPaths до финальной публикации.
                    widget.onNext();
                  }
                : null,
            child: const Text('Далее'),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text('Уточните детали', style: title, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),

            Text('Описание', style: label),
            const SizedBox(height: 6),
            _BoxedField(
              controller: _desc,
              minLines: 5,
              maxLines: 10,
              style: fieldText,
              hintStyle: hint,
              hint: 'Например: сделать лендинг для вебинаров по программированию. '
                  'Нужно продумать структуру, подготовить контент. '
                  'Цель — привлечь 30 человек на первое занятие.',
            ),
            const SizedBox(height: 16),

            Text('Приватная информация', style: label),
            const SizedBox(height: 6),
            _BoxedField(
              controller: _private,
              minLines: 3,
              maxLines: 6,
              style: fieldText,
              hintStyle: hint,
              hint: 'Например: квартира 39, код домофона 234, ключ под ковриком :)',
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_outlined,
                    text: 'Галерея',
                    onTap: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_camera_outlined,
                    text: 'Камера',
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),

            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  final it = _images[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(it.bytes, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeAt(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.45),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 16, color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            if (_images.length >= _maxImages)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Вы выбрали максимум $_maxImages фото.',
                  style: TextStyle(color: AppColors.text.withOpacity(.6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== PICK + BUFFER

  Future<void> _pickFromGallery() async {
    if (_images.length >= _maxImages) return;
    final files = await _picker.pickMultiImage();
    await _addPicked(files);
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= _maxImages) return;
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) await _addPicked([x]);
  }

  Future<void> _addPicked(List<XFile>? files) async {
    if (files == null || files.isEmpty) return;

    final canTake = _maxImages - _images.length;
    final take = files.take(max(0, canTake)).toList();

    final cacheDir = await _ensureDraftCacheDir();

    for (final x in take) {
      // Компрессия в файл (JPEG ~85, по большей стороне ~1600)
      final targetPath = p.join(cacheDir.path, _genFilename('.jpg'));
      final compressed = await _compressToFile(x.path, targetPath);

      // Если компресс не сработал — копируем исходник
      final outFile = compressed ?? await File(x.path).copy(targetPath);
      final bytes = await outFile.readAsBytes();

      // В буфер UI
      _images.add(_LocalImage(path: outFile.path, bytes: bytes));

      // В драфт — путь к локальному файлу
      widget.draft.mediaPaths.add(outFile.path);
    }
    if (mounted) setState(() {});
  }

  Future<File?> _compressToFile(String srcPath, String dstPath) async {
    try {
      final outX = await FlutterImageCompress.compressAndGetFile(
        srcPath,
        dstPath,
        quality: 85,
        format: CompressFormat.jpeg,
        minWidth: 1600,
        minHeight: 1600,
        keepExif: false,
      ); // outX : XFile?
      if (outX == null) return null;
      return File(outX.path); // ← конвертация XFile → File
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _ensureDraftCacheDir() async {
    final tmp = await getTemporaryDirectory();
    // Можно завести подпапку drafts; при желании — под конкретный draftId
    final dir = Directory(p.join(tmp.path, 'job_draft_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _genFilename(String ext) {
    final r = Random();
    final n = DateTime.now().millisecondsSinceEpoch;
    return 'img_${n}_${r.nextInt(999999)}$ext';
  }

  void _removeAt(int index) async {
    final removed = _images.removeAt(index);
    // убрать из draft.mediaPaths
    widget.draft.mediaPaths.remove(removed.path);
    // можно подчистить файл (необязательно)
    try { await File(removed.path).delete(); } catch (_) {}
    if (mounted) setState(() {});
  }
}

/// ===== UI helpers

class _BoxedField extends StatelessWidget {
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final String hint;
  final TextStyle style;
  final TextStyle hintStyle;

  const _BoxedField({
    required this.controller,
    required this.minLines,
    required this.maxLines,
    required this.hint,
    required this.style,
    required this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: style,
      cursorColor: AppColors.freelance,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle,
        filled: true,
        fillColor: Colors.white.withOpacity(.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.background2.withOpacity(.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.freelance, width: 1.4),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.freelance.withOpacity(.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        foregroundColor: AppColors.text.withOpacity(.85),
        backgroundColor: Colors.white.withOpacity(.85),
      ),
      icon: Icon(icon, color: AppColors.freelance),
      label: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
