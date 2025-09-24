import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/vacancy_item.dart';

class VacancyDetailsPage extends StatefulWidget {
  final int vacancyId;
  final String? titleHint;
  const VacancyDetailsPage({super.key, required this.vacancyId, this.titleHint});

  @override
  State<VacancyDetailsPage> createState() => _VacancyDetailsPageState();
}

class _VacancyDetailsPageState extends State<VacancyDetailsPage> {
  VacancyItem? v;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse('https://idoapi.tw1.ru/vacancies/get.php')
          .replace(queryParameters: {'id': widget.vacancyId.toString()});
      final r = await http.get(uri, headers: {'Accept': 'application/json'});
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final map = json.decode(r.body) as Map<String, dynamic>;
      final item = (map['item'] as Map?) ?? {};
      setState(() => v = VacancyItem.fromJson(item.cast<String, dynamic>()));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = v?.title ?? widget.titleHint ?? 'Вакансия';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(child: Text('Ошибка: $error'))
              : _body(),
    );
  }

  Widget _body() {
    final x = v!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(x.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(x.description, style: const TextStyle(height: 1.35)),
        const SizedBox(height: 12),
        _meta(Icons.schedule, _scheduleName(x.schedule)),
        if (x.rotationLengthDays != null) _meta(Icons.autorenew, 'Вахта: ${x.rotationLengthDays} дней'),
        _meta(Icons.payments_outlined, 'З/п: ${x.salaryText} ${_period(x.salaryPeriod)}'),
        _meta(Icons.receipt_long_outlined, x.taxMode == 'net' ? 'На руки' : 'До вычета'),
        _meta(Icons.calendar_month_outlined, _payout(x.payoutFrequency)),
        if (x.addresses.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Адреса', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...x.addresses.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.place_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text(a)),
            ]),
          )),
        ],
        const SizedBox(height: 24),
        // Для вакансий — показываем телефон сразу
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.phone_outlined),
          label: Text(x.phone.isNotEmpty ? x.phone : 'Телефон не указан'),
        ),
      ],
    );
  }

  Widget _meta(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(i, size: 18, color: Colors.black54),
      const SizedBox(width: 8),
      Expanded(child: Text(t)),
    ]),
  );

  String _scheduleName(String v) => const {
    'day': 'Дневные',
    'night': 'Ночные',
    'shift': 'Сменный',
    'rotational': 'Вахта',
    'flexible': 'Гибкий',
    'fixed': 'Фиксированный',
  }[v] ?? v;

  String _period(String v) => const {
    'month': '/мес',
    'week': '/нед',
    'day': '/день',
    'hour': '/час',
    'per_shift': '/смену',
  }[v] ?? '';

  String _payout(String v) => const {
    'daily': 'Ежедневно',
    'weekly': 'Еженедельно',
    'twice_month': 'Два раза в месяц',
    'three_times_month': 'Три раза в месяц',
    'monthly': 'Ежемесячно',
    'per_shift': 'За смену',
    'per_hour': 'За час',
  }[v] ?? v;
}
