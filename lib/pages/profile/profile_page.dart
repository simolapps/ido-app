import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ido/api/wizard_api.dart';
import 'package:ido/pages/bids/templates_page.dart';
import 'package:ido/services/storage.dart';
import 'package:ido/theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final WizardApi _api =
      WizardApi('https://idoapi.tw1.ru', tokenProvider: () async => await Storage().accessToken);

  bool _loading = true;
  String? _error;

  int? _masterId;
  String? _phone;

  // Профильные поля
  String? _firstName;
  String? _lastName;
  String? _middleName;
  String? _avatarUrl;

  // Рейтинг (read-only)
  double _rating = 0.0;
  int _reviews = 0;

  // Баланс
  double _balance = 0;

  // Локальные флаги
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = Storage();
      final mid   = await s.masterId;
      final phone = await s.userPhone ?? '';
      final uname = await s.userName;

      Map<String, dynamic> prof = {};
      try {
        prof = await _api.meProfile();
      } catch (_) {}

      String? first  = (prof['first_name']  ?? prof['firstName']  ?? prof['first'] ?? '')?.toString();
      String? last   = (prof['last_name']   ?? prof['lastName']   ?? prof['last']  ?? '')?.toString();
      String? middle = (prof['middle_name'] ?? prof['middleName'] ?? prof['patronymic'] ?? '')?.toString();
      String? avatar = (prof['avatar_url']  ?? prof['avatar']     ?? '')?.toString();

      final rating  = (prof['rating'] as num?)?.toDouble() ?? 0.0;
      final reviews = (prof['reviews'] as num?)?.toInt() ?? (prof['reviews_count'] as num?)?.toInt() ?? 0;

      double balance = 0;
      if (mid != null) {
        try { balance = await _api.walletBalance(masterId: mid); } catch (_) {}
      }

      // Fallback из локального имени
      final local = (await s.profileName) ?? uname ?? '';
      final localFirst = local.split(' ').skip(1).join(' ').trim();
      final localLast  = local.split(' ').first.trim();

      setState(() {
        _masterId   = mid;
        _phone      = phone;

        _firstName  = (first  != null && first.isNotEmpty)  ? first  : (localFirst.isNotEmpty ? localFirst : null);
        _lastName   = (last   != null && last.isNotEmpty)   ? last   : (localLast.isNotEmpty  ? localLast  : null);
        _middleName = (middle != null && middle.isNotEmpty) ? middle : null;
        _avatarUrl  = (avatar != null && avatar.isNotEmpty) ? avatar : null;

        _rating  = rating;
        _reviews = reviews;
        _balance = balance;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _fullName {
    final parts = [
      if ((_lastName ?? '').trim().isNotEmpty) _lastName!.trim(),
      if ((_firstName ?? '').trim().isNotEmpty) _firstName!.trim(),
      if ((_middleName ?? '').trim().isNotEmpty) _middleName!.trim(),
    ];
    return parts.isEmpty ? 'Пользователь' : parts.join(' ');
  }

  Future<void> _editName() async {
    final lastC   = TextEditingController(text: _lastName ?? '');
    final firstC  = TextEditingController(text: _firstName ?? '');
    final middleC = TextEditingController(text: _middleName ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom + 16;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 44, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999))),
              const Text('Редактировать ФИО', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(controller: lastC, decoration: const InputDecoration(labelText: 'Фамилия')),
              const SizedBox(height: 8),
              TextField(controller: firstC, decoration: const InputDecoration(labelText: 'Имя')),
              const SizedBox(height: 8),
              TextField(controller: middleC, decoration: const InputDecoration(labelText: 'Отчество (необязательно)')),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      setState(() => _saving = true);
      try {
        await _api.updateProfile(
          firstName: firstC.text.trim().isEmpty ? null : firstC.text.trim(),
          lastName:  lastC.text.trim().isEmpty  ? null : lastC.text.trim(),
          middleName:middleC.text.trim().isEmpty? null : middleC.text.trim(),
        );
        // локально
        setState(() {
          _firstName  = firstC.text.trim().isEmpty ? _firstName  : firstC.text.trim();
          _lastName   = lastC.text.trim().isEmpty  ? _lastName   : lastC.text.trim();
          _middleName = middleC.text.trim().isEmpty? ''          : middleC.text.trim();
        });
        await Storage().setProfileName(_fullName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 92);
    if (x == null) return;
    setState(() => _saving = true);
    try {
      final file = File(x.path);
      final url = await _api.uploadImage(file, folder: 'avatars');
      await _api.updateProfile(avatarUrl: url);
      setState(() => _avatarUrl = url);
      await Storage().setUserAvatar(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото обновлено')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openTemplates() {
    final mid = _masterId;
    if (mid == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TemplatesPage(api: _api, masterId: mid)));
  }

  Future<void> _copyToken() async {
    final tok = await Storage().accessToken;
    if (tok == null || tok.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Токен не найден. Войдите заново.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: tok));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access-токен скопирован')));
  }

  Future<void> _logout() async {
    await Storage().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/register', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _card(
        title: 'Профиль',
        trailing: IconButton(
          onPressed: _editName,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Редактировать ФИО',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.black12,
                    backgroundImage: (_avatarUrl?.isNotEmpty ?? false) ? NetworkImage(_avatarUrl!) : null,
                    child: (_avatarUrl?.isNotEmpty ?? false) ? null : const Icon(Icons.person, size: 34),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: InkWell(
                      onTap: _pickAvatar,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.indigo900,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [BoxShadow(color: AppColors.indigo900.withOpacity(.25), blurRadius: 8)],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.photo_camera_outlined, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(_phone ?? '', style: const TextStyle(color: Colors.black54)),
                    if (_masterId != null)
                      const SizedBox(height: 2),
                    if (_masterId != null)
                      Text('ID: ${_masterId}', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ..._buildStars(_rating),
                        const SizedBox(width: 8),
                        Text(
                          _rating > 0 ? '${_rating.toStringAsFixed(1)} • $_reviews' : 'Нет отзывов',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _openTemplates,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Шаблоны откликов'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _copyToken,
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Копировать токен'),
                ),
              ],
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
      _card(
        title: 'Кошелёк',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const LinearProgressIndicator(minHeight: 3)
            else if (_error != null)
              Text('Ошибка: $_error', style: const TextStyle(color: Colors.red))
            else
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatMoney(_balance.round())} ₽',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пополнение кошелька скоро будет доступно')),
                    ),
                    child: const Text('Пополнить'),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            const Text(
              'Комиссия за отклик списывается автоматически при отправке отклика.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
      _card(
        title: 'Отладка',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String?>(
              future: Storage().accessToken,
              builder: (_, snap) {
                final tok = snap.data ?? '';
                final prefix = tok.isEmpty ? '—' : tok.substring(0, math.min(tok.length, 24));
                return Text('Access (prefix): $prefix');
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Обновить')),
                const Spacer(),
                TextButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Выйти')),
              ],
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => items[i],
        ),
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    const total = 5;
    final full = rating.floor().clamp(0, total).toInt();
    final frac = rating - full;
    final half = frac >= 0.25 && frac < 0.75;
    final extraFull = frac >= 0.75 ? 1 : 0;
    final filled = (full + extraFull).clamp(0, total).toInt();

    final stars = <Widget>[];
    for (int i = 0; i < total; i++) {
      if (i < full) {
        stars.add(const Icon(Icons.star_rounded, color: Colors.amber, size: 20));
      } else if (i == full && half) {
        stars.add(const Icon(Icons.star_half_rounded, color: Colors.amber, size: 20));
      } else if (i < filled) {
        stars.add(const Icon(Icons.star_rounded, color: Colors.amber, size: 20));
      } else {
        stars.add(const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 20));
      }
    }
    return stars;
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              if (trailing != null) trailing,
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  String _formatMoney(int v) {
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
