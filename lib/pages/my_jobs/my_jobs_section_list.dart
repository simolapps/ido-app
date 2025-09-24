import 'package:flutter/material.dart';
import 'package:ido/pages/my_jobs/my_jobs_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/wizard_api.dart';
import '../../models/my_job_item.dart';
import '../../theme/app_colors.dart';
import '../jobs/job_details_page.dart';
import '../my_jobs/view_bids_sheet.dart';

import '../../models/job_item.dart'; // для JobDetailsPage

class MyJobsSectionList extends StatefulWidget {
  final WizardApi api;
  final int masterId;
  final MyRole role;
  final String status; // active|cancelled|archived

  const MyJobsSectionList({
    super.key,
    required this.api,
    required this.masterId,
    required this.role,
    required this.status,
  });

  @override
  State<MyJobsSectionList> createState() => _MyJobsSectionListState();
}

class _MyJobsSectionListState extends State<MyJobsSectionList> {
  final _items = <MyJobItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await widget.api.myJobsRaw(
        role: widget.role == MyRole.executor ? 'executor' : 'customer',
        status: widget.status,
        masterId: widget.masterId,
      );
      final items = raw.map(MyJobItem.fromJson).toList();
      if (mounted) setState(() => _items
        ..clear()
        ..addAll(items));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch ((widget.role, widget.status)) {
      (MyRole.executor, 'archived') => 'В архиве',
      (MyRole.customer, 'cancelled') => 'Отменены',
      (_, 'active') => 'Активные',
      _ => 'Мои задания',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _items.isEmpty
                  ? const Center(child: Text('Здесь пока пусто'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _jobCard(_items[i]),
                    ),
    );
  }

  Widget _jobCard(MyJobItem j) {
    final badge = switch (widget.status) {
      'active' => const _Pill(text: 'Активно', color: Color(0xFF16A34A)),
      'cancelled' => const _Pill(text: 'Отменено', color: Color(0xFFE11D48)),
      'archived' => const _Pill(text: 'В архиве', color: Color(0xFF64748B)),
      _ => const SizedBox.shrink(),
    };

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // как в ленте — откроем детальную (если нужно передать api/masterId — получим их выше)
          final prefs = await SharedPreferences.getInstance();
          final mid = prefs.getInt('user_id') ?? 0;
          // подгружать JobItem из вашего Api.jobById
          try {
            final json = await Api.jobById(j.id);
            final job = JobItem.fromJson(json);
            if (!mounted) return;
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => JobDetailsPage(job: job, wizardApi: widget.api, masterId: mid),
            ));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть: $e')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // мини-иконка/обложка
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (j.color ?? const Color(0xFF9CA3AF)).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  image: j.coverUrl == null ? null : DecorationImage(image: NetworkImage(j.coverUrl!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (j.isRemote) 'Удалённо',
                        if (!j.isRemote && (j.cityName ?? '').isNotEmpty) j.cityName!,
                      ].join(' • '),
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(j.budgetText(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        badge,
                      ],
                    ),
                    if (widget.role == MyRole.customer && widget.status != 'cancelled') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.how_to_reg_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('Откликов: ${j.bidsCount}'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => showViewBidsSheet(context: context, api: widget.api, jobId: j.id),
                            child: const Text('Смотреть отклики'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
