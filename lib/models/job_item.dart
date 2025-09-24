import 'package:flutter/material.dart';
import '../pages/feed/feed_row.dart';

class JobItem {
  final int id;
  final String title;
  final String? description;

  // старые поля
  final int? budget;             // в рублях
  final String? priceType;       // 'fixed'|'hourly'|'0'|'1'
  final bool isRemote;
  final String? cityName;
  final String? addressText;

  final DateTime? dueDate;
  final DateTime? createdAt;

  final String? categoryName;
  final String? subcategoryName;

  final String? iconKey;         // из БД
  final Color? color;            // цвет категории

  // новое (для удобного отображения)
  final String? amountText;      // «до 8 500 ₽», «1000 ₽ / час» и т.п.
  final String? meta;            // «Удалённо • Город • до ММ-ДД»
  final List<String> photoUrls;  // media[].url

  // customer
  final String? customerName;          // customer.display_name
  final String? customerAvatarUrl;     // customer.avatar_url
  final int? customerReviewsCount;     // customer.reviews_count
  final double? customerRating;        // customer.rating
  final DateTime? customerLastSeenAt;  // customer.last_seen_at

  JobItem({
    required this.id,
    required this.title,
    this.description,
    this.budget,
    this.priceType,
    this.isRemote = true,
    this.cityName,
    this.addressText,
    this.dueDate,
    this.createdAt,
    this.categoryName,
    this.subcategoryName,
    this.iconKey,
    this.color,
    // новое
    this.amountText,
    this.meta,
    this.photoUrls = const [],
    // customer
    this.customerName,
    this.customerAvatarUrl,
    this.customerReviewsCount,
    this.customerRating,
    this.customerLastSeenAt,
  });

  // ===== Helpers =====
  static int? _money(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final n = num.tryParse(v.replaceAll(',', '.'));
      return n?.round();
    }
    return null;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  static Color? _hex(dynamic raw) {
    final s0 = (raw ?? '').toString().trim();
    if (s0.isEmpty) return null;
    var s = s0.startsWith('#') ? s0.substring(1) : s0;
    s = s.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }

  static String _fmtInt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i - 1;
      b.write(s[i]);
      if (posFromEnd % 3 == 0 && i != s.length - 1) b.write(' ');
    }
    return b.toString();
  }

  static String _amountText(dynamic budget, dynamic priceType) {
    final b = _money(budget);
    if (b == null) return 'Бюджет не указан';
    final hourly = (priceType?.toString() == 'hourly' || priceType?.toString() == '1');
    // для списков остаёмся при «N ₽[/час]», деталька покажет «до … ₽»
    return '${_fmtInt(b)} ₽${hourly ? ' / час' : ''}';
  }

  static String? _metaFrom(Map<String, dynamic> j) {
    final parts = <String>[];
    final isRemote = (j['is_remote']?.toString() == '1') || (j['is_remote'] == true);
    if (isRemote) parts.add('Удалённо');
    final city = (j['city_name'] ?? '').toString();
    if (city.isNotEmpty) parts.add(city);
    final due = (j['due_date'] ?? '').toString();
    if (due.isNotEmpty && due.length >= 10) parts.add('до ${due.substring(5, 10)}');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ===== Универсальная фабрика =====
  factory JobItem.fromJson(Map<String, dynamic> j) {
    final b = _money(j['budget_amount']);
    final pt = j['price_type']?.toString();

    final media = (j['media'] as List? ?? const [])
        .map((m) => (m is Map) ? (m['url']?.toString() ?? '') : m.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final cust = j['customer'] as Map? ?? const {};

    return JobItem(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      description: _s(j['description']),
      budget: b,
      priceType: pt,
      isRemote: (j['is_remote']?.toString() == '1') || (j['is_remote'] == true),
      cityName: _s(j['city_name']),
      addressText: _s(j['address_text']),
      dueDate: _date(j['due_date']),
      createdAt: _date(j['created_at']),
      categoryName: _s(j['category_name']),
      subcategoryName: _s(j['subcategory_name']),
      iconKey: _s(j['category_icon_key']),
      color: _hex(j['category_icon_color']),
      amountText: _amountText(b, pt),
      meta: _metaFrom(j),
      photoUrls: media,
      customerName: _s(cust['display_name']),
      customerAvatarUrl: _s(cust['avatar_url']),
      customerReviewsCount: cust['reviews_count'] == null ? null : int.tryParse('${cust['reviews_count']}'),
      customerRating: cust['rating'] == null ? null : double.tryParse('${cust['rating']}'),
      customerLastSeenAt: _date(cust['last_seen_at']),
    );
  }

  // ===== Для списка (index.php) =====
  factory JobItem.fromListJson(Map<String, dynamic> j) {
    final b = _money(j['budget_amount']);
    final pt = j['price_type']?.toString();
    return JobItem(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      description: _s(j['description']),
      budget: b,
      priceType: pt,
      isRemote: (j['is_remote']?.toString() == '1') || (j['is_remote'] == true),
      cityName: _s(j['city_name']),
      addressText: _s(j['address_text']),
      dueDate: _date(j['due_date']),
      createdAt: _date(j['created_at']),
      categoryName: _s(j['category_name']),
      subcategoryName: _s(j['subcategory_name']),
      iconKey: _s(j['category_icon_key']),
      color: _hex(j['category_icon_color']),
      amountText: _amountText(b, pt),
      meta: _metaFrom(j),
      photoUrls: const [],
      customerName: null,
      customerAvatarUrl: null,
      customerReviewsCount: null,
      customerRating: null,
      customerLastSeenAt: null,
    );
  }

  // ===== Для детальной (view.php) =====
  factory JobItem.fromViewJson(Map<String, dynamic> j) => JobItem.fromJson(j);

  // ===== Удобные геттеры =====
  String get budgetText {
    if (budget == null) return 'Бюджет не указан';
    final s = '${_fmtInt(budget!)} ₽';
    return (priceType == 'hourly' || priceType == '1') ? '$s / час' : s;
  }
}
