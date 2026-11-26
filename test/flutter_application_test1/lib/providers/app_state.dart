import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_strings.dart';
import '../models/item_model.dart';

class AppState extends ChangeNotifier {
  static const String _storageKey = 'spotnote_lists_v1';
  static const String _langKey = 'spotnote_lang_en';

  final List<ItemList> lists = [];
  SpotCategory? selectedCategory; // null = Все категории
  String searchQuery = '';
  bool isInitialized = false;

  /// Геттер текущего языка для UI-хелпера tr(ru, en)
  bool get isRu => !AppStrings.isEn;

  /// Загрузка данных при старте приложения
  Future<void> init() async {
    if (isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    AppStrings.isEn = prefs.getBool(_langKey) ?? false;

    final rawJson = prefs.getString(_storageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        lists.clear();
        lists.addAll(
          decoded.map((e) => ItemList.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        _seedDemoData();
      }
    } else {
      _seedDemoData();
      await _saveToStorage();
    }

    isInitialized = true;
    notifyListeners();
  }

  /// Предзаполненные списки для красивого Live Demo перед жюри
  void _seedDemoData() {
    lists.clear();
    lists.addAll([
      ItemList(
        'Выход из общаги / Dorm Exit',
        true,
        id: 'a101',
        category: SpotCategory.todo,
        isNfcLinked: true,
        nfcTagLabel: 'NTAG215 · DOOR01',
        items: [
          Item('Взять пропуск студента и ключи', true, done: true),
          Item('Зарядка от ноутбука + переходник', true, done: true),
          Item('Выключить утюг и свет', true, done: false),
          Item('Проверить NFC-брелок в рюкзаке', true, done: false),
        ],
      ),
      ItemList(
        'ololo / Coworking Wi-Fi',
        false,
        id: 'w204',
        category: SpotCategory.wifi,
        isNfcLinked: true,
        nfcTagLabel: 'NTAG215 · DESK04',
        wifiSsid: 'ololo_Resident_5G',
        wifiPassword: 'SpotNote2026!',
        items: [
          Item('Гостевой доступ для команды на хакатон', false),
          Item('Переговорка на 3 этаже — бронь до 18:00', false),
        ],
      ),
      ItemList(
        'Midterm Demo Day Checklist',
        true,
        id: 'd309',
        category: SpotCategory.todo,
        isNfcLinked: false,
        items: [
          Item('Показать проблему и целевую аудиторию (30 сек)', true, done: true),
          Item('Live Demo: создание списка и привязка NFC (3 мин)', true, done: false),
          Item('Показать функцию Share List по коду', true, done: false),
          Item('Ответить на вопросы жюри (Q&A)', true, done: false),
        ],
      ),
    ]);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(lists.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  ItemList? _resolveList(Object target) {
    if (target is ItemList) return target;
    if (target is String) {
      for (final l in lists) {
        if (l.id == target) return l;
      }
    }
    return null;
  }

  /// Переключение языка RU <-> EN
  Future<void> toggleLanguage() async {
    AppStrings.isEn = !AppStrings.isEn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, AppStrings.isEn);
    notifyListeners();
  }

  /// Отфильтрованные списки для главного экрана (поиск + категория)
  List<ItemList> get filteredLists {
    return lists.where((list) {
      final matchesCategory =
          selectedCategory == null || list.category == selectedCategory;
      final q = searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          list.name.toLowerCase().contains(q) ||
          list.spotAddress.toLowerCase().contains(q) ||
          (list.nfcTagLabel?.toLowerCase().contains(q) ?? false) ||
          (list.wifiSsid?.toLowerCase().contains(q) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void setCategoryFilter(SpotCategory? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  /// Поиск списка по его локальному NFC-адресу (spot://...)
  ItemList? findBySpotAddress(String address) {
    final clean = address.trim().toLowerCase();
    for (final list in lists) {
      if (list.spotAddress.toLowerCase() == clean ||
          list.id.toLowerCase() == clean) {
        return list;
      }
    }
    return null;
  }

  /// Все списки, привязанные к NFC-меткам (для симулятора касания на эмуляторе)
  List<ItemList> get nfcLinkedLists =>
      lists.where((l) => l.isNfcLinked).toList();

  void addList(
    String name,
    Object categoryOrBool, {
    SpotCategory? category,
    String? wifiSsid,
    String? wifiPassword,
  }) {
    final SpotCategory resolvedCat;
    if (category != null) {
      resolvedCat = category;
    } else if (categoryOrBool is SpotCategory) {
      resolvedCat = categoryOrBool;
    } else if (categoryOrBool is bool) {
      resolvedCat = categoryOrBool ? SpotCategory.todo : SpotCategory.note;
    } else {
      resolvedCat = SpotCategory.todo;
    }

    lists.insert(
      0,
      ItemList(
        name,
        resolvedCat == SpotCategory.todo,
        category: resolvedCat,
        wifiSsid: wifiSsid,
        wifiPassword: wifiPassword,
      ),
    );
    _saveToStorage();
    notifyListeners();
  }

  void renameList(
    Object listOrId,
    String name, {
    SpotCategory? category,
    String? wifiSsid,
    String? wifiPassword,
  }) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    list.name = name;
    if (category != null) list.category = category;
    if (wifiSsid != null) list.wifiSsid = wifiSsid;
    if (wifiPassword != null) list.wifiPassword = wifiPassword;
    _saveToStorage();
    notifyListeners();
  }

  void updateWifiCredentials(
    Object listOrId, {
    required String ssid,
    required String password,
  }) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    list.wifiSsid = ssid;
    list.wifiPassword = password;
    _saveToStorage();
    notifyListeners();
  }

  void deleteList(Object listOrId) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    lists.remove(list);
    _saveToStorage();
    notifyListeners();
  }

  /// Привязка/отвязка списка к NFC-метке
  void bindNfcTag(Object listOrId, [String? tagLabel]) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    list.isNfcLinked = true;
    list.nfcTagLabel =
        (tagLabel != null && tagLabel.isNotEmpty) ? tagLabel : 'NTAG215 · ${list.id.toUpperCase()}';
    _saveToStorage();
    notifyListeners();
  }

  void unbindNfcTag(Object listOrId) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    list.isNfcLinked = false;
    list.nfcTagLabel = null;
    _saveToStorage();
    notifyListeners();
  }

  /// Импорт общего списка (функция Share List)
  bool importSharedList(String shareCode) {
    final imported = ItemList.importFromShareCode(shareCode);
    if (imported == null) return false;
    lists.insert(0, imported);
    _saveToStorage();
    notifyListeners();
    return true;
  }

  void addItem(Object listOrId, String text, [bool? isTodoOverride]) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    final isTodo = isTodoOverride ?? (list.category == SpotCategory.todo);
    list.items.add(Item(text, isTodo));
    _saveToStorage();
    notifyListeners();
  }

  void editItem(Object listOrItem, Object itemIdOrText, [String? maybeText]) {
    if (listOrItem is Item && itemIdOrText is String) {
      listOrItem.text = itemIdOrText;
      _saveToStorage();
      notifyListeners();
      return;
    }
    final list = _resolveList(listOrItem);
    if (list == null || maybeText == null) return;
    for (final item in list.items) {
      if (item.id == itemIdOrText) {
        item.text = maybeText;
        break;
      }
    }
    _saveToStorage();
    notifyListeners();
  }

  void deleteItem(Object listOrId, Object itemOrId) {
    final list = _resolveList(listOrId);
    if (list == null) return;
    if (itemOrId is Item) {
      list.items.remove(itemOrId);
    } else if (itemOrId is String) {
      list.items.removeWhere((e) => e.id == itemOrId);
    }
    _saveToStorage();
    notifyListeners();
  }

  void toggleItem(Object listOrItem, [String? itemId]) {
    if (listOrItem is Item) {
      listOrItem.done = !listOrItem.done;
      _saveToStorage();
      notifyListeners();
      return;
    }
    final list = _resolveList(listOrItem);
    if (list == null || itemId == null) return;
    for (final item in list.items) {
      if (item.id == itemId) {
        item.done = !item.done;
        break;
      }
    }
    _saveToStorage();
    notifyListeners();
  }
}

final appState = AppState();
