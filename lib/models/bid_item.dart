class BidItem {
  final int id;
  final int executorId;
  final String executorName;
  final String? avatarUrl;
  final double? rating;
  final int reviewsCount;
  final int? experienceYears;
  final int? offeredAmount;
  final String message;
  final DateTime createdAt;

  BidItem({
    required this.id,
    required this.executorId,
    required this.executorName,
    required this.message,
    required this.createdAt,
    this.avatarUrl,
    this.rating,
    this.reviewsCount = 0,
    this.experienceYears,
    this.offeredAmount,
  });

  factory BidItem.fromJson(Map<String, dynamic> j) => BidItem(
    id: (j['id'] as num).toInt(),
    executorId: (j['executor_master_id'] as num).toInt(),
    executorName: (j['executor_name'] ?? 'Исполнитель').toString(),
    avatarUrl: (j['executor_avatar'] ?? '').toString().isEmpty ? null : j['executor_avatar'].toString(),
    rating: j['executor_rating'] == null ? null : (j['executor_rating'] as num).toDouble(),
    reviewsCount: (j['executor_reviews_count'] as num?)?.toInt() ?? 0,
    experienceYears: (j['executor_experience_years'] as num?)?.toInt(),
    offeredAmount: (j['offered_amount'] as num?)?.toInt(),
    message: (j['message'] ?? '').toString(),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
  );
}
