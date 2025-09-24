// === file: lib/flows/category_flows.dart
import '../models/step_config.dart';

/// Только СЕРЕДИНА! Якоря (первые 3 и последние 5) добавляются программно.
final Map<String, List<StepConfig>> middleFlowBySubcategory = {
  // Кузовной ремонт: 2 середины (как на скринах)
  'body_repair': [
    StepConfig(
      kind: StepKind.customQ,
      title: 'Какая нужна услуга?',
      props: {
        'json': {
          "id": "body_repair_services",
          "type": "checkbox",
          "title": "Какая нужна услуга?",
          "options": [
            "Покраска","Рихтовка вмятин","Замена детали кузова","Удаление царапин",
            "Полировка","Сварка","Удаление вмятин без покраски","Удаление ржавчины",
            "Антикоррозийная обработка"
          ],
          "required": true
        }
      },
    ),
    StepConfig(
      kind: StepKind.customQ,
      title: "Какой у вас автомобиль?",
      props: {
        'json': {
          "id": "car_info",
          "type": "text",
          "title": "Какой у вас автомобиль?",
          "placeholder": "Марка, модель и год выпуска авто",
          "hint": "Например, Chevrolet Cruze 2014 года",
          "required": true
        }
      },
    ),
  ],

  // Вывоз мусора: 2 середины
  'waste_removal': [
    StepConfig(
      kind: StepKind.customQ,
      title: 'Нужны услуги грузчиков?',
      props: { 'json': {
        "id":"waste_loader_needed",
        "type":"radio",
        "title":"Нужны услуги грузчиков?",
        "options":["Да","Нет"],
        "required": true
      }},
    ),
    StepConfig(
      kind: StepKind.customQ,
      title: 'Насколько большой груз?',
      props: { 'json': {
        "id":"cargo_size",
        "type":"multiform",
        "title":"Насколько большой груз?",
        "subtitle":"Укажите вес и размеры, чтобы исполнители подобрали подходящий транспорт.",
        "fields":[
          {"name":"weight","label":"Вес груза, кг","input":"number"},
          {"name":"length","label":"Длина, м","input":"number"},
          {"name":"width","label":"Ширина, м","input":"number"},
          {"name":"height","label":"Высота, м","input":"number"}
        ]
      }},
    ),
  ],

  // Английский: 2 примера
  'english_lessons': [
    StepConfig(
      kind: StepKind.customQ,
      title: 'Какие нужны занятия?',
      props: { 'json': {
        "id":"eng_lessons_kind",
        "type":"formlist",
        "title":"Какие нужны занятия?",
        "rows":[
          {"name":"frequency","label":"Частота","value":"Регулярно","nav":true},
          {"name":"duration","label":"Длительность","value":"Неважно","nav":true}
        ]
      }},
    ),
    StepConfig(
      kind: StepKind.customQ,
      title: 'Сколько лет ученику?',
      props: { 'json': {
        "id":"pupil_age",
        "type":"text",
        "title":"Сколько лет ученику?",
        "placeholder":"Возраст",
        "keyboard":"number",
        "required":true
      }},
    ),
  ],

  // По умолчанию — без середины
  '_default': const [],
};
