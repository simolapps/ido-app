// lib/services/vacancy_suggest_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Простой элемент подсказки (id + отображаемое имя).
class SuggestItem {
  final int id;
  final String name;
  final String? slug;
  final int? usageCount;

  const SuggestItem({
    required this.id,
    required this.name,
    this.slug,
    this.usageCount,
  });

  factory SuggestItem.fromJson(Map<String, dynamic> j) => SuggestItem(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        slug: j['slug'] as String?,
        usageCount: j['usage_count'] is num ? (j['usage_count'] as num).toInt() : null,
      );
}

/// Клиент для таксономии вакансий: отрасли и профессии.
///
/// baseUrl ожидается вида: `https://idoapi.tw1.ru/taxonomy`
/// Эндпоинты:
///  - GET {base}/industries/get.php
///  - GET {base}/professions/get.php
///  - POST {base}/track_pick.php   (опционально)
class VacancySuggestApi {
  final String baseUrl;
  final Duration timeout;

  VacancySuggestApi(
    String baseUrl, {
    this.timeout = const Duration(seconds: 8),
  }) : baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  String get _industriesUrl  => '$baseUrl/industries/get.php';
  String get _professionsUrl => '$baseUrl/professions/get.php';
  String get _trackPickUrl   => '$baseUrl/track_pick.php';

  /// Подсказки «Вид деятельности компании».
  Future<List<SuggestItem>> industries(
    String query, {
    int limit = 20,
    int offset = 0,
    String locale = 'ru',
    String order = 'popular', // popular|alpha|recent
  }) async {
    final uri = Uri.parse(_industriesUrl).replace(queryParameters: {
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
      'locale': locale,
      'order': order,
    });

    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body);
    final List items = (data is Map && data['items'] is List) ? data['items'] as List : const [];
    return items
        .whereType<Map>()
        .map((e) => SuggestItem.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  /// Подсказки «Профессия».
  Future<List<SuggestItem>> professions(
    String query, {
    int limit = 20,
    int offset = 0,
    String locale = 'ru',
    String order = 'popular',
  }) async {
    final uri = Uri.parse(_professionsUrl).replace(queryParameters: {
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
      'locale': locale,
      'order': order,
    });

    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body);
    final List items = (data is Map && data['items'] is List) ? data['items'] as List : const [];
    return items
        .whereType<Map>()
        .map((e) => SuggestItem.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  /// (Опционально) сообщаем серверу, что пользователь выбрал элемент.
  /// type = 'industry' | 'profession'
  Future<bool> trackPick({required String type, required int id}) async {
    try {
      final res = await http
          .post(Uri.parse(_trackPickUrl), body: {'type': type, 'id': '$id'})
          .timeout(timeout);
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      return (data is Map && data['ok'] == true);
    } catch (_) {
      return false;
    }
  }
}
