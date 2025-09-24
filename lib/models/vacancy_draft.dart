import 'package:flutter/foundation.dart';

@immutable
class VacancyDraft {
  // Описание
  String title;
  String profession;          // «Посудомойщик»
  String industry;            // «Общественное питание»
  String description;

  // Занятость и график
  String employment;          // full|part|temp|intern
  String schedule;            // day|night|shift|rotational (вахта) и т.п.
  int? rotationLengthDays;    // 10, 15, 20, 21, 25, 30, 33, 35, 45, 50, 60, 90
  String dailyHours;          // 6-7|8|9-10|11-12

  // Зарплата
  int? salaryFrom;
  int? salaryTo;
  String salaryPeriod;        // month|week|day|hour|piece
  String taxMode;             // gross (до вычета) | net (на руки)
  String payoutFrequency;     // daily|weekly|twice_month|monthly|per_shift|per_hour

  // География
  String searchRegion;        // «Махачкала»
  final List<String> workAddresses;

  // Контакты
  String phone;

  VacancyDraft({
    this.title = '',
    this.profession = '',
    this.industry = '',
    this.description = '',
    this.employment = 'full',
    this.schedule = 'day',
    this.rotationLengthDays,
    this.dailyHours = '8',
    this.salaryFrom,
    this.salaryTo,
    this.salaryPeriod = 'month',
    this.taxMode = 'gross',
    this.payoutFrequency = 'monthly',
    this.searchRegion = '',
    List<String>? workAddresses,
    this.phone = '',
  }) : workAddresses = workAddresses ?? [];

  bool get isSalaryRangeValid =>
      salaryFrom != null && salaryTo != null && salaryFrom! <= salaryTo!;
}
