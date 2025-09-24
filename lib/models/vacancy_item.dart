class VacancyItem {
  final int id;
  final String title;
  final String description;
  final String phone;
  final String? profession;
  final String? industry;
  final String schedule;              // shift|rotational|flexible|fixed...
  final int? rotationLengthDays;
  final int? salaryFrom;
  final int? salaryTo;
  final String salaryPeriod;          // month|per_shift|hour
  final String taxMode;               // gross|net
  final String payoutFrequency;       // monthly|twice_month|weekly|three_times_month
  final List<String> addresses;
  final DateTime createdAt;

  VacancyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.phone,
    required this.schedule,
    required this.salaryPeriod,
    required this.taxMode,
    required this.payoutFrequency,
    required this.addresses,
    required this.createdAt,
    this.profession,
    this.industry,
    this.rotationLengthDays,
    this.salaryFrom,
    this.salaryTo,
  });

  static DateTime _dt(dynamic v) {
    try { return DateTime.parse('$v'); } catch (_) { return DateTime.now(); }
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
    return null;
  }

  factory VacancyItem.fromJson(Map<String, dynamic> j) {
    return VacancyItem(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      profession: (j['profession'] ?? j['profession_name'])?.toString(),
      industry: (j['industry'] ?? j['industry_name'])?.toString(),
      schedule: (j['schedule'] ?? '').toString(),
      rotationLengthDays: _toInt(j['rotation_length_days']),
      salaryFrom: _toInt(j['salary_from']),
      salaryTo: _toInt(j['salary_to']),
      salaryPeriod: (j['salary_period'] ?? 'month').toString(),
      taxMode: (j['tax_mode'] ?? 'gross').toString(),
      payoutFrequency: (j['payout_frequency'] ?? 'monthly').toString(),
      addresses: ((j['addresses'] ?? j['work_addresses']) as List? ?? const [])
          .map((e) => e is String ? e : (e['address_text'] ?? '').toString())
          .where((s) => s.isNotEmpty).cast<String>().toList(),
      createdAt: _dt(j['created_at']),
    );
  }

  String get salaryText {
    String m(int v) {
      final s = v.toString();
      final b = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final idx = s.length - i;
        b.write(s[i]);
        if (i < s.length - 1 && idx % 3 == 1) b.write(' ');
      }
      return '$b ₽';
    }
    if (salaryFrom == null && salaryTo == null) return 'Не указана';
    if (salaryFrom != null && salaryTo != null) return '${m(salaryFrom!)} – ${m(salaryTo!)}';
    if (salaryFrom != null) return 'от ${m(salaryFrom!)}';
    return 'до ${m(salaryTo!)}';
  }
}
