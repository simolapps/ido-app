// lib/pages/create_job/steps/title_step.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ido/theme/app_colors.dart';
import '../../../models/job_draft.dart';

class TitleStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  const TitleStep({super.key, required this.draft, required this.onNext});

  @override
  State<TitleStep> createState() => _TitleStepState();
}

class _TitleStepState extends State<TitleStep> {
  final _title = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focus = FocusNode();

  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestions();

    // Автофокус — сразу открывает клавиатуру
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<List<String>> _loadSuggestions() async {
    if (widget.draft.subcategoryId == null) return [];
    final uri = Uri.parse(
      'https://idoapi.tw1.ru/title_suggestions/get.php?subcategory_id=${widget.draft.subcategoryId}',
    );
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final map = json.decode(res.body) as Map<String, dynamic>;
    final items = (map['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items
        .map((e) => (e['text'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _applySuggestion(String s) {
    _title.text = s;
    _title.selection = TextSelection.fromPosition(
      TextPosition(offset: _title.text.length),
    );
    _focus.requestFocus();
    setState(() {});
  }

  void _goNext() {
    if (_formKey.currentState!.validate()) {
      widget.draft.title = _title.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    const black = Colors.black87;

    return Scaffold(
      backgroundColor: Colors.white,
      // Кнопка всегда «приклеена» к низу
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor:AppColors.freelance),
              onPressed: _goNext,
              child: const Text('Далее'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Как назвать задание?',
                style: TextStyle(
                  color: black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Поле ввода
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _title,
                  focusNode: _focus,
                  autofocus: true,
                  style: const TextStyle(color: black),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 5, // поле растёт до 5 строк
                  decoration: const InputDecoration(
                    labelText: 'Название задания',
                    hintText: 'Например, Собрать шкаф',
                    labelStyle: TextStyle(color: black),
                    hintStyle: TextStyle(color: Colors.black45),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Примеры как можно назвать',
                style: TextStyle(color: black, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Скроллимый список подсказок
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _future,
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Не удалось загрузить подсказки',
                          style: TextStyle(color: black),
                        ),
                      );
                    }
                    final suggestions = snap.data ?? const <String>[];
                    if (suggestions.isEmpty) {
                      return const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Пока нет примеров для этой подкатегории.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = suggestions[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s, style: const TextStyle(color: black)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                          onTap: () => _applySuggestion(s),
                        );
                      },
                    );
                  },
                ),
              ),

              // Низ оставляем пустым — под кнопку в bottomNavigationBar
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
