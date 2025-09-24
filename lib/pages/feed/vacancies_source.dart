import 'package:flutter/material.dart';
import 'feed_row.dart';
import 'feed_source.dart';
import '../../models/vacancy_item.dart';
import '../vacancies/vacancy_details_page.dart';

class VacanciesSource extends FeedSource {
  @override
  String get path => 'vacancies/index.php';

  @override
  FeedRow mapItem(Map<String, dynamic> j) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v.replaceAll(' ', ''));
      return null;
    }

    String salary(Map<String, dynamic> j) {
      final f = toInt(j['salary_from']);
      final t = toInt(j['salary_to']);
      final per = (j['salary_period'] ?? 'month').toString();
      final perText = switch (per) {
        'hour' => '/час',
        'day' => '/день',
        'week' => '/нед',
        'per_shift' => '/смену',
        _ => '/мес',
      };
      if (f == null && t == null) return 'З/п не указана';
      if (f != null && t != null) return '$f–$t ₽ $perText';
      if (f != null) return 'от $f ₽ $perText';
      return 'до $t ₽ $perText';
    }

    String meta(Map<String, dynamic> j) {
      final parts = <String>[];
      const m = {
        'day':'Дневные','night':'Ночные','shift':'Сменный','rotational':'Вахта',
        'flexible':'Гибкий','fixed':'Фиксированный'
      };
      final sch = (j['schedule'] ?? '').toString();
      if (m[sch] != null) parts.add(m[sch]!);

      final addrs = j['addresses'] ?? j['work_addresses'];
      if (addrs is List && addrs.isNotEmpty) {
        final first = addrs.first;
        final text = (first is Map) ? (first['address_text']?.toString() ?? '') : first.toString();
        if (text.isNotEmpty) parts.add(text);
      }
      return parts.join(' • ');
    }

    return FeedRow(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      description: ((j['description'] ?? '').toString().trim().isEmpty) ? null : j['description'].toString(),
      meta: meta(j),
      amountText: salary(j),
      iconKey: null, // у вакансий своей иконки нет
      color: null,
      // payload можно прокинуть, если хочешь не перезагружать детали
      // payload: j,
    );
  }

  @override
  void openDetails(BuildContext context, FeedRow row) {
    // Детали вакансии: показываем телефон
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VacancyDetailsPage(vacancyId: row.id, titleHint: row.title)),
    );
  }
}
