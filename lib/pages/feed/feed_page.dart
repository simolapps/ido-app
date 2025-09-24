// lib/pages/feed/feed_page.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../api/wizard_api.dart';
import 'feed_row.dart';
import 'feed_source.dart';
import 'jobs_source.dart';
import 'vacancies_source.dart';

const _API = 'https://idoapi.tw1.ru/';

enum FeedTab { gigs, vacancies }

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // === настройки карточек/отступов ===
  static const double _cardHeight = 130;
  static const double _hPad = 12;
  static const double _bottomGap = 16; // небольшой отступ снизу списка

  final _scroll = ScrollController();
  final List<FeedRow> _items = [];

  WizardApi? _wizardApi;
  int? _masterId;              // ← берём из SharedPreferences
  Map<FeedTab, FeedSource>? _sources;

  bool _authLoading = true;    // загрузка master_id
  String? _authError;

  bool _loadingList = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _error;

  FeedTab _tab = FeedTab.gigs;

  @override
  void initState() {
    super.initState();
    _initAuthAndSources();
    _scroll.addListener(_onScroll);
  }

  Future<void> _initAuthAndSources() async {
    setState(() { _authLoading = true; _authError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final mid = prefs.getInt('user_id'); // ← сохраняется в RegisterPage
      if (mid == null || mid <= 0) {
        _masterId = null;
      } else {
        _masterId = mid;
        _wizardApi = WizardApi('https://idoapi.tw1.ru');
        _sources = {
          FeedTab.gigs: JobsSource(api: _wizardApi!, masterId: _masterId!), // ← ничего не хардкодим
          FeedTab.vacancies: VacanciesSource(),
        };
        // подтягиваем первую страницу сразу после инициализации
        await _load(reset: true);
      }
    } catch (e) {
      _authError = e.toString();
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _log(Object? m) { if (kDebugMode) debugPrint('[Feed] $m'); }

  String _endpointForTab(FeedTab t) =>
      t == FeedTab.gigs ? 'jobs/index.php' : 'vacancies/index.php';

  Future<void> _load({bool reset = false}) async {
    // если источники ещё не готовы (нет masterId) — не грузим
    if (_sources == null) return;

    if (_loadingList || _loadingMore) return;

    if (reset) {
      setState(() {
        _loadingList = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
        _items.clear();
      });
    } else {
      if (!_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final src = _sources![_tab]!;
      final uri = Uri.parse('$_API${_endpointForTab(_tab)}')
          .replace(queryParameters: {'limit': '$_limit', 'offset': '$_offset'});
      _log('GET $uri');

      final r = await http.get(uri, headers: {'Accept': 'application/json'});
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');

      final map = json.decode(r.body) as Map<String, dynamic>;
      final list = (map['items'] as List?) ?? const [];
      final page = list.cast<Map<String, dynamic>>().map(src.mapItem).toList();

      setState(() {
        _items.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _limit;
      });
    } catch (e, st) {
      _log('ERROR: $e\n$st');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _load(reset: false);
    }
  }

  Future<void> _refresh() => _load(reset: true);

  void _switchTab(FeedTab t) {
    if (_tab == t) return;
    setState(() => _tab = t);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    // состояние авторизации / готовности источников
    if (_authLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_authError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Ошибка инициализации: $_authError',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _initAuthAndSources,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_sources == null || _masterId == null) {
      // Пользователь не авторизован — предлагаем перейти на регистрацию/логин
      return Scaffold(
        appBar: AppBar(title: const Text('Лента')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Чтобы видеть задания и откликаться, войдите или зарегистрируйтесь.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                  child: const Text('Войти / Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bg = _tab == FeedTab.gigs ? const Color(0xFFF2F4F7) : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // переключатель
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: CupertinoSlidingSegmentedControl<FeedTab>(
                groupValue: _tab,
                backgroundColor: Colors.transparent,
                thumbColor: _tab == FeedTab.gigs ? AppColors.primary : AppColors.vacancy,
                children: const {
                  FeedTab.gigs: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text('Разовые задачи',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                  FeedTab.vacancies: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text('Вакансии',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                },
                onValueChanged: (t) { if (t != null) _switchTab(t); },
              ),
            ),
            // счётчик
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'items: ${_items.length}${_loadingList ? ' (loading)' : ''}',
                style: TextStyle(
                    color: _tab == FeedTab.gigs ? Colors.black54 : Colors.white70, fontSize: 12),
              ),
            ),
            // список
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _buildList(bg: bg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== LIST ======
  Widget _buildList({required Color bg}) {
    final bottomPad = _bottomGap + MediaQuery.of(context).padding.bottom;

    if (_loadingList && _items.isEmpty) {
      return ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(_hPad, 8, _hPad, bottomPad),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => _SkeletonCard(height: _cardHeight),
      );
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPad),
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 42),
          const SizedBox(height: 12),
          Text('Не удалось загрузить.\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: _tab == FeedTab.gigs ? Colors.black54 : Colors.white70)),
          const SizedBox(height: 12),
          Center(child: OutlinedButton(onPressed: () => _load(reset: true), child: const Text('Повторить'))),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPad),
        children: [
          Text(
            _tab == FeedTab.gigs ? 'Заданий пока нет' : 'Вакансий пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(color: _tab == FeedTab.gigs ? Colors.black45 : Colors.white70),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(_hPad, 8, _hPad, bottomPad),
      itemCount: _items.length + 1,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == _items.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return const SizedBox.shrink();
        }
        final row = _items[i];

        return SizedBox(
          height: _cardHeight, // одинаковая высота для всех карточек
          child: _FeedCard(
            row: row,
            onTap: row.onTap ?? () => _sources![_tab]!.openDetails(context, row),
          ),
        );
    });
  }
}

/// Карточка строки ленты с фиксированной высотой.
/// 2 строки заголовка, 2 строки сниппета, внизу meta + бюджет.
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.row, this.onTap});
  final FeedRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = row.color ?? const Color(0xFF9CA3AF);
    final icon = _iconForKey(row.iconKey);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.35), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // слева значок
              Container(
                width: 36,
                height: double.infinity,
                alignment: Alignment.topCenter,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 10),

              // контент карточки
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // заголовок
                    Text(
                      row.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // несколько слов из описания
                    Text(
                      _snippet(row.description, maxWords: 12, maxChars: 90),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: (row.description == null || row.description!.isEmpty)
                            ? Colors.black38
                            : Colors.black54,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // низ: meta и бюджет
                    if ((row.meta ?? '').isNotEmpty)
                      Text(
                        row.meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            row.amountText ?? 'Бюджет не указан',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForKey(String? key) {
    switch (key) {
      case 'courier': return Icons.delivery_dining_outlined;
      case 'construction': return Icons.handyman_outlined;
      case 'moving_truck': return Icons.local_shipping_outlined;
      case 'home_cleaning': return Icons.cleaning_services_outlined;
      case 'computer_help': return Icons.computer_outlined;
      case 'photo_video': return Icons.photo_camera_back_outlined;
      case 'software_dev': return Icons.code_outlined;
      case 'appliance_repair': return Icons.build_outlined;
      case 'events': return Icons.event_outlined;
      case 'design': return Icons.brush_outlined;
      case 'virtual_assistant': return Icons.support_agent_outlined;
      case 'electronics': return Icons.memory_outlined;
      case 'beauty': return Icons.face_retouching_natural_outlined;
      case 'legal': return Icons.gavel_outlined;
      case 'transport_repair': return Icons.car_repair_outlined;
      case 'tutoring': return Icons.school_outlined;
      default: return Icons.category_outlined;
    }
  }

  // Без ручного «…» — многоточие добавит TextOverflow.ellipsis
  static String _snippet(String? text, {int maxWords = 12, int maxChars = 90}) {
    final s = text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (s.isEmpty) return 'Описание не указано';
    final words = s.split(' ');
    var cut = words.take(maxWords).join(' ');
    if (cut.length > maxChars) {
      cut = cut.substring(0, maxChars).trimRight();
    }
    return cut;
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Container(height: 14, color: Colors.black12),
                  const SizedBox(height: 6),
                  Container(height: 12, color: Colors.black12),
                  const Spacer(),
                  Container(height: 10, color: Colors.black12),
                  const SizedBox(height: 6),
                  Container(height: 12, color: Colors.black12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
