import 'package:flutter/material.dart';

class MyJobItem {
  final int id;
  final String title;
  final int? budget;
  final String? cityName;
  final bool isRemote;
  final String status; // active|cancelled|archived
  final String role;   // executor|customer
  final int bidsCount;
  final DateTime createdAt;
  final String? coverUrl; // первая фотка
  final Color? color;
  final String? priceType; // '0'|'1'|'fixed'|'hourly'

  MyJobItem({
    required this.id,
    required this.title,
    required this.status,
    required this.role,
    required this.createdAt,
    this.budget,
    this.cityName,
    this.isRemote = true,
    this.bidsCount = 0,
    this.coverUrl,
    this.color,
    this.priceType,
  });

  factory MyJobItem.fromJson(Map<String, dynamic> j) {
    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is double) return v.round();
      return null;
    }
    Color? _hex(dynamic raw) {
      final s0 = (raw ?? '').toString().trim();
      if (s0.isEmpty) return null;
      final ox = int.tryParse(s0);
      if (ox != null) return Color(ox);
      var s = s0.startsWith('#') ? s0.substring(1) : s0;
      s = s.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (s.length == 6) s = 'FF$s';
      final v = int.tryParse(s, radix: 16);
      return v == null ? null : Color(v);
    }

    return MyJobItem(
      id: _int(j['id']) ?? 0,
      title: (j['title'] ?? '').toString(),
      budget: _int(j['budget_amount']),
      cityName: (j['city_name'] ?? '').toString().isEmpty ? null : j['city_name'].toString(),
      isRemote: (j['is_remote']?.toString() == '1') || (j['is_remote'] == true),
      status: (j['status_text'] ?? j['status'] ?? 'active').toString(),
      role: (j['role'] ?? 'executor').toString(),
      bidsCount: _int(j['bids_count']) ?? 0,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
      coverUrl: (j['cover_url'] ?? '').toString().isEmpty ? null : j['cover_url'].toString(),
      color: _hex(j['category_icon_color']),
      priceType: j['price_type']?.toString(),
    );
  }

  String budgetText() {
    if (budget == null) return 'Бюджет не указан';
    final base = 'до ${_fmtMoney(budget!)} ₽';
    final hourly = (priceType == 'hourly' || priceType == '1');
    return hourly ? '$base / час' : base;
  }

  static String _fmtMoney(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i - 1;
      b.write(s[i]);
      if (posFromEnd % 3 == 0 && i != s.length - 1) b.write(' ');
    }
    return b.toString();
  }
}
