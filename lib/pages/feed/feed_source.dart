// feed_source.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'feed_row.dart';

abstract class FeedSource {
  /// Путь к списку (без домена)
  String get path;

  /// Маппинг JSON-объекта в элемент фида
  FeedRow mapItem(Map<String, dynamic> j);

  /// Загрузка страницы данных
  Future<List<FeedRow>> load({
    required Uri base,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = base.resolve('$path?limit=$limit&offset=$offset');
    final r = await http.get(uri, headers: {'Accept': 'application/json'});
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}');
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (map['items'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(mapItem).toList();
  }

  /// Открыть экран деталей для выбранной строки
  void openDetails(BuildContext context, FeedRow row);
}
