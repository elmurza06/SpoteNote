import 'dart:convert';

/// 3 основные категории по ТЗ (Share вынесен в отдельную функцию экспорта/импорта)
enum SpotCategory { todo, note, wifi }

class Item {
  String id;
  String text;
  bool isTodo; // true — с галочкой, false — обычный текстовый пункт
  bool done;

  Item(
    this.text,
    this.isTodo, {
    this.done = false,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isTodo': isTodo,
        'done': done,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        json['text'] as String? ?? '',
        json['isTodo'] as bool? ?? true,
        done: json['done'] as bool? ?? false,
        id: json['id'] as String?,
      );
}

class ItemList {
  String id;
  String name;
  SpotCategory category;
  final List<Item> items;
  bool isNfcLinked;
  String? nfcTagLabel; // Например: "Метка у входной двери" или "Брелок коворкинга"
  String? wifiSsid;
  String? wifiPassword;
  DateTime createdAt;

  ItemList(
    this.name,
    bool isTodoLegacy, {
    String? id,
    SpotCategory? category,
    List<Item>? items,
    this.isNfcLinked = false,
    this.nfcTagLabel,
    this.wifiSsid,
    this.wifiPassword,
    DateTime? createdAt,
  })  : id = id ?? _generateShortId(),
        category = category ?? (isTodoLegacy ? SpotCategory.todo : SpotCategory.note),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  static String _generateShortId() {
    final millis = DateTime.now().millisecondsSinceEpoch % 100000;
    return millis.toRadixString(16).padLeft(4, '0');
  }

  /// Обратная совместимость со старыми экранами
  bool get isTodo => category == SpotCategory.todo;
  set isTodo(bool value) {
    category = value ? SpotCategory.todo : SpotCategory.note;
  }

  /// Уникальный локальный адрес списка, который записывается на NFC-метку
  String get spotAddress => 'spot://${category.name}/$id';

  /// Прогресс выполнения для To-Do списков (от 0.0 до 1.0)
  double get progress {
    final todoItems = items.where((e) => e.isTodo).toList();
    if (todoItems.isEmpty) return 0.0;
    final completed = todoItems.where((e) => e.done).length;
    return completed / todoItems.length;
  }

  /// Функция Share: сериализация списка в компактный код для передачи другому юзеру
  String exportShareCode() {
    final payload = jsonEncode(toJson());
    return 'SPOTNOTE_SHARE:${base64UrlEncode(utf8.encode(payload))}';
  }

  /// Функция Share: импорт списка из кода другого пользователя
  static ItemList? importFromShareCode(String rawCode) {
    try {
      final clean = rawCode.trim();
      final base64Part = clean.startsWith('SPOTNOTE_SHARE:')
          ? clean.substring('SPOTNOTE_SHARE:'.length)
          : clean;
      final decoded = utf8.decode(base64Url.decode(base64Part));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final imported = ItemList.fromJson(map);
      // Генерируем новый локальный ID при импорте, чтобы не было конфликта
      imported.id = _generateShortId();
      return imported;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'items': items.map((e) => e.toJson()).toList(),
        'isNfcLinked': isNfcLinked,
        'nfcTagLabel': nfcTagLabel,
        'wifiSsid': wifiSsid,
        'wifiPassword': wifiPassword,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ItemList.fromJson(Map<String, dynamic> json) {
    final catStr = json['category'] as String? ?? 'todo';
    final category = SpotCategory.values.firstWhere(
      (e) => e.name == catStr,
      orElse: () => SpotCategory.todo,
    );
    final rawItems = (json['items'] as List<dynamic>? ?? [])
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();

    return ItemList(
      json['name'] as String? ?? 'Untitled',
      category == SpotCategory.todo,
      id: json['id'] as String?,
      category: category,
      items: rawItems,
      isNfcLinked: json['isNfcLinked'] as bool? ?? false,
      nfcTagLabel: json['nfcTagLabel'] as String?,
      wifiSsid: json['wifiSsid'] as String?,
      wifiPassword: json['wifiPassword'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}