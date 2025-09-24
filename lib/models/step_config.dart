
enum StepKind { category, subcategory, title, address, date, details, budget, preview, customQ }

class StepConfig {
  final StepKind kind;
  final String title;
  final Map<String, dynamic>? props;

  const StepConfig({required this.kind, required this.title, this.props});
}

/// Конфиг страницы адреса
class AddressConfig {
  final bool allowRemote;
  final bool multiPoints;
  final int minPoints;
  final int maxPoints;
  final Map<String, String> labels;
  final Map<String, String> placeholders;
  final bool singleField;

  AddressConfig({
    required this.allowRemote,
    required this.multiPoints,
    required this.minPoints,
    required this.maxPoints,
    required this.labels,
    required this.placeholders,
    required this.singleField,
  });

  factory AddressConfig.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const {};
    final labels = (m['labels'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {};
    final ph = (m['placeholders'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {};
    final multi = m['multi_points'] == true;
    final minP = (m['min_points'] is num) ? (m['min_points'] as num).toInt() : 1;
    final maxP = (m['max_points'] is num) ? (m['max_points'] as num).toInt() : 1;

    // single_field можно явно прислать, либо выводим: не multi и max=1
    final single = m['single_field'] == true || (!multi && maxP == 1);

    return AddressConfig(
      allowRemote: m['allow_remote'] != false,
      multiPoints: multi,
      minPoints: minP,
      maxPoints: maxP,
      labels: Map<String, String>.from(labels),
      placeholders: Map<String, String>.from(ph),
      singleField: single,
    );
  }
}
