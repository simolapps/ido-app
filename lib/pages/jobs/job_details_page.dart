// === file: lib/pages/jobs/job_details_page.dart
import 'package:flutter/material.dart';
import 'package:ido/api/wizard_api.dart';
import 'package:ido/models/bid_template.dart';
import 'package:ido/pages/bids/templates_page.dart';
import '../../models/job_item.dart';

class JobDetailsPage extends StatelessWidget {
  final JobItem job;
  final WizardApi wizardApi;
  final int masterId;

  const JobDetailsPage({
    super.key,
    required this.job,
    required this.wizardApi,
    required this.masterId,
  });

  @override
  Widget build(BuildContext context) {
    final c = job.color ?? const Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Задание № ${job.id}', style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),

      // Кнопка «Откликнуться» закреплена внизу
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showBidBottomSheet(context, job, wizardApi, masterId),
              icon: const Icon(Icons.reply_outlined),
              label: const Text('Откликнуться',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // цветная лента категории
          Container(height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),

          // фото
          if (job.photoUrls.isNotEmpty) ...[
            _PhotosCarousel(urls: job.photoUrls),
            const SizedBox(height: 12),
          ],

          // Заголовок
          Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          // Описание
          if ((job.description ?? '').isNotEmpty)
            Text(job.description!, style: const TextStyle(height: 1.35, color: Colors.black87))
          else
            const Text('Описание не указано', style: TextStyle(color: Colors.black45)),
          const SizedBox(height: 14),

          // Мета (место/срок)
          if ((job.meta ?? '').isNotEmpty) _meta(Icons.event_available_outlined, job.meta!),

          // Бюджет «до … ₽»
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  _budgetCeilText(job),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Место оказания услуги (если меты нет)
          if ((job.meta ?? '').isEmpty) ...[
            _sectionLabel('Место оказания услуги'),
            Text(_place(job), style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 18),
          ],

          // Начать (дата)
          if (job.dueDate != null) ...[
            _sectionLabel('Начать'),
            Text(_fmtDateTime(job.dueDate!), style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 18),
          ],

          // Оплата
          _divider(),
          Row(
            children: const [
              Icon(Icons.credit_card_outlined, size: 20, color: Colors.black54),
              SizedBox(width: 8),
              Text('Оплата напрямую исполнителю', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          _divider(),

          // Заказчик
          if (job.customerName != null || job.customerAvatarUrl != null) ...[
            _sectionLabel('Заказчик'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black12,
                  backgroundImage: (job.customerAvatarUrl != null && job.customerAvatarUrl!.isNotEmpty)
                      ? NetworkImage(job.customerAvatarUrl!)
                      : null,
                  child: (job.customerAvatarUrl == null || job.customerAvatarUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white70, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.customerName ?? 'Пользователь',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        _reviewsLine(job.customerReviewsCount, job.customerRating),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (job.customerLastSeenAt != null) ...[
                        const SizedBox(height: 2),
                        Text(_lastSeenLine(job.customerLastSeenAt!),
                            style: const TextStyle(color: Colors.black45)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Подвал
          const SizedBox(height: 8),
          if (job.createdAt != null)
            Text('Создано ${_fmtHuman(job.createdAt!)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if ((job.subcategoryName ?? '').isNotEmpty)
            Text('Подкатегория «${job.subcategoryName}»',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  // ===== UI helpers =====
  static Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
      );

  static Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Divider(color: Colors.black12, height: 1),
      );

  static Widget _meta(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(i, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(t)),
        ]),
      );

  // ===== Data helpers & fallbacks =====
  static String _budgetCeilText(JobItem j) {
    if (j.budget == null) return 'Бюджет не указан';
    final base = 'до ${_fmtMoney(j.budget!)} ₽';
    final hourly = (j.priceType == 'hourly' || j.priceType == '1');
    return hourly ? '$base / час' : base;
  }

  static String _place(JobItem j) {
    if (j.isRemote) return 'Удалённо';
    if ((j.addressText ?? '').isNotEmpty) return j.addressText!;
    if ((j.cityName ?? '').isNotEmpty) return j.cityName!;
    return 'По адресу';
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

  static String _fmtDateTime(DateTime d) =>
      '${_weekdayRu(d.weekday)}, ${_two(d.day)} ${_monthRu(d.month)} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';

  static String _fmtHuman(DateTime d) =>
      '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';

  static String _weekdayRu(int weekday) {
    const w = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return w[(weekday - 1).clamp(0, 6)];
  }

  static String _monthRu(int m) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _reviewsLine(int? count, double? rating) {
    final c = count ?? 0;
    if (c <= 0) return 'Нет отзывов';
    final r = (rating == null) ? '' : '${rating.toStringAsFixed(1)} • ';
    final word = (c % 10 == 1 && c % 100 != 11)
        ? 'отзыв'
        : ((c % 10 >= 2 && c % 10 <= 4) && !(c % 100 >= 12 && c % 100 <= 14))
            ? 'отзыва'
            : 'отзывов';
    return '$r$c $word';
  }

  static String _lastSeenLine(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = _two(dt.hour), mm = _two(dt.minute);
    if (sameDay) return 'Был сегодня, $hh:$mm';
    return 'Был ${_two(dt.day)}.${_two(dt.month)}.${dt.year}, $hh:$mm';
  }
}

// ===== Слайдер фото =====
class _PhotosCarousel extends StatefulWidget {
  final List<String> urls;
  const _PhotosCarousel({required this.urls});

  @override
  State<_PhotosCarousel> createState() => _PhotosCarouselState();
}

class _PhotosCarouselState extends State<_PhotosCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(widget.urls[i], fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (widget.urls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.urls.length, (i) {
              final active = i == _index;
              return Container(
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? Colors.black87 : Colors.black26,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ===== Модалка «Откликнуться» =====
Future<void> showBidBottomSheet(
  BuildContext context,
  JobItem job,
  WizardApi api,
  int masterId,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BidSheet(job: job, api: api, masterId: masterId),
  );
}

class _BidSheet extends StatefulWidget {
  const _BidSheet({required this.job, required this.api, required this.masterId});
  final JobItem job;
  final WizardApi api;
  final int masterId;

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  final _priceCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _useEscrow = false;
  bool _submitting = false;

  static const int _responseFeeRub = 22;

  // шаблоны
  List<BidTemplate> _templates = [];
  BidTemplate? _applied; // какой сейчас применён
  bool _loadingTemplates = true;
  String? _tplError;

  @override
  void initState() {
    super.initState();
    _loadTemplatesAndApplyDefault();
  }

  Future<void> _loadTemplatesAndApplyDefault() async {
    setState(() {
      _loadingTemplates = true;
      _tplError = null;
    });
    try {
      final items = await widget.api.templatesList(masterId: widget.masterId, limit: 100, offset: 0);
      _templates = items;
      final def = items.where((t) => t.isDefault).toList();
      if (def.isNotEmpty) {
        _applyTemplate(def.first);
      }
    } catch (e) {
      _tplError = e.toString();
    } finally {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  void _applyTemplate(BidTemplate t) {
    _applied = t;
    _textCtrl.text = t.body;
    _priceCtrl.text = (t.priceSuggest == null) ? '' : t.priceSuggest.toString();
    setState(() {});
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return FractionallySizedBox(
      heightFactor: 0.92,
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Material(
          color: Colors.white,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                      const Expanded(
                        child: Text('Обычный',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Открываем страницу шаблонов в режиме выбора
                          final picked = await Navigator.of(context).push<BidTemplate>(
                            MaterialPageRoute(
                              builder: (_) => TemplatesPage(
                                api: widget.api,
                                masterId: widget.masterId,
                                pickMode: true,
                              ),
                            ),
                          );
                          if (picked != null) {
                            _applyTemplate(picked);
                          }
                        },
                        child: const Text('Выбрать шаблон', style: TextStyle(color: Color(0xFF6C63FF))),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Заказчик предлагает ${_budgetCeilText(job)}',
                            style: const TextStyle(fontSize: 16, color: Colors.black87)),
                        const SizedBox(height: 12),

                        if (_loadingTemplates) const LinearProgressIndicator(minHeight: 3),
                        if (_applied != null && !_loadingTemplates) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  'Применён: ${_applied!.title}${_applied!.isDefault ? ' • по умолчанию' : ''}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_tplError != null && !_loadingTemplates) ...[
                          const SizedBox(height: 8),
                          Text('Шаблоны: $_tplError', style: const TextStyle(color: Colors.red)),
                        ],

                        const SizedBox(height: 12),
                        const Text('Предложите свою цену',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: false),
                          decoration: InputDecoration(
                            hintText: 'В рублях',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 10, right: 8),
                              child: Text('₽', style: TextStyle(fontSize: 18)),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 0, minHeight: 0),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          job.budget != null
                              ? 'Если вы запросите меньше ${JobDetailsPage._fmtMoney(job.budget!)} ₽, то шансов получить заказ больше.'
                              : 'Укажите сумму, за которую готовы выполнить работу.',
                          style: const TextStyle(color: Colors.black45),
                        ),
                        const SizedBox(height: 18),

                        const Text('Напишите текст отклика',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _textCtrl,
                          maxLines: 5,
                          minLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Почему это задание нужно доверить вам',
                            filled: true,
                            fillColor: const Color(0xFFF7F7F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Укажите опыт, сроки, этапы работ — всё, что поможет выбрать именно вас.',
                          style: TextStyle(color: Colors.black45),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: const [
                            Text('Оплата на карту', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Через Сделку без риска',
                                  style: TextStyle(color: Colors.black38)),
                            ),
                            Switch(
                              value: _useEscrow,
                              onChanged: (v) => setState(() => _useEscrow = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Вы гарантированно получите оплату, если вас выберут исполнителем и задание выполнено.',
                          style: TextStyle(color: Colors.black45),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () {}, child: const Text('Подробнее')),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // CTA
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text('Откликнуться | $_responseFeeRub ₽',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _budgetCeilText(JobItem j) => JobDetailsPage._budgetCeilText(j);

  Future<void> _submit() async {
    final price = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите корректную цену')));
      return;
    }
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Напишите текст отклика')));
      return;
    }

    setState(() => _submitting = true);
    try {
await widget.api.sendBid(
  jobId: widget.job.id!,
  masterId: widget.masterId,
  message: _textCtrl.text.trim(),
  offeredAmount: price,
  useEscrow: _useEscrow,
  templateId: _applied?.id,
);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Отклик отправлен')));
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      String pretty = 'Не удалось отправить отклик';
      if (raw.contains('insufficient_funds')) {
        pretty = 'Недостаточно средств. Пополните кошелёк.';
      } else if (raw.contains('bid_already_exists')) {
        pretty = 'Вы уже откликались на это задание.';
      } else if (raw.contains('job_not_available')) {
        pretty = 'Задание недоступно для отклика.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pretty)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
