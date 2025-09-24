import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';

typedef VPreviewEdit = void Function(int stepIndex);

class VPreviewStep extends StatefulWidget {
  final VacancyDraft draft;
  final VPreviewEdit onEdit;
  /// Если true — экран встроен в мастер (PageView) и рисуем только контент + футер.
  final bool embedded;

  const VPreviewStep({
    super.key,
    required this.draft,
    required this.onEdit,
    this.embedded = true,
  });

  @override
  State<VPreviewStep> createState() => _VPreviewStepState();
}

class _VPreviewStepState extends State<VPreviewStep> {
  bool _saving = false;
  bool _publishing = false;

  /// draftId, возвращённый сервером после первого сохранения — чтобы далее делать UPDATE
  int? _draftId;

  VacancyDraft get d => widget.draft;

  // API (работают через bootstrap.php → Util/Db/Response)
  static const _apiDraftSave = 'https://idoapi.tw1.ru/vacancies/vacancy_draft_save.php';
  static const _apiCreate    = 'https://idoapi.tw1.ru/vacancies/vacancies_create.php';

  @override
  void initState() {
    super.initState();
    // не открывать клавиатуру
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: AppColors.text.withOpacity(.6), fontSize: 13, fontWeight: FontWeight.w600);
    final valueStyle = const TextStyle(color: AppColors.text, fontSize: 16);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24 + 76),
      children: [
        // 0 — Название/Профессия/Сфера
        _SectionCard(
          title: 'Название',
          onEdit: () => widget.onEdit(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(label: 'Как назвать вакансию?', value: _val(d.title), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'Профессия', value: _val(d.profession), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'Сфера', value: _val(d.industry), labelStyle: labelStyle, valueStyle: valueStyle),
            ],
          ),
        ),

        // 1 — Описание
        _SectionCard(
          title: 'Описание',
          onEdit: () => widget.onEdit(1),
          child: _LabeledValue(
            label: 'О вакансии и компании',
            value: _val(d.description),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ),

        // 2 — График
        _SectionCard(
          title: 'График',
          onEdit: () => widget.onEdit(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(label: 'Занятость', value: _mapEmployment(d.employment), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'График', value: _mapSchedule(d.schedule), labelStyle: labelStyle, valueStyle: valueStyle),
              if (d.schedule == 'rotational' && d.rotationLengthDays != null) ...[
                const SizedBox(height: 12),
                _LabeledValue(label: 'Вахта', value: '${d.rotationLengthDays} дней', labelStyle: labelStyle, valueStyle: valueStyle),
              ],
              if (d.dailyHours.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LabeledValue(label: 'Часы в день', value: _mapHours(d.dailyHours), labelStyle: labelStyle, valueStyle: valueStyle),
              ],
            ],
          ),
        ),

        // 3 — Зарплата
        _SectionCard(
          title: 'Зарплата',
          onEdit: () => widget.onEdit(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(label: 'Диапазон', value: _salaryRange(d), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'Период', value: _mapPeriod(d.salaryPeriod), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'Указание', value: d.taxMode == 'net' ? 'На руки' : 'До вычета', labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(label: 'Частота выплат', value: _mapFreq(d.payoutFrequency), labelStyle: labelStyle, valueStyle: valueStyle),
            ],
          ),
        ),

        // 4 — География
        _SectionCard(
          title: 'География',
          onEdit: () => widget.onEdit(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledValue(label: 'Ищем в регионе', value: _val(d.searchRegion), labelStyle: labelStyle, valueStyle: valueStyle),
              const SizedBox(height: 12),
              _LabeledValue(
                label: 'Адреса работы',
                value: d.workAddresses.isEmpty ? '—' : d.workAddresses.join('; '),
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),
        ),

        // 5 — Контакты
        _SectionCard(
          title: 'Контакты',
          onEdit: () => widget.onEdit(5),
          child: _LabeledValue(
            label: 'Телефон',
            value: _val(d.phone),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ),
      ],
    );

    final footer = SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // серый фон + прежняя обводка
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : _onSaveDraft,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                side: BorderSide(color: AppColors.vacancy.withOpacity(.5)),
                foregroundColor: AppColors.vacancy,
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
                      ? AppColors.vacancy.withOpacity(.45)
                      : AppColors.vacancy,
                ),
                foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
                padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 14)),
                shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              onPressed: _publishing ? null : _onPublish,
              child: _publishing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Опубликовать'),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(left: 0, right: 0, bottom: 0, child: footer),
        ],
      );
    }

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

  // ====== actions ======

  Future<void> _onSaveDraft() async {
    setState(() => _saving = true);
    try {
      final payload = _draftToJson(d);

      final req = <String, dynamic>{
        if (_draftId != null) 'draftId': _draftId,
        'payload': payload,
      };

      final r = await http.post(
        Uri.parse(_apiDraftSave),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req),
      );

      final Map<String, dynamic>? body =
          (r.body.isNotEmpty) ? jsonDecode(r.body) as Map<String, dynamic> : null;

      if (r.statusCode >= 200 && r.statusCode < 300 && body?['ok'] == true) {
        final newId = body?['draftId'];
        if (newId is int) _draftId = newId;
        _toast('Черновик сохранён');
      } else {
        _toast(_extractErr(body) ?? 'Не удалось сохранить черновик');
      }
    } catch (_) {
      _toast('Ошибка сети при сохранении');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onPublish() async {
    setState(() => _publishing = true);
    try {
      // минимальная валидация перед публикацией
      if (d.title.trim().isEmpty) { _toast('Заполните название'); return; }
      if (d.description.trim().isEmpty) { _toast('Добавьте описание'); return; }
      if (d.phone.trim().isEmpty) { _toast('Укажите телефон для связи'); return; }

      final req = {
        'title': d.title.trim(),
        'description': d.description.trim(),
        'phone': d.phone.trim(),
        'schedule': d.schedule,
        'rotation_length_days': d.rotationLengthDays,
        'salary_from': d.salaryFrom,
        'salary_to': d.salaryTo,
        'salary_period': d.salaryPeriod,
        'tax_mode': d.taxMode,
        'payout_frequency': d.payoutFrequency,
        'addresses': d.workAddresses, // можно строками
        'media': [],
        // доп. инфо — если на бэке решите маппить в id
        'profession': d.profession,
        'industry': d.industry,
      };

      final r = await http.post(
        Uri.parse(_apiCreate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req),
      );

      final Map<String, dynamic>? body =
          (r.body.isNotEmpty) ? jsonDecode(r.body) as Map<String, dynamic> : null;

      if (r.statusCode >= 200 && r.statusCode < 300 && body?['ok'] == true) {
        _toast('Вакансия опубликована');
        // здесь можно закрыть мастер/перейти «Мои вакансии»
      } else {
        _toast(_extractErr(body) ?? 'Не удалось опубликовать');
      }
    } catch (_) {
      _toast('Ошибка сети при публикации');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  // ====== helpers ======
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _extractErr(Map<String, dynamic>? body) {
    if (body == null) return null;
    if (body['message'] is String) return body['message'] as String;
    if (body['error'] is String) return body['error'] as String;
    return null;
  }

  Map<String, dynamic> _draftToJson(VacancyDraft d) {
    return {
      'title': d.title,
      'profession': d.profession,
      'industry': d.industry,
      'description': d.description,
      'schedule': d.schedule,
      'rotation_length_days': d.rotationLengthDays,
      'salary_from': d.salaryFrom,
      'salary_to': d.salaryTo,
      'salary_period': d.salaryPeriod,
      'tax_mode': d.taxMode,
      'payout_frequency': d.payoutFrequency,
      'search_region': d.searchRegion,
      'work_addresses': d.workAddresses,
      'phone': d.phone,
      // добавляйте новые поля по мере появления
    };
  }

  String _val(String s) => s.trim().isNotEmpty ? s.trim() : '—';

  String _salaryRange(VacancyDraft d) {
    final f = d.salaryFrom;
    final t = d.salaryTo;
    if (f == null && t == null) return '—';
    if (f != null && t != null) return '${_fmtMoney(f)}–${_fmtMoney(t)} ₽';
    if (f != null) return 'от ${_fmtMoney(f)} ₽';
    return 'до ${_fmtMoney(t!)} ₽';
  }

  String _fmtMoney(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (i < s.length - 1 && idxFromEnd % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  String _mapEmployment(String v) => {
        'full': 'Полная',
        'part': 'Частичная',
        'temp': 'Временная',
        'intern': 'Стажировка',
      }[v] ?? (v.isEmpty ? '—' : v);

  String _mapSchedule(String v) => {
        'day': 'Дневные',
        'night': 'Ночные',
        'shift': 'Сменный',
        'rotational': 'Вахта',
        'flexible': 'Гибкий',
        'fixed': 'Фиксированный',
      }[v] ?? (v.isEmpty ? '—' : v);

  String _mapHours(String v) => {
        '6-7': '6–7 часов',
        '8': '8 часов',
        '9-10': '9–10 часов',
        '11-12': '11–12 часов',
      }[v] ?? (v.isEmpty ? '—' : v);
  
  String _mapPeriod(String v) => {
        'month': 'в месяц',
        'week': 'в неделю',
        'day': 'в день',
        'hour': 'в час',
        'piece': 'сдельно',
        'per_shift': 'за смену',
      }[v] ?? (v.isEmpty ? '—' : v);

  String _mapFreq(String v) => {
        'daily': 'ежедневно',
        'weekly': 'еженедельно',
        'twice_month': 'два раза в месяц',
        'three_times_month': 'три раза в месяц',
        'monthly': 'ежемесячно',
        'per_shift': 'за смену',
        'per_hour': 'за час',
      }[v] ?? (v.isEmpty ? '—' : v);
}

// ====== UI helpers ======

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
        side: const BorderSide(color: AppColors.vacancy, width: 1),
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
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.vacancy),
                    label: const Text('Изменить', style: TextStyle(color: AppColors.vacancy)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: labelStyle),
      const SizedBox(height: 4),
      Text(value, style: valueStyle),
    ]);
  }
}
