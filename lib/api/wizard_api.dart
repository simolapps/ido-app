// === file: lib/api/wizard_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/wizard_flow.dart';
import '../models/job_draft.dart';
import '../models/bid_template.dart';

/// Публичные чтения (деталка/лента)
class Api {
  static const String _base = 'https://idoapi.tw1.ru';

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final r = await http.get(uri, headers: {'Accept': 'application/json'});
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
    dynamic parsed;
    try {
      parsed = json.decode(r.body);
    } catch (_) {
      throw Exception('bad_json');
    }
    if (parsed is! Map<String, dynamic>) {
      throw Exception('bad_json_shape');
    }
    return parsed;
  }

  /// Детальная по заданию
  static Future<Map<String, dynamic>> jobById(int id) async {
    final uri = Uri.parse('$_base/jobs/view.php').replace(queryParameters: {'id': '$id'});
    final data = await _getJson(uri);
    if (data['ok'] != true || data['item'] == null) {
      throw Exception(data['error'] ?? 'not_found');
    }
    return Map<String, dynamic>.from(data['item']);
  }

  /// Детальная по вакансии
  static Future<Map<String, dynamic>> vacancyById(int id) async {
    final uri = Uri.parse('$_base/vacancies/view.php').replace(queryParameters: {'id': '$id'});
    final data = await _getJson(uri);
    if (data['ok'] != true || data['item'] == null) {
      throw Exception(data['error'] ?? 'not_found');
    }
    return Map<String, dynamic>.from(data['item']);
  }

  /// Лента заданий
  static Future<Map<String, dynamic>> jobsList({int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$_base/jobs/index.php').replace(queryParameters: {
      'status': '1',
      'limit': '$limit',
      'offset': '$offset',
    });
    return await _getJson(uri);
  }

  /// Лента вакансий
  static Future<Map<String, dynamic>> vacanciesList({int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$_base/vacancies/index.php').replace(queryParameters: {
      'status': '1',
      'limit': '$limit',
      'offset': '$offset',
    });
    return await _getJson(uri);
  }
}

/// Клиент мастера + шаблоны + кошелёк/мои задания/отклики
class WizardApi {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// Если нужна авторизация — пробрось токен-провайдер.
  /// Токен добавится в заголовок как `Authorization: Bearer <token>`.
  final Future<String?> Function()? tokenProvider;

  WizardApi(
    String baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.tokenProvider,
  })  : baseUrl = _normalizeBase(baseUrl),
        _client = client ?? http.Client();

  /// Получить динамический флоу под выбранную подкатегорию
  Future<WizardFlow> fetchFlowBySubcategoryId(int subcategoryId) async {
    final map = await _get(
      '/wizard/flow.php',
      query: {'subcategory_id': subcategoryId.toString()},
    );
    _ensureOk(map);
    return WizardFlow.fromJson(Map<String, dynamic>.from(map));
  }

  /// Сохранить черновик (jobs)
  Future<void> saveDraft(JobDraft draft) async {
    final map = await _post('/jobs/save_draft.php', body: draft.toJson());
    _ensureOk(map);
  }

  /// Опубликовать задание (jobs)
  Future<void> publishJob(JobDraft draft) async {
    final map = await _post('/jobs/publish.php', body: draft.toJson());
    _ensureOk(map);
  }

  /// Удалить/сбросить черновик (jobs)
  Future<void> deleteDraft(JobDraft draft) async {
    final map = await _post('/jobs/delete_draft.php', body: draft.toJson());
    _ensureOk(map);
  }

  // ======== ШАБЛОНЫ ОТКЛИКОВ ========

  /// Список шаблонов (masterId обязателен, пока нет токена)
  Future<List<BidTemplate>> templatesList({
    required int masterId,
    int limit = 100,
    int offset = 0,
  }) async {
    final q = <String, String>{
      'master_id': '$masterId',
      'limit': '$limit',
      'offset': '$offset',
    };
    final map = await _get('/templates/index.php', query: q);
    _ensureOk(map);
    final items = (map['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => BidTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return items;
  }

  /// Создать шаблон
  Future<int> templateCreate(BidTemplate t) async {
    final map = await _post('/templates/create.php', body: {
      'master_id': t.masterId,
      'title': t.title,
      'body': t.body,
      'price_suggest': t.priceSuggest,
      'is_default': t.isDefault ? 1 : 0,
    });
    _ensureOk(map);
    return (map['id'] as num).toInt();
  }

  /// Обновить шаблон
  Future<void> templateUpdate({
    required int id,
    required int masterId,
    String? title,
    String? body,
    int? priceSuggest,
    bool? isDefault,
  }) async {
    final map = await _post('/templates/update.php', body: {
      'master_id': masterId,
      'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (priceSuggest != null) 'price_suggest': priceSuggest,
      if (isDefault != null) 'is_default': isDefault ? 1 : 0,
    });
    _ensureOk(map);
  }

  /// Удалить шаблон
  Future<void> templateDelete({
    required int id,
    required int masterId,
  }) async {
    final map = await _post('/templates/delete.php', body: {
      'master_id': masterId,
      'id': id,
    });
    _ensureOk(map);
  }

  // ======== Мои задания / кошелёк / отклики ========

  /// Кошелёк пользователя (по master_id)
  Future<double> walletBalance({required int masterId}) async {
    final map = await _get('/wallet/balance.php', query: {'master_id': '$masterId'});
    _ensureOk(map);
    return (map['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Списки моих заданий (по роли и статусу)
  /// role: executor|customer, status: active|cancelled|archived
  Future<List<Map<String, dynamic>>> myJobsRaw({
    required String role,
    required String status,
    required int masterId,
    int limit = 50,
    int offset = 0,
  }) async {
    final q = <String, String>{
      'role': role,
      'status': status,
      'master_id': '$masterId',
      'limit': '$limit',
      'offset': '$offset',
    };
    final map = await _get('/me/jobs.php', query: q);
    _ensureOk(map);
    return (map['items'] as List? ?? const [])
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Отклики на задание (видны заказчику)
  Future<List<Map<String, dynamic>>> bidsForJob({required int jobId}) async {
    final map = await _get('/bids/index.php', query: {'job_id': '$jobId'});
    _ensureOk(map);
    return (map['items'] as List? ?? const [])
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // ======== ПРОФИЛЬ (по токену) ========

  /// Профиль текущего пользователя (по токену)
  Future<Map<String, dynamic>> meProfile() async {
    final map = await _get('/me/profile.php');
    _ensureOk(map);
    final item = (map['item'] as Map?) ?? const {};
    return Map<String, dynamic>.from(item);
  }

  /// Обновление полей профиля (любое подмножество)
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? middleName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (middleName != null) 'middle_name': middleName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    final map = await _post('/me/profile.php', body: body);
    _ensureOk(map);
  }

  /// Загрузка изображения на сервер. Возвращает публичный URL
  Future<String> uploadImage(File file, {String folder = 'avatars'}) async {
    final uri = Uri.parse('$baseUrl/uploads/upload_image.php');
    final headers = await _buildHeaders(acceptJson: true);

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', _extToMime(file.path)),
        filename: file.path.split('/').last,
      ));

    http.StreamedResponse streamed;
    try {
      streamed = await req.send().timeout(timeout);
    } catch (e) {
      throw Exception('Network error: $e');
    }
    final res = await http.Response.fromStream(streamed);
    final map = _decodeJsonOrThrow(res);
    _ensureOk(map);
    final url = (map['url'] ?? map['path'] ?? map['location'] ?? '') as String;
    if (url.isEmpty) throw Exception('no_url_in_response');
    return url;
  }

  String _extToMime(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'heic';
    return 'jpeg';
  }

  // ======== Базовые HTTP-утилиты ========

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = await _buildHeaders(acceptJson: true);
    http.Response res;
    try {
      res = await _client.get(uri, headers: headers).timeout(timeout);
    } catch (e) {
      throw Exception('Network error: $e');
    }
    return _decodeJsonOrThrow(res);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(acceptJson: true, sendJson: true);
    http.Response res;
    try {
      res = await _client.post(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
    } catch (e) {
      throw Exception('Network error: $e');
    }
    return _decodeJsonOrThrow(res);
  }

  Future<Map<String, String>> _buildHeaders({
    bool acceptJson = false,
    bool sendJson = false,
  }) async {
    final h = <String, String>{};
    if (acceptJson) h['Accept'] = 'application/json';
    if (sendJson) h['Content-Type'] = 'application/json; charset=utf-8';
    if (tokenProvider != null) {
      final tok = await tokenProvider!.call();
      if (tok != null && tok.isNotEmpty) {
        h['Authorization'] = 'Bearer $tok';
      }
    }
    return h;
  }

  Map<String, dynamic> _decodeJsonOrThrow(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    dynamic parsed;
    try {
      parsed = json.decode(res.body);
    } catch (_) {
      throw Exception('bad_json: ${res.body}');
    }
    if (parsed is! Map) {
      throw Exception('bad_json_shape');
    }
    return Map<String, dynamic>.from(parsed);
  }

  // lib/api/wizard_api.dart

  Future<Map<String, dynamic>> _postForm(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(acceptJson: true);
    final form = body.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              ...headers,
              'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            },
            body: form,
          )
          .timeout(timeout);
    } catch (e) {
      throw Exception('Network error: $e');
    }
    return _decodeJsonOrThrow(res);
  }

  // sendBid — используем _postForm !
  Future<int> sendBid({
    required int jobId,
    required int masterId,
    required String message,
    required int offeredAmount,
    bool useEscrow = false,
    int? templateId,
  }) async {
    final body = <String, dynamic>{
      'job_id': jobId,
      // executor_master_id можешь не слать, если бэк берёт uid из токена.
      // Если токенов нет — можно слать:
      'executor_master_id': masterId,
      'message': message,
      'offered_amount': offeredAmount,
      'use_escrow': useEscrow ? 1 : 0,
      if (templateId != null) 'template_id': templateId,
    };
    final map = await _postForm('/bids/create.php', body: body);
    _ensureOk(map);
    // если бэк не отдаёт id — вернём 0
    return (map['id'] as num?)?.toInt() ?? 0;
  }

  /// (alias) Старое имя метода — для обратной совместимости с экранами.
  Future<int> createBid({
    required int jobId,
    required int masterId,
    required String message,
    required int offeredAmount,
    bool useEscrow = false,
    int? templateId,
  }) {
    return sendBid(
      jobId: jobId,
      masterId: masterId,
      message: message,
      offeredAmount: offeredAmount,
      useEscrow: useEscrow,
      templateId: templateId,
    );
  }

  void _ensureOk(Map<String, dynamic> map) {
    if (map['ok'] != true) {
      final err = map['error'] ?? 'unknown';
      throw Exception('API error: $err');
    }
  }

  static String _normalizeBase(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
