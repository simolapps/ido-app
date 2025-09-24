import 'package:flutter/material.dart';
import '../../api/wizard_api.dart';
import '../../models/bid_item.dart';

Future<void> showViewBidsSheet({
  required BuildContext context,
  required WizardApi api,
  required int jobId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ViewBidsSheet(api: api, jobId: jobId),
  );
}

class _ViewBidsSheet extends StatefulWidget {
  final WizardApi api;
  final int jobId;
  const _ViewBidsSheet({required this.api, required this.jobId});

  @override
  State<_ViewBidsSheet> createState() => _ViewBidsSheetState();
}

class _ViewBidsSheetState extends State<_ViewBidsSheet> {
  bool _loading = true;
  String? _error;
  List<BidItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await widget.api.bidsForJob(jobId: widget.jobId);
      _items = raw.map(BidItem.fromJson).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close)),
                    const Expanded(child: Text('Отклики', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text('Ошибка: $_error'))
                        : _items.isEmpty
                            ? const Center(child: Text('Откликов пока нет'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _bidCard(_items[i]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bidCard(BidItem b) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // executor header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black12,
                  backgroundImage: b.avatarUrl == null ? null : NetworkImage(b.avatarUrl!),
                  child: b.avatarUrl == null ? const Icon(Icons.person, color: Colors.white70) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(b.executorName, style: const TextStyle(fontWeight: FontWeight.w800))),
                        const Icon(Icons.chevron_right_rounded),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.star_rate_rounded, size: 16, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text('${(b.rating ?? 0).toStringAsFixed(2)} · ${b.reviewsCount} отзывов'
                            '${b.experienceYears != null ? ' · Стаж ${b.experienceYears} ' : ''}'),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // badges (пример)
            Wrap(
              spacing: 8,
              runSpacing: -6,
              children: const [
                _Pill(text: 'Документы подтверждены', color: Color(0xFF34D399)),
                _Pill(text: 'Проверенный бизнес-исп...', color: Color(0xFF60A5FA)),
              ],
            ),
            const SizedBox(height: 10),

            Text('Стоимость ${b.offeredAmount ?? 0} ₽', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Оплата напрямую исполнителю', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),

            Text(b.message),
            const SizedBox(height: 12),

            Text(
              '${_pad2(b.createdAt.day)}.${_pad2(b.createdAt.month)}.${b.createdAt.year}, '
              '${_pad2(b.createdAt.hour)}:${_pad2(b.createdAt.minute)}',
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {/* открыть чат */},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Написать'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {/* звонок */},
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Позвонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _pad2(int v) => v.toString().padLeft(2, '0');
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
