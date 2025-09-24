// === file: lib/models/job_draft.dart

class JobDraft {
  // -------- Категория/подкатегория
  int? categoryId;
  String? categoryName;
  String? categorySlug;

  int? subcategoryId;
  String? subcategoryName;
  String? subcategorySlug;

  // -------- Базовые поля
  String title;
  String description;
  String privateNote;

  /// Локальные пути выбранных медиа (до загрузки)
  List<String> mediaPaths;

  /// Публичные URL загруженных фото/медиа (после аплоада)
  List<String> photoUrls;

  // -------- Бюджет
  String priceType; // fixed | hourly
  int? budgetPreset;
  int? customBudget;
  String paymentType; // direct | escrow | docs

  // -------- Даты
  DateTime? exactDateTime;
  DateTime? periodFrom;
  DateTime? periodTo;

  // -------- Адрес
  bool isRemote;
  String address;

  /// Точки адресов (если multi_points)
  List<String> addressPoints;

  /// Режим места: atCustomer | atPerformer | remote | any
  String placeMode;

  // -------- Динамические ответы (гибкие поля шага)
  Map<String, dynamic> dynamicAnswers;

  // ====== Конструктор с дефолтами
  JobDraft({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.subcategoryId,
    this.subcategoryName,
    this.subcategorySlug,
    this.title = '',
    this.description = '',
    this.privateNote = '',
    List<String>? mediaPaths,
    List<String>? photoUrls,
    this.priceType = 'fixed',
    this.budgetPreset,
    this.customBudget,
    this.paymentType = 'direct',
    this.exactDateTime,
    this.periodFrom,
    this.periodTo,
    this.isRemote = true,
    this.address = '',
    List<String>? addressPoints,
    this.placeMode = 'any',
    Map<String, dynamic>? dynamicAnswers,
  })  : mediaPaths = mediaPaths ?? <String>[],
        photoUrls = photoUrls ?? <String>[],
        addressPoints = addressPoints ?? <String>[],
        dynamicAnswers = dynamicAnswers ?? <String, dynamic>{};

  // ====== JSON (для сохранения черновика/отправки)
  factory JobDraft.fromJson(Map<String, dynamic> j) => JobDraft(
        categoryId: _asInt(j['categoryId']),
        categoryName: j['categoryName'] as String?,
        categorySlug: j['categorySlug'] as String?,
        subcategoryId: _asInt(j['subcategoryId']),
        subcategoryName: j['subcategoryName'] as String?,
        subcategorySlug: j['subcategorySlug'] as String?,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        privateNote: (j['privateNote'] as String?) ?? '',
        mediaPaths: _asStringList(j['mediaPaths']),
        photoUrls: _asStringList(j['photoUrls']),
        priceType: (j['priceType'] as String?) ?? 'fixed',
        budgetPreset: _asInt(j['budgetPreset']),
        customBudget: _asInt(j['customBudget']),
        paymentType: (j['paymentType'] as String?) ?? 'direct',
        exactDateTime: _asDate(j['exactDateTime']),
        periodFrom: _asDate(j['periodFrom']),
        periodTo: _asDate(j['periodTo']),
        isRemote: j['isRemote'] is bool ? j['isRemote'] as bool : (j['isRemote']?.toString() == 'true'),
        address: (j['address'] as String?) ?? '',
        addressPoints: _asStringList(j['addressPoints']),
        placeMode: (j['placeMode'] as String?) ?? 'any',
        dynamicAnswers: (j['dynamicAnswers'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      );

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categorySlug': categorySlug,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'subcategorySlug': subcategorySlug,
        'title': title,
        'description': description,
        'privateNote': privateNote,
        'mediaPaths': mediaPaths,
        'photoUrls': photoUrls,
        'priceType': priceType,
        'budgetPreset': budgetPreset,
        'customBudget': customBudget,
        'paymentType': paymentType,
        'exactDateTime': exactDateTime?.toIso8601String(),
        'periodFrom': periodFrom?.toIso8601String(),
        'periodTo': periodTo?.toIso8601String(),
        'isRemote': isRemote,
        'address': address,
        'addressPoints': addressPoints,
        'placeMode': placeMode,
        'dynamicAnswers': dynamicAnswers,
      };

  // ====== Удобные хелперы для экрана деталей/загрузки
  /// Добавить локальный путь выбранного файла
  void addLocalMediaPath(String path) {
    if (path.isEmpty) return;
    mediaPaths.add(path);
  }

  /// Установить публичные URL после загрузки
  void setUploadedPhotoUrls(List<String> urls) {
    photoUrls = List<String>.from(urls);
  }

  /// Очистить медиа
  void clearMedia() {
    mediaPaths.clear();
    photoUrls.clear();
  }

  /// Валидный период (если выбран режим «Период»)
  bool get isValidPeriod =>
      periodFrom != null && periodTo != null && !periodTo!.isBefore(periodFrom!);

  /// Есть ли дата (любой режим)
  bool get hasAnyDate => exactDateTime != null || isValidPeriod;

  // ====== Внутренние парсеры
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static List<String> _asStringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) return v.map((e) => e.toString()).toList();
    return <String>[];
  }
}
