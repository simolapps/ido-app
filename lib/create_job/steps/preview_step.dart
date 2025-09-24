// === file: lib/pages/create_job/steps/preview_step.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart'; // ⟵ добавили

import '../../../models/job_draft.dart';
import '../../../theme/app_colors.dart';

/// Разделы, которые можно редактировать из превью.
enum PreviewSection { title, details, budget, payment, date, address, dynamicAnswers }

class PreviewStep extends StatefulWidget {
  final JobDraft draft;
  final void Function(PreviewSection section)? onEdit;

  /// Если true — экран встроен в мастер и НЕ рисует свой Scaffold/AppBar.
  final bool embedded;

  const PreviewStep({
    super.key,
    required this.draft,
    this.onEdit,
    this.embedded = false,
  });

  @override
  State<PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends State<PreviewStep> {
  bool _publishing = false;
  bool _saving = false;

  // auth
  bool _authLoading = true;
  String? _userId; // строковый master_id из SharedPreferences

  JobDraft get draft => widget.draft;

  @override
  void initState() {
    super.initState();

    // Не открывать клавиатуру
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    _loadUserId(); // ⟵ подтянем master_id из SharedPreferences
  }

  Future<void> _loadUserId() async {
    setState(() => _authLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final mid = prefs.getInt('user_id'); // ← такой же ключ ты уже используешь на регистрации
      _userId = (mid == null || mid <= 0) ? null : mid.toString();

      // Пробросим в JobApi, чтобы он прикреплял X-User-Id к запросам
      JobApi.userId = _userId;
    } catch (_) {
      _userId = null;
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: AppColors.text.withOpacity(.6), fontSize: 13, fontWeight: FontWeight.w600);
    final valueStyle = const TextStyle(color: AppColors.text, fontSize: 16);
    final sectionTitle = const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24 + 76), // запас под нижние кнопки
      children: [
        if (_authLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 3),
          )
        else if (_userId == null)
          Card(
            color: const Color(0xFFFFF7ED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF9A3412)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Чтобы публиковать задания, войдите в аккаунт.',
                      style: TextStyle(color: Color(0xFF9A3412)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    child: const Text('Войти / Регистрация'),
                  ),
                ],
              ),
            ),
          ),

        _SectionCard(
          title: 'Название',
          onEdit: _edit(PreviewSection.title),
          child: _LabeledValue(
            label: 'Как назвать задание?',
            value: draft.title.isEmpty ? '—' : draft.title,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ),
        _SectionCard(
          title: 'Детали',
          onEdit: _edit(PreviewSection.details),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(
                label: 'Описание',
                value: draft.description.isEmpty ? '—' : draft.description,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              const SizedBox(height: 12),
              _LabeledValue(
                label: 'Приватная информация',
                value: draft.privateNote.isEmpty ? '—' : draft.privateNote,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              if (_allMedia().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Фото', style: sectionTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                _PhotosGrid(localPaths: draft.mediaPaths, remoteUrls: draft.photoUrls),
              ],
            ],
          ),
        ),
        _SectionCard(
          title: 'Место оказания услуги',
          onEdit: _edit(PreviewSection.address),
          child: _LabeledValue(
            label: 'Место',
            value: draft.isRemote ? 'Удалённо' : (draft.address.isEmpty ? 'По адресу' : draft.address),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ),
        _SectionCard(
          title: 'Сроки',
          onEdit: _edit(PreviewSection.date),
          child: _LabeledValue(
            label: 'Когда приступить',
            value: _dateStr(draft),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ),
        _SectionCard(
          title: 'Бюджет',
          onEdit: _edit(PreviewSection.budget),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(
                label: 'Тип оплаты',
                value: _payName(draft.paymentType),
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              const SizedBox(height: 12),
              _LabeledValue(
                label: 'Бюджет',
                value: _budgetStr(draft),
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),
        ),
        if (draft.dynamicAnswers.isNotEmpty)
          _SectionCard(
            title: 'Дополнительные ответы',
            onEdit: _edit(PreviewSection.dynamicAnswers),
            child: Column(
              children: draft.dynamicAnswers.entries.map((e) {
                final k = e.key.toString();
                final v = e.value;
                final text = v is List ? v.join(', ') : (v?.toString() ?? '—');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _LabeledValue(
                    label: k,
                    value: text.isEmpty ? '—' : text,
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );

    final footer = SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: (_saving || _authLoading || _userId == null) ? null : _onSaveDraft,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.freelance.withOpacity(.5)),
                foregroundColor: AppColors.freelance,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Сохранить черновик'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) => states.contains(MaterialState.disabled)
                      ? AppColors.freelance.withOpacity(.45)
                      : AppColors.freelance,
                ),
                foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
                padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 14)),
                shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              onPressed: (_publishing || _authLoading || _userId == null) ? null : _onPublish,
              child: _publishing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Опубликовать'),
            ),
          ),
        ],
      ),
    );

    // Встроенный режим — без собственного AppBar/Scaffold
    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(left: 0, right: 0, bottom: 0, child: footer),
        ],
      );
    }

    // Отдельный экран — со своим Scaffold
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          title: const Text('Предпросмотр', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        bottomNavigationBar: footer,
        body: content,
      ),
    );
  }

  VoidCallback? _edit(PreviewSection s) => widget.onEdit == null ? null : () => widget.onEdit!(s);

  List<String> _allMedia() => [...draft.mediaPaths, ...draft.photoUrls];

  // ========= ACTIONS

  Future<void> _onSaveDraft() async {
    setState(() => _saving = true);
    try {
      final draftId = await JobApi.saveDraft(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Черновик сохранён (#$draftId)')));
    } catch (e) {
      _showNiceError(e, context, prefix: 'Сохранение черновика');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onPublish() async {
    setState(() => _publishing = true);
    try {
      // дозаливаем локальные медиа, если нужно
      if (draft.photoUrls.isEmpty && draft.mediaPaths.isNotEmpty) {
        final urls = <String>[];
        for (final path in draft.mediaPaths) {
          final url = await JobApi.uploadImage(File(path));
          urls.add(url);
        }
        draft.photoUrls = urls;
      }
      final id = await JobApi.publish(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Задание опубликовано (#$id)')));
      Navigator.pop(context, true);
    } catch (e) {
      _showNiceError(e, context, prefix: 'Публикация');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showNiceError(Object e, BuildContext ctx, {String? prefix}) {
    final msg = e.toString();
    String pretty = msg;

    // частая опечатка на бэке: Util::customerIdOrFail()
    if (msg.contains('Util::customerldOrFail') || msg.contains('customerIdOrFail')) {
      pretty = 'Требуется авторизация на сервере (или исправить Util::customerIdOrFail на бэке).';
    } else if (msg.startsWith('Exception: ')) {
      pretty = msg.replaceFirst('Exception: ', '');
    }

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('${prefix ?? 'Ошибка'}: $pretty')),
    );
  }

  // ========= FORMATTERS

  String _budgetStr(JobDraft d) {
    if (d.customBudget != null) return '≈ ${d.customBudget} ₽';
    if (d.budgetPreset != null) return 'до ${d.budgetPreset} ₽';
    return '—';
  }

  String _dateStr(JobDraft d) {
    if (d.exactDateTime != null) {
      final x = d.exactDateTime!;
      return '${_dd(x.day)}.${_dd(x.month)}.${x.year} ${_dd(x.hour)}:${_dd(x.minute)}';
    }
    if (d.periodFrom != null || d.periodTo != null) {
      String fmt(DateTime? t) => t == null ? '' : '${_dd(t.day)}.${_dd(t.month)}.${t.year}';
      final f = fmt(d.periodFrom);
      final t = fmt(d.periodTo);
      final sep = (f.isNotEmpty && t.isNotEmpty) ? ' — ' : '';
      final s = (f + sep + t);
      return s.isEmpty ? '—' : s;
    }
    return '—';
  }

  String _payName(String k) {
    switch (k) {
      case 'escrow':
        return 'Сделка без риска';
      case 'docs':
        return 'С документами';
      default:
        return 'Напрямую исполнителю';
    }
  }

  String _dd(int v) => v.toString().padLeft(2, '0');
}

// ================= API CLIENT =================

class JobApi {
  static const String baseJobs  = 'https://idoapi.tw1.ru/jobs';
  static const String uploadUrl = 'https://idoapi.tw1.ru/uploads/upload_image.php';

  /// userId (master_id) прокидывается после логина/регистрации
  static String? userId;

  /// Включить/выключить сетевой лог
  static const bool _logNet = true;

  static void _log(String tag, Object? data) {
    if (!_logNet) return;
    final text = switch (data) {
      null => 'null',
      String s => s,
      _ => const JsonEncoder.withIndent('  ').convert(data),
    };
    debugPrint('[$tag] $text');
  }

  static Map<String, String> _jsonH() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (userId != null && userId!.isNotEmpty) h['X-User-Id'] = userId!;
    return h;
  }

  static Map<String, String> _formH() {
    final h = <String, String>{};
    if (userId != null && userId!.isNotEmpty) h['X-User-Id'] = userId!;
    return h;
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : {'ok': false, 'error': 'bad_json_shape'};
    } catch (e) {
      _log('decode.error', {'message': e.toString(), 'body': body});
      return {'ok': false, 'error': 'bad_json'};
    }
  }

  static void _requireUser() {
    if (userId == null || userId!.isEmpty) {
      throw Exception('auth_required'); // красиво обработаем в UI
    }
  }

  /// Публикация задания
  static Future<int> publish(JobDraft draft) async {
    _requireUser();
    final url = Uri.parse('$baseJobs/publish.php');
    final payload = draft.toJson();

    _log('publish.request', {'url': url.toString(), 'headers': _jsonH(), 'body': payload});

    final resp = await http.post(url, headers: _jsonH(), body: jsonEncode(payload));

    _log('publish.response', {'status': resp.statusCode, 'headers': resp.headers, 'body': resp.body});

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = _decode(resp.body);
    if (data['ok'] != true) {
      throw Exception(data['error'] ?? 'Неизвестная ошибка сервера');
    }
    return (data['id'] as num).toInt();
  }

  /// Сохранение черновика
  static Future<int> saveDraft(JobDraft draft) async {
    _requireUser();
    final url = Uri.parse('$baseJobs/save_draft.php');
    final payload = draft.toJson();

    _log('saveDraft.request', {'url': url.toString(), 'headers': _jsonH(), 'body': payload});

    final resp = await http.post(url, headers: _jsonH(), body: jsonEncode(payload));

    _log('saveDraft.response', {'status': resp.statusCode, 'headers': resp.headers, 'body': resp.body});

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = _decode(resp.body);
    if (data['ok'] != true) {
      throw Exception(data['error'] ?? 'Неизвестная ошибка сервера');
    }
    return ((data['draftId'] ?? data['id'] ?? 0) as num).toInt();
  }

  /// Загрузка изображения. Возвращает публичный URL.
  static Future<String> uploadImage(File file) async {
    _requireUser();
    final exists = await file.exists();
    final len = exists ? await file.length() : -1;

    _log('uploadImage.request', {
      'url': uploadUrl,
      'filePath': file.path,
      'exists': exists,
      'size': len,
      'headers': _formH(),
    });

    final req = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..headers.addAll(_formH())
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    _log('uploadImage.response', {'status': streamed.statusCode, 'headers': streamed.headers, 'body': body});

    if (streamed.statusCode != 200) {
      throw Exception('Загрузка не удалась: HTTP ${streamed.statusCode} $body');
    }
    final data = _decode(body);
    if (data['ok'] != true || data['url'] == null) {
      throw Exception('Сервер вернул некорректный ответ на загрузку');
    }
    return data['url'] as String;
  }
}

// ================= UI HELPERS =================

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  const _SectionCard({
    required this.title,
    required this.child,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.freelance, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700))),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.freelance),
                    label: const Text('Изменить', style: TextStyle(color: AppColors.freelance)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _LabeledValue({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  final List<String> localPaths;
  final List<String> remoteUrls;

  const _PhotosGrid({
    required this.localPaths,
    required this.remoteUrls,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    for (final p in localPaths) {
      tiles.add(_thumb(Image.file(File(p), fit: BoxFit.cover)));
    }
    for (final u in remoteUrls) {
      tiles.add(_thumb(Image.network(u, fit: BoxFit.cover)));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }

  Widget _thumb(Image img) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(color: Colors.black12, child: img),
    );
  }
}
