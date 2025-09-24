import 'package:flutter/material.dart';

/// Единый источник цветов приложения.
/// Используем только эти токены — никакого Colors.red и т.п. по коду.
class AppColors {
  // ---------- Neutrals (серые)
  static const gray50  = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);

  // ---------- Brand: Indigo/Violet (фриланс)
  static const indigo50  = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo200 = Color(0xFFC7D2FE);
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo800 = Color(0xFF3730A3);
  static const indigo900 = Color(0xFF312E81);

  static const violet500 = Color(0xFF8B5CF6);
  static const primary    = Color(0xFF6C5CE7); // твой прежний фирменный

  // ---------- Brand: Emerald Green (вакансии)
  static const emerald50  = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981); // основной зелёный
  static const emerald600 = Color(0xFF059669); // тёмнее для акцентов
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);

  // ---------- Blues (info)
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);

  // ---------- Reds (danger)
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);

  // ---------- Yellows/Amber (warning)
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);

  // ---------- Базовые фоны/текст
  static const background  = Color(0xFFF9F9F9);
  static const background2 = Color(0xFF3B375C); // тёмная карточка/панель
  static const surface     = Colors.white;
  static const text        = Colors.black;

  // ---------- Семантика (единые ключи)
  static const success = emerald500;
  static const warning = amber500;
  static const info    = blue500;
  static const danger  = red600;

  // ---------- Категорные цвета (для меток/иконок/кнопок)
  static const freelance = Color(0xFF4338CA);  // разовые подработки
  static const vacancy   = emerald600; // вакансии

  // ---------- Оверлеи/прозрачности (для бликов/бэджей)
  static const white12 = Color(0x1FFFFFFF); // 12%
  static const white18 = Color(0x2EFFFFFF); // 18%
  static const white24 = Color(0x3DFFFFFF); // 24%
  static const black10 = Color(0x1A000000); // 10%
  static const black20 = Color(0x33000000); // 20%

  // ---------- Градиенты (готово для карточек)
  static const Gradient freelanceCard = LinearGradient(
    colors: [indigo500, violet500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient vacancyCard = LinearGradient(
    colors: [emerald500, emerald600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme() {
  // Базируемся на light, но сохраним фирменные тёмные панели там, где нужно.
  final base = ThemeData.light(useMaterial3: false);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,            // общий фирменный фиолетовый
      secondary: AppColors.vacancy,          // доп. бренд (зелёный) — удобно для тем "вакансии"
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background, // светлая шапка по умолчанию
      foregroundColor: AppColors.text,
      elevation: 0.5,
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(12),
      shadowColor: AppColors.black20,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: AppColors.gray500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.indigo500, width: 1.6),
      ),
      labelStyle: TextStyle(color: AppColors.gray600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: AppColors.black20,
        elevation: 2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.vacancy, // удобно для зелёных CTA
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.indigo600),
    ),
    dividerColor: AppColors.gray200,
  );
}
