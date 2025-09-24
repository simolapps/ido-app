import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/job_draft.dart';

class Category {
  final int id;
  final String name;
  final String? iconKey;
  final String? iconColor; // hex, например "#A5C9CA"
  final String? iconUrl;

  const Category({
    required this.id,
    required this.name,
    this.iconKey,
    this.iconColor,
    this.iconUrl,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        iconKey: j['icon_key'] as String?,
        iconColor: j['icon_color'] as String?,
        iconUrl: j['icon_url'] as String?,
      );
}

class CategoryStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  const CategoryStep({super.key, required this.draft, required this.onNext});

  @override
  State<CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<CategoryStep> {
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCategories();
  }

  Future<List<Category>> _loadCategories() async {
    final uri = Uri.parse('https://idoapi.tw1.ru/categories/get.php?limit=100');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final items = (map['items'] as List).cast<Map<String, dynamic>>();
    return items.map(Category.fromJson).toList();
  }

  Color _parseHexOr(String? hex, Color or) {
    if (hex == null || hex.isEmpty) return or;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : or;
  }

  IconData _fallbackIconByKey(String? key) {
    switch (key) {
      case 'courier':
        return Icons.local_shipping_outlined;
      case 'construction':
        return Icons.handyman_outlined;
      case 'moving_truck':
        return Icons.local_shipping;
      case 'home_cleaning':
        return Icons.cleaning_services_outlined;
      case 'computer_help':
        return Icons.computer;
      case 'photo_video':
        return Icons.photo_camera_outlined;
      case 'software_dev':
        return Icons.code;
      case 'appliance_repair':
        return Icons.build_outlined;
      case 'events':
        return Icons.campaign_outlined;
      case 'design':
        return Icons.brush_outlined;
      case 'virtual_assistant':
        return Icons.headset_mic_outlined;
      case 'electronics':
        return Icons.memory_outlined;
      case 'beauty':
        return Icons.content_cut_outlined;
      case 'legal':
        return Icons.balance_outlined;
      case 'transport_repair':
        return Icons.car_repair_outlined;
      case 'tutoring':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildLeading(Category c) {
    final bg = _parseHexOr(c.iconColor, const Color(0xFF607D8B)); // fallback
    final white = Colors.white;

    // Иконка из сети (покрасим в белый через color + BlendMode)
    if (c.iconUrl != null && c.iconUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: bg,
        radius: 22,
        child: ClipOval(
          child: Image.network(
            c.iconUrl!,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            // Принудительно в белый (работает для монохромных PNG/SVG, для сложных PNG может выглядеть как “tint”)
            color: white,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => Icon(_fallbackIconByKey(c.iconKey), color: white, size: 22),
          ),
        ),
      );
    }

    // Fallback иконка — белая
    return CircleAvatar(
      backgroundColor: bg,
      radius: 22,
      child: Icon(_fallbackIconByKey(c.iconKey), color: white, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Ошибка: ${snap.error}'));
        }
        final categories = snap.data ?? const [];
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = categories[i];
            return ListTile(
              leading: _buildLeading(c),
              title: Text(
                c.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                widget.draft.categoryId = c.id;
                widget.draft.categoryName = c.name;
                widget.onNext();
              },
            );
          },
        );
      },
    );
  }
}
