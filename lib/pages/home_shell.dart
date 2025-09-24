import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ido/api/wizard_api.dart';

// если у тебя другие пути — поправь ниже
import 'package:ido/create_job/create_job_wizard.dart';
import 'package:ido/create_job/create_vacancy_wizard.dart';
import 'package:ido/pages/feed/feed_page.dart';
import 'package:ido/pages/my_jobs/my_jobs_page.dart';
import 'package:ido/services/storage.dart';
import '../theme/app_colors.dart';
import 'package:ido/pages/profile/profile_page.dart';
import 'package:http/http.dart' as http;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  late final List<Widget> _pages = const <Widget>[
    FeedPage(),
    PostPage(),
    MessagesPage(),
    MyJobsPage(),
    ProfilePage(),
  ];

  List<Widget> _navItems() => [
        Icon(Icons.list_alt, color: _idx == 0 ? Colors.white : Colors.white70),
        Icon(Icons.add_circle_outline, color: _idx == 1 ? Colors.white : Colors.white70),
        Icon(Icons.chat_bubble_outline, color: _idx == 2 ? Colors.white : Colors.white70),
        Icon(Icons.work_outline, color: _idx == 3 ? Colors.white : Colors.white70),
        Icon(Icons.person_outline, color: _idx == 4 ? Colors.white : Colors.white70),
      ];

  Future<bool> _onWillPop() async {
    if (_idx != 0) {
      setState(() => _idx = 0);
      return false;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из приложения?'),
        content: const Text('Вы уверены, что хотите закрыть приложение?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true, // контент под навбар
        body: SafeArea(
          bottom: false, // нижний отступ отдаём навбару
          child: IndexedStack(index: _idx, children: _pages),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.transparent,     // без белой подложки
          color: AppColors.indigo900,              // плашка
          buttonBackgroundColor: AppColors.emerald900, // «пузырь»
          height: 58,
          animationDuration: const Duration(milliseconds: 300),
          index: _idx,
          items: _navItems(),
          onTap: (i) => setState(() => _idx = i),
        ),
      ),
    );
  }
}

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'Что хотите разместить?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 14),

            // Разовая услуга (фриланс)
            _CreateTypeCard(
              tag: 'Фриланс / подработка',
              title: 'Разовая услуга',
              bullet1: 'Быстрый заказ с оплатой за результат',
              bullet2: 'Фото, сроки, бюджет — как в YouDo',
              icon: Icons.task_alt,
              gradient: AppColors.freelanceCard,
              accent: AppColors.freelance,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateJobWizard()),
              ),
            ),

            const SizedBox(height: 14),

            // Вакансия
            _CreateTypeCard(
              tag: 'Вакансия',
              title: 'Сотрудник в штат',
              bullet1: 'График, оклад, частота выплат',
              bullet2: 'Регион поиска и адреса работы',
              icon: Icons.business_center,
              gradient: AppColors.vacancyCard,
              accent: AppColors.vacancy,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateVacancyWizard()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTypeCard extends StatelessWidget {
  final String tag;
  final String title;
  final String bullet1;
  final String bullet2;
  final IconData icon;
  final Gradient gradient; // из AppColors
  final Color accent; // для тени и акцентов
  final VoidCallback onTap;

  const _CreateTypeCard({
    required this.tag,
    required this.title,
    required this.bullet1,
    required this.bullet2,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(.35), blurRadius: 22, offset: const Offset(0, 12)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white18,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tagPill(tag),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _bullet(bullet1),
                      const SizedBox(height: 4),
                      _bullet(bullet2),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white18,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Создать', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _bullet(String text) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Padding(
      padding: EdgeInsets.only(top: 2),
      child: Icon(Icons.check_circle_outline, size: 18, color: Colors.white70),
    ),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))), // ← текст теперь используется
  ],
);


  Widget _tagPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.white18, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: .2)),
      );
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _api = WizardApi('https://idoapi.tw1.ru',
      tokenProvider: () async => await Storage().accessToken);

  final _tokenC = TextEditingController();
  final _masterIdC = TextEditingController();
  String _log = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final tok = await Storage().accessToken ?? '';
    final mid = await Storage().masterId;
    setState(() {
      _tokenC.text = tok;
      _masterIdC.text = (mid ?? '').toString();
    });
  }

  void _appendLog(String s) => setState(() => _log = '${DateTime.now().toIso8601String()}  $s\n$_log');

  Future<void> _saveToken() async {
    await Storage().setAccessToken(_tokenC.text.trim());
    _appendLog('Token saved (prefix): ${_tokenC.text.isEmpty ? '—' : _tokenC.text.substring(0, _tokenC.text.length < 24 ? _tokenC.text.length : 24)}');
  }

  Future<void> _clearToken() async {
    await Storage().clearAccessToken();
    _tokenC.clear();
    _appendLog('Token cleared');
  }

  Future<void> _callPing() async {
    await _run(() async {
      final res = await _getRaw('/ping.php');
      _appendLog('GET /ping.php → $res');
    });
  }

  Future<void> _callProfile() async {
    await _run(() async {
      final map = await _api.meProfile();
      _appendLog('GET /me/profile.php → ${map.toString()}');
    });
  }

  Future<void> _callBalance() async {
    final midStr = _masterIdC.text.trim();
    final mid = int.tryParse(midStr);
    if (mid == null) {
      _appendLog('ERR: master_id не задан');
      return;
    }
    await _run(() async {
      final bal = await _api.walletBalance(masterId: mid);
      _appendLog('GET /wallet/balance.php?master_id=$mid → $bal');
    });
  }

  // универсальный GET (сырой json как строка)
  Future<String> _getRaw(String path) async {
    final uri = Uri.parse('https://idoapi.tw1.ru$path');
    final headers = <String, String>{'Accept': 'application/json'};
    final tok = await Storage().accessToken;
    if (tok != null && tok.isNotEmpty) headers['Authorization'] = 'Bearer $tok';
    final r = await http.get(uri, headers: headers);
    return 'HTTP ${r.statusCode} ${r.reasonPhrase}; body=${r.body}';
  }

  // пример «получить токен» (замени path/параметры под свой бэкенд)
  Future<void> _devGetToken() async {
    await _run(() async {
      // ПРИМЕР! ЗАМЕНИ на свой эндпоинт авторизации
      // final res = await _getRaw('/auth/dev_login.php?phone=79991234567');
      // имитация: просто запишем введённое как «токен»
      if (_tokenC.text.trim().isEmpty) {
        _appendLog('Введите токен вручную и нажмите Сохранить, или реализуйте dev_login запрос.');
      } else {
        await _saveToken();
      }
    });
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await fn(); } catch (e, st) { _appendLog('ERR: $e\n$st'); }
    finally { if(mounted) setState(() => _busy = false); }
  }

  @override
  void dispose() {
    _tokenC.dispose();
    _masterIdC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 194, 54, 54),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('API тестер', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _panel(
            'Токен',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tokenC,
                  decoration: const InputDecoration(
                    labelText: 'Bearer Token',
                    hintText: 'вставьте токен или получите ниже',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _saveToken,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Сохранить'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _clearToken,
                      icon: const Icon(Icons.clear),
                      label: const Text('Очистить'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _devGetToken,
                      icon: const Icon(Icons.login),
                      label: const Text('Получить токен (dev)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            'Быстрые запросы',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(onPressed: _busy ? null : _callPing, child: const Text('GET /ping')),
                    ElevatedButton(onPressed: _busy ? null : _callProfile, child: const Text('GET /me/profile')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _masterIdC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'master_id'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _callBalance,
                      child: const Text('GET /wallet/balance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            'Лог',
            Container(
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _log.isEmpty ? 'Здесь будут ответы запросов…' : _log,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}


