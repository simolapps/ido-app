// jobs_source.dart
import 'package:flutter/material.dart';
import 'package:ido/api/wizard_api.dart';
import 'package:ido/models/job_item.dart';
import 'feed_row.dart';
import 'feed_source.dart';
import '../jobs/job_details_page.dart';

class JobsSource extends FeedSource {
  JobsSource({required this.api, required this.masterId});

  final WizardApi api;
  final int masterId;

  @override
  String get path => 'jobs/index.php';

  @override
  FeedRow mapItem(Map<String, dynamic> j) {
    int? _money(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) {
        final n = num.tryParse(v.replaceAll(',', '.'));
        return n?.round();
      }
      return null;
    }

    Color? _hex(dynamic raw) {
      final s0 = (raw ?? '').toString().trim();
      if (s0.isEmpty) return null;

      // поддержим 0xFFxxxxxx
      final ox = int.tryParse(s0);
      if (ox != null) return Color(ox);

      var s = s0.startsWith('#') ? s0.substring(1) : s0;
      s = s.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (s.length == 6) s = 'FF$s'; // RGB -> ARGB
      final v = int.tryParse(s, radix: 16);
      return v == null ? null : Color(v);
    }

    final budget = _money(j['budget_amount']);
    final priceType = j['price_type']?.toString(); // 'fixed'|'hourly'|'0'|'1'
    final amountText = budget == null
        ? 'Бюджет не указан'
        : '${budget} ₽${(priceType == 'hourly' || priceType == '1') ? ' / час' : ''}';

    final parts = <String>[];
    final isRemote = (j['is_remote']?.toString() == '1') || (j['is_remote'] == true);
    if (isRemote) parts.add('Удалённо');
    final city = (j['city_name'] ?? '').toString();
    if (city.isNotEmpty) parts.add(city);
    final due = (j['due_date'] ?? '').toString();
    if (due.isNotEmpty && due.length >= 10) parts.add('до ${due.substring(5, 10)}'); // мм-дд

    return FeedRow(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      description: ((j['description'] ?? '').toString().trim().isEmpty) ? null : j['description'].toString(),
      meta: parts.join(' • '),
      amountText: amountText,
      iconKey: j['category_icon_key']?.toString(),
      color: _hex(j['category_icon_color']),
    );
  }

  @override
  void openDetails(BuildContext context, FeedRow row) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final json = await Api.jobById(row.id);
      Navigator.of(context).pop(); // закрыть лоадер

      final job = JobItem.fromJson(json);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          wizardApi: api,      // ← передаём
          masterId: masterId,  // ← передаём
        ),
      ));
    } catch (e) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить задание: $e')),
      );
    }
  }
}
