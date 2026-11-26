import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_widgets.dart';
import '../list_detail/list_screen.dart';

/// Алиас для совместимости с main.dart
typedef HomePage = HomeScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _openList(ItemList list) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ListScreen(list: list)),
    );
  }

  Future<void> _createList() async {
    final result = await showSpotSheet<
        ({String name, SpotCategory category, String? ssid, String? password})>(
      context,
      builder: (_) => const _CreateListSheet(),
    );
    if (result == null || !mounted) return;
    appState.addList(
      result.name,
      result.category,
      category: result.category,
      wifiSsid: result.ssid,
      wifiPassword: result.password,
    );
    showSpotSnack(
      context,
      tr('Список «${result.name}» создан', 'List “${result.name}” created'),
      kind: SpotSnackKind.success,
    );
  }

  Future<void> _showListActions(ItemList list) async {
    final action = await showSpotSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(list.name, subtitle: list.spotAddress),
          const SizedBox(height: 16),
          SpotButton(
            label: tr('Переименовать', 'Rename'),
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.of(ctx).pop('rename'),
          ),
          const SizedBox(height: 8),
          SpotButton(
            label: tr('Удалить список', 'Delete list'),
            icon: Icons.delete_outline_rounded,
            kind: SpotButtonKind.danger,
            onPressed: () => Navigator.of(ctx).pop('delete'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'rename') {
      final name = await showTextInputSheet(
        context,
        title: tr('Переименовать список', 'Rename list'),
        hint: tr('Название', 'Name'),
        initial: list.name,
        confirmLabel: tr('Сохранить', 'Save'),
      );
      if (name != null && mounted) appState.renameList(list.id, name);
    } else if (action == 'delete') {
      final ok = await showConfirmSheet(
        context,
        title: tr('Удалить «${list.name}»?', 'Delete “${list.name}”?'),
        message: tr('Список и все его пункты будут удалены безвозвратно.',
            'The list and all its items will be permanently deleted.'),
        confirmLabel: tr('Удалить', 'Delete'),
        destructive: true,
      );
      if (ok && mounted) {
        appState.deleteList(list.id);
        showSpotSnack(context, tr('Список удалён', 'List deleted'));
      }
    }
  }

  Future<void> _importByCode() async {
    final code = await showSpotSheet<String>(
      context,
      builder: (_) => const _ImportSheet(),
    );
    if (code == null || !mounted) return;
    final ok = appState.importSharedList(code);
    showSpotSnack(
      context,
      ok
          ? tr('Список импортирован', 'List imported')
          : tr('Неверный код — не удалось импортировать',
              'Invalid code — import failed'),
      kind: ok ? SpotSnackKind.success : SpotSnackKind.error,
    );
  }

  Future<void> _openNfcSimulator() async {
    final address = await showSpotSheet<String>(
      context,
      builder: (_) => const _NfcSimSheet(),
    );
    if (address == null || !mounted) return;
    _handleNfcTap(address);
  }

  void _handleNfcTap(String raw) {
    final address = raw.trim();
    final messenger = ScaffoldMessenger.of(context);
    final target = appState.findBySpotAddress(address);

    if (target == null) {
      showSpotSnackOn(
        messenger,
        tr('Метка не найдена: $address', 'Tag not found: $address'),
        kind: SpotSnackKind.error,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _openList(target);
    showSpotSnackOn(
      messenger,
      tr('NFC-метка считана: переход по адресу ${target.spotAddress}',
          'NFC tag read: opening ${target.spotAddress}'),
      kind: SpotSnackKind.success,
      icon: Icons.nfc_rounded,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lists = appState.filteredLists;
        return Scaffold(
          backgroundColor: AppColors.kBg,
          appBar: AppBar(
            backgroundColor: AppColors.kBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: const Text(
              'SpotNote',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.kText,
              ),
            ),
            actions: [
              _LangButton(onPressed: appState.toggleLanguage),
              IconButton(
                tooltip: tr('Импорт по коду', 'Share Import'),
                icon: const Icon(Icons.file_download_outlined,
                    color: AppColors.kAccentBright),
                onPressed: _importByCode,
              ),
              IconButton(
                tooltip: tr('Симуляция NFC', 'Simulate NFC Tap'),
                icon: const Icon(Icons.nfc_rounded,
                    color: AppColors.kAccentBright),
                onPressed: _openNfcSimulator,
              ),
              const SizedBox(width: 4),
            ],
            bottom: const SpotAppBarDivider(),
          ),
          floatingActionButton: SpotFab(
            icon: Icons.add_rounded,
            label: tr('Новый список', 'New list'),
            onPressed: _createList,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SpotTextField(
                  controller: _searchCtrl,
                  hint: tr('Поиск по названию или spot:// адресу...',
                      'Search by title or spot:// address...'),
                  prefixIcon: Icons.search_rounded,
                  onChanged: appState.setSearchQuery,
                  suffix: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.kDim),
                          onPressed: () {
                            _searchCtrl.clear();
                            appState.setSearchQuery('');
                          },
                        ),
                ),
              ),
              const _CategoryChips(),
              Expanded(
                child: lists.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title: tr('Ничего не найдено', 'Nothing found'),
                        subtitle: tr(
                            'Создайте новый список или измените фильтр',
                            'Create a new list or change the filter'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: lists.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final list = lists[i];
                          return _ListCard(
                            key: ValueKey('list_${list.id}'),
                            list: list,
                            onOpen: () => _openList(list),
                            onMenu: () => _showListActions(list),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar: language switch
// ─────────────────────────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  const _LangButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ru = appState.isRu;
    const active = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kText);
    const idle = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.kDim);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: 'RU', style: ru ? active : idle),
          const TextSpan(text: ' / ', style: idle),
          TextSpan(text: 'EN', style: ru ? idle : active),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final options = <(SpotCategory?, String)>[
      (null, tr('Все', 'All')),
      (SpotCategory.todo, 'To-Do'),
      (SpotCategory.note, tr('Список', 'List')),
      (SpotCategory.wifi, 'Wi-Fi'),
    ];
    final selected = appState.selectedCategory;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label) = options[i];
          return _FilterChipButton(
            label: label,
            selected: selected == cat,
            onTap: () => appState.setCategoryFilter(cat),
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.kSurfaceElevated : Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: selected ? AppColors.kAccent : AppColors.kBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.kText : AppColors.kDim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List card
// ─────────────────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  const _ListCard({
    super.key,
    required this.list,
    required this.onOpen,
    required this.onMenu,
  });

  final ItemList list;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final isTodo = list.category == SpotCategory.todo;
    final isWifi = list.category == SpotCategory.wifi;

    return SpotCard(
      onTap: onOpen,
      onLongPress: onMenu,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.kBorder, width: 1),
                ),
                child: Icon(categoryIcon(list.category),
                    size: 20, color: AppColors.kAccentBright),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SpotAddressBadge(address: list.spotAddress),
                          if (list.isNfcLinked) const NfcStatusBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('Действия', 'Actions'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: AppColors.kDim),
                onPressed: onMenu,
              ),
            ],
          ),
          if (isTodo) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ProgressRow(list: list),
            ),
          ],
          if (isWifi) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SsidRow(list: list),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.list});
  final ItemList list;

  @override
  Widget build(BuildContext context) {
    final total = list.items.length;
    final done = list.items.where((i) => i.done).length;
    final p = list.progress.toDouble().clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: p,
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: AppColors.kBorder,
            color: p >= 1 ? AppColors.kSuccess : AppColors.kAccentBright,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done/$total',
          style: const TextStyle(
            fontFamily: kMonoFont,
            fontSize: 12,
            color: AppColors.kDim,
          ),
        ),
      ],
    );
  }
}

class _SsidRow extends StatelessWidget {
  const _SsidRow({required this.list});
  final ItemList list;

  @override
  Widget build(BuildContext context) {
    final ssid = list.wifiSsid == null ? '' : list.wifiSsid.toString();
    return Row(
      children: [
        const Icon(Icons.router_outlined, size: 16, color: AppColors.kDim),
        const SizedBox(width: 8),
        const Text('SSID',
            style: TextStyle(fontSize: 12, color: AppColors.kDim)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ssid.isEmpty ? '—' : ssid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kMonoFont,
              fontSize: 13,
              color: AppColors.kText,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: create list (с поддержкой Wi-Fi SSID & Password)
// ─────────────────────────────────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  const _CreateListSheet();

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  final TextEditingController _c = TextEditingController();
  final TextEditingController _ssidCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  SpotCategory _cat = SpotCategory.todo;

  @override
  void dispose() {
    _c.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop((
      name: v,
      category: _cat,
      ssid: _cat == SpotCategory.wifi ? _ssidCtrl.text.trim() : null,
      password: _cat == SpotCategory.wifi ? _passCtrl.text.trim() : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(tr('Новый список', 'New list')),
        const SizedBox(height: 16),
        SpotTextField(
          controller: _c,
          hint: tr('Название (напр. Выход из общаги)',
              'Title (e.g. Dorm Exit Checklist)'),
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final c in SpotCategory.values) ...[
              Expanded(
                child: _CategoryOption(
                  category: c,
                  selected: _cat == c,
                  onTap: () => setState(() => _cat = c),
                ),
              ),
              if (c != SpotCategory.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        if (_cat == SpotCategory.wifi) ...[
          const SizedBox(height: 12),
          SpotTextField(
            controller: _ssidCtrl,
            hint: tr('Имя сети Wi-Fi (SSID)', 'Wi-Fi Network Name (SSID)'),
            prefixIcon: Icons.wifi_rounded,
            mono: true,
          ),
          const SizedBox(height: 10),
          SpotTextField(
            controller: _passCtrl,
            hint: tr('Пароль от Wi-Fi', 'Wi-Fi Password'),
            prefixIcon: Icons.lock_outline_rounded,
            mono: true,
            onSubmitted: (_) => _submit(),
          ),
        ],
        const SizedBox(height: 16),
        SpotButton(
          label: tr('Создать', 'Create'),
          kind: SpotButtonKind.primary,
          onPressed: _c.text.trim().isEmpty ? null : _submit,
        ),
      ],
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SpotCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.kSurfaceElevated : Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: selected ? AppColors.kAccent : AppColors.kBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(categoryIcon(category),
                    size: 20,
                    color: selected ? AppColors.kAccentBright : AppColors.kDim),
                const SizedBox(height: 6),
                Text(
                  categoryLabel(category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.kText : AppColors.kDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: import by code
// ─────────────────────────────────────────────────────────────────────────────

class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && mounted) {
      setState(() => _c.text = text);
    }
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          tr('Импорт по коду', 'Share Import'),
          subtitle: tr('Вставьте код, полученный через «Поделиться»',
              'Paste a code received via “Share”'),
        ),
        const SizedBox(height: 16),
        SpotTextField(
          controller: _c,
          hint: tr('Код списка', 'List code'),
          mono: true,
          maxLines: 5,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SpotButton(
                label: tr('Вставить', 'Paste'),
                icon: Icons.content_paste_rounded,
                onPressed: _paste,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SpotButton(
                label: tr('Импортировать', 'Import'),
                kind: SpotButtonKind.primary,
                onPressed: _c.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: NFC simulator
// ─────────────────────────────────────────────────────────────────────────────

class _NfcSimSheet extends StatefulWidget {
  const _NfcSimSheet();

  @override
  State<_NfcSimSheet> createState() => _NfcSimSheetState();
}

class _NfcSimSheetState extends State<_NfcSimSheet> {
  final TextEditingController _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submitManual() {
    final v = _c.text.trim();
    if (v.isEmpty) {
      setState(() => _error = tr('Введите spot:// адрес или короткий ID',
          'Enter a spot:// address or short ID'));
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final linked = appState.nfcLinkedLists;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          tr('Симуляция NFC', 'Simulate NFC Tap'),
          subtitle: tr('Выберите привязанную метку или введите адрес',
              'Pick a linked tag or enter an address'),
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('Привязанные метки', 'Linked tags')),
        const SizedBox(height: 10),
        if (linked.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.kBorder, width: 1),
            ),
            child: Text(
              tr('Нет списков, привязанных к NFC. Откройте список и нажмите «Записать на NFC».',
                  'No lists linked to NFC yet. Open a list and tap “Write to NFC”.'),
              style: const TextStyle(fontSize: 13, color: AppColors.kDim),
            ),
          )
        else
          for (final list in linked) ...[
            _LinkedTagTile(
              list: list,
              onTap: () => Navigator.of(context).pop(list.spotAddress),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        SectionLabel(tr('Или введите адрес', 'Or enter an address')),
        const SizedBox(height: 10),
        SpotTextField(
          controller: _c,
          hint: 'spot://todo/a101',
          mono: true,
          errorText: _error,
          prefixIcon: Icons.link_rounded,
          textInputAction: TextInputAction.go,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submitManual(),
        ),
        const SizedBox(height: 12),
        SpotButton(
          label: tr('Считать метку', 'Tap tag'),
          icon: Icons.nfc_rounded,
          kind: SpotButtonKind.primary,
          onPressed: _submitManual,
        ),
      ],
    );
  }
}

class _LinkedTagTile extends StatelessWidget {
  const _LinkedTagTile({required this.list, required this.onTap});
  final ItemList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tag = list.nfcTagLabel == null ? '' : list.nfcTagLabel.toString();
    return SpotCard(
      color: AppColors.kSurfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(categoryIcon(list.category),
              size: 20, color: AppColors.kAccentBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tag.isEmpty ? list.spotAddress : '${list.spotAddress} · $tag',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kMonoFont,
                    fontSize: 11,
                    color: AppColors.kDim,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.kDim),
        ],
      ),
    );
  }
}