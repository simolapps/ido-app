// lib/pages/feed/widgets/feed_card.dart
import 'package:flutter/material.dart';
import '../feed_row.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.row,
    this.height = 156,      // фиксируем одинаковую высоту
    this.onTap,
  });

  final FeedRow row;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForKey(row.iconKey);
    final color = row.color ?? const Color(0xFF9CA3AF);

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withOpacity(0.35), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? row.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // слева иконка и цветная полоска
                Container(
                  width: 36,
                  height: double.infinity,
                  alignment: Alignment.topCenter,
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 10),

                // контент
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // заголовок (2 строки)
                      Text(
                        row.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // несколько слов из описания (2 строки)
                      if ((row.description ?? '').isNotEmpty)
                        Text(
                          _snippet(row.description!, maxWords: 14, maxChars: 110),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54, height: 1.2),
                        )
                      else
                        const Text('Описание не указано',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black38)),

                      const Spacer(), // выталкиваем низ карточки вниз

                      // низ карточки: мета и бюджет
                      if ((row.meta ?? '').isNotEmpty)
                        Text(
                          row.meta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black45, fontSize: 12),
                        ),

                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              row.amountText ?? 'Бюджет не указан',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // подбираем иконку по ключу категории
  static IconData _iconForKey(String? key) {
    switch (key) {
      case 'courier': return Icons.delivery_dining_outlined;
      case 'construction': return Icons.handyman_outlined;
      case 'moving_truck': return Icons.local_shipping_outlined;
      case 'home_cleaning': return Icons.cleaning_services_outlined;
      case 'computer_help': return Icons.computer_outlined;
      case 'photo_video': return Icons.photo_camera_back_outlined;
      case 'software_dev': return Icons.code_outlined;
      case 'appliance_repair': return Icons.build_outlined;
      case 'events': return Icons.event_outlined;
      case 'design': return Icons.brush_outlined;
      case 'virtual_assistant': return Icons.support_agent_outlined;
      case 'electronics': return Icons.memory_outlined;
      case 'beauty': return Icons.face_retouching_natural_outlined;
      case 'legal': return Icons.gavel_outlined;
      case 'transport_repair': return Icons.car_repair_outlined;
      case 'tutoring': return Icons.school_outlined;
      default: return Icons.category_outlined;
    }
  }

static String _snippet(String? text, {int maxWords = 12, int maxChars = 90}) {
  // нормализуем пробелы/переводы строк
  final s = text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  if (s.isEmpty) return 'Описание не указано';

  // ограничим по количеству слов
  final words = s.split(' ');
  var cut = words.take(maxWords).join(' ');

  // и по символам (без ручного «…» — его добавит TextOverflow.ellipsis)
  if (cut.length > maxChars) {
    cut = cut.substring(0, maxChars).trimRight();
  }
  return cut;
}
}
