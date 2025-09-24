// create_job/steps/subcategories_step.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/job_draft.dart';

class Subcategory {
  final int id;
  final String name;
  const Subcategory({required this.id, required this.name});

  factory Subcategory.fromJson(Map<String, dynamic> j) =>
      Subcategory(id: j['id'] as int, name: j['name'] as String);
}

bool _skipped = false;

class SubcategoriesStep extends StatefulWidget {
  final JobDraft draft;

  final VoidCallback onNext; // вызвать, когда выбрали/пропустили
  const SubcategoriesStep(
      {super.key, required this.draft, required this.onNext});

  @override
  State<SubcategoriesStep> createState() => _SubcategoriesStepState();
}

class _SubcategoriesStepState extends State<SubcategoriesStep> {
  late Future<List<Subcategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Subcategory>> _load() async {
    final id = widget.draft.categoryId;
    if (id == null) return [];
    final uri = Uri.parse(
        'https://idoapi.tw1.ru/subcategories/get.php?category_id=$id&limit=100');
    final r = await http.get(uri, headers: {'Accept': 'application/json'});
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}: ${r.body}');
    final map = json.decode(r.body) as Map<String, dynamic>;
    final items = (map['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items.map(Subcategory.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Subcategory>>(
      future: _future,
      builder: (_, snap) {
        // авто-пропуск, если нет или загрузилось пусто
        if (!_skipped &&
            snap.connectionState == ConnectionState.done &&
            (snap.data?.isEmpty ?? true)) {
          _skipped = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNext());
        }

        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Не удалось загрузить подкатегории:\n${snap.error}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('Повторить'),
              ),
              TextButton(
                onPressed: widget.onNext,
                child: const Text('Пропустить'),
              ),
            ]),
          );
        }

        final items = snap.data ?? const <Subcategory>[];
        if (items.isEmpty) return const SizedBox.shrink(); // будет автопропуск

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final s = items[i];
            return ListTile(
              leading: const Text(
                ">",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              title: Text(
                s.name,
                style: const TextStyle(color: Colors.black87),
              ),
              onTap: () {
                widget.draft.subcategoryId = s.id;
                widget.draft.subcategoryName = s.name;
                widget.onNext();
              },
            );
          },
        );
      },
    );
  }
}
