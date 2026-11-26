# SpotNote - Project Context

This file contains the complete snapshot of the project structure and source code to be used for architectural planning and task distribution among AI agents.

## Project Tree
```text
mopil app/test/flutter_application_test1/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── progress/
│   │   ├── project_report_gemini1.md
│   │   ├── REPORT 2 cloude.md
│   │   └── REPORT1_cloude.MD
│   └── user target/
│       ├── user.md
│       └── users_plases.md
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── models/
│   │   └── item_model.dart
│   ├── providers/
│   │   └── app_state.dart
│   ├── widgets/
│   │   └── app_widgets.dart
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   └── list_detail/
│   │       └── list_screen.dart
│   └── main.dart
└── pubspec.yaml
```

---

## pubspec.yaml
```yaml
name: flutter_application_test1
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: ^3.13.4
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
flutter:
  uses-material-design: true
```

---

## 1. Documentation Files

### docs/ARCHITECTURE.md
```md
## Architecture 
## функции :
* создовать файлы списков
* каждый из файлов иммет свой аддрес 
* NFC тек запоминает адрес а не информацию в списке как бы файл сохраняется на телфоне а не на нфс
* запись адресса на NFC тег должно быть максимально простым 
* чтение тег и переход к заметке должно быть максимально простым 
* котегории: Todp list , wifi writer , list , делится листом(папка , информация папки и его адрес что бы и другой юзер мог локально его открыть)
 
# фичи  которые мейби добавлю (на этот блок внимания не обращай)
* создания тег профиль , украшение с NFC чипом и показывает профили соцсетей , 
* отслеживания продуктов , напоминания о дедлайнах idk 
* не полноценное украшение а доб брилок или легко добавить на украшения. 
```

### docs/progress/project_report_gemini1.md
```md
# Отчёт по проекту: Реструктуризация приложения SpotNote
**Дата:** 22 октября 2026 г.  
**Проект:** SpotNote (Мобильное приложение на Flutter)

## 1. Обзор выполненных изменений
В ходе текущей сессии мы перешли от однофайловой структуры (`main.dart`) к чистой, масштабируемой многофайловой архитектуре, удобной для дальнейшей разработки и работы с ИИ-ассистентами.

### Ключевые достижения:
1. **Настройка архитектуры и структуры папок:** Сформирована структура директорий по принципу Feature-First / Clean Architecture внутри папки `lib/`.
2. **Модуляция и разделение кода:** Монолитный файл `main.dart` был разбит на отдельные файлы по зонам ответственности.
3. **Обновление брендинга и интерфейса:** Заголовок на главном экране изменён с «Списки» на **«SpotNote»**.

## 3. Ближайшие шаги разработки (План)
* [ ] Подключить локальное хранилище данных (`shared_preferences` или `hive`), чтобы списки сохранялись после перезапуска приложения.
* [ ] Добавить возможность удаления и редактирования отдельных пунктов внутри `ListPage`.
* [ ] Добавить поиск и фильтрацию списков на главном экране.
```

---

## 2. Flutter Source Code (lib/)

### lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Списки',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
```

### lib/core/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.kBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.kAccent,
        onPrimary: AppColors.kBg,
        surface: AppColors.kBg,
        onSurface: AppColors.kText,
        surfaceContainerHigh: AppColors.kCard, // фон диалогов
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.kText,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.kAccent,
        foregroundColor: AppColors.kBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
```

### lib/core/constants/app_colors.dart
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const kBg = Color(0xFF0E0E10); // фон
  static const kCard = Color(0xFF1A1A1E); // карточки
  static const kAccent = Color(0xFF7C9CFF); // акцент
  static const kText = Color(0xFFEDEDF0); // основной текст
  static const kDim = Color(0xFF8A8A93); // второстепенный текст
}
```

### lib/models/item_model.dart
```dart
class Item {
  String text;
  bool isTodo; // true — с галочкой, false — обычный пункт
  bool done;

  Item(this.text, this.isTodo, {this.done = false});
}

class ItemList {
  String name;
  bool isTodo; // тип списка (задаёт значение по умолчанию для новых пунктов)
  final List<Item> items = [];

  ItemList(this.name, this.isTodo);
}
```

### lib/providers/app_state.dart
```dart
import 'package:flutter/material.dart';
import '../models/item_model.dart';

class AppState extends ChangeNotifier {
  final List<ItemList> lists = [];

  void addList(String name, bool isTodo) {
    lists.add(ItemList(name, isTodo));
    notifyListeners();
  }

  void renameList(ItemList list, String name) {
    list.name = name;
    notifyListeners();
  }

  void deleteList(ItemList list) {
    lists.remove(list);
    notifyListeners();
  }

  void addItem(ItemList list, String text, bool isTodo) {
    list.items.add(Item(text, isTodo));
    notifyListeners();
  }

  void toggleItem(Item item) {
    item.done = !item.done;
    notifyListeners();
  }
}

final appState = AppState();
```

### lib/widgets/app_widgets.dart
```dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Простая скруглённая карточка
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.kCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Поле ввода в общем стиле
InputDecoration inputStyle(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.kDim),
    filled: true,
    fillColor: AppColors.kBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

/// Пустое состояние
class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppColors.kDim, fontSize: 16)),
    );
  }
}

/// Кнопка-выбор типа списка
Widget typeChip(String label, bool selected, VoidCallback onTap) {
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    selectedColor: AppColors.kAccent,
    backgroundColor: AppColors.kBg,
    side: BorderSide.none,
    labelStyle: TextStyle(color: selected ? AppColors.kBg : AppColors.kText),
  );
}
```

### lib/screens/home/home_screen.dart
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_widgets.dart';
import '../list_detail/list_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _createList(BuildContext context) async {
    final controller = TextEditingController();
    bool isTodo = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Новый список'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: inputStyle('Название'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  typeChip('To-do', isTodo, () => setLocal(() => isTodo = true)),
                  const SizedBox(width: 8),
                  typeChip(
                      'Обычный', !isTodo, () => setLocal(() => isTodo = false)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Создать')),
          ],
        ),
      ),
    );

    final name = controller.text.trim();
    if (ok == true && name.isNotEmpty) appState.addList(name, isTodo);
  }

  Future<void> _renameList(BuildContext context, ItemList list) async {
    final controller = TextEditingController(text: list.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переименовать'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: inputStyle('Название'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Сохранить')),
        ],
      ),
    );

    final name = controller.text.trim();
    if (ok == true && name.isNotEmpty) appState.renameList(list, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SpoteNote')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.lists.isEmpty) {
            return const EmptyState('Создайте первый список');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: appState.lists.length,
            itemBuilder: (context, i) {
              final list = appState.lists[i];
              return AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ListPage(list: list)),
                ),
                child: Row(
                  children: [
                    Icon(
                      list.isTodo
                          ? Icons.check_circle_outline
                          : Icons.format_list_bulleted,
                      color: AppColors.kAccent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Пунктов: ${list.items.length}',
                            style: const TextStyle(color: AppColors.kDim, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: AppColors.kDim),
                      onSelected: (v) {
                        if (v == 'rename') _renameList(context, list);
                        if (v == 'delete') appState.deleteList(list);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'rename', child: Text('Переименовать')),
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createList(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### lib/screens/list_detail/list_screen.dart
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_widgets.dart';

class ListPage extends StatelessWidget {
  final ItemList list;
  const ListPage({super.key, required this.list});

  Future<void> _addItem(BuildContext context) async {
    final controller = TextEditingController();
    bool isTodo = list.isTodo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Новый пункт'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: inputStyle('Текст'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('С галочкой (to-do)'),
                value: isTodo,
                activeColor: AppColors.kAccent,
                onChanged: (v) => setLocal(() => isTodo = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Добавить')),
          ],
        ),
      ),
    );

    final text = controller.text.trim();
    if (ok == true && text.isNotEmpty) appState.addItem(list, text, isTodo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (list.items.isEmpty) return const EmptyState('Список пуст');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: list.items.length,
            itemBuilder: (context, i) {
              final item = list.items[i];
              return AppCard(
                onTap: item.isTodo ? () => appState.toggleItem(item) : null,
                child: Row(
                  children: [
                    item.isTodo
                        ? Icon(
                            item.done
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: item.done ? AppColors.kAccent : AppColors.kDim,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.circle, size: 8, color: AppColors.kDim),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: item.done ? AppColors.kDim : AppColors.kText,
                          decoration:
                              item.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```
