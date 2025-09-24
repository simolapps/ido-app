// === file: lib/pages/create_job/steps/dynamic_step_page.dart
import 'package:flutter/material.dart';
import 'package:ido/theme/app_colors.dart';
import '../../../models/job_draft.dart';

enum DynType { radio, checkbox, text, multiform, picker, formlist }

class DynamicStepPage extends StatefulWidget {
  final JobDraft draft;
  final String id;
  final DynType type;
  final String title;
  final String? subtitle;
  final List<String> options;
  /// поля для multiform: [{name,label,input}]
  final List<Map<String, String>> fields;
  final String? placeholder;
  final String? hint;
  final String? label;
  final bool required;
  final VoidCallback onNext;

  const DynamicStepPage({
    super.key,
    required this.draft,
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.options = const [],
    this.fields = const [],
    this.placeholder,
    this.hint,
    this.label,
    this.required = false,
    required this.onNext,
  });

  /// Безопасный конструктор из JSON схемы шага
  factory DynamicStepPage.fromJson({
    required JobDraft draft,
    required Map<String, dynamic> json,
    required VoidCallback onNext,
  }) {
    DynType parseType(String? v) {
      switch (v) {
        case 'radio':     return DynType.radio;
        case 'checkbox':  return DynType.checkbox;
        case 'multiform': return DynType.multiform;
        case 'picker':    return DynType.picker;
        case 'formlist':  return DynType.formlist;
        default:          return DynType.text;
      }
    }

    final opts = (json['options'] as List?)
            ?.map((e) => '$e')
            .toList() ??
        const <String>[];

    final rawFields = (json['fields'] as List?) ?? const <dynamic>[];
    final fields = <Map<String, String>>[];
    for (final f in rawFields) {
      if (f is Map) {
        fields.add(
          f.map((k, v) => MapEntry('$k', '${v ?? ''}')),
        );
      }
    }

    return DynamicStepPage(
      draft: draft,
      id: '${json['id'] ?? json['name'] ?? DateTime.now().millisecondsSinceEpoch}',
      type: parseType(json['type'] as String?),
      title: '${json['title'] ?? 'Вопрос'}',
      subtitle: (json['subtitle'] != null) ? '${json['subtitle']}' : null,
      options: opts,
      fields: fields,
      placeholder: (json['placeholder'] != null) ? '${json['placeholder']}' : null,
      hint: (json['hint'] != null) ? '${json['hint']}' : null,
      label: (json['label'] != null) ? '${json['label']}' : null,
      required: json['required'] == true,
      onNext: onNext,
    );
  }

  @override
  State<DynamicStepPage> createState() => _DynamicStepPageState();
}

class _DynamicStepPageState extends State<DynamicStepPage> {
  String? _radio;
  final Set<String> _checks = {};
  final TextEditingController _text = TextEditingController();
  final Map<String, TextEditingController> _mf = {};
  String? _pickerValue;

  @override
  void initState() {
    super.initState();

    // восстановление из draft
    final prev = widget.draft.dynamicAnswers[widget.id];
    if (prev != null) {
      switch (widget.type) {
        case DynType.radio:
          _radio = prev as String?;
          break;
        case DynType.checkbox:
          _checks.addAll((prev as List).map((e) => '$e'));
          break;
        case DynType.text:
          _text.text = prev as String? ?? '';
          break;
        case DynType.multiform:
          final m = (prev as Map).map((k, v) => MapEntry('$k', v));
          for (final f in widget.fields) {
            final name = f['name']!;
            _mf[name] = TextEditingController(text: '${m[name] ?? ''}');
          }
          break;
        case DynType.picker:
          _pickerValue = prev as String?;
          break;
        case DynType.formlist:
          break;
      }
    } else if (widget.type == DynType.multiform) {
      for (final f in widget.fields) {
        _mf[f['name']!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    for (final c in _mf.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canProceed {
    if (!widget.required) return true;
    switch (widget.type) {
      case DynType.radio:
        return _radio != null;
      case DynType.checkbox:
        return _checks.isNotEmpty;
      case DynType.text:
        return _text.text.trim().isNotEmpty;
      case DynType.multiform:
        return widget.fields.every(
          (f) => (_mf[f['name']]?.text.trim().isNotEmpty ?? false),
        );
      case DynType.picker:
        return _pickerValue != null && _pickerValue!.isNotEmpty;
      case DynType.formlist:
        return true;
    }
  }

  void _saveAndNext() {
    final id = widget.id;
    switch (widget.type) {
      case DynType.radio:
        widget.draft.dynamicAnswers[id] = _radio;
        break;
      case DynType.checkbox:
        widget.draft.dynamicAnswers[id] = _checks.toList();
        break;
      case DynType.text:
        widget.draft.dynamicAnswers[id] = _text.text.trim();
        break;
      case DynType.multiform:
        widget.draft.dynamicAnswers[id] = {
          for (final f in widget.fields)
            f['name']!: _mf[f['name']]!.text.trim(),
        };
        break;
      case DynType.picker:
        widget.draft.dynamicAnswers[id] = _pickerValue;
        break;
      case DynType.formlist:
        // если появятся подэкраны — сохраняем здесь
        break;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    );
    const black = TextStyle(color: Colors.black);

    Widget body;

    switch (widget.type) {
      case DynType.radio:
        body = Theme(
          data: Theme.of(context).copyWith(
            radioTheme: RadioThemeData(
              fillColor: MaterialStatePropertyAll(AppColors.freelance),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.title, style: titleStyle),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(widget.subtitle!, style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 12),
              ...widget.options.map(
                (o) => RadioListTile<String>(
                  value: o,
                  groupValue: _radio,
                  onChanged: (v) => setState(() => _radio = v),
                  title: Text(o, style: black),
                  // на случай старых версий Flutter:
                  activeColor: AppColors.freelance,
                ),
              ),
            ],
          ),
        );
        break;

      case DynType.checkbox:
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.title, style: titleStyle),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(widget.subtitle!, style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 12),
            ...widget.options.map(
              (o) => CheckboxListTile(
                value: _checks.contains(o),
                onChanged: (v) => setState(() {
                  v == true ? _checks.add(o) : _checks.remove(o);
                }),
                title: Text(o, style: black),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
          ],
        );
        break;

      case DynType.text:
        body = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: titleStyle),
              if (widget.hint != null || widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(widget.subtitle ?? widget.hint!,
                    style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                keyboardType: (widget.placeholder?.toLowerCase() == 'возраст')
                    ? TextInputType.number
                    : TextInputType.text,
                style: black,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(color: Colors.black45),
                ),
              ),
            ],
          ),
        );
        break;

      case DynType.multiform:
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.title, style: titleStyle),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!, style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 12),
            ...widget.fields.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _mf[f['name']],
                  keyboardType: (f['input'] == 'number')
                      ? TextInputType.number
                      : TextInputType.text,
                  style: black,
                  decoration: InputDecoration(
                    labelText: f['label'],
                    labelStyle: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case DynType.picker:
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.title, style: titleStyle),
            const SizedBox(height: 12),
            ListTile(
              title: Text(widget.label ?? 'Выбрать',
                  style: const TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.chevron_right),
              subtitle: Text(_pickerValue ?? '',
                  style: const TextStyle(color: Colors.black)),
              onTap: () async {
                final v = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => _PickerSheet(
                    options: widget.options,
                    initial: _pickerValue,
                  ),
                );
                if (v != null) setState(() => _pickerValue = v);
              },
            ),
          ],
        );
        break;

      case DynType.formlist:
        // заглушка на будущее
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text('Заполните список параметров',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
            SizedBox(height: 12),
            ListTile(
                title: Text('Частота', style: TextStyle(color: Colors.black54)),
                trailing: Icon(Icons.chevron_right)),
            Divider(height: 1),
            ListTile(
                title: Text('Длительность', style: TextStyle(color: Colors.black54)),
                trailing: Icon(Icons.chevron_right)),
          ],
        );
        break;
    }

    return Column(
      children: [
        Expanded(child: body),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.freelance),
                onPressed: _canProceed ? _saveAndNext : null,
                child: const Text('Далее', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final List<String> options;
  final String? initial;
  const _PickerSheet({required this.options, this.initial});
  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late String _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial ?? (widget.options.isNotEmpty ? widget.options.first : '');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            itemCount: widget.options.length,
            itemBuilder: (_, i) {
              final o = widget.options[i];
              final sel = o == _value;
              return ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    color: sel ? Colors.black : Colors.black87,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: sel
                    ? const Icon(Icons.radio_button_checked, color: AppColors.freelance)
                    : const Icon(Icons.radio_button_off, color: Colors.black38),
                onTap: () => setState(() => _value = o),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('Готово'),
        ),
      ]),
    );
  }
}
