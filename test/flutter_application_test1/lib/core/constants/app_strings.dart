/// Двуязычный словарь (RU / EN) с мгновенным переключением
class AppStrings {
  static bool isEn = false;

  static String get appTitle => 'SpotNote';
  static String get subtitle => isEn
      ? 'Smart local lists & NFC spot tags'
      : 'Умные локальные списки и NFC-метки';

  // Категории
  static String get catAll => isEn ? 'All' : 'Все';
  static String get catTodo => isEn ? 'To-Do' : 'Задачи';
  static String get catNote => isEn ? 'List' : 'Список';
  static String get catWifi => isEn ? 'Wi-Fi' : 'Wi-Fi';

  // Главный экран
  static String get searchHint =>
      isEn ? 'Search by title or spot:// address...' : 'Поиск по названию или spot:// адресу...';
  static String get emptyLists => isEn
      ? 'No spots yet. Create your first list or scan an NFC tag.'
      : 'Списков пока нет. Создайте первый или считайте NFC-метку.';
  static String get simulateNfcTap =>
      isEn ? 'Simulate NFC Tap' : 'Симуляция NFC';
  static String get importShared =>
      isEn ? 'Import Shared List' : 'Импорт по коду';
  static String get itemsCount => isEn ? 'Items' : 'Пунктов';
  static String get nfcLinked => isEn ? 'NFC Linked' : 'NFC привязан';
  static String get nfcNotLinked => isEn ? 'No tag' : 'Без метки';

  // Диалоги и действия
  static String get newList => isEn ? 'New Spot List' : 'Новый список';
  static String get editList => isEn ? 'Rename List' : 'Переименовать';
  static String get titleHint => isEn ? 'Title (e.g. Dorm Exit Checklist)' : 'Название (напр. Выход из общаги)';
  static String get wifiSsidHint => isEn ? 'Wi-Fi Network Name (SSID)' : 'Имя сети Wi-Fi (SSID)';
  static String get wifiPassHint => isEn ? 'Wi-Fi Password' : 'Пароль от Wi-Fi';
  static String get cancel => isEn ? 'Cancel' : 'Отмена';
  static String get create => isEn ? 'Create' : 'Создать';
  static String get save => isEn ? 'Save' : 'Сохранить';
  static String get delete => isEn ? 'Delete' : 'Удалить';
  static String get shareList => isEn ? 'Share List' : 'Поделиться';
  static String get bindNfc => isEn ? 'Write to NFC Tag' : 'Записать на NFC';
  static String get unbindNfc => isEn ? 'Unlink NFC Tag' : 'Отвязать NFC';

  // Внутри списка
  static String get newItem => isEn ? 'Add Item' : 'Новый пункт';
  static String get editItem => isEn ? 'Edit Item' : 'Изменить пункт';
  static String get itemHint => isEn ? 'Enter text...' : 'Введите текст...';
  static String get checkableItem =>
      isEn ? 'Checkable (To-Do item)' : 'С галочкой (To-Do пункт)';
  static String get emptyItems =>
      isEn ? 'This list is empty. Add your first item below.' : 'Список пуст. Добавьте первый пункт.';
  static String get copiedToast =>
      isEn ? 'Copied to clipboard' : 'Скопировано в буфер обмена';
  static String get nfcWrittenToast =>
      isEn ? 'Spot address written to NFC tag!' : 'Адрес списка записан на NFC-метку!';
}