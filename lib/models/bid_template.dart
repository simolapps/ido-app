// lib/models/bid_template.dart
class BidTemplate {
  final int id;
  final int masterId;
  final String title;
  final String body;
  final int? priceSuggest;
  final bool isDefault;

  BidTemplate({
    required this.id,
    required this.masterId,
    required this.title,
    required this.body,
    this.priceSuggest,
    this.isDefault = false,
  });

  factory BidTemplate.fromJson(Map<String, dynamic> j) => BidTemplate(
    id: j['id'] ?? 0,
    masterId: j['master_id'] ?? 0,
    title: (j['title'] ?? '').toString(),
    body: (j['body'] ?? '').toString(),
    priceSuggest: j['price_suggest'] == null ? null : int.tryParse('${j['price_suggest']}'),
    isDefault: (j['is_default']?.toString() == '1') || (j['is_default'] == true),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'master_id': masterId,
    'title': title,
    'body': body,
    'price_suggest': priceSuggest,
    'is_default': isDefault ? 1 : 0,
  };
}
