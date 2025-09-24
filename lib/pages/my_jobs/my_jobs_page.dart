import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ido/pages/my_jobs/my_jobs_section_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/wizard_api.dart';
import '../../models/my_job_item.dart';
import '../../theme/app_colors.dart';
import '../jobs/job_details_page.dart';



enum MyRole { executor, customer }

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});
  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  MyRole _role = MyRole.executor;
  late final WizardApi _api;
  int? _masterId;
  bool _loading = true;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _api = WizardApi('https://idoapi.tw1.ru');
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    setState(() { _masterId = id; });
    if (id != null) {
      try {
        final bal = await _api.walletBalance(masterId: id);
        if (mounted) setState(() => _balance = bal);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Мои задания', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_masterId == null)
              ? const Center(child: Text('Авторизуйтесь, чтобы видеть свои задания'))
              : Column(
                  children: [
                    // Роли
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: CupertinoSlidingSegmentedControl<MyRole>(
                        groupValue: _role,
                        backgroundColor: Colors.white,
                        thumbColor: _role == MyRole.executor ? AppColors.freelance : AppColors.vacancy,
                        children: const {
                          MyRole.executor: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            child: Text('Я исполнитель', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          MyRole.customer: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            child: Text('Я заказчик', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        },
                        onValueChanged: (v) => setState(() => _role = v ?? MyRole.executor),
                      ),
                    ),
                    // Баланс
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text('Баланс: ${_balance.toStringAsFixed(2)} ₽'),
                          const Spacer(),
                          TextButton(
                            onPressed: () { /* пополнение позже */ },
                            child: const Text('Пополнить'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _sectionCard(
                            title: _role == MyRole.executor
                                ? 'Отменено или выбран другой исполнитель'
                                : 'Вы создали',
                            subtitle: _role == MyRole.executor ? 'В архиве' : 'Отменены',
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => MyJobsSectionList(
                                  api: _api,
                                  masterId: _masterId!,
                                  role: _role,
                                  status: _role == MyRole.executor ? 'archived' : 'cancelled',
                                ),
                              ));
                            },
                          ),
                          const SizedBox(height: 10),
                          _sectionCard(
                            title: 'Активные',
                            subtitle: _role == MyRole.executor ? 'Мои отклики/исполнение' : 'Ожидают исполнителя',
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => MyJobsSectionList(
                                  api: _api,
                                  masterId: _masterId!,
                                  role: _role,
                                  status: 'active',
                                ),
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _sectionCard({required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.white18,
          child: const Icon(Icons.folder_outlined, color: Colors.black54),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
